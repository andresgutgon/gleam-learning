import blah/name
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import packages/platform/postgresql/repositories/contacts/sql.{
  type PipelineStage, Contact, Customer, Lead, Opportunity,
}
import pog

const seed_contact_count = 300

const companies = [
  "Acme Corp", "TechFlow Inc", "Digital Dynamics", "Innovate Labs",
  "CloudScale Solutions", "DataVision Systems", "Quantum Networks",
  "Synergy Partners", "NextGen Technologies", "Velocity Ventures",
  "Pinnacle Industries", "Horizon Enterprises", "Atlas Corporation",
  "Zenith Systems", "Fusion Tech", "Catalyst Group", "Nexus Solutions",
  "Endeavor Inc", "Momentum Digital", "Apex Innovations",
]

const job_titles = [
  "Software Engineer", "Product Manager", "Sales Director", "VP of Engineering",
  "Marketing Manager", "Data Analyst", "Account Executive", "CTO",
  "Operations Manager", "Business Analyst", "Customer Success Manager",
  "Frontend Developer", "Backend Developer", "DevOps Engineer",
  "UX Designer", "Content Strategist", "HR Manager", "Finance Director",
  "Chief Revenue Officer", "Technical Lead",
]

const pipeline_stages = [Lead, Contact, Opportunity, Customer]

type SeedContact {
  SeedContact(
    first_name: String,
    last_name: String,
    email: String,
    phone: String,
    company: String,
    title: String,
    stage: PipelineStage,
  )
}

pub fn seed(db: pog.Connection) -> Result(Nil, String) {
  io.println("🌱 Seeding " <> int.to_string(seed_contact_count) <> " contacts...")

  // Generate all contacts
  let contacts = generate_range(1, seed_contact_count + 1, [])
    |> list.map(generate_contact)

  // Insert or update contacts
  case insert_contacts_batch(db, contacts) {
    Ok(_) -> {
      io.println(
        "✓ Successfully seeded "
        <> int.to_string(seed_contact_count)
        <> " contacts",
      )
      Ok(Nil)
    }
    Error(e) -> Error("Failed to seed contacts: " <> e)
  }
}

fn generate_range(from: Int, to: Int, acc: List(Int)) -> List(Int) {
  case from >= to {
    True -> list.reverse(acc)
    False -> generate_range(from + 1, to, [from, ..acc])
  }
}

fn generate_contact(index: Int) -> SeedContact {
  let email =
    "contact_" <> string.pad_start(int.to_string(index), 3, "0") <> "@seed.local"

  // Deterministically cycle through companies and titles
  let company_index = { index - 1 } % list.length(companies)
  let title_index = { index - 1 } % list.length(job_titles)
  let stage_index = { index - 1 } % list.length(pipeline_stages)

  let company = get_list_item(companies, company_index, "Unknown Company")
  let title = get_list_item(job_titles, title_index, "Unknown Title")
  let stage = get_list_item(pipeline_stages, stage_index, Lead)

  // Generate realistic names using blah
  let first_name = name.first_name()
  let last_name = name.last_name()

  // Generate deterministic phone number
  let phone = generate_phone_number(index)

  SeedContact(
    first_name: first_name,
    last_name: last_name,
    email: email,
    phone: phone,
    company: company,
    title: title,
    stage: stage,
  )
}

fn get_list_item(list: List(a), index: Int, default: a) -> a {
  list
  |> list.drop(index)
  |> list.first
  |> result.unwrap(default)
}

fn generate_phone_number(seed: Int) -> String {
  // Generate a US-style phone number (555) XXX-XXXX
  // Using seed to make it deterministic but varied
  let area_code = 555
  let exchange = { seed * 7 } % 1000
  let line = { seed * 13 } % 10_000

  "("
  <> int.to_string(area_code)
  <> ") "
  <> string.pad_start(int.to_string(exchange), 3, "0")
  <> "-"
  <> string.pad_start(int.to_string(line), 4, "0")
}

fn insert_contacts_batch(
  db: pog.Connection,
  contacts: List(SeedContact),
) -> Result(Nil, String) {
  // Use single inserts with upsert logic
  contacts
  |> list.try_each(fn(contact) { insert_or_update_contact(db, contact) })
  |> result.replace(Nil)
}

fn insert_or_update_contact(
  db: pog.Connection,
  contact: SeedContact,
) -> Result(Nil, String) {
  // Use ON CONFLICT to handle idempotency
  let query =
    "
    INSERT INTO contacts (first_name, last_name, email, phone, company, title, stage)
    VALUES ($1, $2, $3, $4, $5, $6, $7::pipeline_stage)
    ON CONFLICT (email) DO UPDATE SET
      first_name = EXCLUDED.first_name,
      last_name = EXCLUDED.last_name,
      phone = EXCLUDED.phone,
      company = EXCLUDED.company,
      title = EXCLUDED.title,
      stage = EXCLUDED.stage
    "

  pog.query(query)
  |> pog.parameter(pog.text(contact.first_name))
  |> pog.parameter(pog.text(contact.last_name))
  |> pog.parameter(pog.text(contact.email))
  |> pog.parameter(pog.text(contact.phone))
  |> pog.parameter(pog.text(contact.company))
  |> pog.parameter(pog.text(contact.title))
  |> pog.parameter(pipeline_stage_to_value(contact.stage))
  |> pog.execute(db)
  |> result.map_error(fn(e) {
    case e {
      pog.ConnectionUnavailable -> "Database connection unavailable"
      pog.ConstraintViolated(msg, ..) -> "Constraint violated: " <> msg
      pog.PostgresqlError(code, name, msg) ->
        "PostgreSQL error " <> code <> " (" <> name <> "): " <> msg
      pog.UnexpectedArgumentCount(..) -> "Unexpected argument count"
      pog.UnexpectedArgumentType(..) -> "Unexpected argument type"
      pog.UnexpectedResultType(..) -> "Unexpected result type"
      pog.QueryTimeout -> "Query timeout"
    }
  })
  |> result.replace(Nil)
}

fn pipeline_stage_to_value(stage: PipelineStage) -> pog.Value {
  case stage {
    Customer -> pog.text("customer")
    Opportunity -> pog.text("opportunity")
    Contact -> pog.text("contact")
    Lead -> pog.text("lead")
  }
}
