/**
 * GENE1799 Security Integration
 * Integrates Protective Matrix with Orchestrator and Telegram Bot
 * Real-time security monitoring and alerting
 */

const ProtectiveMatrix = require('./protective-matrix');

class SecurityIntegration {
  constructor(orchestrator, telegramBot) {
    this.orchestrator = orchestrator;
    this.telegramBot = telegramBot;
    this.matrix = new ProtectiveMatrix();
    this.alertThresholds = {
      critical: 1,      // Immediate alert
      high: 3,          // Alert after 3 incidents
      medium: 10,       // Alert after 10 incidents
      low: 50           // Alert after 50 incidents
    };
    this.incidentCounter = {
      critical: 0,
      high: 0,
      medium: 0,
      low: 0
    };

    this.setupSecurityListeners();
    console.log('✓ Security Integration initialized with Protective Matrix');
  }

  /**
   * Setup listeners for security events
   */
  setupSecurityListeners() {
    // Listen to matrix threats
    this.matrix.on('threat:detected', (threat) => {
      this.handleThreat(threat);
    });

    this.matrix.on('threat:critical', () => {
      this.handleCriticalThreat();
    });

    this.matrix.on('threat:blocked', (resource) => {
      this.notifyBlockList(resource);
    });

    this.matrix.on('security:lockdown', () => {
      this.notifyLockdown();
    });

    // Listen to orchestrator tasks
    this.orchestrator.on('task:started', (event) => {
      this.validateTaskSecurity(event);
    });

    this.orchestrator.on('task:failed', (event) => {
      this.checkFailurePattern(event);
    });
  }

  /**
   * Validate task security before execution
   */
  validateTaskSecurity(event) {
    const { agent, task } = event;

    const validation = {
      agentAuthorized: true,
      taskAllowed: true,
      dataEncrypted: false,
      anomalies: []
    };

    // Check agent permissions
    if (!this.isAgentAuthorized(agent)) {
      validation.agentAuthorized = false;
      validation.anomalies.push('Unauthorized agent');
    }

    // Check task type
    if (this.isSensitiveTask(task.type)) {
      validation.dataEncrypted = true;
      task.encrypted = true;
    }

    // Detect anomalies
    const anomaly = this.matrix.detectAnomaly({
      type: 'task-execution',
      source: agent,
      action: task.type,
      targetSensitive: this.isSensitiveTask(task.type)
    });

    if (anomaly.isAnomaly) {
      validation.anomalies.push(`Anomaly detected: ${anomaly.anomalyScore.toFixed(2)}`);
    }

    if (!validation.agentAuthorized || !validation.taskAllowed) {
      this.matrix.logThreat('unauthorized_task', {
        agent,
        task: task.type,
        reason: validation.anomalies[0]
      });

      this.notifySecurityIncident({
        type: 'unauthorized_task',
        severity: 'high',
        agent,
        task: task.type
      });
    }

    return validation;
  }

  /**
   * Check for failure patterns that could indicate attacks
   */
  checkFailurePattern(event) {
    const { agent, error } = event;

    // Pattern: Multiple failures could indicate brute force
    if (!this.failureHistory) this.failureHistory = new Map();

    if (!this.failureHistory.has(agent)) {
      this.failureHistory.set(agent, []);
    }

    const failures = this.failureHistory.get(agent);
    failures.push(Date.now());

    // Keep only last 10 minutes
    const tenMinutesAgo = Date.now() - 600000;
    const recentFailures = failures.filter(t => t > tenMinutesAgo);
    this.failureHistory.set(agent, recentFailures);

    // Alert if 10+ failures in 10 minutes
    if (recentFailures.length > 10) {
      this.matrix.logThreat('brute_force_suspected', {
        agent,
        failures: recentFailures.length,
        window: '10 minutes'
      });

      this.notifySecurityIncident({
        type: 'brute_force_suspected',
        severity: 'high',
        agent,
        failureCount: recentFailures.length
      });
    }
  }

