// Serveur MCP minimal sur stdio (JSON-RPC 2.0, un message JSON par ligne).
// Aucune dépendance : fonctionne avec Node 18+ (PC, Mac, Linux, Termux).

import readline from 'node:readline';

const PROTOCOL_VERSIONS = ['2025-06-18', '2025-03-26', '2024-11-05'];

export class ToolError extends Error {}

export function startServer({ name, version, instructions, tools }) {
  const byName = new Map(tools.map((t) => [t.name, t]));
  const out = (msg) => process.stdout.write(JSON.stringify(msg) + '\n');
  const log = (...a) => process.stderr.write(`[${name}] ${a.join(' ')}\n`);

  async function handle(msg) {
    const { id, method, params } = msg;
    const isRequest = id !== undefined && id !== null;
    try {
      let result;
      switch (method) {
        case 'initialize': {
          const asked = params?.protocolVersion;
          result = {
            protocolVersion: PROTOCOL_VERSIONS.includes(asked) ? asked : PROTOCOL_VERSIONS[0],
            capabilities: { tools: { listChanged: false } },
            serverInfo: { name, version },
            instructions,
          };
          break;
        }
        case 'ping':
          result = {};
          break;
        case 'tools/list':
          result = {
            tools: tools.map((t) => ({
              name: t.name,
              description: t.description,
              inputSchema: t.inputSchema,
              ...(t.annotations ? { annotations: t.annotations } : {}),
            })),
          };
          break;
        case 'tools/call': {
          const tool = byName.get(params?.name);
          if (!tool) throw Object.assign(new Error(`Outil inconnu : ${params?.name}`), { code: -32602 });
          try {
            const value = await tool.handler(params.arguments || {});
            const text = typeof value === 'string' ? value : JSON.stringify(value, null, 2);
            result = { content: [{ type: 'text', text }] };
          } catch (e) {
            if (!(e instanceof ToolError)) log('erreur', tool.name, e.stack || e);
            result = { content: [{ type: 'text', text: `Erreur : ${e.message}` }], isError: true };
          }
          break;
        }
        case 'resources/list':
          result = { resources: [] };
          break;
        case 'prompts/list':
          result = { prompts: [] };
          break;
        default:
          if (!isRequest) return; // notifications (initialized, cancelled…)
          throw Object.assign(new Error(`Méthode non prise en charge : ${method}`), { code: -32601 });
      }
      if (isRequest) out({ jsonrpc: '2.0', id, result });
    } catch (e) {
      if (isRequest) out({ jsonrpc: '2.0', id, error: { code: e.code || -32603, message: e.message } });
    }
  }

  const pending = new Set();
  const rl = readline.createInterface({ input: process.stdin });
  rl.on('line', (line) => {
    if (!line.trim()) return;
    let msg;
    try {
      msg = JSON.parse(line);
    } catch {
      out({ jsonrpc: '2.0', id: null, error: { code: -32700, message: 'JSON invalide' } });
      return;
    }
    for (const m of Array.isArray(msg) ? msg : [msg]) {
      const p = handle(m).finally(() => pending.delete(p));
      pending.add(p);
    }
  });
  // Fin de l'entrée : on termine les appels en cours avant de quitter.
  rl.on('close', () => Promise.allSettled([...pending]).then(() => process.exit(0)));
  log(`prêt (${tools.length} outils)`);
}
