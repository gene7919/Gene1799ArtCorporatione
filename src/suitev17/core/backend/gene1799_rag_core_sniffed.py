class RAGConfig(BaseModel):
    chroma_server_nofile: Optional[str] = None
    RAG_HOST: str = "http://127.0.0.1:8090"
    BRIDGE_PORT: int = 8091


def start_rag_core():
    config = RAGConfig()
    print("GENE1799 RAG CORE pronto")
    print(f"Config caricata: {config.model_dump()}")

if __name__ == "__main__":
    start_rag_core()

