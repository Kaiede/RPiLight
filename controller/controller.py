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
import heapq
import itertools
import threading

from apscheduler.schedulers.background import BackgroundScheduler
from constants import *
from datetime import datetime, timedelta


class LightController:
	# m_channels - Dict:(Token, PWM.Channel) - The channel objects being controlled
	# m_scheduler - BackgroundScheduler - This is how we toggle events.
	# m_events - Array:Event - Events with cron jobs 

	# m_behaviorJob - Job - Singular job used to manage behaviors.
	# m_behaviorHeap - heapq
	# m_behaviorCounter 

	def __init__(self, channels):
		# Store away the channel dictionary for later		
		self.m_channels = channels

		# Initialize the Scheduler
		self.m_events = []
		self.m_scheduler = BackgroundScheduler()
		self.m_scheduler.start()

		# Intialize the Job handling behaviors
		self.m_behaviorJob = self.m_scheduler.add_job(self.RunBehaviors, 'interval', id='run_behaviors_job', seconds=1, next_run_time=None)
		self.m_behaviorHeap = []
		self.m_behaviorCounter = itertools.count()

		self.m_activeBehavior = None
		self.m_activeJob = None


	def Shutdown(self):
		self.m_behaviorJob.remove()
		self.m_scheduler.shutdown()


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


	def GetCurrentBehavior(self, now):
		if not self.m_behaviorHeap:
			return None, False, None

		# We provide details on what to execute, and
		# if we need to reconfigure after execution
		_, _, currentBehavior = self.m_behaviorHeap[0]
		lastRun = False
		nextBehavior = None

		# If the current behavior is expiring, find the next one that hasn't
		# also expired.
		if currentBehavior.EndDate() <= now:
			lastRun = True
			nextBehavior = currentBehavior
			while nextBehavior.EndDate() <= now:
				_, _, expiredBehavior = heapq.heappop(self.m_behaviorHeap)
				if expiredBehavior != currentBehavior:
					expiredBehavior.OnBehaviorRemoved()

				if not self.m_behaviorHeap:
					nextBehavior = None
					break

				# Because the first one has expired, we need to reconfigure
				# our interval for the new job
				_, _, nextBehavior = self.m_behaviorHeap[0]

		return currentBehavior, lastRun, nextBehavior


	def ReconfigureJobForBehavior(self, behavior):
		startDate = behavior.StartDate()
		intervalSeconds = behavior.IntervalInSeconds()
		self.m_behaviorJob = self.m_behaviorJob.reschedule(trigger='interval', start_date=startDate, seconds=intervalSeconds)
		self.m_behaviorJob.resume()

		print
		print self.m_behaviorJob

		return


	def RunBehaviors(self):
		now = datetime.now()
		currentBehavior, lastRun, nextBehavior = self.GetCurrentBehavior(now)
		if currentBehavior is None and nextBehavior is None:
			self.m_behaviorJob.pause()
			return

		# Guard against being asked to trigger behavior before the start time
		# Can happen when reconfiguring for a new behavior
		if currentBehavior.StartDate() <= now:
			currentBehavior.DoBehavior(self.m_channels)

		if lastRun:
			currentBehavior.OnBehaviorRemoved()
			if nextBehavior is not None:
				self.ReconfigureJobForBehavior(nextBehavior)
			else:
				self.m_behaviorJob.pause()


	def AddBehavior(self, behavior, priority, startDate, endDate):
		behavior.AttachToController(self, startDate, endDate)

		behaviorId = next(self.m_behaviorCounter)
		behaviorItem = [priority, behaviorId, behavior]
		heapq.heappush(self.m_behaviorHeap, behaviorItem)

		# Handle the case of the insert changing the current behavior
		_, frontId, _ = self.m_behaviorHeap[0]
		if frontId == behaviorId:
			self.ReconfigureJobForBehavior(behavior)



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

		controller.AddBehavior(self.m_behavior, PRIORITY_LIGHTRAMP, startTime, endTime)
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

