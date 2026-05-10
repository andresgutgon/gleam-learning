-- Get contacts with filtering, sorting, and keyset (cursor) pagination.
--
-- Cursor convention:
--   - $11 = 0 means "no cursor" (first page). SERIAL ids start at 1, so 0 is a safe sentinel.
--   - When a cursor is set, $10 carries the sort column's value at the cursor (text-encoded;
--     timestamps are RFC3339), and $11 carries the row id at the cursor.
--
-- The id tiebreak is aligned with the primary sort direction so that
-- (sort_col, id) lexicographic comparison is correct in both directions.
--
-- Parameters:
--   $1: stage filter (empty string = no filter)
--   $2: company filter (empty string = no filter)
--   $3: search term across first_name, last_name, email, company (empty = no filter)
--   $4: email filter (empty = no filter)
--   $5: phone filter (empty = no filter)
--   $6: title filter (empty = no filter)
--   $7: sort column (first_name, last_name, email, company, created_at, updated_at)
--   $8: sort direction (ASC or DESC)
--   $9: limit (caller should pass desired_page_size + 1 to detect "has more")
--   $10: cursor value (text-encoded; timestamps as RFC3339)
--   $11: cursor id (0 = no cursor)
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
  (stage::text = $1 OR $1 = '') AND
  (company ILIKE '%' || $2 || '%' OR $2 = '') AND
  (first_name ILIKE '%' || $3 || '%' OR last_name ILIKE '%' || $3 || '%' OR email ILIKE '%' || $3 || '%' OR company ILIKE '%' || $3 || '%' OR $3 = '') AND
  (email ILIKE '%' || $4 || '%' OR $4 = '') AND
  (phone ILIKE '%' || $5 || '%' OR $5 = '') AND
  (title ILIKE '%' || $6 || '%' OR $6 = '') AND

  -- Keyset cursor predicate. Skipped entirely when no cursor is set ($11 = 0).
  ($11 = 0 OR
    CASE
      WHEN $7 = 'name'       AND $8 = 'ASC'  THEN (first_name || ' ' || last_name, id) > ($10, $11)
      WHEN $7 = 'name'       AND $8 = 'DESC' THEN (first_name || ' ' || last_name, id) < ($10, $11)
      WHEN $7 = 'email'      AND $8 = 'ASC'  THEN (email, id)      > ($10, $11)
      WHEN $7 = 'email'      AND $8 = 'DESC' THEN (email, id)      < ($10, $11)
      WHEN $7 = 'company'    AND $8 = 'ASC'  THEN (COALESCE(company, ''), id) > ($10, $11)
      WHEN $7 = 'company'    AND $8 = 'DESC' THEN (COALESCE(company, ''), id) < ($10, $11)
      WHEN $7 = 'created_at' AND $8 = 'ASC'  THEN (created_at, id) > ($10::timestamptz, $11)
      WHEN $7 = 'created_at' AND $8 = 'DESC' THEN (created_at, id) < ($10::timestamptz, $11)
      WHEN $7 = 'updated_at' AND $8 = 'ASC'  THEN (updated_at, id) > ($10::timestamptz, $11)
      WHEN $7 = 'updated_at' AND $8 = 'DESC' THEN (updated_at, id) < ($10::timestamptz, $11)
      ELSE TRUE
    END
  )
ORDER BY
  CASE WHEN $7 = 'name'       AND $8 = 'ASC'  THEN first_name || ' ' || last_name END ASC,
  CASE WHEN $7 = 'name'       AND $8 = 'DESC' THEN first_name || ' ' || last_name END DESC,
  CASE WHEN $7 = 'email'      AND $8 = 'ASC'  THEN email      END ASC,
  CASE WHEN $7 = 'email'      AND $8 = 'DESC' THEN email      END DESC,
  CASE WHEN $7 = 'company'    AND $8 = 'ASC'  THEN COALESCE(company, '') END ASC,
  CASE WHEN $7 = 'company'    AND $8 = 'DESC' THEN COALESCE(company, '') END DESC,
  CASE WHEN $7 = 'created_at' AND $8 = 'ASC'  THEN created_at END ASC,
  CASE WHEN $7 = 'created_at' AND $8 = 'DESC' THEN created_at END DESC,
  CASE WHEN $7 = 'updated_at' AND $8 = 'ASC'  THEN updated_at END ASC,
  CASE WHEN $7 = 'updated_at' AND $8 = 'DESC' THEN updated_at END DESC,
  -- id tiebreak aligned to the primary sort direction so (col, id) tuple compare is monotonic.
  CASE WHEN $8 = 'ASC'  THEN id END ASC,
  CASE WHEN $8 = 'DESC' THEN id END DESC
LIMIT $9;
