terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.67.0"
    }
  }
  required_version = ">= 1.4.0"
}

provider "aws" {
  region = "eu-central-1"
  default_tags {
    tags = {
      environment = "qdrant-vector-db"
    }
  }
}

# VPC resource

resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
}

# Define public subnet

resource "aws_subnet" "subnet" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.public_subnet_cidr
  availability_zone = var.aws_az
}

# Define internet gateway

resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route" "route" {
  route_table_id         = aws_vpc.vpc.default_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gateway.id

}

# Create a security group

resource "aws_security_group" "sg" {
  name        = "qdrant-security-group"
  description = "Allow incoming http(s) and ssh to withoutsystems instances"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 6333
    to_port     = 6333
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "qdrant"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create ECS Cluster

resource "aws_ecs_cluster" "cluster" {
  name = "qdrant-vectordb-cluster"
}

# Create a task definition for Fargate service
resource "aws_ecs_task_definition" "task" {
  family                   = "qdrant-vectordb-task"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "1024"
  network_mode             = "awsvpc"

  container_definitions = file("tasks/qdrant-vectordb-task.json")
}

resource "aws_ecs_service" "service" {
  name            = "qdrant-vectordb-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.sg.id]
    subnets          = [aws_subnet.subnet.id]
    assign_public_ip = true
  }
}
