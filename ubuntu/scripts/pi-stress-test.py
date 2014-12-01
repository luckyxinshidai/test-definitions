#!/usr/bin/env python
#
# PI stress test case for Linux Linaro ubuntu
#
# Copyright (C) 2012 - 2014, Linaro Limited.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# Author: Chase Qi <chase.qi@linaro.org>
#

import sys
import os
import signal
from subprocess import call

# Get arguments
DURATION = sys.argv[1]
GROUP = sys.argv[2]
MLOCKALL = sys.argv[3]
RR = sys.argv[4]
OPTIONS = "--duration " + DURATION

# Determine test options
if GROUP != 'default':
    OPTIONS = OPTIONS + " --groups " + GROUP
if MLOCKALL == 'true':
    OPTIONS = OPTIONS + " --mlockall"
if RR != 'false':
    OPTIONS = OPTIONS + " --rr"

def handler(signum, frame):
    print 'Signal handler called with signal', signum
    call(['lava-test-case', 'pi-stress-test', '--result', 'fail'])

# Set terminate signal happened
signal.signal(signal.SIGTERM, handler)

# Run PI stress and generate test result
pi_stress_command = "pi_stress {0}".format(OPTIONS)
print "Runing pi_stress test with options '{0}'".format(OPTIONS)
if os.system(pi_stress_command) == 0:
    print 'PI stress test finished successfully'
    call(['lava-test-case', 'pi-stress-test', '--result', 'pass'])
else:
    print 'Error occurred, PI stress test failed'
    call(['lava-test-case', 'pi-stress-test', '--result', 'fail'])
