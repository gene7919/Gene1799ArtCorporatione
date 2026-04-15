/**
 * Gene1799 Art Corporatione - Electron Preload v5.2.0
 * Secure bridge: renderer <-> main process
 */
const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('gene1799', {
  getAppInfo: () => ipcRenderer.invoke('get-app-info'),
  computeSHA256: (data) => ipcRenderer.invoke('compute-sha256', data),
  computeFileSHA256: (filePath) => ipcRenderer.invoke('compute-file-sha256', filePath),
  selectFile: () => ipcRenderer.invoke('select-file'),
  openExternal: (url) => ipcRenderer.invoke('open-external', url),

  // AI
  aiAsk: (opts) => ipcRenderer.invoke('ai-ask', opts),
  aiChat: (opts) => ipcRenderer.invoke('ai-chat', opts),
  aiStream: (opts) => ipcRenderer.invoke('ai-stream', opts),
  aiGenerate: (opts) => ipcRenderer.invoke('ai-generate', opts),
  aiModels: () => ipcRenderer.invoke('ai-models'),
  aiHealth: () => ipcRenderer.invoke('ai-health'),
  aiSetModel: (opts) => ipcRenderer.invoke('ai-set-model', opts),
  aiGetModel: () => ipcRenderer.invoke('ai-get-model'),
  aiClearHistory: (opts) => ipcRenderer.invoke('ai-clear-history', opts),
  aiGetHistory: (opts) => ipcRenderer.invoke('ai-get-history', opts),
  onAiStreamChunk: (cb) => ipcRenderer.on('ai-stream-chunk', (_e, d) => cb(d)),

  // Terminal
  terminalCreate: (id) => ipcRenderer.invoke('terminal:create', id),
  terminalWrite: (id, data) => ipcRenderer.send('terminal:write', { terminalId: id, data }),
  terminalResize: (id, cols, rows) => ipcRenderer.send('terminal:resize', { terminalId: id, cols, rows }),
  runCommand: (cmd) => ipcRenderer.send('run-command', cmd),
  openTerminal: () => ipcRenderer.send('open-terminal'),
  onTerminalData: (cb) => ipcRenderer.on('terminal:data', (_e, d) => cb(d)),
  onTerminalOutput: (cb) => ipcRenderer.on('terminal-output', (_e, d) => cb(d)),
  onTerminalDone: (cb) => ipcRenderer.on('terminal-done', () => cb()),

  // Downloader
  downloadModel: (opts) => ipcRenderer.invoke('download-model', opts),
  pullOllamaModel: (opts) => ipcRenderer.invoke('pull-ollama-model', opts),
  listModels: () => ipcRenderer.invoke('list-models'),
  listAgents: () => ipcRenderer.invoke('list-agents'),
  onDownloadProgress: (cb) => ipcRenderer.on('download-progress', (_e, d) => cb(d)),
  onPullProgress: (cb) => ipcRenderer.on('pull-progress', (_e, d) => cb(d)),

  // API proxy
  apiRequest: (opts) => ipcRenderer.invoke('api-request', opts),

  // Events from menu
  onNavigate: (cb) => ipcRenderer.on('navigate', (_e, s) => cb(s)),
  onAction: (cb) => ipcRenderer.on('action', (_e, a) => cb(a)),
  onScriptAdded: (cb) => ipcRenderer.on('script-added', (_e, d) => cb(d)),
});
