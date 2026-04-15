class Gene1799RAGCore:
    def __init__(self):
        self.stores={}; self.ready=False
        CHROMA_PATH.mkdir(parents=True,exist_ok=True)
        if not HAS_ALL: return
        try:
            self.client=chromadb.PersistentClient(
                path=str(CHROMA_PATH),
                settings=Settings(anonymized_telemetry=False))
            self.emb=OllamaEmbeddings(model=EMBED_MODEL,base_url=OLLAMA_HOST)
            self.llm=OllamaLLM(model=OLLAMA_MODEL,base_url=OLLAMA_HOST,
                                temperature=0.1,num_predict=1024)
            for n in COLLECTIONS:
                self.stores[n]=Chroma(collection_name=n,
                    embedding_function=self.emb,client=self.client)
            self.ready=True
            print(f"[RAG][OK] {len(COLLECTIONS)} collezioni pronte")
        except Exception as e:
            print(f"[RAG][ERRORE] {e}")

    def ingest_text(self,testo,col,meta=None):
        if not self.ready or col not in self.stores or not testo.strip():
            return 0
        sp=RecursiveCharacterTextSplitter(chunk_size=800,chunk_overlap=100)
        m={"fonte":col,"ts":datetime.datetime.now().isoformat(),
           "sha":hashlib.sha256(testo.encode()).hexdigest()[:12]}
        if meta: m.update(meta)
        docs=[Document(page_content=c,metadata=m) for c in sp.split_text(testo)]
        self.stores[col].add_documents(docs)
        print(f"[RAG][+] {len(docs)} chunk -> '{col}'")
        return len(docs)

    def ingest_file(self,percorso,col):
        p=Path(percorso)
        if not p.exists(): return 0
        try:
            if p.suffix==".json":
                testo=json.dumps(json.load(open(p,encoding="utf-8")),
                                 indent=2,ensure_ascii=False)
            else:
                testo=open(p,encoding="utf-8",errors="ignore").read()
            return self.ingest_text(testo,col,{"file":p.name,"ext":p.suffix})
        except: return 0

    def ingest_dal_db(self):
        if not DB_PATH.exists(): return {}
        ris={}
        try:
            conn=sqlite3.connect(str(DB_PATH)); c=conn.cursor()
            for tb,col,campi in [
                ("ai_agents","gene_agenti",["name","type","description","status"]),
                ("agent_messages","gene_logs",["from_agent","message","message_type"])]:
                try:
                    c.execute(f"SELECT {','.join(campi)} FROM {tb} LIMIT 500")
                    t="\n".join([" | ".join(str(x) for x in r) for r in c.fetchall()])
                    if t.strip(): ris[tb]=self.ingest_text(t,col,{"fonte_db":tb})
                except: pass
            conn.close()
        except: pass
        return ris

    def query(self,domanda,col=None,k=5):
        if not self.ready:
            return {"errore":"RAG non pronto","risposta":"","domanda":domanda}
        try:
            docs=[]
            targets=[col] if col and col in self.stores else list(self.stores.keys())
            for n in targets:
                try: docs+=self.stores[n].similarity_search(domanda,k=2 if not col else k)
                except: pass
            if not docs:
                return {"risposta":"Nessun documento rilevante.","fonti":[],"n":0,"domanda":domanda}
            ctx="\n---\n".join(d.page_content for d in docs)
            prompt=(f"Sei il motore AI di Gene1799 ArtCorporatione.\n"
                    f"Rispondi in italiano usando SOLO questo contesto:\n\n{ctx}\n\n"
                    f"DOMANDA: {domanda}\n\nRISPOSTA:")
            risp=self.llm.invoke(prompt)
            fonti=list({d.metadata.get("file",d.metadata.get("fonte_db","interno"))
                        for d in docs})
            self._log(domanda,risp,len(docs))
            return {"risposta":risp,"fonti":fonti,"n":len(docs),"domanda":domanda}
        except Exception as e:
            return {"errore":str(e),"risposta":"","domanda":domanda}

    def search(self,testo,col="gene_docs",k=5):
        if not self.ready or col not in self.stores: return []
        try:
            return [{"testo":d.page_content,"meta":d.metadata}
                    for d in self.stores[col].similarity_search(testo,k=k)]
        except: return []

    def stats(self):
        s={"ready":self.ready,"llm":OLLAMA_MODEL,"embed":EMBED_MODEL,"collezioni":{}}
        for n,st in self.stores.items():
            try: s["collezioni"][n]={"chunks":st._collection.count(),"desc":COLLECTIONS[n]}
            except: s["collezioni"][n]={"chunks":0}
        return s

    def _log(self,domanda,risposta,n):
        try:
            conn=sqlite3.connect(str(DB_PATH)); c=conn.cursor()
            c.execute("""CREATE TABLE IF NOT EXISTS rag_queries
                (id INTEGER PRIMARY KEY,domanda TEXT,risposta TEXT,n_docs INTEGER,ts TEXT)""")
            c.execute("INSERT INTO rag_queries VALUES(NULL,?,?,?,?)",
                      (domanda,risposta,n,datetime.datetime.now().isoformat()))
            conn.commit(); conn.close()
        except: pass

