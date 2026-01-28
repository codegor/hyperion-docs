---
applyTo: "**"
---

# Codebase Instructions
## Architecture Overview

**Hyperion Docs** is a documentation platform combining:
- **Next.js 15** with App Router for modern full-stack React development
- **Fumadocs v15** for beautiful MDX-based documentation generation
- **Kroki** Docker service for rendering code-based diagrams (PlantUML, Graphviz, Mermaid)
- **Turbo** monorepo orchestration with pnpm workspace

### Key Technologies
- **Node.js 22+**, **pnpm 10+** (required versions)
- **TypeScript 5.9** (strict mode enabled)
- **React 19** with `'use client'` directive for client components
- **TailwindCSS 3** for styling
- **Zod** for environment variable validation
- **React Flow** for interactive diagram viewer

### Monorepo Structure
```
.
├── turbo.json              # Turbo task orchestration config
├── pnpm-workspace.yaml     # pnpm monorepo declaration
├── docker-compose.dev.yml  # Dev environment (docs + Kroki)
├── scripts/                # Shell scripts for dev lifecycle
├── apps/
│   └── docs/               # Single Next.js 15 app
│       ├── content/docs/   # MDX documentation files
│       ├── diagrams/       # Diagram source files (.puml, .dot)
│       ├── openapi/        # OpenAPI YAML schemas
│       └── src/
│           ├── app/        # Next.js App Router (pages, API routes)
│           ├── components/ # React components (feature modules)
│           └── lib/        # Utilities, constants, API clients
```

---

## Feature Module Pattern

Each React component feature is organized as a **feature module** with a consistent structure. This enables clean imports, type safety, and maintainability.

### Standard Feature Structure
```
components/
├── feature-name/
│   ├── index.ts              # Barrel export (exports all public APIs)
│   ├── types.ts              # TypeScript interfaces
│   ├── constants.ts          # Static configuration
│   ├── component.tsx         # Main component(s)
│   ├── hooks/
│   │   ├── index.ts          # Barrel export
│   │   └── use-hook.ts       # Custom React hooks
│   ├── context/              # React Context (if needed)
│   ├── factories/            # Factory functions
│   ├── errors/               # Custom error classes
│   └── components/           # Subcomponents
```

### Example: Barrel Exports
```typescript
// apps/docs/src/components/diagram/index.ts
export { Diagram } from './diagram';
export { useSvgDiagramMarkup } from './hooks';
export type { DiagramParams } from './types';
```
This enables clean imports:
```typescript
import { Diagram, useSvgDiagramMarkup, type DiagramParams } from '@/components/diagram';
```

---

## Modal Launcher System

A type-safe, promise-based modal management system supporting multiple modals with subscriptions and custom error handling.

### How Modals Work

1. **Registration**: Components are registered globally via `useModal(YourComponent)`
2. **Subscription**: Changes broadcast to all subscribers via observer pattern
3. **Promise-based**: `modal.open()` returns `Promise<T>` that resolves when modal closes
4. **Type safety**: Props and return types inferred from component generics

### Basic Usage Example
```typescript
// Define your modal component
interface ConfirmModalProps {
  message: string;
}

function ConfirmModal({ message, close }: ConfirmModalProps & { close: (result: boolean) => void }) {
  return (
    <dialog>
      <p>{message}</p>
      <button onClick={() => close(true)}>Yes</button>
      <button onClick={() => close(false)}>No</button>
    </dialog>
  );
}

// Use the modal (any child component)
function App() {
  const confirmModal = useModal(ConfirmModal);

  const handleAction = async () => {
    try {
      const result = await confirmModal.open({ message: 'Continue?' });
      console.log('User chose:', result); // true or false
    } catch (error) {
      console.error('Modal error:', error);
    }
  };

  return <button onClick={handleAction}>Click me</button>;
}
```

### Key Implementation Files
- [store.ts](../../../apps/docs/src/components/modal-launcher/store.ts) — Singleton store with registry, subscriptions, and promise management
- [types.ts](../../../apps/docs/src/components/modal-launcher/types.ts) — Type definitions (ModalHandler, ModalState, generics)
- [use-modal.ts](../../../apps/docs/src/components/modal-launcher/hooks/use-modal.ts) — React hook integration

---

## Diagram System: Three Rendering Paths

Diagrams support multiple languages with **type-discriminated rendering**: client-side Mermaid or backend Kroki proxy.

### How It Works

