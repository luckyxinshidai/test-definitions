#!/usr/bin/env python
import os
import sys
import shutil
import glob
import subprocess
import json
from optparse import OptionParser

LAVA_JOB1 = sys.argv[1]
LAVA_JOB2 = sys.argv[2]
WD = os.getcwd()


def get_result(lava_job):
    print('Downloading %s lkp test results...' % lava_job)
    subprocess.call(['../lavadownload.py', '-n', 'lkp-result',
                     '-l', 'https://validation.linaro.org/RPC2/',
                     '-i', lava_job])
    for result_package in glob.glob('*.tar.xz'):
        subprocess.check_output(['tar', 'xvf', result_package])
        os.remove(result_package)
    shutil.rmtree('/result', ignore_errors=True)
    shutil.copytree('./result', '/result')


if os.path.exists('./downloads'):
    shutil.rmtree('./downloads', ignore_errors=True)
os.makedirs('./downloads')
os.chdir('./downloads')

get_result(LAVA_JOB1)
results_to_compare = []
benchmarks = os.listdir('/result')
for benchmark in benchmarks:
    for root, dirs, files in os.walk('/result/' + benchmark):
        if benchmark + '.json' in files:
            file_path = os.path.join(root, benchmark + '.json')
            results_to_compare.append(file_path)
commit1 = results_to_compare[0].split('/')[-3]

get_result(LAVA_JOB2)
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
# todo, add linux repo check.
if not os.path.exists('lkp-tests'):
    subprocess.check_ouput(['git', 'clone',
                            'https://github.com/chase-qi/lkp-tests'])

result_dict = {}
for result_file in results_to_compare:
    subtest_id = result_file.split('/')[3]
    result_directory = '/'.join(result_file.split('/')[0:-3])
    json_data = open(result_file)
    dict = json.load(json_data)
    for item in dict:
        diff = subprocess.check_output(['./lkp-tests/sbin/compare', '-f', item,
                                        result_directory + '/' + commit1,
                                        result_directory + '/' + commit2])
        key = subtest_id + '-' + item
        result_dict[key] = diff.split('\n')[5] + '-' + subtest_id
    json_data.close()

# Print comparison results and save them to txt file.
output = open(commit1[0:7] + '_' + commit2[0:7] + '_comparison.txt', 'w')
header = LAVA_JOB1 + '-' + commit1[0:7] + '      %changes  ' + \
    LAVA_JOB2 + '-' + commit2[0:7] + '  test_measurement-testcase'
print(header)
output.write(header + '\n')
for item in sorted(result_dict):
    print result_dict[item]
    output.write(result_dict[item] + '\n')
output.close()
print('Result saved to %s_%s_comparison.txt' % (commit1[0:7], commit2[0:7]))
