'use strict';

/**
 * GENE1799 ART CORPORATIONE - Core v5.1.0 (no HTTP, no ports)
 */

const crypto = require('crypto');
const { Ollama } = require('ollama');
let orchestrator;
try {
  orchestrator = require('../agents/multiAgent').orchestrator;
} catch (e) {
  console.warn('⚠️  multiAgent module not available, using stub');
  orchestrator = {
    getAgents: () => [],
    callAgent: async () => ({ error: 'multiAgent not loaded' }),
    workflowAnalysisSocial: async () => ({ error: 'not available' }),
    workflowTokenCampaign: async () => ({ error: 'not available' }),
    workflowAgentDebate: async () => ({ error: 'not available' }),
    getLog: () => [],
    clearAll: () => ({ success: true }),
  };
}

// ─── App Constants ─────────────────────────────────────────────────────────────

const APP_NAME = 'Gene1799 Art Corporatione';
const VERSION = '5.1.0';
const LICENSE = '16/A408979L';
const DEVELOPERS = ['Marco Antonio Saverio Mazzitelli', 'Fabio Amedeo Lo Presti'];
const COMPANY = 'Arthemis Ludovici Production';

let ACTIVE_MODEL = process.env.OLLAMA_MODEL || 'llama3:8b';

const ollama = new Ollama({
  host: process.env.OLLAMA_HOST || 'http://127.0.0.1:11434'
});

// ─── Utilities ─────────────────────────────────────────────────────────────────

function sha256(data) {
  return crypto.createHash('sha256')
    .update(typeof data === 'string' ? data : JSON.stringify(data))
    .digest('hex');
}

const APP_SIGNATURE = sha256({
  project: APP_NAME,
  version: VERSION,
  license: LICENSE,
  signatories: DEVELOPERS,
  company: COMPANY,
  date: '2026-02-12'
});

// ─── In-Memory Store ───────────────────────────────────────────────────────────

const store = {
  users: [],
  agents: [],
  posts: [],
  nfts: [],
  scripts: [],
  token1799_holders: [],
  signatures: [{
    entity_type: 'application',
    entity_id: `${APP_NAME}_v${VERSION}`,
    sha256: APP_SIGNATURE,
    signer: DEVELOPERS.join(' & '),
    license: LICENSE,
    date: new Date().toISOString()
  }],
  logs: []
};

// ─── Conversation History ──────────────────────────────────────────────────────

/** @type {Map<string, Array<{role: string, content: string}>>} */
const sessions = new Map();

function getSession(id) {
  if (!sessions.has(id)) sessions.set(id, []);
  return sessions.get(id);
}

// ─── Auth Utils ────────────────────────────────────────────────────────────────

function generateTOTPSecret() {
  return crypto.randomBytes(20)
    .toString('base64')
    .replace(/[^A-Z2-7]/gi, '')
    .substring(0, 16);
}

function computeTOTP(secret, timeStep = 30) {
  const counter = Math.floor(Date.now() / 1000 / timeStep);
  const buf = Buffer.alloc(8);
  buf.writeUInt32BE(0, 0);
  buf.writeUInt32BE(counter, 4);
  const hmac = crypto.createHmac('sha1', Buffer.from(secret, 'base32'));
  hmac.update(buf);
  const hash = hmac.digest();
  const offset = hash[hash.length - 1] & 0xf;
  return ((hash.readUInt32BE(offset) & 0x7fffffff) % 1000000)
    .toString()
    .padStart(6, '0');
}

function hashPassword(password) {
  const salt = crypto.randomBytes(32).toString('hex');
  const hash = crypto.pbkdf2Sync(password, salt, 100000, 64, 'sha256').toString('hex');
  return { salt, hash };
}

function verifyPassword(password, salt, storedHash) {
  const hash = crypto.pbkdf2Sync(password, salt, 100000, 64, 'sha256').toString('hex');
  return crypto.timingSafeEqual(Buffer.from(hash), Buffer.from(storedHash));
}

