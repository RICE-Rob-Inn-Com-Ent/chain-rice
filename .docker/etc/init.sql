# CUE source: infra/configs/docker/etc__init.sql.cue (package docker; aggregator infra/configs/config.cue)
# Do not overwrite from CUE gen until shard content is wired; edit the .cue shard.

# KING TODO map
# TODO:
# [ ] CREATE extension pgcrypto — required by PASETO token generation in CLERK
# [ ] CREATE extension "uuid-ossp" — UUID primary keys across all roles
# [ ] CREATE extension pg_trgm — trigram indexes for SMITH full-text search
# [ ] CREATE extension btree_gin — composite GIN indexes for CLERK audit logs
# [ ] CREATE DATABASE per role if multi-tenant:
#     db name read from var RICE_DB_NAME (default: rice)
#     owner: RICE_DB_USER — created here, password injected via SOPS
# [ ] CREATE SCHEMA per domain: smith, clerk, sage, bard, chief
#     each schema owned by its role service account
# [ ] CREATE ROLE per service: rice_web, rice_auth, rice_token, rice_database
#     GRANT CONNECT ON DATABASE to each role
#     GRANT USAGE ON SCHEMA to each role — principle of least privilege
# [ ] CREATE TABLE smith.events — NATS JetStream consumer offset tracking
#     columns: stream TEXT, consumer TEXT, seq BIGINT, updated_at TIMESTAMPTZ
# [ ] CREATE TABLE clerk.audit_log — immutable append-only audit trail
#     columns: id UUID, role TEXT, action TEXT, subject TEXT,
#              payload JSONB, sig TEXT, ts TIMESTAMPTZ
#     ROW SECURITY POLICY: SELECT only, no UPDATE/DELETE ever
# [ ] CREATE TABLE sage.vector_metadata — Qdrant point metadata mirror
#     columns: point_id UUID, collection TEXT, payload JSONB, indexed_at TIMESTAMPTZ
# [ ] CREATE TABLE chief.projects — .rice project registry
#     columns: name TEXT PRIMARY KEY, manifest_hash TEXT,
#              compiled_at TIMESTAMPTZ, status TEXT
# [ ] CREATE INDEX on all ts/updated_at columns — YugabyteDB LSM-aware
# [ ] SET timezone = 'UTC' globally — all timestamps UTC, never local
# [ ] all names (db, schema, role, table) read from CUE template vars —
#     RICE_DB_NAME, RICE_DB_USER, RICE_DB_SCHEMA_PREFIX — never hardcoded here

-- Placeholder init script for database bootstrap.

