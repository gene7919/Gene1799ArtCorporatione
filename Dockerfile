FROM node:20-alpine

# Install Python and dependencies
RUN apk add --no-cache python3 py3-pip python3-dev build-base

# Create app directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install Node.js dependencies
RUN npm install --production

# Copy application files
COPY . .

# Create Python virtual environment and install dependencies
RUN python3 -m venv /app/venv && \
    source /app/venv/bin/activate && \
    pip install --no-cache-dir \
    numpy \
    pandas \
    scikit-learn \
    openai \
    anthropic \
    aiohttp || echo "Some Python packages may not be available in Alpine"

# Create necessary directories
RUN mkdir -p database logs uploads temp

# Set Python path to use virtual environment
ENV PYTHON_PATH=/app/venv/bin/python3
ENV PATH="/app/venv/bin:$PATH"

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/api/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Start application
CMD ["npm", "start"]

