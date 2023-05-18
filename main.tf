####################################
######         S3             ######
####################################

resource "aws_s3_bucket" "gitops" {
  bucket = "s3-${var.name}-codebuild"
}

resource "aws_s3_bucket_acl" "gitops" {
  bucket = aws_s3_bucket.gitops.id
  acl    = "private"
}

####################################
#####          IAM             #####
####################################

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "gitops" {
  name               = "role-${var.name}"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "gitops" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeDhcpOptions",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeVpcs",
    ]

    resources = ["*"]
  }

  statement {
    effect  = "Allow"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.gitops.arn,
      "${aws_s3_bucket.gitops.arn}/*",
    ]
  }
}

resource "aws_iam_role_policy" "gitops" {
  role   = aws_iam_role.gitops.name
  policy = data.aws_iam_policy_document.gitops.json
}

####################################
####        CodeBuild           ####
####################################
resource "aws_codebuild_project" "gitops" {
  name          = "codebuild-${var.name}"
  description   = "codebuild-${var.description}"
  build_timeout = "5"
  service_role  = aws_iam_role.gitops.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }


  environment {
    compute_type                = "${var.codebuild_compute_type}"
    image                       = "aws/codebuild/standard:1.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    dynamic "environment_variable" {
      for_each = var.environment_variables

      content {
        name  = environment_variable.key
        value = environment_variable.value
      }
  }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "log-group"
      stream_name = "log-stream"
    }

    s3_logs {
      status   = "ENABLED"
      location = "${aws_s3_bucket.gitops.id}/build-log"
    }
  }


  source {
    type            = "GITHUB"
    location        = "${var.github_repository}"
    git_clone_depth = 1

    git_submodules_config {
      fetch_submodules = true
    }
  }


  tags = {
    Environment = "Test" #TODO: change tags to vars
  }
}

resource "aws_codebuild_webhook" "gitops" {
  project_name = aws_codebuild_project.gitops.name
  build_type   = "BUILD"
  filter_group {
    filter {
      type    = "EVENT"
      pattern = "${var.github_event}"
    }

    filter {
      type    = "BASE_REF"
      pattern = "${var.branch}"
    }
  }
}
