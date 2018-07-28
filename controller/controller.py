#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
#	controller.py
#
#	Package: PiLight
#	Module: Controller
#	Copyright 2018 <user@biticus.net>
#

import heapq
import itertools
import logging
import threading

from constants import *
from datetime import datetime, timedelta


class LightController:
	# m_controlEvent - Event

	def __init__(self, channels):
		# Control Variables
		self.m_controlEvent = threading.Event()
		self.m_controlThread = threading.Thread(target=self.RunLoop)
		self.m_isRunning = False

		# Behavior Variables
		self.m_channels = channels
		self.m_channelEvents = []
		self.m_nextChannelEventIdx = None
		self.m_nextChannelEventDatetime = None
		self.m_currentBehavior = None


	def SetSchedule(self, schedule):
		self.m_channelEvents = CreateLightEventsFromSchedule(schedule)
		currentTime = datetime.now().time()
		idxLatestEvent = -1
		for idxEvent, event in enumerate(self.m_channelEvents):
			if event.Time() < currentTime:
				idxLatestEvent = idxEvent

		# Wake up the thread so it can fire things
		logging.info("Scheduling Next Event: %s", str(idxLatestEvent))
		self.m_nextChannelEventIdx = idxLatestEvent
		self.m_nextChannelEventDatetime = datetime.combine(datetime.today(), self.m_channelEvents[idxLatestEvent].Time())
		self.m_controlEvent.set()


	def SetBehavior(self, behavior, startDate, endDate):
		self.ClearBehavior()
		self.m_currentBehavior = behavior
		behavior.ConfigureForRunning(startDate, endDate)

		logging.info("New Behavior {%s -> %s}" % (startDate.strftime("%H:%M:%S.%f"), endDate.strftime("%H:%M:%S.%f")))
		self.m_controlEvent.set()


	def ClearBehavior(self):
		if self.m_currentBehavior is not None:
			self.m_currentBehavior.Complete()

		self.m_currentBehavior = None
		self.m_controlEvent.set()


	def Start(self):
		self.m_isRunning = True
		self.m_controlThread.start()


	def Stop(self):
		self.m_isRunning = False
		self.m_controlEvent.set()
		self.m_controlThread.join()


	def CalculateNextEventIdx(self, now, idxEvent):
		idxNextEvent = idxEvent + 1
		if idxNextEvent >= len(self.m_channelEvents):
			idxNextEvent = 0

		currentEvent = self.m_channelEvents[idxEvent]
		nextEvent = self.m_channelEvents[idxNextEvent]

		datetimeNextEvent = datetime.combine(now.date(), nextEvent.Time())
		if nextEvent.Time() < currentEvent.Time():
			datetimeNextEvent = datetimeNextEvent + timedelta(days=1)

		return idxNextEvent, datetimeNextEvent


	def RunEvent(self, now):
		if not self.m_channelEvents:
			return

		logging.debug("Checking Event %d" % self.m_nextChannelEventIdx)
		while self.m_nextChannelEventDatetime <= now:
			nextEvent = self.m_channelEvents[self.m_nextChannelEventIdx]
			nextEvent.OnEventFired(self)
			self.m_nextChannelEventIdx, self.m_nextChannelEventDatetime = self.CalculateNextEventIdx(now, self.m_nextChannelEventIdx)	
			logging.debug("Checking Event %d" % self.m_nextChannelEventIdx)


	def WaitNextInterval(self, now):
		interval = None
		intervalEvent = None

		# Check Event
		if self.m_nextChannelEventDatetime is not None:
			intervalEvent = (self.m_nextChannelEventDatetime - now).total_seconds()

		# Check Behavior
		if self.m_currentBehavior is not None:
			interval = self.m_currentBehavior.Interval()

		# Do an override so interval is the smallest of the two,
		# or the one that exists.
		if intervalEvent is not None and interval is not None:
			interval = min(intervalEvent, interval)
		elif intervalEvent is not None:
			interval = intervalEvent

		if interval is not None:
			spentTime = (datetime.now() - now).total_seconds()
			logging.debug("%s: Next Wakeup: %s" % (now.strftime("%H:%M:%S.%f"), (now + timedelta(seconds=interval)).strftime("%H:%M:%S.%f")))
			self.m_controlEvent.wait(interval - spentTime)
		else:
			logging.debug("%s: Pausing Controller Thread" % now.strftime("%H:%M:%S.%f"))
			self.m_controlEvent.wait()

		return interval


	def RunBehavior(self, now):
		if self.m_currentBehavior is not None:
			lightLevels = self.m_currentBehavior.GetLightLevelForDate(now, self.m_channels)

			for token, brightness in lightLevels.iteritems():
				if not self.m_channels.has_key(token):
					logging.warning("Unknown Channel Token: %s", token)
					continue

				channel = self.m_channels[token]
				channel.SetBrightness(brightness)

			if self.m_currentBehavior.EndDate() <= now:
				self.ClearBehavior()


	def RunLoop(self):
		while True:
			# Early Abort
			if not self.m_isRunning:
				return

			#
			# Get Current Time
			#
			now = datetime.now()

			#
			# Run Current Event(s) If Needed
			#
			logging.debug("Running Events")
			self.RunEvent(now)

			#
			# Handle The Current Behavior
			#
			logging.debug("Running Behavior")
			self.RunBehavior(now)

			# 
			# Pause For Next Work Item
			#
			interval = self.WaitNextInterval(now)
			if self.m_controlEvent.is_set():
				logging.debug("Early Wakeup From Control Event")
			self.m_controlEvent.clear()


