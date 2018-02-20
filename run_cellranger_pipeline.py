# # Single Sample Pipeline
# ###########################################
# from common_utils.s3_utils import download_file, upload_file, download_folder, upload_folder
# from common_utils.job_utils import generate_working_dir, delete_working_dir

import re
import yaml
import pandas as pd
import glob
import json
import sys
import boto3
import botocore
import os
import shlex
import subprocess
from common_utils.s3_utils import download_file, upload_file, download_folder, upload_folder
from common_utils.job_utils import generate_working_dir, delete_working_dir

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



# check available disk space
cmd = "df -h"
subprocess.check_call(shlex.split(cmd))

# move into scratch directory
os.chdir('scratch')

# Copy files from S3
###########################################

# refdata
inst_bucket = 'cellranger_bucket'
s3_folder = 'refdata-cellranger-GRCh38-1.2.0'
s3_path = 's3://'+inst_bucket + '/' + s3_folder
download_folder(s3_path, 'refdata-cellranger-GRCh38-1.2.0')

# tiny-bcl
inst_bucket = 'cellranger_bucket'
s3_folder = 'tiny-bcl'
s3_path = 's3://'+inst_bucket + '/' + s3_folder
download_folder(s3_path, 'tiny-bcl')

# check refdata
cmd = "ls -l refdata-cellranger-GRCh38-1.2.0"
subprocess.check_call(shlex.split(cmd))

# Run Cellranger
############################################

# cellranger mkfastqs
cmd = 'cellranger mkfastq --id=tiny-bcl-output --run=tiny-bcl/cellranger-tiny-bcl-1.2.0/ --csv=tiny-bcl/cellranger-tiny-bcl-samplesheet-1.2.0.csv'
subprocess.check_call(shlex.split(cmd))

# cellranger count
cmd = 'cellranger count --id=test_sample --fastqs=tiny-bcl-output/outs/fastq_path/p1/s1 --sample=test_sample --expect-cells=1000 --localmem=3 --chemistry=SC3Pv2 --transcriptome=refdata-cellranger-GRCh38-1.2.0'
subprocess.check_call(shlex.split(cmd))


# # Copy data back to S3
# ###########################

# # copy mkfastq outputs
# s3_path = 's3://'+inst_bucket + '/tiny-bcl-output'
# fcs_files_path = 'tiny-bcl-output'
# upload_folder(s3_path, fcs_files_path)

# # copy count outputs
# s3_path = 's3://'+inst_bucket + '/something'
# fcs_files_path = 'something'
# upload_folder(s3_path, fcs_files_path)