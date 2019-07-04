# Don't edit this file unless you know what you're doing.

# This file defines the networking resources that the cellranger
# pipeline depends on; the `cellranger-pipeline` VPC is the largest of
# these resources, and it contains everything else defined in this
# file.

# These resources are foundational to the pipeline; we build upon
# them, and they are unlikely to be changed.

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
  name   = "all-outbound"
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
