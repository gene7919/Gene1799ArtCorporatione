def compute_sha256(data):
    """Compute SHA-256 hash of data"""
    if isinstance(data, str):
        data = data.encode('utf-8')
    return hashlib.sha256(data).hexdigest()


def compute_file_sha256(filepath):
    """Compute SHA-256 hash of a file"""
    sha256 = hashlib.sha256()
    with open(filepath, 'rb') as f:
        for chunk in iter(lambda: f.read(8192), b''):
            sha256.update(chunk)
    return sha256.hexdigest()


def generate_digital_signature(data_dict):
    """Generate SHA-256 digital signature for data"""
    sig_string = json.dumps(data_dict, sort_keys=True, default=str)
    signature = compute_sha256(sig_string)
    return signature


def verify_digital_signature(data_dict, expected_hash):
    """Verify SHA-256 digital signature"""
    computed = generate_digital_signature(data_dict)
    return hmac.compare_digest(computed, expected_hash)


def hash_password(password, salt=None):
    """PBKDF2-SHA256 password hashing"""
    if salt is None:
        salt = os.urandom(32)
    elif isinstance(salt, str):
        salt = bytes.fromhex(salt)
    key = hashlib.pbkdf2_hmac('sha256', password.encode(), salt, 100000)
    return salt.hex(), key.hex()


def verify_password(password, salt_hex, key_hex):
    """Verify password against stored hash"""
    _, computed = hash_password(password, salt_hex)
    return hmac.compare_digest(computed, key_hex)


def generate_otp(length=6):
    """Generate numeric OTP"""
    return ''.join(random.choices(string.digits, k=length))


def generate_totp_secret():
    """Generate TOTP secret for Google Authenticator"""
    return base64.b32encode(os.urandom(20)).decode('utf-8').rstrip('=')


def compute_totp(secret, time_step=30, digits=6):
    """Compute TOTP code compatible with Google Authenticator"""
    # Pad secret
    secret_padded = secret + '=' * (8 - len(secret) % 8) if len(secret) % 8 != 0 else secret
    key = base64.b32decode(secret_padded.upper())
    counter = int(time.time()) // time_step
    counter_bytes = struct.pack('>Q', counter)
    hmac_hash = hmac.new(key, counter_bytes, hashlib.sha1).digest()
    offset = hmac_hash[-1] & 0x0F
    code = struct.unpack('>I', hmac_hash[offset:offset + 4])[0]
    code = (code & 0x7FFFFFFF) % (10 ** digits)
    return str(code).zfill(digits)


