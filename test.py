#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
#	test.py
#
#	Package: PiLight
#	Module: PiLight
#	Copyright 2018 <user@biticus.net>
#

import controller
import logging
import pwm
import sys
import time

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
lightController.Start()

rampToHigh = RampForChannels(activeChannels, 0.0, 1.0)
rampToLow = RampForChannels(activeChannels, 1.0, 0.0)

logging.info("Start Ramps")

rampToHighBehavior = controller.LightLevelChangeBehavior(rampToHigh)
rampToLowBehavior = controller.LightLevelChangeBehavior(rampToLow)


logging.info("First Pulse:")
# First Pulse: 10 seconds total, 4 up, 4 down. Break of 2 in the middle
now = datetime.now()
lightController.SetBehavior(rampToHighBehavior, now, now + timedelta(seconds=6))
rampToHighBehavior.Join()

now = datetime.now()
lightController.SetBehavior(rampToLowBehavior, now, now + timedelta(seconds=6))
rampToLowBehavior.Join()

logging.info("Second Pulse:")

rampToHighBehavior.Reset()
rampToLowBehavior.Reset()

# Second Pulse: 10 seconds total, 6 up, 5 down. 1 second overlap
now = datetime.now()
lightController.SetBehavior(rampToHighBehavior, now, now + timedelta(seconds=6))

# Test smashing the existing ramp
time.sleep(5)

now = datetime.now()
lightController.SetBehavior(rampToLowBehavior, now, now + timedelta(seconds=5))
rampToLowBehavior.Join()


#
# Cleanup
#
lightController.Stop()
pwm.Shutdown()
