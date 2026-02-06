"""{{service_name}} — Cloud Run Entry Point."""

import os
from typing import Any

import uvicorn
from fastapi import FastAPI

app = FastAPI(
    title="{{service_name}}",
    description="{{service_description}}",
    version="0.1.0",
)


@app.get("/health")
async def healthcheck() -> dict[str, Any]:
    """Health check endpoint."""
    return {"status": "healthy", "service": "{{service_name}}"}


@app.get("/")
async def root() -> dict[str, str]:
    """Root endpoint."""
    return {"message": "Welcome to {{service_name}}"}


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8080))
    uvicorn.run(app, host="0.0.0.0", port=port)
