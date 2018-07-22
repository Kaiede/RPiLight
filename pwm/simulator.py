#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
#	simulator.py
#
#	Package: PiLight
#	Module: PWM
#	Copyright 2018 <user@biticus.net>
#

import pwmlib

def StartupPWM():
	return SimulatedModule()


class SimulatedModule(pwmlib.Module, object):
	def __init__(self):
		super(SimulatedModule, self).__init__([ "SIM1", "SIM2" ])


	def CreateChannel(self, token):
		return SimulatedChannel(token)


class SimulatedChannel(pwmlib.Channel, object):
	def __init__(self, token):
		super(SimulatedChannel, self).__init__(token)


	def OnBrightnessChanged(self, brightness):
		# Convert the brightness to a percentage before writing out.
		print "[%s] Brightness Changed to: %0.1f" % (self.Token(), brightness * 100.0)
		return