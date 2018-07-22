#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
#	rpio.py
#
#	Package: PiLight
#	Module: PWM
#	Copyright 2018 <user@biticus.net>
#

from collections import OrderedDict
from RPIO import PWM

# RPIO has some issues with using really small subcycles. (2ms)
# To get the behavior we want, we need to do something a bit more
# drastic. So let's create a subcycle that RPIO likes, but then
# place multiple pulses inside it to get the resulting frequency
# we need.
#
# To keep this simple, a "zone" is an actual PWM cycle we want to
# create. A subcycle is the DMA channel's subcycle. The subcycle
# is split into zones.

# Microseconds/Zone
# Zones/DMA Subcycle
UNITS_PER_ZONE = 2000
ZONES_PER_SUBCYCLE = 2
UNITS_PER_SUBCYCLE = UNITS_PER_ZONE * ZONES_PER_SUBCYCLE

def StartupPWM():
	return RPIOModule()
	
def BoundValue(value, minValue, maxValue):
	value = min(maxValue, value)
	value = max(minValue, value)
	return value

class RPIOModule:
	# m_dmaChannel - Int - RPi DMA Channel In Use
	# m_gpioChannels - Dict - GPIO Pins Available for PWM Channels, and Active Channel Mapping

	def __init__(self):
		self.m_dmaChannel = 0
		self.m_gpioChannels = self.SetupGpioChannels()

		PWM.setup(pulse_incr_us = 1)
		PWM.init_channel(self.m_dmaChannel, subcycle_time_us = UNITS_PER_SUBCYCLE)

		print "DMA PWM Initialized"

	def Shutdown(self):
		for gpioPin, channel in self.m_gpioChannels.items():
			if channel is not None:
				channel.Shutdown()

		PWM.clear_channel(self.m_dmaChannel)
		PWM.cleanup()

		print "DMA PWM Shutdown"

	def CreateChannel(self, name):
		gpioPin = self.NextAvailableChannel()
		if gpioPin is None:
			raise ValueError('gpioPin')

		channel = RPIOChannel(name, self.m_dmaChannel, gpioPin)
		self.m_gpioChannels[ gpioPin ] = channel
		return channel

	##### Internal
	def SetupGpioChannels(self):
		gpioChannels = OrderedDict()
		gpioChannels[ 2 ] = None
		gpioChannels[ 3 ] = None
		gpioChannels[ 4 ] = None
		return gpioChannels

	def NextAvailableChannel(self):
		for gpioPin, channel in self.m_gpioChannels.items():
			if channel is None:
				return gpioPin

		return None


class RPIOChannel:
	# m_brightness
	# m_name
	# m_dmaChannel
	# m_gpioPin

	def __init__(self, name, dmaChannel, gpioPin):
		self.m_name = name if not None else ""
		self.m_dmaChannel = dmaChannel
		self.m_gpioPin = gpioPin
		print "[%s] Channel Created" % self.m_name

		# This is bad, but it forces the GPIO pin to be configured
		PWM.add_channel_pulse(self.m_dmaChannel, self.m_gpioPin, 0, 0)
		self.SetBrightness(0.0)

	def Shutdown(self):
		PWM.clear_channel_gpio(self.m_dmaChannel, self.m_gpioPin)

	def Brightness(self):
		return 0

	def SetBrightness(self, brightness):
		self.m_brightness = BoundValue(brightness, 0.0, 100.0)

		brightnessMicrosec = int(round(self.m_brightness * UNITS_PER_ZONE / 100.0))

		PWM.clear_channel_gpio(self.m_dmaChannel, self.m_gpioPin)
		for zone in range(0, ZONES_PER_SUBCYCLE):
			PWM.add_channel_pulse(self.m_dmaChannel, self.m_gpioPin, zone * UNITS_PER_ZONE, brightnessMicrosec)

		print "[%s] Brightness Changed to: %0.1f" % (self.m_name, self.m_brightness)
		return

	def Name(self):
		return 

	def SetName(self, name):
		print "[%s] Channel Name Changed to: %s" % (self.m_name, name)
		self.m_name = name
		return
