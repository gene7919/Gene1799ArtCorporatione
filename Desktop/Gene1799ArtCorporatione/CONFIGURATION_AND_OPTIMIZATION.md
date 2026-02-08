# 🎯 Gene1799 Enhanced System - Configuration & Best Practices
## Optimization Guide for Maximum Performance

---

## ⚙️ OPTIMAL CONFIGURATION

### 1. Self-Healing Configuration

```python
# DIAGNOSTIC THRESHOLDS (in auto_healing_agent.py)

THRESHOLDS = {
    'cpu': {
        'warning': 75,      # Alert at 75%
        'critical': 85,     # Action at 85%
        'target': 60        # Aim for <60%
    },
    'memory': {
        'warning': 80,      # Alert at 80%
        'critical': 90,     # Action at 90%
        'target': 65        # Aim for <65%
    },
    'disk': {
        'warning': 80,      # Alert when 80% full
        'critical': 95,     # Action at 95% full
        'target': 20        # Keep 20%+ free
    },
    'database': {
        'warning': 1000,    # >1000ms query time
        'critical': 5000,   # >5000ms query time
        'target': 100       # Aim for <100ms
    },
    'api_response': {
        'warning': 2000,    # >2000ms response
        'critical': 5000,   # >5000ms response
        'target': 500       # Aim for <500ms
    },
    'error_rate': {
        'warning': 0.05,    # >5% errors
        'critical': 0.10,   # >10% errors
        'target': 0.01      # Aim for <1%
    }
}

# HEALING CONFIGURATION

HEALING_CONFIG = {
    'check_interval': 60,           # Check every 60 seconds
    'repair_attempts': 3,           # Try 3 times before escalating
    'repair_timeout': 120,          # 2 minute timeout per repair
    'allow_restart': True,          # Can restart components
    'aggressive_cleanup': False,    # Set True for high-memory systems
}

# RECOMMENDED STRATEGY

HEALING_STRATEGY = {
    'cpu_high': ['optimize', 'cleanup', 'restart'],
    'memory_high': ['cleanup', 'reset', 'restart'],
    'disk_full': ['cleanup'],
    'database_slow': ['optimize', 'restart'],
    'api_slow': ['optimize', 'restart'],
    'high_errors': ['rotate_logs', 'reset', 'restart']
}
```

### 2. Content Generation Configuration

```python
# GENERATION PARAMETERS (in content_creation_agents.py)

CONTENT_CONFIG = {
    'text': {
        'daily_quota': 10,           # Items per day
        'styles': ['engaging', 'educational', 'professional', 'viral'],
        'min_quality': 0.80,         # Minimum quality score
        'readability_target': 0.85,  # Flesch reading ease
        'min_length': 50,            # Minimum characters
        'max_length': 280,           # Twitter limit
    },
    'video': {
        'daily_quota': 3,            # Specs/concept videos per day
        'types': ['viral', 'educational', 'demo'],
        'min_quality': 0.80,
        'resolution': '1920x1080',   # HD
        'fps': 30,                   # Smooth motion
        'duration_viral': 25,        # 25 seconds
        'duration_educational': 480, # 8 minutes
    },
    'music': {
        'daily_quota': 5,            # Tracks per day
        'genres': ['ambient', 'electronic', 'orchestral', 'cinematic'],
        'min_quality': 0.85,
        'sample_rate': 44100,        # CD quality
        'bit_depth': 16,             # 16-bit
        'duration_min': 10,          # Minimum 10 seconds
        'duration_max': 300,         # Maximum 5 minutes
    }
}

# PLATFORM OPTIMIZATION

PLATFORM_CONFIG = {
    'twitter': {
        'max_length': 280,
        'optimal_time': '17:00-19:00',  # Peak engagement
        'hashtags': 3,
        'media': 1,
        'frequency': 'multiple_per_day'
    },
    'linkedin': {
        'max_length': 3000,
        'optimal_time': '08:00-10:00, 17:00-19:00',
        'hashtags': 5,
        'media': 1,
        'frequency': '1-2_per_day'
    },
    'tiktok': {
        'duration': '15-60_seconds',
        'optimal_time': '18:00-22:00',
        'hashtags': 8,
        'trending': True,
        'frequency': '1_per_day'
    },
    'youtube': {
        'duration': '5-20_minutes',
        'frequency': '2-3_per_week',
        'thumbnail': 'compelling',
        'seo': 'optimized'
    }
}

# QUALITY THRESHOLDS

QUALITY_THRESHOLDS = {
    'text': {
        'quality_score': 0.80,
        'readability_score': 0.75,
        'engagement_potential': 'high'
    },
    'video': {
        'quality_score': 0.80,
        'resolution': '1920x1080_minimum',
        'fps': 30,
        'encoding': 'h264_best'
    },
    'music': {
        'quality_score': 0.85,
        'sample_rate': 44100,
        'distortion': 'none',
        'clarity': 'excellent'
    }
}
```

