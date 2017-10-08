resource "aws_iam_role" "role" {
  name = "test-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "application-autoscaling.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "policy" {
  name        = "test-policy"
  description = "A test policy"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:DescribeTable",
                "dynamodb:UpdateTable",
                "cloudwatch:PutMetricAlarm",
                "cloudwatch:DescribeAlarms",
                "cloudwatch:DeleteAlarms"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "null_resource" "wait_time" {
  provisioner "local-exec" {
    command = "sleep 10"
  }
}

resource "aws_iam_role_policy_attachment" "test-attach" {
  role       = "${aws_iam_role.role.name}"
  policy_arn = "${aws_iam_policy.policy.arn}"
  depends_on = ["aws_iam_role.role"]
  depends_on = ["aws_iam_policy.policy"]
}

resource "null_resource" "Scalable_Target" {
  provisioner "local-exec" {
    command = "aws application-autoscaling register-scalable-target --service-namespace dynamodb --resource-id 'table/GameScores' --scalable-dimension 'dynamodb:table:WriteCapacityUnits' --min-capacity 5 --max-capacity 10 --role-arn ${aws_iam_role.role.arn}"
  }
  depends_on = ["aws_iam_role.role"]
}
resource "null_resource" "Scaling_Policy" {
  provisioner "local-exec" {
    command = "aws application-autoscaling put-scaling-policy --service-namespace dynamodb --resource-id 'table/GameScores' --scalable-dimension 'dynamodb:table:WriteCapacityUnits' --policy-name 'MyScalingPolicy' --policy-type 'TargetTrackingScaling' --target-tracking-scaling-policy-configuration file://scaling-policy.json"
  }
depends_on = ["null_resource.Scalable_Target"]
}
