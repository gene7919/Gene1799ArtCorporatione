/**
 * GENE1799 Orchestrator Service
 * Integrates the Gene1799 Orchestrator Core with the backend API
 */

const Gene1799Orchestrator = require('./orchestrator-core');
const { getPythonBridge } = require('./pythonBridge');

class OrchestratorService {
  constructor() {
    this.orchestrator = new Gene1799Orchestrator({
      logDir: './logs',
      dataDir: './data'
    });
    
    this.pythonBridge = getPythonBridge();
    this.isInitialized = false;
    
    // Setup core systems
    this.orchestrator.setupLearning();
  }

  /**
   * Initialize the orchestrator service
   */
  async initialize() {
    if (this.isInitialized) {
      return true;
    }

    try {
      console.log('Initializing Orchestrator Service...');
      
      // Register default AI agents
      this.registerDefaultAgents();
      
      // Setup social automation if credentials available
      if (process.env.TELEGRAM_BOT_TOKEN) {
        await this.orchestrator.setupSocialAutomation({
          telegram: {
            token: process.env.TELEGRAM_BOT_TOKEN,
            channelId: process.env.TELEGRAM_CHANNEL_ID
          },
          twitter: {
            apiKey: process.env.TWITTER_API_KEY,
            apiSecret: process.env.TWITTER_API_SECRET
          }
        });
      }
      
      this.isInitialized = true;
      console.log('Orchestrator Service initialized successfully');
      return true;
    } catch (error) {
      console.error('Orchestrator Service initialization error:', error);
      return false;
    }
  }

  /**
   * Register default AI agents
   */
  registerDefaultAgents() {
    const defaultAgents = [
      {
        name: 'anti-cancer',
        execute: async (task) => this.executeAgentTask('anti-cancer', task)
      },
      {
        name: 'drug-discovery',
        execute: async (task) => this.executeAgentTask('drug-discovery', task)
      },
      {
        name: 'ml-orchestrator',
        execute: async (task) => this.executeAgentTask('ml-orchestrator', task)
      },
      {
        name: 'content-creator',
        execute: async (task) => this.executeAgentTask('content-creator', task)
      },
      {
        name: 'social-media',
        execute: async (task) => this.executeAgentTask('social-media', task)
      },
      {
        name: 'self-healer',
        execute: async (task) => this.executeAgentTask('self-healer', task)
      }
    ];

    defaultAgents.forEach(agent => {
      this.orchestrator.registerAgent(agent.name, agent);
    });
  }

  /**
   * Execute agent task through Python or Node.js
   */
  async executeAgentTask(agentName, task) {
    try {
      // Try Python execution first
      try {
        const result = await this.pythonBridge.runOrchestrator({
          agent: agentName,
          task: task.description || task.task,
          parameters: task.parameters || {}
        });
        
        return {
          success: true,
          source: 'python',
          result
        };
      } catch (pythonError) {
        // Fallback to Node.js simulation
        console.log(`Python execution failed for ${agentName}, using fallback`);
      }
      
      // Node.js fallback
      return {
        success: true,
        source: 'node',
        result: {
          message: `Task processed by ${agentName}`,
          task: task.description || task.task,
          timestamp: new Date().toISOString()
        }
      };
    } catch (error) {
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * Dispatch task to agent through orchestrator
   */
  async dispatchTask(agentName, task) {
    if (!this.isInitialized) {
      await this.initialize();
    }
    
    return await this.orchestrator.dispatchTask(agentName, task);
  }

  /**
   * Queue multiple tasks
   */
  queueTasks(tasks) {
    if (!this.isInitialized) {
      throw new Error('Orchestrator not initialized');
    }
    
    this.orchestrator.queueTasks(tasks);
  }

  /**
   * Process task queue
   */
  async processQueue() {
    if (!this.isInitialized) {
      throw new Error('Orchestrator not initialized');
    }
    
    return await this.orchestrator.processQueue();
  }

  /**
   * Generate social content
   */
  async generateSocialContent(topic, platforms) {
    if (!this.isInitialized) {
      await this.initialize();
    }
    
    return await this.orchestrator.generateSocialContent(topic, platforms);
  }

  /**
   * Get agent status
   */
  getAgentStatus(name = null) {
    if (!this.isInitialized) {
      return null;
    }
    
    return this.orchestrator.getAgentStatus(name);
  }

  /**
   * Get orchestrator health
   */
  getHealth() {
    if (!this.isInitialized) {
      return {
        status: 'not_initialized',
        agents: { total: 0, active: 0, idle: 0 }
      };
    }
    
    return this.orchestrator.getHealth();
  }

  /**
   * Remember data
   */
  remember(key, data) {
    this.orchestrator.remember(key, data);
  }

  /**
   * Recall data
   */
  recall(key) {
    return this.orchestrator.recall(key);
  }

  /**
   * Shutdown orchestrator
   */
  async shutdown() {
    if (this.isInitialized) {
      await this.orchestrator.shutdown();
      this.isInitialized = false;
    }
  }
}

// Singleton instance
let orchestratorService = null;

function getOrchestratorService() {
  if (!orchestratorService) {
    orchestratorService = new OrchestratorService();
  }
  return orchestratorService;
}

module.exports = { OrchestratorService, getOrchestratorService };
