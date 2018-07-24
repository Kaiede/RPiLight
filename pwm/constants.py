#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
#	constants.py
#
#	Package: PiLight
#	Module: PWM
#	Copyright 2018 <user@biticus.net>
#


#
# Module Definitions
#
# Simulated:
#   Doesn't provide any output, it is used for testing.
# PIGPIO:
#   Uses the PIGPIO library and daemon to provide hardware support.
#   2 Channels
#   960Hz PWM Frequency, Maaaany dimming steps.
# Adafruit:
#   Uses the Adafruit Servo/PWM Hat/Bonnet.
#   16 Channels
#   1440Hz Max PWM Frequency, 4096 dimming steps.

MODE_SIMULATED = "simulated"
MODE_PIGPIO = "pigpio"
#MODE_ADAFRUIT = "adafruit"


#
# Constants for Hardware Config JSON
#
KEY_PWM_MODE = "pwmMode"
KEY_CHANNELS = "channels"

#
# Reasonable Gamma Value
#
GAMMA_VALUE = 2.2