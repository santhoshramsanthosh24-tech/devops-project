# ============ Stage 1: Builder ============
FROM node:18-alpine AS builder

LABEL maintainer="DevOps Team"
LABEL description="Multi-stage Docker build for Enterprise DevOps CI/CD Application"

WORKDIR /build

# Copy package files
COPY app/package*.json ./

# Install dependencies with fallback
RUN npm install --legacy-peer-deps --production || npm install --production && \
    npm cache clean --force

# ============ Stage 2: Runtime ============
FROM node:18-alpine

# Install necessary tools
RUN apk add --no-cache curl

# Create app directory
WORKDIR /app

# Create non-root user for security
RUN addgroup appuser && \
    adduser -D -G appuser appuser

# Copy node_modules from builder
COPY --from=builder --chown=appuser:appuser /build/node_modules ./node_modules

# Copy application code
COPY --chown=appuser:appuser app/src ./src
COPY --chown=appuser:appuser app/package*.json ./

# Create logs directory
RUN mkdir -p logs && chown appuser:appuser logs

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

# Start application (no dumb-init needed)
CMD ["node", "src/index.js"]

# Build metadata
ARG BUILD_DATE
ARG VCS_REF
ARG VERSION=1.0.0

LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.name="devops-cicd-app" \
      org.label-schema.description="Enterprise DevOps CI/CD Application" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.version=$VERSION \
      org.label-schema.schema-version="1.0"
