# Configuring the Light Schedule

There are example configuration files in the [examples](https://github.com/Kaiede/RPiLight/examples) folder. These files are JSON-formatted, and are split into two components: The hardware configuration, and the schedule.

## Hardware Configuration

Let's look at an example that uses a PWM HAT (config-example-pca9685.json):

```
{
    "user": "pi",
    "board": "raspberryPi",

    "controllers": [
        {
            "type": "hardware",
            "frequency": 960,
            "gamma": 2.2,
            "channels": {
                "primary": 0,
                "secondary": 1
            }
        }
    ]
}
```

* `user` can be any valid user on the OS. `pi` is recommended.

This is the account to run the service as. This should **not** be `root`, as that has too many permissions. Instead, the service starts as root, and then switches to this user once it has mapped in any hardware it needs extra permissions for, such as the PWM hardware.

* `board` can currently only be `raspberryPi`. 

* `gamma` can be between `1.0` and `3.0`. Default is `1.8`

This controls how brightness is converted into light intensity. The human eye is closer to a gamma of around `2.5`, and most displays use a gamma of `2.2`. If using a gamma of `1.0`, then `brightness` and `intensity` are the same thing.

### Controllers

This is an array of hardware you want to control. It's possible to have multiple controllers handling many channels of lighting.

```
{
    "type": "raspberryPwm",
    "frequency": 960,
    "address": 0x61,
    "channels": {
        "primary": 0,
        "secondary": 1
    }
}
```

* `type` can be `raspberryPwm`, `pca9685`, `mcp4725` or `simulated`

`raspberryPwm` uses the two PWM channels included with the Raspberry Pi. `pca9685` uses the PCA9685 I2C PWM chip, available from Adafruit as the PCA9685 PWM/Servo Bonnet or Hat. `mcp4725` is meant for use with 0-10V boards that use the MCP4725 I2C DAC. `simulated` is used for testing.

* `frequency` must be between `480` and `1500` (Hz). If `pwmMode = hardware` the max is `16000` (16 kHz). Default is `480`

This is the frequency of PWM to use. Lower values produce more flicker, but not all light drivers can take higher values. Before picking a value, check to see what your LED drivers support. This setting should not be used with `simulated`, as it has no meaning.

> ex. Meanwell LDD drivers can only go so high (1 KHz), and so RPiLight should not use a value over `960` when driving Meanwell LDDs. 

* `address` is used by the `pca9685` and `mcp4725` types that use I2C, if using multiple boards, or non-default I2C addresses.

This doesn't normally need to be put into the configuration file. But it allows someone to use a non-default I2C address for these chips 

* `channels` is a dictionary of names being mapped to channels for the controller.

This is where you map numbered channels to a more friendly name you can reference in your schedule. This friendly name is also what will be used in any sort of logging or remote control, to make it easier to identify.

Valid indexes are:
* `raspberryPwm`: 0 or 1
* `pca9685`: 0-15
* `mcp4725`: 0
* `simulated`: 0 and up.

## Schedule

The schedule.json file contains the schedule for the lighting. It doesn't contain any information related to the hardware, so it can be configured separately from the underlying hardware configuration, making it easier to share settings.

### Channel Configuration

```
"primary": {
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

Each channel has its settings and schedule bound to it. The channel name is used to name the settings/schedule assoicated with it, and depends on what you named your channels in the config.json file earlier.

`minIntensity` is used to adjust the cut-off of the light, and is optional. The default is `0.0`. This will treat the channel as off at any intensity level or lower. In this example it will turn of at `0.25%` intensity. Twinstar E lights start shutting off some LEDs but not others at around `0.2%` intensity, so this example provides a generally nicer transition for the lights when turning off or on.

The `schedule` array is where the work really happens. It is an array of events used to control the lights. In this example, the lights will be off at 8:00 am. Starting at 8:00 am, it will ramp up the lights until they are at 25% at 8:30 am. Then they will remain at 25% until 12:00 pm. Increase again to 50% brightness (28.7% intensity) by 2:00 pm until 6:00 pm. Then it shifts to 10% brightness by 8:00pm where it stays before ramping back to off between 10:30 pm and 11:00 pm.

* `time` is a 24-hour time.

This time is in the local timezone set on the Raspberry Pi.

> ex. 8:15 pm would be 20:15:00.

* `brightness` or `intensity` is between `0.0` (off) and `1.0` (fully on)

This is how strong the light should be. One or the other must be used. Brightness is adjusted by gamma, while intensity directly sets the intensity of the light. The key here is that brightness takes into account how the light will *look* to the human eye, while intensity is a raw measure of the light being output. Use `brightness` when trying to set a light level pleasing to the eye. Use `intensity` if you are trying to hit a specific PAR/PPFD value for plants, which will make your math easier.

> For example, you are measuring 75 PAR/PPFD at the substrate at full power on your light, but want to get to 25 PAR/PPFD to keep the tank low light. The intensity of the light you want is `0.3333` (repeating). This will get you close to 25 PAR/PPFD. However, if I picked `0.3333` *brightness*, the result will be quite a bit lower. Instead, I want `0.5431660741` when using brightness: `intensity = brightness ^ gamma`. In this case: `1/3 = 0.5431660741 ^ 1.8`. So in this case, it does make a lot more sense to simply set the power for planted tanks using intensity, where you can simply calculate the percentage directly. 

In both cases, changes in the light level will be calculated as brightness to make the shift appear natural to the eye.

### Lunar Cycle 

```
"lunarCycle": {
    "start": "21:00:00",
    "end": "07:00:00",
}
```

The lunar cycle feature makes it possible to have light during a night period that follows the cycle of the moon phases. It works by taking your existing schedule, and adjusting it based on the current phase of the moon between `start` and `end`. 

Using the above example, I make my lights drop down to 4% brightness at 9:00pm to 7:00am. What will happen is that if the moon is full, the lights will remain at 4% all night. If the moon is half full, the lights will be brought down to 2% during the night. If the moon is new, the lights will be off. 

The feature doesn't currently take moonrise or moonset into account. 

### Testing Your Hardware / Schedule

The `--preview` option was meant to test hardware configurations with simple ramps:
```
cd /opt/rpilight
RPiLight --preview
```

This file is expected to be in the `./config/` directory, and by default it will look for `./config/config.json` for the hardware configuration, and `./config/schedule.json` for the schedule. For now, it is required to be root to copy either file to the service's config directory: `sudo cp <myfile> /opt/rpilight/config/config.json`. 

You should first make sure the service is stopped before running previews to avoid getting weird results.
