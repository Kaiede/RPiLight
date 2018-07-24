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
import controller

from datetime import datetime, timedelta

#
# Test Ramp Generators
#
def StateForChannels(channels, brightness):
	return [brightness for channel in channels]


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
lightController = controller.LightController(activeChannels)

highStates = StateForChannels(activeChannels, 1.0)
lowStates = StateForChannels(activeChannels, 0.0)

print "Start Ramp"

rampBehavior = controller.RampBehavior(lowStates, highStates)
now = datetime.now()
lightController.AddBehavior(rampBehavior, now, now + timedelta(seconds=10))

print "Wait on Ramp"

rampBehavior.Wait()

print "Start Ramp 2"

now = datetime.now()
#rampBehavior = controller.RampBehavior(lowStates, highStates)
lightController.AddBehavior(rampBehavior, now, now + timedelta(seconds=10))

print "Wait on Ramp 2"

rampBehavior.Wait()


#
# Cleanup
#
lightController.Shutdown()
pwm.Shutdown()
