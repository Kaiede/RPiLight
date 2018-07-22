#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
#	__init__.py
#
#	Package: PiLight
#	Module: PWM
#	Copyright 2018 <user@biticus.net>
#

from importlib import import_module

# Modes Supported
#
# Simulated:
#   Doesn't provide any output, it is used for testing.
# RPIO:
#   Uses the RPIO library to provide DMA-timed output.
#   16 Channels
#   500Hz PWM Frequency, 2000 dimming steps.
# PIGPIO:
#   Uses the PIGPIO library and daemon to provide hardware support.
#   2 Channels
#   960Hz PWM Frequency, Maaaany dimming steps.

# Constants for Modes
MODE_SIMULATED = 1
MODE_RPIO = 2
MODE_PIGPIO = 3
#MODE_EXTERNAL = 3

# Startup
_activeModule = None
def Startup(mode):
	global _activeModule
	selectedModule = None

	if mode == MODE_SIMULATED:
		selectedModule = import_module(".simulator", __package__)
	elif mode == MODE_RPIO:
		selectedModule = import_module(".rpio", __package__)
	elif mode == MODE_PIGPIO:
		selectedModule = import_module(".pigpio", __package__)
	else:
		raise ValueError('mode')

	if selectedModule is not None:
		_activeModule = selectedModule.StartupPWM()
	else:
		raise ValueError('_activeModule')

	return

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

