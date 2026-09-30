#!/usr/bin/env node

import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import {
  canonicalRow,
  cellAad,
  decryptCell,
  encodeSnapshot,
  encodeTable,
  parseKey,
  sha256Hex,
  stableJson,
} from "./shadow_snapshot_codec.mjs";

const here=path.dirname(fileURLToPath(import.meta.url));
const manifest=JSON.parse(fs.readFileSync(path.resolve(here,"..","db","source-schema-manifest.json"),"utf8"));
const tables={...manifest.active_tables,...manifest.archive_tables};
const encKey=Buffer.alloc(32,0x11);
const hmacKey=Buffer.alloc(32,0x22);

function emptySnapshot(){
  return {
    tables:Object.fromEntries(
      Object.entries(tables).map(([name,headers])=>[name,{headers:[...headers],rows:[]}])
    ),
  };
}

const snapshot=emptySnapshot();
snapshot.tables.config.rows=[["EXAMPLE_KEY","EXAMPLE_VALUE"]];
const encoded1=encodeSnapshot({
  manifest,
  snapshot,
  encryptionKey:encKey,
  digestKey:hmacKey,
  encryptionKeyId:"synthetic-enc-key",
  digestKeyId:"synthetic-hmac-key",
});
const encoded2=encodeSnapshot({
  manifest,
  snapshot,
  encryptionKey:encKey,
  digestKey:hmacKey,
  encryptionKeyId:"synthetic-enc-key",
  digestKeyId:"synthetic-hmac-key",
});

assert.equal(encoded1.format,"pml-shadow-snapshot/v1");
assert.equal(Object.keys(encoded1.tables).length,Object.keys(tables).length);
assert.equal(encoded1.source_table_counts.config,1);
assert.equal(encoded1.tables.config.rows[0].source_row,2);
assert.match(encoded1.tables.config.rows[0].row_hmac,/^[0-9a-f]{64}$/);
assert.equal(encoded1.tables.config.table_hmac,encoded2.tables.config.table_hmac);
assert.equal(encoded1.tables.config.rows[0].row_hmac,encoded2.tables.config.rows[0].row_hmac);
assert.notEqual(
  encoded1.tables.config.rows[0].cells.value,
  encoded2.tables.config.rows[0].cells.value,
  "fresh IVs should make ciphertext differ across encodes"
);

for(const [column,token] of Object.entries(encoded1.tables.config.rows[0].cells)){
  assert.ok(token.startsWith("enc:v1:"));
  const decoded=decryptCell(
    token,
    encKey,
    cellAad({
      schemaVersion:manifest.source_schema_version,
      manifestSha256:encoded1.manifest_sha256,
      table:"config",
      sourceRow:2,
      column,
    })
  );
  if(column==="key") assert.deepEqual(decoded,{t:"s",v:"EXAMPLE_KEY"});
  if(column==="value") assert.deepEqual(decoded,{t:"s",v:"EXAMPLE_VALUE"});
  if(column==="note") assert.deepEqual(decoded,{t:"blank"});
}

const token=encoded1.tables.config.rows[0].cells.key;
assert.throws(()=>decryptCell(
  token,
  encKey,
  cellAad({
    schemaVersion:manifest.source_schema_version,
    manifestSha256:encoded1.manifest_sha256,
    table:"config",
    sourceRow:3,
    column:"key",
  })
));

const parts=token.split(":");
parts[4]=(parts[4].slice(0,-1)+(parts[4].endsWith("A")?"B":"A"));
assert.throws(()=>decryptCell(
  parts.join(":"),
  encKey,
  cellAad({
    schemaVersion:manifest.source_schema_version,
    manifestSha256:encoded1.manifest_sha256,
    table:"config",
    sourceRow:2,
    column:"key",
  })
));

assert.deepEqual(canonicalRow(["a","b"],["x"]),[{t:"s",v:"x"},{t:"blank"}]);
assert.throws(()=>canonicalRow(["a"],["x","y"]));

assert.throws(()=>encodeTable({
  table:"config",
  expectedHeaders:tables.config,
  actualHeaders:["wrong",...tables.config.slice(1)],
  rows:[],
  schemaVersion:manifest.source_schema_version,
  manifestSha256:sha256Hex(stableJson(manifest)),
  encryptionKey:encKey,
  digestKey:hmacKey,
}));

const missing=emptySnapshot();
delete missing.tables.config;
assert.throws(()=>encodeSnapshot({
  manifest,
  snapshot:missing,
  encryptionKey:encKey,
  digestKey:hmacKey,
  encryptionKeyId:"synthetic-enc-key",
  digestKeyId:"synthetic-hmac-key",
}));

assert.equal(parseKey(encKey.toString("base64"),"TEST_KEY").length,32);
assert.throws(()=>parseKey(Buffer.alloc(31).toString("base64"),"TEST_KEY"));

console.log("shadow_snapshot_codec synthetic tests: PASS");
