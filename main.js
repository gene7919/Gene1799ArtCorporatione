/**
 * ══════════════════════════════════════════════════════════════════
 * GENE1799 ART CORPORATIONE - Electron Main Process v5.2.0
 * SHA-256 Digitally Signed
 * Integra: Ollama AI SDK + PTY Terminal + Model Downloader + Multi-Agent
 * 
 * Signatories:
 *   • Marco Antonio Saverio Mazzitelli
 *   • Fabio Amedeo Lo Presti
 * License: 16/A408979L
 * © Arthemis Ludovici Production
 * ══════════════════════════════════════════════════════════════════
 */

'use strict';

const { app, BrowserWindow, ipcMain, dialog, Menu, shell } = require('electron');
const path   = require('path');
const crypto = require('crypto');
const fs     = require('fs');
const http   = require('http');
const https  = require('https');
const { exec, spawn } = require('child_process');

// ─── Ollama SDK (gestione AI locale) ──────────────────────────────────────────
const { Ollama } = require('ollama');
const ollama = new Ollama({ 
  host: process.env.OLLAMA_HOST || 'http://127.0.0.1:11434' 
});

// ─── node-pty (terminale PowerShell integrato) ────────────────────────────────
let pty;
try {
  pty = require('node-pty');
} catch (e) {
  console.warn('⚠️  node-pty non disponibile. Terminal PTY disabilitato.');
}

// ─── Costanti App ─────────────────────────────────────────────────────────────
const APP_NAME    = 'Gene1799 Art Corporatione';
const VERSION     = '5.2.0';
const LICENSE     = '16/A408979L';
const DEVELOPERS  = ['Marco Antonio Saverio Mazzitelli', 'Fabio Amedeo Lo Presti'];
const COMPANY     = 'Arthemis Ludovici Production';
const SERVER_URL  = process.env.GENE1799_SERVER || 'http://localhost:8888';

// Modello AI attivo (modificabile runtime)
let ACTIVE_MODEL = process.env.OLLAMA_MODEL || 'llama3:8b';

// ─── SHA-256 Digital Signature ────────────────────────────────────────────────
function computeAppSignature() {
  return crypto.createHash('sha256').update(JSON.stringify({
    project: APP_NAME,
    version: VERSION,
    license: LICENSE,
    signatories: DEVELOPERS,
    company: COMPANY,
    timestamp: '2026-02-18'
  })).digest('hex');
}
const APP_SIGNATURE = computeAppSignature();

// ─── Directories (auto-create) ────────────────────────────────────────────────
const USER_DATA    = app.getPath('userData');
const DATA_DIR     = path.join(USER_DATA, 'Data');
const CONFIG_DIR   = path.join(USER_DATA, 'Config');
const SCRIPTS_DIR  = path.join(USER_DATA, 'Scripts');
const BACKUPS_DIR  = path.join(USER_DATA, 'Backups');
const MODELS_DIR   = path.join(USER_DATA, 'Models', 'Downloaded');
const AGENTS_DIR   = path.join(USER_DATA, 'Agents');

[DATA_DIR, CONFIG_DIR, SCRIPTS_DIR, BACKUPS_DIR, MODELS_DIR, AGENTS_DIR].forEach(dir => {
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
});

// ─── Conversation History (multi-session per agenti) ──────────────────────────
/** @type {Map<string, Array<{role:string, content:string}>>} */
const conversationHistory = new Map();

function getHistory(sessionId) {
  if (!conversationHistory.has(sessionId)) {
    conversationHistory.set(sessionId, []);
  }
  return conversationHistory.get(sessionId);
}

// ─── Windows ──────────────────────────────────────────────────────────────────
let mainWindow = null;
let termWindow = null;
let ptyProcesses = new Map(); // Map<terminalId, ptyProcess>

// ══════════════════════════════════════════════════════════════════════════════
// OLLAMA AI CORE FUNCTIONS
// ══════════════════════════════════════════════════════════════════════════════

