#!/bin/bash

# =================================
# PROMPT FLOW POETRY DEBUG SCRIPT (BASH)
# =================================

echo "[*] Debugging Poetry configuration..."

# Navigate to project root
cd ..

# Build the backend
echo "Building backend container..."
docker-compose build backend

# Run each diagnostic command separately
echo "=== Poetry Environment Info ==="
docker-compose run --rm backend poetry env info

echo "=== Poetry Show Packages ==="
docker-compose run --rm backend poetry show

echo "=== Check if uvicorn is installed ==="
docker-compose run --rm backend bash -c "poetry run which uvicorn || echo 'uvicorn not found'"

echo "=== Try running uvicorn directly ==="
docker-compose run --rm backend bash -c "poetry run uvicorn --version || echo 'uvicorn version failed'"

echo "=== Check virtual environment ==="
docker-compose run --rm backend bash -c "ls -la .venv/ || echo 'No .venv directory'"

echo "=== Python path ==="
docker-compose run --rm backend poetry run python -c "import sys; print(sys.path)"

echo "=== Try importing app ==="
docker-compose run --rm backend poetry run python -c "import app.main; print('App import successful')"

echo ""
echo "=== POETRY DEBUG COMPLETE ==="
