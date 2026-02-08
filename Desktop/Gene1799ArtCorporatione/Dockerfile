# Multi-stage Dockerfile for Gene1799 Production Deployment

# Stage 1: Build Backend
FROM node:20-alpine AS backend-builder
WORKDIR /app
COPY package*.json ./
COPY backend/ ./backend/
COPY shared/ ./shared/
RUN npm install && npm run build -w backend

# Stage 2: Build Frontend
FROM node:20-alpine AS frontend-builder
WORKDIR /app
COPY package*.json ./
COPY frontend/ ./frontend/
COPY shared/ ./shared/
RUN npm install && npm run build -w frontend

# Stage 3: Build Python Agent
FROM python:3.13-slim AS agent-builder
WORKDIR /app
COPY ai-agent/requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Stage 4: Production - Backend & API
FROM node:20-alpine AS production-backend
WORKDIR /app
ENV NODE_ENV=production
COPY package*.json ./
COPY backend/ ./backend/
COPY --from=backend-builder /app/backend/dist ./backend/dist
RUN npm install --production
EXPOSE 3000
CMD ["npm", "start", "-w", "backend"]

# Stage 5: Production - Frontend Static
FROM nginx:alpine AS production-frontend
COPY --from=frontend-builder /app/frontend/dist /usr/share/nginx/html
COPY ./nginx.conf /etc/nginx/nginx.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]

# Stage 6: Production - AI Agent
FROM python:3.13-slim AS production-agent
WORKDIR /app
ENV PYTHONUNBUFFERED=1
COPY ai-agent/ ./
RUN pip install --no-cache-dir -r requirements.txt
CMD ["python", "main.py"]
