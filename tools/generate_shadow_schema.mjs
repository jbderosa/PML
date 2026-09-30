#!/usr/bin/env node
/**
 * Generate the encrypted PostgreSQL staging schema used by the v2.8 shadow import.
 *
 * This tool consumes only the sanitized header manifest. It never reads live
 * deployment state. Every source cell must be application ciphertext before it
 * is persisted. Plaintext may exist only transiently inside the importer process.
 */

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(here, "..");
const manifestPath = path.join(repoRoot, "db", "source-schema-manifest.json");

const manifest = JSON.parse(fs.readFileSync(manifestPath, "utf8"));

function assertIdentifier(value, kind) {
  if (typeof value !== "string" || !/^[A-Za-z_][A-Za-z0-9_]*$/.test(value)) {
    throw new Error(`Invalid ${kind} identifier: ${JSON.stringify(value)}`);
  }
}

function q(value) {
  assertIdentifier(value, "SQL");
  return `"${value.replaceAll('"', '""')}"`;
}

function validateTable(name, columns) {
  assertIdentifier(name, "table");
  if (!Array.isArray(columns) || columns.length === 0) {
    throw new Error(`Table ${name} has no columns`);
  }
  const seen = new Set();
  for (const column of columns) {
    assertIdentifier(column, "column");
    if (seen.has(column)) throw new Error(`Duplicate column ${name}.${column}`);
    seen.add(column);
  }
}

const tables = {
  ...manifest.active_tables,
  ...manifest.archive_tables,
};

for (const [name, columns] of Object.entries(tables)) {
  validateTable(name, columns);
}

const out = [];
out.push("-- Generated from db/source-schema-manifest.json.");
out.push("-- Encrypted staging only: every persisted source cell must be enc:v1 ciphertext.");
out.push("-- Plaintext is permitted only transiently inside the importer process.");
out.push("BEGIN;");
out.push("CREATE SCHEMA IF NOT EXISTS pml_import;");
out.push("");
out.push(`CREATE TABLE IF NOT EXISTS pml_import.import_batches (
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
);`);
out.push("");

for (const [name, columns] of Object.entries(tables)) {
  const defs = [
    "batch_id uuid NOT NULL REFERENCES pml_import.import_batches(batch_id) ON DELETE RESTRICT",
    "source_row bigint NOT NULL CHECK (source_row >= 2)",
    ...columns.map((column) =>
      `${q(column)} text NOT NULL CHECK (${q(column)} LIKE 'enc:v1:%')`
    ),
    "row_hmac char(64) NOT NULL CHECK (row_hmac ~ '^[0-9a-f]{64}$')",
    "PRIMARY KEY (batch_id, source_row)",
  ];

  out.push(`CREATE TABLE IF NOT EXISTS pml_import.${q(name)} (`);
  out.push("  " + defs.join(",\n  "));
  out.push(");");
  out.push(`CREATE INDEX IF NOT EXISTS ${q(`idx_${name}_batch`)} ON pml_import.${q(name)} (batch_id);`);
  out.push("");
}

out.push("COMMIT;");
out.push("");

process.stdout.write(out.join("\n"));
