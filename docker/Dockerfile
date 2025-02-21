# Stage 1: Build the mkdocs site
FROM python:3.11-slim AS builder

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements.txt first (optimizes caching)
COPY requirements.txt .

# Install dependencies from requirements.txt
RUN pip install --no-cache-dir -r requirements.txt \
    && rm -rf /root/.cache/pip

# Copy the rest of your mkdocs project files
COPY . /app/

# Build the mkdocs site
RUN mkdocs build

# Stage 2: Serve the static site
FROM nginx:alpine

# Copy the built site from the builder stage
COPY --from=builder /app/site /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Nginx will start automatically with its default command