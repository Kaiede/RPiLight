#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
#	__init__.py
#
#	Package: PiLight
#	Module: PWM
#	Copyright 2018 <user@biticus.net>
#

import simulator

# Constants for Modes
MODE_SIMULATED = 1
MODE_DMA = 2
#MODE_EXTERNAL = 3
#MODE_GPIO = 4

# Startup
_activeModule = None
def Startup(mode):
	global _activeModule
	if mode == MODE_SIMULATED:
		_activeModule = simulator.StartupPWM()
	else:
		raise ValueError('mode')

	return

# Shutdown
def Shutdown():
	global _activeModule
	if _activeModule is not None:
		_activeModule.Shutdown()
	else:
		raise ValueError('_activeModule')

	return

# Create Channel
def CreateChannel(name):
	global _activeModule
	if _activeModule is None:
		raise ValueError('_activeModule')

	return _activeModule.CreateChannel(name)

