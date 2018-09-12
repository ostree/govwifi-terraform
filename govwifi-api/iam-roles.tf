resource "aws_iam_role_policy" "ecs-api-instance-policy" {
  name = "${var.aws-region-name}-ecs-api-instance-policy-${var.Env-Name}"
  role = "${aws_iam_role.ecs-api-instance-role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecs:CreateCluster",
        "ecs:DeregisterContainerInstance",
        "ecs:DiscoverPollEndpoint",
        "ecs:Poll",
        "ecs:RegisterContainerInstance",
        "ecs:StartTelemetrySession",
        "ecs:Submit*",
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage"
      ],
      "Resource": [ "*" ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
      ],
      "Resource": [
        "arn:aws:logs:*:*:*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "cloudwatch:PutMetricData",
        "cloudwatch:GetMetricStatistics",
        "cloudwatch:ListMetrics",
        "ec2:DescribeTags"
      ],
      "Resource": "*"
    },{
      "Effect": "Allow",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": ["${var.admin-bucket-arn}/*"]
     }
  ]
}
EOF
}

resource "aws_iam_role" "ecs-api-instance-role" {
  name = "${var.aws-region-name}-ecs-api-instance-role-${var.Env-Name}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "ecs-api-instance-profile" {
  name  = "${var.aws-region-name}-ecs-api-instance-profile-${var.Env-Name}"
  role  = "${aws_iam_role.ecs-api-instance-role.name}"
}
