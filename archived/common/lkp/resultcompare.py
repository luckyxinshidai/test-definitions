#!/usr/bin/env python
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
import shutil
import glob
import subprocess
import json
import optparse

parser = optparse.OptionParser()
parser.add_option('--job1', dest='job1', help='the first LAVA job ID')
parser.add_option('--job2', dest='job2', help='the second LAVA job ID')

(opts, args) = parser.parse_args()

if not opts.job1:
    parser.error('The --job1 option is mandatory')
else:
    print('The first LAVA job is %s' % opts.job1)
if not opts.job2:
    parser.error('The --job2 is mandatory')
else:
    print('The second LAVA job is %s, used for comparison\n' % opts.job2)


def get_result(lava_job):
    print('Downloading %s lkp test results...' % lava_job)
    subprocess.call(['../lavadownload.py', '-n', 'lkp-result',
                     '-l', 'https://validation.linaro.org/RPC2/',
                     '-i', lava_job])
    for result_package in glob.glob('*.tar.xz'):
        print('Extracting %s' % result_package)
        subprocess.check_output(['tar', 'xvf', result_package])
        os.remove(result_package)
    shutil.rmtree('/result', ignore_errors=True)
    shutil.copytree('./result', '/result')
    print('\n')


if os.path.exists('./downloads'):
    shutil.rmtree('./downloads', ignore_errors=True)
os.makedirs('./downloads')
os.chdir('./downloads')

get_result(opts.job1)
results_to_compare = []
benchmarks = os.listdir('/result')
for benchmark in benchmarks:
    for root, dirs, files in os.walk('/result/' + benchmark):
        if benchmark + '.json' in files:
            file_path = os.path.join(root, benchmark + '.json')
            results_to_compare.append(file_path)
commit1 = results_to_compare[0].split('/')[-3]

get_result(opts.job2)
commits_directory = '/'.join(results_to_compare[0].split('/')[0:-3])
for commit in os.listdir(commits_directory):
    if commit != commit1:
        commit2 = commit

print('The first commit: %s' % commit1)
print('The second commit: %s' % commit2)
print('Result files to compare:')
print('\n'.join(results_to_compare))
print('\n')

os.chdir('../')
os.environ['LINUX_GIT'] = '/root/linux-linaro-stable'
if not os.path.exists('/root/linux-linaro-stable'):
    print('You may need to set environment variable by')
    print('    # export LINUX_GIT=/path/to/linux/kernel/repo')
    print ('It should not impact finally comparison result, \
           but you may see some warnings')
if not os.path.exists('lkp-tests'):
    subprocess.check_ouput(['git', 'clone',
                            'https://github.com/chase-qi/lkp-tests'])

# Compare test scores and store them in dict_comparison dictionary.
dict_comparison = {}
for result_file_commit1 in results_to_compare:
    subtest_id = result_file_commit1.split('/')[3]
    result_directory = '/'.join(result_file_commit1.split('/')[0:-3])
    json_data_commit1 = open(result_file_commit1)
    dict_commit1 = json.load(json_data_commit1)

    result_file_commit2 = result_file_commit1.split('/')
    result_file_commit2[-3] = commit2
    result_file_commit2 = '/'.join(result_file_commit2)
    if not os.path.exists(result_file_commit2):
        key = result_file_commit1.split('/')[2] + '-' + subtest_id
        dict_comparison[key] = 'NA'
        continue
    else:
        json_data_commit2 = open(result_file_commit2)
        dict_commit2 = json.load(json_data_commit2)

    for item in dict_commit1:
        key = item + '-' + subtest_id
        if item in dict_commit2:
            lkp_compare = ['./lkp-tests/sbin/compare',
                           '-d', 'commit', '-f', item,
                           result_directory + '/' + commit1,
                           result_directory + '/' + commit2]
            lkp_output = subprocess.check_output(lkp_compare)
            # Keep the last GEO-MEAN comparison line only.
            lkp_output = lkp_output.split('\n')[5]
            # Strip extra withe spaces.
            lkp_output = lkp_output.split()
            # Store test case and result diff to dict_comparison.
            dict_comparison[key] = lkp_output[1]
        else:
            dict_comparison[key] = 'NA'

    json_data_commit1.close()
    json_data_commit2.close()

# Print comparison results and save them to txt file.
output = open(commit1[0:8] + '_' + commit2[0:8] + '_comparison.txt', 'w')
header = commit1[0:8] + '/' + commit2[0:8] + '\tmeasurement-testcase'
print(header)
output.write(header + '\n')
for item in sorted(dict_comparison):
    line = dict_comparison[item] + '\t\t\t' + item
    print(line)
    output.write(line + '\n')
output.close()
print('Result saved to %s_%s_comparison.txt' % (commit1[0:8], commit2[0:8]))
