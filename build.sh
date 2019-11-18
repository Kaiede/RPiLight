#!/bin/bash
#
# Build Script
#
# ./build.sh <options>
#   stable - Get latest tag
#   latest - Get latest source
#   package - Build Package
#   install - Install Locally
#

function usage()
{
    echo "usage: build.sh [bootstrap] [stable | latest] [package] [install]"
    echo 
    echo "  bootstrap - Fetch latest Swift & Packages (like bootstrap.sh)"
    echo "  stable | latest - Stable fetches latest release, latest contains newer changes"
    echo "  install - Install to /opt/rpilight"
    echo 
    echo "WARNING: package option is currently unsupported"
}

#
# Ensures Swift is in the PATH
#
# Used as a catch-all if this is run in the same shell as 
#

function ensure_swift_in_path() {
    which swift
    swift_profile="/etc/profile.d/swiftlang.sh"
    if [ $? -ne 0 ] && [ -e $swift_profile ]; then
        source $swift_profile
    fi

    which swift
    if [ $? -ne 0 ]; then
        echo "Error: Swift doesn't appear to be installed, or isn't in the PATH."
        echo 
        exit 1
    fi
}

#
# Run Bootstrap Again for Swift/Packages
#
function run_bootstrap() {
    echo "Running Bootstrap"
    bash ./bootstrap.sh nobuild
}

#
# Grab Latest Tag
#
function update_latest_source() {
    echo "Fetching Latest Source"
    git checkout master
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
    # Need this to avoid causing real bad throttling on Pi.
    swift build -c release -j 2
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
# Calculate the Package Version
#
# Takes variable to set with version
function get_package_version() {
    local VERSION=$(git describe --tags)

    local VERSION_ARRAY=(${VERSION//-/ })
    if [ "${VERSION_ARRAY[1]}" == "0" ]; then
        eval "$1=${VERSION_ARRAY[0]}"
    fi

    eval "$1=$VERSION"
}

function render_template() {
  eval "echo \"$(sed 's/\"/\\\\"/g' $1)\""
}

#
# Build Binary Package
#
function build_package() {
    PACKAGE_PATH=$(realpath .package)
    PACKAGE_DEBIAN="$PACKAGE_PATH/DEBIAN"
    PACKAGE_INSTALL="$PACKAGE_PATH/opt/rpilight"
    PACKAGE_SYSTEMD="$PACKAGE_PATH/lib/systemd/system"
    PACKAGE_ASSETS="$(realpath Assets/DEBIAN)"

    echo "Packaging..."
    rm -rf "$PACKAGE_PATH"
    mkdir "$PACKAGE_PATH"

    copy_binaries "$PACKAGE_PATH" ""

    version=""
    get_package_version version

    SYSTEM_ARCH=$(uname -m)
    case $SYSTEM_ARCH in
        aarch64 )               package_arch=
                                swift_package="swift4"
                                swift_version="4.1.1"
                                arch=arm64
                                filename_arch=aarch64
                                ;;
        armv6l )                package_arch="-armv6"
                                swift_package="swift3-armv6"
                                swift_version="3.1.1"
                                arch=armhf
                                filename_arch=$arch
                                ;;
        armv7l )                package_arch=
                                swift_package="swift3"
                                swift_version="3.1.1"
                                arch=armhf
                                filename_arch=$arch
                                ;;
        * )                     exit 1
                                ;;
    esac


    mkdir -p "$PACKAGE_DEBIAN"
    render_template "$PACKAGE_ASSETS/control.tmpl" > "$PACKAGE_DEBIAN/control"
    cp "$PACKAGE_ASSETS/preinst" "$PACKAGE_DEBIAN/"
    cp "$PACKAGE_ASSETS/postinst" "$PACKAGE_DEBIAN/"

    fakeroot dpkg-deb --build "$PACKAGE_PATH" rpilight$package_arch\_$version\_$filename_arch.deb
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
    PACKAGE_ASSETS="$(realpath Assets/DEBIAN)"
    sudo "$PACKAGE_ASSETS/preinst"
}

function configure_service() {
    PACKAGE_ASSETS="$(realpath Assets/DEBIAN)"
    sudo "$PACKAGE_ASSETS/postinst"
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
BOOTSTRAP=0

while [ "$1" != "" ]; do
    case $1 in
        bootstrap)              BOOTSTRAP=1
                                ;;
        stable | latest )       FETCH=$1
                                ;;
        package )               PACKAGE=1
                                ;;
        install )               INSTALL=1
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

# This is called just to make sure we can install swift
ensure_swift_in_path || exit $?

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

if [ "$BOOTSTRAP" == "1" ]; then
    run_bootstrap
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
