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

from constants import *


def StartupPWM(channelCount):
	return SimulatedModule(channelCount)


def CreateChannelArray(count):
	count = pwmlib.BoundValue(count, 1, 16)

	channelArray = []
	for x in range(count):
		channelArray.append("SIM%02d" % (x+1))

	return channelArray


class SimulatedModule(pwmlib.Module, object):
	def __init__(self, channelCount):
		channels = CreateChannelArray(channelCount)
		super(SimulatedModule, self).__init__(channels)


	def CreateChannel(self, token):
		return SimulatedChannel(token)


class SimulatedChannel(pwmlib.Channel, object):
	def __init__(self, token):
		super(SimulatedChannel, self).__init__(token)


	def OnLuminanceChanged(self, luminance):
		# Should this still do something?
		return