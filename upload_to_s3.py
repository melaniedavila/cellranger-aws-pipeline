'''
Upload data to S3
------------------
This script makes a S3 bucket and uploads data
'''

import boto3
import glob
from common_utils.s3_utils import download_file, upload_file, download_folder, upload_folder

inst_bucket = 'cellranger_bucket'

# make s3 bucket
#################
s3 = boto3.client('s3')
s3.create_bucket(Bucket=inst_bucket)

# common_utils upload
#########################
s3_path = 's3://'+inst_bucket + '/tiny-bcl'
fcs_files_path = 'tiny-bcl'
upload_folder(s3_path, fcs_files_path)

# s3_path = 's3://'+inst_bucket + '/cytof_pipeline_data/pipeline-configs'
# fcs_files_path = 'cytof_pipeline_data/pipeline-configs'
# upload_folder(s3_path, fcs_files_path)

# print('uploaded cytof_pipeline_data files to s3')
