#!/usr/bin/env node

/**
 * ╔═══════════════════════════════════════════════════════════════════════════╗
 * ║                                                                           ║
 * ║  🎯 GENE1799 UNIFIED ORCHESTRATOR AGENT - v3.0 🎯                       ║
 * ║                                                                           ║
 * ║  Master Intelligence Coordinating:                                       ║
 * ║    • 7 Local Services (Ollama, Backend, Frontend, GPU, MongoDB, etc.)   ║
 * ║    • Azure AI Agents (alMedicochelante Medical Specialist + others)     ║
 * ║    • 23 Local AI Agents (Content, Analytics, Medical, etc.)            ║
 * ║                                                                           ║
 * ║  Intelligent Routing: Local → Azure → Cloud Fallback                    ║
 * ║  Real-time Health Monitoring & Dynamic Load Balancing                   ║
 * ║                                                                           ║
 * ╚═══════════════════════════════════════════════════════════════════════════╝
 */

const express = require('express');
const EventEmitter = require('events');
const axios = require('axios');
const { v4: uuidv4 } = require('uuid');

// ═══════════════════════════════════════════════════════════════════════════
// CONFIGURATION
// ═══════════════════════════════════════════════════════════════════════════

const CONFIG = {
    LOCAL_SERVICES: {
        ollama: { port: 11434, name: 'OLLAMA (LLM Engine)', type: 'inference' },
        backend: { port: 3000, name: 'Backend API', type: 'api' },
        frontend: { port: 5173, name: 'Frontend Dashboard', type: 'ui' },
        gpu: { port: 4000, name: 'GPU Service', type: 'compute' },
        mongodb: { port: 27017, name: 'MongoDB', type: 'database' },
        agent: { port: 8000, name: 'Python AI Agent', type: 'agent' },
        orchestrator: { port: 5000, name: 'Master Orchestrator', type: 'orchestration' }
    },

    AZURE_SERVICE: {
        port: 8001,
        name: 'Azure AI Integration',
        type: 'cloud',
        endpoint: 'http://localhost:8001'
    },

    LOCAL_AGENTS: {
        'content-creator': { type: 'content', capability: 'text generation' },
        'code-analyzer': { type: 'development', capability: 'code analysis' },
        'data-analyst': { type: 'analytics', capability: 'data processing' },
        'art-curator': { type: 'creative', capability: 'visual content' },
        'medical-specialist': { type: 'medical', capability: 'medical analysis' },
        'security-auditor': { type: 'security', capability: 'security analysis' },
        'social-media-bot': { type: 'social', capability: 'social automation' },
        'nft-manager': { type: 'web3', capability: 'NFT operations' },
        'drug-discovery': { type: 'pharma', capability: 'drug research' }
        // + 14 more agents configured in GENE1799 system
    },

    AZURE_AGENTS: {
        'alMedicochelante': {
            name: 'alMedicochelante',
            type: 'medical',
            specialty: 'Medical AI specialist',
            capabilities: [
                'tumor_classification',
                'drug_targeting',
                'clinical_trials',
                'healthcare_integration'
            ],
            languages: ['Italian', 'English']
        }
    },

    SERVER_PORT: 5050,
    HEALTH_CHECK_INTERVAL: 5000, // 5 seconds
    REQUEST_TIMEOUT: 30000 // 30 seconds
};

// ═══════════════════════════════════════════════════════════════════════════
// UNIFIED ORCHESTRATOR AGENT
// ═══════════════════════════════════════════════════════════════════════════

class UnifiedOrchestrator extends EventEmitter {
    constructor(config = CONFIG) {
        super();
        this.config = config;
        this.serviceStatus = new Map();
        this.metrics = {
            totalRequests: 0,
            successfulRequests: 0,
            failedRequests: 0,
            avgResponseTime: 0,
            routingDecisions: {}
        };

        this.initializeServiceStatus();
        this.startHealthMonitoring();
    }

    /**
     * Initialize tracking for all services
     */
    initializeServiceStatus() {
        // Local services
        for (const [key, service] of Object.entries(this.config.LOCAL_SERVICES)) {
            this.serviceStatus.set(key, {
                name: service.name,
                port: service.port,
                type: service.type,
                status: 'unknown',
                lastCheck: null,
                responseTime: 0,
                requestCount: 0
            });
        }

        // Azure service
        this.serviceStatus.set('azure', {
            name: this.config.AZURE_SERVICE.name,
            port: this.config.AZURE_SERVICE.port,
            type: this.config.AZURE_SERVICE.type,
            status: 'unknown',
            lastCheck: null,
            responseTime: 0,
            requestCount: 0
        });
    }

