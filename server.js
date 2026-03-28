"use strict";

const express = require("express");
const exphbs = require("express-handlebars");
const client = require("prom-client");

// Requiring our models for syncing
const db = require("./models");

const PORT = process.env.PORT || 8080;

const app = express();

// ── Prometheus metrics ───────────────────────────────────────────
// Collects default Node.js metrics: CPU, memory, event loop, GC
// Scraped by Prometheus at /metrics every 15s
const register = new client.Registry();
client.collectDefaultMetrics({ register });

// HTTP request duration histogram — enables p50/p90/p99 in Grafana
const httpRequestDuration = new client.Histogram({
  name: "http_request_duration_seconds",
  help: "HTTP request duration in seconds",
  labelNames: ["method", "route", "statusCode"],
  buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5],
  registers: [register],
});

// HTTP request counter — enables request rate graph in Grafana
const httpRequestsTotal = new client.Counter({
  name: "http_requests_total",
  help: "Total number of HTTP requests",
  labelNames: ["method", "route", "statusCode"],
  registers: [register],
});

// Middleware to record metrics for every request
app.use((req, res, next) => {
  const end = httpRequestDuration.startTimer();
  res.on("finish", () => {
    const labels = { method: req.method, route: req.path, statusCode: res.statusCode };
    end(labels);
    httpRequestsTotal.inc(labels);
  });
  next();
});

// Serve static content for the app from the "public" directory in the application directory.
app.use(express.static("public"));

// Parse application body
app.use(express.urlencoded({ extended: true }));
app.use(express.json());

app.engine("handlebars", exphbs.engine({ defaultLayout: "main" }));
app.set("view engine", "handlebars");

// ── Health check — used by Cloud Load Balancer + Docker healthcheck
// Must return 200 for the LB to mark the backend as healthy.
// Returns 503 if the database is unreachable.
app.get("/health", async (req, res) => {
  try {
    await db.sequelize.authenticate();
    res.status(200).json({ status: "ok", db: "connected" });
  } catch (err) {
    res.status(503).json({ status: "error", db: "unreachable" });
  }
});

// ── Prometheus metrics endpoint ──────────────────────────────────
// Scraped by Prometheus every 15s (configured in prometheus.yml)
app.get("/metrics", async (req, res) => {
  res.set("Content-Type", register.contentType);
  res.end(await register.metrics());
});

require("./routes/cart-api-routes")(app);

console.log("going to html route");
app.use("/", require("./routes/html-routes"));
app.use("/cart", require("./routes/html-routes"));
app.use("/gallery", require("./routes/html-routes"));

db.sequelize.sync().then(function () {
  app.listen(PORT, function () {
    console.log("App listening on PORT " + PORT);
  });
});
