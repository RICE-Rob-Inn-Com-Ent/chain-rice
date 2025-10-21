#!/usr/bin/env python3
"""
Simple Knative serverless function in Python
"""

from flask import Flask, request, jsonify
import os
import json
from datetime import datetime

app = Flask(__name__)

@app.route('/')
def hello():
    """Main handler"""
    target = os.environ.get('TARGET', 'World')
    return f'Hello {target} from Knative!\n'

@app.route('/health')
def health():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.utcnow().isoformat()
    })

@app.route('/api/process', methods=['POST'])
def process():
    """Process data endpoint"""
    data = request.get_json() or {}

    # Process the data (example)
    result = {
        'status': 'processed',
        'input': data,
        'timestamp': datetime.utcnow().isoformat(),
        'function': 'hello-function'
    }

    return jsonify(result)

@app.route('/api/info')
def info():
    """Function information"""
    return jsonify({
        'name': 'hello-function',
        'version': '1.0.0',
        'runtime': 'Python 3.11',
        'platform': 'Knative',
        'environment': {
            'PORT': os.environ.get('PORT'),
            'TARGET': os.environ.get('TARGET'),
            'K_SERVICE': os.environ.get('K_SERVICE'),
            'K_REVISION': os.environ.get('K_REVISION'),
            'K_CONFIGURATION': os.environ.get('K_CONFIGURATION'),
        }
    })

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8080))
    app.run(host='0.0.0.0', port=port, debug=False)
