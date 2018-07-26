#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
#	adafruit.py
#
#	Package: PiLight
#	Module: PWM
#	Copyright 2018 <user@biticus.net>
#

import pwmlib

from importlib import import_module

from constants import *

UNITS_PER_CYCLE = 4096 # 12-bit resolution
MAX_FREQUENCY = PWM_BASE_FREQ * 3 # 1440 Hz

def StartupPWM(channelCount, frequency):
	return AdafruitModule(channelCount, frequency)

def CreateChannelDict(count):
	count = pwmlib.BoundValue(count, 1, 16)

	channelDict = {}
	for x in range(count):
		channelName = "AF-PWM%02d" % (x+1)
		channelDict[channelName] = x

	return channelDict


class AdafruitModule(pwmlib.Module, object):
	# m_channels - Dictionary Token:Int - Dictionary mapping token to channel number
	# m_adafruit - Module - Instance of the PCA9685 library
	# m_pca9685 - Object - Instance of the control object for PWM

	def __init__(self, channelCount, frequency):
		if frequency > MAX_FREQUENCY:
			raise ValueError('frequency')

		self.m_channels = CreateChannelDict(channelCount)

		self.m_adafruit = import_module("Adafruit_PCA9685")
		self.m_pca9685 = adafruit.PCA9685()
		self.m_pca9685.set_pwm_frequency(frequency)

		super(AdafruitModule, self).__init__(self.m_channels.keys(), frequency)


	def Shutdown(self):
		self.m_adafruit.software_reset()
		super(AdafruitModule, self).Shutdown()


	def CreateChannel(self, token):
		return AdafruitChannel(token, self.m_pca9685, self.m_channels[token])


class AdafruitChannel(pwmlib.Channel, object):
	# m_pca9685 - Object - Instance of the control object for PWM
	# m_pwmChannel - Integer - Which PWM channel are we controller

	def __init__(self, token, pca9685, pwmChannel):
		self.m_pca9685 = pca9685
		self.m_pwmChannel = pwmChannel
		super(AdafruitChannel, self).__init__(token)


	def OnLuminanceChanged(self, luminance):
		# Would be interesting to be able to stagger the on/off
		# times in the future. 16 channels is a lot to be turning on
		# all at the same time. Docs do warn of current surges when used
		# with servos.
		luminanceUnits = int(round(luminance * UNITS_PER_CYCLE))
		self.m_pca9685.set_pwm(self.m_pwmChannel, 0, luminanceUnits)
