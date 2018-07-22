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
import sys

from time import sleep

#
# Allow users to quickly test different configs
#

if len(sys.argv) < 2:
	targetConfig = "testConfig.json"
else:
	targetConfig = sys.argv[1]


#
# Initialize PWM and get the list of channels
#
pwm.StartupWithConfigFile(targetConfig)

availableChannels = pwm.GetValidTokens()

activeChannels = []
for token in availableChannels:
	channel = pwm.GetChannel(token)
	activeChannels.append(channel)


#
# Ramp up, then down
#
brightnessLevel = 0.0
while (brightnessLevel <= 100.0):
	brightnessLevel += 2.5
	# brightnessLevel += 0.1

	for channel in activeChannels:
		channel.SetBrightness(brightnessLevel / 100.0)

	sleep(0.1)

while (brightnessLevel >= 0.0):
	brightnessLevel -= 2.5
	# brightnessLevel += 0.1

	for channel in activeChannels:
		channel.SetBrightness(brightnessLevel / 100.0)

	sleep(0.1)


#
# Cleanup
#
pwm.Shutdown()
