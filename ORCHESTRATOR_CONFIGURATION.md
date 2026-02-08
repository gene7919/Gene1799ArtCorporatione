# Orchestrator Core Configuration Notes

## Overview

The Gene1799 Orchestrator Core (`backend/services/orchestrator-core.js`) has been integrated as-is from the Desktop/Gene1799ArtCorporatione system to maintain compatibility and consistency.

## Configuration Recommendations

### 1. Python Scripts Directory

**Current**: Hardcoded path `../../Desktop/Gene1799ArtCorporatione`
**File**: `backend/services/pythonBridge.js`, line 12

**Recommendation**: 
Set environment variable for flexibility:
```bash
PYTHON_SCRIPTS_DIR=/path/to/Desktop/Gene1799ArtCorporatione
```

**Fallback**: Current hardcoded path will work if repository structure is maintained.

### 2. Task Timeout

**Current**: 30 seconds (30000ms)
**File**: `backend/services/orchestrator-core.js`, line 96

**Configuration Option**:
```javascript
const orchestrator = new Gene1799Orchestrator({
  taskTimeout: 60000  // 60 seconds for slower operations
});
```

**Note**: Requires modifying orchestrator core to accept this parameter.

### 3. Memory TTL

**Current**: 24 hours (86400000ms)
**File**: `backend/services/orchestrator-core.js`, line 340

**Configuration Option**:
```javascript
const orchestrator = new Gene1799Orchestrator({
  memoryTTL: 172800000  // 48 hours
});
```

**Note**: Currently hardcoded. Can be made configurable if needed.

### 4. Task Queue Delay

**Current**: 1 second (1000ms) between tasks
**File**: `backend/services/orchestrator-core.js`, line 157

**Configuration Option**:
```javascript
const orchestrator = new Gene1799Orchestrator({
  queueDelay: 2000  // 2 seconds for less aggressive processing
});
```

**Note**: Helps prevent overwhelming the system during queue processing.

## Environment Variables

### Recommended .env Settings

```bash
# Orchestrator Configuration
PYTHON_SCRIPTS_DIR=/home/runner/work/Gene1799ArtCorporatione/Gene1799ArtCorporatione/Desktop/Gene1799ArtCorporatione
PYTHON_PATH=python3

# Task Management
TASK_TIMEOUT_MS=30000
TASK_QUEUE_DELAY_MS=1000

# Memory System
MEMORY_TTL_MS=86400000

# Logging
ORCHESTRATOR_LOG_DIR=./logs
ORCHESTRATOR_DATA_DIR=./data
```

## Directory Structure Requirements

For the system to work correctly, maintain this structure:

```
Gene1799ArtCorporatione/
├── server.js
├── backend/
│   ├── services/
│   │   ├── orchestrator-core.js
│   │   ├── orchestratorService.js
│   │   └── pythonBridge.js
│   └── routes/
│       └── orchestrator.js
└── Desktop/
    └── Gene1799ArtCorporatione/
        ├── enhanced_system.py
        ├── content_creation_agents.py
        ├── ai_learning_engine.py
        └── backend/
            └── src/
                └── orchestrator-core.js  (original source)
```

## Future Enhancements

If you need to customize these values, consider:

1. **Extend OrchestratorService Constructor**:
   ```javascript
   // In orchestratorService.js
   constructor(config = {}) {
     this.orchestrator = new Gene1799Orchestrator({
       logDir: './logs',
       dataDir: './data',
       taskTimeout: process.env.TASK_TIMEOUT_MS || 30000,
       queueDelay: process.env.TASK_QUEUE_DELAY_MS || 1000,
       memoryTTL: process.env.MEMORY_TTL_MS || 86400000,
       ...config
     });
   }
   ```

2. **Update Orchestrator Core** (if needed):
   - Make the orchestrator core accept these configuration parameters
   - Maintain backward compatibility
   - Ensure Desktop system compatibility

## Current Implementation

The current implementation:
- ✅ Works out-of-the-box with default values
- ✅ Maintains compatibility with Desktop system
- ✅ Supports environment variable for Python path
- ⚠️ Requires specific directory structure for Python integration
- ⚠️ Uses fixed timeout and delay values

## Deployment Considerations

### Development
- Default values are suitable
- Python fallback works if Python unavailable

### Production
- Consider increasing timeout for complex AI tasks
- Adjust queue delay based on system load
- Monitor memory usage and adjust TTL accordingly
- Ensure Python dependencies are installed for full functionality

### Docker
- Set PYTHON_SCRIPTS_DIR environment variable
- Mount Desktop directory as volume
- Configure timeouts via environment variables

## Troubleshooting

### Python Script Not Found
**Issue**: `cannot access '../../Desktop/Gene1799ArtCorporatione'`
**Solution**: 
1. Verify directory structure
2. Set PYTHON_SCRIPTS_DIR environment variable
3. Check file permissions

### Task Timeout
**Issue**: Tasks timing out after 30 seconds
**Solution**:
1. Extend task timeout for specific agents
2. Optimize Python script execution
3. Consider async processing for long tasks

### Memory Issues
**Issue**: Memory entries not expiring
**Solution**:
1. Check TTL configuration
2. Manually call `clearExpiredMemory()`
3. Adjust TTL for your use case

## Compatibility Matrix

| Component | Desktop System | Backend API | Compatible |
|-----------|---------------|-------------|------------|
| Orchestrator Core | ✅ v1.0.0 | ✅ v1.0.0 | ✅ Yes |
| Agent Registration | ✅ 6 agents | ✅ 6 agents | ✅ Yes |
| Task Dispatch | ✅ | ✅ | ✅ Yes |
| Learning System | ✅ | ✅ | ✅ Yes |
| Social Automation | ✅ | ✅ | ✅ Yes |
| Memory System | ✅ | ✅ | ✅ Yes |

## Best Practices

1. **Keep orchestrator-core.js in sync** with Desktop system
2. **Use environment variables** for deployment-specific configuration
3. **Monitor task execution times** and adjust timeout if needed
4. **Regular memory cleanup** to prevent memory leaks
5. **Log orchestrator events** for debugging and monitoring
6. **Test Python integration** before production deployment

---

**Note**: The orchestrator core has been integrated as-is from the Desktop system to ensure maximum compatibility. Configuration enhancements can be added to the wrapper layer (`orchestratorService.js`) without modifying the core.
