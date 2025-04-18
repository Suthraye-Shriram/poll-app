# --- Stage 1: Build Dependencies on Alpine ---
FROM python:3.9-alpine AS builder

# Install build dependencies needed for some Python packages on Alpine
# psycopg2-binary might need postgresql-dev, etc. Add as needed.
# For Flask/Flask-Cors, build-base should suffice if wheels aren't available.
RUN apk add --no-cache build-base

WORKDIR /app

# Create and activate virtual environment
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Upgrade pip and install wheel (good practice)
RUN pip install --no-cache-dir --upgrade pip wheel

# Copy requirements and install
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# --- Stage 2: Final Runtime Image ---
# Using Alpine instead of distroless for better environment variable support
FROM python:3.9-alpine

WORKDIR /app

# Copy virtual environment from builder stage
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy application code
COPY . .

# Set environment variables
ENV FLASK_APP=app.py
ENV PYTHONUNBUFFERED=1

# Expose the port the app runs on
EXPOSE 5000

# Run Flask
CMD ["flask", "run", "--host=0.0.0.0", "--port=5000"]
