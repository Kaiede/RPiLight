#!/bin/bash
#
# Build Script 
#
# ./build.sh <options>
#	stable - Get latest tag
#	latest - Get latest source
#	package - Build Package
#   install - Install Locally
#   

usage()
{
    echo "usage: build.sh [stable | latest] [package] [install]"
}

#
# Grab Latest Tag
#
function update_latest_source() {
	echo "Fetching Latest Source"
	git pull --rebase
}

#
# Grab Latest Git State
#
function update_stable_source() {
        echo "Fetching Tags"
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
# Copy Binaries to Output
#
function copy_binaries() {
	ROOT_DIR="$1"
	NEED_SUDO="$2"

	BINARY_PATH="$ROOT_DIR/opt/rpilight"
	CONFIG_PATH="$BINARY_PATH/config"
	SERVICE_PATH="$ROOT_DIR/lib/systemd/system"

	RPILIGHT_BINARY=$(realpath .build/release/RPiLight)
	RPILIGHT_EXAMPLES=$(realpath examples)
	RPILIGHT_SERVICE=$(realpath rpilight.service)

	if [ ! -e "$BINARY_PATH" ]; then
		$NEED_SUDO mkdir -p "$BINARY_PATH"
	fi
	if [ ! -e "$CONFIG_PATH" ]; then
		$NEED_SUDO mkdir -p "$CONFIG_PATH"
	fi
	if [ ! -e "$SERVICE_PATH" ]; then
		$NEED_SUDO mkdir -p "$SERVICE_PATH"
	fi
	echo "Copying Binaries to $BINARY_PATH"
	$NEED_SUDO cp "$RPILIGHT_BINARY" "$BINARY_PATH/RPiLight"

	echo "Copying Examples"
	$NEED_SUDO rsync --delete -r "$RPILIGHT_EXAMPLES/" "$BINARY_PATH/examples/"

	echo "Copying Service Configuration to $SERVICE_PATH" 
	sudo cp "$RPILIGHT_SERVICE" "$SERVICE_PATH"
}

#
# Build Binary Package
#
function build_package() {
	PACKAGE_PATH=$(realpath .package)
	PACKAGE_DEBIAN="$PACKAGE_PATH/DEBIAN"
	PACKAGE_INSTALL="$PACKAGE_PATH/opt/rpilight"
	PACKAGE_SYSTEMD="$PACKAGE_PATH/lib/systemd/system"

	echo "Packaging..."
	rm -rf "$PACKAGE_PATH"
	mkdir "$PACKAGE_PATH"

	copy_binaries "$PACKAGE_PATH" ""

	PACKAGE_ARCH=$(uname -m)
	PACKAGE_VERSION=$(git describe --tags `git rev-list --tags --max-count=1`)

	mkdir -p "$PACKAGE_DEBIAN"
	echo Package: RPiLight > "$PACKAGE_DEBIAN/control"
	echo Version: $PACKAGE_VERSION >> "$PACKAGE_DEBIAN/control"
	echo Architecture: armhf >> "$PACKAGE_DEBIAN/control"
	echo Depends: swiftlang \(\>= 3.1.1\) >> "$PACKAGE_DEBIAN/control"
	echo Maintainer: Kaiede \(user@biticus.net\) >> "$PACKAGE_DEBIAN/control"
	echo Description: TBD >> "$PACKAGE_DEBIAN/control"

	fakeroot dpkg-deb --build "$PACKAGE_PATH" rpilight\_$PACKAGE_VERSION\_$PACKAGE_ARCH.deb
}

#
# Install Binaries
#
function install_rpilight() {
	echo "Installing..."
	copy_binaries "" "sudo"
}

#
# Service Utilities
#
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
FETCH=0
PACKAGE=0
INSTALL=0

while [ "$1" != "" ]; do
    case $1 in
        stable | latest )       FETCH=$1
                                ;;
        package )    			PACKAGE=1
                                ;;
        install )           	INSTALL=1
                                ;;
		-h | --help )           usage
                                exit
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done

SCRIPT_PATH=$(realpath $0)
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")


echo "RPiLight Directory: $SCRIPT_DIR"
if [ "$FETCH" != "0" ]; then
	echo "Fetch Source: $FETCH"
fi
echo "Build Type: release"
if [ "$PACKAGE" == "1" ]; then 
	echo "Build Package: yes"
fi
if [ "$INSTALL" == "1" ]; then 
	echo "Install to /opt: yes"
fi
pushd "$SCRIPT_DIR" > /dev/null

if [ "$FETCH" == "stable" ]; then
	update_stable_source
elif [ "$FETCH" == "latest" ]; then
	update_latest_source
fi

build_rpilight

if [ "$PACKAGE" == "1" ]; then
	build_package
fi 

if [ "$INSTALL" == "1" ]; then
	shutdown_service
	install_rpilight
	configure_service
	echo "To start service, restart or run 'sudo systemctl start rpilight'."
fi

popd > /dev/null
