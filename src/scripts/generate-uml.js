#!/usr/bin/env node
/*
 Generates a Mermaid ER diagram from Prisma schemas in src/schemas.
 Output: src/diagrams/db.mmd
*/
const fs = require('fs');
const path = require('path');
const { getSchema } = require('@mrleebo/prisma-ast');

const ROOT = path.resolve(__dirname, '..');
const SCHEMAS_DIR = path.join(ROOT, 'schemas');
const OUT_DIR = path.join(ROOT, 'diagrams');
const OUT_FILE = path.join(OUT_DIR, 'db.mmd');

function readPrismaFiles(dir) {
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  return entries
    .filter((e) => e.isFile() && e.name.endsWith('.prisma'))
    .map((e) => ({ name: e.name, content: fs.readFileSync(path.join(dir, e.name), 'utf8') }));
}

function getModelsAndEnums(ast) {
  const models = new Map();
  const enums = new Map();
  for (const decl of ast.list) {
    if (decl.type === 'model') {
      const fields = decl.properties.filter((p) => p.type === 'field');
      const model = {
        name: decl.name,
        fields: fields.map((f) => ({
          name: f.name,
          type: f.fieldType,
          isArray: !!f.array,
          attributes: f.attributes || [],
          isId: (f.attributes || []).some((a) => a.name === 'id'),
          isUnique: (f.attributes || []).some((a) => a.name === 'unique' || a.name === 'unique'),
        })),
      };
      models.set(decl.name, model);
    } else if (decl.type === 'enum') {
      enums.set(decl.name, decl);
    }
  }
  return { models, enums };
}

function isModelType(typeName, models) {
  return models.has(typeName);
}

function toMermaidFieldType(t) {
  const map = {
    String: 'string',
    Int: 'int',
    BigInt: 'int',
    Float: 'float',
    Decimal: 'float',
    Boolean: 'bool',
    DateTime: 'datetime',
    Json: 'json',
    Bytes: 'bytes',
  };
  return map[t] || t;
}

function generateMermaid(models) {
  const lines = ['erDiagram'];

  // Build relation hints
  // relations: key = A::B (A has field referencing B)
  const relationHints = [];
  for (const [modelName, model] of models) {
    for (const f of model.fields) {
      if (isModelType(f.type, models)) {
        const hint = {
          from: modelName,
          to: f.type,
          fromIsArray: f.isArray,
        };
        relationHints.push(hint);
      }
    }
  }

  // Build entities
  for (const [modelName, model] of models) {
    lines.push(`  ${modelName} {`);
    for (const f of model.fields) {
      if (isModelType(f.type, models)) continue; // skip relation fields in entity property list
      const type = toMermaidFieldType(f.type) + (f.isArray ? '[]' : '');
      const marker = f.isId ? ' PK' : (f.isUnique ? ' UK' : '');
      lines.push(`    ${type} ${f.name}${marker}`);
    }
    lines.push('  }');
  }

  // Derive cardinalities
  // For each pair (A,B), if both A->B (array) and B->A (array) => many-to-many }o--o{
  // If A->B (array) and not B->A (array) => one-to-many A ||--o{ B
  // If A->B (scalar relation) and not B->A (array) => many-to-one A }o--|| B
  // To avoid duplicates, canonicalize by building a map
  const arrMap = new Map(); // key: A->B boolean array
  const scalarMap = new Map(); // key: A->B scalar relation exists
  for (const h of relationHints) {
    const key = `${h.from}->${h.to}`;
    if (h.fromIsArray) arrMap.set(key, true);
    else scalarMap.set(key, true);
  }

  const emitted = new Set();
  function addEdge(a, b, relation) {
    const key = `${a}|${b}|${relation}`;
    if (emitted.has(key)) return;
    lines.push(`  ${a} ${relation} ${b} : relates`);
    emitted.add(key);
  }

  // Collect unique model pairs
  const modelsList = Array.from(models.keys());
  for (const A of modelsList) {
    for (const B of modelsList) {
      if (A === B) continue;
      const a2bArr = arrMap.has(`${A}->${B}`);
      const b2aArr = arrMap.has(`${B}->${A}`);
      const a2bScalar = scalarMap.has(`${A}->${B}`);
      const b2aScalar = scalarMap.has(`${B}->${A}`);

      if (a2bArr && b2aArr) {
        addEdge(A, B, '}o--o{');
      } else if (a2bArr) {
        addEdge(A, B, '||--o{');
      } else if (b2aArr) {
        addEdge(A, B, '}o--||');
      } else if (a2bScalar && b2aScalar) {
        // ambiguous one-to-one
        addEdge(A, B, '||--||');
      } else if (a2bScalar) {
        addEdge(A, B, '}o--||');
      } else if (b2aScalar) {
        addEdge(A, B, '||--o{'); // inverse perspective
      }
    }
  }

  return lines.join('\n');
}

function main() {
  const files = readPrismaFiles(SCHEMAS_DIR);
  if (files.length === 0) {
    console.error('No .prisma files found in', SCHEMAS_DIR);
    process.exit(1);
  }

  // Merge ASTs from all files
  const combinedAst = { list: [] };
  for (const file of files) {
    const ast = getSchema(file.content);
    combinedAst.list.push(...ast.list);
  }

  const { models } = getModelsAndEnums(combinedAst);
  if (models.size === 0) {
    console.error('No models found in schemas');
    process.exit(1);
  }

  const mermaid = generateMermaid(models);
  fs.mkdirSync(OUT_DIR, { recursive: true });
  fs.writeFileSync(OUT_FILE, mermaid, 'utf8');
  console.log(`Mermaid ER diagram written to: ${path.relative(process.cwd(), OUT_FILE)}`);
}

main();
