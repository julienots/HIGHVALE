// Lecture d’archives ZIP (APK) sans dépendance.

import fs from 'node:fs';
import zlib from 'node:zlib';

export function readZip(file) {
  const buf = fs.readFileSync(file);
  let eocd = -1;
  for (let i = buf.length - 22; i >= Math.max(0, buf.length - 65557); i--) {
    if (buf.readUInt32LE(i) === 0x06054b50) { eocd = i; break; }
  }
  if (eocd < 0) throw new Error('Archive ZIP invalide (pas un APK ?)');
  const count = buf.readUInt16LE(eocd + 10);
  const cdOffset = buf.readUInt32LE(eocd + 16);
  const entries = [];
  let p = cdOffset;
  for (let i = 0; i < count; i++) {
    if (buf.readUInt32LE(p) !== 0x02014b50) break;
    const method = buf.readUInt16LE(p + 10);
    const csize = buf.readUInt32LE(p + 20);
    const usize = buf.readUInt32LE(p + 24);
    const nlen = buf.readUInt16LE(p + 28);
    const elen = buf.readUInt16LE(p + 30);
    const clen = buf.readUInt16LE(p + 32);
    const offset = buf.readUInt32LE(p + 42);
    const name = buf.toString('utf8', p + 46, p + 46 + nlen);
    entries.push({ name, method, csize, usize, offset });
    p += 46 + nlen + elen + clen;
  }
  const sigBlock = cdOffset >= 16 && buf.toString('latin1', cdOffset - 16, cdOffset) === 'APK Sig Block 42';
  return {
    buf,
    entries,
    hasV2Signature: sigBlock,
    get(name) {
      const e = entries.find((x) => x.name === name);
      if (!e) return null;
      const nlen = buf.readUInt16LE(e.offset + 26);
      const elen = buf.readUInt16LE(e.offset + 28);
      const start = e.offset + 30 + nlen + elen;
      const data = buf.subarray(start, start + e.csize);
      return e.method === 0 ? data : zlib.inflateRawSync(data);
    },
  };
}