function generateToken(payload) {
  const header = Buffer.from(JSON.stringify({ alg: 'HS256', typ: 'JWT' })).toString('base64url');
  const body = Buffer.from(JSON.stringify({
    ...payload,
    iat: Date.now(),
    exp: Date.now() + 7 * 24 * 60 * 60 * 1000
  })).toString('base64url');
  const sig = crypto
    .createHmac('sha256', `gene1799_${LICENSE}`)
    .update(`${header}.${body}`)
    .digest('base64url');
  return `${header}.${body}.${sig}`;
}

// ─── Logger ────────────────────────────────────────────────────────────────────

function log(level, message, module = 'system') {
  const entry = { level, message, module, timestamp: new Date().toISOString() };
  store.logs.push(entry);
  if (store.logs.length > 500) store.logs.shift();
  const prefix = level === 'ERROR' ? '❌' : level === 'WARN' ? '⚠️' : '✅';
  console.log(`${prefix} [${module}] ${message}`);
}

// ─── Ollama AI Helpers ─────────────────────────────────────────────────────────

async function aiAsk(prompt, model = ACTIVE_MODEL, systemPrompt = null) {
  const messages = [];
  if (systemPrompt) messages.push({ role: 'system', content: systemPrompt });
  messages.push({ role: 'user', content: prompt });
  const r = await ollama.chat({ model, messages });
  return r.message.content;
}

async function aiChat(sessionId, message, model = ACTIVE_MODEL, systemPrompt = null) {
  const history = getSession(sessionId);
  if (history.length === 0 && systemPrompt) {
    history.push({ role: 'system', content: systemPrompt });
  }
  history.push({ role: 'user', content: message });
  const r = await ollama.chat({ model, messages: history });
  history.push({ role: 'assistant', content: r.message.content });
  return { response: r.message.content, historyLength: history.length };
}

async function aiGenerate(prompt, model = ACTIVE_MODEL, options = {}) {
  const r = await ollama.generate({
    model,
    prompt,
    stream: false,
    options: { temperature: 0.7, top_p: 0.9, num_predict: 1024, ...options }
  });
  return r.response;
}

async function aiHealth() {
  try {
    const r = await ollama.list();
    return {
      online: true,
      models: r.models.length,
      host: process.env.OLLAMA_HOST || 'http://127.0.0.1:11434'
    };
  } catch (e) {
    return { online: false, error: e.message };
  }
}

// ─── Core API (ex routes) ──────────────────────────────────────────────────────
// Tutte funzioni sincrone/async, senza HTTP, riusabili ovunque.

// ── Sistema ──

function apiStatus() {
  return {
    status: 'online',
    version: VERSION,
    timestamp: new Date().toISOString(),
    signature: APP_SIGNATURE.substring(0, 32) + '...',
    activeModel: ACTIVE_MODEL
  };
}

function apiSignature() {
  return {
    project: APP_NAME,
    version: VERSION,
    algorithm: 'SHA-256',
    hash: APP_SIGNATURE,
    license: LICENSE,
    signatories: DEVELOPERS,
    company: COMPANY,
    date: '2026-02-12'
  };
}

function apiStats() {
  return {
    users: store.users.length,
    agents: store.agents.length,
    posts: store.posts.length,
    nfts: store.nfts.length,
    scripts: store.scripts.length,
    signatures: store.signatures.length,
    token1799_holders: store.token1799_holders.length,
    ai_sessions: sessions.size,
    activeModel: ACTIVE_MODEL
  };
}

function apiLogs() {
  return store.logs.slice(-100).reverse();
}

// ── Token $1799 ──

function apiToken1799Info() {
  return {
    name: 'Gene1799 Token',
    symbol: '$1799',
    platform: 'zora.co',
    chain: 'Base (Ethereum L2)',
    contract_url: 'https://zora.co/collect/base:gene1799',
    ecosystem: APP_NAME,
    holders: store.token1799_holders.length
  };
}

function apiToken1799HoldersGet() {
  return store.token1799_holders;
}

function apiToken1799HoldersPost(body) {
  const holder = {
    id: store.token1799_holders.length + 1,
    ...body,
    added: new Date().toISOString()
  };
  store.token1799_holders.push(holder);
  return holder;
}

// ── Auth ──

