-- Generated from db/source-schema-manifest.json.
-- Encrypted staging only: every persisted source cell must be enc:v1 ciphertext.
-- Plaintext is permitted only transiently inside the importer process.
BEGIN;
CREATE SCHEMA IF NOT EXISTS pml_import;

CREATE TABLE IF NOT EXISTS pml_import.import_batches (
  batch_id uuid PRIMARY KEY,
  source_schema_version integer NOT NULL,
  source_snapshot_label text NOT NULL,
  manifest_sha256 char(64) NOT NULL,
  encryption_key_id text NOT NULL,
  digest_key_id text NOT NULL,
  claims_chain_head text,
  events_chain_head text,
  source_table_counts jsonb NOT NULL DEFAULT '{}'::jsonb,
  source_table_hmacs jsonb NOT NULL DEFAULT '{}'::jsonb,
  status text NOT NULL CHECK (status IN ('IMPORTING','IMPORTED','VERIFIED','REJECTED')),
  created_at timestamptz NOT NULL DEFAULT now(),
  verified_at timestamptz
);

CREATE TABLE IF NOT EXISTS pml_import."config" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "key" text NOT NULL CHECK ("key" LIKE 'enc:v1:%'),
  "value" text NOT NULL CHECK ("value" LIKE 'enc:v1:%'),
  "note" text NOT NULL CHECK ("note" LIKE 'enc:v1:%'),
  row_hmac char(64) NOT NULL CHECK (row_hmac ~ '^[0-9a-f]{64}$'),
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_config_batch" ON pml_import."config" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."operator_commands" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "command_id" text NOT NULL CHECK ("command_id" LIKE 'enc:v1:%'),
  "operation" text NOT NULL CHECK ("operation" LIKE 'enc:v1:%'),
  "review_packet_nonce" text NOT NULL CHECK ("review_packet_nonce" LIKE 'enc:v1:%'),
  "payload" text NOT NULL CHECK ("payload" LIKE 'enc:v1:%'),
  "key_id" text NOT NULL CHECK ("key_id" LIKE 'enc:v1:%'),
  "auth_sig" text NOT NULL CHECK ("auth_sig" LIKE 'enc:v1:%'),
  "status" text NOT NULL CHECK ("status" LIKE 'enc:v1:%'),
  "error" text NOT NULL CHECK ("error" LIKE 'enc:v1:%'),
  "created_at" text NOT NULL CHECK ("created_at" LIKE 'enc:v1:%'),
  "applied_at" text NOT NULL CHECK ("applied_at" LIKE 'enc:v1:%'),
  row_hmac char(64) NOT NULL CHECK (row_hmac ~ '^[0-9a-f]{64}$'),
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_operator_commands_batch" ON pml_import."operator_commands" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."peer_reviews" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "peer_review_id" text NOT NULL CHECK ("peer_review_id" LIKE 'enc:v1:%'),
  "row_id" text NOT NULL CHECK ("row_id" LIKE 'enc:v1:%'),
  "result_id" text NOT NULL CHECK ("result_id" LIKE 'enc:v1:%'),
  "producer_slot" text NOT NULL CHECK ("producer_slot" LIKE 'enc:v1:%'),
  "reviewer_slot" text NOT NULL CHECK ("reviewer_slot" LIKE 'enc:v1:%'),
  "verdict" text NOT NULL CHECK ("verdict" LIKE 'enc:v1:%'),
  "reason" text NOT NULL CHECK ("reason" LIKE 'enc:v1:%'),
  "created_at" text NOT NULL CHECK ("created_at" LIKE 'enc:v1:%'),
  row_hmac char(64) NOT NULL CHECK (row_hmac ~ '^[0-9a-f]{64}$'),
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_peer_reviews_batch" ON pml_import."peer_reviews" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."review_packet" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "review_packet_nonce" text NOT NULL CHECK ("review_packet_nonce" LIKE 'enc:v1:%'),
  "rank" text NOT NULL CHECK ("rank" LIKE 'enc:v1:%'),
  "row_id" text NOT NULL CHECK ("row_id" LIKE 'enc:v1:%'),
  "result_id" text NOT NULL CHECK ("result_id" LIKE 'enc:v1:%'),
  "priority" text NOT NULL CHECK ("priority" LIKE 'enc:v1:%'),
  "risk_score" text NOT NULL CHECK ("risk_score" LIKE 'enc:v1:%'),
  "reasons" text NOT NULL CHECK ("reasons" LIKE 'enc:v1:%'),
  "provisional_verdict" text NOT NULL CHECK ("provisional_verdict" LIKE 'enc:v1:%'),
  "dependency_fanout" text NOT NULL CHECK ("dependency_fanout" LIKE 'enc:v1:%'),
  "created_at" text NOT NULL CHECK ("created_at" LIKE 'enc:v1:%'),
  row_hmac char(64) NOT NULL CHECK (row_hmac ~ '^[0-9a-f]{64}$'),
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_review_packet_batch" ON pml_import."review_packet" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."script_budget" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "job_class" text NOT NULL CHECK ("job_class" LIKE 'enc:v1:%'),
  "minutes_per_day" text NOT NULL CHECK ("minutes_per_day" LIKE 'enc:v1:%'),
  "priority" text NOT NULL CHECK ("priority" LIKE 'enc:v1:%'),
  "min_floor" text NOT NULL CHECK ("min_floor" LIKE 'enc:v1:%'),
  "enabled" text NOT NULL CHECK ("enabled" LIKE 'enc:v1:%'),
  "note" text NOT NULL CHECK ("note" LIKE 'enc:v1:%'),
  row_hmac char(64) NOT NULL CHECK (row_hmac ~ '^[0-9a-f]{64}$'),
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_script_budget_batch" ON pml_import."script_budget" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."script_runtime" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "runtime_id" text NOT NULL CHECK ("runtime_id" LIKE 'enc:v1:%'),
  "kind" text NOT NULL CHECK ("kind" LIKE 'enc:v1:%'),
  "started_at" text NOT NULL CHECK ("started_at" LIKE 'enc:v1:%'),
  "ended_at" text NOT NULL CHECK ("ended_at" LIKE 'enc:v1:%'),
  "duration_ms" text NOT NULL CHECK ("duration_ms" LIKE 'enc:v1:%'),
  "status" text NOT NULL CHECK ("status" LIKE 'enc:v1:%'),
  "note" text NOT NULL CHECK ("note" LIKE 'enc:v1:%'),
  row_hmac char(64) NOT NULL CHECK (row_hmac ~ '^[0-9a-f]{64}$'),
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_script_runtime_batch" ON pml_import."script_runtime" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."packets" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "packet_id" text NOT NULL CHECK ("packet_id" LIKE 'enc:v1:%'),
  "slot" text NOT NULL CHECK ("slot" LIKE 'enc:v1:%'),
  "doc_id" text NOT NULL CHECK ("doc_id" LIKE 'enc:v1:%'),
  "packet_nonce" text NOT NULL CHECK ("packet_nonce" LIKE 'enc:v1:%'),
  "header_hash" text NOT NULL CHECK ("header_hash" LIKE 'enc:v1:%'),
  "assignment_json" text NOT NULL CHECK ("assignment_json" LIKE 'enc:v1:%'),
  "status" text NOT NULL CHECK ("status" LIKE 'enc:v1:%'),
  "created_at" text NOT NULL CHECK ("created_at" LIKE 'enc:v1:%'),
  "expires_at" text NOT NULL CHECK ("expires_at" LIKE 'enc:v1:%'),
  "started_at" text NOT NULL CHECK ("started_at" LIKE 'enc:v1:%'),
  "completed_at" text NOT NULL CHECK ("completed_at" LIKE 'enc:v1:%'),
  "parse_note" text NOT NULL CHECK ("parse_note" LIKE 'enc:v1:%'),
  "worker_prompt_revision" text NOT NULL CHECK ("worker_prompt_revision" LIKE 'enc:v1:%'),
  "worker_generation" text NOT NULL CHECK ("worker_generation" LIKE 'enc:v1:%'),
  "policy_revision" text NOT NULL CHECK ("policy_revision" LIKE 'enc:v1:%'),
  row_hmac char(64) NOT NULL CHECK (row_hmac ~ '^[0-9a-f]{64}$'),
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_packets_batch" ON pml_import."packets" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."review_commands" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "command_id" text NOT NULL CHECK ("command_id" LIKE 'enc:v1:%'),
  "row_id" text NOT NULL CHECK ("row_id" LIKE 'enc:v1:%'),
  "result_id" text NOT NULL CHECK ("result_id" LIKE 'enc:v1:%'),
  "expected_row_version" text NOT NULL CHECK ("expected_row_version" LIKE 'enc:v1:%'),
  "review_packet_nonce" text NOT NULL CHECK ("review_packet_nonce" LIKE 'enc:v1:%'),
  "verdict" text NOT NULL CHECK ("verdict" LIKE 'enc:v1:%'),
  "note" text NOT NULL CHECK ("note" LIKE 'enc:v1:%'),
  "rework_action" text NOT NULL CHECK ("rework_action" LIKE 'enc:v1:%'),
  "key_id" text NOT NULL CHECK ("key_id" LIKE 'enc:v1:%'),
  "auth_sig" text NOT NULL CHECK ("auth_sig" LIKE 'enc:v1:%'),
  "status" text NOT NULL CHECK ("status" LIKE 'enc:v1:%'),
  "error" text NOT NULL CHECK ("error" LIKE 'enc:v1:%'),
  "created_at" text NOT NULL CHECK ("created_at" LIKE 'enc:v1:%'),
  "applied_at" text NOT NULL CHECK ("applied_at" LIKE 'enc:v1:%'),
  row_hmac char(64) NOT NULL CHECK (row_hmac ~ '^[0-9a-f]{64}$'),
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_review_commands_batch" ON pml_import."review_commands" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."priority_commands" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "command_id" text NOT NULL CHECK ("command_id" LIKE 'enc:v1:%'),
  "row_id" text NOT NULL CHECK ("row_id" LIKE 'enc:v1:%'),
  "expected_row_version" text NOT NULL CHECK ("expected_row_version" LIKE 'enc:v1:%'),
  "review_packet_nonce" text NOT NULL CHECK ("review_packet_nonce" LIKE 'enc:v1:%'),
  "priority" text NOT NULL CHECK ("priority" LIKE 'enc:v1:%'),
  "reason" text NOT NULL CHECK ("reason" LIKE 'enc:v1:%'),
  "key_id" text NOT NULL CHECK ("key_id" LIKE 'enc:v1:%'),
  "auth_sig" text NOT NULL CHECK ("auth_sig" LIKE 'enc:v1:%'),
  "status" text NOT NULL CHECK ("status" LIKE 'enc:v1:%'),
  "error" text NOT NULL CHECK ("error" LIKE 'enc:v1:%'),
  "created_at" text NOT NULL CHECK ("created_at" LIKE 'enc:v1:%'),
  "applied_at" text NOT NULL CHECK ("applied_at" LIKE 'enc:v1:%'),
  row_hmac char(64) NOT NULL CHECK (row_hmac ~ '^[0-9a-f]{64}$'),
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_priority_commands_batch" ON pml_import."priority_commands" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."config_commands" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "command_id" text NOT NULL CHECK ("command_id" LIKE 'enc:v1:%'),
  "key" text NOT NULL CHECK ("key" LIKE 'enc:v1:%'),
  "expected_value" text NOT NULL CHECK ("expected_value" LIKE 'enc:v1:%'),
  "review_packet_nonce" text NOT NULL CHECK ("review_packet_nonce" LIKE 'enc:v1:%'),
  "value" text NOT NULL CHECK ("value" LIKE 'enc:v1:%'),
  "reason" text NOT NULL CHECK ("reason" LIKE 'enc:v1:%'),
  "key_id" text NOT NULL CHECK ("key_id" LIKE 'enc:v1:%'),
  "auth_sig" text NOT NULL CHECK ("auth_sig" LIKE 'enc:v1:%'),
  "status" text NOT NULL CHECK ("status" LIKE 'enc:v1:%'),
  "error" text NOT NULL CHECK ("error" LIKE 'enc:v1:%'),
  "created_at" text NOT NULL CHECK ("created_at" LIKE 'enc:v1:%'),
  "applied_at" text NOT NULL CHECK ("applied_at" LIKE 'enc:v1:%'),
  row_hmac char(64) NOT NULL CHECK (row_hmac ~ '^[0-9a-f]{64}$'),
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_config_commands_batch" ON pml_import."config_commands" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."control" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "role" text NOT NULL CHECK ("role" LIKE 'enc:v1:%'),
  "next_action" text NOT NULL CHECK ("next_action" LIKE 'enc:v1:%'),
  "target" text NOT NULL CHECK ("target" LIKE 'enc:v1:%'),
  "reserved" text NOT NULL CHECK ("reserved" LIKE 'enc:v1:%'),
  "detail" text NOT NULL CHECK ("detail" LIKE 'enc:v1:%'),
  "computed_at" text NOT NULL CHECK ("computed_at" LIKE 'enc:v1:%'),
  row_hmac char(64) NOT NULL CHECK (row_hmac ~ '^[0-9a-f]{64}$'),
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_control_batch" ON pml_import."control" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."queue" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "row_id" text NOT NULL CHECK ("row_id" LIKE 'enc:v1:%'),
  "work_id" text NOT NULL CHECK ("work_id" LIKE 'enc:v1:%'),
  "kind" text NOT NULL CHECK ("kind" LIKE 'enc:v1:%'),
  "job" text NOT NULL CHECK ("job" LIKE 'enc:v1:%'),
  "params" text NOT NULL CHECK ("params" LIKE 'enc:v1:%'),
  "action" text NOT NULL CHECK ("action" LIKE 'enc:v1:%'),
  "policy" text NOT NULL CHECK ("policy" LIKE 'enc:v1:%'),
  "untrusted_data" text NOT NULL CHECK ("untrusted_data" LIKE 'enc:v1:%'),
  "untrusted_provenance" text NOT NULL CHECK ("untrusted_provenance" LIKE 'enc:v1:%'),
  "workflow_id" text NOT NULL CHECK ("workflow_id" LIKE 'enc:v1:%'),
  "semantic_owner" text NOT NULL CHECK ("semantic_owner" LIKE 'enc:v1:%'),
  "priority" text NOT NULL CHECK ("priority" LIKE 'enc:v1:%'),
  "size" text NOT NULL CHECK ("size" LIKE 'enc:v1:%'),
  "tier" text NOT NULL CHECK ("tier" LIKE 'enc:v1:%'),
  "template" text NOT NULL CHECK ("template" LIKE 'enc:v1:%'),
  "status" text NOT NULL CHECK ("status" LIKE 'enc:v1:%'),
  "executor" text NOT NULL CHECK ("executor" LIKE 'enc:v1:%'),
  "reserved_for" text NOT NULL CHECK ("reserved_for" LIKE 'enc:v1:%'),
  "reserved_rank" text NOT NULL CHECK ("reserved_rank" LIKE 'enc:v1:%'),
  "claim_token" text NOT NULL CHECK ("claim_token" LIKE 'enc:v1:%'),
  "claimed_at" text NOT NULL CHECK ("claimed_at" LIKE 'enc:v1:%'),
  "attempt" text NOT NULL CHECK ("attempt" LIKE 'enc:v1:%'),
  "result_doc_id" text NOT NULL CHECK ("result_doc_id" LIKE 'enc:v1:%'),
  "result_key" text NOT NULL CHECK ("result_key" LIKE 'enc:v1:%'),
  "outcome" text NOT NULL CHECK ("outcome" LIKE 'enc:v1:%'),
  "delivered_at" text NOT NULL CHECK ("delivered_at" LIKE 'enc:v1:%'),
  "review_note" text NOT NULL CHECK ("review_note" LIKE 'enc:v1:%'),
  "reviewed_at" text NOT NULL CHECK ("reviewed_at" LIKE 'enc:v1:%'),
  "integrity_hold" text NOT NULL CHECK ("integrity_hold" LIKE 'enc:v1:%'),
  "stale_note" text NOT NULL CHECK ("stale_note" LIKE 'enc:v1:%'),
  "schedule_id" text NOT NULL CHECK ("schedule_id" LIKE 'enc:v1:%'),
  "rework_of" text NOT NULL CHECK ("rework_of" LIKE 'enc:v1:%'),
  "context_ref" text NOT NULL CHECK ("context_ref" LIKE 'enc:v1:%'),
  "dedupe_key" text NOT NULL CHECK ("dedupe_key" LIKE 'enc:v1:%'),
  "idempotency_key" text NOT NULL CHECK ("idempotency_key" LIKE 'enc:v1:%'),
  "privacy_class" text NOT NULL CHECK ("privacy_class" LIKE 'enc:v1:%'),
  "waiting_on" text NOT NULL CHECK ("waiting_on" LIKE 'enc:v1:%'),
  "resume_condition" text NOT NULL CHECK ("resume_condition" LIKE 'enc:v1:%'),
  "legacy_source" text NOT NULL CHECK ("legacy_source" LIKE 'enc:v1:%'),
  "created_at" text NOT NULL CHECK ("created_at" LIKE 'enc:v1:%'),
  "row_version" text NOT NULL CHECK ("row_version" LIKE 'enc:v1:%'),
  "updated_at" text NOT NULL CHECK ("updated_at" LIKE 'enc:v1:%'),
  "packet_id" text NOT NULL CHECK ("packet_id" LIKE 'enc:v1:%'),
  "result_nonce" text NOT NULL CHECK ("result_nonce" LIKE 'enc:v1:%'),
  "source_result_ids" text NOT NULL CHECK ("source_result_ids" LIKE 'enc:v1:%'),
  "origin" text NOT NULL CHECK ("origin" LIKE 'enc:v1:%'),
  row_hmac char(64) NOT NULL CHECK (row_hmac ~ '^[0-9a-f]{64}$'),
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_queue_batch" ON pml_import."queue" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."claims" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "claim_event_id" text NOT NULL CHECK ("claim_event_id" LIKE 'enc:v1:%'),
  "row_id" text NOT NULL CHECK ("row_id" LIKE 'enc:v1:%'),
  "work_id" text NOT NULL CHECK ("work_id" LIKE 'enc:v1:%'),
  "executor" text NOT NULL CHECK ("executor" LIKE 'enc:v1:%'),
  "claim_token" text NOT NULL CHECK ("claim_token" LIKE 'enc:v1:%'),
  "claimed_at" text NOT NULL CHECK ("claimed_at" LIKE 'enc:v1:%'),
  "counted_at" text NOT NULL CHECK ("counted_at" LIKE 'enc:v1:%'),
  "claim_kind" text NOT NULL CHECK ("claim_kind" LIKE 'enc:v1:%'),
  "step_generation" text NOT NULL CHECK ("step_generation" LIKE 'enc:v1:%'),
  "source" text NOT NULL CHECK ("source" LIKE 'enc:v1:%'),
  "attempt" text NOT NULL CHECK ("attempt" LIKE 'enc:v1:%'),
  "prev_hash" text NOT NULL CHECK ("prev_hash" LIKE 'enc:v1:%'),
  "hash" text NOT NULL CHECK ("hash" LIKE 'enc:v1:%'),
  row_hmac char(64) NOT NULL CHECK (row_hmac ~ '^[0-9a-f]{64}$'),
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_claims_batch" ON pml_import."claims" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."inbox" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "inbox_id" text NOT NULL CHECK ("inbox_id" LIKE 'enc:v1:%'),
  "from_role" text NOT NULL CHECK ("from_role" LIKE 'enc:v1:%'),
  "type" text NOT NULL CHECK ("type" LIKE 'enc:v1:%'),
  "priority" text NOT NULL CHECK ("priority" LIKE 'enc:v1:%'),
  "summary" text NOT NULL CHECK ("summary" LIKE 'enc:v1:%'),
  "body" text NOT NULL CHECK ("body" LIKE 'enc:v1:%'),
  "untrusted" text NOT NULL CHECK ("untrusted" LIKE 'enc:v1:%'),
  "provenance" text NOT NULL CHECK ("provenance" LIKE 'enc:v1:%'),
  "status" text NOT NULL CHECK ("status" LIKE 'enc:v1:%'),
  "exec_note" text NOT NULL CHECK ("exec_note" LIKE 'enc:v1:%'),
  "dedupe_key" text NOT NULL CHECK ("dedupe_key" LIKE 'enc:v1:%'),
  "created_at" text NOT NULL CHECK ("created_at" LIKE 'enc:v1:%'),
  "updated_at" text NOT NULL CHECK ("updated_at" LIKE 'enc:v1:%'),
  row_hmac char(64) NOT NULL CHECK (row_hmac ~ '^[0-9a-f]{64}$'),
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_inbox_batch" ON pml_import."inbox" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."schedules" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "schedule_id" text NOT NULL CHECK ("schedule_id" LIKE 'enc:v1:%'),
  "enabled" text NOT NULL CHECK ("enabled" LIKE 'enc:v1:%'),
  "kind" text NOT NULL CHECK ("kind" LIKE 'enc:v1:%'),
  "job" text NOT NULL CHECK ("job" LIKE 'enc:v1:%'),
  "params" text NOT NULL CHECK ("params" LIKE 'enc:v1:%'),
  "action" text NOT NULL CHECK ("action" LIKE 'enc:v1:%'),
  "workflow_id" text NOT NULL CHECK ("workflow_id" LIKE 'enc:v1:%'),
  "priority" text NOT NULL CHECK ("priority" LIKE 'enc:v1:%'),
  "size" text NOT NULL CHECK ("size" LIKE 'enc:v1:%'),
  "tier" text NOT NULL CHECK ("tier" LIKE 'enc:v1:%'),
  "every_min" text NOT NULL CHECK ("every_min" LIKE 'enc:v1:%'),
  "next_due_at" text NOT NULL CHECK ("next_due_at" LIKE 'enc:v1:%'),
  "last_run_at" text NOT NULL CHECK ("last_run_at" LIKE 'enc:v1:%'),
  "notes" text NOT NULL CHECK ("notes" LIKE 'enc:v1:%'),
  row_hmac char(64) NOT NULL CHECK (row_hmac ~ '^[0-9a-f]{64}$'),
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_schedules_batch" ON pml_import."schedules" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."doorbells" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "ring_id" text NOT NULL CHECK ("ring_id" LIKE 'enc:v1:%'),
  "target" text NOT NULL CHECK ("target" LIKE 'enc:v1:%'),
  "subject" text NOT NULL CHECK ("subject" LIKE 'enc:v1:%'),
  "reason" text NOT NULL CHECK ("reason" LIKE 'enc:v1:%'),
  "transport" text NOT NULL CHECK ("transport" LIKE 'enc:v1:%'),
  "status" text NOT NULL CHECK ("status" LIKE 'enc:v1:%'),
  "created_at" text NOT NULL CHECK ("created_at" LIKE 'enc:v1:%'),
  "sent_at" text NOT NULL CHECK ("sent_at" LIKE 'enc:v1:%'),
  "error" text NOT NULL CHECK ("error" LIKE 'enc:v1:%'),
  row_hmac char(64) NOT NULL CHECK (row_hmac ~ '^[0-9a-f]{64}$'),
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_doorbells_batch" ON pml_import."doorbells" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."results" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "result_id" text NOT NULL CHECK ("result_id" LIKE 'enc:v1:%'),
  "row_id" text NOT NULL CHECK ("row_id" LIKE 'enc:v1:%'),
  "work_id" text NOT NULL CHECK ("work_id" LIKE 'enc:v1:%'),
  "kind" text NOT NULL CHECK ("kind" LIKE 'enc:v1:%'),
  "executor" text NOT NULL CHECK ("executor" LIKE 'enc:v1:%'),
  "result_doc_id" text NOT NULL CHECK ("result_doc_id" LIKE 'enc:v1:%'),
  "doc_id" text NOT NULL CHECK ("doc_id" LIKE 'enc:v1:%'),
  "result_text" text NOT NULL CHECK ("result_text" LIKE 'enc:v1:%'),
  "mech_check" text NOT NULL CHECK ("mech_check" LIKE 'enc:v1:%'),
  "mech_detail" text NOT NULL CHECK ("mech_detail" LIKE 'enc:v1:%'),
  "exec_verdict" text NOT NULL CHECK ("exec_verdict" LIKE 'enc:v1:%'),
  "result_key" text NOT NULL CHECK ("result_key" LIKE 'enc:v1:%'),
  "created_at" text NOT NULL CHECK ("created_at" LIKE 'enc:v1:%'),
  "provisional_verdict" text NOT NULL CHECK ("provisional_verdict" LIKE 'enc:v1:%'),
  "provisional_reason" text NOT NULL CHECK ("provisional_reason" LIKE 'enc:v1:%'),
  "provisional_by" text NOT NULL CHECK ("provisional_by" LIKE 'enc:v1:%'),
  "peer_review_at" text NOT NULL CHECK ("peer_review_at" LIKE 'enc:v1:%'),
  "manual_review_required" text NOT NULL CHECK ("manual_review_required" LIKE 'enc:v1:%'),
  "source_result_ids" text NOT NULL CHECK ("source_result_ids" LIKE 'enc:v1:%'),
  "packet_id" text NOT NULL CHECK ("packet_id" LIKE 'enc:v1:%'),
  "result_nonce" text NOT NULL CHECK ("result_nonce" LIKE 'enc:v1:%'),
  row_hmac char(64) NOT NULL CHECK (row_hmac ~ '^[0-9a-f]{64}$'),
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_results_batch" ON pml_import."results" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."py_state" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "state_key" text NOT NULL CHECK ("state_key" LIKE 'enc:v1:%'),
  "version" text NOT NULL CHECK ("version" LIKE 'enc:v1:%'),
  "value" text NOT NULL CHECK ("value" LIKE 'enc:v1:%'),
  "last_commit_key" text NOT NULL CHECK ("last_commit_key" LIKE 'enc:v1:%'),
  "updated_at" text NOT NULL CHECK ("updated_at" LIKE 'enc:v1:%'),
  row_hmac char(64) NOT NULL CHECK (row_hmac ~ '^[0-9a-f]{64}$'),
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_py_state_batch" ON pml_import."py_state" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."py_commits" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "commit_key" text NOT NULL CHECK ("commit_key" LIKE 'enc:v1:%'),
  "row_id" text NOT NULL CHECK ("row_id" LIKE 'enc:v1:%'),
  "status" text NOT NULL CHECK ("status" LIKE 'enc:v1:%'),
  "payload_hash" text NOT NULL CHECK ("payload_hash" LIKE 'enc:v1:%'),
  "payload" text NOT NULL CHECK ("payload" LIKE 'enc:v1:%'),
  "response" text NOT NULL CHECK ("response" LIKE 'enc:v1:%'),
  "created_at" text NOT NULL CHECK ("created_at" LIKE 'enc:v1:%'),
  "committed_at" text NOT NULL CHECK ("committed_at" LIKE 'enc:v1:%'),
  row_hmac char(64) NOT NULL CHECK (row_hmac ~ '^[0-9a-f]{64}$'),
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_py_commits_batch" ON pml_import."py_commits" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."runner_runs" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "run_id" text NOT NULL CHECK ("run_id" LIKE 'enc:v1:%'),
  "trigger" text NOT NULL CHECK ("trigger" LIKE 'enc:v1:%'),
  "started_at" text NOT NULL CHECK ("started_at" LIKE 'enc:v1:%'),
  "ended_at" text NOT NULL CHECK ("ended_at" LIKE 'enc:v1:%'),
  "duration_s" text NOT NULL CHECK ("duration_s" LIKE 'enc:v1:%'),
  "billed_minutes" text NOT NULL CHECK ("billed_minutes" LIKE 'enc:v1:%'),
  "processed" text NOT NULL CHECK ("processed" LIKE 'enc:v1:%'),
  "errors" text NOT NULL CHECK ("errors" LIKE 'enc:v1:%'),
  "more_pending" text NOT NULL CHECK ("more_pending" LIKE 'enc:v1:%'),
  "status" text NOT NULL CHECK ("status" LIKE 'enc:v1:%'),
  row_hmac char(64) NOT NULL CHECK (row_hmac ~ '^[0-9a-f]{64}$'),
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_runner_runs_batch" ON pml_import."runner_runs" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."doc_ledger" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "doc_event_id" text NOT NULL CHECK ("doc_event_id" LIKE 'enc:v1:%'),
  "doc_id" text NOT NULL CHECK ("doc_id" LIKE 'enc:v1:%'),
  "purpose" text NOT NULL CHECK ("purpose" LIKE 'enc:v1:%'),
  "row_id" text NOT NULL CHECK ("row_id" LIKE 'enc:v1:%'),
  "created_at" text NOT NULL CHECK ("created_at" LIKE 'enc:v1:%'),
  row_hmac char(64) NOT NULL CHECK (row_hmac ~ '^[0-9a-f]{64}$'),
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_doc_ledger_batch" ON pml_import."doc_ledger" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."exec_state" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "key" text NOT NULL CHECK ("key" LIKE 'enc:v1:%'),
  "value" text NOT NULL CHECK ("value" LIKE 'enc:v1:%'),
  "updated_at" text NOT NULL CHECK ("updated_at" LIKE 'enc:v1:%'),
  row_hmac char(64) NOT NULL CHECK (row_hmac ~ '^[0-9a-f]{64}$'),
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_exec_state_batch" ON pml_import."exec_state" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."events" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "event_id" text NOT NULL CHECK ("event_id" LIKE 'enc:v1:%'),
  "at" text NOT NULL CHECK ("at" LIKE 'enc:v1:%'),
  "type" text NOT NULL CHECK ("type" LIKE 'enc:v1:%'),
  "actor" text NOT NULL CHECK ("actor" LIKE 'enc:v1:%'),
  "row_id" text NOT NULL CHECK ("row_id" LIKE 'enc:v1:%'),
  "detail" text NOT NULL CHECK ("detail" LIKE 'enc:v1:%'),
  "prev_hash" text NOT NULL CHECK ("prev_hash" LIKE 'enc:v1:%'),
  "hash" text NOT NULL CHECK ("hash" LIKE 'enc:v1:%'),
  row_hmac char(64) NOT NULL CHECK (row_hmac ~ '^[0-9a-f]{64}$'),
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_events_batch" ON pml_import."events" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."migration_journal" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "entry_id" text NOT NULL CHECK ("entry_id" LIKE 'enc:v1:%'),
  "source_sheet" text NOT NULL CHECK ("source_sheet" LIKE 'enc:v1:%'),
  "source_row" text NOT NULL CHECK ("source_row" LIKE 'enc:v1:%'),
  "transform" text NOT NULL CHECK ("transform" LIKE 'enc:v1:%'),
  "version" text NOT NULL CHECK ("version" LIKE 'enc:v1:%'),
  "checksum" text NOT NULL CHECK ("checksum" LIKE 'enc:v1:%'),
  "at" text NOT NULL CHECK ("at" LIKE 'enc:v1:%'),
  row_hmac char(64) NOT NULL CHECK (row_hmac ~ '^[0-9a-f]{64}$'),
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_migration_journal_batch" ON pml_import."migration_journal" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."_shadow" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "row_id" text NOT NULL CHECK ("row_id" LIKE 'enc:v1:%'),
  "status" text NOT NULL CHECK ("status" LIKE 'enc:v1:%'),
  "work_id" text NOT NULL CHECK ("work_id" LIKE 'enc:v1:%'),
  "kind" text NOT NULL CHECK ("kind" LIKE 'enc:v1:%'),
  "job" text NOT NULL CHECK ("job" LIKE 'enc:v1:%'),
  "params_hash" text NOT NULL CHECK ("params_hash" LIKE 'enc:v1:%'),
  "action_hash" text NOT NULL CHECK ("action_hash" LIKE 'enc:v1:%'),
  "policy" text NOT NULL CHECK ("policy" LIKE 'enc:v1:%'),
  "untrusted_hash" text NOT NULL CHECK ("untrusted_hash" LIKE 'enc:v1:%'),
  "workflow_id" text NOT NULL CHECK ("workflow_id" LIKE 'enc:v1:%'),
  "template" text NOT NULL CHECK ("template" LIKE 'enc:v1:%'),
  "tier" text NOT NULL CHECK ("tier" LIKE 'enc:v1:%'),
  "size" text NOT NULL CHECK ("size" LIKE 'enc:v1:%'),
  "schedule_id" text NOT NULL CHECK ("schedule_id" LIKE 'enc:v1:%'),
  "executor" text NOT NULL CHECK ("executor" LIKE 'enc:v1:%'),
  "claim_token" text NOT NULL CHECK ("claim_token" LIKE 'enc:v1:%'),
  "claimed_at" text NOT NULL CHECK ("claimed_at" LIKE 'enc:v1:%'),
  "attempt" text NOT NULL CHECK ("attempt" LIKE 'enc:v1:%'),
  "result_doc_id" text NOT NULL CHECK ("result_doc_id" LIKE 'enc:v1:%'),
  "reserved_for" text NOT NULL CHECK ("reserved_for" LIKE 'enc:v1:%'),
  "reserved_rank" text NOT NULL CHECK ("reserved_rank" LIKE 'enc:v1:%'),
  "integrity_hold" text NOT NULL CHECK ("integrity_hold" LIKE 'enc:v1:%'),
  "delivered_at" text NOT NULL CHECK ("delivered_at" LIKE 'enc:v1:%'),
  "reviewed_at" text NOT NULL CHECK ("reviewed_at" LIKE 'enc:v1:%'),
  "packet_id" text NOT NULL CHECK ("packet_id" LIKE 'enc:v1:%'),
  "result_nonce" text NOT NULL CHECK ("result_nonce" LIKE 'enc:v1:%'),
  row_hmac char(64) NOT NULL CHECK (row_hmac ~ '^[0-9a-f]{64}$'),
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx__shadow_batch" ON pml_import."_shadow" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."packets_archive" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "packet_id" text NOT NULL CHECK ("packet_id" LIKE 'enc:v1:%'),
  "slot" text NOT NULL CHECK ("slot" LIKE 'enc:v1:%'),
  "doc_id" text NOT NULL CHECK ("doc_id" LIKE 'enc:v1:%'),
  "packet_nonce" text NOT NULL CHECK ("packet_nonce" LIKE 'enc:v1:%'),
  "header_hash" text NOT NULL CHECK ("header_hash" LIKE 'enc:v1:%'),
  "assignment_json" text NOT NULL CHECK ("assignment_json" LIKE 'enc:v1:%'),
  "status" text NOT NULL CHECK ("status" LIKE 'enc:v1:%'),
  "created_at" text NOT NULL CHECK ("created_at" LIKE 'enc:v1:%'),
  "expires_at" text NOT NULL CHECK ("expires_at" LIKE 'enc:v1:%'),
  "started_at" text NOT NULL CHECK ("started_at" LIKE 'enc:v1:%'),
  "completed_at" text NOT NULL CHECK ("completed_at" LIKE 'enc:v1:%'),
  "parse_note" text NOT NULL CHECK ("parse_note" LIKE 'enc:v1:%'),
  "worker_prompt_revision" text NOT NULL CHECK ("worker_prompt_revision" LIKE 'enc:v1:%'),
  "worker_generation" text NOT NULL CHECK ("worker_generation" LIKE 'enc:v1:%'),
  "policy_revision" text NOT NULL CHECK ("policy_revision" LIKE 'enc:v1:%'),
  row_hmac char(64) NOT NULL CHECK (row_hmac ~ '^[0-9a-f]{64}$'),
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_packets_archive_batch" ON pml_import."packets_archive" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."review_commands_archive" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "command_id" text NOT NULL CHECK ("command_id" LIKE 'enc:v1:%'),
  "row_id" text NOT NULL CHECK ("row_id" LIKE 'enc:v1:%'),
  "result_id" text NOT NULL CHECK ("result_id" LIKE 'enc:v1:%'),
  "expected_row_version" text NOT NULL CHECK ("expected_row_version" LIKE 'enc:v1:%'),
  "review_packet_nonce" text NOT NULL CHECK ("review_packet_nonce" LIKE 'enc:v1:%'),
  "verdict" text NOT NULL CHECK ("verdict" LIKE 'enc:v1:%'),
  "note" text NOT NULL CHECK ("note" LIKE 'enc:v1:%'),
  "rework_action" text NOT NULL CHECK ("rework_action" LIKE 'enc:v1:%'),
  "key_id" text NOT NULL CHECK ("key_id" LIKE 'enc:v1:%'),
  "auth_sig" text NOT NULL CHECK ("auth_sig" LIKE 'enc:v1:%'),
  "status" text NOT NULL CHECK ("status" LIKE 'enc:v1:%'),
  "error" text NOT NULL CHECK ("error" LIKE 'enc:v1:%'),
  "created_at" text NOT NULL CHECK ("created_at" LIKE 'enc:v1:%'),
  "applied_at" text NOT NULL CHECK ("applied_at" LIKE 'enc:v1:%'),
  row_hmac char(64) NOT NULL CHECK (row_hmac ~ '^[0-9a-f]{64}$'),
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_review_commands_archive_batch" ON pml_import."review_commands_archive" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."priority_commands_archive" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "command_id" text NOT NULL CHECK ("command_id" LIKE 'enc:v1:%'),
  "row_id" text NOT NULL CHECK ("row_id" LIKE 'enc:v1:%'),
  "expected_row_version" text NOT NULL CHECK ("expected_row_version" LIKE 'enc:v1:%'),
  "review_packet_nonce" text NOT NULL CHECK ("review_packet_nonce" LIKE 'enc:v1:%'),
  "priority" text NOT NULL CHECK ("priority" LIKE 'enc:v1:%'),
  "reason" text NOT NULL CHECK ("reason" LIKE 'enc:v1:%'),
  "key_id" text NOT NULL CHECK ("key_id" LIKE 'enc:v1:%'),
  "auth_sig" text NOT NULL CHECK ("auth_sig" LIKE 'enc:v1:%'),
  "status" text NOT NULL CHECK ("status" LIKE 'enc:v1:%'),
  "error" text NOT NULL CHECK ("error" LIKE 'enc:v1:%'),
  "created_at" text NOT NULL CHECK ("created_at" LIKE 'enc:v1:%'),
  "applied_at" text NOT NULL CHECK ("applied_at" LIKE 'enc:v1:%'),
  row_hmac char(64) NOT NULL CHECK (row_hmac ~ '^[0-9a-f]{64}$'),
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_priority_commands_archive_batch" ON pml_import."priority_commands_archive" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."config_commands_archive" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "command_id" text NOT NULL CHECK ("command_id" LIKE 'enc:v1:%'),
  "key" text NOT NULL CHECK ("key" LIKE 'enc:v1:%'),
  "expected_value" text NOT NULL CHECK ("expected_value" LIKE 'enc:v1:%'),
  "review_packet_nonce" text NOT NULL CHECK ("review_packet_nonce" LIKE 'enc:v1:%'),
  "value" text NOT NULL CHECK ("value" LIKE 'enc:v1:%'),
  "reason" text NOT NULL CHECK ("reason" LIKE 'enc:v1:%'),
  "key_id" text NOT NULL CHECK ("key_id" LIKE 'enc:v1:%'),
  "auth_sig" text NOT NULL CHECK ("auth_sig" LIKE 'enc:v1:%'),
  "status" text NOT NULL CHECK ("status" LIKE 'enc:v1:%'),
  "error" text NOT NULL CHECK ("error" LIKE 'enc:v1:%'),
  "created_at" text NOT NULL CHECK ("created_at" LIKE 'enc:v1:%'),
  "applied_at" text NOT NULL CHECK ("applied_at" LIKE 'enc:v1:%'),
  row_hmac char(64) NOT NULL CHECK (row_hmac ~ '^[0-9a-f]{64}$'),
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_config_commands_archive_batch" ON pml_import."config_commands_archive" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."operator_commands_archive" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "command_id" text NOT NULL CHECK ("command_id" LIKE 'enc:v1:%'),
  "operation" text NOT NULL CHECK ("operation" LIKE 'enc:v1:%'),
  "review_packet_nonce" text NOT NULL CHECK ("review_packet_nonce" LIKE 'enc:v1:%'),
  "payload" text NOT NULL CHECK ("payload" LIKE 'enc:v1:%'),
  "key_id" text NOT NULL CHECK ("key_id" LIKE 'enc:v1:%'),
  "auth_sig" text NOT NULL CHECK ("auth_sig" LIKE 'enc:v1:%'),
  "status" text NOT NULL CHECK ("status" LIKE 'enc:v1:%'),
  "error" text NOT NULL CHECK ("error" LIKE 'enc:v1:%'),
  "created_at" text NOT NULL CHECK ("created_at" LIKE 'enc:v1:%'),
  "applied_at" text NOT NULL CHECK ("applied_at" LIKE 'enc:v1:%'),
  row_hmac char(64) NOT NULL CHECK (row_hmac ~ '^[0-9a-f]{64}$'),
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_operator_commands_archive_batch" ON pml_import."operator_commands_archive" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."peer_reviews_archive" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "peer_review_id" text NOT NULL CHECK ("peer_review_id" LIKE 'enc:v1:%'),
  "row_id" text NOT NULL CHECK ("row_id" LIKE 'enc:v1:%'),
  "result_id" text NOT NULL CHECK ("result_id" LIKE 'enc:v1:%'),
  "producer_slot" text NOT NULL CHECK ("producer_slot" LIKE 'enc:v1:%'),
  "reviewer_slot" text NOT NULL CHECK ("reviewer_slot" LIKE 'enc:v1:%'),
  "verdict" text NOT NULL CHECK ("verdict" LIKE 'enc:v1:%'),
  "reason" text NOT NULL CHECK ("reason" LIKE 'enc:v1:%'),
  "created_at" text NOT NULL CHECK ("created_at" LIKE 'enc:v1:%'),
  row_hmac char(64) NOT NULL CHECK (row_hmac ~ '^[0-9a-f]{64}$'),
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_peer_reviews_archive_batch" ON pml_import."peer_reviews_archive" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."script_runtime_archive" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "runtime_id" text NOT NULL CHECK ("runtime_id" LIKE 'enc:v1:%'),
  "kind" text NOT NULL CHECK ("kind" LIKE 'enc:v1:%'),
  "started_at" text NOT NULL CHECK ("started_at" LIKE 'enc:v1:%'),
  "ended_at" text NOT NULL CHECK ("ended_at" LIKE 'enc:v1:%'),
  "duration_ms" text NOT NULL CHECK ("duration_ms" LIKE 'enc:v1:%'),
  "status" text NOT NULL CHECK ("status" LIKE 'enc:v1:%'),
  "note" text NOT NULL CHECK ("note" LIKE 'enc:v1:%'),
  row_hmac char(64) NOT NULL CHECK (row_hmac ~ '^[0-9a-f]{64}$'),
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_script_runtime_archive_batch" ON pml_import."script_runtime_archive" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."queue_archive" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "row_id" text NOT NULL CHECK ("row_id" LIKE 'enc:v1:%'),
  "work_id" text NOT NULL CHECK ("work_id" LIKE 'enc:v1:%'),
  "kind" text NOT NULL CHECK ("kind" LIKE 'enc:v1:%'),
  "job" text NOT NULL CHECK ("job" LIKE 'enc:v1:%'),
  "params" text NOT NULL CHECK ("params" LIKE 'enc:v1:%'),
  "action" text NOT NULL CHECK ("action" LIKE 'enc:v1:%'),
  "policy" text NOT NULL CHECK ("policy" LIKE 'enc:v1:%'),
  "untrusted_data" text NOT NULL CHECK ("untrusted_data" LIKE 'enc:v1:%'),
  "untrusted_provenance" text NOT NULL CHECK ("untrusted_provenance" LIKE 'enc:v1:%'),
  "workflow_id" text NOT NULL CHECK ("workflow_id" LIKE 'enc:v1:%'),
  "semantic_owner" text NOT NULL CHECK ("semantic_owner" LIKE 'enc:v1:%'),
  "priority" text NOT NULL CHECK ("priority" LIKE 'enc:v1:%'),
  "size" text NOT NULL CHECK ("size" LIKE 'enc:v1:%'),
  "tier" text NOT NULL CHECK ("tier" LIKE 'enc:v1:%'),
  "template" text NOT NULL CHECK ("template" LIKE 'enc:v1:%'),
  "status" text NOT NULL CHECK ("status" LIKE 'enc:v1:%'),
  "executor" text NOT NULL CHECK ("executor" LIKE 'enc:v1:%'),
  "reserved_for" text NOT NULL CHECK ("reserved_for" LIKE 'enc:v1:%'),
  "reserved_rank" text NOT NULL CHECK ("reserved_rank" LIKE 'enc:v1:%'),
  "claim_token" text NOT NULL CHECK ("claim_token" LIKE 'enc:v1:%'),
  "claimed_at" text NOT NULL CHECK ("claimed_at" LIKE 'enc:v1:%'),
  "attempt" text NOT NULL CHECK ("attempt" LIKE 'enc:v1:%'),
  "result_doc_id" text NOT NULL CHECK ("result_doc_id" LIKE 'enc:v1:%'),
  "result_key" text NOT NULL CHECK ("result_key" LIKE 'enc:v1:%'),
  "outcome" text NOT NULL CHECK ("outcome" LIKE 'enc:v1:%'),
  "delivered_at" text NOT NULL CHECK ("delivered_at" LIKE 'enc:v1:%'),
  "review_note" text NOT NULL CHECK ("review_note" LIKE 'enc:v1:%'),
  "reviewed_at" text NOT NULL CHECK ("reviewed_at" LIKE 'enc:v1:%'),
  "integrity_hold" text NOT NULL CHECK ("integrity_hold" LIKE 'enc:v1:%'),
  "stale_note" text NOT NULL CHECK ("stale_note" LIKE 'enc:v1:%'),
  "schedule_id" text NOT NULL CHECK ("schedule_id" LIKE 'enc:v1:%'),
  "rework_of" text NOT NULL CHECK ("rework_of" LIKE 'enc:v1:%'),
  "context_ref" text NOT NULL CHECK ("context_ref" LIKE 'enc:v1:%'),
  "dedupe_key" text NOT NULL CHECK ("dedupe_key" LIKE 'enc:v1:%'),
  "idempotency_key" text NOT NULL CHECK ("idempotency_key" LIKE 'enc:v1:%'),
  "privacy_class" text NOT NULL CHECK ("privacy_class" LIKE 'enc:v1:%'),
  "waiting_on" text NOT NULL CHECK ("waiting_on" LIKE 'enc:v1:%'),
  "resume_condition" text NOT NULL CHECK ("resume_condition" LIKE 'enc:v1:%'),
  "legacy_source" text NOT NULL CHECK ("legacy_source" LIKE 'enc:v1:%'),
  "created_at" text NOT NULL CHECK ("created_at" LIKE 'enc:v1:%'),
  "row_version" text NOT NULL CHECK ("row_version" LIKE 'enc:v1:%'),
  "updated_at" text NOT NULL CHECK ("updated_at" LIKE 'enc:v1:%'),
  "packet_id" text NOT NULL CHECK ("packet_id" LIKE 'enc:v1:%'),
  "result_nonce" text NOT NULL CHECK ("result_nonce" LIKE 'enc:v1:%'),
  "source_result_ids" text NOT NULL CHECK ("source_result_ids" LIKE 'enc:v1:%'),
  "origin" text NOT NULL CHECK ("origin" LIKE 'enc:v1:%'),
  row_hmac char(64) NOT NULL CHECK (row_hmac ~ '^[0-9a-f]{64}$'),
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_queue_archive_batch" ON pml_import."queue_archive" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."claims_archive" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "claim_event_id" text NOT NULL CHECK ("claim_event_id" LIKE 'enc:v1:%'),
  "row_id" text NOT NULL CHECK ("row_id" LIKE 'enc:v1:%'),
  "work_id" text NOT NULL CHECK ("work_id" LIKE 'enc:v1:%'),
  "executor" text NOT NULL CHECK ("executor" LIKE 'enc:v1:%'),
  "claim_token" text NOT NULL CHECK ("claim_token" LIKE 'enc:v1:%'),
  "claimed_at" text NOT NULL CHECK ("claimed_at" LIKE 'enc:v1:%'),
  "counted_at" text NOT NULL CHECK ("counted_at" LIKE 'enc:v1:%'),
  "claim_kind" text NOT NULL CHECK ("claim_kind" LIKE 'enc:v1:%'),
  "step_generation" text NOT NULL CHECK ("step_generation" LIKE 'enc:v1:%'),
  "source" text NOT NULL CHECK ("source" LIKE 'enc:v1:%'),
  "attempt" text NOT NULL CHECK ("attempt" LIKE 'enc:v1:%'),
  "prev_hash" text NOT NULL CHECK ("prev_hash" LIKE 'enc:v1:%'),
  "hash" text NOT NULL CHECK ("hash" LIKE 'enc:v1:%'),
  row_hmac char(64) NOT NULL CHECK (row_hmac ~ '^[0-9a-f]{64}$'),
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_claims_archive_batch" ON pml_import."claims_archive" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."inbox_archive" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "inbox_id" text NOT NULL CHECK ("inbox_id" LIKE 'enc:v1:%'),
  "from_role" text NOT NULL CHECK ("from_role" LIKE 'enc:v1:%'),
  "type" text NOT NULL CHECK ("type" LIKE 'enc:v1:%'),
  "priority" text NOT NULL CHECK ("priority" LIKE 'enc:v1:%'),
  "summary" text NOT NULL CHECK ("summary" LIKE 'enc:v1:%'),
  "body" text NOT NULL CHECK ("body" LIKE 'enc:v1:%'),
  "untrusted" text NOT NULL CHECK ("untrusted" LIKE 'enc:v1:%'),
  "provenance" text NOT NULL CHECK ("provenance" LIKE 'enc:v1:%'),
  "status" text NOT NULL CHECK ("status" LIKE 'enc:v1:%'),
  "exec_note" text NOT NULL CHECK ("exec_note" LIKE 'enc:v1:%'),
  "dedupe_key" text NOT NULL CHECK ("dedupe_key" LIKE 'enc:v1:%'),
  "created_at" text NOT NULL CHECK ("created_at" LIKE 'enc:v1:%'),
  "updated_at" text NOT NULL CHECK ("updated_at" LIKE 'enc:v1:%'),
  row_hmac char(64) NOT NULL CHECK (row_hmac ~ '^[0-9a-f]{64}$'),
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_inbox_archive_batch" ON pml_import."inbox_archive" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."doorbells_archive" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "ring_id" text NOT NULL CHECK ("ring_id" LIKE 'enc:v1:%'),
  "target" text NOT NULL CHECK ("target" LIKE 'enc:v1:%'),
  "subject" text NOT NULL CHECK ("subject" LIKE 'enc:v1:%'),
  "reason" text NOT NULL CHECK ("reason" LIKE 'enc:v1:%'),
  "transport" text NOT NULL CHECK ("transport" LIKE 'enc:v1:%'),
  "status" text NOT NULL CHECK ("status" LIKE 'enc:v1:%'),
  "created_at" text NOT NULL CHECK ("created_at" LIKE 'enc:v1:%'),
  "sent_at" text NOT NULL CHECK ("sent_at" LIKE 'enc:v1:%'),
  "error" text NOT NULL CHECK ("error" LIKE 'enc:v1:%'),
  row_hmac char(64) NOT NULL CHECK (row_hmac ~ '^[0-9a-f]{64}$'),
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_doorbells_archive_batch" ON pml_import."doorbells_archive" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."results_archive" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "result_id" text NOT NULL CHECK ("result_id" LIKE 'enc:v1:%'),
  "row_id" text NOT NULL CHECK ("row_id" LIKE 'enc:v1:%'),
  "work_id" text NOT NULL CHECK ("work_id" LIKE 'enc:v1:%'),
  "kind" text NOT NULL CHECK ("kind" LIKE 'enc:v1:%'),
  "executor" text NOT NULL CHECK ("executor" LIKE 'enc:v1:%'),
  "result_doc_id" text NOT NULL CHECK ("result_doc_id" LIKE 'enc:v1:%'),
  "doc_id" text NOT NULL CHECK ("doc_id" LIKE 'enc:v1:%'),
  "result_text" text NOT NULL CHECK ("result_text" LIKE 'enc:v1:%'),
  "mech_check" text NOT NULL CHECK ("mech_check" LIKE 'enc:v1:%'),
  "mech_detail" text NOT NULL CHECK ("mech_detail" LIKE 'enc:v1:%'),
  "exec_verdict" text NOT NULL CHECK ("exec_verdict" LIKE 'enc:v1:%'),
  "result_key" text NOT NULL CHECK ("result_key" LIKE 'enc:v1:%'),
  "created_at" text NOT NULL CHECK ("created_at" LIKE 'enc:v1:%'),
  "provisional_verdict" text NOT NULL CHECK ("provisional_verdict" LIKE 'enc:v1:%'),
  "provisional_reason" text NOT NULL CHECK ("provisional_reason" LIKE 'enc:v1:%'),
  "provisional_by" text NOT NULL CHECK ("provisional_by" LIKE 'enc:v1:%'),
  "peer_review_at" text NOT NULL CHECK ("peer_review_at" LIKE 'enc:v1:%'),
  "manual_review_required" text NOT NULL CHECK ("manual_review_required" LIKE 'enc:v1:%'),
  "source_result_ids" text NOT NULL CHECK ("source_result_ids" LIKE 'enc:v1:%'),
  "packet_id" text NOT NULL CHECK ("packet_id" LIKE 'enc:v1:%'),
  "result_nonce" text NOT NULL CHECK ("result_nonce" LIKE 'enc:v1:%'),
  row_hmac char(64) NOT NULL CHECK (row_hmac ~ '^[0-9a-f]{64}$'),
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_results_archive_batch" ON pml_import."results_archive" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."py_commits_archive" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "commit_key" text NOT NULL CHECK ("commit_key" LIKE 'enc:v1:%'),
  "row_id" text NOT NULL CHECK ("row_id" LIKE 'enc:v1:%'),
  "status" text NOT NULL CHECK ("status" LIKE 'enc:v1:%'),
  "payload_hash" text NOT NULL CHECK ("payload_hash" LIKE 'enc:v1:%'),
  "payload" text NOT NULL CHECK ("payload" LIKE 'enc:v1:%'),
  "response" text NOT NULL CHECK ("response" LIKE 'enc:v1:%'),
  "created_at" text NOT NULL CHECK ("created_at" LIKE 'enc:v1:%'),
  "committed_at" text NOT NULL CHECK ("committed_at" LIKE 'enc:v1:%'),
  row_hmac char(64) NOT NULL CHECK (row_hmac ~ '^[0-9a-f]{64}$'),
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_py_commits_archive_batch" ON pml_import."py_commits_archive" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."runner_runs_archive" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "run_id" text NOT NULL CHECK ("run_id" LIKE 'enc:v1:%'),
  "trigger" text NOT NULL CHECK ("trigger" LIKE 'enc:v1:%'),
  "started_at" text NOT NULL CHECK ("started_at" LIKE 'enc:v1:%'),
  "ended_at" text NOT NULL CHECK ("ended_at" LIKE 'enc:v1:%'),
  "duration_s" text NOT NULL CHECK ("duration_s" LIKE 'enc:v1:%'),
  "billed_minutes" text NOT NULL CHECK ("billed_minutes" LIKE 'enc:v1:%'),
  "processed" text NOT NULL CHECK ("processed" LIKE 'enc:v1:%'),
  "errors" text NOT NULL CHECK ("errors" LIKE 'enc:v1:%'),
  "more_pending" text NOT NULL CHECK ("more_pending" LIKE 'enc:v1:%'),
  "status" text NOT NULL CHECK ("status" LIKE 'enc:v1:%'),
  row_hmac char(64) NOT NULL CHECK (row_hmac ~ '^[0-9a-f]{64}$'),
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_runner_runs_archive_batch" ON pml_import."runner_runs_archive" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."doc_ledger_archive" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "doc_event_id" text NOT NULL CHECK ("doc_event_id" LIKE 'enc:v1:%'),
  "doc_id" text NOT NULL CHECK ("doc_id" LIKE 'enc:v1:%'),
  "purpose" text NOT NULL CHECK ("purpose" LIKE 'enc:v1:%'),
  "row_id" text NOT NULL CHECK ("row_id" LIKE 'enc:v1:%'),
  "created_at" text NOT NULL CHECK ("created_at" LIKE 'enc:v1:%'),
  row_hmac char(64) NOT NULL CHECK (row_hmac ~ '^[0-9a-f]{64}$'),
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_doc_ledger_archive_batch" ON pml_import."doc_ledger_archive" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."events_archive" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "event_id" text NOT NULL CHECK ("event_id" LIKE 'enc:v1:%'),
  "at" text NOT NULL CHECK ("at" LIKE 'enc:v1:%'),
  "type" text NOT NULL CHECK ("type" LIKE 'enc:v1:%'),
  "actor" text NOT NULL CHECK ("actor" LIKE 'enc:v1:%'),
  "row_id" text NOT NULL CHECK ("row_id" LIKE 'enc:v1:%'),
  "detail" text NOT NULL CHECK ("detail" LIKE 'enc:v1:%'),
  "prev_hash" text NOT NULL CHECK ("prev_hash" LIKE 'enc:v1:%'),
  "hash" text NOT NULL CHECK ("hash" LIKE 'enc:v1:%'),
  row_hmac char(64) NOT NULL CHECK (row_hmac ~ '^[0-9a-f]{64}$'),
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_events_archive_batch" ON pml_import."events_archive" (batch_id);

COMMIT;
