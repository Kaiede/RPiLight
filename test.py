#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
#	test.py
#
#	Package: PiLight
#	Module: PiLight
#	Copyright 2018 <user@biticus.net>
#

import pwm

from time import sleep

pwm.Startup(pwm.MODE_SIMULATED)

channel1 = pwm.CreateChannel("Channel 1")
channel2 = pwm.CreateChannel("Channel 2")

brightnessLevel = 0.0
while (brightnessLevel <= 100.0):
	brightnessLevel += 2.5
	# brightnessLevel += 0.1
	channel1.SetBrightness(brightnessLevel)
	channel2.SetBrightness(brightnessLevel)
	sleep(0.1)

pwm.Shutdown()