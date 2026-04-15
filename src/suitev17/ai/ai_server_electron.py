#!/usr/bin/env python3
"""
AI Server Electron v2.0 - Dashboard-ready AI API Server
Con logging avanzato, gestione errori e endpoint dashboard
"""
import os
import sys
import json
import time
import logging
from datetime import datetime
from flask import Flask, request, jsonify
from flask_cors import CORS

sys.path.insert(0, r'C:\SuiteV17')

# Configurazione logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler(r'C:\SuiteV17\logs\ai_server.log', encoding='utf-8') if os.path.exists(r'C:\SuiteV17\logs') else logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app, resources={r"/api/*": {"origins": "*"}})

# Load env
env_path = os.path.join(r'C:\SuiteV17', '.env')
if os.path.exists(env_path):
    with open(env_path, 'r', encoding='utf-8') as f:
        for line in f:
            if '=' in line and not line.startswith('#'):
                try:
                    key, value = line.strip().split('=', 1)
                    os.environ.setdefault(key, value)
                except ValueError:
                    continue

# Init AI
ai = None
AI_READY = False
try:
    from ai_unified import UnifiedAI
    ai = UnifiedAI()
    AI_READY = True
    logger.info('AI Server: UnifiedAI inizializzato con successo')
except Exception as e:
    logger.error(f'AI Server: Errore inizializzazione AI: {e}')
    AI_READY = False

@app.before_request
def log_request():
    logger.info(f'Request: {request.method} {request.path} from {request.remote_addr}')

@app.after_request
def after_request(response):
    response.headers.add('Access-Control-Allow-Origin', '*')
    response.headers.add('Access-Control-Allow-Headers', 'Content-Type,Authorization')
    response.headers.add('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE,OPTIONS')
    return response

@app.route('/api/status')
def status():
    """Stato del server AI"""
    return jsonify({
        'status': 'online',
        'ai_ready': AI_READY,
        'groq': ai.groq_client is not None if ai else False,
        'timestamp': datetime.now().isoformat(),
        'metrics': ai.get_metrics() if ai else None
    })

@app.route('/api/health')
def health():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'ai_ready': AI_READY,
        'timestamp': datetime.now().isoformat()
    })

@app.route('/api/config')
def get_config():
    """Restituisce configurazione AI (senza API key sensibili)"""
    return jsonify({
        'groq_model': os.getenv('GROQ_MODEL', 'llama-3.3-70b-versatile'),
        'groq_configured': bool(os.getenv('GROQ_API_KEY') and 'YOUR' not in os.getenv('GROQ_API_KEY', '')),
        'huggingface_configured': bool(os.getenv('HUGGINGFACE_API_KEY') and 'YOUR' not in os.getenv('HUGGINGFACE_API_KEY', '')),
        'tts_backend': os.getenv('TTS_BACKEND', 'edge')
    })

@app.route('/api/generate/text', methods=['POST'])
def gen_text():
    """Genera testo con AI"""
    if not AI_READY:
        return jsonify({'error': 'AI not ready', 'status': 'unavailable'}), 503
    
    data = request.json or {}
    prompt = data.get('prompt', '')
    system = data.get('system')
    max_tokens = data.get('max_tokens', 500)
    
    if not prompt:
        return jsonify({'error': 'Prompt richiesto'}), 400
    
    try:
        result = ai.generate_text(prompt, system, max_tokens)
        return jsonify({
            'result': result.content,
            'success': result.success,
            'latency_ms': result.latency_ms,
            'timestamp': result.timestamp,
            'metadata': result.metadata
        })
    except Exception as e:
        logger.error(f'Errore generate_text: {e}')
        return jsonify({'error': str(e)}), 500

