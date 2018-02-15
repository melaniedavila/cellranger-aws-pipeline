# # Single Sample Pipeline
# ###########################################
# from common_utils.s3_utils import download_file, upload_file, download_folder, upload_folder
# from common_utils.job_utils import generate_working_dir, delete_working_dir

# import re
# import yaml
# import pandas as pd
# import glob
# import json
# import sys
# import boto3
# import botocore
# import os
# import subprocess

# ###############################################################################
# #
# # parse arguments
# #
# ###############################################################################
# # the first element in the script name, the second is the first argument
# # the argument is specified by the cloudformation json
# print('----------- CELLRANGER PIPELINE --------------\n\n')
# print('parsing argument data\n------------------------------')
# try:
#   arg_string = sys.argv[1]
#   arg_dict = json.loads(arg_string)

#   inst_bucket = arg_dict['bucket']
#   inst_fcs = arg_dict['inst_fcs']

#   print('the bucket is: ' + str(inst_bucket))
#   print('the folder has been hard wired')
#   print('inst_fcs: ' + str(inst_fcs))

#   s3_folder = 'cytof_pipeline_data'

# except:
#   print('------------------------------')
#   print('unable to parse argument json')
#   print('------------------------------')


import shlex
import subprocess
cmd = "df -h"
subprocess.check_call(shlex.split(cmd))

cmd = "ls"
subprocess.check_call(shlex.split(cmd))

# Single Sample Pipeline
###########################################
from common_utils.s3_utils import download_file, upload_file, download_folder, upload_folder
from common_utils.job_utils import generate_working_dir, delete_working_dir

inst_bucket = 'cellranger_bucket'
# s3_folder = 'tiny-bcl'
s3_folder = 'refdata-cellranger-GRCh38-1.2.0'
s3_path = 's3://'+inst_bucket + '/' + s3_folder
download_folder(s3_path, 'scratch')

cmd = "ls scratch"
subprocess.check_call(shlex.split(cmd))