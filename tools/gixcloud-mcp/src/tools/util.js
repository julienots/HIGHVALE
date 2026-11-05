export const S = {
  str: (description, extra = {}) => ({ type: 'string', description, ...extra }),
  int: (description, extra = {}) => ({ type: 'integer', description, ...extra }),
  bool: (description) => ({ type: 'boolean', description }),
  arr: (items, description) => ({ type: 'array', items, description }),
  enum: (values, description) => ({ type: 'string', enum: values, description }),
};

export const REPO = {
  owner: S.str('Propriétaire (facultatif, par défaut l’utilisateur local).'),
  repo: S.str('Nom du dépôt, ou « propriétaire/dépôt ».'),
};

export function tool(name, description, properties, required, handler, annotations) {
  return {
    name,
    description,
    inputSchema: { type: 'object', properties, required, additionalProperties: false },
    handler,
    ...(annotations ? { annotations } : {}),
  };
}

export const RO = { readOnlyHint: true };
export const DESTRUCTIVE = { destructiveHint: true };

export function clip(text, max = 200_000) {
  if (text.length <= max) return text;
  return text.slice(0, max) + `\n… (tronqué, ${text.length - max} caractères de plus)`;
}
