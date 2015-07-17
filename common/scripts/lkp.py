#!/usr/bin/env python
#
# Run LKP test suite on Linaro ubuntu
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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301,
# USA.
#
# Author: Chase Qi <chase.qi@linaro.org>
#
import os
import sys
import platform
import glob
import json
import pwd
import shutil
from subprocess import call

LKP_PATH = str(sys.argv[1])
print 'LKP test suite path: %s' % (LKP_PATH)
WD = str(sys.argv[2])
print 'Working directory: %s' % (WD)
LOOPS = int(sys.argv[3])
JOB = str(sys.argv[4])
MONITORS = str(sys.argv[5])
print 'Going to run %s %s times' % (JOB, LOOPS)
HOST_NAME = platform.node()
KERNEL_VERSION = platform.release()
DIST = str.lower(platform.dist()[0])
CONFIG = 'defconfig'


def test_result(TEST_COMMAND, TEST_CASE_ID):
    # For each step of test run, print pass or fail to test log.
    if call(TEST_COMMAND) == 0:
        print '%s pass' % (TEST_CASE_ID)
        return True
    else:
        print '%s fail' % (TEST_CASE_ID)
        return False


def find_user(NAME):
    # Create user 'lkp' if it doesn't exist.
    try:
        return pwd.getpwnam(NAME)
    except KeyError:
        return None


# pre-config.
if not find_user('lkp'):
    print 'creating user lkp...'
    call(['useradd', '--create-home', '--home-dir', '/home/lkp', 'lkp'])
else:
    print 'User lkp already exists.'

if not os.path.exists('/home/lkp'):
    call(['mkdir', '-p', '/home/lkp'])

call(['chown', '-R', 'lkp:lkp', '/home/lkp'])

f = open('/etc/apt/sources.list.d/multiverse.list', 'w')
f.write('deb http://ports.ubuntu.com/ubuntu-ports/ vivid multiverse\n')
f.close()
call(['apt-get', 'update'])

# Setup test job.
SETUP_JOB = [LKP_PATH + '/bin/lkp install',
             LKP_PATH + '/jobs/' + JOB + '.yaml']
print 'Set up %s test with command: %s' % (JOB, SETUP_JOB)
if not test_result(SETUP_JOB, 'setup-' + JOB):
    sys.exit(1)

# Split test job.
if not os.path.exists(WD + '/' + JOB):
    os.makedirs(WD + '/' + JOB)
SPLIT_JOB = [LKP_PATH + '/bin/lkp split-job', MONITORS, '--output',
            WD + '/' + JOB, LKP_PATH + '/jobs/' + JOB + '.yaml']
print 'Splitting job %s with command: %s' % (JOB, SPLIT_JOB)
if not test_result(SPLIT_JOB, 'split-job-' + JOB):
    sys.exit(1)

# Delete test results from last lava-test-shell-run.
if os.path.exists('/result/'):
    shutil.rmtree('/result/', ignore_errors=True)

# Run tests.
SUB_TESTS = glob.glob(WD + '/' + JOB + '/*.yaml')
for SUB_TEST in SUB_TESTS:
    COUNT = 1
    DONE = True
    SUB_TEST_CASE_ID = os.path.basename(SUB_TEST)[:-5]
    RESULT_ROOT = str('/'.join(['/result', JOB,
                               SUB_TEST_CASE_ID[int(len(JOB) + 1):],
                               HOST_NAME, DIST, CONFIG, KERNEL_VERSION]))
    while COUNT <= LOOPS:
        # Use suffix for mutiple runs.
        if LOOPS > 1:
            SUFFIX = '-run' + str(COUNT)
        else:
            SUFFIX = ''

        RUN_COMMAND = [LKP_PATH + '/bin/lkp run', SUB_TEST]
        print 'Running test %s%s with command: %s' % (SUB_TEST_CASE_ID,
                                                      SUFFIX, RUN_COMMAND)
        if not test_result(RUN_COMMAND, 'run-' + SUB_TEST_CASE_ID + SUFFIX):
            DONE = False
            break

        # For each run, decode JOB.json to pick up the scores produced by the
        # benchmark itself.
        RESULT_FILE = RESULT_ROOT + '/' + str(COUNT - 1) + '/' + JOB + '.json'
        if not os.path.isfile(RESULT_FILE):
            print '%s not found' % (RESULT_FILE)
        else:
            json_data = open(RESULT_FILE)
            DICT = json.load(json_data)
            for item in DICT:
                call(['lava-test-case', SUB_TEST_CASE_ID + '-' + item + SUFFIX,
                      '--result', 'pass', '--measurement', str(DICT[item][0])])
            json_data.close()

        COUNT = COUNT + 1

    # For mutiple runs, if all runs are completed and results found, decode
    # avg.json.
    if LOOPS > 1 and DONE:
        AVG_FILE = RESULT_ROOT + '/' + 'avg.json'
        if not os.path.isfile(RESULT_FILE):
            print '%s not found' % (RESULT_FILE)
        elif not os.path.isfile(AVG_FILE):
            print '%s not found' % (AVG_FILE)
        else:
            json_data = open(RESULT_FILE)
            avg_json_data = open(AVG_FILE)
            DICT = json.load(json_data)
            AVG_DICT = json.load(avg_json_data)
            for item in DICT:
                if item in AvgDict:
                    call(['lava-test-case',
                          SUB_TEST_CASE_ID + '-' + item + '-avg', '--result',
                          'pass', '--measurement', str(AVG_DICT[item])])
            json_data.close()
            avg_json_data.close()

    # Compress and attach raw data.
    call(['tar', 'caf', 'lkp-result-' + JOB + '.tar.xz', '/result/' + JOB])
    call(['lava-test-run-attach', 'lkp-result-' + JOB + '.tar.xz'])

if not DONE:
    sys.exit(1)
else:
    sys.exit(0)
