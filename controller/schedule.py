#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
#	schedule.py
#
#	Package: PiLight
#	Module: Controller
#	Copyright 2018 <user@biticus.net>
#

import json
import os
import sets

from datetime import datetime

#
# Schedule Keys
#
KEY_BRIGHTNESS = "brightness"
KEY_CHANNELS = "channels"
KEY_SCHEDULE = "schedule"
KEY_TIME = "time"
KEY_TOKEN = "token"


def GetConfigurationDir():
	scriptPath = os.path.realpath(__file__)
	scriptDir = os.path.dirname(scriptPath)
	configDir = os.path.join("config")
	return configDir


def ReadSchedule(configFile, channelTokens):
	configDict = {}
	configPath = os.path.join(GetConfigurationDir(), configFile)

	if not os.path.isfile(configPath):
		raise ValueError('configFile')

	with open(configPath, 'r') as infile:
		configDict = json.load(infile)

	return Schedule(configDict, channelTokens)


class Schedule:
	# m_events - Array:Event - Array of the events in the schedule. 

	def __init__(self, configDict, channelTokens):
		channelTokenSet = sets.Set(channelTokens)
		if not configDict.has_key(KEY_SCHEDULE):
			raise ValueError(KEY_SCHEDULE)

		self.m_events = []
		for eventDict in configDict[KEY_SCHEDULE]:
			event = Event(eventDict, channelTokenSet)
			self.m_events.append(event)

		self.m_events = sorted(self.m_events, key = lambda event: event.Time())

		return

	def Events(self):
		return self.m_events;

	def __str__(self):
		string = "%d Events: " % len(self.m_events)
		for event in self.m_events:
			string += "\n"
			string += str(event)

		return string


class Event:
	def __init__(self, eventDict, channelTokenSet):
		if not eventDict.has_key(KEY_TIME):
			raise ValueError(KEY_TIME)

		if not eventDict.has_key(KEY_CHANNELS):
			raise ValueError(KEY_CHANNELS)

		self.m_time = datetime.strptime(eventDict[KEY_TIME], '%H:%M:%S').time()

		self.m_channelValues = []
		for channelDict in eventDict[KEY_CHANNELS]:
			channel = ChannelValue(channelDict, channelTokenSet)
			self.m_channelValues.append(channel)

		return

	def Time(self):
		return self.m_time

	def DatetimeForToday(self):
		return datetime.combine(datetime.now(), self.m_time)

	def ChannelValues(self):
		return self.m_channelValues

	def __str__(self):
		string = str(self.m_time) + " - "
		for value in self.m_channelValues:
			string += "{ %s : %0.2f } " % (value.Token(), value.Brightness() * 100.0)
			
		return string

class ChannelValue:
	# m_token
	# m_brightness 

	def __init__(self, channelDict, channelTokenSet):
		if not channelDict.has_key(KEY_TOKEN):
			raise ValueError(KEY_TOKEN)

		if not channelDict[KEY_TOKEN] in channelTokenSet:
			raise ValueError(channelDict[KEY_TOKEN])

		if not channelDict.has_key(KEY_BRIGHTNESS):
			raise ValueError(KEY_BRIGHTNESS)

		self.m_token = channelDict[KEY_TOKEN]
		self.m_brightness = float(channelDict[KEY_BRIGHTNESS])

	def Token(self):
		return self.m_token

	def Brightness(self):
		return self.m_brightness