function apiAuthRegister(body) {
  const { username, email, password } = body || {};
  if (!username || !email || !password) return { error: 'Missing fields' };
  if (store.users.find(u => u.username === username || u.email === email)) {
    return { error: 'User already exists' };
  }
  const { salt, hash } = hashPassword(password);
  const totp_secret = generateTOTPSecret();
  const otp = Math.floor(100000 + Math.random() * 900000).toString();
  const user = {
    id: store.users.length + 1,
    username,
    email,
    password_salt: salt,
    password_hash: hash,
    totp_secret,
    totp_enabled: true,
    email_verified: false,
    otp_code: otp,
    created: new Date().toISOString()
  };
  store.users.push(user);
  log('INFO', `User registered: ${username}`, 'auth');
  return {
    success: true,
    user_id: user.id,
    totp_secret,
    totp_uri: `otpauth://totp/${APP_NAME}:${email}?secret=${totp_secret}&issuer=${APP_NAME}`,
    otp_code: otp,
    message: 'Verify email with OTP code'
  };
}

function apiAuthVerifyEmail(body) {
  const user = store.users.find(u => u.id === body.user_id);
  if (!user) return { error: 'User not found' };
  if (user.otp_code !== body.otp) return { error: 'Invalid OTP' };
  user.email_verified = true;
  return { success: true, message: 'Email verified' };
}

function apiAuthLogin(body) {
  const { username, password } = body || {};
  const user = store.users.find(
    u => u.username === username || u.email === username
  );
  if (!user) return { error: 'User not found' };
  if (!verifyPassword(password, user.password_salt, user.password_hash)) {
    return { error: 'Invalid password' };
  }
  if (!user.email_verified) return { error: 'Email not verified' };
  const token = generateToken({ id: user.id, username: user.username });
  log('INFO', `User logged in: ${user.username}`, 'auth');
  return {
    success: true,
    token,
    user: { id: user.id, username: user.username, email: user.email }
  };
}

// ── Agents ──

function apiAgentsGet() {
  return store.agents;
}

function apiAgentsPost(body) {
  const agent = {
    id: store.agents.length + 1,
    ...body,
    runs: 0,
    created: new Date().toISOString()
  };
  store.agents.push(agent);
  log('INFO', `Agent created: ${agent.name}`, 'agents');
  return agent;
}

// multiAgent orchestrator (dalla coda del tuo server.js)
function apiAgentsList() {
  return {
    agents: orchestrator.getAgents(),
    workflows: ['analysis-social', 'token-campaign', 'agent-debate']
  };
}

async function apiAgentsCall(body) {
  const { agent, message } = body || {};
  if (!agent || !message) return { error: 'agent e message richiesti' };
  return orchestrator.callAgent(agent, message);
}

async function apiAgentsWorkflowAnalysisSocial(body) {
  const { topic, platforms } = body || {};
  if (!topic) return { error: 'topic richiesto' };
  return orchestrator.workflowAnalysisSocial(topic, platforms);
}

async function apiAgentsWorkflowTokenCampaign(body) {
  const { focus } = body || {};
  return orchestrator.workflowTokenCampaign(focus);
}

async function apiAgentsWorkflowDebate(body) {
  const { topic, rounds } = body || {};
  if (!topic) return { error: 'topic richiesto' };
  return orchestrator.workflowAgentDebate(topic, rounds || 2);
}

function apiAgentsLog() {
  return orchestrator.getLog();
}

function apiAgentsMemoryDelete() {
  orchestrator.clearAll();
  return { success: true, message: 'Memoria agenti azzerata' };
}

// ── Scripts ──

function apiScriptsGet() {
  return store.scripts;
}

function apiScriptsPost(body) {
  const script = {
    id: store.scripts.length + 1,
    ...body,
    sha256: sha256(body.content || body.name),
    runs: 0,
    active: true,
    added: new Date().toISOString()
  };
  store.scripts.push(script);
  log('INFO', `Script added: ${script.name}`, 'scripts');
  return script;
}

// ── Signatures ──

function apiSignaturesGet() {
  return store.signatures;
}

function apiSignaturesVerify(body) {
  const computed = sha256(body.data || '');
  return {
    valid: computed === body.hash,
    computed,
    provided: body.hash,
    algorithm: 'SHA-256'
  };
}

