#!/bin/bash
#
# 
#

#
# Prerequisites for Swift
#
function install_swift_prereqs() {
	echo "Installing Dependencies for Swift..."
	sudo apt-get install git cmake ninja-build clang-3.8 python uuid-dev libicu-dev icu-devtools libbsd-dev libedit-dev libxml2-dev libsqlite3-dev swig libpython-dev libncurses5-dev pkg-config libblocksruntime-dev libcurl4-openssl-dev autoconf libtool systemtap-sdt-dev

	sudo update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-3.8 100
	sudo update-alternatives --install /usr/bin/clang clang /usr/bin/clang-3.8 100
}

#
# Swift 3.1.1 Prerequisite
#
function install_swift() {
	PROCESSOR=$(uname -m)
	SWIFT_TARBALL=$(realpath swift_binaries.tgz)

	if [ -f "$SWIFT_TARBALL" ]; then
		echo "Swift Tarball Found: $SWIFT_TARBALL"
	elif [ "$PROCESSOR" == "armv6l" ]; then
		echo "Downloading Swift 3.1.1 for ARMv6"
		curl -L -o "$SWIFT_TARBALL" https://www.dropbox.com/s/r7a97yh1h7hc059/swift-3.1.1-Rpi1armv6-RaspbianStretchAug17_dispatchfix.tgz?dl=1
	elif [ "$PROCESSOR" == "armv7l" ]; then
		echo "Downloading Swift 3.1.1 for ARMv7"
		curl -L -o "$SWIFT_TARBALL" https://www.dropbox.com/s/z7uihfx2bcbuurw/swift-3.1.1-RPi23-RaspbianStretchAug17.tgz?dl=1
	else 
		echo "Unknown Processor. RPiLight may not work."
		exit 1
	fi

	echo "Installing Swift 3.1.1 into /usr..."
	pushd / > /dev/null
	sudo tar -xvf $SWIFT_TARBALL
	popd > /dev/null
}

#
# Grab Latest Git State
#
function update_source() {
	echo "Fetching Latest Source..."
	git pull
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
	RPILIGHT_SERVICE=$(realpath rpilight.service)

	RPILIGHT_DEST="/opt/rpilight"

	if [ ! -e "$RPILIGHT_DEST" ]; then
		sudo mkdir -p "$RPILIGHT_DEST"
	fi
	if [ ! -e "$RPILIGHT_DEST/config" ]; then
		sudo mkdir -p "$RPILIGHT_DEST/config"
	fi

	echo "Copying Binaries to $RPILIGHT_DEST"
	sudo cp "$RPILIGHT_BINARY" "$RPILIGHT_DEST"

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

if [ "$1" == "full" ] || [ "$1" == "update" ]; then
	INSTALL_MODE="$1"
fi

echo "RPiLight Directory: $SCRIPT_DIR"
echo "Install Mode: $INSTALL_MODE"
pushd "$SCRIPT_DIR" > /dev/null

if [ "$INSTALL_MODE" == "full" ]; then
	install_swift_prereqs
	install_swift
fi

if [ "$INSTALL_MODE" == "full" ] || [ "$INSTALL_MODE" == "update" ]; then
	update_source
fi

shutdown_service
build_rpilight
install_rpilight
configure_service

popd > /dev/null

echo "To start service, restart or run 'sudo systemctl start rpilight.service'."

