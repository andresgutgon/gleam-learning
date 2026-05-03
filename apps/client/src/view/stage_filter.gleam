import gleam/option.{type Option}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import shared/contacts/contact.{
  type PipelineStage, ContactStage, CustomerStage, LeadStage, OpportunityStage,
}

pub fn view(
  active: Option(PipelineStage),
  on_select: fn(Option(PipelineStage)) -> msg,
) -> Element(msg) {
  html.div([attribute.class("flex items-center gap-1.5 flex-wrap")], [
    all_pill(active, on_select),
    html.div([attribute.class("w-px h-4 bg-border mx-0.5 shrink-0")], []),
    stage_pill(ContactStage, active, on_select),
    stage_pill(LeadStage, active, on_select),
    stage_pill(OpportunityStage, active, on_select),
    stage_pill(CustomerStage, active, on_select),
  ])
}

fn all_pill(
  active: Option(PipelineStage),
  on_select: fn(Option(PipelineStage)) -> msg,
) -> Element(msg) {
  let is_active = active == option.None
  let classes = case is_active {
    True -> "border-border bg-muted text-foreground font-semibold"
    False ->
      "border-border bg-transparent text-muted-foreground"
      <> " hover:text-foreground hover:bg-muted/50"
  }
  html.button(
    [
      attribute.class(
        "inline-flex items-center rounded border px-3 py-1 text-xs"
        <> " transition-colors cursor-pointer "
        <> classes,
      ),
      event.on_click(on_select(option.None)),
    ],
    [element.text("All")],
  )
}

fn stage_pill(
  stage: PipelineStage,
  active: Option(PipelineStage),
  on_select: fn(Option(PipelineStage)) -> msg,
) -> Element(msg) {
  let is_active = active == option.Some(stage)
  let #(label, dot_class, base_class, active_extra) = case stage {
    ContactStage -> #(
      "Contact",
      "bg-amber-400",
      "border-amber-400/50 bg-amber-400/10 text-amber-800"
        <> " hover:border-amber-400/65 hover:bg-amber-400/20",
      "border-amber-400 bg-amber-400/30 font-semibold",
    )
    LeadStage -> #(
      "Lead",
      "bg-unnamed-blue",
      "border-unnamed-blue/55 bg-unnamed-blue/15 text-sky-800"
        <> " hover:border-unnamed-blue/70 hover:bg-unnamed-blue/25",
      "border-unnamed-blue bg-unnamed-blue/35 font-semibold",
    )
    OpportunityStage -> #(
      "Opportunity",
      "bg-purple-400",
      "border-purple-400/50 bg-purple-400/10 text-purple-800"
        <> " hover:border-purple-400/65 hover:bg-purple-400/20",
      "border-purple-400 bg-purple-400/30 font-semibold",
    )
    CustomerStage -> #(
      "Customer",
      "bg-faff-pink",
      "border-faff-pink/55 bg-faff-pink/10 text-aubergine"
        <> " hover:border-faff-pink/70 hover:bg-faff-pink/20",
      "border-faff-pink bg-faff-pink/30 font-semibold",
    )
  }
  let classes = case is_active {
    True -> base_class <> " " <> active_extra
    False -> base_class
  }
  let msg = case is_active {
    True -> on_select(option.None)
    False -> on_select(option.Some(stage))
  }
  html.button(
    [
      attribute.class(
        "inline-flex items-center gap-1.5 rounded border px-3 py-1 text-xs"
        <> " transition-colors cursor-pointer "
        <> classes,
      ),
      event.on_click(msg),
    ],
    [
      html.span(
        [attribute.class("h-1.5 w-1.5 rounded-full shrink-0 " <> dot_class)],
        [],
      ),
      element.text(label),
    ],
  )
}
