# VPC Configuration
resource "aws_vpc" "mwaa_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "mwaa-vpc"
  }
}

# Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.mwaa_vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "mwaa-public-subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.mwaa_vpc.id

  tags = {
    Name = "mwaa-internet-gateway"
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat_eip" {
  tags = {
    Name = "mwaa-nat"
  }
}

# NAT Gateway
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id

  tags = {
    Name = "mwaa-nat-gateway"
  }
}


# Subnet Configuration
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.mwaa_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  map_public_ip_on_launch = false

  tags = {
    Name = "mwaa-private-subnet-1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.mwaa_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  map_public_ip_on_launch = false

  tags = {
    Name = "mwaa-private-subnet-2"
  }
}

# Security Group for MWAA
resource "aws_security_group" "mwaa_security_group" {
  vpc_id      = aws_vpc.mwaa_vpc.id
  description = "Security group for MWAA environment"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Route Table for Private Subnet 1
resource "aws_route_table" "private_route_table_1" {
  vpc_id = aws_vpc.mwaa_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    Name = "private-route-table-1"
  }
}

resource "aws_route_table_association" "private_route_association_1" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_route_table_1.id
}

# Route Table for Private Subnet 2
resource "aws_route_table" "private_route_table_2" {
  vpc_id = aws_vpc.mwaa_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    Name = "private-route-table-2"
  }
}

resource "aws_route_table_association" "private_route_association_2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_route_table_2.id
}


# IAM Role for MWAA Execution
resource "aws_iam_role" "mwaa_role" {
  name               = "mwaa-execution-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "airflow-env.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "custom_mwaa_policy" {
  name        = "CustomMWAAFullAccess"
  description = "Custom policy with Amazon MWAA permissions."

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "airflow:*",
                "cloudwatch:PutMetricData",
                "cloudwatch:GetMetricData",
                "cloudwatch:ListMetrics",
                "ec2:DescribeNetworkInterfaces",
                "ec2:CreateNetworkInterface",
                "ec2:DeleteNetworkInterface",
                "ec2:DescribeSubnets",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeVpcs",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:BatchCheckLayerAvailability",
                "iam:PassRole",
                "kms:Decrypt",
                "kms:DescribeKey",
                "kms:GenerateDataKey",
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:PutLogEvents",
                "s3:GetObject",
                "s3:ListBucket"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "mwaa_policy_attachment" {
  role       = aws_iam_role.mwaa_role.name
  policy_arn = aws_iam_policy.custom_mwaa_policy.arn
}

resource "aws_iam_policy" "mwaa_s3_access_policy" {
  name        = "mwaa-s3-access-policy"
  description = "Permisos para acceso a S3 necesarios para MWAA"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket",
        "s3:GetBucketPublicAccessBlock"
      ],
      "Resource": "*" 
    },
     {
      "Effect": "Allow",
      "Action": "s3:GetAccountPublicAccessBlock",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach_mwaa_s3_access_policy" {
  role       = aws_iam_role.mwaa_role.name
  policy_arn = aws_iam_policy.mwaa_s3_access_policy.arn
}

# S3 Bucket for MWAA DAGs and requirements
resource "aws_s3_bucket" "mwaa_bucket" {
  bucket_prefix = "demo-mwaa"


  tags = {
    Name = "mwaa-bucket"
  }
}

# Upload requirements.txt to S3
resource "aws_s3_object" "requirements" {
  bucket = aws_s3_bucket.mwaa_bucket.id
  key    = "requirements.txt"
  source = "./mwaa/requirements.txt"
  etag   = filemd5("./mwaa/requirements.txt")
}

# Upload startup.sh to S3
resource "aws_s3_object" "startup" {
  bucket = aws_s3_bucket.mwaa_bucket.id
  key    = "startup.sh"
  source = "./mwaa/startup.sh"
  etag   = filemd5("./mwaa/startup.sh")
}

# MWAA Environment Configuration
resource "aws_mwaa_environment" "demo" {
  name                             = "demo-mwaa-environment2"
  airflow_version                  = "2.8.1"
  environment_class                = "mw1.small"
  execution_role_arn               = aws_iam_role.mwaa_role.arn
  source_bucket_arn                = aws_s3_bucket.mwaa_bucket.arn
  dag_s3_path                      = "dags/"
  plugins_s3_path                  = ""
  plugins_s3_object_version        = ""
  requirements_s3_path             = "requirements.txt"
  requirements_s3_object_version   = ""
  startup_script_s3_path           = "startup.sh"
  startup_script_s3_object_version = ""
  webserver_access_mode            = "PUBLIC_ONLY"

  logging_configuration {
    dag_processing_logs {
      enabled   = true
      log_level = "INFO"
    }
    scheduler_logs {
      enabled   = true
      log_level = "INFO"
    }
    task_logs {
      enabled   = true
      log_level = "INFO"
    }
    webserver_logs {
      enabled   = true
      log_level = "INFO"
    }
    worker_logs {
      enabled   = true
      log_level = "INFO"
    }
  }

  network_configuration {
    security_group_ids = [aws_security_group.mwaa_security_group.id]
    subnet_ids         = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
  }

  weekly_maintenance_window_start = "MON:00:00"
  min_workers                     = 1
  max_workers                     = 5
}
#
