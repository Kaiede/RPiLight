# RPiLight

[![Build Status](https://travis-ci.org/Kaiede/RPiLight.svg?branch=master)](https://travis-ci.org/Kaiede/RPiLight)
[![MIT license](http://img.shields.io/badge/license-MIT-brightgreen.svg)](http://opensource.org/licenses/MIT)
![Swift](https://img.shields.io/badge/Swift%203-Supported-brightgreen.svg)
![Swift](https://img.shields.io/badge/Swift%204-Compatible-yellow.svg)

An Aquarium Light Controller for the Raspberry Pi

### Hardware / OS

![Supported](https://img.shields.io/badge/-Supported-brightgreen.svg) ![Raspbian](https://img.shields.io/badge/ARM-Raspbian%20Stretch-brightgreen.svg) ![Swift](https://img.shields.io/badge/Swift%203--brightgreen.svg)
* Pi 3B or 3B+ ![Recommended](https://img.shields.io/badge/-Recommended-blue.svg)
* Pi Zero

![Supported](https://img.shields.io/badge/-Experimental-yellow.svg) ![Debian](https://img.shields.io/badge/ARM64-Debian%20Buster-yellow.svg) ![Swift](https://img.shields.io/badge/Swift%204--yellow.svg)
* Pi 3B 

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

See the page on [Setting up the Raspberry Pi](Docs/HardwareSetup.md) for details.

### Installing RPiLight

RPiLight includes a bootstrapping script that walks you through getting things setup from a freshly flashed OS:
```
source <(curl -s https://raw.githubusercontent.com/Kaiede/RPiLight/master/bootstrap.sh)
```

Once installed, if you installed the package, you can update using this (not supported on Pi Zero):
```
sudo apt-get update
sudo apt-get install rpilight
```

If updating from source:
```
./build.sh [stable | latest] install
```

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
* [SwiftyGPIO](https://github.com/uraimo/SwiftyGPIO) [\(Fork\)](https://github.com/Kaiede/SwiftyGPIO) - Patched with improved GPIO PWM behavior.
* [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON) [\(IBM-Swift Fork\)](https://github.com/IBM-Swift/SwiftyJSON) - The better way to deal with JSON data in Swift.

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.

## Authors

* **Adam Thayer** - *Initial work* - [Kaiede](https://github.com/Kaiede)

See also the list of [contributors](https://github.com/Kaiede/RPiLight/contributors) who participated in this project.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details