**1. Type Discrimination** — Component accepts `DiagramParams` (discriminated union):
```typescript
// apps/docs/src/components/diagram/types.ts
type DiagramParams = MermaidParams | KrokiParams;
// MermaidParams: { lang: 'mermaid'; chart: string }
// KrokiParams: { lang: 'puml' | 'dot' | ...; path: string }
```

**2. Rendering Paths**
- **Mermaid** (`lang: 'mermaid'`): Dynamic client-side import via React, no backend needed
- **Kroki** (`lang: 'puml'`, `'dot'`, etc.): Backend proxy at `/api/diagram?lang=X&path=Y` returns SVG
- **Security**: Path traversal prevention, file inclusion validation, size limits

**3. API Route Security** — [diagram/route.ts](../../../apps/docs/src/app/api/diagram/route.ts)
```typescript
// Only allow files under BASE_DIR (diagrams/)
if (!fullPath.startsWith(BASE_DIR)) {
  throw new Error('Path outside allowlist');
}

// Resolve !include directives safely (prevents circular includes)
const resolved = await resolveIncludes(content, baseDir);

// Compress with pako, limit size
if (compressed.length > MAX_BYTES) throw new Error('Too large');
```

### Usage Example
```typescript
// apps/docs/src/components/diagram/diagram.tsx
<Diagram
  lang="mermaid"
  chart="graph TD; A-->B"
/>

<Diagram
  lang="puml"
  path="architecture.puml"
/>
```

---

## Type Safety Patterns

### `'use client'` Directive
All interactive components require the directive:
```typescript
'use client';
import { useState } from 'react';
```
This distinguishes client-rendered components from server components (default in App Router).

### Environment Validation (Zod)
```typescript
// apps/docs/src/env.ts
const SERVER_ENV = () => createEnv(SERVER_ENV_SCHEMA, {
  KROKI_BASE_URL: process.env.KROKI_BASE_URL ?? '',
});

// Type-safe access on server only:
const env = SERVER_ENV(); // throws if validation fails
```

### Discriminated Unions
```typescript
type DiagramParams = MermaidParams | KrokiParams;
// Type narrows by 'lang' property automatically
if (params.lang === 'mermaid') {
  // params.chart is guaranteed to exist
}
```

---

## Custom Error Classes

Located in `errors/` folders within feature modules. Examples:
- `ModalNotFoundError` — Modal not registered
- `ModalMaxLimitReachedError` — Too many modals open
- `ModalProviderNotFoundError` — Missing `<ModalProvider>`

---

## Critical Development Workflows

### Setup & Development
```bash
# One-command setup (installs Node deps, starts Docker)
./scripts/dev.sh --init

# Or step by step
pnpm install
pnpm dev  # Turbo task runner

# Stop services
pnpm stop
```

### Code Quality
```bash
pnpm lint          # Biome + ESLint
pnpm typecheck     # TypeScript type checking
```

### OpenAPI Documentation
```bash
pnpm build:api-doc  # Generates API documentation from apps/docs/api-doc-gen/*.yaml
# Output: apps/docs/content/docs/openapi/
```

### Docker & Kroki
The `docker-compose.dev.yml` provides:
- **docs** service (Next.js on port 3000)
- **kroki** service (diagram renderer on port 8000)

Set environment variables for development:
```
NEXT_PUBLIC_APP_URL=http://localhost:3000
KROKI_BASE_URL=http://kroki:8000  # Inside Docker, references kroki service
WATCHPACK_POLLING=true             # File watching in containers
```

---

## Key Files & Patterns

| Pattern | File | Purpose |
|---------|------|---------|
| Modal system | [modal-launcher/store.ts](../../../apps/docs/src/components/modal-launcher/store.ts) | Singleton registry, subscriptions, promises |
| Diagram rendering | [diagram/diagram.tsx](../../../apps/docs/src/components/diagram/diagram.tsx) | Component accepting type-discriminated params |
| API security | [api/diagram/route.ts](../../../apps/docs/src/app/api/diagram/route.ts) | Path validation, include resolution, compression |
| Type inference | [modal-launcher/types.ts](../../../apps/docs/src/components/modal-launcher/types.ts) | `InferComponentProps<T>`, `InferModalResult<T>` generics |
| Env validation | [src/env.ts](../../../apps/docs/src/env.ts) | Zod schemas, server/client split |
| Constants | [lib/constants.ts](../../../apps/docs/src/lib/constants.ts) | Language maps, supported languages, app-wide config |
