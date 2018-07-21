#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
#	dma.py
#
#	Package: PiLight
#	Module: PWM
#	Copyright 2018 <user@biticus.net>
#

from collections import OrderedDict
from RPIO import PWM

# Microseconds/Cycle
UNITS_PER_CYCLE = 2000

class DMAModule:
	# m_dmaChannel - Int - RPi DMA Channel In Use
	# m_gpioChannels - Dict - GPIO Pins Available for PWM Channels, and Active Channel Mapping

	def __init__(self):
		self.m_dmaChannel = 0
		self.m_gpioChannels = self.SetupGpioChannels()

		PWM.setup(pulse_incr_us = 1)
		PWM.init_channel(self.m_dmaChannel, subcycle_time_us = UNITS_PER_CYCLE)

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

		channel = DMAPWMChannel(name, self.m_dmaChannel, gpioPin)
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


class DMAPWMChannel:
	# m_brightness
	# m_name
	# m_dmaChannel
	# m_gpioPin

	def __init__(self, name, dmaChannel gpioPin):
		self.m_name = name if not None else ""
		self.m_dmaChannel = dmaChannel
		self.m_gpioPin = gpioPin
		print "[%s] Channel Created" % self.m_name

		self.SetBrightness(0.0)

	def Shutdown(self):
		PWM.clear_channel_gpio(self.m_dmaChannel, self.m_gpioPin)

	def Brightness(self):
		return 0

	def SetBrightness(self, brightness):
		self.m_brightness = BoundValue(brightness, 0.0, 100.0)

		brightnessMicrosec = int(round(self.m_brightness * UNITS_PER_CYCLE / 100.0))

		PWM.clear_channel_gpio(self.m_dmaChannel, self.m_gpioPin)
		PWM.add_channel_pulse(self.m_dmaChannel, self.m_gpioPin, 0, brightnessMicrosec)

		print "[%s] Brightness Changed to: %0.1f" % (self.m_name, self.m_brightness)
		return

	def Name(self):
		return 

	def SetName(self, name):
		print "[%s] Channel Name Changed to: %s" % (self.m_name, name)
		self.m_name = name
		return