    /**
     * Start continuous health monitoring of all services
     */
    startHealthMonitoring() {
        setInterval(() => this.checkAllServicesHealth(), this.config.HEALTH_CHECK_INTERVAL);

        // Initial check
        this.checkAllServicesHealth();
    }

    /**
     * Check health of all services
     */
    async checkAllServicesHealth() {
        const checks = [];

        // Check local services
        for (const [key, service] of Object.entries(this.config.LOCAL_SERVICES)) {
            checks.push(this.checkServiceHealth(key, `http://localhost:${service.port}`));
        }

        // Check Azure service
        checks.push(this.checkServiceHealth('azure', this.config.AZURE_SERVICE.endpoint));

        await Promise.all(checks);
    }

    /**
     * Check health of a single service
     */
    async checkServiceHealth(serviceKey, endpoint) {
        try {
            const startTime = Date.now();
            const response = await axios.get(`${endpoint}/health`, {
                timeout: 3000
            });
            const responseTime = Date.now() - startTime;

            const status = response.status === 200 ? 'healthy' : 'degraded';

            this.serviceStatus.set(serviceKey, {
                ...this.serviceStatus.get(serviceKey),
                status,
                lastCheck: new Date(),
                responseTime
            });

            this.emit('serviceHealthUpdate', {
                service: serviceKey,
                status,
                responseTime
            });
        } catch (error) {
            this.serviceStatus.set(serviceKey, {
                ...this.serviceStatus.get(serviceKey),
                status: 'unhealthy',
                lastCheck: new Date(),
                error: error.message
            });

            this.emit('serviceHealthUpdate', {
                service: serviceKey,
                status: 'unhealthy',
                error: error.message
            });
        }
    }

    /**
     * Determine best provider for a query based on type and availability
     */
    async determineBestProvider(query) {
        const { type = 'general', domain = 'general', requiresAzure = false } = query;

        // Medical queries preferentially route to Azure alMedicochelante
        if (domain === 'medical' || requiresAzure) {
            if (this.serviceStatus.get('azure')?.status === 'healthy') {
                return { provider: 'azure', agent: 'alMedicochelante' };
            }
        }

        // Check local agent capability first
        if (type !== 'general') {
            const localAgent = Object.entries(this.config.LOCAL_AGENTS).find(
                ([_, agent]) => agent.type === type
            );

            if (localAgent && this.serviceStatus.get('agent')?.status === 'healthy') {
                return { provider: 'local', agent: localAgent[0] };
            }
        }

        // Fall back to local Ollama if available
        if (this.serviceStatus.get('ollama')?.status === 'healthy') {
            return { provider: 'ollama', model: 'mistral' };
        }

        // Last resort: Azure if available
        if (this.serviceStatus.get('azure')?.status === 'healthy') {
            return { provider: 'azure', agent: 'alMedicochelante' };
        }

        throw new Error('No available AI providers');
    }

    /**
     * Route query to appropriate provider
     */
    async routeQuery(query) {
        const requestId = uuidv4();
        const startTime = Date.now();

        this.metrics.totalRequests++;

        try {
            const provider = await this.determineBestProvider(query);

            this.metrics.routingDecisions[provider.provider] =
                (this.metrics.routingDecisions[provider.provider] || 0) + 1;

            let result;

            switch (provider.provider) {
                case 'azure':
                    result = await this.queryAzureAgent(query, provider.agent);
                    break;

                case 'local':
                    result = await this.queryLocalAgent(query, provider.agent);
                    break;

                case 'ollama':
                    result = await this.queryOllama(query, provider.model);
                    break;

                default:
                    throw new Error(`Unknown provider: ${provider.provider}`);
            }

            const responseTime = Date.now() - startTime;
            this.metrics.successfulRequests++;
            this.metrics.avgResponseTime = (this.metrics.avgResponseTime + responseTime) / 2;

            return {
                requestId,
                success: true,
                provider: provider.provider,
                agent: provider.agent || provider.model,
                result,
                responseTime,
                timestamp: new Date().toISOString()
            };

        } catch (error) {
            this.metrics.failedRequests++;

            return {
                requestId,
                success: false,
                error: error.message,
                responseTime: Date.now() - startTime,
                timestamp: new Date().toISOString()
            };
        }
    }

    /**
     * Query Azure AI Agent
     */
    async queryAzureAgent(query, agentName = 'alMedicochelante') {
        try {
            const response = await axios.post(
                `${this.config.AZURE_SERVICE.endpoint}/query`,
                {
                    agent_name: agentName,
                    message: query.message || query.text || query
                },
                { timeout: this.config.REQUEST_TIMEOUT }
            );

            return response.data;
        } catch (error) {
            throw new Error(`Azure Agent Error: ${error.message}`);
        }
    }

