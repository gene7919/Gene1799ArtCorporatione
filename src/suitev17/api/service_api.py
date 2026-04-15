#!/usr/bin/env python3
# SuiteV17 Service Control API - FastAPI Version
import sys
sys.path.insert(0, r'C:\SuiteV17')

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import uvicorn

from service_controller import ServiceController

app = FastAPI(title='SuiteV17 Service Control')

app.add_middleware(
    CORSMiddleware,
    allow_origins=['*'],
    allow_methods=['*'],
    allow_headers=['*']
)

controller = ServiceController()

@app.get('/api/services')
async def list_services():
    return controller.get_status()

@app.post('/api/services/{name}/start')
async def start_service(name: str):
    return controller.start(name)

@app.post('/api/services/{name}/stop')
async def stop_service(name: str):
    return controller.stop(name)

@app.post('/api/services/start-all')
async def start_all():
    results = {}
    for name in controller.SERVICES:
        results[name] = controller.start(name)
    return results

@app.post('/api/services/stop-all')
async def stop_all():
    return controller.stop_all()

@app.get('/api/status')
async def api_status():
    return {'status': 'ok', 'services_available': len(controller.SERVICES)}

if __name__ == '__main__':
    print('SuiteV17 Service Control API')
    print('http://localhost:9000')
    uvicorn.run(app, host='0.0.0.0', port=9000)
