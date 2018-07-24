#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
#	preview.py
#
#	Package: PiLight
#	Module: Controller
#	Copyright 2018 <user@biticus.net>
#

import controller

from datetime import datetime, timedelta

#
# Compress 24 Hours to 1 Minute
#
PREVIEW_COMPRESSION_FACTOR = 24.0 * 60.0

def nextIndex(array, idx):
	nextIdx = idx + 1
	if nextIdx >= len(array):
		nextIdx = 0

	return nextIdx

class SchedulePreview:
	def __init__(self, controller, channels, schedule):
		self.m_lightController = controller
		self.m_ramps = []
		self.m_rampDurations = []
		self.CalculateRamps(channels, schedule)

	def CalculateRamps(self, channels, schedule):
		events = schedule.Events()
		for idx, event in enumerate(events):
			startStateDict = {}
			endStateDict = {}

			nextIdx = nextIndex(events, idx)
			nextEvent = events[nextIdx]

			for channel in event.ChannelValues():
				startStateDict[channel.Token()] = channel.Brightness()
			for channel in nextEvent.ChannelValues():
				endStateDict[channel.Token()] = channel.Brightness()

			startStates = []
			endStates = []
			for channel in channels:
				startStates.append(startStateDict[channel.Token()])
				endStates.append(endStateDict[channel.Token()])

			rampBehavior = controller.RampBehavior(startStates, endStates)

			nextEventDatetime = nextEvent.DatetimeForToday()
			if (nextIdx < idx):
				nextEventDatetime = nextEventDatetime + timedelta(days=1)

			rampDuration = (nextEventDatetime - event.DatetimeForToday()).total_seconds()
			rampDuration = rampDuration / PREVIEW_COMPRESSION_FACTOR

			self.m_ramps.append(rampBehavior)
			self.m_rampDurations.append(rampDuration)

		return

	def Run(self):
		for idx, rampBehavior in enumerate(self.m_ramps):
			rampDuration = self.m_rampDurations[idx]
			print "Ramp %d: %0.1f Seconds" % (idx, rampDuration)

			now = datetime.now()
			self.m_lightController.AddBehavior(rampBehavior, now, now + timedelta(seconds=rampDuration))
			rampBehavior.Wait()


		return