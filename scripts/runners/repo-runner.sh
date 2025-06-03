#!/bin/bash

# -----------------------
# Configurable Variables.
# -----------------------
RUNNER_VERSION="2.324.0"
REPO_URL="https://github.com/cyprientemateu/github-action"
RUNNER_TOKEN="A3TRWM3MJAISAPBLRQ3VWDLIH6L6W"
RUNNER_LABELS="tcc-build,tcc-deploy"
RUNNER_USER="runner"
RUNNER_COUNT=3
BASE_DIR="/opt/github-runner-multi"

# -----------------------
# Create system user
# -----------------------
if ! id -u "$RUNNER_USER" >/dev/null 2>&1; then
  echo "[INFO] Creating system user: $RUNNER_USER"
  sudo useradd -m -s /bin/bash "$RUNNER_USER"
fi

# Allow the runner user to run all sudo commands without password
echo "[INFO] Granting passwordless sudo to $RUNNER_USER"
echo "$RUNNER_USER ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/$RUNNER_USER > /dev/null
sudo chmod 0440 /etc/sudoers.d/$RUNNER_USER

# Create base directory for all runners
sudo mkdir -p "$BASE_DIR"
sudo chown "$RUNNER_USER":"$RUNNER_USER" "$BASE_DIR"

# Download runner package once
cd "$BASE_DIR"
RUNNER_TAR="actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz"
if [ ! -f "$RUNNER_TAR" ]; then
  echo "[INFO] Downloading runner version $RUNNER_VERSION"
  curl -o "$RUNNER_TAR" -L \
    "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/${RUNNER_TAR}"
fi

echo "[INFO] Validating SHA256 checksum"
echo "5020da7139d85c776059f351e0de8fdec753affc9c558e892472d43ebeb518f4  $RUNNER_TAR" | shasum -a 256 -c

# -----------------------
# Install multiple runners
# -----------------------
for i in $(seq 1 $RUNNER_COUNT); do
  RUNNER_DIR="$BASE_DIR/runner-$i"
  RUNNER_NAME="$(hostname)-RNNER-$i"
  SERVICE_NAME="github-runner-$i"

  echo "[INFO] Setting up runner $i in $RUNNER_DIR"
  sudo mkdir -p "$RUNNER_DIR"
  sudo chown "$RUNNER_USER":"$RUNNER_USER" "$RUNNER_DIR"

  sudo -u "$RUNNER_USER" bash <<EOF
set -e
cd "$RUNNER_DIR"

# Copy and extract
cp "$BASE_DIR/$RUNNER_TAR" .
tar xzf "$RUNNER_TAR"

# Remove old config if exists
if [ -f ".runner" ]; then
  yes | ./config.sh remove || true
  rm -f .runner
fi

# Configure runner
./config.sh \
  --url "$REPO_URL" \
  --token "$RUNNER_TOKEN" \
  --name "$RUNNER_NAME" \
  --labels "$RUNNER_LABELS" \
  --runnergroup "$RUNNER_GROUP" \
  --unattended \
  --work _work
EOF

  # -----------------------
  # Create systemd service
  # -----------------------
  echo "[INFO] Creating systemd service for $SERVICE_NAME"
  sudo tee /etc/systemd/system/$SERVICE_NAME.service > /dev/null <<EOL
[Unit]
Description=GitHub Actions Runner $i
After=network.target

[Service]
ExecStart=$RUNNER_DIR/run.sh
User=$RUNNER_USER
WorkingDirectory=$RUNNER_DIR
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOL

  # Start the runner
  sudo systemctl daemon-reload
  sudo systemctl enable --now "$SERVICE_NAME"
done

echo "✅ All $RUNNER_COUNT GitHub runners installed and running with labels: $RUNNER_LABELS"