    /**
     * Query Local AI Agent
     */
    async queryLocalAgent(query, agentName) {
        try {
            const response = await axios.post(
                `http://localhost:${this.config.LOCAL_SERVICES.agent.port}/dispatch`,
                {
                    agent: agentName,
                    message: query.message || query.text || query,
                    metadata: query.metadata || {}
                },
                { timeout: this.config.REQUEST_TIMEOUT }
            );

            return response.data;
        } catch (error) {
            throw new Error(`Local Agent Error: ${error.message}`);
        }
    }

    /**
     * Query Local Ollama LLM
     */
    async queryOllama(query, model = 'mistral') {
        try {
            const response = await axios.post(
                `http://localhost:${this.config.LOCAL_SERVICES.ollama.port}/api/generate`,
                {
                    model,
                    prompt: query.message || query.text || query,
                    stream: false
                },
                { timeout: this.config.REQUEST_TIMEOUT }
            );

            return {
                text: response.data.response,
                model,
                source: 'ollama'
            };
        } catch (error) {
            throw new Error(`Ollama Error: ${error.message}`);
        }
    }

    /**
     * Multi-source query aggregation
     */
    async aggregateResults(query, providers = ['azure', 'local', 'ollama']) {
        const results = [];

        for (const provider of providers) {
            try {
                const result = await this.routeQuery({ ...query, provider });
                results.push(result);
            } catch (error) {
                // Continue with next provider
                results.push({ provider, error: error.message });
            }
        }

        return {
            query,
            results,
            aggregatedAt: new Date().toISOString(),
            totalProviders: providers.length,
            successfulProviders: results.filter(r => r.success).length
        };
    }

    /**
     * Get orchestrator status
     */
    getStatus() {
        const serviceStatuses = {};

        for (const [key, status] of this.serviceStatus) {
            serviceStatuses[key] = {
                name: status.name,
                status: status.status,
                responseTime: status.responseTime,
                lastCheck: status.lastCheck
            };
        }

        return {
            timestamp: new Date().toISOString(),
            services: serviceStatuses,
            metrics: this.metrics,
            localAgents: Object.keys(this.config.LOCAL_AGENTS),
            azureAgents: Object.keys(this.config.AZURE_AGENTS),
            totalAgents: Object.keys(this.config.LOCAL_AGENTS).length +
                        Object.keys(this.config.AZURE_AGENTS).length
        };
    }

    /**
     * Get available agents and their capabilities
     */
    getAvailableAgents() {
        return {
            local: Object.entries(this.config.LOCAL_AGENTS).map(([key, agent]) => ({
                id: key,
                ...agent,
                status: this.serviceStatus.get('agent')?.status || 'unknown'
            })),
            azure: Object.entries(this.config.AZURE_AGENTS).map(([key, agent]) => ({
                id: key,
                ...agent,
                status: this.serviceStatus.get('azure')?.status || 'unknown'
            }))
        };
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// EXPRESS API SERVER
// ═══════════════════════════════════════════════════════════════════════════

const app = express();
const orchestrator = new UnifiedOrchestrator(CONFIG);

app.use(express.json());

// ───────────────────────────────────────────────────────────────────────────
// HEALTH & STATUS ENDPOINTS
// ───────────────────────────────────────────────────────────────────────────

app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        service: 'GENE1799 Unified Orchestrator',
        version: '3.0',
        timestamp: new Date().toISOString()
    });
});

app.get('/status', (req, res) => {
    res.json(orchestrator.getStatus());
});

app.get('/agents', (req, res) => {
    res.json(orchestrator.getAvailableAgents());
});

// ───────────────────────────────────────────────────────────────────────────
// QUERY ENDPOINTS
// ───────────────────────────────────────────────────────────────────────────

/**
 * POST /query - Route query to best available provider
 * Body: { message: string, domain?: 'medical' | 'general' | ..., requiresAzure?: boolean }
 */
app.post('/query', async (req, res) => {
    try {
        const query = req.body;
        const result = await orchestrator.routeQuery(query);

        res.json(result);
    } catch (error) {
        res.status(500).json({
            error: error.message,
            timestamp: new Date().toISOString()
        });
    }
});

/**
 * POST /query/aggregate - Get results from multiple providers
 * Body: { message: string, providers?: string[] }
 */
app.post('/query/aggregate', async (req, res) => {
    try {
        const { message, providers } = req.body;
        const result = await orchestrator.aggregateResults(
            { message },
            providers
        );

        res.json(result);
    } catch (error) {
        res.status(500).json({
            error: error.message,
            timestamp: new Date().toISOString()
        });
    }
});

/**
 * POST /query/medical - Direct routing to Azure medical agent
 */
app.post('/query/medical', async (req, res) => {
    try {
        const { message } = req.body;
        const result = await orchestrator.routeQuery({
            message,
            domain: 'medical',
            requiresAzure: true
        });

        res.json(result);
    } catch (error) {
        res.status(500).json({
            error: error.message,
            timestamp: new Date().toISOString()
        });
    }
});

