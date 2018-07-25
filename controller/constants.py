#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
#	constants.py
#
#	Package: PiLight
#	Module: Controller
#	Copyright 2018 <user@biticus.net>
#


#
# Priority Definitions
#
# Lower numbers mean higher priority
#
# Light Ramp : Base Priority. Used for the schedule
# Preview : Highest Priority. Used to display a preview
# Override : Meant for Manual Controls. 
#

PRIORITY_LIGHTRAMP		= 16
PRIORITY_PREVIEW		= 1
PRIORITY_OVERRIDE		= 0
