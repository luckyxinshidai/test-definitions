reboot_policy = 'as_needed'
execution_order = 'by_iteration'
device = 'generic_linux'
device_config = dict(
    host = '10.0.0.13',
    username = 'root',
    password = 'linarolinaro'
)
instrumentation = [
    'execution_time',
]
result_processors = [
    'standard',
    'csv',
    'summary_csv',
]
logging = {
    'file format': '%(asctime)s %(levelname)-8s %(name)s: %(message)s',
    'verbose format': '%(asctime)s %(levelname)-8s %(name)s: %(message)s',
    'regular format': '%(levelname)-8s %(message)s',
    'colour_enabled': True,
}