### 3. Social Media Configuration

```python
# RATE LIMITS (in social_media_automation.py)

RATE_LIMITS = {
    'twitter': {
        'posts_per_day': 15,
        'posts_per_hour': 3,
        'min_interval': 300,         # 5 minutes between posts
        'respect_rate_limits': True,
    },
    'linkedin': {
        'posts_per_day': 10,
        'posts_per_hour': 2,
        'min_interval': 600,         # 10 minutes between posts
        'respect_rate_limits': True,
    },
    'tiktok': {
        'posts_per_day': 5,
        'posts_per_hour': 1,
        'min_interval': 3600,        # 1 hour between posts
        'respect_rate_limits': True,
    }
}

# ENGAGEMENT TRACKING

ENGAGEMENT_CONFIG = {
    'check_interval': 1800,         # Check every 30 minutes
    'metrics': [
        'likes',
        'comments',
        'shares',
        'views',
        'impressions',
        'reach',
        'sentiment'
    ],
    'sentiment_threshold': 0.7,     # 70% positive
    'viral_threshold': 1000,        # 1000+ views = viral
}

# AUTO-REPLY CONFIGURATION

AUTO_REPLY_CONFIG = {
    'enabled': True,
    'response_time': 3600,          # Reply within 1 hour
    'templates': [
        'thank_you',
        'ask_question',
        'provide_link',
        'request_feedback'
    ],
    'sentiment_based': True,
}
```

### 4. AI Learning Configuration

```python
# LEARNING PARAMETERS (in ai_learning_engine.py)

LEARNING_CONFIG = {
    'algorithm': 'Q_learning',
    'learning_rate': 0.1,           # 10% weight to new experience
    'discount_factor': 0.9,         # 90% value to future rewards
    'epsilon': 0.2,                 # 20% exploration vs 80% exploitation
    'update_frequency': 'realtime',
}

# AGENT SPECIALIZATIONS

AGENTS = {
    'anti_cancer': {
        'domain': 'Medical Oncology',
        'specialization': 'Cancer research & treatment',
        'decision_context': 'Disease analysis',
        'success_metric': 'Research accuracy'
    },
    'drug_discovery': {
        'domain': 'Pharmaceutical',
        'specialization': 'Drug molecule analysis',
        'decision_context': 'Screening protocols',
        'success_metric': 'Hit rate'
    },
    'healthcare': {
        'domain': 'Medical',
        'specialization': 'EHR systems',
        'decision_context': 'Patient care',
        'success_metric': 'Patient outcomes'
    },
    'data_processor': {
        'domain': 'Analytics',
        'specialization': 'Data science',
        'decision_context': 'Processing pipelines',
        'success_metric': 'Data quality'
    },
    'communicator': {
        'domain': 'Content',
        'specialization': 'Communication strategy',
        'decision_context': 'Engagement tactics',
        'success_metric': 'Engagement rate'
    },
    'learning': {
        'domain': 'Meta-learning',
        'specialization': 'Algorithm optimization',
        'decision_context': 'Model selection',
        'success_metric': 'Performance improvement'
    },
    'orchestrator': {
        'domain': 'System Design',
        'specialization': 'Multi-agent coordination',
        'decision_context': 'Task assignment',
        'success_metric': 'System efficiency'
    }
}

# COLLABORATION BONUS

COLLABORATION = {
    'enabled': True,
    'bonus_factor': 1.30,            # 30% bonus for collaboration
    'knowledge_sharing': True,
    'insight_distribution': True,
    'min_agents_required': 2,
}
```

