#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
#	simulator.py
#
#	Package: PiLight
#	Module: PWM
#	Copyright 2018 <user@biticus.net>
#



def StartupPWM():
	return SimulatedModule()

def BoundValue(value, minValue, maxValue):
	value = min(maxValue, value)
	value = max(minValue, value)
	return value

class SimulatedModule:
	def __init__(self):
		print "Simulated PWM Initialized"

	def Shutdown(self):
		print "Simulated PWM Shutdown"

	def CreateChannel(self, name):
		return SimulatedChannel(name)

class SimulatedChannel:
	def __init__(self, name):
		self.m_brightness = 0
		self.m_name = name if not None else ""
		print "[%s] Channel Created" % self.m_name

	def Brightness(self):
		return 0

	def SetBrightness(self, brightness):
		self.m_brightness = BoundValue(brightness, 0.0, 100.0)
		print "[%s] Brightness Changed to: %0.1f" % (self.m_name, self.m_brightness)
		return

	def Name(self):
		return 

	def SetName(self, name):
		print "[%s] Channel Name Changed to: %s" % (self.m_name, name)
		self.m_name = name
		return