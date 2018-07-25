#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
#	controller.py
#
#	Package: PiLight
#	Module: Controller
#	Copyright 2018 <user@biticus.net>
#

import apscheduler.events as apevents
import threading

from apscheduler.schedulers.background import BackgroundScheduler
from datetime import datetime, timedelta


class LightController:
	# m_channels - Array:Channel - The channel objects being controlled
	# m_scheduler - BackgroundScheduler - This is how we toggle events.

	# m_activeBehavior - 
	# m_activeJob - Job

	def __init__(self, channels):
		self.m_channels = channels
		self.m_events = []

		self.m_scheduler = BackgroundScheduler()
		self.m_scheduler.add_listener(self.OnJobRemoved, apevents.EVENT_JOB_REMOVED)
		self.m_scheduler.start()

		self.m_activeBehavior = None
		self.m_activeJob = None

	def Shutdown(self):
		self.m_scheduler.shutdown()

	def OnJobRemoved(self, event):
		self.m_activeBehavior.OnBehaviorRemoved()
		self.m_activeJob = None
		self.m_activeBehavior = None

		return

	def SetSchedule(self, schedule):
		for event in self.m_events:
			continue

		self.m_events = CreateLightEventsFromSchedule(schedule)
		currentTime = datetime.now().time()
		latestEvent = None
		for event in self.m_events:
			self.m_scheduler.add_job(event.OnEventFired, 'cron', [self], hour=event.Hour(), minute=event.Minute(), second=event.Second())
			if event.Time() < currentTime:
				latestEvent = event

		if latestEvent is None:
			latestEvent = self.m_events[-1]

		# Make sure the previous event fires and does the work. 
		latestEvent.OnEventFired(self)


	def AddBehavior(self, behavior, startDate, endDate):
		if self.m_activeJob is not None:
			return

		self.m_activeBehavior = behavior
		behavior.AttachToController(self, startDate, endDate)
		seconds = behavior.IntervalInSeconds()
		self.m_activeJob = self.m_scheduler.add_job(behavior.DoBehavior, 'interval', [self.m_channels], start_date=startDate, end_date=endDate, seconds=seconds)
		return

	def CompleteBehavior(self, behavior):
		if self.m_activeJob is not None:
			self.m_activeJob.remove()
			self.m_activeJob = None
		return


class Event(object):
	# m_time - time

	def __init__(self, time):
		self.m_time = time
		return

	def Time(self):
		return self.m_time

	def Hour(self):
		return self.m_time.hour

	def Minute(self):
		return self.m_time.minute

	def Second(self):
		return self.m_time.second

	def OnEventFired(self, controller):
		return

def CreateLightEventsFromSchedule(schedule):
	jobEvents = []
	events = schedule.Events()
	for idxEvent, scheduleEvent in enumerate(events):
		channelRanges, idxNext = schedule.ChannelValueRangeForEventIndex(idxEvent)
		eventNext = events[idxNext]

		lightEvent = LightEvent(scheduleEvent.Time(), eventNext.Time(), channelRanges)
		jobEvents.append(lightEvent)

	return jobEvents

class LightEvent(Event, object):

	def __init__(self, time, endTime, channelRanges):
		self.m_endTime = endTime
		self.m_behavior = LightBehavior(channelRanges)
		super(LightEvent, self).__init__(time)

	def OnEventFired(self, controller):
		today = datetime.today()
		startTime =	datetime.combine(today.date(), self.Time())
		endTime = datetime.combine(today.date(), self.m_endTime)
		if endTime < startTime:
			endTime = endTime + timedelta(days=1)

		controller.AddBehavior(self.m_behavior, startTime, endTime)
		return


class Behavior(object):
	# m_controller - LightController
	# m_event - threading.Event

	def __init__(self):
		self.m_event = threading.Event()
		self.m_controller = None
		return

	def StartDate(self):
		return self.m_startDate

	def EndDate(self):
		return self.m_endDate

	def IntervalInSeconds(self):
		return 1.0 # Seconds

	def AttachToController(self, controller, startDate, endDate):
		self.m_event.clear()
		self.m_startDate = startDate
		self.m_endDate = endDate
		self.m_controller = controller
		return

	def Complete(self):
		self.m_controller.CompleteBehavior(self)

	def OnBehaviorRemoved(self):
		print "Behavior Removed"
		self.m_event.set()
		return

	def Wait(self):
		self.m_event.wait()

	def DoBehavior(self, channels):
		return


#
# Let's try to update about 5000 times during the ramp.
# If we can't, update every 10ms instead.
#
RAMP_STEP_TARGET = 2 ** 12	# Steps
MIN_RAMP_INTERVAL = 0.01 	# 10ms
MAX_RAMP_INTERVAL = 1.0		# 1s

class LightBehavior(Behavior, object):
	def __init__(self, channelRanges):
		# Convert to deltas from ranges
		self.m_channelDeltas = {token : (startState, endState - startState) for token, (startState, endState) in channelRanges.iteritems()}

		super(LightBehavior, self).__init__()

	def IntervalInSeconds(self):
		rampTime = (self.EndDate() - self.StartDate()).total_seconds()
		interval = rampTime / RAMP_STEP_TARGET
		return min(max(interval, MIN_RAMP_INTERVAL), MAX_RAMP_INTERVAL)

	def DoBehavior(self, channels):
		now = datetime.now()
		timeSpent = (now - self.StartDate()).total_seconds()
		timeRange = (self.EndDate() - self.StartDate()).total_seconds()


		factor = timeSpent / timeRange
		for token, (startState, delta) in self.m_channelDeltas.iteritems():
			channel = channels[token]
			brightness = startState + (factor * delta)
			channel.SetBrightness(brightness)

