from optparse import OptionParser
import base64
import json
import netrc
import requests
import urlparse
import xmlrpclib


class LavaServerException(Exception):
    def __init__(self, name):
        self.name = name

    def __str__(self):
        return repr(self.name)


class LavaProxy(object):
    def __init__(self, url, username, password):
        self.xmlrpc_url = url
        self.username = username
        self.password = password

    def get_test_job_status(self, job_id):
        return self.__call_xmlrpc('scheduler.job_status', job_id)

    def get_result_bundle(self, job_id):
        job_status = self.get_test_job_status(job_id)
        if "bundle_sha1" in job_status:
            return self.__call_xmlrpc('dashboard.get', job_status["bundle_sha1"])
        return None

    def __call_xmlrpc(self, method_name, *method_params):
        payload = xmlrpclib.dumps((method_params), method_name)

        response = requests.request('POST', self.xmlrpc_url,
                                    data = payload,
                                    headers = {'Content-Type': 'application/xml'},
                                    auth = (self.username, self.password),
                                    timeout = 100,
                                    stream = False)

        if response.status_code == 200:
            result = xmlrpclib.loads(response.content)[0][0]
            return result
        else:
            raise LavaServerException(response.status_code)

def save_attachment(attachment_dict):
    f = open(attachment_dict['pathname'], "w")
    f.write(base64.b64decode(attachment_dict['content']))
    f.close()

def match_attachment(pattern, attachment_dict):
    if attachment['pathname'].startswith(options.attachment_prefix):
        print "saving %s" % attachment['pathname']
        save_attachment(attachment)

if __name__ == '__main__':
    parser = OptionParser()
    parser.add_option("-n", "--name", dest="attachment_prefix",
                  help="prefix of the attachment name to extract")
    parser.add_option("-l", "--lava", dest="lava_url",
                  help="LAVA XML-RPC endpoint URL")
    parser.add_option("-i", "--job-id", dest="lava_job_id",
                  help="LAVA job ID")

    (options, args) = parser.parse_args()
    if not options.attachment_prefix:
        parser.error("Prefix is mandatory!")
    if not options.lava_url:
        parser.error("LAVA URL is mandatory!")

    netrcauth = netrc.netrc()
    urlparser = urlparse.urlparse(options.lava_url)
    username, account, password = netrcauth.authenticators(urlparser[1]) # netloc

    proxy = LavaProxy(options.lava_url, username, password)
    if options.lava_job_id:
        bundle = proxy.get_result_bundle(options.lava_job_id)
        bundle_content = json.loads(bundle['content'])
        for test_run in bundle_content['test_runs']:
            if 'attachments' in test_run.keys():
                for attachment in test_run['attachments']:
                    match_attachment(options.attachment_prefix, attachment)
            for result in test_run['test_results']:
                if 'attachments' in result.keys():
                    for attachment in result['attachments']:
                        match_attachment(options.attachment_prefix, attachment)
