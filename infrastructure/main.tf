provider "aws" {
  region  = "us-east-1"
  version = "~> 2.15"
}

# BEGIN COMPUTE ENVIRONMENT RESOURCES

resource "aws_iam_role" "ecs_instance_role" {
  name = "ecsInstanceRole"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
    {
        "Action": "sts:AssumeRole",
        "Effect": "Allow",
        "Principal": {
        "Service": "ec2.amazonaws.com"
        }
    }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs_instance_role" {
  role = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_instance_role" {
  name = "ecsInstanceRole"
  role = aws_iam_role.ecs_instance_role.name
}

resource "aws_iam_role" "aws_batch_service_role" {
  name = "AWSBatchServiceRole"
  path = "/service-role/"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Effect": "Allow",
            "Principal": {
                "Service": "batch.amazonaws.com"
            }
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "aws_batch_service_role" {
  role       = aws_iam_role.aws_batch_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
}

# BEGIN VPC

resource "aws_vpc" "this" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "cellranger-pipeline"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "public"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
}

resource "aws_security_group" "all_outbound" {
  name   = "all-inbound"
  vpc_id = aws_vpc.this.id
}

resource "aws_security_group_rule" "allow_all_outbound" {
  # this rule is necessary because batch won't be able to launch
  # containers without it. see
  # https://aws.amazon.com/premiumsupport/knowledge-center/batch-job-stuck-runnable-status/
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "all"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.all_outbound.id
}

# END VPC


















resource "aws_batch_compute_environment" "cellranger_pipeline" {
  compute_environment_name = "${var.environment}-cellranger-pipeline"
  type                     = "MANAGED"

  compute_resources {
    # TEMP: debugging purposes
    ec2_key_pair = "cellranger-aws-pipeline"

    image_id = "ami-000f5114abc141b76"

    instance_role = aws_iam_instance_profile.ecs_instance_role.arn
    instance_type = ["r5.4xlarge"]

    max_vcpus = 256
    min_vcpus = 0

    security_group_ids = [aws_security_group.all_outbound.id]

    subnets = [aws_subnet.public.id]

    tags = {
      # TODO: don't repeat this name, we already defined above
      "Name" = "${var.environment}-cellranger-pipeline"
    }

    type = "EC2"
  }

  service_role = aws_iam_role.aws_batch_service_role.arn
  depends_on   = ["aws_iam_role_policy_attachment.aws_batch_service_role"]
}

# END COMPUTE ENVIRONMENT RESOURCES

resource "aws_batch_job_queue" "this" {
  name                 = "${var.environment}-cellranger-pipeline"
  state                = "ENABLED"
  priority             = 10
  compute_environments = [aws_batch_compute_environment.cellranger_pipeline.arn]
}

# TODO: DRY up the job definitions
resource "aws_batch_job_definition" "cellranger_2_2_0_bcl2fastq_2_20_0" {
  name = "${var.environment}-cellranger-pipeline-cellranger-2_2_0-bcl2fastq-2_20_0"
  type = "container"

  retry_strategy {
    attempts = 1
  }

  timeout {
    attempt_duration_seconds = 129600
  }

  container_properties = <<CONTAINER_PROPERTIES
{
  "image": "402084680610.dkr.ecr.us-east-1.amazonaws.com/cellranger-2.2.0-bcl2fastq-2.20.0",
  "vcpus": 16,
  "memory": 126976,
  "command": [
    "Ref::command",
    "Ref::configuration"
  ],
  "jobRoleArn": "arn:aws:iam::402084680610:role/cellranger-pipeline",
  "volumes": [
    {
      "host": {
        "sourcePath": "/docker_scratch"
      },
      "name": "scratch"
    }
  ],
  "environment": [
    {
      "name": "DEBUG",
      "value": "false"
    }
  ],
  "mountPoints": [
    {
      "containerPath": "/home/cellranger/scratch",
      "sourceVolume": "scratch"
    }
  ],
  "ulimits": []
}
CONTAINER_PROPERTIES
}

resource "aws_batch_job_definition" "cellranger_3_0_2_bcl2fastq_2_20_0" {
  name = "${var.environment}-cellranger-pipeline-cellranger-3_0_2-bcl2fastq-2_20_0"
  type = "container"

  retry_strategy {
    attempts = 1
  }

  timeout {
    attempt_duration_seconds = 129600
  }

  container_properties = <<CONTAINER_PROPERTIES
{
  "image": "402084680610.dkr.ecr.us-east-1.amazonaws.com/cellranger-3.0.2-bcl2fastq-2.20.0",
  "vcpus": 16,
  "memory": 126976,
  "command": [
    "Ref::command",
    "Ref::configuration"
  ],
  "jobRoleArn": "arn:aws:iam::402084680610:role/cellranger-pipeline",
  "volumes": [
    {
      "host": {
        "sourcePath": "/docker_scratch"
      },
      "name": "scratch"
    }
  ],
  "environment": [
    {
      "name": "DEBUG",
      "value": "false"
    }
  ],
  "mountPoints": [
    {
      "containerPath": "/home/cellranger/scratch",
      "sourceVolume": "scratch"
    }
  ],
  "ulimits": []
}
CONTAINER_PROPERTIES
}

# TODO: dry this up
resource "aws_ecr_repository" "cellranger_2_2_0_bcl2fastq_2_20_0" {
  name = "cellranger-2.2.0-bcl2fastq-2.20.0"
}

resource "aws_ecr_repository" "cellranger_3_0_2_bcl2fastq_2_20_0" {
  name = "cellranger-3.0.2-bcl2fastq-2.20.0"
}
