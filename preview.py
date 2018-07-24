#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
#	preview.py
#
#	Package: PiLight
#	Module: PiLight
#	Copyright 2018 <user@biticus.net>
#

import pwm
import sys
import controller

from datetime import datetime, timedelta


#
# Allow users to quickly test different configs
#
# Arguments: <Hardware Config File> <Schedule File>
#

if len(sys.argv) < 2:
	targetConfig = "testConfig.json"
else:
	targetConfig = sys.argv[1]

if len(sys.argv) < 3:
	targetSchedule = "testSchedule.json"
else:
	targetSchedule = sys.argv[2]


#
# Initialize PWM, Read Schedule, Initialize Light Controller
#
pwm.StartupWithConfigFile(targetConfig)

availableChannels = pwm.GetValidTokens()
print availableChannels

schedule = controller.ReadSchedule(targetSchedule, availableChannels)

print schedule

activeChannels = []
for token in availableChannels:
	channel = pwm.GetChannel(token)
	activeChannels.append(channel)


lightController = controller.LightController(activeChannels)

#
# Run the Preview
#

preview = controller.SchedulePreview(lightController, activeChannels, schedule)

preview.Run()

#
# Cleanup
#
lightController.Shutdown()
pwm.Shutdown()