### 5. NFT & Monetization Configuration

```python
# ZORA.CO CONFIGURATION (in social_ai_integration.py)

ZORA_CONFIG = {
    'enabled': True,
    'network': 'mainnet',            # Use mainnet (not testnet)
    'wallet_address': 'YOUR_WALLET',
    'collection_name': 'Gene1799 Social Moments',
    'collection_description': 'Viral social media posts tokenized as NFTs',
    'royalty_percentage': 10,        # 10% secondary sales
    'enable_secondary_sales': True,
}

# VIRAL DETECTION

VIRAL_CONFIG = {
    'threshold_views': 1000,         # 1000+ views = viral
    'threshold_engagement': 50,      # 50+ engagements
    'threshold_sentiment': 0.75,     # 75%+ positive
    'time_window': 86400,            # Check within 24 hours
    'required_metrics': [             # All must be met
        'views',
        'engagement',
        'sentiment'
    ]
}

# MINTING STRATEGY

MINTING_STRATEGY = {
    'auto_mint': True,               # Automatic minting
    'mint_delay': 3600,              # Wait 1 hour after viral
    'batch_size': 5,                 # Mint 5 at a time
    'gas_optimization': True,        # Optimize transaction costs
    'metadata_enrichment': True,     # Add rich metadata
}
```

### 6. GPU Acceleration Configuration

```python
# GPU SETTINGS (for RTX 4070)

GPU_CONFIG = {
    'enabled': True,
    'device': 0,                     # GPU device index
    'memory_fraction': 0.8,          # Use 80% of 8GB (~6.4GB)
    'mixed_precision': True,         # FP16 for speed
    'batch_size': 32,                # Parallel processing
}

# FALLBACK STRATEGY

FALLBACK_CONFIG = {
    'cpu_fallback': True,            # Use CPU if GPU unavailable
    'memory_reduction': True,        # Reduce batch size on memory pressure
    'log_gpu_issues': True,          # Track GPU problems
}
```

---

## 🚀 PERFORMANCE OPTIMIZATION

### Checklist for Maximum Performance

```
MEMORY OPTIMIZATION:
☐ Set AGGRESSIVE_CLEANUP = True if <4GB RAM
☐ Reduce batch_size from 32 to 16 on low-memory systems
☐ Enable periodic cache clearing

CPU OPTIMIZATION:
☐ Use GPU acceleration (if available)
☐ Increase check_interval from 60s to 120s if CPU high
☐ Disable aggressive monitoring in off-peak hours

NETWORK OPTIMIZATION:
☐ Implement request batching
☐ Enable connection pooling
☐ Use compression for API calls

CONTENT QUALITY:
☐ Increase quality thresholds in production
☐ Enable human review for critical content
☐ Monitor content performance metrics

SOCIAL OPTIMIZATION:
☐ Time posts for peak engagement hours
☐ Space posts out (don't post all at once)
☐ Vary content types throughout day

LEARNING OPTIMIZATION:
☐ Collect at least 50 data points before evaluation
☐ Use diverse training data
☐ Retrain models at least weekly
```

---

## 📊 MONITORING BEST PRACTICES

### Key Metrics to Track

