# RPiLight

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

Installing Prerequisties:
```
sudo apt-get install python-pip pigpio
sudo pip install adafruit-pca9685 pigpio
```

It is also recommended to install git:
```
sudo apt-get install git
```

If you are using the built-in PWM channels, you now need to kick off pigpiod and enable it to launch on boot:
```
sudo systemctl enable pigpiod.service
sudo systemctl start pigpiod.service
```

Now, it's time to get RPiLight installed. It's recommended to clone it from GitHub to make updates easier. When using git, you can simply use `git pull` to update to the latest version.
```
cd ~
git clone https://github.com/Kaiede/RPiLight.git
```

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

Once you have the configuration file set. Make a directory in the RPiLight folder called `config`, and place it in there. You can also copy an example to the `config/` directory and modify it to suit your needs.

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

`time` is a 24-hour time of the event, in hours, minutes, and seconds. So 8:15 pm would be 20:15:00. This time is in the local timezone set on the Raspberry Pi. 

This internal `channels` array contains items with a `token` and a `brightness` value. The `token` is short-hand for the channel name, and depends on what PWM controller you are using. Examples are below. The `brightness` is a floating point value between `0` and `1.0`, with `1.0` being fully on, and `0` being off. 

Example Channel Tokens:
```
AF-PWM00 - AF-PWM15 : Adafruit Channels 0-15
PWM0-GPIO18 		: pigpio PWM channel 0, on GPIO18
PWM1-GPIO19 		: pigpio PWM channel 1, on GPIO19
SIM00 - SIM15		: Simulated Channels 0-15
```

In this example, the lights will be off at 8:00 am. Starting at 8:00 am, it will ramp up the lights until they are at 25% at 8:30 am. Then they will remain at 25% until 12:00 pm. 

### Testing Your Hardware / Schedule

`test.py` was meant to test hardware configurations with simple ramps:

```
python test.py <testConfig.json>
```

You can use the `preview.py` script to test your schedule:

```
python preview.py <testConfig.json> <testSchedule.json>
```

In both cases, they look in the `config/` directory for you. You don't need a full path to the file, just the name of the file. By default, they use `testConfig.json` and `testSchedule.json` if no arguments are provided. 

### Starting the Daemon

The `daemon.py` script will run indefinitely, looping the schedule each day. It uses `config.json` and `schedule.json`, keeping the files separate from testing and previewing. 

Setting up the service to boot automatically takes a couple of steps. This will configure the service to start automatically at boot, and start it immediately:

```
sudo cp rpilight.service /lib/systemd/system
sudo systemctl enable rpilight.service
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

* [Python](https://www.python.org)
* [pigpio](http://abyz.me.uk/rpi/pigpio/) - Hardware PWM Support
* [Adafruit-PCA9685](https://github.com/adafruit/Adafruit_Python_PCA9685) - Expansion PWM Support

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.

## Authors

* **Adam Thayer** - *Initial work* - [Kaiede](https://github.com/Kaiede)

See also the list of [contributors](https://github.com/Kaiede/RPiLight/contributors) who participated in this project.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details
