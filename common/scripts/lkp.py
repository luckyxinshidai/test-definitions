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
import os, sys, platform, glob, json
from subprocess import call

Jobs = str.split(sys.argv[1])
print 'Jobs to run: %s' % (Jobs)
HostName = platform.node() 
KernelVersion = platform.release()
Dist = str.lower(platform.dist()[0])
Config = 'defconfig'
Count = '0'

# LKP save test scores to json file, it can be parsed by python json module.
def JsonParser(ResultFile, SubTestCaseID):
    JsonData = open(ResultFile)
    Data = json.load(JsonData)
    for item in Data:
        call(['lava-test-case', str(SubTestCaseID) + '-' + str(item), '--result', 'pass', '--measurement', str(Data[item][0])])
    JsonData.close()
    return True

# Use lava-test-case parse result of the execution of each step of lkp test run.
def LavaTestCase(TestCommand, CommandName, TestCaseID):
    if call(TestCommand) == 0:
        call(['lava-test-case', str(CommandName) + '-' + str(TestCaseID), '--result', 'pass'])
        return True
    else:
        call(['lava-test-case', str(CommandName) + '-' + str(TestCaseID), '--result', 'fail'])
        return False

# pre-config
call(['useradd', '--create-home', '--home-dir', '/home/lkp', 'lkp'])
call(['mkdir', '-p', '/home/lkp'])
call(['chown', '-R', 'lkp:lkp', '/home/lkp'])
f = open('/etc/apt/sources.list.d/multiverse.list','w')
f.write('deb http://ports.ubuntu.com/ubuntu-ports/ vivid multiverse\n')
f.close()
call(['apt-get', 'update'])

for Job in Jobs:
    # Split test job.
    SplitJob = ['./sbin/split-job', '--no-defaults', './jobs/' + str(Job) + '.yaml']
    print 'Splitting job %s with command: %s' % (Job, SplitJob)
    if LavaTestCase(SplitJob, 'split-job', Job) == True:
        print '%s split successfully' % (Job)
    else:
        print '%s splitting filed, going to next loop' % (Job)
        continue

    # Setup test job.
    SubTests = glob.glob('*.yaml')
    print 'Sub-tests of %s: %s' % (Job, SubTests)

    SetupLocal = ['./bin/setup-local', str(SubTests[0])]
    print 'Set up %s test with command: %s' % (Job, SetupLocal)
    if LavaTestCase(SetupLocal, 'setup-local', Job) == True:
        print '%s setup finished successfully' %(Job)
    else:
        print '%s setup failed.' %(Job)
        continue

    # Run tests.
    for SubTest in SubTests:
        SubTestCaseID = SubTest[:-5]
        RunLocal = ['./bin/run-local', str(SubTest)]
        print 'Running sub-test %s with command: %s' % (SubTestCaseID, RunLocal)
        if LavaTestCase(RunLocal, 'run-local', SubTestCaseID) == True:
            print '%s test finished successfully' % (SubTestCaseID)
        else:
            print '%s test finished abnormally' % (SubTestCaseID)
            continue

        # Result parsing.
        ResultFile = str('/'.join(['/result', Job, SubTestCaseID[int(len(Job) + 1):], HostName, Dist, Config, KernelVersion, Count, Job + '.json']))
        print 'Location of test result file: %s' % (ResultFile)
        if os.path.isfile(ResultFile):
            print 'Test result found: %s' % (ResultFile)
            if JsonParser(ResultFile, SubTestCaseID):
                call(['lava-test-case', 'result-parsing-' + SubTestCaseID, '--result', 'pass'])
            else:
                call(['lava-test-case', 'result-parsing-' + SubTestCaseID, '--result', 'fail'])
        else:
            print 'Test results file not found'
            call(['lava-test-case', 'result-parsing-' + SubTestCaseID, '--result', 'fail'])
