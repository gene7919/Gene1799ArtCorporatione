/**
 * GENE1799 Python-Node.js Integration Bridge
 * Provides communication between Node.js backend and Python AI agents
 */

const { spawn } = require('child_process');
const path = require('path');

class PythonBridge {
  constructor() {
    this.pythonPath = process.env.PYTHON_PATH || 'python3';
    this.scriptsDir = path.join(__dirname, '../../Desktop/Gene1799ArtCorporatione');
    this.activeProcesses = new Map();
  }

  /**
   * Execute a Python script and return the result
   */
  async execute(scriptName, args = {}) {
    return new Promise((resolve, reject) => {
      const scriptPath = path.join(this.scriptsDir, scriptName);
      const argsJson = JSON.stringify(args);
      
      const pythonProcess = spawn(this.pythonPath, [
        scriptPath,
        '--args', argsJson
      ]);

      let stdout = '';
      let stderr = '';

      pythonProcess.stdout.on('data', (data) => {
        stdout += data.toString();
      });

      pythonProcess.stderr.on('data', (data) => {
        stderr += data.toString();
      });

      pythonProcess.on('close', (code) => {
        if (code !== 0) {
          reject(new Error(`Python script exited with code ${code}: ${stderr}`));
        } else {
          try {
            const result = JSON.parse(stdout);
            resolve(result);
          } catch (error) {
            resolve({ stdout, stderr });
          }
        }
      });

      pythonProcess.on('error', (error) => {
        reject(error);
      });

      const processId = `${scriptName}-${Date.now()}`;
      this.activeProcesses.set(processId, pythonProcess);

      pythonProcess.on('close', () => {
        this.activeProcesses.delete(processId);
      });
    });
  }

  /**
   * Execute the orchestrator
   */
  async runOrchestrator(config = {}) {
    try {
      return await this.execute('enhanced_system.py', {
        action: 'execute',
        config
      });
    } catch (error) {
      console.error('Orchestrator execution error:', error);
      throw error;
    }
  }

  /**
   * Execute content creation
   */
  async createContent(spec) {
    try {
      return await this.execute('content_creation_agents.py', {
        action: 'create',
        spec
      });
    } catch (error) {
      console.error('Content creation error:', error);
      throw error;
    }
  }

  /**
   * Run self-healing diagnostics
   */
  async runSelfHealing() {
    try {
      return await this.execute('enhanced_system.py', {
        action: 'health_check'
      });
    } catch (error) {
      console.error('Self-healing check error:', error);
      throw error;
    }
  }

  /**
   * Get active services
   */
  getActiveServices() {
    return Array.from(this.activeProcesses.entries()).map(([id, process]) => ({
      id,
      pid: process.pid,
      killed: process.killed
    }));
  }

  /**
   * Clean up all processes
   */
  cleanup() {
    for (const [id, process] of this.activeProcesses.entries()) {
      try {
        process.kill();
      } catch (error) {
        console.error(`Error killing process ${id}:`, error);
      }
    }
    this.activeProcesses.clear();
  }
}

// Singleton instance
let bridgeInstance = null;

function getPythonBridge() {
  if (!bridgeInstance) {
    bridgeInstance = new PythonBridge();
  }
  return bridgeInstance;
}

module.exports = { PythonBridge, getPythonBridge };
