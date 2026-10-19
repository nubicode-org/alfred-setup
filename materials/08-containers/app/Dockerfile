# syntax=docker/dockerfile:1

# Build stage: install and test with the full toolchain. Nothing from here ships except what is copied.
FROM node:24-alpine AS build
WORKDIR /src
COPY package.json ./
RUN npm install --omit=dev --no-audit --no-fund
COPY server.js server.test.js ./
RUN npm test

# Runtime stage: only the app, as a non-root user, on a small base.
FROM node:24-alpine
ENV NODE_ENV=production PORT=8080
WORKDIR /app
COPY --from=build --chown=node:node /src/package.json /src/server.js ./
USER node
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD wget -qO- http://127.0.0.1:8080/healthz || exit 1
# The exec form: node is PID 1 and receives docker stop's SIGTERM directly, with no shell in between.
CMD ["node", "server.js"]