```python
# ADD TO monitoring_dashboard.py

METRICS = {
    'system_health': {
        'cpu_usage': ('gauge', 'CPU %'),
        'memory_usage': ('gauge', 'Memory %'),
        'disk_usage': ('gauge', 'Disk %'),
        'error_rate': ('counter', 'Errors/hour'),
        'uptime': ('gauge', 'Hours'),
    },
    'content_generation': {
        'texts_generated': ('counter', 'Texts/day'),
        'videos_generated': ('counter', 'Videos/day'),
        'music_generated': ('counter', 'Tracks/day'),
        'avg_quality_score': ('gauge', 'Quality 0-1'),
        'generation_time': ('timer', 'MS'),
    },
    'social_performance': {
        'posts_published': ('counter', 'Posts/day'),
        'total_impressions': ('counter', 'Impressions'),
        'engagement_rate': ('gauge', '%'),
        'viral_moments': ('counter', 'Moments'),
        'sentiment_avg': ('gauge', '0-1'),
    },
    'learning_progress': {
        'new_patterns': ('counter', 'Patterns/week'),
        'agent_improvement': ('gauge', '%'),
        'model_accuracy': ('gauge', '0-1'),
        'confidence_score': ('gauge', '0-1'),
    },
    'monetization': {
        'nfts_minted': ('counter', 'NFTs'),
        'secondary_sales': ('counter', 'Sales'),
        'revenue': ('counter', 'USD'),
    }
}
```

### Alert Configuration

```python
# Critical alerts to set

ALERTS = {
    'cpu_critical': ('cpu_usage > 85', 'Critical: CPU >85%'),
    'memory_critical': ('memory_usage > 90', 'Critical: Memory >90%'),
    'disk_critical': ('disk_usage > 95', 'Critical: Disk >95%'),
    'error_spike': ('error_rate > 0.10', 'Alert: Error rate >10%'),
    'content_failed': ('generation_failures > 0', 'Alert: Content gen failed'),
    'social_error': ('social_api_down', 'Alert: Social API down'),
    'learning_stalled': ('no_improvements_7days', 'Alert: No learning progress'),
    'nft_failed': ('minting_error', 'Alert: NFT minting failed'),
}

# Alert actions

ALERT_ACTIONS = {
    'critical': ['log', 'email', 'restart_component'],
    'alert': ['log', 'email'],
    'warning': ['log', 'dashboard'],
}
```

---

## 🔐 SECURITY BEST PRACTICES

### Credential Management

```python
# GOOD: Use environment variables
API_KEY = os.getenv('TWITTER_API_KEY')
API_SECRET = os.getenv('TWITTER_API_SECRET')

# BAD: Hardcode in code
API_KEY = "xxx123xxx"  # ❌ NEVER DO THIS
```

### Rate Limiting & Abuse Prevention

```python
# Implement rate limiting
RATE_LIMIT_CONFIG = {
    'requests_per_minute': 60,
    'requests_per_hour': 1000,
    'burst_limit': 10,
    'daily_limit': 10000,
}

# Implement request validation
def validate_request(request):
    # Check rate limits
    if exceeds_rate_limit(request):
        return 429  # Too Many Requests
    
    # Check for suspicious patterns
    if is_suspicious(request):
        return 403  # Forbidden
    
    return 200  # OK
```

### Data Privacy

```python
# Implement data retention policies
DATA_RETENTION = {
    'logs': 30,              # Keep 30 days
    'engagement_data': 90,   # Keep 90 days
    'user_data': 365,        # Keep 1 year
    'learning_data': 'keep',  # Keep indefinitely (needed for learning)
}

# Encrypt sensitive data
from cryptography.fernet import Fernet

ENCRYPTION_KEY = os.getenv('ENCRYPTION_KEY')
cipher = Fernet(ENCRYPTION_KEY)

def encrypt_sensitive_data(data):
    return cipher.encrypt(data.encode())

def decrypt_sensitive_data(encrypted_data):
    return cipher.decrypt(encrypted_data).decode()
```

---

## 🛠️ TROUBLESHOOTING OPTIMIZATIONS

### Common Issues & Solutions

**Issue: High CPU Usage**
```python
# Solution 1: Increase check intervals
HEALING_CONFIG['check_interval'] = 120  # 2 minutes instead of 1

# Solution 2: Reduce batch size
GPU_CONFIG['batch_size'] = 16  # Half batch size

# Solution 3: Disable expensive operations
MONITORING_CONFIG['enable_sentiment'] = False  # Sentiment is expensive
```

