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
import os, sys, platform, glob, json, pwd
from subprocess import call

Jobs = str.split(sys.argv[1])
print 'Jobs to run: %s' % (Jobs)
LKPPath = str(sys.argv[2])
print 'LKP test suite path: %s' % (LKPPath)
WD = str(sys.argv[3])
print 'Working directory: %s' % (WD)
Loops = int(sys.argv[4])
Count = 1
HostName = platform.node() 
KernelVersion = platform.release()
Dist = str.lower(platform.dist()[0])
Config = 'defconfig'

# LKP save test scores to json file, it can be parsed by python json module.
def JsonParser(ResultFile):
    JsonData = open(ResultFile)
    Data = json.load(JsonData)
    for item in Data:
        call(['lava-test-case', str(item), '--result', 'pass', '--measurement', str(Data[item])])
    JsonData.close()
    return True

# Collect result of the execution of each step of test runs.
def LavaTestCase(TestCommand, TestCaseID):
    if call(TestCommand) == 0:
        call(['lava-test-case', str(TestCaseID), '--result', 'pass'])
        return True
    else:
        call(['lava-test-case', str(TestCaseID), '--result', 'fail'])
        return False

# User existence check
def finduser(name):
     try:
         return pwd.getpwnam(name)
     except KeyError:
         return None

# pre-config
if not finduser('lkp'):
     print 'creating user lkp...'
     call(['useradd', '--create-home', '--home-dir', '/home/lkp', 'lkp'])
else:
     print 'User lkp already exists.'

if not os.path.exists('/home/lkp'):
    call(['mkdir', '-p', '/home/lkp'])
call(['chown', '-R', 'lkp:lkp', '/home/lkp'])

f = open('/etc/apt/sources.list.d/multiverse.list','w')
f.write('deb http://ports.ubuntu.com/ubuntu-ports/ vivid multiverse\n')
f.close()
call(['apt-get', 'update'])

## Run jobs.
for Job in Jobs:
    # Split test job.
    if not os.path.exists(WD + '/' + Job):
        os.makedirs(WD + '/' + Job)
    SplitJob = [LKPPath + '/sbin/split-job', '--no-defaults', '--output', WD + '/' + Job, LKPPath + '/jobs/' + Job + '.yaml']
    print 'Splitting job %s with command: %s' % (Job, SplitJob)
    if LavaTestCase(SplitJob, 'split-job-' + Job) == True:
        print '%s split successfully' % (Job)
    else:
        print '%s split failed.' % (Job)
        continue

    # Setup test job.
    SubTests = glob.glob(WD + '/' + Job + '/*.yaml')
    print 'Sub-tests of %s: %s' % (Job, SubTests)

    SetupLocal = [LKPPath + '/bin/setup-local', SubTests[0]]
    print 'Set up %s test with command: %s' % (Job, SetupLocal)
    if LavaTestCase(SetupLocal, 'setup-local-' + Job) == True:
        print '%s setup finished successfully' %(Job)
    else:
        print '%s setup failed.' %(Job)
        continue

    # Run tests.
    while (Count <= Loops):
        for SubTest in SubTests:
            SubTestCaseID = os.path.basename(SubTest)[:-5]
            RunLocal = [LKPPath + '/bin/run-local', SubTest]
            print 'Running sub-test %s with command: %s' % (SubTestCaseID, RunLocal)
            if LavaTestCase(RunLocal, 'run-local-' + SubTestCaseID + '-run' + Count) == True:
                print '%s test finished successfully' % (SubTestCaseID)
                Count = Count + 1
            else:
                print '%s test finished abnormally' % (SubTestCaseID)
                continue

    # Result parsing.
    ResultDir = str('/'.join(['/result', Job, SubTestCaseID[int(len(Job) + 1):], HostName, Dist, Config, KernelVersion]))
    #TestRunsPath = glob.glob(ResultDir + '/[0-9]')
    #LastRunPath = max(TestRunsPath)
    ResultAvgFile = str(ResultDir + '/' + 'avg.json')
    print 'Looking for test result file: %s' % (ResultAvgFile)
    if os.path.isfile(ResultAvgFile):
        print 'Test result found: %s' % (ResultAvgFile)
        if JsonParser(ResultAvgFile):
            call(['lava-test-case', 'result-parsing-' + SubTestCaseID, '--result', 'pass'])
        else:
            call(['lava-test-case', 'result-parsing-' + SubTestCaseID, '--result', 'fail'])
    else:
        print 'Test result file not found'
        call(['lava-test-case', 'result-parsing-' + SubTestCaseID, '--result', 'fail'])
