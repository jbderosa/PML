-- Generated from db/source-schema-manifest.json.
-- Lossless staging only: source values remain TEXT until parity is proven.
BEGIN;
CREATE SCHEMA IF NOT EXISTS pml_import;

CREATE TABLE IF NOT EXISTS pml_import.import_batches (
  batch_id uuid PRIMARY KEY,
  source_schema_version integer NOT NULL,
  source_snapshot_label text NOT NULL,
  manifest_sha256 char(64) NOT NULL,
  claims_chain_head text,
  events_chain_head text,
  source_table_counts jsonb NOT NULL DEFAULT '{}'::jsonb,
  source_table_digests jsonb NOT NULL DEFAULT '{}'::jsonb,
  status text NOT NULL CHECK (status IN ('IMPORTING','IMPORTED','VERIFIED','REJECTED')),
  created_at timestamptz NOT NULL DEFAULT now(),
  verified_at timestamptz
);

CREATE TABLE IF NOT EXISTS pml_import."config" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "key" text,
  "value" text,
  "note" text,
  row_digest char(64) NOT NULL,
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_config_batch" ON pml_import."config" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."operator_commands" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "command_id" text,
  "operation" text,
  "review_packet_nonce" text,
  "payload" text,
  "key_id" text,
  "auth_sig" text,
  "status" text,
  "error" text,
  "created_at" text,
  "applied_at" text,
  row_digest char(64) NOT NULL,
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_operator_commands_batch" ON pml_import."operator_commands" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."peer_reviews" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "peer_review_id" text,
  "row_id" text,
  "result_id" text,
  "producer_slot" text,
  "reviewer_slot" text,
  "verdict" text,
  "reason" text,
  "created_at" text,
  row_digest char(64) NOT NULL,
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_peer_reviews_batch" ON pml_import."peer_reviews" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."review_packet" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "review_packet_nonce" text,
  "rank" text,
  "row_id" text,
  "result_id" text,
  "priority" text,
  "risk_score" text,
  "reasons" text,
  "provisional_verdict" text,
  "dependency_fanout" text,
  "created_at" text,
  row_digest char(64) NOT NULL,
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_review_packet_batch" ON pml_import."review_packet" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."script_budget" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "job_class" text,
  "minutes_per_day" text,
  "priority" text,
  "min_floor" text,
  "enabled" text,
  "note" text,
  row_digest char(64) NOT NULL,
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_script_budget_batch" ON pml_import."script_budget" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."script_runtime" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "runtime_id" text,
  "kind" text,
  "started_at" text,
  "ended_at" text,
  "duration_ms" text,
  "status" text,
  "note" text,
  row_digest char(64) NOT NULL,
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_script_runtime_batch" ON pml_import."script_runtime" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."packets" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "packet_id" text,
  "slot" text,
  "doc_id" text,
  "packet_nonce" text,
  "header_hash" text,
  "assignment_json" text,
  "status" text,
  "created_at" text,
  "expires_at" text,
  "started_at" text,
  "completed_at" text,
  "parse_note" text,
  "worker_prompt_revision" text,
  "worker_generation" text,
  "policy_revision" text,
  row_digest char(64) NOT NULL,
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_packets_batch" ON pml_import."packets" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."review_commands" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "command_id" text,
  "row_id" text,
  "result_id" text,
  "expected_row_version" text,
  "review_packet_nonce" text,
  "verdict" text,
  "note" text,
  "rework_action" text,
  "key_id" text,
  "auth_sig" text,
  "status" text,
  "error" text,
  "created_at" text,
  "applied_at" text,
  row_digest char(64) NOT NULL,
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_review_commands_batch" ON pml_import."review_commands" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."priority_commands" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "command_id" text,
  "row_id" text,
  "expected_row_version" text,
  "review_packet_nonce" text,
  "priority" text,
  "reason" text,
  "key_id" text,
  "auth_sig" text,
  "status" text,
  "error" text,
  "created_at" text,
  "applied_at" text,
  row_digest char(64) NOT NULL,
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_priority_commands_batch" ON pml_import."priority_commands" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."config_commands" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "command_id" text,
  "key" text,
  "expected_value" text,
  "review_packet_nonce" text,
  "value" text,
  "reason" text,
  "key_id" text,
  "auth_sig" text,
  "status" text,
  "error" text,
  "created_at" text,
  "applied_at" text,
  row_digest char(64) NOT NULL,
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_config_commands_batch" ON pml_import."config_commands" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."control" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "role" text,
  "next_action" text,
  "target" text,
  "reserved" text,
  "detail" text,
  "computed_at" text,
  row_digest char(64) NOT NULL,
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_control_batch" ON pml_import."control" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."queue" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "row_id" text,
  "work_id" text,
  "kind" text,
  "job" text,
  "params" text,
  "action" text,
  "policy" text,
  "untrusted_data" text,
  "untrusted_provenance" text,
  "workflow_id" text,
  "semantic_owner" text,
  "priority" text,
  "size" text,
  "tier" text,
  "template" text,
  "status" text,
  "executor" text,
  "reserved_for" text,
  "reserved_rank" text,
  "claim_token" text,
  "claimed_at" text,
  "attempt" text,
  "result_doc_id" text,
  "result_key" text,
  "outcome" text,
  "delivered_at" text,
  "review_note" text,
  "reviewed_at" text,
  "integrity_hold" text,
  "stale_note" text,
  "schedule_id" text,
  "rework_of" text,
  "context_ref" text,
  "dedupe_key" text,
  "idempotency_key" text,
  "privacy_class" text,
  "waiting_on" text,
  "resume_condition" text,
  "legacy_source" text,
  "created_at" text,
  "row_version" text,
  "updated_at" text,
  "packet_id" text,
  "result_nonce" text,
  "source_result_ids" text,
  "origin" text,
  row_digest char(64) NOT NULL,
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_queue_batch" ON pml_import."queue" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."claims" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "claim_event_id" text,
  "row_id" text,
  "work_id" text,
  "executor" text,
  "claim_token" text,
  "claimed_at" text,
  "counted_at" text,
  "claim_kind" text,
  "step_generation" text,
  "source" text,
  "attempt" text,
  "prev_hash" text,
  "hash" text,
  row_digest char(64) NOT NULL,
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_claims_batch" ON pml_import."claims" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."inbox" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "inbox_id" text,
  "from_role" text,
  "type" text,
  "priority" text,
  "summary" text,
  "body" text,
  "untrusted" text,
  "provenance" text,
  "status" text,
  "exec_note" text,
  "dedupe_key" text,
  "created_at" text,
  "updated_at" text,
  row_digest char(64) NOT NULL,
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_inbox_batch" ON pml_import."inbox" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."schedules" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "schedule_id" text,
  "enabled" text,
  "kind" text,
  "job" text,
  "params" text,
  "action" text,
  "workflow_id" text,
  "priority" text,
  "size" text,
  "tier" text,
  "every_min" text,
  "next_due_at" text,
  "last_run_at" text,
  "notes" text,
  row_digest char(64) NOT NULL,
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_schedules_batch" ON pml_import."schedules" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."doorbells" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "ring_id" text,
  "target" text,
  "subject" text,
  "reason" text,
  "transport" text,
  "status" text,
  "created_at" text,
  "sent_at" text,
  "error" text,
  row_digest char(64) NOT NULL,
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_doorbells_batch" ON pml_import."doorbells" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."results" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "result_id" text,
  "row_id" text,
  "work_id" text,
  "kind" text,
  "executor" text,
  "result_doc_id" text,
  "doc_id" text,
  "result_text" text,
  "mech_check" text,
  "mech_detail" text,
  "exec_verdict" text,
  "result_key" text,
  "created_at" text,
  "provisional_verdict" text,
  "provisional_reason" text,
  "provisional_by" text,
  "peer_review_at" text,
  "manual_review_required" text,
  "source_result_ids" text,
  "packet_id" text,
  "result_nonce" text,
  row_digest char(64) NOT NULL,
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_results_batch" ON pml_import."results" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."py_state" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "state_key" text,
  "version" text,
  "value" text,
  "last_commit_key" text,
  "updated_at" text,
  row_digest char(64) NOT NULL,
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_py_state_batch" ON pml_import."py_state" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."py_commits" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "commit_key" text,
  "row_id" text,
  "status" text,
  "payload_hash" text,
  "payload" text,
  "response" text,
  "created_at" text,
  "committed_at" text,
  row_digest char(64) NOT NULL,
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_py_commits_batch" ON pml_import."py_commits" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."runner_runs" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "run_id" text,
  "trigger" text,
  "started_at" text,
  "ended_at" text,
  "duration_s" text,
  "billed_minutes" text,
  "processed" text,
  "errors" text,
  "more_pending" text,
  "status" text,
  row_digest char(64) NOT NULL,
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_runner_runs_batch" ON pml_import."runner_runs" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."doc_ledger" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "doc_event_id" text,
  "doc_id" text,
  "purpose" text,
  "row_id" text,
  "created_at" text,
  row_digest char(64) NOT NULL,
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_doc_ledger_batch" ON pml_import."doc_ledger" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."exec_state" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "key" text,
  "value" text,
  "updated_at" text,
  row_digest char(64) NOT NULL,
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_exec_state_batch" ON pml_import."exec_state" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."events" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "event_id" text,
  "at" text,
  "type" text,
  "actor" text,
  "row_id" text,
  "detail" text,
  "prev_hash" text,
  "hash" text,
  row_digest char(64) NOT NULL,
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_events_batch" ON pml_import."events" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."migration_journal" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "entry_id" text,
  "source_sheet" text,
  "source_row" text,
  "transform" text,
  "version" text,
  "checksum" text,
  "at" text,
  row_digest char(64) NOT NULL,
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_migration_journal_batch" ON pml_import."migration_journal" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."_shadow" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "row_id" text,
  "status" text,
  "work_id" text,
  "kind" text,
  "job" text,
  "params_hash" text,
  "action_hash" text,
  "policy" text,
  "untrusted_hash" text,
  "workflow_id" text,
  "template" text,
  "tier" text,
  "size" text,
  "schedule_id" text,
  "executor" text,
  "claim_token" text,
  "claimed_at" text,
  "attempt" text,
  "result_doc_id" text,
  "reserved_for" text,
  "reserved_rank" text,
  "integrity_hold" text,
  "delivered_at" text,
  "reviewed_at" text,
  "packet_id" text,
  "result_nonce" text,
  row_digest char(64) NOT NULL,
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx__shadow_batch" ON pml_import."_shadow" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."packets_archive" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "packet_id" text,
  "slot" text,
  "doc_id" text,
  "packet_nonce" text,
  "header_hash" text,
  "assignment_json" text,
  "status" text,
  "created_at" text,
  "expires_at" text,
  "started_at" text,
  "completed_at" text,
  "parse_note" text,
  "worker_prompt_revision" text,
  "worker_generation" text,
  "policy_revision" text,
  row_digest char(64) NOT NULL,
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_packets_archive_batch" ON pml_import."packets_archive" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."review_commands_archive" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "command_id" text,
  "row_id" text,
  "result_id" text,
  "expected_row_version" text,
  "review_packet_nonce" text,
  "verdict" text,
  "note" text,
  "rework_action" text,
  "key_id" text,
  "auth_sig" text,
  "status" text,
  "error" text,
  "created_at" text,
  "applied_at" text,
  row_digest char(64) NOT NULL,
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_review_commands_archive_batch" ON pml_import."review_commands_archive" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."priority_commands_archive" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "command_id" text,
  "row_id" text,
  "expected_row_version" text,
  "review_packet_nonce" text,
  "priority" text,
  "reason" text,
  "key_id" text,
  "auth_sig" text,
  "status" text,
  "error" text,
  "created_at" text,
  "applied_at" text,
  row_digest char(64) NOT NULL,
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_priority_commands_archive_batch" ON pml_import."priority_commands_archive" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."config_commands_archive" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "command_id" text,
  "key" text,
  "expected_value" text,
  "review_packet_nonce" text,
  "value" text,
  "reason" text,
  "key_id" text,
  "auth_sig" text,
  "status" text,
  "error" text,
  "created_at" text,
  "applied_at" text,
  row_digest char(64) NOT NULL,
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_config_commands_archive_batch" ON pml_import."config_commands_archive" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."operator_commands_archive" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "command_id" text,
  "operation" text,
  "review_packet_nonce" text,
  "payload" text,
  "key_id" text,
  "auth_sig" text,
  "status" text,
  "error" text,
  "created_at" text,
  "applied_at" text,
  row_digest char(64) NOT NULL,
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_operator_commands_archive_batch" ON pml_import."operator_commands_archive" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."peer_reviews_archive" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "peer_review_id" text,
  "row_id" text,
  "result_id" text,
  "producer_slot" text,
  "reviewer_slot" text,
  "verdict" text,
  "reason" text,
  "created_at" text,
  row_digest char(64) NOT NULL,
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_peer_reviews_archive_batch" ON pml_import."peer_reviews_archive" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."script_runtime_archive" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "runtime_id" text,
  "kind" text,
  "started_at" text,
  "ended_at" text,
  "duration_ms" text,
  "status" text,
  "note" text,
  row_digest char(64) NOT NULL,
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_script_runtime_archive_batch" ON pml_import."script_runtime_archive" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."queue_archive" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "row_id" text,
  "work_id" text,
  "kind" text,
  "job" text,
  "params" text,
  "action" text,
  "policy" text,
  "untrusted_data" text,
  "untrusted_provenance" text,
  "workflow_id" text,
  "semantic_owner" text,
  "priority" text,
  "size" text,
  "tier" text,
  "template" text,
  "status" text,
  "executor" text,
  "reserved_for" text,
  "reserved_rank" text,
  "claim_token" text,
  "claimed_at" text,
  "attempt" text,
  "result_doc_id" text,
  "result_key" text,
  "outcome" text,
  "delivered_at" text,
  "review_note" text,
  "reviewed_at" text,
  "integrity_hold" text,
  "stale_note" text,
  "schedule_id" text,
  "rework_of" text,
  "context_ref" text,
  "dedupe_key" text,
  "idempotency_key" text,
  "privacy_class" text,
  "waiting_on" text,
  "resume_condition" text,
  "legacy_source" text,
  "created_at" text,
  "row_version" text,
  "updated_at" text,
  "packet_id" text,
  "result_nonce" text,
  "source_result_ids" text,
  "origin" text,
  row_digest char(64) NOT NULL,
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_queue_archive_batch" ON pml_import."queue_archive" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."claims_archive" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "claim_event_id" text,
  "row_id" text,
  "work_id" text,
  "executor" text,
  "claim_token" text,
  "claimed_at" text,
  "counted_at" text,
  "claim_kind" text,
  "step_generation" text,
  "source" text,
  "attempt" text,
  "prev_hash" text,
  "hash" text,
  row_digest char(64) NOT NULL,
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_claims_archive_batch" ON pml_import."claims_archive" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."inbox_archive" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "inbox_id" text,
  "from_role" text,
  "type" text,
  "priority" text,
  "summary" text,
  "body" text,
  "untrusted" text,
  "provenance" text,
  "status" text,
  "exec_note" text,
  "dedupe_key" text,
  "created_at" text,
  "updated_at" text,
  row_digest char(64) NOT NULL,
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_inbox_archive_batch" ON pml_import."inbox_archive" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."doorbells_archive" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "ring_id" text,
  "target" text,
  "subject" text,
  "reason" text,
  "transport" text,
  "status" text,
  "created_at" text,
  "sent_at" text,
  "error" text,
  row_digest char(64) NOT NULL,
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_doorbells_archive_batch" ON pml_import."doorbells_archive" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."results_archive" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "result_id" text,
  "row_id" text,
  "work_id" text,
  "kind" text,
  "executor" text,
  "result_doc_id" text,
  "doc_id" text,
  "result_text" text,
  "mech_check" text,
  "mech_detail" text,
  "exec_verdict" text,
  "result_key" text,
  "created_at" text,
  "provisional_verdict" text,
  "provisional_reason" text,
  "provisional_by" text,
  "peer_review_at" text,
  "manual_review_required" text,
  "source_result_ids" text,
  "packet_id" text,
  "result_nonce" text,
  row_digest char(64) NOT NULL,
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_results_archive_batch" ON pml_import."results_archive" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."py_commits_archive" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "commit_key" text,
  "row_id" text,
  "status" text,
  "payload_hash" text,
  "payload" text,
  "response" text,
  "created_at" text,
  "committed_at" text,
  row_digest char(64) NOT NULL,
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_py_commits_archive_batch" ON pml_import."py_commits_archive" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."runner_runs_archive" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "run_id" text,
  "trigger" text,
  "started_at" text,
  "ended_at" text,
  "duration_s" text,
  "billed_minutes" text,
  "processed" text,
  "errors" text,
  "more_pending" text,
  "status" text,
  row_digest char(64) NOT NULL,
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_runner_runs_archive_batch" ON pml_import."runner_runs_archive" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."doc_ledger_archive" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "doc_event_id" text,
  "doc_id" text,
  "purpose" text,
  "row_id" text,
  "created_at" text,
  row_digest char(64) NOT NULL,
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_doc_ledger_archive_batch" ON pml_import."doc_ledger_archive" (batch_id);

CREATE TABLE IF NOT EXISTS pml_import."events_archive" (
  batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT,
  source_row bigint NOT NULL CHECK (source_row >= 2),
  "event_id" text,
  "at" text,
  "type" text,
  "actor" text,
  "row_id" text,
  "detail" text,
  "prev_hash" text,
  "hash" text,
  row_digest char(64) NOT NULL,
  PRIMARY KEY (batch_id, source_row)
);
CREATE INDEX IF NOT EXISTS "idx_events_archive_batch" ON pml_import."events_archive" (batch_id);

COMMIT;
