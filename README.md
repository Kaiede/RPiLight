# RPiLight

[![Build Status](https://travis-ci.org/Kaiede/RPiLight.svg?branch=master)](https://travis-ci.org/Kaiede/RPiLight)
[![MIT license](http://img.shields.io/badge/license-MIT-brightgreen.svg)](http://opensource.org/licenses/MIT)
![Swift](https://img.shields.io/badge/Swift-5.0.2-brightgreen.svg)
![Swift](https://img.shields.io/badge/Swift-4.1.3-brightgreen.svg)

An Aquarium Light Controller for the Raspberry Pi

### Hardware / OS

![Recommended](https://img.shields.io/badge/-Recommended-blue.svg) ![Raspbian](https://img.shields.io/badge/ARM-Raspbian%20Buster-brightgreen.svg) ![Swift](https://img.shields.io/badge/Swift-5.0.2-brightgreen.svg)

Raspbian Buster on any supported Raspberry Pi (Zero, 1, 2, 3, or 4) is the recommended configuration. This matches up with what is used in testing.

![Supported](https://img.shields.io/badge/-Supported-yellow.svg) ![Raspbian](https://img.shields.io/badge/ARM-Raspbian%20Stretch-brightgreen.svg) ![Swift](https://img.shields.io/badge/Swift-4.1.3-brightgreen.svg)

Raspbian Stretch and Swift 4.1.3 should also work, but isn't tested day to day. Reported bugs will be investigated.

![Experimental](https://img.shields.io/badge/-Experimental-orange.svg) ![Debian](https://img.shields.io/badge/ARM64-Debian-orange.svg) ![Ubuntu](https://img.shields.io/badge/ARM64-Ubuntu-orange.svg)

Running on ARM64 Ubuntu 16.04 or 18.04, or Debian Buster is possible, but may have some issues. Generally, this means that hardware LED controllers may be more limited, and access to the PWM hardware on a Raspberry Pi is more locked down. Stick to I2C-based controllers like the PC!9685 or MCP4725 if you can.

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

See the page on [Setting up the Raspberry Pi](Docs/HardwareSetup.md) for details.

### Installing RPiLight

RPiLight includes a bootstrapping script that walks you through getting things setup from a freshly flashed OS:
```
source <(curl -s https://raw.githubusercontent.com/Kaiede/RPiLight/master/bootstrap.sh)
```

This will grab the source from github and build it against the latest released tag. No pre-built binaries are currently available. 

You can update the service by running the following from the RPiLight root directory that was grabbed from GitHub:
```
git pull
./build.sh [stable | latest] install
```

stable will always grab the latest tagged release, while latest will grab the latest code, which may be newer.

## Configuration

Examples are in the [examples](examples) folder.

See [Configuring the Light Schedule](Docs/Configuration.md) for full details.

### Starting the Daemon

The install script will do most of the work, so you should only need to start it using `systemctl`, which will control the service:
```
sudo systemctl start rpilight
sudo systemctl restart rpilight
sudo systemctl stop rpilight
```

## Built With

* [Ephemeris](https://github.com/Kaiede/Ephemeris) - Calculate Moon and Sun positions in Swift.
* [Moderator](https://github.com/kareman/Moderator) - A simple, modular command line argument parser in Swift.
* [PCA9685](https://github.com/Kaiede/PCA9685) - PCA9685 I2C Driver for Swift.
* [MCP4725](https://github.com/Kaiede/MCP4725) - MCP4725 I2C Driver for Swift.
* [SingleBoard](https://github.com/Kaiede/SingleBoard) - Type-safe GPIO Library for single board computers.

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.

## Authors

* **Adam Thayer** - *Initial work* - [Kaiede](https://github.com/Kaiede)

See also the list of [contributors](https://github.com/Kaiede/RPiLight/contributors) who participated in this project.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details
