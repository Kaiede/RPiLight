#!/bin/bash
#
# Bootstraps RPiLight on a Fresh Raspberry Pi
#

#
# Configuring Package Repositories
#
function install_swift_repo() {
    curl -s https://packagecloud.io/install/repositories/swift-arm/debian/script.deb.sh | sudo bash
}

function install_binary_repo() {
    curl -s https://packagecloud.io/install/repositories/Kaiede/rpilight/script.deb.sh | sudo bash
}

function install_experimental_repo() {
    curl -s https://packagecloud.io/install/repositories/Kaiede/experimental/script.deb.sh | sudo bash
}

#
# Setup Pre-Requisites
#
function install_source_dependencies() {
    echo "Installing Source Dependencies..."
    sudo apt-get install --yes \
                    git \
                    pv
}

#
# Install Swift
#
function install_swift() {
    PROCESSOR=$(uname -m)

    if [ "$arch" == "aarch64" ]; then
        sudo apt-get install swift4
    elif [ "$arch" == "armv6l" ]; then
        sudo apt-get install swift3-armv6
    else
        sudo apt-get install swift3
    fi
}

#
# Install Service
#
function install_binaries() {
    local arch=$(uname -m)

    if [ "$arch" == "armv6l" ]; then
        sudo apt-get install rpilight-armv6
    else
        sudo apt-get install rpilight
    fi
}


#
# Script Flow
#
cd ~

while true; do
    read -p "Install [S]ource or [B]inary?" input
    case $input in
        [Ss]* ) install_type=source; break;;
        [Bb]* ) install_type=binary; break;;
        * ) echo "Please answer source or binary.";;
    esac
done

while true; do
    read -p "Install [E]xperimental or [S]table Builds?" input
    case $input in
        [Ee]* ) build_type=latest; break;;
        [Ss]* ) build_type=stable; break;;
        * ) echo "Please answer experimental or stable.";;
    esac
done



# Install the Repositories
install_swift_repo
install_binary_repo
if [ "$build_type" == "latest" ]; then
    install_experimental_repo
fi

# Install the Source or Binaries
if [ "$install_type" == "source" ]; then
    install_source_dependencies
    install_swift

    #
    # Clone and Build
    #
    git clone https://github.com/Kaiede/RPiLight.git
    pushd ~/RPiLight > /dev/null
    ./build.sh $build_type install
    popd > /dev/null
else
    install_binaries
fi

