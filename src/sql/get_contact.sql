-- Get a single contact by ID
SELECT
  id,
  first_name,
  last_name,
  email,
  phone,
  company,
  title,
  stage,
  profile_picture_url,
  notes,
  created_at::timestamp,
  updated_at::timestamp
FROM
  contacts
WHERE
  id = $1;

