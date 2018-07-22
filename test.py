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

print pwm.GetValidTokens()

channel1 = pwm.GetChannel("SIM1")
channel2 = pwm.GetChannel("SIM2")

brightnessLevel = 0.0
while (brightnessLevel <= 100.0):
	brightnessLevel += 2.5
	# brightnessLevel += 0.1
	channel1.SetBrightness(brightnessLevel / 100.0)
	channel2.SetBrightness(brightnessLevel / 100.0)
	sleep(0.1)

pwm.Shutdown()