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

LKPPath = str(sys.argv[1])
print 'LKP test suite path: %s' % (LKPPath)
WD = str(sys.argv[2])
print 'Working directory: %s' % (WD)
Loops = int(sys.argv[3])
Job = str(sys.argv[4])
print 'Going to run %s %s times' % (Job, Loops)
HostName = platform.node() 
KernelVersion = platform.release()
Dist = str.lower(platform.dist()[0])
Config = 'defconfig'

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

# Split test job.
if not os.path.exists(WD + '/' + Job):
    os.makedirs(WD + '/' + Job)
SplitJob = [LKPPath + '/sbin/split-job', '--no-defaults', '--output', WD + '/' + Job, LKPPath + '/jobs/' + Job + '.yaml']
print 'Splitting job %s with command: %s' % (Job, SplitJob)
if LavaTestCase(SplitJob, 'split-job-' + Job) == True:
    print '%s split successfully' % (Job)
else:
    print '%s split failed.' % (Job)
    sys.exit(1)

# Setup test job.
SubTests = glob.glob(WD + '/' + Job + '/*.yaml')
print 'Sub-tests of %s: %s' % (Job, SubTests)

SetupLocal = [LKPPath + '/bin/setup-local', SubTests[0]]
print 'Set up %s test with command: %s' % (Job, SetupLocal)
if LavaTestCase(SetupLocal, 'setup-local-' + Job) == True:
    print '%s setup finished successfully' %(Job)
else:
    print '%s setup failed.' %(Job)
    sys.exit(1)

# Run tests.
for SubTest in SubTests:
    Count = 1
    while (Count <= Loops):
        SubTestCaseID = os.path.basename(SubTest)[:-5]
        RunLocal = [LKPPath + '/bin/run-local', SubTest]
        print 'Running sub-test %s with command: %s' % (SubTestCaseID, RunLocal)
        if LavaTestCase(RunLocal, 'run-local-' + SubTestCaseID + '-run' + str(Count)) == True:
            print '%s test finished successfully' % (SubTestCaseID)
        else:
            print '%s test finished abnormally' % (SubTestCaseID)
            continue

        # Decode matrix.json for each run.
        ResultDir = str('/'.join(['/result', Job, SubTestCaseID[int(len(Job) + 1):], HostName, Dist, Config, KernelVersion]))
        MatrixFile = str(ResultDir + '/' + 'Matrix.json')
        Prefix = 'run' + str(Count)
        MatrixIndex = int(Count - 1)
        if not os.path.isfile(MatrixFile):
            print '%s not found' % (MatrixFile)
            call(['lava-test-case', Prefix + '-' + SubTestCaseID + '-parsing', '--result', 'fail'])
        MatrixJsonData = open(MatrixFile)
        MatrixData = json.load(MatrixJsonData)
        for item in MatrixData:
            if item not in 'stats_source':
                call(['lava-test-case', Prefix + '-' + SubTestCaseID + '-' + str(item), '--result', 'pass', '--measurement', str(MatrixData[item][MatrixIndex])])
        MatrixJsonData.close()

        Count = Count + 1

    # Decode avg.json for mutiple runs.
    if Loops > 1:
        AvgFile = str(ResultDir + '/' + 'avg.json')
        if not os.path.isfile(AvgFile):
            print '%s not found' % (AvgFile)
            call(['lava-test-case', 'avg-' + '-' + SubTestCaseID + '-parsing', '--result', 'fail'])
        AvgJsonData = open(AvgFile)
        AvgData = json.load(AvgJsonData)
        for item in AvgData:
            call(['lava-test-case', 'avg-' + SubTestCaseID + '-' +  str(item), '--result', 'pass', '--measurement', str(AvgData[item])])
        AvgJsonData.close()

    # Compress and attach raw data
    call(['tar', 'caf', WD + '/lkp-' + Job + '-result.tar.xz', '/result'])
    call(['lava-test-run-attach', WD + '/lkp-' + Job + '-result.tar.xz'])
