import boto3
client_ecr = boto3.client('ecr')

# single job repo
response = client_ecr.create_repository(repositoryName='awsbatch/cellranger-aws-pipeline')
print(response['repository']['repositoryUri'])
