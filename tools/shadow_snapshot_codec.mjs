#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import {
  createCipheriv,
  createDecipheriv,
  createHash,
  createHmac,
  randomBytes,
} from "node:crypto";
import { fileURLToPath, pathToFileURL } from "node:url";

const here=path.dirname(fileURLToPath(import.meta.url));
const repoRoot=path.resolve(here,"..");

export function stableJson(value){
  if(Array.isArray(value)) return "["+value.map(stableJson).join(",")+"]";
  if(value && typeof value==="object"){
    return "{"+Object.keys(value).sort().map(k=>JSON.stringify(k)+":"+stableJson(value[k])).join(",")+"}";
  }
  return JSON.stringify(value);
}

export function sha256Hex(value){
  return createHash("sha256").update(value).digest("hex");
}

export function hmacHex(key,value){
  return createHmac("sha256",key).update(value).digest("hex");
}

export function parseKey(value,label){
  if(typeof value!=="string" || !value.trim()) throw new Error(`${label} is required`);
  const normalized=value.trim().replace(/-/g,"+").replace(/_/g,"/");
  const key=Buffer.from(normalized,"base64");
  if(key.length!==32) throw new Error(`${label} must decode to exactly 32 bytes`);
  return key;
}

export function canonicalCell(value){
  if(value===undefined || value===null) return {t:"blank"};
  if(typeof value==="string") return {t:"s",v:value};
  if(typeof value==="boolean") return {t:"b",v:value};
  if(typeof value==="number"){
    if(!Number.isFinite(value)) throw new Error("Non-finite numeric cell is not supported");
    return {t:"n",v:Object.is(value,-0)?"-0":String(value)};
  }
  throw new Error(`Unsupported cell type: ${typeof value}`);
}

export function canonicalRow(headers,row){
  if(!Array.isArray(headers) || headers.length===0) throw new Error("headers must be a non-empty array");
  if(!Array.isArray(row)) throw new Error("row must be an array");
  if(row.length>headers.length) throw new Error(`row has ${row.length} cells but header has ${headers.length}`);
  return headers.map((_,i)=>canonicalCell(i<row.length?row[i]:undefined));
}

export function cellAad({schemaVersion,manifestSha256,table,sourceRow,column}){
  return Buffer.from(
    `pml:v2.8:manifest=${manifestSha256}:schema=${schemaVersion}:table=${table}:row=${sourceRow}:column=${column}`,
    "utf8"
  );
}

export function encryptCell(cell,key,aad){
  const iv=randomBytes(12);
  const cipher=createCipheriv("aes-256-gcm",key,iv);
  cipher.setAAD(aad);
  const plaintext=Buffer.from(stableJson(cell),"utf8");
  const ciphertext=Buffer.concat([cipher.update(plaintext),cipher.final()]);
  const tag=cipher.getAuthTag();
  return ["enc","v1",iv.toString("base64url"),tag.toString("base64url"),ciphertext.toString("base64url")].join(":");
}

export function decryptCell(token,key,aad){
  if(typeof token!=="string" || !token.startsWith("enc:v1:")) throw new Error("Unsupported ciphertext envelope");
  const parts=token.split(":");
  if(parts.length!==5) throw new Error("Malformed ciphertext envelope");
  const iv=Buffer.from(parts[2],"base64url");
  const tag=Buffer.from(parts[3],"base64url");
  const ciphertext=Buffer.from(parts[4],"base64url");
  if(iv.length!==12 || tag.length!==16) throw new Error("Malformed AES-GCM parameters");
  const decipher=createDecipheriv("aes-256-gcm",key,iv);
  decipher.setAAD(aad);
  decipher.setAuthTag(tag);
  const plaintext=Buffer.concat([decipher.update(ciphertext),decipher.final()]).toString("utf8");
  return JSON.parse(plaintext);
}

export function validateHeaders(expected,actual,table){
  if(!Array.isArray(actual)) throw new Error(`${table}: headers missing`);
  if(expected.length!==actual.length || expected.some((h,i)=>h!==actual[i])){
    throw new Error(`${table}: header drift detected`);
  }
}

