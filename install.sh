#!/bin/bash
#
# Installer Script 
#

#
# Grab Latest Git State
#
function update_source() {
        echo "Fetching Latest Source..."
        git fetch
        LATEST_TAG=$(git describe --tags `git rev-list --tags --max-count=1`)
        echo "Updating to $LATEST_TAG..."
        git checkout $LATEST_TAG
}

#
# Build It
#
function build_rpilight() {
	echo "Building RPiLight (Release)..."
	swift build -c release
}

#
# Copy the Output
#
function install_rpilight() {
	RPILIGHT_BINARY=$(realpath .build/release/RPiLight)
	RPILIGHT_EXAMPLES=$(realpath examples)
	RPILIGHT_SERVICE=$(realpath rpilight.service)

	RPILIGHT_DEST="/opt/rpilight"

	if [ ! -e "$RPILIGHT_DEST" ]; then
		sudo mkdir -p "$RPILIGHT_DEST"
	fi
	if [ ! -e "$RPILIGHT_DEST/config" ]; then
		sudo mkdir -p "$RPILIGHT_DEST/config"
	fi

	echo "Copying Binary to $RPILIGHT_DEST"
	sudo cp "$RPILIGHT_BINARY" "$RPILIGHT_DEST"

	echo "Copying Examples to $RPILIGHT_DEST"
	sudo rsync --delete -r examples/ /opt/rpilight/examples/

	SERVICE_DEST="/lib/systemd/system"
	echo "Copying Service Configuration to $SERVICE_DEST" 
	sudo cp "$RPILIGHT_SERVICE" "$SERVICE_DEST"
}

function shutdown_service() {
	echo "Shutting Down rpilight.service"
	sudo systemctl stop rpilight.service
}

function configure_service() {
	sudo systemctl daemon-reload
	sudo systemctl enable rpilight.service
}

#
#
#
#
# Install Script
#
INSTALL_MODE="default"
SCRIPT_PATH=$(realpath $0)
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")

if [ "$1" == "update" ]; then
	INSTALL_MODE="$1"
fi

echo "RPiLight Directory: $SCRIPT_DIR"
echo "Install Mode: $INSTALL_MODE"
pushd "$SCRIPT_DIR" > /dev/null

if [ "$INSTALL_MODE" == "update" ]; then
	update_source
fi

shutdown_service
build_rpilight
install_rpilight
configure_service

popd > /dev/null

echo "To start service, restart or run 'sudo systemctl start rpilight.service'."

