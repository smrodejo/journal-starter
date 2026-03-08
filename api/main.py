import logging
from contextlib import asynccontextmanager

from dotenv import load_dotenv
from fastapi import FastAPI
from opentelemetry import metrics
from opentelemetry.exporter.prometheus import PrometheusMetricReader
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from prometheus_fastapi_instrumentator import Instrumentator

from api.routers.journal_router import router as journal_router

load_dotenv(override=True)

# Logging configuration
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)

logger = logging.getLogger(__name__)
logger.info(" ********* Journal API is launching... ********* ")

# Make metric data available for Prometheus.
reader = PrometheusMetricReader()
provider = MeterProvider(metric_readers=[reader])
metrics.set_meter_provider(provider)


# Using Instrumentator to serve metrics on the same app (Port 8000)

app = FastAPI(
    title="Journal API",
    description="A simple journal API for tracking daily work, struggles, and intentions",
)

@app.get("/health")
async def health():
    return {"status": "healthy"}


# Instrument the FastAPI app with OpenTelemetry and Prometheus
FastAPIInstrumentor.instrument_app(app)
Instrumentator().instrument(app).expose(app)

app.include_router(journal_router)


@app.get("/")
async def root():
    return {"message": "Journal API is online", "docs": "/docs"}