def verify_totp(secret, code, window=1):
    """Verify TOTP code with time window tolerance"""
    for i in range(-window, window + 1):
        secret_padded = secret + '=' * (8 - len(secret) % 8) if len(secret) % 8 != 0 else secret
        key = base64.b32decode(secret_padded.upper())
        counter = (int(time.time()) // 30) + i
        counter_bytes = struct.pack('>Q', counter)
        hmac_hash = hmac.new(key, counter_bytes, hashlib.sha1).digest()
        offset = hmac_hash[-1] & 0x0F
        computed = struct.unpack('>I', hmac_hash[offset:offset + 4])[0]
        computed = (computed & 0x7FFFFFFF) % (10 ** 6)
        if str(computed).zfill(6) == str(code).zfill(6):
            return True
    return False


def generate_token(length=32):
    """Generate secure random token"""
    return ''.join(random.choices(string.ascii_letters + string.digits, k=length))


def validate_email(email):
    """Validate email format"""
    return re.match(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$', email) is not None


def format_bytes(b):
    """Format bytes to human readable"""
    for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
        if b < 1024.0:
            return f"{b:.2f} {unit}"
        b /= 1024.0


# ═══════════════════════════════════════════════════════════════════
#  EMAIL SYSTEM
# ═══════════════════════════════════════════════════════════════════


class EmailSystem:
    """SMTP Email System with HTML templates"""
    
    def __init__(self):
        self.smtp_server = "smtp.gmail.com"
        self.smtp_port = 587
        self.use_tls = True
        self.sender_email = None
        self.sender_password = None
        self.sender_name = APP_NAME
        self.email_queue = queue.Queue()
    
    def configure(self, email, password, server="smtp.gmail.com", port=587):
        self.sender_email = email
        self.sender_password = password
        self.smtp_server = server
        self.smtp_port = port
    
    def send_email(self, to_email, subject, body_html, body_text=None):
        """Send HTML email via SMTP"""
        if not HAS_EMAIL or not self.sender_email:
            return False
        try:
            msg = MIMEMultipart('alternative')
            msg['From'] = f"{self.sender_name} <{self.sender_email}>"
            msg['To'] = to_email
            msg['Subject'] = subject
            if body_text:
                msg.attach(MIMEText(body_text, 'plain'))
            msg.attach(MIMEText(body_html, 'html'))
            
            with smtplib.SMTP(self.smtp_server, self.smtp_port) as server:
                if self.use_tls:
                    server.starttls()
                server.login(self.sender_email, self.sender_password)
                server.send_message(msg)
            return True
        except Exception as e:
            print(f"Email error: {e}")
            return False
    
    def send_confirmation_email(self, to_email, otp_code, user_name="User"):
        """Send registration confirmation with OTP"""
        html = f"""
        <html><body style="font-family:Arial;background:#f4f4f4;padding:20px;">
        <div style="max-width:600px;margin:0 auto;background:white;padding:30px;border-radius:10px;">
            <div style="background:linear-gradient(135deg,#001100,#003300);color:#00FF00;padding:20px;border-radius:10px;text-align:center;">
                <h1>⬢ {APP_NAME}</h1>
                <p>Conferma Iscrizione</p>
            </div>
            <div style="padding:20px;line-height:1.6;">
                <h2>Ciao {user_name},</h2>
                <p>Il tuo codice di conferma è:</p>
                <div style="text-align:center;padding:20px;">
                    <span style="font-size:32px;font-weight:bold;letter-spacing:8px;background:#f0f0f0;padding:15px 30px;border-radius:10px;">{otp_code}</span>
                </div>
                <p>Inserisci questo codice nell'applicazione per completare la registrazione.</p>
                <p>Il codice scade tra 10 minuti.</p>
            </div>
            <div style="text-align:center;color:#666;font-size:0.9em;margin-top:30px;">
                <p>{APP_NAME} v{VERSION} | {COMPANY}</p>
                <p>License: {LICENSE_CODE}</p>
            </div>
        </div></body></html>
        """
        return self.send_email(to_email, f"[{APP_NAME}] Conferma Iscrizione - OTP: {otp_code}", html)
    
    def send_password_reset(self, to_email, reset_token, user_name="User"):
        """Send password reset email"""
        html = f"""
        <html><body style="font-family:Arial;background:#f4f4f4;padding:20px;">
        <div style="max-width:600px;margin:0 auto;background:white;padding:30px;border-radius:10px;">
            <div style="background:linear-gradient(135deg,#001100,#003300);color:#00FF00;padding:20px;border-radius:10px;text-align:center;">
                <h1>⬢ {APP_NAME}</h1>
                <p>Reset Password</p>
            </div>
            <div style="padding:20px;">
                <h2>Ciao {user_name},</h2>
                <p>Hai richiesto il reset della password. Il tuo token di reset è:</p>
                <div style="text-align:center;padding:20px;">
                    <code style="font-size:18px;background:#f0f0f0;padding:10px 20px;border-radius:5px;">{reset_token}</code>
                </div>
                <p>Questo token scade tra 1 ora.</p>
            </div>
        </div></body></html>
        """
        return self.send_email(to_email, f"[{APP_NAME}] Reset Password", html)


# ═══════════════════════════════════════════════════════════════════
#  SCRIPT MANAGER - Auto Expansion System
# ═══════════════════════════════════════════════════════════════════


class ScriptManager:
    """Manages custom scripts for app auto-expansion"""
    
    def __init__(self, scripts_dir):
        self.scripts_dir = Path(scripts_dir)
        self.scripts_dir.mkdir(parents=True, exist_ok=True)
        self.loaded_scripts = {}
        self.script_registry = self.scripts_dir / 'registry.json'
        self.load_registry()
    
    def load_registry(self):
        if self.script_registry.exists():
            with open(self.script_registry, 'r') as f:
                self.registry = json.load(f)
        else:
            self.registry = {"scripts": [], "categories": [
                "ai_agent", "social_automation", "content_creation",
                "nft_tools", "analytics", "utility", "custom"
            ]}
            self.save_registry()
    
    def save_registry(self):
        with open(self.script_registry, 'w') as f:
            json.dump(self.registry, f, indent=2)
    
    def add_script(self, filepath, name=None, category="custom", description=""):
        """Add a script to the system"""
        src = Path(filepath)
        if not src.exists():
            return False, "File not found"
        
        dest = self.scripts_dir / src.name
        shutil.copy2(src, dest)
        
        # Compute SHA-256
        file_hash = compute_file_sha256(str(dest))
        
        entry = {
            "name": name or src.stem,
            "filename": src.name,
            "path": str(dest),
            "category": category,
            "description": description,
            "sha256": file_hash,
            "added_at": datetime.now().isoformat(),
            "runs": 0,
            "active": True
        }
        
        # Remove existing entry with same name
        self.registry["scripts"] = [s for s in self.registry["scripts"] if s["name"] != entry["name"]]
        self.registry["scripts"].append(entry)
        self.save_registry()
        
        return True, f"Script '{entry['name']}' added (SHA-256: {file_hash[:16]}...)"
    
    def remove_script(self, name):
        """Remove a script"""
        for s in self.registry["scripts"]:
            if s["name"] == name:
                try:
                    os.remove(s["path"])
                except:
                    pass
                self.registry["scripts"].remove(s)
                self.save_registry()
                return True
        return False
    
    def run_script(self, name):
        """Execute a script"""
        for s in self.registry["scripts"]:
            if s["name"] == name and s["active"]:
                try:
                    result = subprocess.Popen(
                        [sys.executable, s["path"]],
                        stdout=subprocess.PIPE,
                        stderr=subprocess.PIPE
                    )
                    s["runs"] += 1
                    s["last_run"] = datetime.now().isoformat()
                    self.save_registry()
                    return True, f"Script '{name}' started (PID: {result.pid})"
                except Exception as e:
                    return False, str(e)
        return False, "Script not found or inactive"
    
    def get_scripts(self, category=None):
        """Get all scripts, optionally filtered by category"""
        scripts = self.registry["scripts"]
        if category:
            scripts = [s for s in scripts if s["category"] == category]
        return scripts
    
    def verify_script_integrity(self, name):
        """Verify script hasn't been modified (SHA-256 check)"""
        for s in self.registry["scripts"]:
            if s["name"] == name:
                current_hash = compute_file_sha256(s["path"])
                return current_hash == s["sha256"], current_hash, s["sha256"]
        return False, None, None


# ═══════════════════════════════════════════════════════════════════
#  WEB SERVER (API + Static Files)
# ═══════════════════════════════════════════════════════════════════


class Gene1799HTTPHandler(BaseHTTPRequestHandler):
    """Custom HTTP handler with API support"""
    
    app_dir = None
    db_path = None
    
    def log_message(self, format, *args):
        pass  # Suppress console output
    
    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path
        
        # API endpoints
        if path.startswith('/api/'):
            self.handle_api(path, parsed.query)
            return
        
        # Static files
        if path == '/' or path == '/index.html':
            path = '/index.html'
        
        filepath = Path(self.app_dir) / path.lstrip('/')
        if filepath.exists() and filepath.is_file():
            content_types = {
                '.html': 'text/html', '.css': 'text/css', '.js': 'application/javascript',
                '.json': 'application/json', '.png': 'image/png', '.jpg': 'image/jpeg',
                '.svg': 'image/svg+xml', '.ico': 'image/x-icon'
            }
            ct = content_types.get(filepath.suffix, 'application/octet-stream')
            self.send_response(200)
            self.send_header('Content-Type', ct)
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(filepath.read_bytes())
        else:
            self.send_response(404)
            self.end_headers()
    
    def do_POST(self):
        content_length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(content_length).decode() if content_length > 0 else '{}'
        parsed = urllib.parse.urlparse(self.path)
        self.handle_api_post(parsed.path, body)
    
    def handle_api(self, path, query):
        """Handle GET API requests"""
        data = {}
        if path == '/api/status':
            data = {"status": "online", "version": VERSION, "timestamp": datetime.now().isoformat()}
        elif path == '/api/stats':
            data = self.get_stats()
        elif path == '/api/token':
            data = ZORA_TOKEN
        elif path == '/api/signature':
            sig_data = DIGITAL_SIGNATURE.copy()
            sig_data["integrity_hash"] = generate_digital_signature({
                "project": sig_data["project"], "version": sig_data["version"],
                "license": sig_data["license"], "date": sig_data["date"]
            })
            data = sig_data
        
        self.send_json(data)
    
    def handle_api_post(self, path, body):
        """Handle POST API requests"""
        try:
            payload = json.loads(body) if body else {}
        except:
            payload = {}
        
        data = {"status": "ok"}
        
        if path == '/api/verify-signature':
            hash_to_verify = payload.get('hash', '')
            sig_data = {
                "project": DIGITAL_SIGNATURE["project"], "version": DIGITAL_SIGNATURE["version"],
                "license": DIGITAL_SIGNATURE["license"], "date": DIGITAL_SIGNATURE["date"]
            }
            valid = verify_digital_signature(sig_data, hash_to_verify)
            data = {"valid": valid, "algorithm": "SHA-256"}
        
        self.send_json(data)
    
    def get_stats(self):
        try:
            conn = sqlite3.connect(self.db_path)
            c = conn.cursor()
            stats = {}
            for table in ['users', 'ai_agents', 'social_posts', 'nfts', 'content', 'scripts_registry']:
                try:
                    c.execute(f'SELECT COUNT(*) FROM {table}')
                    stats[table] = c.fetchone()[0]
                except:
                    stats[table] = 0
            conn.close()
            return stats
        except:
            return {}
    
    def send_json(self, data):
        response = json.dumps(data, default=str).encode()
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        self.wfile.write(response)


# ═══════════════════════════════════════════════════════════════════
#  MAIN APPLICATION CLASS
# ═══════════════════════════════════════════════════════════════════


class Gene1799App:
    """
    Gene1799 Art Corporatione - Unified Platform v5.0.0
    
    SHA-256 Digitally Signed by:
      Marco Antonio Saverio Mazzitelli
      Fabio Amedeo Lo Presti
    License: 16/A408979L
    """
    
    def __init__(self, root):
        self.root = root
        self.root.title(f"⬢ {APP_NAME} v{VERSION}")
        self.root.geometry("1600x950")
        self.root.configure(bg=COLORS['bg_main'])
        
        # Current user session
        self.current_user = None
        self.session_token = None
        
        # Setup paths
        self.setup_paths()
        
        # Initialize subsystems
        self.email_system = EmailSystem()
        self.script_manager = ScriptManager(str(self.dirs['scripts']))
        
        # Server
        self.server = None
        self.server_port = 8888
        self.server_running = False
        
        # Database
        self.db_path = str(self.dirs['data'] / 'gene1799_v5.db')
        
        # Compute app signature
        self.app_signature = self.compute_app_signature()
        
        print(f"\n{'═' * 72}")
        print(f"  ⬢ {APP_NAME} v{VERSION}")
        print(f"  SHA-256 Signature: {self.app_signature[:32]}...")
        print(f"  License: {LICENSE_CODE}")
        print(f"  Signatories: {', '.join(DEVELOPERS)}")
        print(f"  © {COMPANY}")
        print(f"{'═' * 72}\n")
        
        # Initialize
        self.initialize_system()
        
        # Show login or main interface
        self.show_login_screen()
    
    def setup_paths(self):
        """Setup complete directory structure"""
        self.home = Path.home()
        self.app_dir = self.home / "Gene1799ArtCorporatione_v5"
        
        self.dirs = {
            'root': self.app_dir,
            'data': self.app_dir / 'Data',
            'config': self.app_dir / 'Config',
            'logs': self.app_dir / 'Logs',
            'backups': self.app_dir / 'Backups',
            'ai': self.app_dir / 'AI_System',
            'ai_agents': self.app_dir / 'AI_System' / 'Agents',
            'ai_models': self.app_dir / 'AI_System' / 'Models',
            'ai_scripts': self.app_dir / 'AI_System' / 'Scripts',
            'social': self.app_dir / 'Social_Media',
            'social_posts': self.app_dir / 'Social_Media' / 'Posts',
            'content': self.app_dir / 'Content_Creation',
            'web3': self.app_dir / 'Web3',
            'web3_nfts': self.app_dir / 'Web3' / 'NFTs',
            'web3_tokens': self.app_dir / 'Web3' / 'Tokens',
            'scripts': self.app_dir / 'Scripts',
            'extensions': self.app_dir / 'Extensions',
            'temp': self.app_dir / 'Temp',
            'exports': self.app_dir / 'Exports',
            'web': self.app_dir / 'Web',
            'signatures': self.app_dir / 'Signatures'
        }
    
    def compute_app_signature(self):
        """Compute SHA-256 signature of the application"""
        sig_data = {
            "project": APP_NAME,
            "version": VERSION,
            "license": LICENSE_CODE,
            "signatories": DEVELOPERS,
            "company": COMPANY,
            "date": BUILD_DATE
        }
        signature = generate_digital_signature(sig_data)
        DIGITAL_SIGNATURE["integrity_hash"] = signature
        return signature
    
    def initialize_system(self):
        """Initialize all subsystems"""
        # Create directories
        for name, path in self.dirs.items():
            path.mkdir(parents=True, exist_ok=True)
        
        # Init database
        self.init_database()
        
        # Load configs
        self.load_configs()
        
        # Save signature file
        sig_file = self.dirs['signatures'] / 'digital_signature.json'
        with open(sig_file, 'w') as f:
            json.dump(DIGITAL_SIGNATURE, f, indent=2, default=str)
        
        # Start server
        self.start_server_thread()
        
        self.log('INFO', 'System initialized v5.0.0', 'system')
    
    def init_database(self):
        """Initialize SQLite database with all tables"""
        conn = sqlite3.connect(self.db_path)
        c = conn.cursor()
        
        # Users & Auth
        c.execute('''CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE NOT NULL,
            email TEXT UNIQUE NOT NULL,
            password_salt TEXT NOT NULL,
            password_hash TEXT NOT NULL,
            first_name TEXT, last_name TEXT,
            totp_secret TEXT,
            totp_enabled BOOLEAN DEFAULT 0,
            email_verified BOOLEAN DEFAULT 0,
            role TEXT DEFAULT 'user',
            status TEXT DEFAULT 'pending',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            last_login TIMESTAMP
        )''')
        
        c.execute('''CREATE TABLE IF NOT EXISTS user_sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            token TEXT UNIQUE NOT NULL,
            ip_address TEXT,
            expires_at TIMESTAMP NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id)
        )''')
        
        c.execute('''CREATE TABLE IF NOT EXISTS email_verifications (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            otp_code TEXT NOT NULL,
            verified BOOLEAN DEFAULT 0,
            expires_at TIMESTAMP NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id)
        )''')
        
        c.execute('''CREATE TABLE IF NOT EXISTS password_resets (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            reset_token TEXT NOT NULL,
            used BOOLEAN DEFAULT 0,
            expires_at TIMESTAMP NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id)
        )''')
        
        # AI Agents
        c.execute('''CREATE TABLE IF NOT EXISTS ai_agents (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE NOT NULL,
            type TEXT NOT NULL,
            description TEXT,
            script_path TEXT,
            config TEXT,
            status TEXT DEFAULT 'active',
            owner_id INTEGER,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            last_run TIMESTAMP,
            runs_count INTEGER DEFAULT 0,
            success_rate REAL DEFAULT 0
        )''')
        
        c.execute('''CREATE TABLE IF NOT EXISTS agent_messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            from_agent TEXT, to_agent TEXT,
            message TEXT NOT NULL,
            message_type TEXT DEFAULT 'info',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )''')
        
        # Social Media
        c.execute('''CREATE TABLE IF NOT EXISTS social_posts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            content TEXT NOT NULL,
            platforms TEXT NOT NULL,
            media_paths TEXT,
            scheduled_time TIMESTAMP,
            posted_time TIMESTAMP,
            status TEXT DEFAULT 'draft',
            engagement TEXT,
            owner_id INTEGER,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )''')
        
        c.execute('''CREATE TABLE IF NOT EXISTS social_analytics (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            platform TEXT NOT NULL,
            post_id TEXT,
            likes INTEGER DEFAULT 0, comments INTEGER DEFAULT 0,
            shares INTEGER DEFAULT 0, views INTEGER DEFAULT 0,
            engagement_rate REAL DEFAULT 0,
            timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )''')
        
        # NFTs & Web3
        c.execute('''CREATE TABLE IF NOT EXISTS nfts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL, description TEXT,
            token_id TEXT, contract_address TEXT,
            network TEXT NOT NULL, image_path TEXT,
            metadata TEXT, owner_address TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            minted BOOLEAN DEFAULT 0,
            listed BOOLEAN DEFAULT 0,
            price REAL DEFAULT 0
        )''')
        
        c.execute('''CREATE TABLE IF NOT EXISTS tokens (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            symbol TEXT NOT NULL, name TEXT NOT NULL,
            contract_address TEXT, network TEXT NOT NULL,
            decimals INTEGER DEFAULT 18,
            balance REAL DEFAULT 0,
            price_usd REAL DEFAULT 0,
            last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )''')
        
        # Token $1799 tracker
        c.execute('''CREATE TABLE IF NOT EXISTS token_1799_holders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            wallet_address TEXT NOT NULL,
            balance REAL DEFAULT 0,
            staked REAL DEFAULT 0,
            rewards REAL DEFAULT 0,
            last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )''')
        
        c.execute('''CREATE TABLE IF NOT EXISTS token_1799_transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            tx_hash TEXT UNIQUE,
            from_address TEXT, to_address TEXT,
            amount REAL NOT NULL,
            tx_type TEXT DEFAULT 'transfer',
            block_number INTEGER,
            timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )''')
        
        # Content
        c.execute('''CREATE TABLE IF NOT EXISTS content (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL, title TEXT,
            content TEXT, file_path TEXT,
            metadata TEXT, ai_model TEXT,
            prompt TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )''')
        
        # Scripts Registry
        c.execute('''CREATE TABLE IF NOT EXISTS scripts_registry (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE NOT NULL,
            filename TEXT NOT NULL,
            path TEXT NOT NULL,
            category TEXT DEFAULT 'custom',
            description TEXT,
            sha256 TEXT NOT NULL,
            active BOOLEAN DEFAULT 1,
            runs INTEGER DEFAULT 0,
            added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            last_run TIMESTAMP
        )''')
        
        # Digital Signatures
        c.execute('''CREATE TABLE IF NOT EXISTS digital_signatures (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            entity_type TEXT NOT NULL,
            entity_id TEXT NOT NULL,
            sha256_hash TEXT NOT NULL,
            signer TEXT NOT NULL,
            license_code TEXT,
            verified BOOLEAN DEFAULT 1,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )''')
        
        # System
        c.execute('''CREATE TABLE IF NOT EXISTS backups (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL, path TEXT NOT NULL,
            size INTEGER, status TEXT DEFAULT 'completed',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )''')
        
        c.execute('''CREATE TABLE IF NOT EXISTS logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            level TEXT NOT NULL, message TEXT NOT NULL,
            module TEXT, user_id INTEGER,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )''')
        
        c.execute('''CREATE TABLE IF NOT EXISTS api_keys (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            service TEXT UNIQUE NOT NULL,
            key_encrypted TEXT NOT NULL,
            active BOOLEAN DEFAULT 1,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )''')
        
        c.execute('''CREATE TABLE IF NOT EXISTS campaigns (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL, type TEXT NOT NULL,
            subject TEXT, content TEXT,
            sent_at TIMESTAMP,
            recipients INTEGER DEFAULT 0,
            opens INTEGER DEFAULT 0,
            clicks INTEGER DEFAULT 0,
            status TEXT DEFAULT 'draft'
        )''')
        
        c.execute('''CREATE TABLE IF NOT EXISTS market_analysis (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            keyword TEXT NOT NULL, platform TEXT NOT NULL,
            data TEXT NOT NULL,
            analyzed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )''')
        
        c.execute('''CREATE TABLE IF NOT EXISTS subscribers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT UNIQUE NOT NULL,
            first_name TEXT, last_name TEXT,
            tags TEXT, status TEXT DEFAULT 'active',
            subscribed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )''')
        
        # Store app signature
        sig_hash = generate_digital_signature({
            "project": APP_NAME, "version": VERSION,
            "license": LICENSE_CODE, "date": BUILD_DATE
        })
        c.execute('''INSERT OR REPLACE INTO digital_signatures 
                    (entity_type, entity_id, sha256_hash, signer, license_code)
                    VALUES (?, ?, ?, ?, ?)''',
                 ('application', f'{APP_NAME}_v{VERSION}', sig_hash,
                  ' & '.join(DEVELOPERS), LICENSE_CODE))
        
        # Ensure $1799 token entry exists
        c.execute('''INSERT OR IGNORE INTO tokens (symbol, name, contract_address, network, decimals)
                    VALUES ('$1799', 'Gene1799 Token', 'zora.co/gene1799', 'Base', 18)''')
        
        conn.commit()
        conn.close()
    
    def load_configs(self):
        """Load or create configuration files"""
        config_file = self.dirs['config'] / 'master.json'
        if not config_file.exists():
            config = {
                'app_name': APP_NAME, 'version': VERSION,
                'initialized': datetime.now().isoformat(),
                'developers': DEVELOPERS, 'license': LICENSE_CODE,
                'company': COMPANY, 'sha256_signature': self.app_signature,
                'server': {'port': 8888, 'auto_start': True},
                'backup': {'auto_backup': True, 'frequency': 'daily'},
                'features': {
                    'ai_agents': True, 'social_media': True,
                    'web3': True, 'content_creation': True,
                    'token_1799': True, 'script_manager': True
                },
                'zora_token': ZORA_TOKEN
            }
            with open(config_file, 'w') as f:
                json.dump(config, f, indent=2)
    
    def log(self, level, message, module='system'):
        """Log to database"""
        try:
            conn = sqlite3.connect(self.db_path)
            c = conn.cursor()
            uid = self.current_user['id'] if self.current_user else None
            c.execute('INSERT INTO logs (level, message, module, user_id) VALUES (?,?,?,?)',
                     (level, message, module, uid))
            conn.commit()
            conn.close()
        except:
            pass
    
    # ═══════════════════════════════════════════════════════════
    #  AUTHENTICATION SYSTEM
    # ═══════════════════════════════════════════════════════════
    
    def show_login_screen(self):
        """Show login/registration screen"""
        # Clear root
        for w in self.root.winfo_children():
            w.destroy()
        
        self.root.configure(bg='#000000')
        
        # Main container
        container = tk.Frame(self.root, bg='#000000')
        container.place(relx=0.5, rely=0.5, anchor='center')
        
        # Logo
        tk.Label(container, text="⬢", font=('Arial', 60),
                fg='#00FF00', bg='#000000').pack()
        tk.Label(container, text=APP_NAME.upper(),
                font=('Courier', 20, 'bold'), fg='#00FF00', bg='#000000').pack()
        tk.Label(container, text=f"v{VERSION} | {COMPANY}",
                font=('Courier', 8), fg='#008800', bg='#000000').pack(pady=(0, 5))
        
        # SHA-256 Signature display
        tk.Label(container, text=f"SHA-256: {self.app_signature[:32]}...",
                font=('Courier', 7), fg='#004400', bg='#000000').pack()
        tk.Label(container, text=f"Signed by: {' & '.join(DEVELOPERS)}",
                font=('Courier', 7), fg='#004400', bg='#000000').pack()
        tk.Label(container, text=f"License: {LICENSE_CODE}",
                font=('Courier', 7), fg='#004400', bg='#000000').pack(pady=(0, 20))
        
        # Login form
        form = tk.Frame(container, bg='#001100', relief='raised', bd=2, padx=30, pady=20)
        form.pack(padx=20, pady=10)
        
        tk.Label(form, text="🔐 ACCESSO", font=('Courier', 14, 'bold'),
                fg='#00FF00', bg='#001100').pack(pady=(0, 15))
        
        # Username/Email
        tk.Label(form, text="Username o Email:", font=('Courier', 9),
                fg='#00FF00', bg='#001100').pack(anchor='w')
        self.login_user_entry = tk.Entry(form, bg='#002200', fg='#00FF00',
                                         insertbackground='#00FF00', font=('Courier', 10), width=35)
        self.login_user_entry.pack(pady=(0, 10))
        
        # Password
        tk.Label(form, text="Password:", font=('Courier', 9),
                fg='#00FF00', bg='#001100').pack(anchor='w')
        self.login_pass_entry = tk.Entry(form, bg='#002200', fg='#00FF00', show='•',
                                         insertbackground='#00FF00', font=('Courier', 10), width=35)
        self.login_pass_entry.pack(pady=(0, 10))
        
        # OTP (Google Authenticator)
        tk.Label(form, text="OTP Google Authenticator (se attivo):", font=('Courier', 9),
                fg='#00FF00', bg='#001100').pack(anchor='w')
        self.login_otp_entry = tk.Entry(form, bg='#002200', fg='#00FF00',
                                        insertbackground='#00FF00', font=('Courier', 10), width=35)
        self.login_otp_entry.pack(pady=(0, 15))
        
        # Buttons
        btn_frame = tk.Frame(form, bg='#001100')
        btn_frame.pack()
        
        tk.Button(btn_frame, text="🔓 ACCEDI", command=self.do_login,
                 bg='#003300', fg='#00FF00', font=('Courier', 10, 'bold'),
                 padx=20, pady=8, cursor='hand2').pack(side='left', padx=5)
        
        tk.Button(btn_frame, text="📝 REGISTRATI", command=self.show_register_screen,
                 bg='#002200', fg='#00FF00', font=('Courier', 10, 'bold'),
                 padx=20, pady=8, cursor='hand2').pack(side='left', padx=5)
        
        # Password reset link
        tk.Button(container, text="Password dimenticata?", command=self.show_reset_password,
                 bg='#000000', fg='#008800', font=('Courier', 8),
                 relief='flat', cursor='hand2').pack(pady=5)
        
        # Skip login (dev mode)
        tk.Button(container, text="[Dev Mode - Skip Login]", command=self.dev_mode_login,
                 bg='#000000', fg='#333333', font=('Courier', 7),
                 relief='flat', cursor='hand2').pack(pady=5)
        
        # Bind Enter key
        self.login_pass_entry.bind('<Return>', lambda e: self.do_login())
        self.login_otp_entry.bind('<Return>', lambda e: self.do_login())
    
    def do_login(self):
        """Process login with OTP verification"""
        username = self.login_user_entry.get().strip()
        password = self.login_pass_entry.get().strip()
        otp_code = self.login_otp_entry.get().strip()
        
        if not username or not password:
            messagebox.showwarning("Errore", "Inserisci username e password")
            return
        
        conn = sqlite3.connect(self.db_path)
        c = conn.cursor()
        
        # Find user
        c.execute('SELECT * FROM users WHERE username = ? OR email = ?', (username, username))
        user = c.fetchone()
        
        if not user:
            messagebox.showerror("Errore", "Utente non trovato")
            conn.close()
            return
        
        uid, uname, email, salt, phash, fname, lname, totp_secret, totp_enabled, \
            email_verified, role, status, created, last_login = user
        
        # Verify password
        if not verify_password(password, salt, phash):
            messagebox.showerror("Errore", "Password non corretta")
            self.log('WARNING', f'Failed login attempt: {username}', 'auth')
            conn.close()
            return
        
        # Check email verification
        if not email_verified:
            messagebox.showwarning("Verifica Email",
                "Il tuo account non è ancora verificato.\nControlla la tua email per il codice OTP.")
            conn.close()
            self.show_email_verification(uid, email)
            return
        
        # Check TOTP (Google Authenticator)
        if totp_enabled and totp_secret:
            if not otp_code:
                messagebox.showwarning("OTP Richiesto",
                    "Inserisci il codice OTP da Google Authenticator")
                self.login_otp_entry.focus()
                conn.close()
                return
            
            if not verify_totp(totp_secret, otp_code):
                messagebox.showerror("Errore OTP", "Codice OTP non valido")
                conn.close()
                return
        
        # Create session
        token = generate_token(64)
        expires = datetime.now() + timedelta(days=7)
        c.execute('INSERT INTO user_sessions (user_id, token, expires_at) VALUES (?,?,?)',
                 (uid, token, expires.isoformat()))
        c.execute('UPDATE users SET last_login = CURRENT_TIMESTAMP WHERE id = ?', (uid,))
        conn.commit()
        conn.close()
        
        # Set current user
        self.current_user = {
            'id': uid, 'username': uname, 'email': email,
            'first_name': fname, 'last_name': lname,
            'role': role, 'totp_enabled': bool(totp_enabled)
        }
        self.session_token = token
        
        self.log('INFO', f'User logged in: {uname}', 'auth')
        
        # Show main interface
        self.show_main_interface()
    
    def show_register_screen(self):
        """Show registration screen"""
        for w in self.root.winfo_children():
            w.destroy()
        
        container = tk.Frame(self.root, bg='#000000')
        container.place(relx=0.5, rely=0.5, anchor='center')
        
        tk.Label(container, text="⬢", font=('Arial', 40), fg='#00FF00', bg='#000000').pack()
        tk.Label(container, text="REGISTRAZIONE", font=('Courier', 16, 'bold'),
                fg='#00FF00', bg='#000000').pack(pady=(0, 15))
        
        form = tk.Frame(container, bg='#001100', relief='raised', bd=2, padx=30, pady=20)
        form.pack()
        
        fields = {}
        for label, key, show in [
            ("Username:", "username", None),
            ("Email:", "email", None),
            ("Nome:", "first_name", None),
            ("Cognome:", "last_name", None),
            ("Password:", "password", '•'),
            ("Conferma Password:", "password2", '•'),
        ]:
            tk.Label(form, text=label, font=('Courier', 9), fg='#00FF00', bg='#001100').pack(anchor='w')
            e = tk.Entry(form, bg='#002200', fg='#00FF00', insertbackground='#00FF00',
                        font=('Courier', 10), width=35, show=show)
            e.pack(pady=(0, 8))
            fields[key] = e
        
        # Google Authenticator option
        totp_var = tk.BooleanVar(value=True)
        tk.Checkbutton(form, text="Attiva Google Authenticator (2FA)",
                      variable=totp_var, fg='#00FF00', bg='#001100',
                      selectcolor='#002200', font=('Courier', 9)).pack(pady=5)
        
        def do_register():
            data = {k: v.get().strip() for k, v in fields.items()}
            
            if not all([data['username'], data['email'], data['password']]):
                messagebox.showwarning("Errore", "Compila tutti i campi obbligatori")
                return
            
            if not validate_email(data['email']):
                messagebox.showwarning("Errore", "Email non valida")
                return
            
            if data['password'] != data['password2']:
                messagebox.showwarning("Errore", "Le password non corrispondono")
                return
            
            if len(data['password']) < 6:
                messagebox.showwarning("Errore", "Password min 6 caratteri")
                return
            
            # Hash password
            salt, phash = hash_password(data['password'])
            
            # Generate TOTP secret
            totp_secret = generate_totp_secret() if totp_var.get() else None
            
            try:
                conn = sqlite3.connect(self.db_path)
                c = conn.cursor()
                c.execute('''INSERT INTO users 
                    (username, email, password_salt, password_hash, first_name, last_name, 
                     totp_secret, totp_enabled, status)
                    VALUES (?,?,?,?,?,?,?,?,?)''',
                    (data['username'], data['email'], salt, phash,
                     data['first_name'], data['last_name'],
                     totp_secret, 1 if totp_var.get() else 0, 'pending'))
                user_id = c.lastrowid
                
                # Generate email verification OTP
                otp = generate_otp()
                expires = datetime.now() + timedelta(minutes=10)
                c.execute('INSERT INTO email_verifications (user_id, otp_code, expires_at) VALUES (?,?,?)',
                         (user_id, otp, expires.isoformat()))
                
                conn.commit()
                conn.close()
                
                # Try to send email
                email_sent = self.email_system.send_confirmation_email(
                    data['email'], otp, data['first_name'] or data['username'])
                
                self.log('INFO', f'New user registered: {data["username"]}', 'auth')
                
                # Show TOTP setup if enabled
                if totp_var.get() and totp_secret:
                    self.show_totp_setup(totp_secret, data['username'], data['email'])
                
                # Show email verification screen
                msg = f"Registrazione completata!\n\n"
                if email_sent:
                    msg += f"Un codice OTP è stato inviato a {data['email']}"
                else:
                    msg += f"Il tuo codice OTP è: {otp}\n(Email non configurata - codice mostrato qui)"
                
                messagebox.showinfo("Successo", msg)
                self.show_email_verification(user_id, data['email'])
                
            except sqlite3.IntegrityError:
                messagebox.showerror("Errore", "Username o email già registrati")
            except Exception as e:
                messagebox.showerror("Errore", str(e))
        
        tk.Button(form, text="📝 REGISTRATI", command=do_register,
                 bg='#003300', fg='#00FF00', font=('Courier', 10, 'bold'),
                 padx=25, pady=8).pack(pady=15)
        
        tk.Button(container, text="← Torna al Login", command=self.show_login_screen,
                 bg='#000000', fg='#008800', font=('Courier', 9),
                 relief='flat', cursor='hand2').pack(pady=10)
    
    def show_totp_setup(self, secret, username, email):
        """Show TOTP setup dialog for Google Authenticator"""
        dialog = tk.Toplevel(self.root)
        dialog.title("Setup Google Authenticator")
        dialog.geometry("500x400")
        dialog.configure(bg='#000000')
        dialog.transient(self.root)
        dialog.grab_set()
        
        tk.Label(dialog, text="🔐 Google Authenticator Setup",
                font=('Courier', 14, 'bold'), fg='#00FF00', bg='#000000').pack(pady=15)
        
        tk.Label(dialog, text="Aggiungi questo account a Google Authenticator:",
                font=('Courier', 9), fg='#00FF00', bg='#000000').pack()
        
        # Manual entry info
        info_frame = tk.Frame(dialog, bg='#001100', relief='raised', bd=2, padx=20, pady=15)
        info_frame.pack(padx=20, pady=15, fill='x')
        
        tk.Label(info_frame, text="Account:", font=('Courier', 9), fg='#008800', bg='#001100').pack(anchor='w')
        tk.Label(info_frame, text=f"{APP_NAME}:{email}", font=('Courier', 10), fg='#00FF00', bg='#001100').pack(anchor='w', pady=(0, 10))
        
        tk.Label(info_frame, text="Secret Key (inserisci manualmente):", font=('Courier', 9), fg='#008800', bg='#001100').pack(anchor='w')
        
        secret_entry = tk.Entry(info_frame, bg='#002200', fg='#FFD700', font=('Courier', 12, 'bold'),
                               width=35, justify='center')
        secret_entry.insert(0, secret)
        secret_entry.config(state='readonly')
        secret_entry.pack(pady=5)
        
        # TOTP URI for QR code generation
        totp_uri = f"otpauth://totp/{APP_NAME}:{email}?secret={secret}&issuer={APP_NAME}"
        
        tk.Label(info_frame, text="TOTP URI:", font=('Courier', 9), fg='#008800', bg='#001100').pack(anchor='w', pady=(10, 0))
        uri_entry = tk.Entry(info_frame, bg='#002200', fg='#00AAFF', font=('Courier', 7), width=55)
        uri_entry.insert(0, totp_uri)
        uri_entry.config(state='readonly')
        uri_entry.pack(pady=5)
        
        def copy_secret():
            self.root.clipboard_clear()
            self.root.clipboard_append(secret)
            messagebox.showinfo("Copiato", "Secret key copiato negli appunti")
        
        tk.Button(dialog, text="📋 Copia Secret Key", command=copy_secret,
                 bg='#003300', fg='#00FF00', font=('Courier', 9),
                 padx=15, pady=5).pack(pady=5)
        
        tk.Label(dialog, text="⚠️ IMPORTANTE: Salva questo secret key in un luogo sicuro!\n"
                "Lo userai per configurare Google Authenticator.",
                font=('Courier', 8), fg='#FFAA00', bg='#000000', justify='center').pack(pady=10)
        
        tk.Button(dialog, text="✅ Ho configurato Google Authenticator", command=dialog.destroy,
                 bg='#003300', fg='#00FF00', font=('Courier', 10, 'bold'),
                 padx=20, pady=8).pack(pady=10)
    
    def show_email_verification(self, user_id, email):
        """Show email OTP verification screen"""
        for w in self.root.winfo_children():
            w.destroy()
        
        container = tk.Frame(self.root, bg='#000000')
        container.place(relx=0.5, rely=0.5, anchor='center')
        
        tk.Label(container, text="📧 VERIFICA EMAIL",
                font=('Courier', 16, 'bold'), fg='#00FF00', bg='#000000').pack(pady=15)
        
        tk.Label(container, text=f"Inserisci il codice OTP inviato a:\n{email}",
                font=('Courier', 10), fg='#00CC00', bg='#000000').pack(pady=10)
        
        otp_entry = tk.Entry(container, bg='#002200', fg='#FFD700', font=('Courier', 24, 'bold'),
                           width=10, justify='center', insertbackground='#FFD700')
        otp_entry.pack(pady=15)
        otp_entry.focus()
        
        def verify():
            code = otp_entry.get().strip()
            if not code:
                return
            
            conn = sqlite3.connect(self.db_path)
            c = conn.cursor()
            c.execute('''SELECT otp_code FROM email_verifications 
                        WHERE user_id = ? AND verified = 0 AND expires_at > ?
                        ORDER BY created_at DESC LIMIT 1''',
                     (user_id, datetime.now().isoformat()))
            result = c.fetchone()
            
            if result and result[0] == code:
                c.execute('UPDATE email_verifications SET verified = 1 WHERE user_id = ?', (user_id,))
                c.execute('UPDATE users SET email_verified = 1, status = ? WHERE id = ?', ('active', user_id))
                conn.commit()
                conn.close()
                
                self.log('INFO', f'Email verified for user_id: {user_id}', 'auth')
                messagebox.showinfo("Verificato!", "Email verificata con successo!\nOra puoi accedere.")
                self.show_login_screen()
            else:
                conn.close()
                messagebox.showerror("Errore", "Codice OTP non valido o scaduto")
        
        tk.Button(container, text="✅ VERIFICA", command=verify,
                 bg='#003300', fg='#00FF00', font=('Courier', 12, 'bold'),
                 padx=30, pady=10).pack(pady=10)
        
        def resend_otp():
            otp = generate_otp()
            expires = datetime.now() + timedelta(minutes=10)
            conn = sqlite3.connect(self.db_path)
            c = conn.cursor()
            c.execute('INSERT INTO email_verifications (user_id, otp_code, expires_at) VALUES (?,?,?)',
                     (user_id, otp, expires.isoformat()))
            conn.commit()
            conn.close()
            
            sent = self.email_system.send_confirmation_email(email, otp)
            if sent:
                messagebox.showinfo("Inviato", f"Nuovo OTP inviato a {email}")
            else:
                messagebox.showinfo("OTP", f"Nuovo OTP: {otp}\n(Email non configurata)")
        
        tk.Button(container, text="🔄 Reinvia OTP", command=resend_otp,
                 bg='#002200', fg='#00CC00', font=('Courier', 9),
                 padx=15, pady=5).pack(pady=5)
        
        tk.Button(container, text="← Torna al Login", command=self.show_login_screen,
                 bg='#000000', fg='#008800', font=('Courier', 9),
                 relief='flat').pack(pady=10)
        
        otp_entry.bind('<Return>', lambda e: verify())
    
    def show_reset_password(self):
        """Show password reset dialog"""
        email = simpledialog.askstring("Reset Password", "Inserisci la tua email:",
                                       parent=self.root)
        if not email:
            return
        
        conn = sqlite3.connect(self.db_path)
        c = conn.cursor()
        c.execute('SELECT id, first_name FROM users WHERE email = ?', (email,))
        user = c.fetchone()
        
        if user:
            token = generate_token(32)
            expires = datetime.now() + timedelta(hours=1)
            c.execute('INSERT INTO password_resets (user_id, reset_token, expires_at) VALUES (?,?,?)',
                     (user[0], token, expires.isoformat()))
            conn.commit()
            
            sent = self.email_system.send_password_reset(email, token, user[1] or "User")
            if sent:
                messagebox.showinfo("Reset", f"Link di reset inviato a {email}")
            else:
                messagebox.showinfo("Reset", f"Token di reset: {token}\n(Email non configurata)")
        else:
            messagebox.showinfo("Reset", "Se l'email è registrata, riceverai un link di reset.")
        
        conn.close()
    
    def dev_mode_login(self):
        """Quick login for development"""
        self.current_user = {
            'id': 0, 'username': 'developer', 'email': 'dev@gene1799.art',
            'first_name': 'Dev', 'last_name': 'Mode', 'role': 'admin',
            'totp_enabled': False
        }
        self.session_token = 'dev_session'
        self.show_main_interface()
    
    # ═══════════════════════════════════════════════════════════
    #  MAIN INTERFACE
    # ═══════════════════════════════════════════════════════════
    
    def show_main_interface(self):
        """Show main application interface"""
        for w in self.root.winfo_children():
            w.destroy()
        
        # Top Bar
        top_bar = tk.Frame(self.root, bg='#001100', height=90, relief='raised', bd=2)
        top_bar.pack(fill='x')
        top_bar.pack_propagate(False)
        
        logo_frame = tk.Frame(top_bar, bg='#001100')
        logo_frame.pack(pady=5)
        
        tk.Label(logo_frame, text=f"⬢ {APP_NAME.upper()}",
                font=('Courier', 22, 'bold'), fg='#00FF00', bg='#001100').pack()
        tk.Label(logo_frame, text=f"v{VERSION} | SHA-256 Verified | {self.current_user['username']}",
                font=('Courier', 8), fg='#008800', bg='#001100').pack()
        
        # Status indicators
        status_frame = tk.Frame(top_bar, bg='#001100')
        status_frame.pack()
        
        self.status_labels = {}
        for icon, name in [('💾','DB'), ('🌐','Server'), ('🤖','AI'), ('📱','Social'),
                           ('⛓️','Web3'), ('🪙','$1799'), ('📜','Scripts'), ('🔐','Auth')]:
            f = tk.Frame(status_frame, bg='#001100')
            f.pack(side='left', padx=6)
            tk.Label(f, text=icon, font=('Arial', 10), bg='#001100').pack(side='left')
            lbl = tk.Label(f, text=name, font=('Courier', 7), fg='#00FF00', bg='#001100')
            lbl.pack(side='left', padx=2)
            self.status_labels[name] = lbl
        
        # User info & logout
        user_frame = tk.Frame(top_bar, bg='#001100')
        user_frame.pack(side='right', padx=10)
        
        tk.Button(user_frame, text="🚪 Logout", command=self.logout,
                 bg='#330000', fg='#00FF00', font=('Courier', 8),
                 padx=8, pady=2).pack(side='right')
        
        # Main Notebook
        self.notebook = ttk.Notebook(self.root)
        self.notebook.pack(fill='both', expand=True, padx=5, pady=5)
        
        # Create all tabs
        self.create_tab_dashboard()
        self.create_tab_ai_agents()
        self.create_tab_social()
        self.create_tab_content()
        self.create_tab_web3()
        self.create_tab_token_1799()
        self.create_tab_scripts()
        self.create_tab_signatures()
        self.create_tab_system()
        
        # Bottom Bar
        bottom = tk.Frame(self.root, bg='#001100', height=30, relief='raised', bd=2)
        bottom.pack(fill='x', side='bottom')
        bottom.pack_propagate(False)
        
        tk.Label(bottom,
                text=f"{APP_NAME} v{VERSION} | {' & '.join(DEVELOPERS)} | License: {LICENSE_CODE} | © {COMPANY} | SHA-256: {self.app_signature[:24]}...",
                font=('Courier', 6), fg='#008800', bg='#001100').pack(pady=7)
    
    def logout(self):
        """Logout current user"""
        if self.session_token:
            try:
                conn = sqlite3.connect(self.db_path)
                c = conn.cursor()
                c.execute('DELETE FROM user_sessions WHERE token = ?', (self.session_token,))
                conn.commit()
                conn.close()
            except:
                pass
        
        self.log('INFO', f'User logged out: {self.current_user["username"]}', 'auth')
        self.current_user = None
        self.session_token = None
        self.show_login_screen()
    
    # ═══════════════════════════════════════════════════════════
    #  TAB: DASHBOARD
    # ═══════════════════════════════════════════════════════════
    
    def create_tab_dashboard(self):
        tab = tk.Frame(self.notebook, bg='#000000')
        self.notebook.add(tab, text='📊 DASHBOARD')
        
        tk.Label(tab, text="📊 DASHBOARD SISTEMA",
                font=('Courier', 16, 'bold'), fg='#00FF00', bg='#000000').pack(pady=10)
        
        # Stats
        stats_frame = tk.Frame(tab, bg='#000000')
        stats_frame.pack(fill='x', padx=20, pady=10)
        
        conn = sqlite3.connect(self.db_path)
        c = conn.cursor()
        
        stats = []
        for table, icon in [('ai_agents', '🤖'), ('social_posts', '📱'), ('nfts', '🎨'),
                            ('content', '✨'), ('scripts_registry', '📜')]:
            try:
                c.execute(f'SELECT COUNT(*) FROM {table}')
                stats.append((f'{icon} {table.replace("_", " ").title()}', c.fetchone()[0]))
            except:
                stats.append((f'{icon} {table}', 0))
        conn.close()
        
        for i, (label, value) in enumerate(stats):
            card = tk.Frame(stats_frame, bg='#002200', relief='raised', bd=2)
            card.grid(row=0, column=i, padx=8, pady=5, ipadx=12, ipady=10)
            tk.Label(card, text=str(value), font=('Courier', 20, 'bold'),
                    fg='#00FF00', bg='#002200').pack()
            tk.Label(card, text=label, font=('Courier', 7), fg='#00CC00', bg='#002200').pack()
        
        # Quick Actions
        actions = tk.Frame(tab, bg='#001100', relief='raised', bd=2)
        actions.pack(fill='both', expand=True, padx=20, pady=10)
        
        tk.Label(actions, text="🚀 AZIONI RAPIDE",
                font=('Courier', 13, 'bold'), fg='#00FF00', bg='#001100').pack(pady=10)
        
        btn_frame = tk.Frame(actions, bg='#001100')
        btn_frame.pack(pady=10)
        
        buttons = [
            ('🌐 Web Interface', self.open_web),
            ('🤖 Nuovo AI Agent', lambda: self.notebook.select(1)),
            ('📱 Programma Post', lambda: self.notebook.select(2)),
            ('🪙 Token $1799', lambda: self.notebook.select(5)),
            ('📜 Aggiungi Script', lambda: self.notebook.select(6)),
            ('💾 Backup', self.backup_system),
            ('🔐 Firma SHA-256', lambda: self.notebook.select(7)),
        ]
        
        for i, (text, cmd) in enumerate(buttons):
            tk.Button(btn_frame, text=text, command=cmd,
                     bg='#003300', fg='#00FF00', font=('Courier', 8, 'bold'),
                     relief='raised', bd=2, padx=10, pady=6, cursor='hand2').grid(
                     row=i // 4, column=i % 4, padx=4, pady=4)
        
        # System info
        info_frame = tk.Frame(actions, bg='#001100')
        info_frame.pack(fill='x', padx=15, pady=10)
        
        sys_info = f"OS: {platform.system()} {platform.release()} | Python: {sys.version.split()[0]}"
        if HAS_PSUTIL:
            sys_info += f" | CPU: {psutil.cpu_percent()}% | RAM: {psutil.virtual_memory().percent}%"
        sys_info += f" | Server: {'🟢 Online' if self.server_running else '🔴 Offline'} (:{self.server_port})"
        
        tk.Label(info_frame, text=sys_info, font=('Courier', 7), fg='#008800', bg='#001100').pack()
    
    # ═══════════════════════════════════════════════════════════
    #  TAB: AI AGENTS
    # ═══════════════════════════════════════════════════════════
    
    def create_tab_ai_agents(self):
        tab = tk.Frame(self.notebook, bg='#000000')
        self.notebook.add(tab, text='🤖 AI AGENTS')
        
        header = tk.Frame(tab, bg='#001100', relief='raised', bd=2)
        header.pack(fill='x', padx=10, pady=10)
        
        tk.Label(header, text="🤖 AI AGENTS MANAGER - Espandibile",
                font=('Courier', 13, 'bold'), fg='#00FF00', bg='#001100').pack(pady=8)
        
        btn_frame = tk.Frame(header, bg='#001100')
        btn_frame.pack(pady=5)
        
        for text, cmd in [("➕ NUOVO AGENT", self.create_agent_dialog),
                          ("📜 AGGIUNGI SCRIPT", self.add_script_to_agent),
                          ("🔄 AGGIORNA", self.refresh_agents)]:
            tk.Button(btn_frame, text=text, command=cmd, bg='#003300', fg='#00FF00',
                     font=('Courier', 9, 'bold'), padx=12, pady=5).pack(side='left', padx=3)
        
        # Agents TreeView
        list_frame = tk.Frame(tab, bg='#001100', relief='raised', bd=2)
        list_frame.pack(fill='both', expand=True, padx=10, pady=10)
        
        columns = ('Name', 'Type', 'Status', 'Runs', 'Success', 'Last Run')
        self.agents_tree = ttk.Treeview(list_frame, columns=columns, show='headings', height=12)
        for col in columns:
            self.agents_tree.heading(col, text=col)
            self.agents_tree.column(col, width=140)
        
        scrollbar = ttk.Scrollbar(list_frame, orient='vertical', command=self.agents_tree.yview)
        self.agents_tree.configure(yscrollcommand=scrollbar.set)
        self.agents_tree.pack(side='left', fill='both', expand=True, padx=5, pady=5)
        scrollbar.pack(side='right', fill='y', pady=5)
        
        # Actions
        actions = tk.Frame(tab, bg='#001100', relief='raised', bd=2)
        actions.pack(fill='x', padx=10, pady=10)
        
        for text, cmd in [("▶️ ESEGUI", self.run_agent), ("✏️ MODIFICA", self.edit_agent),
                          ("🗑️ ELIMINA", self.delete_agent), ("📊 STATS", self.agent_stats)]:
            tk.Button(actions, text=text, command=cmd, bg='#003300', fg='#00FF00',
                     font=('Courier', 9, 'bold'), padx=10, pady=5).pack(side='left', padx=5, pady=5)
        
        self.refresh_agents()
    
    def create_agent_dialog(self):
        dialog = tk.Toplevel(self.root)
        dialog.title("Crea Nuovo AI Agent")
        dialog.geometry("600x500")
        dialog.configure(bg='#000000')
        dialog.transient(self.root)
        dialog.grab_set()
        
        tk.Label(dialog, text="🤖 CREA NUOVO AI AGENT",
                font=('Courier', 14, 'bold'), fg='#00FF00', bg='#000000').pack(pady=10)
        
        form = tk.Frame(dialog, bg='#001100', relief='raised', bd=2, padx=15, pady=15)
        form.pack(fill='both', expand=True, padx=15, pady=10)
        
        # Name
        tk.Label(form, text="Nome:", fg='#00FF00', bg='#001100', font=('Courier', 9)).pack(anchor='w')
        name_e = tk.Entry(form, bg='#002200', fg='#00FF00', insertbackground='#00FF00', font=('Courier', 10), width=45)
        name_e.pack(pady=(0, 8))
        
        # Type
        tk.Label(form, text="Tipo:", fg='#00FF00', bg='#001100', font=('Courier', 9)).pack(anchor='w')
        type_var = tk.StringVar(value='text_generation')
        types = ['text_generation', 'social_automation', 'video_generation', 'image_generation',
                'audio_generation', 'data_analysis', 'nft_creation', 'market_analysis', 'custom']
        ttk.Combobox(form, textvariable=type_var, values=types, width=43).pack(pady=(0, 8))
        
        # Description
        tk.Label(form, text="Descrizione:", fg='#00FF00', bg='#001100', font=('Courier', 9)).pack(anchor='w')
        desc_t = scrolledtext.ScrolledText(form, height=4, bg='#002200', fg='#00FF00',
                                            insertbackground='#00FF00', font=('Courier', 9))
        desc_t.pack(fill='x', pady=(0, 8))
        
        # Script
        tk.Label(form, text="Script (opzionale):", fg='#00FF00', bg='#001100', font=('Courier', 9)).pack(anchor='w')
        sf = tk.Frame(form, bg='#001100')
        sf.pack(fill='x', pady=(0, 8))
        script_e = tk.Entry(sf, bg='#002200', fg='#00FF00', insertbackground='#00FF00', font=('Courier', 9))
        script_e.pack(side='left', fill='x', expand=True)
        tk.Button(sf, text="📁", command=lambda: self._browse_file(script_e),
                 bg='#003300', fg='#00FF00', padx=8).pack(side='right', padx=5)
        
        def save():
            name = name_e.get().strip()
            if not name:
                messagebox.showwarning("Errore", "Inserisci nome")
                return
            try:
                conn = sqlite3.connect(self.db_path)
                c = conn.cursor()
                c.execute('INSERT INTO ai_agents (name,type,description,script_path,status,owner_id) VALUES (?,?,?,?,?,?)',
                         (name, type_var.get(), desc_t.get('1.0', 'end-1c').strip(),
                          script_e.get().strip(), 'active', self.current_user['id'] if self.current_user else None))
                conn.commit()
                conn.close()
                self.log('INFO', f'Agent created: {name}', 'ai_agents')
                messagebox.showinfo("OK", f"Agent '{name}' creato!")
                dialog.destroy()
                self.refresh_agents()
            except sqlite3.IntegrityError:
                messagebox.showerror("Errore", "Agent già esistente")
        
        tk.Button(dialog, text="💾 SALVA", command=save, bg='#003300', fg='#00FF00',
                 font=('Courier', 10, 'bold'), padx=20, pady=8).pack(pady=10)
    
    def refresh_agents(self):
        if not hasattr(self, 'agents_tree'):
            return
        for item in self.agents_tree.get_children():
            self.agents_tree.delete(item)
        conn = sqlite3.connect(self.db_path)
        c = conn.cursor()
        c.execute('SELECT name,type,status,runs_count,success_rate,last_run FROM ai_agents ORDER BY id DESC')
        for a in c.fetchall():
            self.agents_tree.insert('', 'end', values=(a[0], a[1], a[2], a[3], f"{a[4]:.1f}%", a[5] or 'Mai'))
        conn.close()
    
    def run_agent(self):
        sel = self.agents_tree.selection()
        if not sel:
            messagebox.showwarning("!", "Seleziona agent")
            return
        name = self.agents_tree.item(sel[0])['values'][0]
        conn = sqlite3.connect(self.db_path)
        c = conn.cursor()
        c.execute('SELECT script_path FROM ai_agents WHERE name=?', (name,))
        r = c.fetchone()
        if r and r[0] and Path(r[0]).exists():
            subprocess.Popen([sys.executable, r[0]])
            messagebox.showinfo("OK", f"Agent '{name}' avviato!")
        else:
            messagebox.showinfo("OK", f"Agent '{name}' eseguito (simulazione)")
        c.execute('UPDATE ai_agents SET last_run=CURRENT_TIMESTAMP, runs_count=runs_count+1 WHERE name=?', (name,))
        conn.commit()
        conn.close()
        self.refresh_agents()
    
    def edit_agent(self):
        messagebox.showinfo("Edit", "Funzione modifica in sviluppo")
    
    def delete_agent(self):
        sel = self.agents_tree.selection()
        if not sel:
            return
        name = self.agents_tree.item(sel[0])['values'][0]
        if messagebox.askyesno("Conferma", f"Eliminare '{name}'?"):
            conn = sqlite3.connect(self.db_path)
            conn.execute('DELETE FROM ai_agents WHERE name=?', (name,))
            conn.commit()
            conn.close()
            self.refresh_agents()
    
    def agent_stats(self):
        sel = self.agents_tree.selection()
        if not sel:
            return
        name = self.agents_tree.item(sel[0])['values'][0]
        conn = sqlite3.connect(self.db_path)
        c = conn.cursor()
        c.execute('SELECT runs_count,success_rate,last_run,created_at FROM ai_agents WHERE name=?', (name,))
        s = c.fetchone()
        conn.close()
        if s:
            messagebox.showinfo("Stats", f"Agent: {name}\nRuns: {s[0]}\nSuccess: {s[1]:.1f}%\nLast: {s[2] or 'Mai'}\nCreated: {s[3]}")
    
    def add_script_to_agent(self):
        sel = self.agents_tree.selection()
        if not sel:
            messagebox.showwarning("!", "Seleziona agent")
            return
        f = filedialog.askopenfilename(filetypes=[("Python", "*.py"), ("JS", "*.js"), ("All", "*.*")])
        if f:
            name = self.agents_tree.item(sel[0])['values'][0]
            dest = self.dirs['ai_scripts'] / Path(f).name
            shutil.copy(f, dest)
            conn = sqlite3.connect(self.db_path)
            conn.execute('UPDATE ai_agents SET script_path=? WHERE name=?', (str(dest), name))
            conn.commit()
            conn.close()
            messagebox.showinfo("OK", f"Script aggiunto a '{name}'")
            self.refresh_agents()
    
    # ═══════════════════════════════════════════════════════════
    #  TAB: SOCIAL MEDIA
    # ═══════════════════════════════════════════════════════════
    
    def create_tab_social(self):
        tab = tk.Frame(self.notebook, bg='#000000')
        self.notebook.add(tab, text='📱 SOCIAL')
        
        sub_nb = ttk.Notebook(tab)
        sub_nb.pack(fill='both', expand=True, padx=5, pady=5)
        
        # Scheduler tab
        sched_tab = tk.Frame(sub_nb, bg='#000000')
        sub_nb.add(sched_tab, text='📅 SCHEDULER')
        
        tk.Label(sched_tab, text="📅 POST SCHEDULER",
                font=('Courier', 13, 'bold'), fg='#00FF00', bg='#000000').pack(pady=10)
        
        form = tk.Frame(sched_tab, bg='#001100', relief='raised', bd=2)
        form.pack(fill='x', padx=10, pady=10)
        
        tk.Label(form, text="Contenuto:", fg='#00FF00', bg='#001100', font=('Courier', 9)).pack(anchor='w', padx=10, pady=5)
        content_text = scrolledtext.ScrolledText(form, height=5, bg='#002200', fg='#00FF00',
                                                  insertbackground='#00FF00', font=('Courier', 9))
        content_text.pack(fill='x', padx=10, pady=5)
        
        # Date/Time
        dt_frame = tk.Frame(form, bg='#001100')
        dt_frame.pack(fill='x', padx=10, pady=5)
        tk.Label(dt_frame, text="Data:", fg='#00FF00', bg='#001100').pack(side='left')
        date_e = tk.Entry(dt_frame, bg='#002200', fg='#00FF00', insertbackground='#00FF00', width=12)
        date_e.insert(0, datetime.now().strftime('%Y-%m-%d'))
        date_e.pack(side='left', padx=5)
        tk.Label(dt_frame, text="Ora:", fg='#00FF00', bg='#001100').pack(side='left')
        time_e = tk.Entry(dt_frame, bg='#002200', fg='#00FF00', insertbackground='#00FF00', width=8)
        time_e.insert(0, '12:00')
        time_e.pack(side='left', padx=5)
        
        # Platforms
        pf = tk.Frame(form, bg='#001100')
        pf.pack(fill='x', padx=10, pady=5)
        platform_vars = {}
        for i, p in enumerate(['Facebook', 'Instagram', 'Twitter/X', 'LinkedIn', 'TikTok',
                               'YouTube', 'Telegram', 'Discord', 'Reddit', 'Farcaster', 'Lens']):
            var = tk.BooleanVar()
            platform_vars[p] = var
            tk.Checkbutton(pf, text=p, variable=var, fg='#00FF00', bg='#001100',
                          selectcolor='#002200', font=('Courier', 8)).grid(row=i//4, column=i%4, sticky='w', padx=3)
        
        def schedule():
            content = content_text.get('1.0', 'end-1c').strip()
            selected = [p for p, v in platform_vars.items() if v.get()]
            if not content or not selected:
                messagebox.showwarning("!", "Inserisci contenuto e piattaforme")
                return
            sched_dt = f"{date_e.get()} {time_e.get()}:00"
            conn = sqlite3.connect(self.db_path)
            conn.execute('INSERT INTO social_posts (content,platforms,scheduled_time,status,owner_id) VALUES (?,?,?,?,?)',
                        (content, ','.join(selected), sched_dt, 'scheduled',
                         self.current_user['id'] if self.current_user else None))
            conn.commit()
            conn.close()
            messagebox.showinfo("OK", f"Post programmato per {sched_dt}")
            content_text.delete('1.0', 'end')
            self.refresh_scheduled_posts()
        
        tk.Button(form, text="📅 PROGRAMMA", command=schedule,
                 bg='#003300', fg='#00FF00', font=('Courier', 10, 'bold'),
                 padx=20, pady=8).pack(pady=10)
        
        # Scheduled list
        list_f = tk.Frame(sched_tab, bg='#001100', relief='raised', bd=2)
        list_f.pack(fill='both', expand=True, padx=10, pady=10)
        
        cols = ('Content', 'Platforms', 'Date', 'Status')
        self.sched_tree = ttk.Treeview(list_f, columns=cols, show='headings', height=8)
        for c in cols:
            self.sched_tree.heading(c, text=c)
        self.sched_tree.pack(fill='both', expand=True, padx=5, pady=5)
        self.refresh_scheduled_posts()
        
        # Analytics tab
        analytics_tab = tk.Frame(sub_nb, bg='#000000')
        sub_nb.add(analytics_tab, text='📊 ANALYTICS')
        tk.Label(analytics_tab, text="📊 Social Analytics - Coming Soon",
                font=('Courier', 14), fg='#00FF00', bg='#000000').pack(pady=50)
    
    def refresh_scheduled_posts(self):
        if not hasattr(self, 'sched_tree'):
            return
        for item in self.sched_tree.get_children():
            self.sched_tree.delete(item)
        conn = sqlite3.connect(self.db_path)
        c = conn.cursor()
        c.execute("SELECT content,platforms,scheduled_time,status FROM social_posts WHERE status='scheduled' ORDER BY scheduled_time")
        for p in c.fetchall():
            preview = (p[0][:40] + '...') if len(p[0]) > 40 else p[0]
            self.sched_tree.insert('', 'end', values=(preview, p[1], p[2], p[3]))
        conn.close()
    
    # ═══════════════════════════════════════════════════════════
    #  TAB: CONTENT CREATION
    # ═══════════════════════════════════════════════════════════
    
    def create_tab_content(self):
        tab = tk.Frame(self.notebook, bg='#000000')
        self.notebook.add(tab, text='✨ CONTENT')
        
        tk.Label(tab, text="✨ CONTENT CREATION",
                font=('Courier', 14, 'bold'), fg='#00FF00', bg='#000000').pack(pady=20)
        
        types_frame = tk.Frame(tab, bg='#000000')
        types_frame.pack(pady=20)
        
        for i, (text, icon) in enumerate([('VIDEO', '🎬'), ('IMAGE', '🖼️'), ('AUDIO', '🎵'),
                                            ('TEXT', '📝'), ('AD', '📺'), ('ANALYTICS', '📊')]):
            tk.Button(types_frame, text=f"{icon} {text}",
                     command=lambda t=text: messagebox.showinfo(t, f"{t} creation - server integration pending"),
                     bg='#002200', fg='#00FF00', font=('Courier', 11, 'bold'),
                     relief='raised', bd=2, width=15, height=3, cursor='hand2').grid(
                     row=i // 3, column=i % 3, padx=10, pady=10)
    
    # ═══════════════════════════════════════════════════════════
    #  TAB: WEB3
    # ═══════════════════════════════════════════════════════════
    
    def create_tab_web3(self):
        tab = tk.Frame(self.notebook, bg='#000000')
        self.notebook.add(tab, text='⛓️ WEB3')
        
        sub_nb = ttk.Notebook(tab)
        sub_nb.pack(fill='both', expand=True, padx=5, pady=5)
        
        # NFT Tab
        nft_tab = tk.Frame(sub_nb, bg='#000000')
        sub_nb.add(nft_tab, text='🎨 NFT')
        
        tk.Label(nft_tab, text="🎨 NFT MANAGER",
                font=('Courier', 13, 'bold'), fg='#00FF00', bg='#000000').pack(pady=10)
        
        nft_actions = tk.Frame(nft_tab, bg='#001100', relief='raised', bd=2)
        nft_actions.pack(fill='x', padx=10, pady=10)
        
        for text, cmd in [("➕ CREA NFT", lambda: messagebox.showinfo("NFT", "NFT creation ready")),
                          ("🎨 AI GENERA", lambda: messagebox.showinfo("AI", "AI NFT generation ready")),
                          ("⛓️ MINT", lambda: messagebox.showinfo("Mint", "Mint ready - connect wallet"))]:
            tk.Button(nft_actions, text=text, command=cmd, bg='#003300', fg='#00FF00',
                     font=('Courier', 9, 'bold'), padx=12, pady=5).pack(side='left', padx=5, pady=5)
        
        # NFT list
        cols = ('Name', 'Network', 'Token ID', 'Status', 'Price')
        self.nft_tree = ttk.Treeview(nft_tab, columns=cols, show='headings', height=10)
        for c in cols:
            self.nft_tree.heading(c, text=c)
        self.nft_tree.pack(fill='both', expand=True, padx=10, pady=10)
        
        # Token tab
        token_tab = tk.Frame(sub_nb, bg='#000000')
        sub_nb.add(token_tab, text='🪙 TOKENS')
        tk.Label(token_tab, text="🪙 Token Manager - Multi-Chain",
                font=('Courier', 14), fg='#00FF00', bg='#000000').pack(pady=30)
    
    # ═══════════════════════════════════════════════════════════
    #  TAB: TOKEN $1799 (ZORA.CO)
    # ═══════════════════════════════════════════════════════════
    
    def create_tab_token_1799(self):
        tab = tk.Frame(self.notebook, bg='#000000')
        self.notebook.add(tab, text='🪙 $1799')
        
        # Header
        header = tk.Frame(tab, bg='#001100', relief='raised', bd=2)
        header.pack(fill='x', padx=10, pady=10)
        
        tk.Label(header, text="🪙 TOKEN $1799 - ZORA.CO",
                font=('Courier', 16, 'bold'), fg='#FFD700', bg='#001100').pack(pady=10)
        
        tk.Label(header, text=f"Official Token of {APP_NAME} Ecosystem",
                font=('Courier', 10), fg='#00FF00', bg='#001100').pack()
        tk.Label(header, text=f"Platform: Zora.co | Chain: Base (Ethereum L2)",
                font=('Courier', 9), fg='#00CC00', bg='#001100').pack(pady=(5, 10))
        
        # Token Info
        info_frame = tk.Frame(tab, bg='#001100', relief='raised', bd=2)
        info_frame.pack(fill='x', padx=10, pady=10)
        
        tk.Label(info_frame, text="TOKEN DETAILS",
                font=('Courier', 12, 'bold'), fg='#FFD700', bg='#001100').pack(pady=10)
        
        details = [
            ("Nome:", ZORA_TOKEN['name']),
            ("Simbolo:", ZORA_TOKEN['symbol']),
            ("Piattaforma:", ZORA_TOKEN['platform']),
            ("Chain:", ZORA_TOKEN['chain']),
            ("Tipo:", "ERC-20 / Zora Collect Token"),
            ("Ecosystem:", APP_NAME),
            ("Sviluppatori:", ' & '.join(DEVELOPERS)),
            ("Licenza:", LICENSE_CODE),
        ]
        
        for label, value in details:
            row = tk.Frame(info_frame, bg='#001100')
            row.pack(fill='x', padx=20, pady=2)
            tk.Label(row, text=label, font=('Courier', 9), fg='#008800',
                    bg='#001100', width=20, anchor='w').pack(side='left')
            tk.Label(row, text=value, font=('Courier', 9, 'bold'), fg='#FFD700',
                    bg='#001100').pack(side='left')
        
        # Actions
        actions_frame = tk.Frame(tab, bg='#001100', relief='raised', bd=2)
        actions_frame.pack(fill='x', padx=10, pady=10)
        
        tk.Label(actions_frame, text="AZIONI TOKEN $1799",
                font=('Courier', 12, 'bold'), fg='#FFD700', bg='#001100').pack(pady=10)
        
        btn_frame = tk.Frame(actions_frame, bg='#001100')
        btn_frame.pack(pady=10)
        
        for text, cmd in [
            ("🌐 Apri su Zora.co", lambda: webbrowser.open("https://zora.co")),
            ("📊 Vedi Holders", self.show_token_holders),
            ("📈 Transazioni", self.show_token_transactions),
            ("💰 Aggiungi Holder", self.add_token_holder),
        ]:
            tk.Button(btn_frame, text=text, command=cmd, bg='#002200', fg='#FFD700',
                     font=('Courier', 9, 'bold'), padx=15, pady=8, cursor='hand2').pack(side='left', padx=5)
        
        # Holders list
        holders_frame = tk.Frame(tab, bg='#001100', relief='raised', bd=2)
        holders_frame.pack(fill='both', expand=True, padx=10, pady=10)
        
        tk.Label(holders_frame, text="TOKEN $1799 HOLDERS",
                font=('Courier', 11, 'bold'), fg='#FFD700', bg='#001100').pack(pady=8)
        
        cols = ('Wallet', 'Balance', 'Staked', 'Rewards', 'Updated')
        self.token_holders_tree = ttk.Treeview(holders_frame, columns=cols, show='headings', height=8)
        for c in cols:
            self.token_holders_tree.heading(c, text=c)
        self.token_holders_tree.pack(fill='both', expand=True, padx=5, pady=5)
        
        self.refresh_token_holders()
    
    def show_token_holders(self):
        self.refresh_token_holders()
    
    def refresh_token_holders(self):
        if not hasattr(self, 'token_holders_tree'):
            return
        for item in self.token_holders_tree.get_children():
            self.token_holders_tree.delete(item)
        conn = sqlite3.connect(self.db_path)
        c = conn.cursor()
        c.execute('SELECT wallet_address,balance,staked,rewards,last_updated FROM token_1799_holders ORDER BY balance DESC')
        for h in c.fetchall():
            wallet_short = h[0][:8] + '...' + h[0][-6:] if len(h[0]) > 20 else h[0]
            self.token_holders_tree.insert('', 'end', values=(wallet_short, f"{h[1]:.2f}", f"{h[2]:.2f}", f"{h[3]:.4f}", h[4]))
        conn.close()
    
    def show_token_transactions(self):
        messagebox.showinfo("$1799 TX", "Transaction viewer - server integration pending")
    
    def add_token_holder(self):
        wallet = simpledialog.askstring("Add Holder", "Inserisci wallet address:", parent=self.root)
        if wallet:
            balance = simpledialog.askfloat("Balance", "Balance $1799:", parent=self.root, initialvalue=0)
            if balance is not None:
                conn = sqlite3.connect(self.db_path)
                conn.execute('INSERT INTO token_1799_holders (wallet_address, balance) VALUES (?,?)', (wallet, balance))
                conn.commit()
                conn.close()
                self.refresh_token_holders()
                messagebox.showinfo("OK", f"Holder aggiunto: {wallet[:16]}...")
    
    # ═══════════════════════════════════════════════════════════
    #  TAB: SCRIPT MANAGER
    # ═══════════════════════════════════════════════════════════
    
    def create_tab_scripts(self):
        tab = tk.Frame(self.notebook, bg='#000000')
        self.notebook.add(tab, text='📜 SCRIPTS')
        
        header = tk.Frame(tab, bg='#001100', relief='raised', bd=2)
        header.pack(fill='x', padx=10, pady=10)
        
        tk.Label(header, text="📜 SCRIPT MANAGER - Auto Espansione",
                font=('Courier', 13, 'bold'), fg='#00FF00', bg='#001100').pack(pady=8)
        
        tk.Label(header, text="Aggiungi script personalizzati per espandere le funzionalità dell'applicazione",
                font=('Courier', 8), fg='#008800', bg='#001100').pack(pady=(0, 8))
        
        btn_frame = tk.Frame(header, bg='#001100')
        btn_frame.pack(pady=5)
        
        for text, cmd in [("➕ AGGIUNGI SCRIPT", self.add_new_script),
                          ("▶️ ESEGUI SCRIPT", self.run_selected_script),
                          ("🔍 VERIFICA SHA-256", self.verify_script_integrity),
                          ("🗑️ RIMUOVI", self.remove_selected_script),
                          ("🔄 AGGIORNA", self.refresh_scripts)]:
            tk.Button(btn_frame, text=text, command=cmd, bg='#003300', fg='#00FF00',
                     font=('Courier', 8, 'bold'), padx=10, pady=4).pack(side='left', padx=3)
        
        # Scripts list
        list_frame = tk.Frame(tab, bg='#001100', relief='raised', bd=2)
        list_frame.pack(fill='both', expand=True, padx=10, pady=10)
        
        cols = ('Name', 'Category', 'SHA-256', 'Runs', 'Active', 'Added')
        self.scripts_tree = ttk.Treeview(list_frame, columns=cols, show='headings', height=12)
        for c in cols:
            self.scripts_tree.heading(c, text=c)
            w = 200 if c == 'SHA-256' else 130
            self.scripts_tree.column(c, width=w)
        
        self.scripts_tree.pack(fill='both', expand=True, padx=5, pady=5)
        
        # Script workspace
        workspace = tk.Frame(tab, bg='#001100', relief='raised', bd=2)
        workspace.pack(fill='x', padx=10, pady=10)
        
        tk.Label(workspace, text="📝 Script Workspace (spazio per operare con gli script)",
                font=('Courier', 10, 'bold'), fg='#00FF00', bg='#001100').pack(pady=8)
        
        self.script_output = scrolledtext.ScrolledText(workspace, height=6, bg='#000000', fg='#00FF00',
                                                        font=('Courier', 8), insertbackground='#00FF00')
        self.script_output.pack(fill='x', padx=10, pady=(0, 10))
        self.script_output.insert('1.0', "# Script output will appear here...\n# Aggiungi script per espandere le funzionalità\n")
        
        self.refresh_scripts()
    
    def add_new_script(self):
        """Add a new script via file dialog"""
        filepath = filedialog.askopenfilename(
            title="Seleziona Script",
            filetypes=[("Python", "*.py"), ("JavaScript", "*.js"), ("Shell", "*.sh"), ("All", "*.*")]
        )
        if not filepath:
            return
        
        # Ask for details
        name = simpledialog.askstring("Nome Script", "Nome per lo script:", parent=self.root,
                                      initialvalue=Path(filepath).stem)
        if not name:
            return
        
        # Category selection
        dialog = tk.Toplevel(self.root)
        dialog.title("Categoria Script")
        dialog.geometry("300x250")
        dialog.configure(bg='#000000')
        dialog.transient(self.root)
        dialog.grab_set()
        
        tk.Label(dialog, text="Seleziona Categoria:", font=('Courier', 10),
                fg='#00FF00', bg='#000000').pack(pady=10)
        
        cat_var = tk.StringVar(value='custom')
        for cat in ['ai_agent', 'social_automation', 'content_creation',
                     'nft_tools', 'analytics', 'utility', 'custom']:
            tk.Radiobutton(dialog, text=cat, variable=cat_var, value=cat,
                          fg='#00FF00', bg='#000000', selectcolor='#002200',
                          font=('Courier', 9)).pack(anchor='w', padx=30)
        
        def confirm():
            desc = simpledialog.askstring("Descrizione", "Breve descrizione:", parent=dialog) or ""
            success, msg = self.script_manager.add_script(filepath, name, cat_var.get(), desc)
            if success:
                messagebox.showinfo("OK", msg)
                self.refresh_scripts()
            else:
                messagebox.showerror("Errore", msg)
            dialog.destroy()
        
        tk.Button(dialog, text="✅ Conferma", command=confirm, bg='#003300', fg='#00FF00',
                 font=('Courier', 10, 'bold'), padx=15, pady=5).pack(pady=10)
    
    def run_selected_script(self):
        sel = self.scripts_tree.selection()
        if not sel:
            messagebox.showwarning("!", "Seleziona script")
            return
        name = self.scripts_tree.item(sel[0])['values'][0]
        success, msg = self.script_manager.run_script(name)
        self.script_output.insert('end', f"\n[{datetime.now().strftime('%H:%M:%S')}] {msg}\n")
        self.script_output.see('end')
        if success:
            self.refresh_scripts()
    
    def verify_script_integrity(self):
        sel = self.scripts_tree.selection()
        if not sel:
            return
        name = self.scripts_tree.item(sel[0])['values'][0]
        valid, current, original = self.script_manager.verify_script_integrity(name)
        if valid:
            messagebox.showinfo("✅ Integrity OK", f"Script '{name}' SHA-256 verified!\nHash: {current[:32]}...")
        else:
            messagebox.showwarning("⚠️ Modified", f"Script '{name}' è stato modificato!\nOriginale: {original[:24]}...\nAttuale: {current[:24]}...")
    
    def remove_selected_script(self):
        sel = self.scripts_tree.selection()
        if not sel:
            return
        name = self.scripts_tree.item(sel[0])['values'][0]
        if messagebox.askyesno("Conferma", f"Rimuovere '{name}'?"):
            self.script_manager.remove_script(name)
            self.refresh_scripts()
    
    def refresh_scripts(self):
        if not hasattr(self, 'scripts_tree'):
            return
        for item in self.scripts_tree.get_children():
            self.scripts_tree.delete(item)
        for s in self.script_manager.get_scripts():
            sha_short = s.get('sha256', 'N/A')[:24] + '...'
            self.scripts_tree.insert('', 'end', values=(
                s['name'], s['category'], sha_short, s['runs'],
                '✅' if s['active'] else '❌', s.get('added_at', '')[:10]
            ))
    
    # ═══════════════════════════════════════════════════════════
    #  TAB: SHA-256 SIGNATURES
    # ═══════════════════════════════════════════════════════════
    
    def create_tab_signatures(self):
        tab = tk.Frame(self.notebook, bg='#000000')
        self.notebook.add(tab, text='🔐 SHA-256')
        
        tk.Label(tab, text="🔐 FIRMA DIGITALE SHA-256",
                font=('Courier', 16, 'bold'), fg='#00FF00', bg='#000000').pack(pady=15)
        
        # App signature
        sig_frame = tk.Frame(tab, bg='#001100', relief='raised', bd=2)
        sig_frame.pack(fill='x', padx=20, pady=10)
        
        tk.Label(sig_frame, text="APPLICATION DIGITAL SIGNATURE",
                font=('Courier', 12, 'bold'), fg='#FFD700', bg='#001100').pack(pady=10)
        
        sig_details = [
            ("Project:", DIGITAL_SIGNATURE['project']),
            ("Version:", DIGITAL_SIGNATURE['version']),
            ("Algorithm:", DIGITAL_SIGNATURE['algorithm']),
            ("License:", DIGITAL_SIGNATURE['license']),
            ("Signer 1:", DEVELOPERS[0]),
            ("Signer 2:", DEVELOPERS[1]),
            ("Company:", DIGITAL_SIGNATURE['company']),
            ("Date:", DIGITAL_SIGNATURE['date']),
            ("SHA-256 Hash:", self.app_signature),
        ]
        
        for label, value in sig_details:
            row = tk.Frame(sig_frame, bg='#001100')
            row.pack(fill='x', padx=20, pady=1)
            tk.Label(row, text=label, font=('Courier', 9), fg='#008800',
                    bg='#001100', width=18, anchor='w').pack(side='left')
            fg = '#FFD700' if 'Hash' in label else '#00FF00'
            tk.Label(row, text=value, font=('Courier', 9, 'bold'), fg=fg,
                    bg='#001100', wraplength=700, anchor='w').pack(side='left', fill='x')
        
        # Verification section
        verify_frame = tk.Frame(tab, bg='#001100', relief='raised', bd=2)
        verify_frame.pack(fill='x', padx=20, pady=10)
        
        tk.Label(verify_frame, text="VERIFICA FILE SHA-256",
                font=('Courier', 12, 'bold'), fg='#00FF00', bg='#001100').pack(pady=10)
        
        vf = tk.Frame(verify_frame, bg='#001100')
        vf.pack(fill='x', padx=20, pady=5)
        
        file_entry = tk.Entry(vf, bg='#002200', fg='#00FF00', insertbackground='#00FF00',
                             font=('Courier', 9), width=60)
        file_entry.pack(side='left', padx=5)
        
        tk.Button(vf, text="📁 Seleziona", command=lambda: self._browse_file(file_entry),
                 bg='#003300', fg='#00FF00', padx=8).pack(side='left')
        
        result_label = tk.Label(verify_frame, text="", font=('Courier', 8),
                               fg='#00FF00', bg='#001100')
        result_label.pack(pady=5)
        
        def verify_file():
            fp = file_entry.get().strip()
            if fp and Path(fp).exists():
                h = compute_file_sha256(fp)
                result_label.config(text=f"SHA-256: {h}", fg='#FFD700')
                
                # Store signature
                conn = sqlite3.connect(self.db_path)
                conn.execute('''INSERT INTO digital_signatures 
                    (entity_type, entity_id, sha256_hash, signer, license_code)
                    VALUES (?,?,?,?,?)''',
                    ('file', Path(fp).name, h, ' & '.join(DEVELOPERS), LICENSE_CODE))
                conn.commit()
                conn.close()
                self.log('INFO', f'File signed: {Path(fp).name} -> {h[:24]}...', 'signatures')
            else:
                result_label.config(text="File non trovato", fg='#FF0000')
        
        tk.Button(verify_frame, text="🔐 CALCOLA SHA-256", command=verify_file,
                 bg='#003300', fg='#FFD700', font=('Courier', 10, 'bold'),
                 padx=20, pady=8).pack(pady=10)
        
        # Signatures history
        hist_frame = tk.Frame(tab, bg='#001100', relief='raised', bd=2)
        hist_frame.pack(fill='both', expand=True, padx=20, pady=10)
        
        tk.Label(hist_frame, text="STORICO FIRME",
                font=('Courier', 11, 'bold'), fg='#00FF00', bg='#001100').pack(pady=8)
        
        cols = ('Type', 'Entity', 'SHA-256', 'Signer', 'Date')
        self.sig_tree = ttk.Treeview(hist_frame, columns=cols, show='headings', height=8)
        for c in cols:
            self.sig_tree.heading(c, text=c)
        self.sig_tree.pack(fill='both', expand=True, padx=5, pady=5)
        
        self.refresh_signatures()
    
    def refresh_signatures(self):
        if not hasattr(self, 'sig_tree'):
            return
        for item in self.sig_tree.get_children():
            self.sig_tree.delete(item)
        conn = sqlite3.connect(self.db_path)
        c = conn.cursor()
        c.execute('SELECT entity_type, entity_id, sha256_hash, signer, created_at FROM digital_signatures ORDER BY id DESC')
        for s in c.fetchall():
            sha_short = s[2][:32] + '...'
            self.sig_tree.insert('', 'end', values=(s[0], s[1], sha_short, s[3], s[4][:19]))
        conn.close()
    
    # ═══════════════════════════════════════════════════════════
    #  TAB: SYSTEM
    # ═══════════════════════════════════════════════════════════
    
    def create_tab_system(self):
        tab = tk.Frame(self.notebook, bg='#000000')
        self.notebook.add(tab, text='⚙️ SYSTEM')
        
        sub_nb = ttk.Notebook(tab)
        sub_nb.pack(fill='both', expand=True, padx=5, pady=5)
        
        # Backup tab
        backup_tab = tk.Frame(sub_nb, bg='#000000')
        sub_nb.add(backup_tab, text='💾 BACKUP')
        
        tk.Label(backup_tab, text="💾 BACKUP & RESTORE",
                font=('Courier', 13, 'bold'), fg='#00FF00', bg='#000000').pack(pady=10)
        tk.Button(backup_tab, text="💾 CREA BACKUP", command=self.backup_system,
                 bg='#003300', fg='#00FF00', font=('Courier', 11, 'bold'),
                 padx=25, pady=10).pack(pady=10)
        
        cols = ('Name', 'Date', 'Size', 'Status')
        self.backup_tree = ttk.Treeview(backup_tab, columns=cols, show='headings', height=10)
        for c in cols:
            self.backup_tree.heading(c, text=c)
        self.backup_tree.pack(fill='both', expand=True, padx=10, pady=10)
        self.refresh_backups()
        
        # Logs tab
        logs_tab = tk.Frame(sub_nb, bg='#000000')
        sub_nb.add(logs_tab, text='📋 LOGS')
        
        self.log_viewer = scrolledtext.ScrolledText(logs_tab, height=25, bg='#000000', fg='#00FF00',
                                                     font=('Courier', 8))
        self.log_viewer.pack(fill='both', expand=True, padx=10, pady=10)
        tk.Button(logs_tab, text="🔄 Refresh", command=self.refresh_logs,
                 bg='#003300', fg='#00FF00', padx=15, pady=5).pack(pady=5)
        self.refresh_logs()
        
        # Settings tab
        settings_tab = tk.Frame(sub_nb, bg='#000000')
        sub_nb.add(settings_tab, text='⚙️ SETTINGS')
        
        tk.Label(settings_tab, text="⚙️ IMPOSTAZIONI",
                font=('Courier', 13, 'bold'), fg='#00FF00', bg='#000000').pack(pady=10)
        
        sf = tk.Frame(settings_tab, bg='#001100', relief='raised', bd=2)
        sf.pack(fill='x', padx=20, pady=10)
        
        # API Keys
        tk.Label(sf, text="🔐 API KEYS", font=('Courier', 11, 'bold'),
                fg='#00FF00', bg='#001100').pack(pady=10)
        
        for service, key in [('Anthropic Claude', 'anthropic'), ('OpenAI', 'openai'),
                             ('Google AI', 'google'), ('Stability AI', 'stability'),
                             ('ElevenLabs', 'elevenlabs')]:
            row = tk.Frame(sf, bg='#001100')
            row.pack(fill='x', padx=15, pady=2)
            tk.Label(row, text=f"{service}:", fg='#00FF00', bg='#001100',
                    font=('Courier', 9), width=18, anchor='w').pack(side='left')
            entry = tk.Entry(row, bg='#002200', fg='#00FF00', show='*',
                           insertbackground='#00FF00', font=('Courier', 8), width=35)
            entry.pack(side='left', padx=5)
            tk.Button(row, text="💾", command=lambda s=key, e=entry: self.save_api_key(s, e.get()),
                     bg='#003300', fg='#00FF00', padx=6).pack(side='left')
        
        # Email config
        tk.Label(sf, text="📧 EMAIL SMTP", font=('Courier', 11, 'bold'),
                fg='#00FF00', bg='#001100').pack(pady=(15, 10))
        
        for label, key in [("Email:", "smtp_email"), ("Password:", "smtp_pass")]:
            row = tk.Frame(sf, bg='#001100')
            row.pack(fill='x', padx=15, pady=2)
            tk.Label(row, text=label, fg='#00FF00', bg='#001100',
                    font=('Courier', 9), width=18, anchor='w').pack(side='left')
            show = '•' if 'pass' in key else None
            entry = tk.Entry(row, bg='#002200', fg='#00FF00', show=show,
                           insertbackground='#00FF00', font=('Courier', 8), width=35)
            entry.pack(side='left', padx=5)
        
        # Server settings
        tk.Label(sf, text="🌐 SERVER", font=('Courier', 11, 'bold'),
                fg='#00FF00', bg='#001100').pack(pady=(15, 10))
        
        srv_row = tk.Frame(sf, bg='#001100')
        srv_row.pack(fill='x', padx=15, pady=2)
        tk.Label(srv_row, text="Porta:", fg='#00FF00', bg='#001100').pack(side='left', padx=5)
        port_e = tk.Entry(srv_row, bg='#002200', fg='#00FF00', insertbackground='#00FF00', width=8)
        port_e.insert(0, str(self.server_port))
        port_e.pack(side='left', padx=5)
        tk.Button(srv_row, text="🔄 Riavvia Server",
                 command=lambda: self.restart_server(int(port_e.get())),
                 bg='#003300', fg='#00FF00', padx=10, pady=3).pack(side='left', padx=10)
    
    def save_api_key(self, service, key):
        if not key:
            return
        encrypted = base64.b64encode(key.encode()).decode()
        conn = sqlite3.connect(self.db_path)
        conn.execute('INSERT OR REPLACE INTO api_keys (service,key_encrypted,active) VALUES (?,?,1)',
                    (service, encrypted))
        conn.commit()
        conn.close()
        messagebox.showinfo("OK", f"API key per {service} salvata")
    
    def backup_system(self):
        name = f"backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        backup_dir = self.dirs['backups'] / name
        backup_dir.mkdir(exist_ok=True)
        
        shutil.copy(self.db_path, backup_dir / 'gene1799_v5.db')
        shutil.copytree(self.dirs['config'], backup_dir / 'Config', dirs_exist_ok=True)
        
        total_size = sum(f.stat().st_size for f in backup_dir.rglob('*') if f.is_file())
        
        # Compute backup SHA-256
        backup_hash = compute_sha256(f"{name}_{total_size}_{datetime.now().isoformat()}")
        
        conn = sqlite3.connect(self.db_path)
        conn.execute('INSERT INTO backups (name,path,size,status) VALUES (?,?,?,?)',
                    (name, str(backup_dir), total_size, 'completed'))
        conn.execute('INSERT INTO digital_signatures (entity_type,entity_id,sha256_hash,signer,license_code) VALUES (?,?,?,?,?)',
                    ('backup', name, backup_hash, ' & '.join(DEVELOPERS), LICENSE_CODE))
        conn.commit()
        conn.close()
        
        self.log('INFO', f'Backup created: {name}', 'backup')
        messagebox.showinfo("Backup", f"Backup completato!\nSize: {format_bytes(total_size)}\nSHA-256: {backup_hash[:24]}...")
        self.refresh_backups()
    
    def refresh_backups(self):
        if not hasattr(self, 'backup_tree'):
            return
        for item in self.backup_tree.get_children():
            self.backup_tree.delete(item)
        conn = sqlite3.connect(self.db_path)
        c = conn.cursor()
        c.execute('SELECT name,created_at,size,status FROM backups ORDER BY created_at DESC')
        for b in c.fetchall():
            size = format_bytes(b[2]) if b[2] else 'N/A'
            self.backup_tree.insert('', 'end', values=(b[0], b[1], size, b[3]))
        conn.close()
    
    def refresh_logs(self):
        if not hasattr(self, 'log_viewer'):
            return
        self.log_viewer.delete('1.0', tk.END)
        conn = sqlite3.connect(self.db_path)
        c = conn.cursor()
        c.execute('SELECT level,created_at,module,message FROM logs ORDER BY id DESC LIMIT 500')
        for l in c.fetchall():
            self.log_viewer.insert('end', f"[{l[1]}] [{l[0]}] [{l[2]}] {l[3]}\n")
        conn.close()
    
    def restart_server(self, port):
        self.server_port = port
        if self.server:
            self.server.shutdown()
        self.start_server_thread()
        messagebox.showinfo("Server", f"Server riavviato sulla porta {port}")
    
    def open_web(self):
        if self.server_running:
            webbrowser.open(f'http://localhost:{self.server_port}')
        else:
            messagebox.showwarning("Server", "Server non attivo")
    
    def start_server_thread(self):
        def run():
            try:
                Gene1799HTTPHandler.app_dir = str(self.dirs['web'])
                Gene1799HTTPHandler.db_path = self.db_path
                
                # Copy web files
                web_html = Path(__file__).parent / "gene1799_web_interface.html"
                if web_html.exists():
                    shutil.copy(web_html, self.dirs['web'] / 'index.html')
                
                self.server = HTTPServer(('localhost', self.server_port), Gene1799HTTPHandler)
                self.server_running = True
                print(f"🌐 Server started: http://localhost:{self.server_port}")
                self.log('INFO', f'Server started on port {self.server_port}', 'server')
                self.server.serve_forever()
            except Exception as e:
                print(f"Server error: {e}")
                self.server_running = False
        
        thread = threading.Thread(target=run, daemon=True)
        thread.start()
        time.sleep(0.5)
    
    def _browse_file(self, entry):
        f = filedialog.askopenfilename(filetypes=[("All", "*.*"), ("Python", "*.py")])
        if f:
            entry.delete(0, tk.END)
            entry.insert(0, f)


# ═══════════════════════════════════════════════════════════════════
#  MAIN ENTRY POINT
# ═══════════════════════════════════════════════════════════════════


def main():
    print(f"""
    ╔══════════════════════════════════════════════════════════════════╗
    ║                                                                  ║
    ║     ⬢ {APP_NAME.upper():^52} ║
    ║     {'v' + VERSION:^58} ║
    ║                                                                  ║
    ║     SHA-256 Digitally Signed                                     ║
    ║     Signatories:                                                 ║
    ║       • {DEVELOPERS[0]:<54} ║
    ║       • {DEVELOPERS[1]:<54} ║
    ║                                                                  ║
    ║     License: {LICENSE_CODE:<50} ║
    ║     © {COMPANY:<56} ║
    ║     Build: {BUILD_DATE:<52} ║
    ║                                                                  ║
    ║     Token $1799 | Zora.co | Base Chain                           ║
    ║                                                                  ║
    ╚══════════════════════════════════════════════════════════════════╝
    """)
    
    root = tk.Tk()
    app = Gene1799App(root)
    
    # Center window
    root.update_idletasks()
    w, h = root.winfo_width(), root.winfo_height()
    x = (root.winfo_screenwidth() // 2) - (w // 2)
    y = (root.winfo_screenheight() // 2) - (h // 2)
    root.geometry(f'{w}x{h}+{x}+{y}')
    
    root.mainloop()


if __name__ == "__main__":
    main()

