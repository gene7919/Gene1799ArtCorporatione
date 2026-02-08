#!/usr/bin/env node

/**
 * GENE1799 Render Deployment Automation
 * Deploy Telegram Bot to Render with auto-configuration
 *
 * Usage:
 *   npm run deploy:render -- --token YOUR_RENDER_TOKEN
 *   npm run deploy:render -- --interactive
 */

const https = require('https');
const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');
const readline = require('readline');

// ============================================================================
// LOGGER
// ============================================================================

class Logger {
  static success(msg) {
    console.log(`\x1b[32m✓\x1b[0m ${msg}`);
  }

  static error(msg) {
    console.log(`\x1b[31m✗\x1b[0m ${msg}`);
  }

  static warning(msg) {
    console.log(`\x1b[33m⚠\x1b[0m ${msg}`);
  }

  static info(msg) {
    console.log(`\x1b[36mℹ\x1b[0m ${msg}`);
  }

  static section(title) {
    console.log(`\n\x1b[35m${'='.repeat(70)}\x1b[0m`);
    console.log(`\x1b[35m${title}\x1b[0m`);
    console.log(`\x1b[35m${'='.repeat(70)}\x1b[0m\n`);
  }
}

// ============================================================================
// PROMPT
// ============================================================================

function prompt(question) {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });

  return new Promise((resolve) => {
    rl.question(question, (answer) => {
      rl.close();
      resolve(answer);
    });
  });
}

// ============================================================================
// RENDER API
// ============================================================================

class RenderDeployer {
  constructor(apiKey) {
    this.apiKey = apiKey;
    this.baseUrl = 'api.render.com';
  }

  makeRequest(method, path, data = null) {
    return new Promise((resolve, reject) => {
      const options = {
        hostname: this.baseUrl,
        path: `/v1${path}`,
        method: method,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${this.apiKey}`
        }
      };

      const req = https.request(options, (res) => {
        let body = '';
        res.on('data', chunk => body += chunk);
        res.on('end', () => {
          try {
            const parsed = JSON.parse(body);
            resolve({ status: res.statusCode, data: parsed });
          } catch {
            resolve({ status: res.statusCode, data: body });
          }
        });
      });

      req.on('error', reject);

      if (data) {
        req.write(JSON.stringify(data));
      }

      req.end();
    });
  }

  async getServices() {
    Logger.info('Fetching services from Render...');
    const result = await this.makeRequest('GET', '/services');

    if (result.status === 200) {
      Logger.success(`Found ${result.data.services?.length || 0} services`);
      return result.data.services || [];
    } else {
      throw new Error(`API error: ${result.status}`);
    }
  }

  async findBotService(services) {
    const botService = services.find(
      s => s.name === 'gene1799-telegram-bot' || s.name?.includes('telegram-bot')
    );

    if (!botService) {
      Logger.warning('Telegram Bot service not found on Render');
      Logger.info('You need to create it manually:');
      Logger.info(' 1. Go to https://dashboard.render.com');
      Logger.info(' 2. Click "New > Background Worker"');
      Logger.info(' 3. Configure as described in SETUP_GUIDE.md');
      return null;
    }

    Logger.success(`Found bot service: ${botService.name}`);
    return botService;
  }

  async deployService(serviceId) {
    Logger.info(`Deploying service: ${serviceId}`);

    const result = await this.makeRequest('POST', `/services/${serviceId}/deploys`, {
      clearCache: true
    });

    if (result.status === 201) {
      Logger.success('Deployment triggered!');
      Logger.info(`Deploy ID: ${result.data.id}`);
      return result.data;
    } else {
      throw new Error(`Deployment failed: ${result.status}`);
    }
  }

  async setEnvironmentVariable(serviceId, key, value) {
    Logger.info(`Setting env: ${key}`);

    const result = await this.makeRequest('PATCH', `/services/${serviceId}`, {
      envVars: [{
        key,
        value,
        sync: false
      }]
    });

    if (result.status === 200) {
      Logger.success(`${key} configurato`);
      return true;
    } else {
      Logger.warning(`Could not set ${key}: ${result.status}`);
      return false;
    }
  }
}

// ============================================================================
// MAIN
// ============================================================================

async function main() {
  console.log('\n');
  console.log('╔════════════════════════════════════════════════════════════════════╗');
  console.log('║  GENE1799 RENDER DEPLOYMENT AUTOMATION                            ║');
  console.log('║  Automated Bot Deployment to Render                               ║');
  console.log('╚════════════════════════════════════════════════════════════════════╝\n');

  try {
    // Get Render API key
    let apiKey = process.argv.find(arg => arg.startsWith('--token'))?.split('=')[1];

    if (!apiKey) {
      Logger.section('RENDER API KEY');
      Logger.info('Get your API key from: https://dashboard.render.com/account/api-tokens');
      apiKey = await prompt('Paste your Render API Key: ');
    }

    if (!apiKey) {
      Logger.error('No API key provided');
      process.exit(1);
    }

    // Initialize deployer
    const deployer = new RenderDeployer(apiKey);

    // Get services
    Logger.section('FETCHING RENDER SERVICES');
    const services = await deployer.getServices();

    // Find bot service
    const botService = await deployer.findBotService(services);

    if (!botService) {
      Logger.warning('Cannot proceed without bot service');
      process.exit(1);
    }

    // Deploy
    Logger.section('DEPLOYING BOT');
    const deploy = await deployer.deployService(botService.id);

    // Summary
    Logger.section('DEPLOYMENT SUMMARY');
    Logger.success('Bot deployment triggered!');
    Logger.info(`Service: ${botService.name}`);
    Logger.info(`Deploy ID: ${deploy.id}`);
    Logger.info(`Status: ${deploy.status}`);
    Logger.info(`\nMonitor at: https://dashboard.render.com/services/${botService.id}`);

    // GitHub notification
    Logger.section('NEXT STEPS');
    Logger.info('1. Check Render dashboard for deployment progress');
    Logger.info('2. Verify bot is running');
    Logger.info('3. Send /help to @gene1799_art_bot to test');

    console.log('\n');

  } catch (error) {
    Logger.error(`Deployment failed: ${error.message}`);
    process.exit(1);
  }
}

// Run
if (require.main === module) {
  main();
}

module.exports = { RenderDeployer, Logger };
