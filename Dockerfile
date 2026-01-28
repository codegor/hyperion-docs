FROM node:22-alpine

WORKDIR /app

RUN corepack enable && corepack prepare pnpm@latest --activate

# Copy workspace configuration files
COPY pnpm-workspace.yaml pnpm-lock.yaml package.json turbo.json ./
COPY .npmrc ./ 2>/dev/null || true

# Copy all apps
COPY apps/ ./apps/

# Ensure required directories exist for mounted volumes
RUN mkdir -p /app/apps/docs/arch/diagrams /app/apps/docs/api-doc-gen && \
    chmod -R 755 /app/apps/docs

RUN pnpm install --frozen-lockfile

EXPOSE 3000
ENV PORT=3000

RUN pnpm build:api-doc

# Start dev server
# pnpm turbo dev --filter=docs
CMD ["pnpm", "turbo", "dev", "--filter=docs"]
