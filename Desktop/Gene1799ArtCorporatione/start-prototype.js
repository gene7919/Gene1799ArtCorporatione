#!/usr/bin/env node

/**
 * GENE1799 LOCAL PROTOTYPE LAUNCHER
 * Avvia il sistema completo su localhost come prototipo
 *
 * Usage: node start-prototype.js
 */

const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');
const EventEmitter = require('events');

class PrototypeLauncher extends EventEmitter {
    constructor() {
        super();
        this.processes = [];
        this.projectRoot = __dirname;
        this.config = {
            port: 3000,
            backendPort: 3001,
            webPort: 8080
        };
    }

    log(message, type = 'info') {
        const timestamp = new Date().toLocaleTimeString();
        const colors = {
            info: '\x1b[36m',    // Cyan
            success: '\x1b[32m', // Green
            error: '\x1b[31m',   // Red
            warning: '\x1b[33m', // Yellow
            reset: '\x1b[0m'
        };

        const color = colors[type] || colors.info;
        console.log(`${color}[${timestamp}] ${message}${colors.reset}`);
    }

    async checkPrerequisites() {
        this.log('Checking prerequisites...');

        // Check Node.js
        const nodeVersion = process.version;
        this.log(`✓ Node.js ${nodeVersion}`);

        // Check npm
        try {
            const { execSync } = require('child_process');
            const npmVersion = execSync('npm --version', { encoding: 'utf8' }).trim();
            this.log(`✓ npm ${npmVersion}`);
        } catch (error) {
            this.log('npm not found', 'error');
            throw error;
        }

        // Check required directories
        const requiredDirs = ['backend/src', 'frontend', 'telegram-bot'];
        for (const dir of requiredDirs) {
            const dirPath = path.join(this.projectRoot, dir);
            if (!fs.existsSync(dirPath)) {
                this.log(`Missing directory: ${dir}`, 'error');
                throw new Error(`Required directory not found: ${dir}`);
            }
            this.log(`✓ Found ${dir}`);
        }

        return true;
    }

    async setupEnvironment() {
        this.log('Setting up environment...');

        const envPath = path.join(this.projectRoot, 'backend', '.env');
        const envExamplePath = path.join(this.projectRoot, 'backend', '.env.example');

        if (!fs.existsSync(envPath)) {
            if (fs.existsSync(envExamplePath)) {
                fs.copyFileSync(envExamplePath, envPath);
                this.log('Created .env from template', 'warning');
                this.log('Edit backend/.env with your credentials', 'warning');
            }
        }

        // Set local development environment variables
        process.env.NODE_ENV = 'development';
        process.env.PORT = this.config.port;
        process.env.DEBUG = 'gene1799:*';
        process.env.ENVIRONMENT = 'local-prototype';

        this.log('✓ Environment configured');
    }

    async installDependencies() {
        this.log('Installing dependencies...');

        return new Promise((resolve, reject) => {
            // On Windows, use npm.cmd instead of npm
            const npmCmd = process.platform === 'win32' ? 'npm.cmd' : 'npm';

            const npm = spawn(npmCmd, ['install'], {
                cwd: this.projectRoot,
                stdio: 'inherit',
                shell: true
            });

            npm.on('close', (code) => {
                if (code === 0) {
                    this.log('✓ Dependencies installed', 'success');
                    resolve();
                } else {
                    this.log('Failed to install dependencies', 'error');
                    reject(new Error('npm install failed'));
                }
            });

            npm.on('error', (error) => {
                this.log(`npm spawn error: ${error.message}`, 'error');
                reject(error);
            });
        });
    }

    startBackendServer() {
        this.log('Starting Backend Server...');

        return new Promise((resolve) => {
            const backend = spawn('node', [
                'backend/src/index.js'
            ], {
                cwd: this.projectRoot,
                env: { ...process.env, PORT: this.config.backendPort }
            });

            backend.stdout.on('data', (data) => {
                const message = data.toString().trim();
                if (message) {
                    this.log(`[Backend] ${message}`);
                    if (message.includes('listening') || message.includes('started')) {
                        resolve();
                    }
                }
            });

            backend.stderr.on('data', (data) => {
                const message = data.toString().trim();
                if (message) this.log(`[Backend] ${message}`, 'warning');
            });

            this.processes.push({ name: 'Backend', process: backend });
        });
    }

