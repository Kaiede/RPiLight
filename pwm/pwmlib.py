#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
#	pwmlib.py
#
#	Package: PiLight
#	Module: PWM
#	Copyright 2018 <user@biticus.net>
#

import json
import os
import sets

from collections import OrderedDict

from constants import *


#
# Helpers to Read Configuration
#
def ValidateHardwareConfig(configDict):
	#
	# Validate PWM Mode
	#
	# Must be provided

	validModes = sets.Set([ MODE_SIMULATED, MODE_PIGPIO ])
	if not configDict.has_key(KEY_PWM_MODE):
		raise ValueError(KEY_PWM_MODE)

	if not configDict[KEY_PWM_MODE] in validModes:
		raise ValueError(KEY_PWM_MODE)

	#
	# Validate Channel Count
	#
	# Default to 1 channel if not provided

	if not configDict.has_key(KEY_CHANNELS):
		configDict[KEY_CHANNELS] = 1

	if not isinstance(configDict[KEY_CHANNELS], (int, long)):
		raise ValueError(KEY_CHANNELS)

	return configDict


def GetConfigurationDir():
	scriptPath = os.path.realpath(__file__)
	scriptDir = os.path.dirname(scriptPath)
	configDir = os.path.join("config")
	return configDir


def ReadConfiguration(configFile):
	hardwareConfig = {}
	configPath = os.path.join(GetConfigurationDir(), configFile)

	if not os.path.isfile(configPath):
		raise ValueError('configFile')

	with open(configPath, 'r') as infile:
		hardwareConfig = json.load(infile)

	return ValidateHardwareConfig(hardwareConfig)

#
# Module / Channel Base Classes
#

def BoundValue(value, minValue, maxValue):
	value = min(maxValue, value)
	value = max(minValue, value)
	return value


class Module:
	# m_channels - Dictionary - Token:Channel

	def __init__(self, channelTokens):
		self.RegisterChannels(channelTokens)

		print "PWM Initialized"
		print "Channels: " + str(channelTokens)
		print 


	def Shutdown(self):
		for token, channel in self.m_channels.items():
			if channel is not None:
				channel.Shutdown

		self.m_channels = None

		print
		print "PWM Shutdown"


	def RegisterChannels(self, channelTokens):
		self.m_channels = OrderedDict()
		for token in channelTokens:
			self.m_channels[token] = None


	def GetValidTokens(self):
		# WARNING: Only works in Python 2
		return self.m_channels.keys()


	def GetChannel(self, token):
		if not self.m_channels.has_key(token):
			return None

		channel = self.m_channels[token]
		if channel is None:
			channel = self.CreateChannel(token)
			self.m_channels[token] = channel

		return channel


	def CreateChannel(self, token):
		return None



class Channel:
	# m_token - String - Channel ID Token
	# m_brightness - Number - Brightness in "Perceptual" Percentage. 0.0 - 1.0

	def __init__(self, token):
		if token is None:
			raise ValueException('token')

		print "[%s] Channel Created" % token		
		self.m_token = token
		self.SetBrightness(0.0)
		return


	def Token(self):
		return self.m_token


	def Shutdown(self):
		print "[%s] Channel Shutdown" % self.m_token		
		return


	def Brightness(self):
		return self.m_brightness


	def SetBrightness(self, brightness):
		self.m_brightness = BoundValue(brightness, 0.0, 1.0)
		self.OnBrightnessChanged(self.m_brightness)


	def OnBrightnessChanged(self, brightness):
		return