**Issue: Memory Leaks**
```python
# Solution 1: Enable aggressive cleanup
HEALING_CONFIG['aggressive_cleanup'] = True

# Solution 2: Reduce cache size
CACHE_CONFIG['max_size_mb'] = 256

# Solution 3: Implement periodic restarts
SERVICE_CONFIG['auto_restart_interval'] = 86400  # 24 hours
```

**Issue: Slow Content Generation**
```python
# Solution 1: Use GPU acceleration
GPU_CONFIG['enabled'] = True

# Solution 2: Reduce quality requirements
QUALITY_THRESHOLDS['text']['quality_score'] = 0.75  # Lower threshold

# Solution 3: Increase batch processing
GPU_CONFIG['batch_size'] = 64  # Higher batch size
```

**Issue: Social API Rate Limits**
```python
# Solution: Increase post interval spacing
RATE_LIMITS['twitter']['min_interval'] = 600  # 10 minutes

# Solution: Distribute posts throughout day
POSTING_STRATEGY = 'distributed'  # Not 'bulk'
```

---

## 📈 SCALING RECOMMENDATIONS

### Small Scale (Single Server)
```python
# Suitable for: Development, testing, small audiences
CONFIG = {
    'content_daily_quota': 10,
    'social_posts_daily': 30,
    'learning_agents': 7,
    'gpu_enabled': True,
    'monitoring_interval': 300,      # 5 minutes
}
```

### Medium Scale (2-3 Servers)
```python
# Suitable for: Growing audience, semi-production
CONFIG = {
    'content_daily_quota': 50,
    'social_posts_daily': 100,
    'learning_agents': 15,
    'gpu_enabled': True,
    'load_balancer': 'enabled',
    'monitoring_interval': 60,       # 1 minute
    'database': 'replicated',
}
```

### Large Scale (10+ Servers)
```python
# Suitable for: Enterprise, millions of users
CONFIG = {
    'content_daily_quota': 500,
    'social_posts_daily': 1000,
    'learning_agents': 50,
    'gpu_cluster': 'enabled',
    'load_balancer': 'active-active',
    'monitoring_interval': 10,       # 10 seconds
    'database': 'multi-region',
    'caching': 'redis-cluster',
}
```

---

## ✅ RECOMMENDED STARTING CONFIGURATION

```python
# PRODUCTION-READY BASELINE
# Use these settings for best experience on typical hardware

RECOMMENDED_CONFIG = {
    # Healing
    'healing_check_interval': 60,
    'healing_aggressive_cleanup': False,
    
    # Content
    'content_text_daily': 10,
    'content_video_daily': 2,
    'content_music_daily': 5,
    'min_quality_score': 0.80,
    
    # Social
    'twitter_posts_daily': 15,
    'linkedin_posts_daily': 10,
    'tiktok_posts_daily': 5,
    'respect_rate_limits': True,
    
    # Learning
    'learning_enabled': True,
    'num_learning_agents': 7,
    'collaboration_bonus': 1.30,
    
    # GPU
    'gpu_enabled': True,
    'gpu_memory_fraction': 0.8,
    
    # NFT
    'nft_auto_mint': True,
    'viral_threshold': 1000,
    'nft_royalty': 10,
    
    # Monitoring
    'monitoring_interval': 300,      # 5 minutes
    'log_verbosity': 'INFO',
}
```

---

## 📚 Additional Resources

- **Documentation**: See `FULL_SYSTEM_INTEGRATION.md`
- **Testing**: See `TEST_SCENARIOS.md`
- **Deployment**: See `DEPLOYMENT_READY.md`
- **Components**: See `ENHANCED_SYSTEM_README.md`

---

**Gene1799 Enhanced System - Configuration Guide**  
Version: 2.0.0  
Last Updated: 2026-02-08

© 2026 Gene1799. All rights reserved.