_rag=None


def ingest_suite():
    escludi={"node_modules","__pycache__",".git","chroma_db","dist","build",".venv"}
    mappa={
        "gene_ledger.json":"gene_ledger","core_saldatura.json":"gene_ledger",
        "command_bridge.json":"gene_ledger","legal_framework.json":"gene_legale",
    }
    prefissi={"basescan":"gene_blockchain","zora":"gene_blockchain",
              "web3":"gene_blockchain","ens":"gene_blockchain",
              "ready_":"gene_agenti","agent":"gene_agenti"}
    n=0
    for p in ROOT.rglob("*"):
        if any(e in p.parts for e in escludi) or not p.is_file(): continue
        if p.suffix.lower() not in [".py",".js",".txt",".md",".json",".html"]: continue
        col=mappa.get(p.name,"gene_docs")
        for pref,c2 in prefissi.items():
            if p.name.startswith(pref): col=c2
        n+=_rag.ingest_file(str(p),col)
    _rag.ingest_dal_db()
    print(f"[RAG][SUITE] {n} chunk totali indicizzati")
    return n


class Handler(BaseHTTPRequestHandler):
    def log_message(self,*a): pass
    def _j(self,d,code=200):
        b=json.dumps(d,ensure_ascii=False).encode()
        self.send_response(code)
        self.send_header("Content-Type","application/json; charset=utf-8")
        self.send_header("Access-Control-Allow-Origin","*")
        self.sendHeader("Content-Length",len(b))
        self.end_headers(); self.wfile.write(b)
    def do_OPTIONS(self):
        self.send_response(204)
        for h,v in [("Access-Control-Allow-Origin","*"),
                    ("Access-Control-Allow-Methods","GET,POST,OPTIONS"),
                    ("Access-Control-Allow-Headers","Content-Type")]:
            self.send_header(h,v)
        self.end_headers()
    def do_GET(self):
        p=urllib.parse.urlparse(self.path).path
        if   p=="/health":       self._j({"ok":True,"ready":_rag.ready})
        elif p=="/stats":        self._j(_rag.stats())
        elif p=="/ingest/db":    self._j({"ok":True,"ris":_rag.ingest_dal_db()})
        elif p=="/ingest/suite": self._j({"ok":True,"chunks":ingest_suite()})
        else: self._j({"errore":"non trovato"},404)
    def do_POST(self):
        p=urllib.parse.urlparse(self.path).path
        ln=int(self.headers.get("Content-Length",0))
        b=json.loads(self.rfile.read(ln)) if ln else {}
        if   p=="/query":
            self._j(_rag.query(b.get("domanda",""),b.get("collezione"),int(b.get("k",5))))
        elif p=="/search":
            self._j({"ris":_rag.search(b.get("testo",""),b.get("collezione","gene_docs"),int(b.get("k",5)))})
        elif p=="/ingest/testo":
            self._j({"ok":True,"chunks":_rag.ingest_text(b.get("testo",""),b.get("collezione","gene_docs"),b.get("metadata",{}))})
        else: self._j({"errore":"non trovato"},404)

if __name__=="__main__":
    print("="*55)
    print(f"  GENE1799 RAG SERVER — porta {RAG_PORT}")
    print(f"  LLM: {OLLAMA_MODEL}  |  Embed: {EMBED_MODEL}")
    print("="*55)
    _rag=Gene1799RAGCore()
    if not _rag.ready:
        print("[RAG][ERRORE] Controlla Ollama e dipendenze.")
        sys.exit(1)
    threading.Thread(target=ingest_suite,daemon=True).start()
    srv=HTTPServer(("127.0.0.1",RAG_PORT),Handler)
    print(f"[RAG] http://127.0.0.1:{RAG_PORT}")
    print("  GET  /health /stats /ingest/db /ingest/suite")
    print("  POST /query  /search /ingest/testo")
    print("="*55)
    try: srv.serve_forever()
    except KeyboardInterrupt: print("\n[RAG] Stop.")