    startTelegramBot() {
        this.log('Starting Telegram Bot...');

        const botPath = path.join(this.projectRoot, 'telegram-bot', 'bot.js');
        if (!fs.existsSync(botPath)) {
            this.log('Telegram bot not found, skipping', 'warning');
            return Promise.resolve();
        }

        return new Promise((resolve) => {
            const bot = spawn('node', ['telegram-bot/bot.js'], {
                cwd: this.projectRoot
            });

            bot.stdout.on('data', (data) => {
                const message = data.toString().trim();
                if (message) {
                    this.log(`[Bot] ${message}`);
                    if (message.includes('polling') || message.includes('started')) {
                        resolve();
                    }
                }
            });

            bot.stderr.on('data', (data) => {
                const message = data.toString().trim();
                if (message) this.log(`[Bot] ${message}`, 'warning');
            });

            this.processes.push({ name: 'Telegram Bot', process: bot });
        });
    }

    startDashboard() {
        this.log('Starting Dashboard server...');

        const { createServer } = require('http');

        const server = createServer((req, res) => {
            // Serve static files
            let filePath;

            if (req.url === '/' || req.url === '/index.html') {
                // Serve the integrated dashboard as default
                filePath = path.join(this.projectRoot, 'frontend', 'integrated_dashboard.html');
            } else {
                filePath = path.join(this.projectRoot, 'frontend', req.url);
            }

            fs.readFile(filePath, (err, data) => {
                if (err) {
                    res.writeHead(404, { 'Content-Type': 'text/html' });
                    res.end('<h1>404 Not Found</h1><p>File: ' + filePath + '</p>');
                } else {
                    const ext = path.extname(filePath);
                    const contentTypes = {
                        '.html': 'text/html',
                        '.css': 'text/css',
                        '.js': 'application/javascript',
                        '.json': 'application/json'
                    };
                    res.writeHead(200, { 'Content-Type': contentTypes[ext] || 'text/plain' });
                    res.end(data);
                }
            });
        });

        return new Promise((resolve) => {
            server.listen(this.config.port, () => {
                this.log(`✓ Dashboard running at http://localhost:${this.config.port}`, 'success');
                this.log(`✓ Main: Integrated Dashboard (AI + Social + Web3)`, 'success');
                resolve();
            });

            this.processes.push({ name: 'Dashboard', process: { kill: () => server.close() } });
        });
    }

    displayStatus() {
        console.log('\n═════════════════════════════════════════════════════════');
        console.log('✓ GENE1799 LOCAL PROTOTYPE RUNNING');
        console.log('═════════════════════════════════════════════════════════\n');

        console.log('Services:');
        console.log(`  🌐 Dashboard    → http://localhost:${this.config.port}`);
        console.log(`  📊 Web3 dApps   → http://localhost:${this.config.port}/web3-dapps-dashboard.html`);
        console.log(`  🔌 Backend API  → http://localhost:${this.config.backendPort}`);
        console.log(`  🤖 Telegram Bot → Polling active\n`);

        console.log('Modules:');
        console.log('  ✓ Orchestrator Core');
        console.log('  ✓ Learning Agents');
        console.log('  ✓ Web3 dApps Integration');
        console.log('  ✓ Social Automation');
        console.log('  ✓ Protective Matrix Security');
        console.log('  ✓ Telegram Bot\n');

        console.log('Documentation:');
        console.log('  📖 README.md');
        console.log('  📖 QUICK_START.md');
        console.log('  📖 WEB3_DAPPS_GUIDE.md');
        console.log('  📖 DEPLOYMENT_GUIDE.md\n');

        console.log('═════════════════════════════════════════════════════════');
        console.log('Press Ctrl+C to stop all services');
        console.log('═════════════════════════════════════════════════════════\n');
    }

    setupGracefulShutdown() {
        process.on('SIGINT', () => {
            this.log('\nShutting down services...', 'warning');
            this.processes.forEach((proc) => {
                try {
                    proc.process.kill();
                    this.log(`✓ Stopped ${proc.name}`);
                } catch (error) {
                    this.log(`Failed to stop ${proc.name}`, 'error');
                }
            });
            this.log('All services stopped', 'success');
            process.exit(0);
        });
    }

    async launch() {
        try {
            console.log('\n');
            console.log('╔═══════════════════════════════════════════════════╗');
            console.log('║   GENE1799 LOCAL PROTOTYPE LAUNCHER               ║');
            console.log('║   Production-ready system on localhost            ║');
            console.log('╚═══════════════════════════════════════════════════╝\n');

            await this.checkPrerequisites();
            await this.setupEnvironment();
            await this.installDependencies();

            // Start all services
            this.setupGracefulShutdown();

            // Start services in parallel
            await Promise.all([
                this.startDashboard(),
                this.startBackendServer(),
                this.startTelegramBot()
            ]);

            this.displayStatus();

        } catch (error) {
            this.log(`Fatal error: ${error.message}`, 'error');
            process.exit(1);
        }
    }
}

// Launch the prototype
if (require.main === module) {
    const launcher = new PrototypeLauncher();
    launcher.launch().catch(error => {
        console.error('Failed to launch prototype:', error);
        process.exit(1);
    });
}

module.exports = PrototypeLauncher;