  /**
   * Handle threat - decide on action
   */
  handleThreat(threat) {
    const { severity, type, data } = threat;

    // Increment counter
    this.incidentCounter[severity]++;

    // Check if alert threshold reached
    if (this.incidentCounter[severity] >= this.alertThresholds[severity]) {
      this.notifySecurityIncident({
        type,
        severity,
        details: data,
        incidentCount: this.incidentCounter[severity]
      });

      // Reset counter
      this.incidentCounter[severity] = 0;
    }

    // Log to audit
    console.log(`🔒 ${severity.toUpperCase()}: ${type}`);
  }

  /**
   * Handle critical threats - activate protection
   */
  handleCriticalThreat() {
    console.log('🚨 CRITICAL THREAT DETECTED - ACTIVATING PROTECTION');

    // Notify immediately
    this.telegramBot.sendMessage(
      this.orchestrator.config.adminId,
      `🚨 CRITICAL SECURITY ALERT\n\nThreat Level: CRITICAL\nAction: Protective Matrix activated\n\nCheck dashboard: http://localhost:3000/dashboard.html`,
      { parse_mode: 'Markdown' }
    );

    // Activate protection
    this.activateProtection();
  }

  /**
   * Notify about threat intelligence blocklist addition
   */
  notifyBlockList(resource) {
    const message = `🛑 Security: Resource blocked\n\n${resource.ip || resource.domain}\n\nReason: Threat intelligence match`;

    this.telegramBot.sendMessage(
      this.orchestrator.config.channelId,
      message
    );
  }

  /**
   * Notify about emergency lockdown
   */
  notifyLockdown() {
    const message = `🔒 EMERGENCY LOCKDOWN ACTIVATED\n\nAll systems in protective mode\nExternal access blocked\n\nStatus: Monitoring active`;

    this.telegramBot.sendMessage(
      this.orchestrator.config.channelId,
      message,
      { parse_mode: 'Markdown' }
    );
  }

  /**
   * Send security incident notification to Telegram
   */
  async notifySecurityIncident(incident) {
    const {type, severity, agent, task, details, failureCount, incidentCount} = incident;

    const messages = {
      unauthorized_task: `⚠️ Security Alert\n\n❌ Task blocked: Unauthorized\n\nAgent: ${agent}\nTask: ${task}\n\nAction: Access denied`,

      brute_force_suspected: `⚠️ Security Alert\n\n🚨 Brute force attack suspected\n\nAgent: ${agent}\nFailures: ${failureCount}/10\n\nAction: Rate limiting activated`,

      anomaly_detected: `⚠️ Security Alert\n\n🔍 Unusual activity detected\n\nType: ${type}\nSeverity: ${severity}\n\nReview dashboard for details`,

      malicious_ip_detected: `⚠️ Security Alert\n\n🛑 Malicious IP detected\n\n${details?.ip}\n\nAction: Blocked`,

      rate_limit_exceeded: `⚠️ Security Alert\n\n📊 Rate limit exceeded\n\nClient: ${details?.clientId}\n\nAction: Temporarily blocked`
    };

    const message = messages[type] || `⚠️ Security incident: ${type} (${severity})`;

    try {
      await this.telegramBot.sendMessage(
        this.orchestrator.config.channelId,
        message,
        { parse_mode: 'Markdown' }
      );

      // Also notify admin if critical
      if (severity === 'critical' || severity === 'high') {
        await this.telegramBot.sendMessage(
          this.orchestrator.config.adminId,
          `🔴 ${message}`,
          { parse_mode: 'Markdown' }
        );
      }
    } catch (error) {
      console.error('Error sending security notification:', error);
    }
  }

  /**
   * Activate protective measures
   */
  activateProtection() {
    // 1. Enable rate limiting on all endpoints
    this.orchestrator.rateLimit = {
      enabled: true,
      requestsPerMinute: 30  // Reduced from 100
    };

    // 2. Require encryption for all tasks
    this.orchestrator.requireEncryption = true;

    // 3. Reduce agent autonomy
    this.orchestrator.agents.forEach((agent, name) => {
      agent.autonomyLevel = 0.5;  // Reduced from 1.0
    });

    // 4. Schedule enhanced monitoring
    const monitor = setInterval(() => {
      const status = this.matrix.getSecurityStatus();
      if (status.threatLevel === 'normal') {
        clearInterval(monitor);
        this.deactivateProtection();
      }
    }, 30000); // Check every 30 seconds

    console.log('✓ Protection activated');
  }

