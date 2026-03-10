# Multi-stage build for React dashboard
# Production-optimized with security hardening

# ==================== Stage 1: Build ====================
FROM node:18-alpine AS builder

# Install build dependencies
RUN apk add --no-cache \
    python3 \
    make \
    g++

WORKDIR /app

# Copy package files
COPY package.json ./
COPY package-lock.json* ./

# Install dependencies
RUN npm ci --only=production --legacy-peer-deps && \
    npm cache clean --force

# Copy source code
COPY . .

# Build for production
RUN npm run build

# ==================== Stage 2: Production ====================
FROM nginx:1.25-alpine AS production

# Create non-root user
RUN addgroup -g 1000 dashboarduser && \
    adduser -D -u 1000 -G dashboarduser dashboarduser

# Copy built assets from builder
COPY --from=builder /app/dist /usr/share/nginx/html

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Set permissions
RUN chown -R dashboarduser:dashboarduser /usr/share/nginx/html && \
    chmod -R 755 /usr/share/nginx/html && \
    chown -R dashboarduser:dashboarduser /var/cache/nginx && \
    chown -R dashboarduser:dashboarduser /var/log/nginx && \
    touch /var/run/nginx.pid && \
    chown dashboarduser:dashboarduser /var/run/nginx.pid

# Security hardening
RUN rm -rf /usr/share/nginx/html/*.map

# Switch to non-root user
USER dashboarduser

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost:3000 || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
