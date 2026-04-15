'use strict';

/**
 * GENE1799 ART CORPORATIONE - Express Server v5.2.0
 * Ponte HTTP per core.js API -> frontend (Electron o Browser)
 *
 * Signatories:
 *   Marco Antonio Saverio Mazzitelli
 *   Fabio Amedeo Lo Presti
 * License: 16/A408979L
 * Arthemis Ludovici Production
 */

const express = require('express');
const path    = require('path');
const crypto  = require('crypto');
const core    = require('./core');

const app  = express();
const PORT = process.env.PORT || 8888;

// Middleware
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET,POST,PUT,DELETE,OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Content-Type,Authorization');
  if (req.method === 'OPTIONS') return res.sendStatus(200);
  next();
});
app.use(express.json({ limit: '10mb' }));
app.use(express.static(path.join(__dirname, 'renderer')));

app.use((req, _res, next) => {
  if (req.path.startsWith('/api/')) {
    core.log('INFO', `${req.method} ${req.path}`, 'http');
  }
  next();
});

// ── System ──
app.get('/api/status',    (_r, res) => res.json(core.apiStatus()));
app.get('/api/signature', (_r, res) => res.json(core.apiSignature()));
app.get('/api/stats',     (_r, res) => res.json(core.apiStats()));
app.get('/api/logs',      (_r, res) => res.json(core.apiLogs()));

// ── Auth ──
app.post('/api/auth/register',     (req, res) => res.json(core.apiAuthRegister(req.body)));
app.post('/api/auth/verify-email', (req, res) => res.json(core.apiAuthVerifyEmail(req.body)));
app.post('/api/auth/login',        (req, res) => res.json(core.apiAuthLogin(req.body)));

// ── Agents ──
app.get ('/api/agents',      (_r, res) => res.json(core.apiAgentsGet()));
app.post('/api/agents',      (req, res) => res.json(core.apiAgentsPost(req.body)));
app.get ('/api/agents/list', (_r, res) => res.json(core.apiAgentsList()));

app.post('/api/agents/call', async (req, res) => {
  try { res.json(await core.apiAgentsCall(req.body)); }
  catch (e) { res.status(500).json({ error: e.message }); }
});

app.post('/api/agents/workflow/analysis-social', async (req, res) => {
  try { res.json(await core.apiAgentsWorkflowAnalysisSocial(req.body)); }
  catch (e) { res.status(500).json({ error: e.message }); }
});

app.post('/api/agents/workflow/token-campaign', async (req, res) => {
  try { res.json(await core.apiAgentsWorkflowTokenCampaign(req.body)); }
  catch (e) { res.status(500).json({ error: e.message }); }
});

app.post('/api/agents/workflow/debate', async (req, res) => {
  try { res.json(await core.apiAgentsWorkflowDebate(req.body)); }
  catch (e) { res.status(500).json({ error: e.message }); }
});

app.get   ('/api/agents/log',    (_r, res) => res.json(core.apiAgentsLog()));
app.delete('/api/agents/memory', (_r, res) => res.json(core.apiAgentsMemoryDelete()));

// ── Scripts ──
app.get ('/api/scripts', (_r, res) => res.json(core.apiScriptsGet()));
app.post('/api/scripts', (req, res) => res.json(core.apiScriptsPost(req.body)));

// ── Signatures ──
app.get ('/api/signatures',        (_r, res) => res.json(core.apiSignaturesGet()));
app.post('/api/signatures/verify', (req, res) => res.json(core.apiSignaturesVerify(req.body)));
app.post('/api/signatures/file',   (req, res) => res.json(core.apiSignaturesFile(req.body)));

// ── Token $1799 ──
app.get ('/api/token/1799',         (_r, res) => res.json(core.apiToken1799Info()));
app.get ('/api/token/1799/holders', (_r, res) => res.json(core.apiToken1799HoldersGet()));
app.post('/api/token/1799/holders', (req, res) => res.json(core.apiToken1799HoldersPost(req.body)));

// ── AI ──
app.post('/api/ai/ask',       async (req, res) => { try { res.json(await core.apiAiAsk(req.body)); } catch(e) { res.status(500).json({error:e.message}); } });
app.post('/api/ai/chat',      async (req, res) => { try { res.json(await core.apiAiChat(req.body)); } catch(e) { res.status(500).json({error:e.message}); } });
app.post('/api/ai/generate',  async (req, res) => { try { res.json(await core.apiAiGenerate(req.body)); } catch(e) { res.status(500).json({error:e.message}); } });
app.get ('/api/ai/models',    async (_r, res) => { try { res.json(await core.apiAiModels()); } catch(e) { res.status(500).json({error:e.message}); } });
app.get ('/api/ai/health',    async (_r, res) => { try { res.json(await core.apiAiHealth()); } catch(e) { res.status(500).json({error:e.message}); } });
app.post('/api/ai/set-model', (req, res) => res.json(core.apiAiSetModel(req.body)));
app.delete('/api/ai/sessions',     (_r, res) => res.json(core.apiAiDeleteSessions()));
app.get   ('/api/ai/session/:id',  (req, res) => res.json(core.apiAiGetSession(req.params.id)));
app.delete('/api/ai/session/:id',  (req, res) => res.json(core.apiAiDeleteSession(req.params.id)));

// ── Social Posts ──
app.get('/api/social/posts', (_r, res) => res.json(core.store.posts));

app.post('/api/social/posts', (req, res) => {
  const post = { id: core.store.posts.length + 1, ...req.body, status: 'scheduled', created: new Date().toISOString() };
  core.store.posts.push(post);
  core.log('INFO', `Post scheduled: ${post.platforms?.join(', ')}`, 'social');
  res.json(post);
});