/**
 * Chat semplice (senza history) - ritorna stringa completa
 * @param {string} prompt
 * @param {string} [model]
 * @param {string} [systemPrompt]
 */
async function askAI(prompt, model = ACTIVE_MODEL, systemPrompt = null) {
  const messages = [];
  if (systemPrompt) messages.push({ role: 'system', content: systemPrompt });
  messages.push({ role: 'user', content: prompt });

  const response = await ollama.chat({ model, messages });
  return response.message.content;
}

/**
 * Chat con memoria conversazione (per sessionId)
 * @param {string} sessionId
 * @param {string} userMessage
 * @param {string} [model]
 * @param {string} [systemPrompt]
 */
async function chatWithHistory(sessionId, userMessage, model = ACTIVE_MODEL, systemPrompt = null) {
  const history = getHistory(sessionId);

  if (history.length === 0 && systemPrompt) {
    history.push({ role: 'system', content: systemPrompt });
  }
  history.push({ role: 'user', content: userMessage });

  const response = await ollama.chat({ model, messages: history });
  const assistantMsg = response.message.content;
  history.push({ role: 'assistant', content: assistantMsg });

  return { response: assistantMsg, history };
}

/**
 * Generazione testo puro (completamento, non chat)
 * @param {string} prompt
 * @param {string} [model]
 * @param {object} [options]
 */
async function generateText(prompt, model = ACTIVE_MODEL, options = {}) {
  const response = await ollama.generate({
    model,
    prompt,
    stream: false,
    options: { temperature: 0.7, top_p: 0.9, num_predict: 1024, ...options }
  });
  return response.response;
}

/**
 * Lista modelli Ollama installati localmente
 */
async function listOllamaModels() {
  const result = await ollama.list();
  return result.models.map(m => ({
    name: m.name,
    size: m.size,
    modified: m.modified_at,
    digest: m.digest
  }));
}

/**
 * Verifica Ollama health
 */
async function checkOllamaHealth() {
  try {
    await ollama.list();
    return { online: true, host: ollama.config.host };
  } catch (err) {
    return { online: false, error: err.message };
  }
}

/**
 * Pull modello da Ollama registry (con progress streaming)
 * @param {string} modelName
 * @param {Function} [onProgress] - callback(progressData)
 */
async function pullOllamaModel(modelName, onProgress) {
  const stream = await ollama.pull({ model: modelName, stream: true });
  let lastStatus = '';
  
  for await (const chunk of stream) {
    if (chunk.status && chunk.status !== lastStatus) {
      lastStatus = chunk.status;
      if (onProgress) onProgress(chunk);
    }
  }
  
  return { success: true, model: modelName };
}

// ══════════════════════════════════════════════════════════════════════════════
// MODEL DOWNLOADER (HTTP/HTTPS + Ollama integration)
// ══════════════════════════════════════════════════════════════════════════════

/**
 * Download file generico (GGUF, script, ecc.)
 * @param {string} url
 * @param {string} fileName
 * @param {Function} [onProgress] - callback(percentage)
 */
async function downloadModel(url, fileName, onProgress) {
  return new Promise((resolve, reject) => {
    const destPath = path.join(MODELS_DIR, fileName);
    const file = fs.createWriteStream(destPath);
    const proto = url.startsWith('https') ? https : http;

    proto.get(url, response => {
      if (response.statusCode !== 200) {
        reject(new Error(`HTTP ${response.statusCode}: ${response.statusMessage}`));
        return;
      }

      const totalBytes = parseInt(response.headers['content-length'], 10);
      let downloadedBytes = 0;

      response.on('data', chunk => {
        downloadedBytes += chunk.length;
        if (onProgress && totalBytes) {
          const pct = Math.round((downloadedBytes / totalBytes) * 100);
          onProgress(pct);
        }
      });

      response.pipe(file);

      file.on('finish', () => {
        file.close();
        const hash = crypto.createHash('sha256')
          .update(fs.readFileSync(destPath))
          .digest('hex');
        resolve({ 
          success: true, 
          path: destPath, 
          fileName, 
          size: downloadedBytes,
          sha256: hash 
        });
      });
    }).on('error', err => {
      fs.unlink(destPath, () => {});
      reject(err);
    });
  });
}

