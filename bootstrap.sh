#!/bin/bash
#
# Bootstraps RPiLight on a Fresh Raspberry Pi
#

#
# Detecting Distro
#
function process_distro() {
    . /etc/os-release
    distro_string="$ID-$VERSION_ID"
}

#
# Install Specific Versions of Swift
#
function install_swift_tarball() {
    swift_release="$1"
    swift_version="5.0.2"
    tarball_url="https://github.com/uraimo/buildSwiftOnARM/releases/download/${swift_version}/swift-${swift_version}-${swift_release}.tgz"
    swift_filename="swift-${swift_version}-${swift_release}.tgz"

    echo "Downloading ${tarball_url}"
    pushd ~
    curl -L -o "$swift_filename" "$tarball_url"
    swift_filename=~/$swift_filename
    popd

    echo "Installing Swift ${swift_version} to /opt/swift"
    echo "WARNING: This will delete any existing data at /opt/swift"
    sudo rm -rf /opt/swift
    sudo mkdir -p /opt/swift
    pushd /opt/swift
    pv "${swift_filename}" | sudo tar -zx --strip-components=1
    popd

    #
    # Need to add /opt/swift/bin to the PATH Before we can use it.
    # This enables swift for all users on the device going forward. 
    #
    swift_path="export PATH=\$PATH:/opt/swift/bin"
    swift_profile="/etc/profile.d/swiftlang.sh"
    echo $swift_path | sudo tee -a $swift_profile

    # REVIEW: Should we delete the tarball once we know it's been installed?
}

#
# Distro-Specific Dependencies
#
function install_common_dependencies() {
    echo "Installing Common Dependencies..."
    sudo apt-get install --yes \
                    git \
                    pv
}

function install_stretch_dependencies() {
    echo "Installing Dependencies for Raspbian Stretch / Ubuntu Xenial..."
    sudo apt-get install --yes \
                    clang-3.8 \
                    libicu-dev \
                    libcurl4-nss-dev \
    sudo update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-3.8 100
    sudo update-alternatives --install /usr/bin/clang clang /usr/bin/clang-3.8 100
}

function install_buster_dependencies() {
    echo "Installing Dependencies for Raspbian Buster / Ubuntu Bionic..."
    sudo apt-get install --yes \
                    clang \
                    libicu-dev \
                    libcurl4-nss-dev \
                    curl
}

function update_apt() {
    echo "Updating apt Package Database..."
    if [ "$1" == "1" ]; then
        apt-get update --allow-releaseinfo-change
    else
        apt-get update
    fi
}

function install_dependencies() {
    install_common_dependencies

    case "$distro_string" in
        debian-9)
            update_apt 0
            install_stretch_dependencies
            install_swift_tarball "armv7-DebianStretch"
            ;;
        raspbian-9)
            update_apt 0
            install_stretch_dependencies
            install_swift_tarball "armv6-RPi0123-RaspbianStretch"
            ;;
        ubuntu-16.*)
            update_apt 0
            install_stretch_dependencies
            install_swift_tarball "armv7-Ubuntu1604"
            ;;
        debian-10)
            update_apt 0
            install_buster_dependencies
            install_swift_tarball "armv7-DebianBuster"
            ;;
        raspbian-10)
            update_apt 1
            install_buster_dependencies
            install_swift_tarball "armv6-RPi01234-RaspbianBuster"
            ;;
        ubuntu-18.*)
            update_apt 0
            install_buster_dependencies
            install_swift_tarball "armv7-Ubuntu1804"
            ;;
    esac
}

#
# Script Flow
#
process_distro
cd ~

# Install the Dependencies
install_dependencies

#
# Clone & Build
#
git clone https://github.com/Kaiede/RPiLight.git
pushd ~/RPiLight > /dev/null

./build.sh stable install

popd > /dev/null
