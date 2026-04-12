import express from 'express';
import cors from 'cors';
import { createLogger, format, transports } from 'winston';
import { register, Counter, Histogram } from 'prom-client';
import 'dotenv/config';

const app = express();
const PORT = process.env.PORT || 3000;
const ENV = process.env.NODE_ENV || 'development';

// ============ Logging Configuration ============
const logger = createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: format.combine(
    format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
    format.json()
  ),
  transports: [
    new transports.Console(),
    new transports.File({ filename: 'logs/error.log', level: 'error' }),
    new transports.File({ filename: 'logs/combined.log' })
  ]
});

// ============ Prometheus Metrics ============
const httpRequestDuration = new Histogram({
  name: 'http_request_duration_ms',
  help: 'Duration of HTTP requests in ms',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.1, 5, 15, 50, 100, 500]
});

const httpRequestCounter = new Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code']
});

// ============ Middleware ============
app.use(cors());
app.use(express.json());

// Metrics middleware
app.use((req, res, next) => {
  const start = Date.now();
  
  res.on('finish', () => {
    const duration = Date.now() - start;
    httpRequestDuration
      .labels(req.method, req.path, res.statusCode)
      .observe(duration);
    
    httpRequestCounter
      .labels(req.method, req.path, res.statusCode)
      .inc();
  });
  
  next();
});

// Request logging
app.use((req, res, next) => {
  logger.info({
    timestamp: new Date().toISOString(),
    method: req.method,
    path: req.path,
    ip: req.ip,
    userAgent: req.get('user-agent')
  });
  next();
});

// ============ Routes ============

/**
 * Health Check Endpoint
 * Used by load balancers and Kubernetes for liveness probes
 */
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    environment: ENV,
    version: '1.0.0',
    uptime: process.uptime()
  });
});

/**
 * Readiness Check Endpoint
 * Used by Kubernetes for readiness probes
 */
app.get('/ready', (req, res) => {
  res.status(200).json({
    ready: true,
    dependencies: {
      database: 'connected',
      cache: 'operational',
      external_api: 'reachable'
    },
    timestamp: new Date().toISOString()
  });
});

/**
 * Metrics Endpoint
 * Exposes Prometheus metrics
 */
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

/**
 * API Version Endpoint
 */
app.get('/api/version', (req, res) => {
  res.status(200).json({
    version: '1.0.0',
    api: 'v1',
    buildDate: '2026-04-12',
    commitHash: process.env.COMMIT_SHA || 'unknown'
  });
});

/**
 * Status Dashboard Endpoint
 */
app.get('/api/status', (req, res) => {
  res.status(200).json({
    application: 'DevOps CI/CD Pipeline',
    status: 'running',
    environment: ENV,
    timestamp: new Date().toISOString(),
    deployment: {
      version: '1.0.0',
      region: process.env.REGION || 'us-east-1',
      replicas: process.env.REPLICAS || 1,
      uptime: `${Math.floor(process.uptime())}s`
    },
    system: {
      memory: `${Math.round(process.memoryUsage().heapUsed / 1024 / 1024)}MB`,
      cpuUsage: process.cpuUsage()
    }
  });
});

/**
 * Deployment Info Endpoint
 * Returns information about the deployment
 */
app.get('/api/deployment-info', (req, res) => {
  res.status(200).json({
    deployment_id: process.env.DEPLOYMENT_ID || 'local-dev',
    build_number: process.env.BUILD_NUMBER || 'manual',
    git_commit: process.env.COMMIT_SHA || 'unknown',
    deployed_by: process.env.DEPLOYED_BY || 'developer',
    deployment_timestamp: process.env.DEPLOYMENT_TIME || new Date().toISOString(),
    pipeline_url: process.env.PIPELINE_URL || 'http://localhost:8080'
  });
});

/**
 * Test Endpoint
 * Returns test data
 */
app.get('/api/test', (req, res) => {
  res.status(200).json({
    message: 'Test successful',
    data: {
      id: 1,
      name: 'DevOps Project',
      status: 'active',
      created: '2026-04-12'
    }
  });
});

/**
 * Error Handler Endpoint
 */
app.get('/api/error', (req, res) => {
  logger.error('Test error endpoint hit');
  res.status(500).json({
    error: 'Internal Server Error',
    message: 'This is a test error response',
    timestamp: new Date().toISOString()
  });
});

/**
 * Root Endpoint
 */
app.get('/', (req, res) => {
  res.status(200).json({
    name: 'Enterprise DevOps CI/CD Application',
    version: '1.0.0',
    description: 'High-profile DevOps project with Docker and Jenkins',
    endpoints: {
      health: '/health',
      ready: '/ready',
      metrics: '/metrics',
      version: '/api/version',
      status: '/api/status',
      deployment: '/api/deployment-info',
      test: '/api/test'
    }
  });
});

/**
 * 404 Handler
 */
app.use((req, res) => {
  logger.warn(`404 Not Found: ${req.method} ${req.path}`);
  res.status(404).json({
    error: 'Not Found',
    path: req.path,
    message: 'The requested endpoint does not exist',
    availableEndpoints: [
      '/',
      '/health',
      '/ready',
      '/metrics',
      '/api/version',
      '/api/status',
      '/api/deployment-info'
    ]
  });
});

// ============ Error Handler ============
app.use((err, req, res, next) => {
  logger.error({
    error: err.message,
    stack: err.stack,
    path: req.path,
    method: req.method
  });
  
  res.status(err.status || 500).json({
    error: 'Internal Server Error',
    message: err.message,
    timestamp: new Date().toISOString()
  });
});

// ============ Server Startup ============
const server = app.listen(PORT, () => {
  logger.info(`
    ╔════════════════════════════════════════════════════════╗
    ║   Enterprise DevOps CI/CD Application Started         ║
    ╠════════════════════════════════════════════════════════╣
    ║   Environment: ${ENV.padEnd(40)}║
    ║   Port: ${PORT.toString().padEnd(45)}║
    ║   Node Version: ${process.version.padEnd(38)}║
    ║   Running at: http://localhost:${PORT}${' '.repeat(25)}║
    ╠════════════════════════════════════════════════════════╣
    ║   Available Endpoints:                                 ║
    ║   • GET /                    - Root endpoint           ║
    ║   • GET /health              - Health check            ║
    ║   • GET /ready               - Readiness probe         ║
    ║   • GET /metrics             - Prometheus metrics      ║
    ║   • GET /api/version         - API version info        ║
    ║   • GET /api/status          - Application status      ║
    ║   • GET /api/deployment-info - Deployment info        ║
    ╚════════════════════════════════════════════════════════╝
  `);
});

// ============ Graceful Shutdown ============
process.on('SIGTERM', () => {
  logger.info('SIGTERM signal received: closing HTTP server');
  server.close(() => {
    logger.info('HTTP server closed');
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  logger.info('SIGINT signal received: closing HTTP server');
  server.close(() => {
    logger.info('HTTP server closed');
    process.exit(0);
  });
});

export default app;
