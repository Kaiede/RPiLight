#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
#	test.py
#
#	Package: PiLight
#	Module: PiLight
#	Copyright 2018 <user@biticus.net>
#

import logging
import pwm
import sys
import controller

from datetime import datetime, timedelta

#
# Test Ramp Generators
#
def RampForChannels(channels, brightnessStart, brightnessEnd):
	return {token : (brightnessStart, brightnessEnd) for token, _ in channels.items()}


#
# Allow users to quickly test different configs
#

if len(sys.argv) < 2:
	targetConfig = "testConfig.json"
else:
	targetConfig = sys.argv[1]


#
# Configure Logging
#
logging.basicConfig(level=logging.DEBUG)
logging.getLogger("apscheduler.executors.default").setLevel(logging.WARNING)
logging.getLogger("apscheduler.scheduler").setLevel(logging.INFO)


#
# Initialize PWM and get the list of channels
#
pwm.StartupWithConfigFile(targetConfig)

availableChannels = pwm.GetValidTokens()

activeChannels = {}
for token in availableChannels:
	channel = pwm.GetChannel(token)
	activeChannels[token] = channel


#
# Ramp up, then down
#
lightController = controller.LightController(activeChannels)

rampToHigh = RampForChannels(activeChannels, 0.0, 1.0)
rampToLow = RampForChannels(activeChannels, 1.0, 0.0)

logging.info("Start Ramp")

rampToHighBehavior = controller.LightBehavior(rampToHigh)
rampToLowBehavior = controller.LightBehavior(rampToLow)


logging.info("First Pulse:")
# First Pulse: 10 seconds total, 4 up, 4 down. Break of 2 in the middle
now = datetime.now()
lightController.AddBehavior(rampToHighBehavior, controller.PRIORITY_LIGHTRAMP, now, now + timedelta(seconds=4))
lightController.AddBehavior(rampToLowBehavior, controller.PRIORITY_LIGHTRAMP, now + timedelta(seconds=6), now + timedelta(seconds=10))
rampToLowBehavior.Wait()


logging.info("Second Pulse:")
# Second Pulse: 10 seconds total, 6 up, 5 down. 1 second overlap
now = datetime.now()
lightController.AddBehavior(rampToHighBehavior, controller.PRIORITY_LIGHTRAMP, now, now + timedelta(seconds=6))
lightController.AddBehavior(rampToLowBehavior, controller.PRIORITY_LIGHTRAMP, now + timedelta(seconds=5), now + timedelta(seconds=10))
rampToLowBehavior.Wait()


#
# Cleanup
#
lightController.Shutdown()
pwm.Shutdown()
