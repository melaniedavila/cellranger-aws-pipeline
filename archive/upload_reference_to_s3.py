'''
Upload cellranger data to S3
-----------------------------
This script makes a S3 bucket and uploads data
'''

import boto3
import glob
from common_utils.s3_utils import download_file, upload_file, download_folder, upload_folder

inst_bucket = 'cellranger_bucket'

# # make s3 bucket
# #################
# s3 = boto3.client('s3')
# s3.create_bucket(Bucket=inst_bucket)

# common_utils upload
#########################
s3_path = 's3://'+inst_bucket + '/refdata-cellranger-GRCh38-1.2.0'
local_files_path = 'refdata-cellranger-GRCh38-1.2.0'
upload_folder(s3_path, local_files_path)