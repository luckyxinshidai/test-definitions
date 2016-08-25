#!/usr/bin/env python
import os
import sys
import json
from subprocess import call

JOB_ID = sys.argv[1]
AGENDA = sys.argv[2]
IPDATA = sys.argv[3]
WA_OUTPUT = os.path.expanduser('~') + '/.workload_automation/wa_output'
RESULTS_FILE = WA_OUTPUT + '/results.json'

# Amend device config

# Run workloads

# Parse results.json file, send test results to LAVA.
json_data = open(RESULTS_FILE)
results = json.load(json_data)

for result in results:
    metrics = result['metrics']
    for metric in metrics:
        test_case_id = (result['workload'] + '-iteration' +
                        str(result['iteration']) + '-' + 
                        metric['name'].replace(' ', '-'))
        result_measurement = metric['value']
        result_units = metric['units']
        print('%s result: pass, measurement: %s, units: %s' % (test_case_id, result_measurement, result_units))
        #call('lava-test-case', test_case_id, '--result', 'pass',
        #     '--measurement', result_measurement, '--units', result_units)

# Compress and attach raw data.
call(['tar', 'caf', 'wa-output-' + JOB_ID + '.tar.xz', WA_OUTPUT])
call(['lava-test-run-attach', 'wa-output-' + JOB_ID + '.tar.xz'])