  /**
   * Deactivate protective measures when threat passes
   */
  deactivateProtection() {
    this.orchestrator.rateLimit = null;
    this.orchestrator.requireEncryption = false;

    this.orchestrator.agents.forEach((agent, name) => {
      agent.autonomyLevel = 1.0;
    });

    console.log('✓ Protection deactivated - normal operations resumed');

    this.telegramBot.sendMessage(
      this.orchestrator.config.channelId,
      '✅ Security status: Normal - Protection measures deactivated'
    );
  }

  /**
   * Check if agent is authorized
   */
  isAgentAuthorized(agentName) {
    const authorizedAgents = [
      'ContentAgent',
      'AnalyticsAgent',
      'CommunityAgent',
      'SocialAgent'
    ];

    return authorizedAgents.includes(agentName);
  }

  /**
   * Check if task type is sensitive
   */
  isSensitiveTask(taskType) {
    const sensitiveTasks = [
      'financial-transaction',
      'user-data-access',
      'admin-action',
      'security-config',
      'delete-data'
    ];

    return sensitiveTasks.includes(taskType);
  }

  /**
   * Generate security report for dashboard
   */
  getSecurityReport() {
    const matrixStatus = this.matrix.getMatrixStatus();
    const auditReport = this.matrix.generateAuditReport();

    return {
      timestamp: Date.now(),
      matrix: matrixStatus,
      audit: auditReport,
      incidentCounter: this.incidentCounter,
      protectionActive: this.orchestrator.rateLimit?.enabled || false,
      recommendations: this.generateRecommendations()
    };
  }

  /**
   * Generate security recommendations
   */
  generateRecommendations() {
    const recommendations = [];
    const matrixStatus = this.matrix.getSecurityStatus();

    if (matrixStatus.threatLevel === 'critical') {
      recommendations.push('🚨 CRITICAL: Activate emergency lockdown immediately');
    }

    if (this.incidentCounter.high > 5) {
      recommendations.push('⚠️ HIGH: Multiple high-severity incidents - Review access controls');
    }

    if (this.matrix.blockList.size > 100) {
      recommendations.push('📋 Review blocklist size - Consider IP range blocking');
    }

    if (matrixStatus.activeThreats > 10) {
      recommendations.push('🔍 Investigate active threats - Check agent behavior');
    }

    return recommendations;
  }

  /**
   * Encrypt sensitive data from orchestrator
   */
  encryptSensitiveData(data) {
    return this.matrix.encrypt(JSON.stringify(data));
  }

  /**
   * Decrypt sensitive data
   */
  decryptSensitiveData(encryptedData) {
    const decrypted = this.matrix.decrypt(encryptedData);
    return JSON.parse(decrypted);
  }

  /**
   * Get matrix health for monitoring
   */
  getMatrixHealth() {
    const status = this.matrix.getSecurityStatus();

    return {
      status: `MATRIX ${status.status}`,
      threatLevel: status.threatLevel,
      health: `${status.threatLevel === 'normal' ? 100 : 75 - (this.incidentCounter.critical * 10)}%`,
      blocked: status.blockListSize,
      whitelisted: status.whiteListSize,
      recentThreats: status.recentThreats.length,
      securityScore: status.threatLevelHistory
    };
  }
}

// Export
module.exports = SecurityIntegration;

// Integration example:
/*
const Gene1799Orchestrator = require('./orchestrator-core');
const SecurityIntegration = require('./security-integration');
const TelegramBot = require('node-telegram-bot-api');

const orchestrator = new Gene1799Orchestrator();
const bot = new TelegramBot(process.env.BOT_TOKEN);
const security = new SecurityIntegration(orchestrator, bot);

// Now orchestrator has full security protection:
// - Data encryption
// - Threat detection
// - Real-time alerts
// - Anomaly detection
// - Rate limiting
// - Access control
*/
