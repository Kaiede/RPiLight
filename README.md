# RPiLight

An Aquarium Light Controller for the Raspberry Pi

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

### Picking Hardware

This project is tested on a Raspberry Pi Zero W, using Raspbian Stretch Lite. It is recommended that you either solder on a 40-pin header, or buy the Zero WH that includes a pre-soldered header. 

RPiLight supports the 2 built-in PWM channels, but if you need more, it is compatible with the PCA9685 PWM controller. It is recommended that you get an existing board like the [Adafruit 16-Channel PWM Bonnet](https://www.raspberrypi.org/documentation/configuration/wireless/headless.md)

When it comes to driving your lights, there are a couple different options. Some Meanwell LDD drivers like the LDD-H work fine with 3.3V PWM input, and can be used directly. Other Meanwells like the LDD-L need a 5V output. 

It is recommended that you research how you intend to drive your lights and check your work before proceeding.

### Wiring Up the Pi

When using the built-in PWM channels, it's recommended to [use a pinout guide](https://pinout.xyz). RPiLight currently supports two channels using the hardware: PWM0 on GPIO18 and PWM1 on GPIO19. These are pins 12 and 35. You will also want to use the ground pins next to these pins when wiring things up. 

When using the Adafruit PWM bonnet, the channels are marked 0-15 on the board, and in 

### Bootstrapping the Raspberry Pi

These instructions assume you are starting fresh with a clean Micro SD card, and want to install . 

Start by [getting Rasbian Lite](https://www.raspberrypi.org/downloads/raspbian/), and writing the image to an SD card. [For headless setup, these instructions](https://www.raspberrypi.org/documentation/configuration/wireless/headless.md) should point you in the right direction for setting up wireless networking, and turning on SSH. 

Additionally, [these instructions](https://hackernoon.com/raspberry-pi-headless-install-462ccabd75d0) are also useful for setting up a headless Raspberry Pi.

> WARNING: The Raspberry Pi's Wireless is not bullet-proof. It is recommended to also [turn off wireless power management](https://tosbourn.com/stop-wireless-turning-off-raspberry-pi/) once it is setup and booted.

### Installing RPiLight


### Configuring RPiLight Hardware

There are example configuration files in the [example](examples) folder. These files are JSON-formatted. Let's go ahead and break down one of those examples:

```
{
	"pwmMode": "adafruit",
	"freq": 960,
	"channels": 8
}
```

The `pwmMode` parameter tells RPiLight what PWM controller to use. It can be `simulated`, `pigpio`, or `adafruit`. `simulated` is used for testing, and doesn't produce any output. `pigpio` Uses the two internal PWM channels of the Raspberry Pi. `adafruit` uses the PCA9685 expansion over I2C on the default address.

The `freq` parameter tells RPiLight what PWM frequency to use, in Hz. It must be a multiple of `480`: `480`, `960`, `1440`, `1920`, `2400`, or `2880`. For `adafruit`, the maximum value this can be is `1440`. Before picking a value, check to see what your LED drivers support. Meanwell LDD drivers can only go so high (1 KHz), and so RPiLight should not use a value over `960` when driving Meanwell LDDs. This value should not be used with `simulated`, as it has no meaning.

The `channels` parameter tells RPiLight how many channels to use. This can be `1-2` for `pigpio`, and `1-16` for `simulated` and `adafruit`. This will always count up from the first channel, So if you pass in `4` to the `adafruit` controller, then you will get control over channels 0-3. 

### Configuring RPiLight Schedule

There are example schedule files in the [example](examples) folder. These files are JSON-formatted. Let's go ahead and break down one of those examples:

```
{
	"channels" : [
		{ "token": "AF-PWM00", "name" : "Twinstar 600E" }
	],

	"schedule" : [
		{
			"time" : "08:00:00",
			"channels" : [
				{ "token": "AF-PWM00", "brightness": 0.0 }
			]
		},
		{
			"time" : "08:30:00",
			"channels" : [
				{ "token": "AF-PWM00", "brightness": 0.25 }
			]
		},
		{
			"time" : "12:00:00",
			"channels" : [
				{ "token": "AF-PWM00", "brightness": 0.25 }
			]
		},

		<etc>
	]
}
```

The `channels` array at the top is currently not used. In the future it will be used to map a channel token to a friendly name for logging and display.

The `schedule` array is where the work really happens. It is an array of events used to control the lights. Inside each event, we have two children:

`time` is a 24-hour time of the event, in hours, minutes, and seconds. So 8:15pm would be 20:15:00. This time is in the local timezone set on the Raspberry Pi. 

This internal `channels` array contains items with a `token` and a `brightness` value. The token is short-hand for the channel 

Example Channel Tokens:
```
AF-PWM
```

## Built With

* [Python](https://www.python.org)
* [pigpio](http://abyz.me.uk/rpi/pigpio/) - Hardware PWM Support
* [Adafruit-PCA9685](https://github.com/adafruit/Adafruit_Python_PCA9685) - Expansion PWM Support

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.

## Authors

* **Adam Thayer** - *Initial work* - [Kaiede](https://github.com/Kaiede)

See also the list of [contributors](https://github.com/Kaiede/RPiLight/contributors) who participated in this project.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details
