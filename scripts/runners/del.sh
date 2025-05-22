#!/bin/bash

# Directory where your runners are installed
RUNNERS_BASE_DIR="/opt/github-runner-multi"

# GitHub token with permission to remove the runner (if needed).
REMOVE_TOKEN="AN4MXFJDKBNW6QM5MV7AH5DIFDYN4"

echo "Starting GitHub Runner cleanup..."

for runner_dir in "$RUNNERS_BASE_DIR"/*; do
    if [ -d "$runner_dir" ] && [ -f "$runner_dir/config.sh" ]; then
        echo "Processing runner at: $runner_dir"
        cd "$runner_dir" || continue

        # Try stopping the systemd service if it exists
        SERVICE_FILE=$(find /etc/systemd/system -name "*.service" | grep "$(basename "$runner_dir")" || true)
        if [ -n "$SERVICE_FILE" ]; then
            SERVICE_NAME=$(basename "$SERVICE_FILE")
            echo "Stopping service: $SERVICE_NAME"
            sudo systemctl stop "$SERVICE_NAME" || echo "Warning: Failed to stop $SERVICE_NAME"
            sudo systemctl disable "$SERVICE_NAME" || echo "Warning: Failed to disable $SERVICE_NAME"
            sudo rm -f "$SERVICE_FILE"
            sudo systemctl daemon-reload
        else
            echo "No systemd service found for $(basename "$runner_dir")"
        fi

        # Unconfigure runner without sudo
        if [ -n "$REMOVE_TOKEN" ]; then
            echo "Removing runner with token"
            ./config.sh remove --unattended --token "$REMOVE_TOKEN"
        else
            echo "Removing runner without token"
            ./config.sh remove --unattended
        fi

        echo "Deleting runner directory: $runner_dir"
        rm -rf "$runner_dir"
        echo "✅ Cleaned: $(basename "$runner_dir")"
    fi
done

echo "🎉 All GitHub runners have been processed."