export function encodeTable({
  table,
  expectedHeaders,
  actualHeaders,
  rows,
  schemaVersion,
  manifestSha256,
  encryptionKey,
  digestKey,
}){
  validateHeaders(expectedHeaders,actualHeaders,table);
  if(!Array.isArray(rows)) throw new Error(`${table}: rows must be an array`);
  const encodedRows=[];
  for(let i=0;i<rows.length;i++){
    const sourceRow=i+2;
    const canonical=canonicalRow(expectedHeaders,rows[i]);
    const rowMaterial=stableJson({
      manifest_sha256:manifestSha256,
      schema_version:schemaVersion,
      table,
      source_row:sourceRow,
      cells:canonical,
    });
    const rowHmac=hmacHex(digestKey,rowMaterial);
    const cells={};
    for(let c=0;c<expectedHeaders.length;c++){
      const column=expectedHeaders[c];
      cells[column]=encryptCell(
        canonical[c],
        encryptionKey,
        cellAad({schemaVersion,manifestSha256,table,sourceRow,column})
      );
    }
    encodedRows.push({source_row:sourceRow,cells,row_hmac:rowHmac});
  }
  const tableMaterial=stableJson({
    manifest_sha256:manifestSha256,
    schema_version:schemaVersion,
    table,
    rows:encodedRows.map(r=>({source_row:r.source_row,row_hmac:r.row_hmac})),
  });
  return {
    headers:[...expectedHeaders],
    row_count:encodedRows.length,
    table_hmac:hmacHex(digestKey,tableMaterial),
    rows:encodedRows,
  };
}

export function encodeSnapshot({manifest,snapshot,encryptionKey,digestKey,encryptionKeyId,digestKeyId}){
  const tables={...manifest.active_tables,...manifest.archive_tables};
  const supplied=snapshot?.tables;
  if(!supplied || typeof supplied!=="object" || Array.isArray(supplied)) throw new Error("snapshot.tables is required");
  const expectedNames=Object.keys(tables).sort();
  const actualNames=Object.keys(supplied).sort();
  if(stableJson(expectedNames)!==stableJson(actualNames)) throw new Error("snapshot table set does not match manifest");
  const manifestSha256=sha256Hex(stableJson(manifest));
  const encoded={};
  const counts={};
  const hmacs={};
  for(const table of expectedNames){
    const src=supplied[table];
    const result=encodeTable({
      table,
      expectedHeaders:tables[table],
      actualHeaders:src.headers,
      rows:src.rows,
      schemaVersion:manifest.source_schema_version,
      manifestSha256,
      encryptionKey,
      digestKey,
    });
    encoded[table]=result;
    counts[table]=result.row_count;
    hmacs[table]=result.table_hmac;
  }
  return {
    format:"pml-shadow-snapshot/v1",
    source_schema_version:manifest.source_schema_version,
    manifest_sha256:manifestSha256,
    encryption_key_id:encryptionKeyId,
    digest_key_id:digestKeyId,
    source_table_counts:counts,
    source_table_hmacs:hmacs,
    tables:encoded,
  };
}

function loadJson(file){
  return JSON.parse(fs.readFileSync(file,"utf8"));
}

async function main(){
  const input=process.argv[2];
  if(!input) throw new Error("usage: shadow_snapshot_codec.mjs <snapshot.json>");
  const manifest=loadJson(path.join(repoRoot,"db","source-schema-manifest.json"));
  const snapshot=loadJson(path.resolve(input));
  const encryptionKey=parseKey(process.env.PML_IMPORT_ENC_KEY_B64,"PML_IMPORT_ENC_KEY_B64");
  const digestKey=parseKey(process.env.PML_IMPORT_HMAC_KEY_B64,"PML_IMPORT_HMAC_KEY_B64");
  const encryptionKeyId=process.env.PML_IMPORT_ENC_KEY_ID;
  const digestKeyId=process.env.PML_IMPORT_HMAC_KEY_ID;
  if(!encryptionKeyId || !digestKeyId) throw new Error("key IDs are required");
  const encoded=encodeSnapshot({manifest,snapshot,encryptionKey,digestKey,encryptionKeyId,digestKeyId});
  process.stdout.write(JSON.stringify(encoded)+"\n");
}

const invoked=process.argv[1] && import.meta.url===pathToFileURL(path.resolve(process.argv[1])).href;
if(invoked){
  main().catch(err=>{
    process.stderr.write(`shadow snapshot codec failed: ${err.message}\n`);
    process.exitCode=1;
  });
}
