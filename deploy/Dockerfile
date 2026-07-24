# Stage 1: Build the Astro site
FROM node:20-alpine AS builder

# Set working directory
WORKDIR /app

# Copy package files
COPY package.json package-lock.json* ./

# Install production dependencies only. --omit=dev skips @astrojs/check and
# its transitive git-hosted dependency (@emmetio/css-parser), which the
# cluster builder can't reliably fetch from GitHub — the static build
# (astro build) doesn't need the type-checker. The fetch-retry settings add
# resilience against flaky egress from the build node.
RUN npm ci --omit=dev --no-audit --no-fund \
      --fetch-retries=5 \
      --fetch-retry-mintimeout=20000 \
      --fetch-retry-maxtimeout=120000

# Copy the rest of the project
COPY . .

# Build the Astro site
RUN npm run build

# Stage 2: Serve the static site
FROM nginx:alpine

# Copy the built site from the builder stage
COPY --from=builder /app/dist /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Nginx will start automatically with its default command