app.post('/api/social/generate', async (req, res) => {
  try {
    const { topic, platforms, tone } = req.body;
    const prompt = `Create a social media post about "${topic}" for platforms: ${(platforms||['Twitter/X']).join(', ')}. Tone: ${tone||'professional'}. Include relevant hashtags. Respond with ONLY the post text.`;
    res.json(await core.apiAiAsk({ prompt, systemPrompt: 'You are Gene1799 Social Agent. Create engaging social media posts for Web3 and digital art.' }));
  } catch(e) { res.status(500).json({ error: e.message }); }
});

// ── Content Creation ──
app.post('/api/content/generate', async (req, res) => {
  try {
    const { type, description, style } = req.body;
    const prompts = {
      text:  `Write creative content: "${description}". Style: ${style||'artistic'}`,
      video: `Create a detailed video storyboard for: "${description}". Include scenes, transitions, narration.`,
      image: `Describe a detailed image prompt for AI generation: "${description}". Include style, composition, colors.`,
      audio: `Write a script for audio content about: "${description}".`,
      ad:    `Create advertising copy for: "${description}". Include headline, body, call to action.`,
    };
    res.json(await core.apiAiAsk({ prompt: prompts[type] || prompts.text, systemPrompt: 'You are Gene1799 Creative Agent.' }));
  } catch(e) { res.status(500).json({ error: e.message }); }
});

// ── NFTs ──
app.get('/api/nfts', (_r, res) => res.json(core.store.nfts));

app.post('/api/nfts', (req, res) => {
  const nft = {
    id: core.store.nfts.length + 1, ...req.body,
    sha256: crypto.createHash('sha256').update(JSON.stringify(req.body)).digest('hex'),
    status: 'draft', created: new Date().toISOString()
  };
  core.store.nfts.push(nft);
  core.log('INFO', `NFT created: ${nft.name}`, 'web3');
  res.json(nft);
});

app.post('/api/nfts/generate-metadata', async (req, res) => {
  try {
    const { name, description, collection } = req.body;
    const prompt = `Generate NFT metadata JSON for:\nName: ${name}\nDescription: ${description}\nCollection: ${collection||'Gene1799'}\nInclude: name, description, image placeholder, attributes array. Respond ONLY with valid JSON.`;
    res.json(await core.apiAiAsk({ prompt }));
  } catch(e) { res.status(500).json({ error: e.message }); }
});

// ── AI Terminal Command Verification ──
app.post('/api/ai/verify-command', async (req, res) => {
  try {
    const { command } = req.body;
    const dangerous = /rm\s+-rf\s+\/|format\s+c:|del\s+\/[sfq]|shutdown|mkfs|dd\s+if=/i;
    if (dangerous.test(command)) {
      return res.json({ success: true, safe: false, corrected: command, explanation: 'DANGEROUS: This command could damage your system.', risk_level: 'critical', warnings: ['Blocked: destructive command detected'], improvements: [] });
    }
    const prompt = `Analyze this terminal command: "${command}"\nRespond ONLY with valid JSON: {"safe":true/false,"corrected":"...","explanation":"...","risk_level":"low/medium/high/critical","warnings":[],"improvements":[]}`;
    const result = await core.apiAiAsk({ prompt, systemPrompt: 'You are a command security analyzer. Respond ONLY with valid JSON.' });
    try {
      let jsonStr = result.response || '';
      const match = jsonStr.match(/```(?:json)?\s*([\s\S]*?)```/);
      if (match) jsonStr = match[1];
      res.json({ success: true, ...JSON.parse(jsonStr.trim()) });
    } catch {
      res.json({ success: true, safe: true, corrected: command, explanation: result.response || 'OK', risk_level: 'low', warnings: [], improvements: [] });
    }
  } catch(e) { res.status(500).json({ error: e.message }); }
});

// ── Backup ──
app.post('/api/system/backup', (_r, res) => {
  const backup = { timestamp: new Date().toISOString(), version: core.VERSION, store: JSON.parse(JSON.stringify(core.store)) };
  core.log('INFO', 'Backup created', 'system');
  res.json({ success: true, backup });
});

// ── Fallback ──
app.get('*', (req, res) => {
  if (!req.path.startsWith('/api/')) res.sendFile(path.join(__dirname, 'renderer', 'index.html'));
  else res.status(404).json({ error: 'Endpoint not found' });
});

app.use((err, _req, res, _next) => {
  core.log('ERROR', `Server error: ${err.message}`, 'http');
  res.status(500).json({ error: err.message });
});

// ── Start ──
function startServer(port = PORT) {
  return new Promise((resolve, reject) => {
    const server = app.listen(port, () => {
      console.log(`\n${'='.repeat(60)}`);
      console.log(` Gene1799 Art Corporatione v${core.VERSION}`);
      console.log(` http://localhost:${port}`);
      console.log(` API: http://localhost:${port}/api/status`);
      console.log(` SHA-256: ${core.APP_SIGNATURE.substring(0, 32)}...`);
      console.log(` License: ${core.LICENSE}`);
      console.log(` ${core.DEVELOPERS.join(' & ')}`);
      console.log(`${'='.repeat(60)}\n`);
      core.log('INFO', `Server started on port ${port}`, 'http');
      resolve(server);
    });
    server.on('error', (err) => {
      if (err.code === 'EADDRINUSE') {
        console.warn(`Port ${port} in use, trying ${port+1}...`);
        resolve(startServer(port + 1));
      } else reject(err);
    });
  });
}

if (require.main === module) {
  startServer().catch(err => { console.error('Failed to start:', err.message); process.exit(1); });
}

module.exports = { app, startServer };
