FROM python:3.11-slim

WORKDIR /app

# Install uv
RUN pip install uv

# Copy dependency files
COPY pyproject.toml .
COPY README.md .

# Install dependencies
RUN uv pip install --system -e .

# Copy source code
COPY src/ src/

# Run the application
ENV PORT=8080
EXPOSE 8080

CMD ["python", "-m", "src.main"]
