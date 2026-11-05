// Décodage du XML binaire Android (AndroidManifest.xml compilé dans un APK).

const ATTR_IDS = {
  0x01010003: 'name',
  0x01010001: 'label',
  0x01010002: 'icon',
  0x0101021b: 'versionCode',
  0x0101021c: 'versionName',
  0x0101020c: 'minSdkVersion',
  0x01010270: 'targetSdkVersion',
  0x01010271: 'maxSdkVersion',
  0x0101000f: 'debuggable',
  0x01010010: 'exported',
};

function readStringPool(buf, start) {
  const count = buf.readUInt32LE(start + 8);
  const flags = buf.readUInt32LE(start + 16);
  const stringsStart = buf.readUInt32LE(start + 20);
  const utf8 = (flags & 0x100) !== 0;
  const headerSize = buf.readUInt16LE(start + 2);
  const strings = [];
  for (let i = 0; i < count; i++) {
    const off = buf.readUInt32LE(start + headerSize + i * 4);
    let p = start + stringsStart + off;
    if (utf8) {
      let n = buf[p++];
      if (n & 0x80) p++;
      let len = buf[p++];
      if (len & 0x80) len = ((len & 0x7f) << 8) | buf[p++];
      strings.push(buf.toString('utf8', p, p + len));
    } else {
      let len = buf.readUInt16LE(p);
      p += 2;
      if (len & 0x8000) { len = ((len & 0x7fff) << 16) | buf.readUInt16LE(p); p += 2; }
      strings.push(buf.toString('utf16le', p, p + len * 2));
    }
  }
  return strings;
}

/** Renvoie une liste d’éléments { tag, depth, attrs }. */
export function parseAxml(buf) {
  if (buf.readUInt16LE(0) !== 0x0003) throw new Error('XML binaire Android invalide');
  let strings = [];
  let resIds = [];
  const elements = [];
  let depth = 0;
  let p = buf.readUInt16LE(2);
  while (p + 8 <= buf.length) {
    const type = buf.readUInt16LE(p);
    const size = buf.readUInt32LE(p + 4);
    if (size < 8) break;
    if (type === 0x0001) strings = readStringPool(buf, p);
    else if (type === 0x0180) {
      for (let i = 8; i < size; i += 4) resIds.push(buf.readUInt32LE(p + i));
    } else if (type === 0x0102) {
      const name = strings[buf.readUInt32LE(p + 20)];
      const attrStart = buf.readUInt16LE(p + 24);
      const attrSize = buf.readUInt16LE(p + 26) || 20;
      const attrCount = buf.readUInt16LE(p + 28);
      const attrs = {};
      for (let i = 0; i < attrCount; i++) {
        const a = p + 16 + attrStart + i * attrSize;
        const ni = buf.readUInt32LE(a + 4);
        const rid = resIds[ni];
        const an = ATTR_IDS[rid] || strings[ni] || (rid !== undefined ? `0x${rid.toString(16)}` : '');
        const raw = buf.readUInt32LE(a + 8);
        const dtype = buf[a + 15];
        const data = buf.readUInt32LE(a + 16);
        let v;
        if (raw !== 0xffffffff) v = strings[raw];
        else if (dtype === 0x03) v = strings[data];
        else if (dtype === 0x10) v = data | 0;
        else if (dtype === 0x11) v = `0x${data.toString(16)}`;
        else if (dtype === 0x12) v = data !== 0;
        else if (dtype === 0x01) v = `@0x${data.toString(16).padStart(8, '0')}`;
        else v = data;
        attrs[an || `attr${i}`] = v;
      }
      elements.push({ tag: name, depth, attrs });
      depth++;
    } else if (type === 0x0103) depth--;
    p += size;
  }
  return elements;
}

export function manifestSummary(buf) {
  const els = parseAxml(buf);
  const root = els.find((e) => e.tag === 'manifest') || { attrs: {} };
  const sdk = els.find((e) => e.tag === 'uses-sdk')?.attrs || {};
  const app = els.find((e) => e.tag === 'application')?.attrs || {};
  const activities = els.filter((e) => e.tag === 'activity' || e.tag === 'activity-alias');
  let launcher = null;
  for (let i = 0; i < els.length; i++) {
    if (els[i].tag === 'category' && els[i].attrs.name === 'android.intent.category.LAUNCHER') {
      for (let j = i; j >= 0; j--) if (els[j].tag === 'activity' || els[j].tag === 'activity-alias') { launcher = els[j].attrs.name; break; }
      break;
    }
  }
  return {
    package: root.attrs.package,
    versionCode: root.attrs.versionCode,
    versionName: root.attrs.versionName,
    minSdk: sdk.minSdkVersion,
    targetSdk: sdk.targetSdkVersion,
    debuggable: app.debuggable === true,
    label: app.label,
    launcherActivity: launcher,
    activities: activities.length,
    permissions: els.filter((e) => e.tag === 'uses-permission').map((e) => e.attrs.name),
  };
}