@app.route('/api/generate/audio', methods=['POST'])
def gen_audio():
    """Genera audio con AI"""
    if not AI_READY:
        return jsonify({'error': 'AI not ready', 'status': 'unavailable'}), 503
    
    data = request.json or {}
    prompt = data.get('prompt', '')
    duration = data.get('duration', 10)
    
    if not prompt:
        return jsonify({'error': 'Prompt richiesto'}), 400
    
    try:
        result = ai.generate_audio(prompt, duration=duration)
        return jsonify({
            'result': result.content,
            'success': result.success,
            'latency_ms': result.latency_ms,
            'timestamp': result.timestamp,
            'metadata': result.metadata
        })
    except Exception as e:
        logger.error(f'Errore generate_audio: {e}')
        return jsonify({'error': str(e)}), 500

@app.route('/api/generate/image', methods=['POST'])
def gen_image():
    """Genera immagine con AI"""
    if not AI_READY:
        return jsonify({'error': 'AI not ready', 'status': 'unavailable'}), 503
    
    data = request.json or {}
    prompt = data.get('prompt', '')
    
    if not prompt:
        return jsonify({'error': 'Prompt richiesto'}), 400
    
    try:
        result = ai.generate_image(prompt)
        return jsonify({
            'result': result.content,
            'success': result.success,
            'latency_ms': result.latency_ms,
            'timestamp': result.timestamp,
            'metadata': result.metadata
        })
    except Exception as e:
        logger.error(f'Errore generate_image: {e}')
        return jsonify({'error': str(e)}), 500

@app.route('/api/generate/voice', methods=['POST'])
def gen_voice():
    """Genera voce TTS"""
    if not AI_READY:
        return jsonify({'error': 'AI not ready', 'status': 'unavailable'}), 503
    
    data = request.json or {}
    text = data.get('text', '')
    voice = data.get('voice', 'it-IT-ElsaNeural')
    
    if not text:
        return jsonify({'error': 'Testo richiesto'}), 400
    
    try:
        result = ai.generate_voice(text, voice=voice)
        return jsonify({
            'result': result.content,
            'success': result.success,
            'latency_ms': result.latency_ms,
            'timestamp': result.timestamp,
            'metadata': result.metadata
        })
    except Exception as e:
        logger.error(f'Errore generate_voice: {e}')
        return jsonify({'error': str(e)}), 500

@app.route('/api/generate', methods=['POST'])
def generate():
    """Endpoint unificato per generazione"""
    if not AI_READY:
        return jsonify({'error': 'AI not ready', 'status': 'unavailable'}), 503
    
    data = request.json or {}
    module = data.get('module')
    prompt = data.get('prompt', '')
    
    if not module:
        return jsonify({'error': 'Module richiesto (text/audio/image/voice)'}), 400
    if not prompt:
        return jsonify({'error': 'Prompt richiesto'}), 400
    
    try:
        result = ai.generate(module, prompt, **{k: v for k, v in data.items() if k not in ['module', 'prompt']})
        return jsonify({
            'result': result.content,
            'success': result.success,
            'latency_ms': result.latency_ms,
            'timestamp': result.timestamp,
            'error': result.error,
            'metadata': result.metadata
        })
    except Exception as e:
        logger.error(f'Errore generate: {e}')
        return jsonify({'error': str(e)}), 500

@app.route('/api/metrics')
def get_metrics():
    """Restituisce metriche AI"""
    if not AI_READY:
        return jsonify({'error': 'AI not ready'}), 503
    return jsonify(ai.get_metrics())

@app.errorhandler(404)
def not_found(e):
    return jsonify({'error': 'Endpoint non trovato', 'path': request.path}), 404

@app.errorhandler(500)
def server_error(e):
    logger.error(f'Server error: {e}')
    return jsonify({'error': 'Errore interno del server'}), 500

if __name__ == '__main__':
    logger.info('='*60)
    logger.info('AI Server Electron v2.0 - Starting on port 8099')
    logger.info('='*60)
    app.run(host='0.0.0.0', port=8099, debug=False, threaded=True)
