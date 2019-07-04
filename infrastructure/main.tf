provider "aws" {
  region  = "us-east-1"
  version = "~> 2.15"
}

resource "aws_iam_role" "ecs_instance_role" {
  name = "ecsInstanceRole"

  assume_role_policy = jsonencode(
    {
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = {
            Service = "ec2.amazonaws.com"
          }
        },
      ]
      Version = "2012-10-17"
    }
  )
}

resource "aws_iam_role_policy_attachment" "ecs_instance_role" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_instance_role" {
  name = "ecsInstanceRole"
  role = aws_iam_role.ecs_instance_role.name
}

resource "aws_iam_role" "aws_batch_service_role" {
  name               = "AWSBatchServiceRole"
  path               = "/service-role/"
  assume_role_policy = jsonencode(
    {
      Statement = [
        {
          Action    = "sts:AssumeRole"
          Effect    = "Allow"
          Principal = {
            Service = "batch.amazonaws.com"
          }
        },
      ]
      Version   = "2012-10-17"
    }
  )
}

resource "aws_iam_role_policy_attachment" "aws_batch_service_role" {
  role = aws_iam_role.aws_batch_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
}

resource "aws_batch_compute_environment" "cellranger_pipeline" {
  compute_environment_name = "${var.environment}-cellranger-pipeline"
  type = "MANAGED"

  compute_resources {
    image_id = "ami-0d36b4f4d3b46109a"

    instance_role = aws_iam_instance_profile.ecs_instance_role.arn
    instance_type = ["r5.4xlarge"]

    max_vcpus = 256
    min_vcpus = 0

    security_group_ids = [aws_security_group.all_outbound.id]

    subnets = [aws_subnet.public.id]

    tags = {
      "Name" = "${var.environment}-cellranger-pipeline"
    }

    type = "EC2"
  }

  service_role = aws_iam_role.aws_batch_service_role.arn
  depends_on = ["aws_iam_role_policy_attachment.aws_batch_service_role"]
}

resource "aws_batch_job_queue" "this" {
  name = "${var.environment}-cellranger-pipeline"
  state = "ENABLED"
  priority = 10
  compute_environments = [aws_batch_compute_environment.cellranger_pipeline.arn]
}

resource "aws_iam_role" "pipeline" {
  name        = "cellranger-pipeline"
  description = "Allow ECS containers to read input and write output to S3."
  assume_role_policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = {
            Service = "ecs-tasks.amazonaws.com"
          }
        },
      ]
    }
  )
}

resource "aws_batch_job_definition" "main" {
  count = length(var.cellranger_bcl2fastq_version_pairs)

  name = format(
    "%s-%s-%s",
    "${var.environment}-cellranger-pipeline",
    "cellranger-${replace(element(var.cellranger_bcl2fastq_version_pairs, count.index)["cellranger_version"], ".", "_")}",
    "bcl2fastq-${replace(element(var.cellranger_bcl2fastq_version_pairs, count.index)["bcl2fastq_version"], ".", "_")}"
  )
  type = "container"

  retry_strategy {
    attempts = 1
  }

  timeout {
    attempt_duration_seconds = 129600
  }

  container_properties = jsonencode(
    {
      command = [
        "Ref::command",
        "Ref::configuration",
      ]
      environment = [
        {
          name = "DEBUG"
          value = "false"
        },
      ]
      image = format(
        "402084680610.dkr.ecr.us-east-1.amazonaws.com/cellranger-%s-bcl2fastq-%s:%s",
        element(var.cellranger_bcl2fastq_version_pairs, count.index)["cellranger_version"],
        element(var.cellranger_bcl2fastq_version_pairs, count.index)["bcl2fastq_version"],
        var.image_tag
      )

      jobRoleArn = aws_iam_role.pipeline.arn

      memory = 126976
      vcpus = 16
      ulimits = []

      mountPoints = [
        {
          containerPath = "/home/cellranger/scratch"
          sourceVolume = "scratch"
        },
      ]
      volumes = [
        {
          host = {
            sourcePath = "/docker_scratch"
          }
          name = "scratch"
        },
      ]
    }
  )
}

resource "aws_ecr_repository" "main" {
  count = length(var.cellranger_bcl2fastq_version_pairs)

  name = format(
    "cellranger-%s-bcl2fastq-%s",
    element(var.cellranger_bcl2fastq_version_pairs, count.index)["cellranger_version"],
    element(var.cellranger_bcl2fastq_version_pairs, count.index)["bcl2fastq_version"]
  )
}
