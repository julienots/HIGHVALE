import path from 'node:path';
import crypto from 'node:crypto';
import fs from 'node:fs';

const dataDir = path.resolve(process.env.DATA_DIR || './data');
fs.mkdirSync(dataDir, { recursive: true });

// Jeton d'accès : variable d'environnement, sinon généré une fois et gardé dans data/token.txt
let token = process.env.ACCESS_TOKEN;
if (!token) {
  const f = path.join(dataDir, 'token.txt');
  if (fs.existsSync(f)) token = fs.readFileSync(f, 'utf8').trim();
  else {
    token = crypto.randomBytes(18).toString('base64url');
    fs.writeFileSync(f, token);
  }
}

export const config = {
  port: Number(process.env.PORT || 8787),
  dataDir,
  token,
  // URL publique (ex. https://studio.mondomaine.fr). Sinon déduite de la requête.
  publicUrl: (process.env.PUBLIC_URL || '').replace(/\/$/, ''),
  maxUploadMb: Number(process.env.MAX_UPLOAD_MB || 4096),
  font: process.env.FONT_FILE || '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',
};
