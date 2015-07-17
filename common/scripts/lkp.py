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


def test_result(test_command, test_case_id):
    # For each step of test run, print pass or fail to test log.
    if call(test_command) == 0:
        print '%s pass' % (test_case_id)
        return True
    else:
        print '%s fail' % (test_case_id)
        return False


def find_user(name):
    # Create user 'lkp' if it doesn't exist.
    try:
        return pwd.getpwnam(name)
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
for sub_test in SUB_TESTS:
    count = 1
    done = True
    sub_test_case_id = os.path.basename(sub_test)[:-5]
    result_root = str('/'.join(['/result', JOB,
                               sub_test_case_id[int(len(JOB) + 1):],
                               HOST_NAME, DIST, CONFIG, KERNEL_VERSION]))
    while count <= LOOPS:
        # Use suffix for mutiple runs.
        if LOOPS > 1:
            suffix = '-run' + str(count)
        else:
            suffix = ''

        lkp_run = [LKP_PATH + '/bin/lkp run', sub_test]
        print 'Running test %s%s with command: %s' % (sub_test_case_id,
                                                      suffix, lkp_run)
        if not test_result(lkp_run, 'run-' + sub_test_case_id + suffix):
            done = False
            break

        # For each run, decode JOB.json to pick up the scores produced by the
        # benchmark itself.
        result_file = result_root + '/' + str(count - 1) + '/' + JOB + '.json'
        if not os.path.isfile(result_file):
            print '%s not found' % (result_file)
        else:
            json_data = open(result_file)
            dict = json.load(json_data)
            for item in dict:
                call(['lava-test-case', sub_test_case_id + '-' + item + suffix,
                      '--result', 'pass', '--measurement', str(dict[item][0])])
            json_data.close()

        count = count + 1

    # For mutiple runs, if all runs are completed and results found, decode
    # avg.json.
    if LOOPS > 1 and done:
        avg_file = result_root + '/' + 'avg.json'
        if not os.path.isfile(result_file):
            print '%s not found' % (result_file)
        elif not os.path.isfile(avg_file):
            print '%s not found' % (avg_file)
        else:
            json_data = open(result_file)
            avg_json_data = open(avg_file)
            dict = json.load(json_data)
            avg_dict = json.load(avg_json_data)
            for item in dict:
                if item in avg_dict:
                    call(['lava-test-case',
                          sub_test_case_id + '-' + item + '-avg', '--result',
                          'pass', '--measurement', str(avg_dict[item])])
            json_data.close()
            avg_json_data.close()

    # Compress and attach raw data.
    call(['tar', 'caf', 'lkp-result-' + JOB + '.tar.xz', '/result/' + JOB])
    call(['lava-test-run-attach', 'lkp-result-' + JOB + '.tar.xz'])

if not done:
    sys.exit(1)
else:
    sys.exit(0)
