#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
#	__init__.py
#
#	Package: PiLight
#	Module: PWM
#	Copyright 2018 <user@biticus.net>
#

import pwmlib

from importlib import import_module

#
# Expose These Directly to Callers
#
from constants import *


# Startup
_activeModule = None
def Startup(mode, channelCount = 1, frequency = PWM_BASE_FREQ):
	global _activeModule
	selectedModule = None

	validModules = {
		MODE_SIMULATED : ".simulator",
		MODE_PIGPIO : ".pigpio",
		MODE_ADAFRUIT : ".adafruit"
	}

	mode = mode.lower()
	if validModules.has_key(mode):
		selectedModule = import_module(validModules[mode], __package__)
	else:
		raise ValueError('mode')

	if selectedModule is not None:
		_activeModule = selectedModule.StartupPWM(channelCount, frequency)
	else:
		raise ValueError('_activeModule')

	return

# Startup With Config
def StartupWithConfigFile(configFile):
	config = pwmlib.ReadConfiguration(configFile)
	return Startup(config[KEY_PWM_MODE], channelCount = config[KEY_CHANNELS], frequency = config[KEY_FREQUENCY])

# Shutdown
def Shutdown():
	global _activeModule
	if _activeModule is not None:
		_activeModule.Shutdown()
	else:
		raise ValueError('_activeModule')

	return

# Get Tokens
def GetValidTokens():
	global _activeModule
	if _activeModule is None:
		raise ValueError('_activeModule')

	return _activeModule.GetValidTokens()	

# Get Channel
def GetChannel(token):
	global _activeModule
	if _activeModule is None:
		raise ValueError('_activeModule')

	return _activeModule.GetChannel(token)