/**
 * Lista modelli scaricati
 */
function listDownloadedModels() {
  if (!fs.existsSync(MODELS_DIR)) return [];
  return fs.readdirSync(MODELS_DIR).map(f => {
    const fullPath = path.join(MODELS_DIR, f);
    const stats = fs.statSync(fullPath);
    return {
      name: f,
      path: fullPath,
      size: stats.size,
      modified: stats.mtime,
      sha256: crypto.createHash('sha256').update(fs.readFileSync(fullPath)).digest('hex')
    };
  });
}

/**
 * Lista agenti scaricati (script Python/JS nella cartella Agents)
 */
function listDownloadedAgents() {
  if (!fs.existsSync(AGENTS_DIR)) return [];
  return fs.readdirSync(AGENTS_DIR)
    .filter(f => f.endsWith('.py') || f.endsWith('.js'))
    .map(f => {
      const fullPath = path.join(AGENTS_DIR, f);
      return {
        name: path.parse(f).name,
        filename: f,
        path: fullPath,
        type: f.endsWith('.py') ? 'python' : 'javascript'
      };
    });
}

// ══════════════════════════════════════════════════════════════════════════════
// HTTP API REQUEST (per comunicare con server Gene1799 FastAPI se attivo)
// ══════════════════════════════════════════════════════════════════════════════

function apiRequest(endpoint, method = 'GET', body = null) {
  return new Promise((resolve, reject) => {
    const data = body ? JSON.stringify(body) : null;
    const parsed = new URL(SERVER_URL + endpoint);
    const options = {
      hostname: parsed.hostname,
      port: parsed.port || 8888,
      path: parsed.pathname + parsed.search,
      method,
      headers: {
        'Content-Type': 'application/json',
        ...(data ? { 'Content-Length': Buffer.byteLength(data) } : {})
      }
    };

    const req = http.request(options, res => {
      let raw = '';
      res.on('data', chunk => raw += chunk);
      res.on('end', () => {
        try {
          resolve(JSON.parse(raw));
        } catch {
          resolve(raw);
        }
      });
    });

    req.on('error', reject);
    if (data) req.write(data);
    req.end();
  });
}

// ══════════════════════════════════════════════════════════════════════════════
// TERMINAL PTY (PowerShell integrato con xterm.js)
// ══════════════════════════════════════════════════════════════════════════════

/**
 * Crea PTY process per terminale
 * @param {string} terminalId
 */
function createPTY(terminalId) {
  if (!pty) {
    throw new Error('node-pty non disponibile');
  }

  const PROFILE_PATH = path.join(USER_DATA, 'Profiles', 'Gene1799-AI-Profile.ps1');
  const shellArgs = ['-NoLogo', '-ExecutionPolicy', 'Bypass'];
  
  // Se profilo esiste, caricalo
  if (fs.existsSync(PROFILE_PATH)) {
    shellArgs.push('-File', PROFILE_PATH);
  }

  const ptyProcess = pty.spawn('powershell.exe', shellArgs, {
    name: 'xterm-256color',
    cols: 120,
    rows: 30,
    cwd: path.join(__dirname, '..'),
    env: {
      ...process.env,
      GENE1799_CONTEXT: 'Electron Terminal',
      GENE1799_BASE: USER_DATA,
      OLLAMA_HOST: ollama.config.host
    },
    handleFlowControl: true
  });

  ptyProcesses.set(terminalId, ptyProcess);
  return ptyProcess;
}

/**
 * Interpreta comandi speciali (ai:, agent:, download:)
 * @param {string} command
 * @param {Electron.WebContents} sender
 */
