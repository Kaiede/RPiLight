#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
#	pigpio.py
#
#	Package: PiLight
#	Module: PWM
#	Copyright 2018 <user@biticus.net>
#

import pwmlib

from collections import OrderedDict
from importlib import import_module

# Library scales this to however many steps actually exist
#
# At 960Hz, we get about 250k steps. Which is pretty excessive, IMO. 
UNITS_PER_CYCLE = 1000000
PWM_FREQUENCY = 960 # Hz

def StartupPWM():
	return PIGPIOModule()

GPIO_MAP = {
	"PWM-GPIO18" : 18,
	"PWM-GPIO19" : 19
}

class PIGPIOModule(pwmlib.Module, object):
	# m_pigpio - Object - Instance of the PIGPIO for PWM control

	def __init__(self):
		pigpio = import_module("pigpio")
		self.m_pigpio = pigpio.pi()

		super(PIGPIOModule, self).__init__(GPIO_MAP.keys())


	def Shutdown(self):
		self.m_pigpio.stop()
		super(PIGPIOModule, self).Shutdown()


	def CreateChannel(self, token):
		return PIGPIOChannel(token, self.m_pigpio, GPIO_MAP[token])


class PIGPIOChannel(pwmlib.Channel, object):
	# m_pigpio - Object - Instance of the PIGPIO for PWM control
	# m_gpioPin - Integer - Which GPIO Pin Are We Controlling?

	def __init__(self, token, pigpio, gpioPin):
		self.m_pigpio = pigpio
		self.m_gpioPin = gpioPin
		super(PIGPIOChannel, self).__init__(token)


	def OnBrightnessChanged(self, brightness):
		brightnessUnits = int(round(brightness * UNITS_PER_CYCLE))
		self.m_pigpio.hardware_PWM(self.m_gpioPin, PWM_FREQUENCY, brightnessUnits)
		print "[%s] Brightness Changed to: %0.1f" % (self.Token(), brightness * 100.0)
