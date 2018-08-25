# RPiLight

[![Build Status](https://travis-ci.org/Kaiede/RPiLight.svg?branch=master)](https://travis-ci.org/Kaiede/RPiLight)
![Swift](https://img.shields.io/badge/Swift-3.1.1-green.svg)
![Swift](https://img.shields.io/badge/Swift-4.1.2-orange.svg)
[![MIT license](http://img.shields.io/badge/license-MIT-brightgreen.svg)](http://opensource.org/licenses/MIT)

![Raspbian](https://img.shields.io/badge/OS-Raspbian%20Stretch-green.svg)

An Aquarium Light Controller for the Raspberry Pi

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

### Picking Hardware

This project is tested on a Raspberry Pi Zero W, using Raspbian Stretch Lite. It is recommended that you either solder on a 40-pin header, or buy the Zero WH that includes a pre-soldered header. 

RPiLight supports the 2 built-in PWM channels, but if you need more, it is compatible with the PCA9685 PWM controller. It is recommended that you get an existing board like the [Adafruit 16-Channel PWM Bonnet](https://www.adafruit.com/product/3416)

When it comes to driving your lights, there are a couple different options. Some Meanwell LDD drivers like the LDD-H work fine with 3.3V PWM input, and can be used directly. Other Meanwells like the LDD-L need a 5V output. 

Another option for driving lights like Beamswork or Twinstar lights are MOSFET Trigger Switches. The ones I use can be found cheaply on e-bay, and [look a bit like this](examples/mosfet_trigger_switch.jpg). You will find it easier if you solder on headers, and will need to track down the correct power plugs so they can be between the power supply of the light, and the light itself. For the Twinstar, you can get 2.5mm ID x 5.5mm OD DC power plugs (male and female). They hook up much like the Current USA ramp timers. 

It is recommended that you research how you intend to drive your lights and check your work before proceeding. This setup is specific to your situation, and is hard to cover in a simple guide.

### Wiring Up the Pi

When using the built-in PWM channels, it's recommended to [use a pinout guide](https://pinout.xyz). RPiLight currently supports two channels using the hardware: PWM0 on GPIO18 and PWM1 on GPIO19. These are pins 12 and 35. You will also want to use the ground pins next to these pins when wiring things up. 

When using the Adafruit PWM bonnet, the channels are marked 0-15 on the board, and these will map the same way in your configuration of RPiLight, making it easier. 

### Bootstrapping the Raspberry Pi

These instructions assume you are starting fresh with a clean Micro SD card, and want to make this Raspberry Pi headless. 

Start by [getting Rasbian Lite](https://www.raspberrypi.org/downloads/raspbian/), and writing the image to an SD card. [For headless setup, these instructions](https://www.raspberrypi.org/documentation/configuration/wireless/headless.md) should point you in the right direction for setting up wireless networking, and turning on SSH. 

Additionally, [these instructions](https://hackernoon.com/raspberry-pi-headless-install-462ccabd75d0) are also useful for setting up a headless Raspberry Pi.

> WARNING: The Raspberry Pi's Wireless is not bullet-proof. Raspbian Stretch is better than earlier versions, but it tends to have major problems with misconfigured networks that Windows or macOS doesn't have. If you are having problems with host down or similar errors, I recommend checking your network configuration. IPv6 configured incorrectly, wrong wireless channels, etc.

### Installing RPiLight

RPiLight includes a bootstrapping script that can install Swift and its dependencies, build, and install RPiLight for the first time.
```
source <(curl -s https://raw.githubusercontent.com/Kaiede/RPiLight/master/bootstrap.sh)
```

Once bootstrapped, it is possible to get the latest release and update using `build.sh`:
```
./build.sh stable install
```

## Configuring RPiLight

There are example configuration files in the [examples](examples) folder. These files are JSON-formatted. Let's go ahead and break down a specific example:

```
{
    "hardware" : {
        "board": "pizero",
        "pwmMode": "pca9685",
        "freq": 960,
        "channels": 8,
        "gamma": 1.8
    },
    
    "PWM00": {
        "minIntensity": 0.0025
        "schedule": [
            { "time": "08:00:00", "brightness": 0.0 },
            { "time": "08:30:00", "brightness": 0.25 },
            { "time": "12:00:00", "brightness": 0.25 },
            { "time": "14:00:00", "brightness": 0.50 },
            { "time": "18:00:00", "brightness": 0.50 },
            { "time": "20:00:00", "brightness": 0.10 },
            { "time": "22:30:00", "brightness": 0.10 },
            { "time": "23:00:00", "brightness": 0.0 }
        ]
    }
    
    <etc>
}
```

### Hardware

```
"hardware" : {
    "board": "pizero",
    "pwmMode": "pca9685",
    "freq": 960,
    "channels": 8,
    "gamma": 1.8
}
```

`board` is optional, and RPiLight will attempt to autodetect which Raspberry Pi board you are currently running for you. Only set it if you are getting errors that it should be set. It is used to tell RPiLight what hardware board you have, so that the `pwmMode` will work correctly. Valid options are: `pi1`, `pi2`, `pi3`, `pizero` or `desktop` (used for testing).

The `pwmMode` parameter tells RPiLight what PWM controller to use. It can be `simulated`, `hardware`, or `pca9685`. `simulated` is used for testing, and doesn't produce any output. `hardware` Uses the two internal PWM channels of the Raspberry Pi. `pca9685` uses the PCA9685 expansion over I2C on the default address, such as the Adafruit PCA9685 PWM Bonnet or Hat.

The `freq` parameter tells RPiLight what PWM frequency to use, in Hz. It must be a multiple of `480`: `480`, `960`, `1440`, `1920`, `2400`, or `2880`. For `adafruit`, the maximum value this can be is `1440`. Before picking a value, check to see what your LED drivers support. Meanwell LDD drivers can only go so high (1 KHz), and so RPiLight should not use a value over `960` when driving Meanwell LDDs. This value should not be used with `simulated`, as it has no meaning.

The `channels` parameter tells RPiLight how many channels to use. This can be `1-2` for `hardware`, and `1-16` for `simulated` and `pca9685`. This will always count up from the first channel, So if you pass in `4` to the `pca9685` controller, then you will get control over channels 0-3. 

`gamma` controls how brightness is converted into light intensity. The default is `1.8`. The human eye is closer to a gamma of around `2.5`, and most displays use a gamma of `2.2`. For many light controllers, the `gamma` can be considered to be `1.0` where brightness and intensity are the same thing. 

### Channel Configuration

```
"PWM00": {
        "minIntensity": 0.0025
        "schedule": [
        { "time": "08:00:00", "brightness": 0.0 },
        { "time": "08:30:00", "brightness": 0.25 },
        { "time": "12:00:00", "brightness": 0.25 },
        { "time": "14:00:00", "brightness": 0.50 },
        { "time": "18:00:00", "brightness": 0.50 },
        { "time": "20:00:00", "brightness": 0.10 },
        { "time": "22:30:00", "brightness": 0.10 },
        { "time": "23:00:00", "brightness": 0.0 }
    ]
}
```

Each channel has its settings and schedule bound to it. The channel token is used to name the settings/schedule assoicated with it, and depends on what hardware you are using.

Example Channel Tokens:
```
PWM00 to PWM15      : Adafruit PCA9685 Channels 0-15
PWM0-IO18           : Raspberry Pi PWM channel 0, on GPIO18
PWM1-IO19           : Raspberry Pi PWM channel 1, on GPIO19
SIM00 to SIM15      : Simulated Channels 0-15
```

`minIntensity` is used to adjust the cut-off of the light, and is optional. The default is `0.0`. This will treat the channel as off at any intensity level or lower. In this example it will turn of at `0.25%` intensity. Twinstar E lights start shutting off some LEDs but not others at around `0.2%` intensity, so this example provides a generally nicer transition for the lights when turning off or on.

The `schedule` array is where the work really happens. It is an array of events used to control the lights. In this example, the lights will be off at 8:00 am. Starting at 8:00 am, it will ramp up the lights until they are at 25% at 8:30 am. Then they will remain at 25% until 12:00 pm. Increase again to 50% brightness (28.7% intensity) by 2:00 pm until 6:00 pm. Then it shifts to 10% brightness by 8:00pm where it stays before ramping back to off between 10:30 pm and 11:00 pm.

`time` is a 24-hour time of the event, in hours, minutes, and seconds. So 8:15 pm would be 20:15:00. This time is in the local timezone set on the Raspberry Pi. 

`brightness` or `intensity` is how strong the light should be. One or the other must be used. Brightness is adjusted by gamma, while intensity directly sets the intensity of the light. The key here is that brightness takes into account how the light will *look* to the human eye, while intensity is a raw measure of the light being output. Use `brightness` when trying to set a light level pleasing to the eye. Use `intensity` if you are trying to hit a specific PAR/PPFD value for plants, which will make your math easier.

> For example, you are measuring 75 PAR/PPFD at the substrate at full power on your light, but want to get to 25 PAR/PPFD to keep the tank low light. The intensity of the light you want is `0.3333` (repeating). This will get you close to 25 PAR/PPFD. However, if I picked `0.3333` *brightness*, the result will be quite a bit lower. Instead, I want `0.5431660741` when using brightness: `intensity = brightness ^ gamma`. In this case: `1/3 = 0.5431660741 ^ 1.8`. So in this case, it does make a lot more sense to simply set the power for planted tanks using intensity, where you can simply calculate the percentage directly. 

In both cases, changes in the light level will be calculated as brightness to make the shift appear natural to the eye.

### Testing Your Hardware / Schedule

The `--preview` option was meant to test hardware configurations with simple ramps:
```
cd /opt/rpilight
RPiLight --preview <config.json>
```

This file is expected to be in the `./config/` directory, and by default it will look for `./config/config.json`. For now, it is required to be root to copy the file to the service's config directory: `sudo cp <myfile> /opt/rpilight/config/config.json`. 

You should first make sure the service is stopped before running previews to avoid getting weird results. See "Starting the Daemon" below.

### Starting the Daemon

The install script will do most of the work, so you should only need to start it using `systemctl`.
```
sudo systemctl start rpilight
```

If you need to restart the service after making changes to the schedule:
```
sudo systemctl restart rpilight
```

Or stop it to run previews:
```
sudo systemctl stop rpilight
```

## Built With

* [SwiftyGPIO](https://github.com/uraimo/SwiftyGPIO) [\(Fork\)](https://github.com/Kaiede/SwiftyGPIO) - Patched with improved GPIO PWM behavior.
* [Moderator](https://github.com/kareman/Moderator) [\(Fork\)](https://github.com/Kaiede/Moderator) - Modified to build for Swift 3 & 4.
* [PCA9685](https://github.com/Kaiede/PCA9685) - Swift Library for PCA9685 PWM Module.

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.

## Authors

* **Adam Thayer** - *Initial work* - [Kaiede](https://github.com/Kaiede)

See also the list of [contributors](https://github.com/Kaiede/RPiLight/contributors) who participated in this project.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details