async function handleSpecialCommand(command, sender) {
  const cmd = command.trim();

  // Comando AI: ai:<prompt>
  if (cmd.toLowerCase().startsWith('ai:')) {
    const prompt = cmd.slice(3).trim();
    try {
      const response = await askAI(prompt);
      sender.send('terminal-output', `\r\n[AI] ${response}\r\n`);
    } catch (err) {
      sender.send('terminal-output', `\r\n❌ AI Error: ${err.message}\r\n`);
    }
    sender.send('terminal-done');
    return true;
  }

  // Comando agente: agent:<nome>:<messaggio>
  if (cmd.toLowerCase().startsWith('agent:')) {
    const parts = cmd.slice(6).split(':');
    const agentName = parts[0]?.trim();
    const message = parts.slice(1).join(':').trim();
    
    try {
      const result = await apiRequest('/api/agents/call', 'POST', {
        agent: agentName,
        message
      });
      sender.send('terminal-output', `\r\n[Agent ${agentName}] ${result.response?.output || result.error}\r\n`);
    } catch (err) {
      sender.send('terminal-output', `\r\n❌ Agent Error: ${err.message}\r\n`);
    }
    sender.send('terminal-done');
    return true;
  }

  // Comando download: download:<url>:<filename>
  if (cmd.toLowerCase().startsWith('download:')) {
    const parts = cmd.slice(9).split(':');
    const url = parts.slice(0, -1).join(':');
    const fileName = parts[parts.length - 1];
    
    try {
      sender.send('terminal-output', `\r\n⬇️  Downloading ${fileName}...\r\n`);
      const result = await downloadModel(url, fileName, (pct) => {
        sender.send('terminal-output', `\r   Progress: ${pct}%...`);
      });
      sender.send('terminal-output', `\r\n✅ Downloaded: ${result.path}\r\n   SHA-256: ${result.sha256}\r\n`);
    } catch (err) {
      sender.send('terminal-output', `\r\n❌ Download Error: ${err.message}\r\n`);
    }
    sender.send('terminal-done');
    return true;
  }

  // Comando pull Ollama: ollama pull <model>
  if (cmd.toLowerCase().startsWith('ollama pull ')) {
    const modelName = cmd.slice(12).trim();
    try {
      sender.send('terminal-output', `\r\n📥 Pulling Ollama model: ${modelName}...\r\n`);
      await pullOllamaModel(modelName, (chunk) => {
        if (chunk.status) {
          sender.send('terminal-output', `\r   ${chunk.status}...\r`);
        }
      });
      sender.send('terminal-output', `\r\n✅ Model ${modelName} ready\r\n`);
    } catch (err) {
      sender.send('terminal-output', `\r\n❌ Pull Error: ${err.message}\r\n`);
    }
    sender.send('terminal-done');
    return true;
  }

  return false; // Non è comando speciale
}

// ══════════════════════════════════════════════════════════════════════════════
// WINDOWS
// ══════════════════════════════════════════════════════════════════════════════

function createMainWindow() {
  mainWindow = new BrowserWindow({
    width: 1600,
    height: 950,
    minWidth: 1200,
    minHeight: 700,
    title: `⬢ ${APP_NAME} v${VERSION}`,
    backgroundColor: '#0d1117',
    icon: path.join(__dirname, '..', 'assets', 'icon.png'),
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      preload: path.join(__dirname, 'preload.js'),
      webSecurity: true
    },
    show: false
  });

  mainWindow.once('ready-to-show', () => {
    mainWindow.show();
    if (process.env.NODE_ENV === 'development') {
      mainWindow.webContents.openDevTools({ mode: 'detach' });
    }
  });

  mainWindow.loadFile(path.join(__dirname, 'renderer', 'index.html'));
  mainWindow.on('closed', () => { mainWindow = null; });

  return mainWindow;
}

function createTerminalWindow() {
  if (termWindow) {
    termWindow.focus();
    return;
  }

  termWindow = new BrowserWindow({
    width: 1000,
    height: 650,
    title: 'Gene1799 Terminal',
    backgroundColor: '#0d1117',
    webPreferences: {
      nodeIntegration: true,
      contextIsolation: false,
      webSecurity: false
    },
    show: false
  });

  termWindow.once('ready-to-show', () => termWindow.show());
  termWindow.loadFile(path.join(__dirname, 'renderer', 'terminal.html'));
  termWindow.on('closed', () => {
    termWindow = null;
    // Kill all PTY processes
    ptyProcesses.forEach(pty => pty.kill());
    ptyProcesses.clear();
  });
}

