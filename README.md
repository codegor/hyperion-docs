# Hyperion Docs

> Developer-first documentation stack with diagrams-as-code

A two-service monorepo combining **Fumadocs v15** (Next.js) for beautiful MDX documentation with **Kroki** for rendering diagrams from code. Built for developer experience with one-command setup and hot reload in Docker.

## Features

- 🎨 **Dark/Light Theme Support** - All diagrams adapt automatically
- 🔍 **Zoomable Diagrams** - Click any diagram to open in fullscreen with pan/zoom
- 🚀 **Hot Reload** - Edit MDX or components, see changes instantly
- 🔒 **Secure by Default** - Path traversal protection, size limits, language allowlist
- 📦 **One Command** - `./scripts/dev.sh` starts everything or if you have Node.js installed you can run `pnpm dev`
- 🎯 **Type-Safe** - TypeScript strict mode throughout

## Tech Stack

- **Node.js 22+** with **pnpm 10+**
- **Next.js 15** App Router with Turbopack
- **Fumadocs v15** for documentation UI
- **Turbo** for monorepo task orchestration
- **Kroki** for diagram rendering (PlantUML, Graphviz, etc.)
- **Mermaid** for inline diagrams
- **React Flow** for zoomable diagram viewer
- **TailwindCSS 4** for styling
- **TypeScript 5.9** in strict mode
- **Docker** & **Docker Compose** for containerization

## Quick Start

### Prerequisites

- Node.js 22+
- pnpm 10+
- Docker & Docker Compose v2
- Homebrew (for automated setup script)

### Installation

```bash
# Clone the repository
git clone <your-repo-url>

# Navigate to the project directory
cd hyperion-docs

# Option 1: One-command setup (installs dependencies & starts Docker)
./scripts/dev.sh

# Option 2: Manual setup
pnpm install  # Install dependencies
pnpm dev      # Start both services (docs + kroki)
```

Visit **http://localhost:3000** - changes hot-reload automatically!

### Stop Services

```bash
# Stop both services (docs + kroki)
pnpm stop

# or use the script
./scripts/stop.sh
```

## Project Structure

```
hyperion-docs/
├── apps/
│   └── docs/                    # Next.js + Fumadocs app
│       ├── src/
│       │   ├── app/             # Next.js App Router
│       │   │   ├── api/diagram/ # Diagram proxy API
│       │   │   ├── docs/        # Docs routes
│       │   │   ├── layout.tsx   # Root layout
│       │   │   └── page.tsx     # Home page
│       │   ├── components/      # React components
│       │   │   ├── diagram/     # Diagram rendering (Mermaid/Kroki)
│       │   │   ├── modal-launcher/ # Type-safe modal system
│       │   │   └── whiteboard/  # React Flow viewer
│       │   ├── lib/             # Utilities & constants
│       │   └── env.ts           # Environment validation (Zod)
│       ├── arch/
│       │   ├── content/docs/    # MDX documentation files
│       │   └── diagrams/        # Diagram source files (.puml, .dot)
│       ├── api-doc-gen/         # OpenAPI schema files (.yaml)
│       ├── scripts/             # Code generation scripts
│       ├── source.config.ts     # Fumadocs source config
│       └── Dockerfile           # Docs service Dockerfile
├── scripts/
│   ├── dev.sh                   # Development setup script
│   └── stop.sh                  # Stop services script
├── docker-compose.dev.yml       # Services orchestration
├── turbo.json                   # Turbo configuration
├── pnpm-workspace.yaml          # Monorepo config
└── package.json                 # Root scripts & tasks
```

## Usage

### Inline Mermaid Diagrams
arch/
```mdx
<Diagram lang="mermaid" chart="
graph TD;
  A[Client] --> B[Server];
  B --> C[Database];" />
```

### External Diagrams (PlantUML, Graphviz, etc.)

Place your diagram files in `apps/docs/diagrams/`:

```mdx
<Diagram lang="plantuml" path="erd.puml" alt="Entity Relationship Diagram" />
<Diagram lang="graphviz" path="flow.dot" alt="Processing Flow" />
```

### Supported Languages

