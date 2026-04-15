#!/usr/bin/env python3
"""
Agent that uses Ollama's glm-5.1:cloud model to generate text from a prompt.
Usage: python glm_agent.py "<prompt>"
Outputs the model's response to stdout (UTF-8).
"""
import sys
import json
import urllib.request
import urllib.error

OLLAMA_API = "http://localhost:11434/api/generate"
MODEL_NAME = "glm-5.1:cloud"

def main():
    if len(sys.argv) < 2:
        print("Usage: python glm_agent.py \"<prompt>\"", file=sys.stderr)
        sys.exit(1)
    prompt = sys.argv[1]
    data = {
        "model": MODEL_NAME,
        "prompt": prompt,
        "stream": False
    }
    data_bytes = json.dumps(data).encode('utf-8')
    req = urllib.request.Request(OLLAMA_API, data=data_bytes,
                                 headers={'Content-Type': 'application/json'})
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            resp_data = json.load(resp)
            # The response field contains the generated text
            result = resp_data.get('response', '')
            # Write as UTF-8 bytes to avoid encoding issues on Windows console
            sys.stdout.buffer.write(result.encode('utf-8'))
            sys.stdout.buffer.flush()
    except urllib.error.HTTPError as e:
        print(f"HTTP error: {e.code} {e.reason}", file=sys.stderr)
        sys.exit(1)
    except urllib.error.URLError as e:
        print(f"URL error: {e.reason}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Unexpected error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()