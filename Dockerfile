# Stage 1: Build frontend
FROM node:18 AS frontend-build
WORKDIR /app/frontend
COPY frontend/package.json ./
RUN npm install
COPY frontend/ ./
RUN npm run build

# Stage 2: Build backend
FROM python:3.11-slim AS backend-build
WORKDIR /app
COPY backend/ ./backend/
COPY --from=frontend-build /app/frontend/dist ./frontend_dist
COPY scripts/ ./scripts/
RUN pip install --upgrade pip && pip install -r backend/requirements.txt

# Stage 3: Final image
FROM python:3.11-slim
WORKDIR /app
COPY --from=backend-build /app/backend ./backend
COPY --from=backend-build /app/frontend_dist ./frontend_dist
COPY --from=backend-build /app/scripts ./scripts
ENV PYTHONUNBUFFERED=1
RUN pip install --upgrade pip && pip install -r backend/requirements.txt
EXPOSE 8000
CMD ["python", "-m", "uvicorn", "backend.main:app", "--host", "0.0.0.0", "--port", "8000"] 