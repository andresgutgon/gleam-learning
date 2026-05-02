-- Delete a contact by ID
DELETE FROM contacts
WHERE
  id = $1
RETURNING id;

