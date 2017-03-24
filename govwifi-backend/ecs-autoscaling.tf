# TODO: review the settings here - registry???
module "ecs-autoscaling" {
  source                     = "./modules/ecs-autoscaling"
  Env-Name                   = "${var.Env-Name}"
  cluster_name               = "${var.Env-Name}-backend-cluster"
  key_name                   = "${var.ssh-key-name}"
  instance_type              = "t2.medium"
  region                     = "${var.aws-region}"
  availability_zones         = "${join(",", values(var.zone-names))}"
  subnet_ids                 = "${join(",", aws_subnet.wifi-backend-subnet.*.id)}"
  security_group_ids         = "${join(",", var.backend-sg-list)}"
  min_size                   = "1"
  max_size                   = "10"
  desired_capacity           = "${var.backend-instance-count}"
  instance-profile-id        = "${aws_iam_instance_profile.ecs-instance-profile.id}"
  registry_url               = "https://index.docker.io/v1/"
  registry_email             = "your_email@"
  registry_auth              = "your_registry_auth_token"
  ami                        = "${var.ami}"
  critical-notifications-arn = "${var.critical-notifications-arn}"
}