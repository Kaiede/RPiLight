#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
#	preview.py
#
#	Package: PiLight
#	Module: PiLight
#	Copyright 2018 <user@biticus.net>
#

import controller
import logging
import pwm
import sys

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
# Configure Logging
#
logging.basicConfig(level=logging.INFO)


#
# Initialize PWM, Read Schedule, Initialize Light Controller
#
pwm.StartupWithConfigFile(targetConfig)

availableChannels = pwm.GetValidTokens()
logging.info(availableChannels)

schedule = controller.ReadSchedule(targetSchedule, availableChannels)

logging.info(schedule)

activeChannels = {}
for token in availableChannels:
	channel = pwm.GetChannel(token)
	activeChannels[token] = channel


lightController = controller.LightController(activeChannels)

#
# Run the Preview
#

preview = controller.SchedulePreview(lightController, activeChannels, schedule)

preview.Run()

#
# Cleanup
#
pwm.Shutdown()
