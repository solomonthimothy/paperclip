FROM node:lts-trixie-slim AS base
RUN apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates curl git \
  && rm -rf /var/lib/apt/lists/*
RUN corepack enable

FROM base AS deps
WORKDIR /app
COPY package.json pnpm-workspace.yaml pnpm-lock.yaml .npmrc ./
COPY cli/package.json cli/
COPY server/package.json server/
COPY ui/package.json ui/
COPY packages/shared/package.json packages/shared/
COPY packages/db/package.json packages/db/
COPY packages/adapter-utils/package.json packages/adapter-utils/
COPY packages/adapters/claude-local/package.json packages/adapters/claude-local/
COPY packages/adapters/codex-local/package.json packages/adapters/codex-local/
COPY packages/adapters/cursor-local/package.json packages/adapters/cursor-local/
COPY packages/adapters/gemini-local/package.json packages/adapters/gemini-local/
COPY packages/adapters/openclaw-gateway/package.json packages/adapters/openclaw-gateway/
COPY packages/adapters/opencode-local/package.json packages/adapters/opencode-local/
COPY packages/adapters/pi-local/package.json packages/adapters/pi-local/
COPY packages/plugins/sdk/package.json packages/plugins/sdk/
COPY patches/ patches/

RUN pnpm install --frozen-lockfile

FROM base AS build
WORKDIR /app
COPY --from=deps /app /app
COPY . .
RUN pnpm --filter @paperclipai/ui build
RUN pnpm --filter @paperclipai/plugin-sdk build
RUN pnpm --filter @paperclipai/server build
RUN test -f server/dist/index.js || (echo "ERROR: server build output missing" && exit 1)

FROM base AS production
WORKDIR /app
COPY --chown=node:node --from=build /app /app
RUN npm install --global --omit=dev @anthropic-ai/claude-code@latest @openai/codex@latest opencode-ai \
  && mkdir -p /paperclip \
  && chown node:node /paperclip

ENV NODE_ENV=production \
  HOME=/paperclip \
  HOST=0.0.0.0 \
  PORT=3100 \
  SERVE_UI=true \
  PAPERCLIP_HOME=/paperclip \
  PAPERCLIP_INSTANCE_ID=default \
  PAPERCLIP_CONFIG=/paperclip/instances/default/config.json \
  PAPERCLIP_DEPLOYMENT_MODE=authenticated \
  PAPERCLIP_DEPLOYMENT_EXPOSURE=private

EXPOSE 3100
CMD ["sh", "-c", "mkdir -p /paperclip/instances/default/logs /paperclip/instances/default/db /paperclip/instances/default/data && node -e 'const crypto=require(\"crypto\");const postgres=require(\"/app/node_modules/.pnpm/postgres@3.4.8/node_modules/postgres/cjs/src/index.js\");(async()=>{const sql=postgres(process.env.DATABASE_URL);const token=\"pcp_bootstrap_\"+crypto.randomBytes(24).toString(\"hex\");const hash=crypto.createHash(\"sha256\").update(token).digest(\"hex\");const exp=new Date(Date.now()+72*3600000);try{await sql`INSERT INTO invites(invite_type,token_hash,allowed_join_types,expires_at,invited_by_user_id) VALUES(${\"bootstrap_ceo\"},${hash},${\"human\"},${exp},${\"system\"})`;console.log(\"INVITE URL: \"+(process.env.PAPERCLIP_PUBLIC_URL||\"http://localhost:3100\")+\"/invite/\"+token)}catch(e){console.log(\"Bootstrap:\",e.message)}await sql.end()})()' 2>&1 || true; exec node --import ./server/node_modules/tsx/dist/loader.mjs server/dist/index.js"]