function apiSignaturesFile(body) {
  const sig = {
    entity_type: 'file',
    entity_id: body.filename,
    sha256: body.hash,
    signer: DEVELOPERS.join(' & '),
    license: LICENSE,
    date: new Date().toISOString()
  };
  store.signatures.push(sig);
  return sig;
}

// ── AI high level API ──

async function apiAiAsk(body) {
  const { prompt, model, systemPrompt } = body || {};
  if (!prompt) return { error: 'prompt required' };
  try {
    const response = await aiAsk(prompt, model, systemPrompt);
    log('INFO', `AI ask: ${prompt.substring(0, 50)}`, 'ai');
    return { success: true, response, model: model || ACTIVE_MODEL };
  } catch (err) {
    log('ERROR', `AI ask failed: ${err.message}`, 'ai');
    return { success: false, error: err.message };
  }
}

async function apiAiChat(body) {
  const { sessionId = 'default', message, model, systemPrompt } = body || {};
  if (!message) return { error: 'message required' };
  try {
    const result = await aiChat(sessionId, message, model, systemPrompt);
    log('INFO', `AI chat [${sessionId}]: ${message.substring(0, 50)}`, 'ai');
    return { success: true, sessionId, ...result, model: model || ACTIVE_MODEL };
  } catch (err) {
    log('ERROR', `AI chat failed: ${err.message}`, 'ai');
    return { success: false, error: err.message };
  }
}

async function apiAiGenerate(body) {
  const { prompt, model, options } = body || {};
  if (!prompt) return { error: 'prompt required' };
  try {
    const response = await aiGenerate(prompt, model, options);
    return { success: true, response, model: model || ACTIVE_MODEL };
  } catch (err) {
    return { success: false, error: err.message };
  }
}

async function apiAiModels() {
  try {
    const r = await ollama.list();
    return { success: true, models: r.models, activeModel: ACTIVE_MODEL };
  } catch (err) {
    return { success: false, error: err.message };
  }
}

async function apiAiHealth() {
  return aiHealth();
}

function apiAiSetModel(body) {
  if (!body.model) return { error: 'model required' };
  ACTIVE_MODEL = body.model;
  log('INFO', `Active model changed to ${ACTIVE_MODEL}`, 'ai');
  return { success: true, activeModel: ACTIVE_MODEL };
}

function apiAiDeleteSessions() {
  sessions.clear();
  return { success: true, message: 'All sessions cleared' };
}

function apiAiGetSession(id) {
  return { sessionId: id, history: getSession(id) };
}

function apiAiDeleteSession(id) {
  sessions.delete(id);
  return { success: true, cleared: id };
}

// ─── Exports ───────────────────────────────────────────────────────────────────

module.exports = {
  // meta
  APP_NAME,
  VERSION,
  LICENSE,
  DEVELOPERS,
  COMPANY,
  APP_SIGNATURE,
  // stato
  store,
  sessions,
  getSession,
  // log
  log,
  // auth utils
  generateTOTPSecret,
  computeTOTP,
  hashPassword,
  verifyPassword,
  generateToken,
  // ai low level
  aiAsk,
  aiChat,
  aiGenerate,
  aiHealth,
  // core API (ex routes)
  apiStatus,
  apiSignature,
  apiStats,
  apiLogs,
  apiToken1799Info,
  apiToken1799HoldersGet,
  apiToken1799HoldersPost,
  apiAuthRegister,
  apiAuthVerifyEmail,
  apiAuthLogin,
  apiAgentsGet,
  apiAgentsPost,
  apiAgentsList,
  apiAgentsCall,
  apiAgentsWorkflowAnalysisSocial,
  apiAgentsWorkflowTokenCampaign,
  apiAgentsWorkflowDebate,
  apiAgentsLog,
  apiAgentsMemoryDelete,
  apiScriptsGet,
  apiScriptsPost,
  apiSignaturesGet,
  apiSignaturesVerify,
  apiSignaturesFile,
  apiAiAsk,
  apiAiChat,
  apiAiGenerate,
  apiAiModels,
  apiAiHealth,
  apiAiSetModel,
  apiAiDeleteSessions,
  apiAiGetSession,
  apiAiDeleteSession
};
