-- Update an existing contact
UPDATE contacts
SET first_name = $1,
last_name = $2,
email = $3,
phone = $4,
company = $5,
title = $6,
stage = $7,
profile_picture_url = $8,
notes = $9,
updated_at = NOW()
WHERE
  id = $10
RETURNING id,
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
  updated_at::timestamp;

