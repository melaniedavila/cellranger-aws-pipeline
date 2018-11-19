# # Single Sample Pipeline
# ###########################################
# from common_utils.s3_utils import download_file, upload_file, download_folder, upload_folder
# from common_utils.job_utils import generate_working_dir, delete_working_dir

# import re
# import yaml
import pandas as pd
# import glob
# import json
# import sys
import tarfile
import boto3
import botocore
import os
import shlex
import subprocess
from common_utils.s3_utils import download_file, upload_file, download_folder, upload_folder
from common_utils.job_utils import generate_working_dir, delete_working_dir

# check available disk space
subprocess.check_call(shlex.split('df -h'))

directory = 'scratch'
if not os.path.exists(directory):
    os.makedirs(directory)

# move into scratch directory
os.chdir('scratch')


################## TODO ###################
# # Job 1
# 1. Decompress raw data
# 2. Download config file
# 3. Create sample sheet
# 4. Cellranger mkfastq

# # Job 2 (runs after successful completion of job one, for each sample @ the 
# same time)
# 1. Download config file
# 2. One sample at a time:
# 	a. extract params to run cellranger count from config file:
# 		- sample_id
# 		- fastq path
# 		- index
# 		- job mode (maybe not?)
# 		- expect-cells
# 		- reference reference_transcriptome


def run_bash_command(command):
	print('In-Progress: ' + command + '\n\n')
	completed_process = subprocess.run(
	args = command.split(' '),
	stdout = subprocess.PIPE,
	stderr = subprocess.STDOUT,
	)

	completed_process.check_returncode()
	completed_process_stdout = completed_process.stdout.decode('utf-8')
	return completed_process_stdout


bucket = '10x-pipeline'
# 1. Download and decompress raw data:
s3_folder = 'run_tiny_bcl_himc_0_181116'
s3_path = f"s3://{bucket}/{s3_folder}/raw_data"
download_folder(s3_path, 'raw_data')

raw_data_filename = run_bash_command('ls raw_data')
print('RAW DATA FILENAME: ' + raw_data_filename)
filepath = ('/').join(['raw_data', raw_data_filename])
print('FILEPATH: ' + filepath)

filepath = filepath.rstrip('\n')
print('FILEPATH: ' + filepath)

tar = tarfile.open('raw_data/cellranger-tiny-bcl-1.2.0.tar.gz')
tar.extractall('raw_data')
tar.close()

# print('os.lisdir(raw_data)')
# print(os.listdir('raw_data'))

# 2. Download config file and extract sample_name and sample_index_location 
# parameters
s3_path = f"s3://{bucket}/{s3_folder}/config"
download_folder(s3_path, 'config')
os.listdir('config')
config = pd.read_csv('config/config.csv')

# sample_names = config['sample_name'].values
# print(sample_names)

samplesheet = pd.DataFrame(columns=['Lane','Sample_ID','Sample_Name','index'])

for index, row in config.iterrows():
    lane = ''
    sample_id = row['sample_index_location']
    sample_name = row['sample_name']
    index = sample_id
    row = pd.Series([lane, sample_id, sample_name, index], index = ['Lane', 
    									'Sample_ID', 'Sample_Name', 'index'])
    samplesheet = samplesheet.append(row, ignore_index=True)    

print(samplesheet)

#3. Run cellranger mkfastq

# cellranger mkfastq \
# --run=/sc/orga/projects/HIMC/chromium/run448_himc54_092518/raw_data/180925_NS500672_0448_AH25MLBGX9 \
# --samplesheet=/sc/orga/projects/HIMC/chromium/run448_himc54_092518/samplesheets/ss_092518_gex.csv

###########################################

# Copy files from S3
###########################################

# refdata
# bucket = '10x-pipeline'
# s3_folder = 'reference_transcriptome'
# version = '1.2.0'
# ref_trans = 'GRCh38'
# s3_path = f"s3://{bucket}/{s3_folder}/{version}"
# download_folder(s3_path, ref_trans)

# s3_folder = 'run_tiny_bcl_himc_0_181116'
# s3_path = f"s3://{bucket}/{s3_folder}/raw_data"
# download_folder(s3_path, 'raw_data')

# check refdata
# cmd = f"ls -l {ref_trans}"
# subprocess.check_call(shlex.split(cmd))

# Run Cellranger MKFASTQ and COUNT
############################################

# # cellranger mkfastqs
# cmd = 'cellranger mkfastq --id=tiny-bcl-output --run=tiny-bcl/cellranger-tiny-bcl-1.2.0/ --csv=tiny-bcl/cellranger-tiny-bcl-samplesheet-1.2.0.csv'
# subprocess.check_call(shlex.split(cmd))

# #
# # use full path for reference transcriptome
# #

# # cellranger count
# cmd = 'cellranger count --id=test_sample --fastqs=tiny-bcl-output/outs/fastq_path/p1/s1 --sample=test_sample --expect-cells=1000 --localmem=3 --chemistry=SC3Pv2 --transcriptome=refdata-cellranger-GRCh38-1.2.0'
# subprocess.check_call(shlex.split(cmd))


# # # Copy data back to S3
# # ###########################

# # copy mkfastq outputs
# s3_path = 's3://' + bucket + '/tiny-bcl-output'
# fcs_files_path = 'tiny-bcl-output'
# upload_folder(s3_path, fcs_files_path)

# # copy count outputs
# s3_path = 's3://' + bucket + '/test_sample'
# fcs_files_path = 'test_sample'
# upload_folder(s3_path, fcs_files_path)