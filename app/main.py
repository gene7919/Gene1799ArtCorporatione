from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import os

app = FastAPI(title="Gene1799ArtCorporatione API")

# CORS per permettere accesso da frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def root():
    return {
        "status": "online",
        "service": "Gene1799ArtCorporatione API",
        "version": "1.0.0"
    }

@app.get("/health")
def health_check():
    return {"status": "healthy"}

# Importa db check solo se variabili ambiente presenti
if all([
    os.getenv("DB_HOST"),
    os.getenv("DB_NAME"),
    os.getenv("DB_USER"),
    os.getenv("DB_PASSWORD")
]):
    from .db import get_connection
    
    @app.get("/db-check")
    def db_check():
        try:
            conn = get_connection()
            cur = conn.cursor()
            cur.execute("SELECT version();")
            version = cur.fetchone()[0]
            cur.close()
            conn.close()
            return {
                "status": "ok",
                "database": "reachable",
                "postgres_version": version
            }
        except Exception as e:
            return {
                "status": "error",
                "database": "unreachable",
                "details": str(e)
            }
