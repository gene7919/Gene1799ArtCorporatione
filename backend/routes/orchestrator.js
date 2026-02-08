/**
 * GENE1799 Orchestrator Routes
 * Exposes orchestrator core functionality via API
 */

const express = require('express');
const router = express.Router();
const { getOrchestratorService } = require('../services/orchestratorService');

// Get orchestrator service
const orchestratorService = getOrchestratorService();

// GET /api/orchestrator/health - Get orchestrator health
router.get('/health', async (req, res) => {
  try {
    const health = orchestratorService.getHealth();
    res.json({
      success: true,
      health,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Orchestrator health check error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: error.message
    });
  }
});

// GET /api/orchestrator/agents - Get all agent statuses
router.get('/agents', (req, res) => {
  try {
    const statuses = orchestratorService.getAgentStatus();
    res.json({
      success: true,
      agents: statuses,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Get agent statuses error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: error.message
    });
  }
});

// GET /api/orchestrator/agents/:name - Get specific agent status
router.get('/agents/:name', (req, res) => {
  try {
    const { name } = req.params;
    const status = orchestratorService.getAgentStatus(name);
    
    if (!status) {
      return res.status(404).json({
        success: false,
        error: 'Agent not found',
        agentName: name
      });
    }
    
    res.json({
      success: true,
      agent: name,
      status,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Get agent status error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: error.message
    });
  }
});

// POST /api/orchestrator/tasks/dispatch - Dispatch a task to an agent
router.post('/tasks/dispatch', async (req, res) => {
  try {
    const { agent, task } = req.body;
    
    if (!agent || !task) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields: agent and task'
      });
    }
    
    const result = await orchestratorService.dispatchTask(agent, task);
    
    res.json({
      success: result.success,
      agent,
      task,
      result,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Dispatch task error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: error.message
    });
  }
});

// POST /api/orchestrator/tasks/queue - Queue multiple tasks
router.post('/tasks/queue', (req, res) => {
  try {
    const { tasks } = req.body;
    
    if (!tasks || !Array.isArray(tasks)) {
      return res.status(400).json({
        success: false,
        error: 'Tasks must be an array'
      });
    }
    
    orchestratorService.queueTasks(tasks);
    
    res.json({
      success: true,
      queued: tasks.length,
      message: `${tasks.length} tasks queued successfully`,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Queue tasks error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: error.message
    });
  }
});

// POST /api/orchestrator/tasks/process - Process task queue
router.post('/tasks/process', async (req, res) => {
  try {
    await orchestratorService.processQueue();
    
    res.json({
      success: true,
      message: 'Task queue processed',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Process queue error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: error.message
    });
  }
});

// POST /api/orchestrator/social/generate - Generate social content
router.post('/social/generate', async (req, res) => {
  try {
    const { topic, platforms } = req.body;
    
    if (!topic) {
      return res.status(400).json({
        success: false,
        error: 'Topic is required'
      });
    }
    
    const posts = await orchestratorService.generateSocialContent(
      topic,
      platforms || ['twitter', 'instagram', 'telegram']
    );
    
    res.json({
      success: true,
      topic,
      posts,
      count: posts.length,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Generate social content error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: error.message
    });
  }
});

// POST /api/orchestrator/memory/remember - Store data in memory
router.post('/memory/remember', (req, res) => {
  try {
    const { key, data } = req.body;
    
    if (!key || !data) {
      return res.status(400).json({
        success: false,
        error: 'Key and data are required'
      });
    }
    
    orchestratorService.remember(key, data);
    
    res.json({
      success: true,
      message: 'Data stored in memory',
      key,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Remember data error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: error.message
    });
  }
});

// GET /api/orchestrator/memory/recall/:key - Recall data from memory
router.get('/memory/recall/:key', (req, res) => {
  try {
    const { key } = req.params;
    const data = orchestratorService.recall(key);
    
    if (!data) {
      return res.status(404).json({
        success: false,
        error: 'Data not found or expired',
        key
      });
    }
    
    res.json({
      success: true,
      key,
      data,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Recall data error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: error.message
    });
  }
});

module.exports = router;
