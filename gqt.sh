#!/bin/bash

INSTALL_DIR="/usr/local/bin"
SCRIPT_NAME="gqt"

# Install AWS CLI for Linux
install_aws_cli() {
    if ! command -v aws &> /dev/null; then
        echo "Installing AWS CLI..."
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        unzip awscliv2.zip
        sudo ./aws/install
        rm -rf aws awscliv2.zip
    else
        echo "AWS CLI is already installed."
    fi
}

# Copy the gq script to /usr/local/bin
install_gq() {
    echo "Installing gq command..."
    sudo cp gqt.sh "$INSTALL_DIR/$SCRIPT_NAME"
    sudo chmod +x "$INSTALL_DIR/$SCRIPT_NAME"
    echo "Installation complete. You can now use 'gq' command."
}

# Run installation steps
install_aws_cli
install_gq