// ══════════════════════════════════════════════════════════════════════════════
// DIALOGS
// ══════════════════════════════════════════════════════════════════════════════

function showAbout() {
  dialog.showMessageBox(mainWindow, {
    type: 'info',
    title: `About ${APP_NAME}`,
    message: `⬢ ${APP_NAME}`,
    detail: [
      `Version: ${VERSION}`,
      `License: ${LICENSE}`,
      '',
      `SHA-256 Signature:`,
      APP_SIGNATURE,
      '',
      'Signatories:',
      ` • ${DEVELOPERS[0]}`,
      ` • ${DEVELOPERS[1]}`,
      '',
      `© ${COMPANY}`,
      '',
      'Token: $1799 (Zora.co / Base Chain)'
    ].join('\n')
  });
}

function showSignature() {
  dialog.showMessageBox(mainWindow, {
    type: 'info',
    title: 'SHA-256 Digital Signature',
    message: 'Application Digital Signature',
    detail: [
      `Algorithm: SHA-256`,
      `Hash: ${APP_SIGNATURE}`,
      `Project: ${APP_NAME}`,
      `Version: ${VERSION}`,
      `License: ${LICENSE}`,
      `Signer 1: ${DEVELOPERS[0]}`,
      `Signer 2: ${DEVELOPERS[1]}`,
      `Company: ${COMPANY}`,
      `Date: 2026-02-18`
    ].join('\n')
  });
}

async function verifyFileHash() {
  const result = await dialog.showOpenDialog(mainWindow, {
    title: 'Select File to Verify SHA-256',
    properties: ['openFile']
  });
  
  if (!result.canceled && result.filePaths.length > 0) {
    const filePath = result.filePaths[0];
    const hash = crypto.createHash('sha256')
      .update(fs.readFileSync(filePath))
      .digest('hex');
    
    dialog.showMessageBox(mainWindow, {
      type: 'info',
      title: 'SHA-256 Hash',
      message: path.basename(filePath),
      detail: [
        `SHA-256: ${hash}`,
        '',
        `Signed by: ${DEVELOPERS.join(' & ')}`,
        `License: ${LICENSE}`
      ].join('\n')
    });
  }
}