/**
 * POST /query/agent/{agentName} - Query specific agent
 */
app.post('/query/agent/:agentName', async (req, res) => {
    try {
        const { agentName } = req.params;
        const { message } = req.body;

        // Check if it's an Azure agent
        if (CONFIG.AZURE_AGENTS[agentName]) {
            const result = await orchestrator.queryAzureAgent(message, agentName);
            res.json({ success: true, agent: agentName, result });
        }
        // Otherwise try local agent
        else {
            const result = await orchestrator.queryLocalAgent(message, agentName);
            res.json({ success: true, agent: agentName, result });
        }
    } catch (error) {
        res.status(500).json({
            error: error.message,
            timestamp: new Date().toISOString()
        });
    }
});

// ───────────────────────────────────────────────────────────────────────────
// MONITORING ENDPOINTS
// ───────────────────────────────────────────────────────────────────────────

app.get('/services', (req, res) => {
    const services = {};

    for (const [key, status] of orchestrator.serviceStatus) {
        services[key] = {
            name: status.name,
            port: status.port,
            type: status.type,
            status: status.status,
            responseTime: `${status.responseTime}ms`,
            lastCheck: status.lastCheck
        };
    }

    res.json(services);
});

app.get('/metrics', (req, res) => {
    res.json(orchestrator.metrics);
});

app.get('/config', (req, res) => {
    res.json({
        localServices: CONFIG.LOCAL_SERVICES,
        azureService: CONFIG.AZURE_SERVICE,
        localAgentsCount: Object.keys(CONFIG.LOCAL_AGENTS).length,
        azureAgentsCount: Object.keys(CONFIG.AZURE_AGENTS).length
    });
});

// ───────────────────────────────────────────────────────────────────────────
// API DOCUMENTATION
// ───────────────────────────────────────────────────────────────────────────

app.get('/api/docs', (req, res) => {
    res.json({
        service: 'GENE1799 Unified Orchestrator v3.0',
        description: 'Master intelligence coordinating local and Azure AI services',
        port: CONFIG.SERVER_PORT,
        endpoints: {
            health: 'GET /health - Health check',
            status: 'GET /status - Complete orchestrator status',
            agents: 'GET /agents - List available agents',
            services: 'GET /services - List all services',
            metrics: 'GET /metrics - Request metrics',
            config: 'GET /config - Configuration info',

            query: 'POST /query - Route query to best provider',
            queryAggregate: 'POST /query/aggregate - Multi-provider results',
            queryMedical: 'POST /query/medical - Route to Azure medical agent',
            querySpecific: 'POST /query/agent/:agentName - Query specific agent'
        },
        examples: {
            simpleQuery: {
                method: 'POST',
                url: '/query',
                body: { message: 'What is the meaning of life?' }
            },
            medicalQuery: {
                method: 'POST',
                url: '/query/medical',
                body: { message: 'Analyze tumor classification for melanoma' }
            },
            specificAgent: {
                method: 'POST',
                url: '/query/agent/alMedicochelante',
                body: { message: 'Drug targeting recommendation' }
            }
        }
    });
});

// ═══════════════════════════════════════════════════════════════════════════
// STARTUP
// ═══════════════════════════════════════════════════════════════════════════

app.listen(CONFIG.SERVER_PORT, () => {
    console.log(`
╔═══════════════════════════════════════════════════════════════════════════╗
║                                                                           ║
║  🎯 GENE1799 UNIFIED ORCHESTRATOR v3.0 - STARTED 🎯                    ║
║                                                                           ║
║  Coordinating:                                                            ║
║    • 7 Local Services (Ollama, Backend, Frontend, GPU, MongoDB, etc.)   ║
║    • Azure AI Agents (alMedicochelante Medical Specialist)              ║
║    • 23+ Local AI Agents                                                 ║
║                                                                           ║
║  Listening on: http://localhost:${CONFIG.SERVER_PORT}                        ║
║  API Docs: http://localhost:${CONFIG.SERVER_PORT}/api/docs                 ║
║                                                                           ║
║  Real-time Health Monitoring: ACTIVE                                     ║
║  Intelligent Query Routing: ACTIVE                                       ║
║  Multi-Provider Aggregation: ACTIVE                                      ║
║                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════╝
    `);

    // Initial service health checks
    orchestrator.checkAllServicesHealth().then(() => {
        console.log('✅ Initial health check complete\n');
    });
});

// Handle graceful shutdown
process.on('SIGINT', () => {
    console.log('\n🏥 Orchestrator shutting down gracefully...');
    process.exit(0);
});

module.exports = UnifiedOrchestrator;
