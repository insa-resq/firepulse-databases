#!/usr/bin/env bash

set -euo pipefail

LOCAL_ENV_FILE=.env.deploy

if [ ! -f "$LOCAL_ENV_FILE" ]; then
    echo "Error: Environment file $LOCAL_ENV_FILE not found." >&2
    exit 1
fi

echo "Loading environment variables from $LOCAL_ENV_FILE..."
set -a
# shellcheck source=/dev/null
source "$LOCAL_ENV_FILE"
set +a

REQUIRED_VARS=("SSH_HOST" "SSH_USER" "SSH_PASSWORD" "POSTGRES_DB" "POSTGRES_USER" "POSTGRES_PASSWORD")
MISSING_VARS=0
for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var:-}" ]; then
        echo "Error: Environment variable $var is not set." >&2
        MISSING_VARS=1
    fi
done
if [ "$MISSING_VARS" -eq 1 ]; then
    echo "Please update $LOCAL_ENV_FILE with the required variables." >&2
    exit 1
fi

DEPLOYMENT_PATH=/home/$SSH_USER/deployment

# Get confirmation from user
echo "You are about to deploy all files from the 'src' directory to the remote server:"
echo "  Host: $SSH_HOST"
echo "  User: $SSH_USER"
echo "  Deployment Directory: $DEPLOYMENT_PATH"
echo "This will overwrite existing files in the deployment directory on the remote server."
read -rp "Are you sure you want to continue? (yes/no): " confirmation
if [[ "$confirmation" != "yes" ]]; then
    echo "Deployment aborted."
    exit 0
fi

# Install sshpass if not present
if ! command -v sshpass >/dev/null 2>&1; then
    echo "sshpass not found. Installing sshpass..."
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update
        sudo apt-get install -y sshpass
    else
        echo "Error: Package manager not supported. Please install sshpass manually." >&2
        exit 1
    fi
fi

REMOTE_ENV_FILE=.env.remote

# Function to clean up temporary files
cleanup() {
    if [ -f "$REMOTE_ENV_FILE" ]; then
        rm -f "$REMOTE_ENV_FILE"
    fi
}
trap cleanup EXIT

echo "Generating $REMOTE_ENV_FILE file..."

cat > "$REMOTE_ENV_FILE" <<EOF
POSTGRES_DB=$POSTGRES_DB
POSTGRES_USER=$POSTGRES_USER
POSTGRES_PASSWORD="$POSTGRES_PASSWORD"
DATABASE_URL="postgresql://$POSTGRES_USER:$POSTGRES_PASSWORD@postgres:5432/$POSTGRES_DB"
EOF

echo "Starting deployment to $SSH_HOST as user $SSH_USER..."

export SSHPASS="$SSH_PASSWORD"
SSH_TARGET=$SSH_USER@$SSH_HOST
SSH_OPTIONS=(-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR)

echo "Creating remote deployment directory..."
sshpass -e ssh "${SSH_OPTIONS[@]}" "$SSH_TARGET" "mkdir -p $DEPLOYMENT_PATH"

echo "Copying files to remote server..."
sshpass -e rsync -avz \
    --exclude 'node_modules' \
    --exclude '.env' \
    --exclude '.env.example' \
    "src/" "$SSH_TARGET:$DEPLOYMENT_PATH/"

echo "Uploading secrets..."
sshpass -e scp "${SSH_OPTIONS[@]}" "$REMOTE_ENV_FILE" "$SSH_TARGET:$DEPLOYMENT_PATH/.env"
rm -f "$REMOTE_ENV_FILE"

echo "Executing remote commands..."
sshpass -e ssh "${SSH_OPTIONS[@]}" "$SSH_TARGET" "bash -s" <<EOF
set -e

echo 'Navigating to deployment directory...'
cd "${DEPLOYMENT_PATH}"

chmod 600 .env

chmod +x ./scripts/install-docker.sh
sudo ./scripts/install-docker.sh

echo 'Starting Docker services...'
sudo docker compose up --build -d --wait
sudo docker system prune -f
EOF

echo "Deployment completed successfully !"
