from flask import Flask, jsonify
app = Flask(__name__)

@app.route("/")
def home():
    return jsonify({"Gene1799": "🚀 FULLY OPERATIONAL", "modules": ["Healthcare✅", "Chelation✅", "Anticancer✅", "Copilot✅"]})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