async function openScriptDialog() {
  const result = await dialog.showOpenDialog(mainWindow, {
    title: 'Add Script',
    filters: [
      { name: 'Scripts', extensions: ['py', 'js', 'sh', 'ps1'] },
      { name: 'All Files', extensions: ['*'] }
    ],
    properties: ['openFile']
  });

  if (!result.canceled && result.filePaths.length > 0) {
    const sourcePath = result.filePaths[0];
    const fileName = path.basename(sourcePath);
    const destPath = path.join(SCRIPTS_DIR, fileName);
    
    fs.copyFileSync(sourcePath, destPath);
    
    const hash = crypto.createHash('sha256')
      .update(fs.readFileSync(destPath))
      .digest('hex');

    mainWindow.webContents.send('script-added', {
      name: path.parse(fileName).name,
      filename: fileName,
      path: destPath,
      sha256: hash
    });

    dialog.showMessageBox(mainWindow, {
      type: 'info',
      title: 'Script Added',
      message: `Script "${fileName}" added successfully`,
      detail: `SHA-256: ${hash}`
    });
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// MENU
// ══════════════════════════════════════════════════════════════════════════════

function buildMenu() {
  const menuTemplate = [
    {
      label: APP_NAME,
      submenu: [
        { label: `About ${APP_NAME}`, click: showAbout },
        { type: 'separator' },
        { label: 'SHA-256 Signature', click: showSignature },
        { type: 'separator' },
        { label: 'Preferences', accelerator: 'CmdOrCtrl+,', click: () => mainWindow.webContents.send('navigate', 'settings') },
        { type: 'separator' },
        { role: 'quit' }
      ]
    },
    {
      label: 'File',
      submenu: [
        { label: 'New AI Agent', accelerator: 'CmdOrCtrl+N', click: () => mainWindow.webContents.send('action', 'new-agent') },
        { label: 'Add Script', accelerator: 'CmdOrCtrl+Shift+S', click: openScriptDialog },
        { type: 'separator' },
        { label: 'Backup', accelerator: 'CmdOrCtrl+B', click: () => mainWindow.webContents.send('action', 'backup') },
        { type: 'separator' },
        { label: 'Export Data', click: () => mainWindow.webContents.send('action', 'export') }
      ]
    },
    {
      label: 'View',
      submenu: [
        { label: 'Dashboard', click: () => mainWindow.webContents.send('navigate', 'dashboard') },
        { label: 'AI Agents', click: () => mainWindow.webContents.send('navigate', 'agents') },
        { label: 'Terminal', accelerator: 'CmdOrCtrl+T', click: createTerminalWindow },
        { label: 'Scripts', click: () => mainWindow.webContents.send('navigate', 'scripts') },
        { type: 'separator' },
        { role: 'toggleDevTools' },
        { role: 'reload' }
      ]
    },
    {
      label: 'AI',
      submenu: [
        { label: 'AI Chat', accelerator: 'CmdOrCtrl+Shift+A', click: () => mainWindow.webContents.send('navigate', 'ai-chat') },
        { label: 'Open Terminal', accelerator: 'CmdOrCtrl+T', click: createTerminalWindow },
        { label: 'Ollama Status', click: async () => {
          const health = await checkOllamaHealth();
          dialog.showMessageBox(mainWindow, {
            type: health.online ? 'info' : 'error',
            title: 'Ollama Status',
            message: health.online ? `✅ Ollama Online\n${health.host}` : `❌ Ollama Offline\n${health.error}`
          });
        }},
        { type: 'separator' },
        { label: 'Clear Chat History', click: () => { conversationHistory.clear(); } }
      ]
    },
    {
      label: 'Help',
      submenu: [
        { label: 'Documentation', click: () => shell.openExternal('https://gene1799.art/docs') },
        { label: 'GitHub', click: () => shell.openExternal('https://github.com/gene1799') },
        { type: 'separator' },
        { label: 'Verify SHA-256', click: verifyFileHash }
      ]
    }
  ];

  return Menu.buildFromTemplate(menuTemplate);
}

// ══════════════════════════════════════════════════════════════════════════════
// IPC HANDLERS
// ══════════════════════════════════════════════════════════════════════════════

// ─── App Info ──────────────────────────────────────────────────────────────────
ipcMain.handle('get-app-info', () => ({
  name: APP_NAME,
  version: VERSION,
  license: LICENSE,
  developers: DEVELOPERS,
  company: COMPANY,
  signature: APP_SIGNATURE,
  dataDir: USER_DATA
}));

// ─── SHA-256 ───────────────────────────────────────────────────────────────────
ipcMain.handle('compute-sha256', async (_e, data) =>
  crypto.createHash('sha256').update(data).digest('hex')
);

ipcMain.handle('compute-file-sha256', async (_e, filePath) =>
  crypto.createHash('sha256').update(fs.readFileSync(filePath)).digest('hex')
);

// ─── File Operations ───────────────────────────────────────────────────────────
ipcMain.handle('select-file', async () => {
  const result = await dialog.showOpenDialog(mainWindow, {
    properties: ['openFile'],
    filters: [
      { name: 'Scripts', extensions: ['py', 'js', 'sh', 'ps1'] },
      { name: 'All', extensions: ['*'] }
    ]
  });
  return result.canceled ? null : result.filePaths[0];
});

ipcMain.handle('open-external', (_e, url) => shell.openExternal(url));

// ─── Terminal PTY ──────────────────────────────────────────────────────────────
ipcMain.handle('terminal:create', async (event, terminalId) => {
  try {
    const ptyProcess = createPTY(terminalId);
    
    ptyProcess.onData(data => {
      event.sender.send('terminal:data', { terminalId, data });
    });

    ptyProcess.onExit(({ exitCode }) => {
      event.sender.send('terminal:exit', { terminalId, exitCode });
      ptyProcesses.delete(terminalId);
    });

    return { success: true, terminalId };
  } catch (err) {
    return { success: false, error: err.message };
  }
});

ipcMain.on('terminal:write', (event, { terminalId, data }) => {
  const ptyProcess = ptyProcesses.get(terminalId);
  if (ptyProcess) {
    ptyProcess.write(data);
  }
});

ipcMain.on('terminal:resize', (event, { terminalId, cols, rows }) => {
  const ptyProcess = ptyProcesses.get(terminalId);
  if (ptyProcess) {
    ptyProcess.resize(cols, rows);
  }
});

// Comando terminale (con gestione comandi speciali)
ipcMain.on('run-command', async (event, command) => {
  const trimmed = command.trim();
  if (!trimmed) return;

  // Gestisci comandi speciali (ai:, agent:, download:)
  const isSpecial = await handleSpecialCommand(trimmed, event.sender);
  if (isSpecial) return;

  // Comando PTY normale
  const termId = 'default';
  let ptyProcess = ptyProcesses.get(termId);
  
  if (!ptyProcess) {
    try {
      ptyProcess = createPTY(termId);
      ptyProcess.onData(data => event.sender.send('terminal-output', data));
      ptyProcess.onExit(() => {
        event.sender.send('terminal-done');
        ptyProcesses.delete(termId);
      });
    } catch (err) {
      // Fallback: usa exec se PTY non disponibile
      exec(`powershell -Command "${trimmed.replace(/"/g, '\\"')}"`, (error, stdout, stderr) => {
        event.sender.send('terminal-output', (stdout || '') + (stderr || '') + (error?.message || ''));
        event.sender.send('terminal-done');
      });
      return;
    }
  }

  ptyProcess.write(trimmed + '\r');
});

ipcMain.on('open-terminal', () => createTerminalWindow());

// ─── Ollama AI ─────────────────────────────────────────────────────────────────
ipcMain.handle('ai-ask', async (_e, { prompt, model, systemPrompt } = {}) => {
  try {
    const response = await askAI(prompt, model, systemPrompt);
    return { success: true, response };
  } catch (err) {
    return { success: false, error: err.message };
  }
});

ipcMain.handle('ai-chat', async (_e, { sessionId = 'default', message, model, systemPrompt } = {}) => {
  try {
    const result = await chatWithHistory(sessionId, message, model, systemPrompt);
    return { success: true, ...result };
  } catch (err) {
    return { success: false, error: err.message };
  }
});

ipcMain.handle('ai-stream', async (event, { sessionId = 'default', message, model, systemPrompt } = {}) => {
  try {
    const history = getHistory(sessionId);
    if (history.length === 0 && systemPrompt) {
      history.push({ role: 'system', content: systemPrompt });
    }
    history.push({ role: 'user', content: message });

    const stream = await ollama.chat({
      model: model || ACTIVE_MODEL,
      messages: history,
      stream: true
    });

    let fullResponse = '';
    for await (const chunk of stream) {
      const token = chunk.message?.content || '';
      fullResponse += token;
      event.sender.send('ai-stream-chunk', { chunk: token, done: false, sessionId });
    }

    history.push({ role: 'assistant', content: fullResponse });
    event.sender.send('ai-stream-chunk', { chunk: '', done: true, sessionId, fullResponse });
    
    return { success: true, response: fullResponse };
  } catch (err) {
    event.sender.send('ai-stream-chunk', { chunk: '', done: true, sessionId, error: err.message });
    return { success: false, error: err.message };
  }
});

ipcMain.handle('ai-generate', async (_e, { prompt, model, options } = {}) => {
  try {
    const text = await generateText(prompt, model, options);
    return { success: true, response: text };
  } catch (err) {
    return { success: false, error: err.message };
  }
});

ipcMain.handle('ai-models', async () => {
  try {
    const models = await listOllamaModels();
    return { success: true, models };
  } catch (err) {
    return { success: false, error: err.message };
  }
});

ipcMain.handle('ai-health', async () => {
  return await checkOllamaHealth();
});

ipcMain.handle('ai-set-model', (_e, { model } = {}) => {
  if (!model) return { success: false, error: 'model required' };
  ACTIVE_MODEL = model;
  return { success: true, activeModel: ACTIVE_MODEL };
});

ipcMain.handle('ai-get-model', () => ({ activeModel: ACTIVE_MODEL }));

ipcMain.handle('ai-clear-history', (_e, { sessionId } = {}) => {
  if (sessionId) {
    conversationHistory.delete(sessionId);
    return { success: true, cleared: sessionId };
  }
  conversationHistory.clear();
  return { success: true, cleared: 'all' };
});

ipcMain.handle('ai-get-history', (_e, { sessionId = 'default' } = {}) => {
  return { history: getHistory(sessionId) };
});

// ─── Downloader ────────────────────────────────────────────────────────────────
ipcMain.handle('download-model', async (event, { url, fileName }) => {
  try {
    const result = await downloadModel(url, fileName, (pct) => {
      event.sender.send('download-progress', { fileName, progress: pct });
    });
    return result;
  } catch (err) {
    return { success: false, error: err.message };
  }
});

ipcMain.handle('pull-ollama-model', async (event, { modelName }) => {
  try {
    const result = await pullOllamaModel(modelName, (chunk) => {
      event.sender.send('pull-progress', chunk);
    });
    return result;
  } catch (err) {
    return { success: false, error: err.message };
  }
});

ipcMain.handle('list-models', () => {
  return { models: listDownloadedModels() };
});

ipcMain.handle('list-agents', () => {
  return { agents: listDownloadedAgents() };
});

// ─── API Request (FastAPI backend) ────────────────────────────────────────────
ipcMain.handle('api-request', async (_e, { endpoint, method, body }) => {
  try {
    const result = await apiRequest(endpoint, method, body);
    return { success: true, data: result };
  } catch (err) {
    return { success: false, error: err.message };
  }
});

// ══════════════════════════════════════════════════════════════════════════════
// APP LIFECYCLE
// ══════════════════════════════════════════════════════════════════════════════

app.whenReady().then(async () => {
  console.log(`\n${'═'.repeat(60)}`);
  console.log(` ⬢ ${APP_NAME} v${VERSION}`);
  console.log(` SHA-256: ${APP_SIGNATURE.substring(0, 32)}...`);
  console.log(` License: ${LICENSE}`);
  console.log(` ${DEVELOPERS.join(' & ')}`);
  console.log(` © ${COMPANY}`);
  console.log(` Ollama: ${ollama.config?.host || 'http://127.0.0.1:11434'}`);
  console.log(` Model: ${ACTIVE_MODEL}`);
  console.log(` Data: ${USER_DATA}`);
  console.log(`${'═'.repeat(60)}\n`);

  // Start Express HTTP server (API backend)
  try {
    const { startServer } = require('./server');
    const serverPort = parseInt(process.env.PORT || '8888', 10);
    await startServer(serverPort);
    console.log(`✅ Express API server running`);
  } catch (err) {
    console.warn(`⚠️  Express server failed: ${err.message}`);
    console.warn('   Frontend will use IPC bridge (Electron only)');
  }

  // Check Ollama health
  const health = await checkOllamaHealth();
  if (!health.online) {
    console.warn('⚠️  Ollama non disponibile. Avvia: ollama serve');
  }

  Menu.setApplicationMenu(buildMenu());
  createMainWindow();

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createMainWindow();
    }
  });
});

app.on('window-all-closed', () => {
  // Kill all PTY processes
  ptyProcesses.forEach(pty => pty.kill());
  ptyProcesses.clear();
  
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

app.on('before-quit', () => {
  // Cleanup
  ptyProcesses.forEach(pty => pty.kill());
  ptyProcesses.clear();
});
