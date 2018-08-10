# RPiLight

[![Build Status](https://travis-ci.org/Kaiede/RPiLight.svg?branch=master)](https://travis-ci.org/Kaiede/RPiLight)
![Swift](https://img.shields.io/badge/Swift-3.1.1-green.svg)
![Swift](https://img.shields.io/badge/Swift-4.1.2-green.svg)
[![MIT license](http://img.shields.io/badge/license-MIT-brightgreen.svg)](http://opensource.org/licenses/MIT)

![Raspbian](https://img.shields.io/badge/OS-Raspbian%20Stretch-green.svg)

An Aquarium Light Controller for the Raspberry Pi

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

### Picking Hardware

This project is tested on a Raspberry Pi Zero W, using Raspbian Stretch Lite. It is recommended that you either solder on a 40-pin header, or buy the Zero WH that includes a pre-soldered header. 

RPiLight supports the 2 built-in PWM channels, but if you need more, it is compatible with the PCA9685 PWM controller. It is recommended that you get an existing board like the [Adafruit 16-Channel PWM Bonnet](https://www.raspberrypi.org/documentation/configuration/wireless/headless.md)

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

> WARNING: The Raspberry Pi's Wireless is not bullet-proof. It is recommended to also [turn off wireless power management](https://tosbourn.com/stop-wireless-turning-off-raspberry-pi/) once it is setup and booted.

### Installing RPiLight

First, we will need to make sure git is installed.
```
sudo apt-get install git
```

Then, we can
```
cd ~
git clone https://github.com/Kaiede/RPiLight.git
cd RPiLight
./install.sh full
```

The `./install.sh full` command only needs to be run the first time an install is done, or during major updates, as it installs things that RPiLight requires using apt-get, and grabs the version of Swift needed to build. When making changes

When updating, you can use:
```
./install.sh update
```

This command pulls the latest source from GitHub, builds it, and installs it. 

## Configuring RPiLight

There are example configuration files in the [example](examples) folder. These files are JSON-formatted. Let's go ahead and break down one of those examples:

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

The `pwmMode` parameter tells RPiLight what PWM controller to use. It can be `simulated`, `hardware`, or `pca9685`. `simulated` is used for testing, and doesn't produce any output. `hardware` Uses the two internal PWM channels of the Raspberry Pi. `pca9685` uses the PCA9685 expansion over I2C on the default address, like the Adafruit PWM board.

The `freq` parameter tells RPiLight what PWM frequency to use, in Hz. It must be a multiple of `480`: `480`, `960`, `1440`, `1920`, `2400`, or `2880`. For `adafruit`, the maximum value this can be is `1440`. Before picking a value, check to see what your LED drivers support. Meanwell LDD drivers can only go so high (1 KHz), and so RPiLight should not use a value over `960` when driving Meanwell LDDs. This value should not be used with `simulated`, as it has no meaning.

The `channels` parameter tells RPiLight how many channels to use. This can be `1-2` for `hardware`, and `1-16` for `simulated` and `pca9685`. This will always count up from the first channel, So if you pass in `4` to the `pca9685` controller, then you will get control over channels 0-3. 

`gamma` controls how brightness is converted into light intensity. The default is `1.8`

### Per Channel Tweaks

```
"channels" : [
	{ "token": "PWM0-IO18", "minIntensity": 0.0025 }
],
```

For each channel you want to tweak, you add 

The `token` is short-hand for the channel name, and depends on what PWM controller you are using. Examples are below, in the "Schedule" section.

Currently, the only option available here is `minIntensity`. This sets a cut-off for the channel. If the intensity drops below this value for that channel, it will turn it off instead. A specific example is that Twinstar ES lights tend to start showing problems at around 0.2% intensity, where some of the LEDs shut off, but not others. By setting the `minIntensity` to 0.25%, the entire light will go off or come on at the same time.

Minimum intensity is also taken into account when turning the lights off or on during your schedule. It will adjust things for you so that the cutoff is reached as close to the point in time where you wanted the lights to turn off or come on as possible.

### Schedule

```
"schedule" : [
	{
		"time" : "08:00:00",
		"channels" : [
			{ "token": "PWM00", "brightness": 0.0 }
		]
	},
	{
		"time" : "08:30:00",
		"channels" : [
			{ "token": "PWM00", "brightness": 0.25 }
		]
	},
	{
		"time" : "12:00:00",
		"channels" : [
			{ "token": "PWM00", "brightness": 0.25 }
		]
	},

	<etc>
]
```

The `schedule` array is where the work really happens. It is an array of events used to control the lights. Inside each event, we have two children:

`time` is a 24-hour time of the event, in hours, minutes, and seconds. So 8:15 pm would be 20:15:00. This time is in the local timezone set on the Raspberry Pi. 

This internal `channels` array contains items with a `token` and a `brightness` or `intensity` value. The `token` is short-hand for the channel name, and depends on what PWM controller you are using. Examples are below. The `brightness` or `intensity` is a floating point value between `0` and `1.0`, with `1.0` being fully on, and `0` being off. Which you use depends on what the goal is. If the light is at 50%, using `brightness` will *look* like 50% brightness. Using `intensity` will give you 50% of the lumen/PAR output of the channel. If setting the level for plants, It is recommended to use `intensity`, but if setting the level for aesthetics, it is recommended to use `brightness`. To avoid confusion, it is best to create a schedule using one or the other, but not both. 

In both cases, changes in the light level will be calculated as brightness to make the shift appear natural to the eye.

Example Channel Tokens:
```
PWM00 - PWM15 		: Adafruit PCA9685 Channels 0-15
PWM0-IO18 			: Raspberry Pi PWM channel 0, on GPIO18
PWM1-IO19 			: Raspberry Pi PWM channel 1, on GPIO19
SIM00 - SIM15		: Simulated Channels 0-15
```

In this example, the lights will be off at 8:00 am. Starting at 8:00 am, it will ramp up the lights until they are at 25% at 8:30 am. Then they will remain at 25% until 12:00 pm. 

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
sudo systemctl start rpilight.service
```

If you need to restart the service after making changes to the schedule:
```
sudo systemctl restart rpilight.service
```

Or stop it to run previews:
```
sudo systemctl stop rpilight.service
```

## Built With

* SwiftyGPIO - Patched with improved GPIO PWM behavior.
* Moderator - Modified to build for Swift 3 & 4.
* [Adafruit-PCA9685](https://github.com/adafruit/Adafruit_Python_PCA9685) - Inspiration for PCA9685 implementation.

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.

## Authors

* **Adam Thayer** - *Initial work* - [Kaiede](https://github.com/Kaiede)

See also the list of [contributors](https://github.com/Kaiede/RPiLight/contributors) who participated in this project.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details