- **PlantUML** - `puml`, `plantuml`
- **Graphviz** - `dot`, `graphviz`
- **Mermaid** - `mermaid` (or use `<Mermaid>` component)
- **C4 PlantUML** - `c4plantuml`

Easily extend by adding to `LANG_MAP` in `apps/docs/app/api/diagram/route.ts`.

## Architecture

### Flow

```
MDX File → <Diagram> Component → /api/diagram API Route → Kroki Service → SVG/PNG Response
```

### API Route (`/api/diagram`)

- **Runtime**: `nodejs` (required for `fs` access)
- **Security**: Path allowlist, size limits, language validation
- **Caching**: `Cache-Control: no-store` in dev

**Query Parameters**:
- `lang` - Diagram language (e.g., `puml`, `dot`)
- `path` - Relative path to diagram file
- `fmt` - Output format (`svg` or `png`, default: `svg`)

### Components


#### `<Diagram>`
- Fetches from `/api/diagram` or generates Mermaid diagrams directly from the chart string
- Opens modal on click
- Supports SVG

#### `<PreviewModal>`
- Whiteboard canvas
- Pan, zoom, reset controls

## Development

### Local Development (without Docker)

```bash
cd apps/docs
pnpm install
pnpm dev
```

> **Note**: You'll need to run Kroki separately or set `KROKI_BASE_URL` to a public instance.

### Adding New Diagram Types

1. Add language mapping to [apps/docs/src/app/api/diagram/route.ts](apps/docs/src/app/api/diagram/route.ts):
   ```ts
   const LANG_MAP: Record<string, string> = {
     // ...existing
     d2: 'd2',  // Add new type
   };
   ```

2. Create diagram files in `apps/docs/arch/diagrams/`

3. Use in MDX:
   ```mdx
   <Diagram lang="d2" path="my-diagram.d2" />
   ```

### Generating API Documentation

TailwindCSS 4 configuration is in [apps/docs/postcss.config.mjs](apps/docs/postcss.config.mjs). Override Fumadocs theme variables in [apps/docs/src/styles/globals.css](apps/docs/src/styles/globals.css)

```Key Features

### Modal Launcher System
Type-safe, promise-based modal management with:
- Global registration via `useModal(Component)`
- Promise-based API: `modal.open()` returns typed result
- Multiple concurrent modals with subscriptions
- Custom error classes for debugging

### Diagram Rendering
Three rendering paths with type discrimination:
- **Mermaid**: Client-side rendering (no backend needed)
- **Kroki**: Backend prox: `docker compose -f docker-compose.dev.yml ps`
2. Verify diagram file path is relative to `apps/docs/arch/diagrams`
3. Check browser console for API errors
4. Confirm language is in `LANG_MAP` in [route.ts](apps/docs/src/app/api/diagram/route.ts)
Zod-based validation for all environment variables with server/client split pattern.

## Security

- **Path Traversal**: All paths resolved relative to `apps/docs/arch/diagrams` and validated
- **File Size**: Max 256 KB per diagram file
- **Language Allowlist**: Only mapped languages accepted
- **No Code Execution**: Diagrams treated as opaque text sent to Kroki
- **Include Safety**: Circular include detection and path validation
### Customizing Styles

Edit `apps/docs/tailwind.config.ts` to customize Tailwind or override Fumadocs styles.

## Security

- **Path Traversal**: All paths resolved relative to `apps/docs/diagrams` and validated
- **File Size**: Max 256 KB per diagram file
- **Language Allowlist**: Only mapped languages accepted
- **No Code Execution**: Diagrams treated as opaque text sent to Kroki


## Troubleshooting

### Diagrams not rendering

1. Check Kroki is running
2. Verify diagram file path is relative to `apps/docs/diagrams`
3. Check browser console for API errors
4. Confirm language is in `LANG_MAP`

### TypeScript errors

```bash
cd apps/docs
pnpm typecheck
```

## License

MIT

## Contributing

1. Fork the repo
2. Create a feature branch
3. Make your changes
4. Submit a pull request

---

Built with ❤️ using Fumadocs, Next.js, and Kroki
