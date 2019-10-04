#!/bin/bash

SWIFT_VERSION=$1
DISTRO_RAW=$2

DISTRO_LONG=${DISTRO_RAW//[-]/}
DISTRO_SHORT=${DISTRO_LONG//[.]/}

# Install Swift to $HOME/swift

mkdir ${HOME}/swift
curl https://swift.org/builds/swift-${SWIFT_VERSION}-release/${DISTRO_SHORT}/swift-${SWIFT_VERSION}-RELEASE/swift-${SWIFT_VERSION}-RELEASE-${DISTRO_LONG}.tar.gz -s | tar -xz -C ${HOME}/swift --strip-components=2
