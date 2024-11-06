resource "aws_mwaa_environment" "demo" {
  airflow_configuration_options = {
    "core.default_task_retries" = "3"
  }
  airflow_version    = "2.3.2"
  dag_s3_path        = "dags/"
  environment_class  = "mw1.small"
  execution_role_arn = aws_iam_role.mwaa_role.arn
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
  max_workers = 5
  min_workers = 1
  name        = "demo-mwaa-environment"
  network_configuration {
    security_group_ids = [aws_security_group.mwaa_security_group.id]
    subnet_ids         = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
  }
  plugins_s3_object_version        = ""
  plugins_s3_path                  = ""
  requirements_s3_object_version   = "1"
  requirements_s3_path             = "requirements.txt"
  startup_script_s3_object_version = "1"
  startup_script_s3_path           = "startup.sh"
  source_bucket_arn                = aws_s3_bucket.mwaa_bucket.arn
  webserver_access_mode            = "PUBLIC_ONLY"
  weekly_maintenance_window_start  = "MON:00:00"
}

resource "aws_iam_role" "mwaa_role" {
  name = "mwaa-execution-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "airflow.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_s3_bucket" "mwaa_bucket" {
  bucket = "demo-mwaa-bucket"
}

resource "aws_s3_object" "requirements" {
  bucket = aws_s3_bucket.mwaa_bucket.id

  key    = "requirements.txt"
  source = "./mwaa/requirements.txt"
}

resource "aws_s3_object" "startup" {
  bucket = aws_s3_bucket.mwaa_bucket.id

  key    = "startup.sh"
  source = "./mwaa/startup.sh"
}
