#!/bin/bash
#
# Bootstraps RPiLight on a Fresh Raspberry Pi
#

#
# Setup Pre-Requisites
#
function install_dependencies() {
    echo "Installing Dependencies..."
    sudo apt-get install --yes \
                    autoconf \
                    clang-3.8 \
                    cmake \
                    git \
                    icu-devtools \
                    libblocksruntime-dev \
                    libbsd-dev \
                    libcurl4-openssl-dev \
                    libedit-dev \
                    libicu-dev \
                    libncurses5-dev \
                    libpthread-workqueue-dev \
                    libpython-dev \
                    libsqlite3-dev \
                    libtool \
                    libxml2-dev \
                    ninja-build \
                    pkg-config \
                    pv \
                    python \
                    swig \
                    systemtap-sdt-dev \
                    uuid-dev	


	sudo update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-3.8 100
	sudo update-alternatives --install /usr/bin/clang clang /usr/bin/clang-3.8 100
}

#
# Install Swift
#
function install_swift() {
	PROCESSOR=$(uname -m)
	SWIFT_TARBALL=$(realpath swift3_binaries.tgz)
	COMPONENT_NUM=2

	if [ "$PROCESSOR" == "armv6l" ]; then
		echo "Downloading Swift 3.1.1 for ARMv6..."
		curl -L -o "$SWIFT_TARBALL" https://www.dropbox.com/s/r7a97yh1h7hc059/swift-3.1.1-Rpi1armv6-RaspbianStretchAug17_dispatchfix.tgz?dl=1
	elif [ "$PROCESSOR" == "armv7l" ]; then
		echo "Downloading Swift 3.1.1 for ARMv7..."
		curl -L -o "$SWIFT_TARBALL" https://www.dropbox.com/s/z7uihfx2bcbuurw/swift-3.1.1-RPi23-RaspbianStretchAug17.tgz?dl=1
	else
		echo "Unknown Processor. RPiLight may not work."
		exit 1
	fi

	echo "Installing Swift into /opt/swift/..."
	if [ ! -d "/opt/swift" ]; then
		sudo mkdir -p /opt/swift
	fi
	pushd /opt/swift > /dev/null
	pv "$SWIFT_TARBALL" | sudo tar -zx --strip-components=$COMPONENT_NUM 
	popd > /dev/null
}

function add_swift_path() {
	PROFILE_PATH=$(realpath ~/.bash_profile)

	echo "Adding /opt/swift/bin to ~/.bash_profile..."
	touch $PROFILE_PATH
	echo "#" >> $PROFILE_PATH
	echo "# Swift Binaries" >> $PROFILE_PATH
	echo "#" >> $PROFILE_PATH
	echo "export PATH=\$PATH:/opt/swift/bin" >> $PROFILE_PATH
	source $PROFILE_PATH

	export PATH
}

#
# Script Flow
#
cd ~
install_dependencies
install_swift
add_swift_path

git clone https://github.com/Kaiede/RPiLight.git
pushd ~/RPiLight > /dev/null
./install.sh 
popd > /dev/null