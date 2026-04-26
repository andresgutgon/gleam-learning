-- Get contacts with filtering and sorting
-- Parameters:
--   $1: stage filter (nullable)
--   $2: company filter (nullable)
--   $3: search term for first_name, last_name, email, company (nullable)
--   $4: email filter (nullable)
--   $5: phone filter (nullable)
--   $6: title filter (nullable)
--   $7: sort column (first_name, last_name, email, company, created_at, updated_at)
--   $8: sort direction (ASC or DESC)
--   $9: limit
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
FROM contacts
WHERE
  -- Filtering
  (stage::text = $1 OR $1 IS NULL) AND
  (company ILIKE '%' || $2 || '%' OR $2 IS NULL) AND
  (first_name ILIKE '%' || $3 || '%' OR last_name ILIKE '%' || $3 || '%' OR email ILIKE '%' || $3 || '%' OR company ILIKE '%' || $3 || '%' OR $3 IS NULL) AND
  (email ILIKE '%' || $4 || '%' OR $4 IS NULL) AND
  (phone ILIKE '%' || $5 || '%' OR $5 IS NULL) AND
  (title ILIKE '%' || $6 || '%' OR $6 IS NULL) AND
  
  -- Keyset pagination (skip for now since cursor_value can't be NULL)
  TRUE
ORDER BY
  CASE WHEN $7 = 'first_name' AND $8 = 'ASC' THEN first_name END ASC,
  CASE WHEN $7 = 'first_name' AND $8 = 'DESC' THEN first_name END DESC,
  CASE WHEN $7 = 'last_name' AND $8 = 'ASC' THEN last_name END ASC,
  CASE WHEN $7 = 'last_name' AND $8 = 'DESC' THEN last_name END DESC,
  CASE WHEN $7 = 'email' AND $8 = 'ASC' THEN email END ASC,
  CASE WHEN $7 = 'email' AND $8 = 'DESC' THEN email END DESC,
  CASE WHEN $7 = 'company' AND $8 = 'ASC' THEN company END ASC,
  CASE WHEN $7 = 'company' AND $8 = 'DESC' THEN company END DESC,
  CASE WHEN $7 = 'created_at' AND $8 = 'ASC' THEN created_at END ASC,
  CASE WHEN $7 = 'created_at' AND $8 = 'DESC' THEN created_at END DESC,
  CASE WHEN $7 = 'updated_at' AND $8 = 'ASC' THEN updated_at END ASC,
  CASE WHEN $7 = 'updated_at' AND $8 = 'DESC' THEN updated_at END DESC,
  id ASC
LIMIT $9;
