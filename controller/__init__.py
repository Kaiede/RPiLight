#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
#	__init__.py
#
#	Package: PiLight
#	Module: Controller
#	Copyright 2018 <user@biticus.net>
#

import apscheduler.events as apevents
import threading

from apscheduler.schedulers.background import BackgroundScheduler
from datetime import datetime, timedelta


#
# Expose To Callers
#
from schedule import ReadSchedule

class LightController:
	# m_channels - Array:Channel - The channel objects being controlled
	# m_scheduler - BackgroundScheduler - This is how we toggle events.

	# m_activeBehavior - 
	# m_activeJob - Job

	def __init__(self, channels):
		self.m_channels = channels

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


class Behavior:
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
RAMP_STEP_TARGET = 5000		# Steps
MIN_RAMP_INTERVAL = 0.01 	# 10ms

class RampBehavior(Behavior, object):
	def __init__(self, startStates, endStates):
		self.m_startStates = startStates
		self.m_channelDeltas = self.CalculateDeltas(startStates, endStates)

		self.m_currentInterval = 1
		super(RampBehavior, self).__init__()
		return

	def IntervalInSeconds(self):
		rampTime = (self.EndDate() - self.StartDate()).total_seconds()
		return max(rampTime / RAMP_STEP_TARGET, MIN_RAMP_INTERVAL)

	def CalculateDeltas(self, startStates, endStates):
		channelDeltas = []
		for x, startState in enumerate(startStates):
			delta = endStates[x] - startState
			channelDeltas.append(delta)

		return channelDeltas

	def DoBehavior(self, channels):
		now = datetime.now()
		timeSpent = (now - self.StartDate()).total_seconds()
		timeRange = (self.EndDate() - self.StartDate()).total_seconds()

		factor = timeSpent / timeRange
		for x, channel in enumerate(channels):
			brightness = self.m_startStates[x] + (factor * self.m_channelDeltas[x])
			channel.SetBrightness(brightness)

		#if timeSpent >= timeRange:
			#self.Complete()
			#endTime = time.time()
			#print "Ramp Complete: %0.2f seconds" % (endTime - self.m_startTime)
