-- Anchor DDL so sqlc has a schema root; replace or extend with real migrations.
CREATE TABLE IF NOT EXISTS sqlc_schema_anchor (
    id uuid PRIMARY KEY
);
