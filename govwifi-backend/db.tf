resource "aws_db_subnet_group" "db-subnets" {
  name        = "wifi-${var.Env-Name}-subnets"
  description = "GovWifi ${var.Env-Name} backend subnets"
  subnet_ids  = ["${aws_subnet.wifi-backend-subnet.*.id}"]

  tags {
    Name = "wifi-${var.Env-Name}-subnets"
  }
}

resource "aws_db_instance" "db" {
  count                       = "${var.db-instance-count}"
  allocated_storage           = "${var.db-storage-gb}"
  storage_type                = "gp2"
  engine                      = "mysql"
  engine_version              = "5.7.16"
  auto_minor_version_upgrade  = true
  allow_major_version_upgrade = false
  apply_immediately           = true
  instance_class              = "${var.db-instance-type}"
  identifier                  = "wifi-${var.Env-Name}-db"
  name                        = "govwifi_${var.Env-Name}"
  username                    = "${var.db-user}"
  password                    = "${var.db-password}"
  backup_retention_period     = "${var.db-backup-retention-days}"
  multi_az                    = true
  storage_encrypted           = "${var.db-encrypt-at-rest}"
  db_subnet_group_name        = "wifi-${var.Env-Name}-subnets"
  vpc_security_group_ids      = ["${var.db-sg-list}"]
  depends_on                  = ["aws_iam_role.rds-monitoring-role"]
  monitoring_role_arn         = "${aws_iam_role.rds-monitoring-role.arn}"
  monitoring_interval         = "${var.db-monitoring-interval}"
  maintenance_window          = "${var.db-maintenance-window}"
  backup_window               = "${var.db-backup-window}"
  skip_final_snapshot         = true

  tags {
    Name = "${title(var.Env-Name)} DB"
  }
}

resource "aws_db_instance" "read_replica" {
  count                       = "${var.db-replica-count}"
  allocated_storage           = "${var.db-storage-gb}"
  replicate_source_db         = "${aws_db_instance.db.identifier}"
  storage_type                = "gp2"
  engine                      = "mysql"
  engine_version              = "5.7.16"
  auto_minor_version_upgrade  = true
  allow_major_version_upgrade = false
  apply_immediately           = true
  instance_class              = "${var.db-instance-type}"
  identifier                  = "${var.Env-Name}-db-rr"
  username                    = "${var.db-user}"
  password                    = "${var.db-password}"
  backup_retention_period     = 0
  multi_az                    = false
  storage_encrypted           = "${var.db-encrypt-at-rest}"
  vpc_security_group_ids      = ["${var.db-sg-list}"]
  depends_on                  = ["aws_iam_role.rds-monitoring-role"]
  monitoring_role_arn         = "${aws_iam_role.rds-monitoring-role.arn}"
  monitoring_interval         = "${var.db-monitoring-interval}"
  maintenance_window          = "${var.db-maintenance-window}"
  backup_window               = "${var.db-backup-window}"
  skip_final_snapshot         = true

  tags {
    Name = "${title(var.Env-Name)} DB Read Replica"
  }
}

resource "aws_cloudwatch_metric_alarm" "db_cpualarm" {
  count               = "${var.db-instance-count}"
  alarm_name          = "${var.Env-Name}-db-cpu-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "80"

  dimensions {
    DBInstanceIdentifier = "${aws_db_instance.db.identifier}"
  }

  alarm_description  = "This metric monitors the cpu utilization of the DB."
  alarm_actions      = ["${var.critical-notifications-arn}"]
  treat_missing_data = "breaching"
}

resource "aws_cloudwatch_metric_alarm" "db_memoryalarm" {
  count               = "${var.db-instance-count}"
  alarm_name          = "${var.Env-Name}-db-memory-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "FreeableMemory"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Minimum"
  threshold           = "524288000"

  dimensions {
    DBInstanceIdentifier = "${aws_db_instance.db.identifier}"
  }

  alarm_description  = "This metric monitors the freeable memory available for the DB."
  alarm_actions      = ["${var.critical-notifications-arn}"]
  treat_missing_data = "breaching"
}

resource "aws_cloudwatch_metric_alarm" "db_storagealarm" {
  count               = "${var.db-instance-count}"
  alarm_name          = "${var.Env-Name}-db-storage-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Minimum"
  threshold           = "21474836480"

  dimensions {
    DBInstanceIdentifier = "${aws_db_instance.db.identifier}"
  }

  alarm_description  = "This metric monitors the storage space available for the DB."
  alarm_actions      = ["${var.critical-notifications-arn}"]
  treat_missing_data = "breaching"
}

resource "aws_cloudwatch_metric_alarm" "rr_cpualarm" {
  count               = "${var.db-replica-count}"
  alarm_name          = "${var.Env-Name}-rr-cpu-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "80"

  dimensions {
    DBInstanceIdentifier = "${aws_db_instance.read_replica.identifier}"
  }

  alarm_description  = "This metric monitors the cpu utilization of the DB read replica."
  alarm_actions      = ["${var.critical-notifications-arn}"]
  treat_missing_data = "breaching"
}

resource "aws_cloudwatch_metric_alarm" "rr_memoryalarm" {
  count               = "${var.db-replica-count}"
  alarm_name          = "${var.Env-Name}-rr-memory-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "FreeableMemory"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Minimum"
  threshold           = "524288000"

  dimensions {
    DBInstanceIdentifier = "${aws_db_instance.read_replica.identifier}"
  }

  alarm_description  = "This metric monitors the freeable memory available for the DB read replica."
  alarm_actions      = ["${var.critical-notifications-arn}"]
  treat_missing_data = "breaching"
}

resource "aws_cloudwatch_metric_alarm" "rr_storagealarm" {
  count               = "${var.db-replica-count}"
  alarm_name          = "${var.Env-Name}-rr-storage-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Minimum"
  threshold           = "21474836480"

  dimensions {
    DBInstanceIdentifier = "${aws_db_instance.read_replica.identifier}"
  }

  alarm_description  = "This metric monitors the storage space available for the DB read replica."
  alarm_actions      = ["${var.critical-notifications-arn}"]
  treat_missing_data = "breaching"
}
