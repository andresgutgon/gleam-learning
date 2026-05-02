--- migration:up
CREATE TYPE pipeline_stage AS ENUM (
  'lead',
  'contact',
  'opportunity',
  'customer'
);

CREATE TABLE contacts(
    id SERIAL PRIMARY KEY,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    phone TEXT,
    company TEXT,
    title TEXT,
    stage pipeline_stage NOT NULL DEFAULT 'lead',
    profile_picture_url TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_contacts_stage ON contacts(stage);
CREATE INDEX idx_contacts_company ON contacts(company);
CREATE INDEX idx_contacts_created_at_desc ON contacts(created_at DESC);
CREATE INDEX idx_contacts_stage_created_at ON contacts(stage, created_at DESC);
CREATE INDEX idx_contacts_company_created_at ON contacts(company, created_at DESC);
CREATE INDEX idx_contacts_search_trgm ON contacts USING GIN (
  first_name gin_trgm_ops,
  last_name gin_trgm_ops,
  email gin_trgm_ops,
  company gin_trgm_ops
);

--- migration:down
DROP INDEX IF EXISTS idx_contacts_search_trgm;
DROP INDEX IF EXISTS idx_contacts_company_created_at;
DROP INDEX IF EXISTS idx_contacts_stage_created_at;
DROP INDEX IF EXISTS idx_contacts_created_at_desc;
DROP INDEX IF EXISTS idx_contacts_company;
DROP INDEX IF EXISTS idx_contacts_stage;
DROP TABLE IF EXISTS contacts;
DROP TYPE IF EXISTS pipeline_stage;

--- migration:end