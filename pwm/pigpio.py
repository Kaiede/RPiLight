#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
#	pigpio.py
#
#	Package: PiLight
#	Module: PWM
#	Copyright 2018 <user@biticus.net>
#

import pigpio

# Library scales this to however many steps actually exist
#
# At 960Hz, we get about 250k steps. Which is pretty excessive, IMO. 
UNITS_PER_CYCLE = 1000000
PWM_FREQUENCY = 960 # Hz

def StartupPWM():
	return PIGPIOModule()

class PIGPIOModule:
	# m_pigpio - Object - PIGPIO API Instance
	# m_gpioChannels - Array - Available Channels

	def __init__(self):
		self.m_gpioChannels = self.SetupGpioChannels()
		self.m_pigpio = pigpio.pi()

		print "Hardware PWM Initialized"

	def Shutdown(self):
		self.m_pigpio.stop()

		print "Hardware PWM Shutdown"

	def CreateChannel(self, name):
		gpioPin = self.NextAvailableChannel()
		if gpioPin is None:
			raise ValueError('gpioPin')

		channel = PIGPIOChannel(name, self.m_pigpio, gpioPin)
		self.m_gpioChannels[ gpioPin ] = channel
		return channel

	##### Internal
	def SetupGpioChannels(self):
		gpioChannels = OrderedDict()
		gpioChannels[ 18 ] = None
		gpioChannels[ 19 ] = None
		return gpioChannels

	def NextAvailableChannel(self):
		for gpioPin, channel in self.m_gpioChannels.items():
			if channel is None:
				return gpioPin

		return None


class PIGPIOChannel:
	# m_brightness
	# m_name
	# m_gpioPin
	# m_pigpio

	def __init__(self, name, pigpio, gpioPin):
		self.m_name = name if not None else ""
		self.m_pigpio = pigpio
		self.m_gpioPin = gpioPin
		print "[%s] Channel Created" % self.m_name

		self.SetBrightness(0.0)

	def Shutdown(self):
		return

	def Brightness(self):
		return 0

	def SetBrightness(self, brightness):
		self.m_brightness = BoundValue(brightness, 0.0, 100.0)

		brightnessUnits = int(round(self.m_brightness * UNITS_PER_CYCLE / 100.0))
		self.m_pigpio.hardware_PWM(self.m_gpioPin)

		print "[%s] Brightness Changed to: %0.1f" % (self.m_name, self.m_brightness)
		return

	def Name(self):
		return 

	def SetName(self, name):
		print "[%s] Channel Name Changed to: %s" % (self.m_name, name)
		self.m_name = name
		return