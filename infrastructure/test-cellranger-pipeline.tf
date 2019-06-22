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
  role       = "${aws_iam_role.ecs_instance_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_instance_role" {
  name = "ecsInstanceRole"
  role = "${aws_iam_role.ecs_instance_role.name}"
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
  role       = "${aws_iam_role.aws_batch_service_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
}

resource "aws_vpc" "test-cellranger-pipeline" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "test-cellranger-pipeline"
  }
}

resource "aws_subnet" "main" {
  vpc_id = "${aws_vpc.test-cellranger-pipeline.id}"
  cidr_block = "10.0.0.0/24"

  tags = {
    Name = "main"
  }
}

resource "aws_security_group" "test-cellranger-pipeline" {
  name = "test-cellranger-pipeline"
  vpc_id = "${aws_vpc.test-cellranger-pipeline.id}"
}

resource "aws_batch_compute_environment" "test-cellranger-pipeline" {
  compute_environment_name = "test-cellranger-pipeline"
  type = "MANAGED"

  compute_resources {
    image_id = "ami-000f5114abc141b76"

    instance_role = "${aws_iam_instance_profile.ecs_instance_role.arn}"
    instance_type = ["r5.4xlarge"]

    max_vcpus = 256
    min_vcpus = 0

    security_group_ids = ["${aws_security_group.test-cellranger-pipeline.id}"]

    subnets = ["${aws_subnet.main.id}"]

    tags = {
      # TODO: don't repeat this name, we already defined above
      "Name" = "test-cellranger-pipeline"
    }

    type = "EC2"
  }

  service_role = "${aws_iam_role.aws_batch_service_role.arn}"
  depends_on   = ["aws_iam_role_policy_attachment.aws_batch_service_role"]
}

# END COMPUTE ENVIRONMENT RESOURCES

resource "aws_batch_job_queue" "test-cellranger-pipeline" {
  name = "test-cellranger-pipeline"
  state                = "ENABLED"
  priority             = 10
  compute_environments = ["${aws_batch_compute_environment.test-cellranger-pipeline.arn}"]
}

# TODO: DRY up the job definitions
resource "aws_batch_job_definition" "test-cellranger-pipeline-cellranger-2_2_0-bcl2fastq-2_20_0" {
  name = "test-cellranger-pipeline-cellranger-2_2_0-bcl2fastq-2_20_0"
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

resource "aws_batch_job_definition" "test-cellranger-pipeline-cellranger-3_0_2-bcl2fastq-2_20_0" {
  name = "test-cellranger-pipeline-cellranger-3_0_2-bcl2fastq-2_20_0"
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
resource "aws_ecr_repository" "cellranger-2_2_0-bcl2fastq-2_20_0" {
  name = "cellranger-2.2.0-bcl2fastq-2.20.0"
}

resource "aws_ecr_repository" "cellranger-3_0_2-bcl2fastq-2_20_0" {
  name = "cellranger-3.0.2-bcl2fastq-2.20.0"
}