class Event(object):
	# m_time - time

	def __init__(self, time):
		self.m_time = time
		return

	def Time(self):
		return self.m_time

	def OnEventFired(self, controller):
		return

def CreateLightEventsFromSchedule(schedule):
	jobEvents = []
	events = schedule.Events()
	for idxEvent, scheduleEvent in enumerate(events):
		channelRanges, idxNext = schedule.ChannelValueRangeForEventIndex(idxEvent)
		eventNext = events[idxNext]

		lightEvent = LightLevelChangeEvent(scheduleEvent.Time(), eventNext.Time(), channelRanges)
		jobEvents.append(lightEvent)

	return jobEvents

class LightLevelChangeEvent(Event, object):

	def __init__(self, time, endTime, channelRanges):
		self.m_endTime = endTime
		self.m_behavior = LightLevelChangeBehavior(channelRanges)
		super(LightLevelChangeEvent, self).__init__(time)

	def OnEventFired(self, controller):
		now = datetime.now()
		logging.info("%s: LightLevelChangeEvent Fired" % now.strftime("%H:%M:%S.%f"))

		today = datetime.today()
		startTime =	datetime.combine(today.date(), self.Time())
		endTime = datetime.combine(today.date(), self.m_endTime)
		if endTime < startTime:
			endTime = endTime + timedelta(days=1)

		controller.SetBehavior(self.m_behavior, startTime, endTime)
		return


class Behavior:
	# m_startDate
	# m_endDate
	# m_event

	def __init__(self):
		self.m_startDate = None
		self.m_endDate = None
		self.m_event = threading.Event()
		pass

	def ConfigureForRunning(self, startDate, endDate):
		self.m_startDate = startDate
		self.m_endDate = endDate

	def StartDate(self):
		return self.m_startDate

	def EndDate(self):
		return self.m_endDate

	def Interval(self):
		return 0.01

	def Complete(self):
		self.m_event.set()

	def Join(self):
		logging.debug("Join Started")
		self.m_event.wait()
		logging.debug("Join Ended")

	def Reset(self):
		self.m_startDate = None
		self.m_endDate = None
		self.m_event.clear()

	def GetLightLevelForDate(self, now, channels):
		return 1.0


MIN_INTERVAL = 1.0 / 24.0	# 24 updates per second
TARGET_UPDATES = 2 ** 10 	# 1024 updates per interpolation if we run a full ramp


class LightLevelChangeBehavior(Behavior, object):
	# m_channelDeltas

	def __init__(self, channelRanges):
		self.m_timeDelta = None
		self.m_interval = None
		self.m_channelDeltas = {token : (startState, endState - startState) for token, (startState, endState) in channelRanges.iteritems()}
		super(LightLevelChangeBehavior, self).__init__()


	def Interval(self):
		if self.m_interval is None:
			max_change = 0.0
			for _, (_, delta) in self.m_channelDeltas.iteritems():
				max_change = max(max_change, abs(delta))

			if max_change == 0.0:
				return self.TimeDelta()

			self.m_interval = max(MIN_INTERVAL, self.TimeDelta() / (max_change * TARGET_UPDATES))

		return self.m_interval


	def TimeDelta(self):
		if getattr(self, 'm_timeRange', None) is None:
			self.m_timeDelta = (self.EndDate() - self.StartDate()).total_seconds()

		return self.m_timeDelta


	def Reset(self):
		self.m_timeRange = None
		self.m_interval = None
		super(LightLevelChangeBehavior, self).Reset()


	def GetLightLevelForDate(self, now, channels):
		timeSpent = (now - self.StartDate()).total_seconds()

		channelOutputs = {}
		factor = min(timeSpent / self.TimeDelta(), 1.0)
		for token, (startState, delta) in self.m_channelDeltas.items():
			brightness = startState + (factor * delta)
			channelOutputs[token] = brightness

		return channelOutputs
