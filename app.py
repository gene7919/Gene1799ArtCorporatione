from flask import Flask
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

@app.route('/')
def index():
    return '''
    <html>
        <head><title>GENE1799 Medical AI</title></head>
        <body style='font-family: Arial; padding: 50px; background: #0f0f0f; color: #00ff00;'>
            <h1>🏥 GENE1799 Medical AI System</h1>
            <h2>✅ Web Dashboard Attivo</h2>
            <p>Sistema operativo sulla porta 5000</p>
        </body>
    </html>
    '''

@app.route('/api/status')
def status():
    return {'status': 'online', 'system': 'GENE1799'}

if __name__ == '__main__':
    print("\n" + "="*60)
    print("🌐 GENE1799 Web Dashboard")
    print("="*60)
    print("\n✅ Server: http://localhost:5000")
    print("\n" + "="*60)
    app.run(debug=True, port=5000)
