import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from __init__ import app
import uvicorn

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=5000)