# RPiLight

[![Actions Status](https://github.com/Kaiede/RPiLight/workflows/Full%20CI/badge.svg)](https://github.com/Kaiede/RPiLight/actions)
[![MIT license](http://img.shields.io/badge/license-MIT-brightgreen.svg)](http://opensource.org/licenses/MIT)
![Swift](https://img.shields.io/badge/Swift-5.1.5-brightgreen.svg)

An Aquarium Light Controller for the Raspberry Pi

### Hardware / OS

![Supported](https://img.shields.io/badge/-Supported-blue.svg)

Raspbian Buster on any supported Raspberry Pi (Zero, 1, 2, 3, or 4) is the recommended configuration.

While RPiLight depends on Swift, the binary packages include the needed pre-compiled libraries, and can be installed on a clean Raspberry Pi image. 

![Experimental](https://img.shields.io/badge/-Experimental-orange.svg)

Running on ARM64 Ubuntu 16.04 or 18.04, or Debian Buster is possible, but may have some issues. Generally, this means that hardware LED controllers may be more limited, and access to the PWM hardware on a Raspberry Pi is more locked down. Stick to I2C-based controllers like the PCA9685 or MCP4725 if you can.

## Getting Started

These instructions will get you a copy of the project up and running on your local Raspberry Pi. It can be installed from binary, or you can grab source for development purposes.

See the page on [Setting up the Raspberry Pi](Docs/HardwareSetup.md) for details.

### Installing RPiLight

Grab the latest .deb package from [here](https://github.com/Kaiede/RPiLight/releases). You can grab it from the Pi using `curl`, usually.

Once downloaded you can install it using a command like this, where the final argument is the path to the package:

`sudo apt install ./rpilight_1.1.1_armhf.deb`

Once installed, you will then need to configure it. Under `/opt/rpilight/config` it is expected to find a `config.yml` and `schedule.yml` file. The first tells RPiLight how you're hardware is setup, while the second contains the light schedule.

## Configuration

Examples are in the [examples](examples) folder.

See [Configuring the Light Schedule](Docs/Configuration.md) for full details.

### Starting the Daemon

The installer will do most of the work, so you should only need to start it using `systemctl`, which will control the service:
```
sudo systemctl start rpilight
sudo systemctl restart rpilight
sudo systemctl stop rpilight
```

## Building From Source

- Clone the repository on a Raspberry Pi, and then navigate to the directory
- (One Time Only) `bash bootstrap.sh` - This will install dependencies needed for development. Specifically, it will download and install the version of Swift currently used for development, and anything else it may need.
- `./build.sh` - This is a wrapper around the Swift build system. It mostly provides a couple functions:
  - It can install a release build on the device using `./build.sh install`
  - It can package a release build using `./build.sh package`
  - You can add the `stable` or `latest` argument to have it fetch the latest tag (stable) or the latest master commit (latest) before building.

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
