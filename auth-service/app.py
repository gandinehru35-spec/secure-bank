import os
from flask import Flask, jsonify

app = Flask(__name__)

# --- Secret Configuration ---
# These paths are where the Secret Manager CSI driver will mount the secrets.
REDIS_HOST_PATH = "/mnt/secrets/redis-host"
REDIS_PORT_PATH = "/mnt/secrets/redis-port"

def get_secret(secret_path):
    """Reads a secret from a file."""
    try:
        with open(secret_path, 'r') as f:
            return f.read().strip()
    except IOError:
        return None

# Load config at runtime
redis_host = get_secret(REDIS_HOST_PATH)
redis_port = get_secret(REDIS_PORT_PATH)

@app.route("/")
def home():
    """Health check and config-check endpoint."""
    return jsonify(
        service="auth-service",
        status="ok",
        message="Hello from Project SecureBank!"
    )

@app.route("/config")
def config_check():
    """Endpoint to verify that secrets were loaded correctly."""
    
    # We check if the secrets were successfully read from the volume
    if redis_host and redis_port:
        return jsonify(
            service="auth-service",
            secrets_loaded=True,
            redis_host=redis_host,
            redis_port=redis_port
        )
    else:
        return jsonify(
            service="auth-service",
            secrets_loaded=False,
            error="Could not read secrets from /mnt/secrets/"
        ), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", 5000)))
