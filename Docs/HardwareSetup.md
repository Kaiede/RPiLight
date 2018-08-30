# Setting up the Raspberry Pi

### Picking Hardware

This project is tested on a Raspberry Pi Zero W, using Raspbian Stretch Lite. It is recommended that you either solder on a 40-pin header, or buy the Zero WH that includes a pre-soldered header. 

RPiLight supports the 2 built-in PWM channels, but if you need more, it is compatible with the PCA9685 PWM controller. It is recommended that you get an existing board like the [Adafruit 16-Channel PWM Bonnet](https://www.adafruit.com/product/3416)

When it comes to driving your lights, there are a couple different options. Some Meanwell LDD drivers like the LDD-H work fine with 3.3V PWM input, and can be used directly. Other Meanwells like the LDD-L need a 5V output. 

Another option for driving lights like Beamswork or Twinstar lights are MOSFET Trigger Switches. The ones I use can be found cheaply on e-bay, and [look a bit like this](Assets/mosfet_trigger_switch.jpg). You will find it easier if you solder on headers, and will need to track down the correct power plugs so they can be between the power supply of the light, and the light itself. For the Twinstar, you can get 2.5mm ID x 5.5mm OD DC power plugs (male and female). They hook up much like the Current USA ramp timers. 

It is recommended that you research how you intend to drive your lights and check your work before proceeding. This setup is specific to your situation, and is hard to cover in a simple guide.

### Wiring Up the Pi

When using the built-in PWM channels, it's recommended to [use a pinout guide](https://pinout.xyz). RPiLight currently supports two channels using the hardware: PWM0 on GPIO18 and PWM1 on GPIO19. These are pins 12 and 35. You will also want to use the ground pins next to these pins when wiring things up. 

When using the Adafruit PWM bonnet, the channels are marked 0-15 on the board, and these will map the same way in your configuration of RPiLight, making it easier. 

### Bootstrapping the Raspberry Pi

These instructions assume you are starting fresh with a clean Micro SD card, and want to make this Raspberry Pi headless. 

Start by [getting Rasbian Lite](https://www.raspberrypi.org/downloads/raspbian/), and writing the image to an SD card. [For headless setup, these instructions](https://www.raspberrypi.org/documentation/configuration/wireless/headless.md) should point you in the right direction for setting up wireless networking, and turning on SSH. 

Additionally, [these instructions](https://hackernoon.com/raspberry-pi-headless-install-462ccabd75d0) are also useful for setting up a headless Raspberry Pi.

> WARNING: The Raspberry Pi's Wireless is not bullet-proof. Raspbian Stretch is better than earlier versions, but it tends to have major problems with misconfigured networks that Windows or macOS doesn't have. If you are having problems with host down or similar errors, I recommend checking your network configuration. IPv6 configured incorrectly, wrong wireless channels, etc.