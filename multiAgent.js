'use strict';
/**
 * GENE1799 - Multi-Agent Orchestrator v5.2.0
 * Gestione agenti AI con Ollama
 */

const { Ollama } = require('ollama');
const ollama = new Ollama({ host: process.env.OLLAMA_HOST || 'http://127.0.0.1:11434' });
const ACTIVE_MODEL = process.env.OLLAMA_MODEL || 'llama3:8b';

// ─── Agent Definitions ──────────────────────────────────────────────────────
const AGENTS = {
  'social-agent': {
    name: 'Social Agent',
    role: 'Social media strategy, content creation, scheduling',
    systemPrompt: 'You are Gene1799 Social Agent. You help with social media strategy, creating engaging posts for platforms like Instagram, Twitter/X, TikTok, LinkedIn, Farcaster, and Lens Protocol. Always respond in a professional but creative way. Focus on Web3, NFT art, and digital culture.'
  },
  'blockchain-agent': {
    name: 'Blockchain Agent',
    role: 'Web3, NFT, token $1799, smart contracts',
    systemPrompt: 'You are Gene1799 Blockchain Agent. You assist with Web3 topics including NFT creation on Zora.co, token $1799 management on Base chain, smart contract analysis, and blockchain data. You understand ERC-721, ERC-1155, and ERC-20 standards.'
  },
  'creative-agent': {
    name: 'Creative Agent',
    role: 'Art direction, content ideas, visual concepts',
    systemPrompt: 'You are Gene1799 Creative Agent. You generate artistic concepts, visual descriptions for AI image generation, video storyboards, and creative writing. Your style blends contemporary digital art with classical influences.'
  },
  'analyst-agent': {
    name: 'Analyst Agent',
    role: 'Data analysis, market research, trends',
    systemPrompt: 'You are Gene1799 Analyst Agent. You analyze data, market trends, social metrics, and provide actionable insights. You present findings clearly with recommendations.'
  },
  'code-agent': {
    name: 'Code Agent',
    role: 'Programming, scripts, automation, debugging',
    systemPrompt: 'You are Gene1799 Code Agent. You help with programming tasks including Python, JavaScript, Node.js, Solidity, and shell scripting. You write clean, documented code and help debug issues.'
  },
  'orchestrator': {
    name: 'Orchestrator',
    role: 'Coordinates all agents, manages workflows',
    systemPrompt: 'You are Gene1799 Orchestrator. You coordinate tasks between specialized AI agents, determine which agent should handle a request, and synthesize multi-agent outputs into coherent results.'
  }
};

// ─── State ──────────────────────────────────────────────────────────────────
const agentMemory = new Map();  // agentId -> conversation history
const activityLog = [];         // global activity log

function logActivity(agent, action, details) {
  const entry = {
    timestamp: new Date().toISOString(),
    agent,
    action,
    details,
  };
  activityLog.push(entry);
  if (activityLog.length > 200) activityLog.shift();
  return entry;
}

// ─── Core Functions ─────────────────────────────────────────────────────────

function getAgents() {
  return Object.entries(AGENTS).map(([id, a]) => ({
    id,
    name: a.name,
    role: a.role,
    memorySize: (agentMemory.get(id) || []).length,
  }));
}

async function callAgent(agentId, message) {
  const agent = AGENTS[agentId];
  if (!agent) {
    return { error: `Agent "${agentId}" not found`, available: Object.keys(AGENTS) };
  }

  const history = agentMemory.get(agentId) || [];
  if (history.length === 0) {
    history.push({ role: 'system', content: agent.systemPrompt });
  }
  history.push({ role: 'user', content: message });

  try {
    const response = await ollama.chat({
      model: ACTIVE_MODEL,
      messages: history,
    });
    const output = response.message.content;
    history.push({ role: 'assistant', content: output });
    agentMemory.set(agentId, history);

    logActivity(agentId, 'call', { message: message.substring(0, 100), responseLength: output.length });
    return { agent: agentId, name: agent.name, output, historyLength: history.length };
  } catch (err) {
    logActivity(agentId, 'error', { message: err.message });
    return { agent: agentId, error: err.message };
  }
}

// ─── Workflows ──────────────────────────────────────────────────────────────

async function workflowAnalysisSocial(topic, platforms = ['Twitter/X', 'Instagram']) {
  logActivity('orchestrator', 'workflow:analysis-social', { topic, platforms });

  const analysis = await callAgent('analyst-agent',
    `Analyze the topic "${topic}" for social media potential. Consider trends, audience engagement, and content angles.`
  );

  const social = await callAgent('social-agent',
    `Based on this analysis: "${analysis.output?.substring(0, 500) || topic}"\n\nCreate posts for platforms: ${platforms.join(', ')}. For each platform, write an optimized post with hashtags.`
  );

  return {
    workflow: 'analysis-social',
    topic,
    platforms,
    analysis: analysis.output || analysis.error,
    posts: social.output || social.error,
    timestamp: new Date().toISOString(),
  };
}

async function workflowTokenCampaign(focus = 'awareness') {
  logActivity('orchestrator', 'workflow:token-campaign', { focus });

  const creative = await callAgent('creative-agent',
    `Create a marketing campaign concept for Token $1799 on Zora.co (Base chain). Focus: ${focus}. Include visual concepts and messaging.`
  );

  const social = await callAgent('social-agent',
    `Turn this campaign concept into a multi-platform social media plan:\n"${creative.output?.substring(0, 500)}"`
  );

  return {
    workflow: 'token-campaign',
    focus,
    concept: creative.output || creative.error,
    socialPlan: social.output || social.error,
    timestamp: new Date().toISOString(),
  };
}

async function workflowAgentDebate(topic, rounds = 2) {
  logActivity('orchestrator', 'workflow:agent-debate', { topic, rounds });

  const debate = [];
  const agents = ['analyst-agent', 'creative-agent', 'social-agent'];

  for (let r = 0; r < rounds; r++) {
    for (const agentId of agents) {
      const context = debate.length > 0
        ? `Previous arguments:\n${debate.slice(-3).map(d => `${d.agent}: ${d.output?.substring(0, 200)}`).join('\n')}\n\nNow respond to the topic: "${topic}"`
        : `Share your perspective on: "${topic}"`;

      const result = await callAgent(agentId, context);
      debate.push({ round: r + 1, agent: AGENTS[agentId].name, agentId, output: result.output || result.error });
    }
  }

  return { workflow: 'agent-debate', topic, rounds, debate, timestamp: new Date().toISOString() };
}

// ─── Memory Management ──────────────────────────────────────────────────────

function getLog() {
  return activityLog.slice(-50).reverse();
}

function clearAll() {
  agentMemory.clear();
  activityLog.length = 0;
  return { success: true, message: 'All agent memory and logs cleared' };
}

function clearAgent(agentId) {
  agentMemory.delete(agentId);
  return { success: true, cleared: agentId };
}

// ─── Export ─────────────────────────────────────────────────────────────────

const orchestrator = {
  getAgents,
  callAgent,
  workflowAnalysisSocial,
  workflowTokenCampaign,
  workflowAgentDebate,
  getLog,
  clearAll,
  clearAgent,
};

module.exports = { orchestrator, AGENTS };
