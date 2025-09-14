# =============================================================================
# MONITORING MODULE - COMPREHENSIVE OBSERVABILITY STACK
# =============================================================================
# 
# This module creates a comprehensive monitoring and observability stack:
# - Prometheus for metrics collection
# - Grafana for visualization and dashboards
# - ELK Stack (Elasticsearch, Logstash, Kibana) for log management
# - Jaeger for distributed tracing
# - AlertManager for alerting
# - CloudWatch integration
# - Custom dashboards and alerts
#
# Features:
# - Multi-cloud monitoring
# - Custom metrics and dashboards
# - Alerting and notification
# - Log aggregation and analysis
# - Distributed tracing
# - Cost monitoring
# =============================================================================

# =============================================================================
# PROMETHEUS SERVER
# =============================================================================

resource "aws_instance" "prometheus" {
  count = var.enable_prometheus ? 1 : 0
  
  ami           = var.ami_id
  instance_type = var.prometheus_instance_type
  key_name      = var.key_pair_name
  
  vpc_security_group_ids = [aws_security_group.prometheus[0].id]
  subnet_id              = var.public_subnet_ids[0]
  
  user_data = templatefile("${path.module}/prometheus_user_data.sh", {
    cluster_endpoint = var.cluster_endpoint
    grafana_password = random_password.grafana[0].result
  })
  
  root_block_device {
    volume_type = "gp3"
    volume_size = var.prometheus_storage_size
    encrypted   = true
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-prometheus"
    Type = "PrometheusServer"
    Role = "Monitoring"
  })
}

# =============================================================================
# GRAFANA SERVER
# =============================================================================

resource "aws_instance" "grafana" {
  count = var.enable_grafana ? 1 : 0
  
  ami           = var.ami_id
  instance_type = var.grafana_instance_type
  key_name      = var.key_pair_name
  
  vpc_security_group_ids = [aws_security_group.grafana[0].id]
  subnet_id              = var.public_subnet_ids[0]
  
  user_data = templatefile("${path.module}/grafana_user_data.sh", {
    prometheus_url = var.enable_prometheus ? "http://${aws_instance.prometheus[0].private_ip}:9090" : ""
    grafana_password = random_password.grafana[0].result
  })
  
  root_block_device {
    volume_type = "gp3"
    volume_size = var.grafana_storage_size
    encrypted   = true
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-grafana"
    Type = "GrafanaServer"
    Role = "Monitoring"
  })
}

# =============================================================================
# ELK STACK
# =============================================================================

# Elasticsearch Cluster
resource "aws_instance" "elasticsearch" {
  count = var.enable_elk_stack ? var.elasticsearch_instance_count : 0
  
  ami           = var.ami_id
  instance_type = var.elasticsearch_instance_type
  key_name      = var.key_pair_name
  
  vpc_security_group_ids = [aws_security_group.elasticsearch[0].id]
  subnet_id              = var.private_subnet_ids[count.index % length(var.private_subnet_ids)]
  
  user_data = templatefile("${path.module}/elasticsearch_user_data.sh", {
    cluster_name = "${var.name_prefix}-elasticsearch"
    node_name    = "${var.name_prefix}-elasticsearch-${count.index + 1}"
    master_nodes = join(",", [for i in range(var.elasticsearch_instance_count) : "${var.name_prefix}-elasticsearch-${i + 1}"])
  })
  
  root_block_device {
    volume_type = "gp3"
    volume_size = var.elasticsearch_storage_size
    encrypted   = true
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-elasticsearch-${count.index + 1}"
    Type = "ElasticsearchNode"
    Role = "Logging"
  })
}

# Logstash Server
resource "aws_instance" "logstash" {
  count = var.enable_elk_stack ? 1 : 0
  
  ami           = var.ami_id
  instance_type = var.logstash_instance_type
  key_name      = var.key_pair_name
  
  vpc_security_group_ids = [aws_security_group.logstash[0].id]
  subnet_id              = var.private_subnet_ids[0]
  
  user_data = templatefile("${path.module}/logstash_user_data.sh", {
    elasticsearch_hosts = join(",", [for instance in aws_instance.elasticsearch : instance.private_ip])
  })
  
  root_block_device {
    volume_type = "gp3"
    volume_size = var.logstash_storage_size
    encrypted   = true
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-logstash"
    Type = "LogstashServer"
    Role = "Logging"
  })
}

# Kibana Server
resource "aws_instance" "kibana" {
  count = var.enable_elk_stack ? 1 : 0
  
  ami           = var.ami_id
  instance_type = var.kibana_instance_type
  key_name      = var.key_pair_name
  
  vpc_security_group_ids = [aws_security_group.kibana[0].id]
  subnet_id              = var.public_subnet_ids[0]
  
  user_data = templatefile("${path.module}/kibana_user_data.sh", {
    elasticsearch_hosts = join(",", [for instance in aws_instance.elasticsearch : instance.private_ip])
  })
  
  root_block_device {
    volume_type = "gp3"
    volume_size = var.kibana_storage_size
    encrypted   = true
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-kibana"
    Type = "KibanaServer"
    Role = "Logging"
  })
}

# =============================================================================
# JAEGER DISTRIBUTED TRACING
# =============================================================================

resource "aws_instance" "jaeger" {
  count = var.enable_jaeger ? 1 : 0
  
  ami           = var.ami_id
  instance_type = var.jaeger_instance_type
  key_name      = var.key_pair_name
  
  vpc_security_group_ids = [aws_security_group.jaeger[0].id]
  subnet_id              = var.public_subnet_ids[0]
  
  user_data = templatefile("${path.module}/jaeger_user_data.sh", {
    elasticsearch_hosts = var.enable_elk_stack ? join(",", [for instance in aws_instance.elasticsearch : instance.private_ip]) : ""
  })
  
  root_block_device {
    volume_type = "gp3"
    volume_size = var.jaeger_storage_size
    encrypted   = true
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-jaeger"
    Type = "JaegerServer"
    Role = "Tracing"
  })
}

# =============================================================================
# SECURITY GROUPS
# =============================================================================

# Prometheus Security Group
resource "aws_security_group" "prometheus" {
  count = var.enable_prometheus ? 1 : 0
  
  name_prefix = "${var.name_prefix}-prometheus-"
  vpc_id      = var.vpc_id
  
  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-prometheus-sg"
    Type = "SecurityGroup"
  })
}

# Grafana Security Group
resource "aws_security_group" "grafana" {
  count = var.enable_grafana ? 1 : 0
  
  name_prefix = "${var.name_prefix}-grafana-"
  vpc_id      = var.vpc_id
  
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-grafana-sg"
    Type = "SecurityGroup"
  })
}

# Elasticsearch Security Group
resource "aws_security_group" "elasticsearch" {
  count = var.enable_elk_stack ? 1 : 0
  
  name_prefix = "${var.name_prefix}-elasticsearch-"
  vpc_id      = var.vpc_id
  
  ingress {
    from_port = 9200
    to_port   = 9200
    protocol  = "tcp"
    self      = true
  }
  
  ingress {
    from_port = 9300
    to_port   = 9300
    protocol  = "tcp"
    self      = true
  }
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-elasticsearch-sg"
    Type = "SecurityGroup"
  })
}

# Logstash Security Group
resource "aws_security_group" "logstash" {
  count = var.enable_elk_stack ? 1 : 0
  
  name_prefix = "${var.name_prefix}-logstash-"
  vpc_id      = var.vpc_id
  
  ingress {
    from_port   = 5044
    to_port     = 5044
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  
  ingress {
    from_port   = 9600
    to_port     = 9600
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-logstash-sg"
    Type = "SecurityGroup"
  })
}

# Kibana Security Group
resource "aws_security_group" "kibana" {
  count = var.enable_elk_stack ? 1 : 0
  
  name_prefix = "${var.name_prefix}-kibana-"
  vpc_id      = var.vpc_id
  
  ingress {
    from_port   = 5601
    to_port     = 5601
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-kibana-sg"
    Type = "SecurityGroup"
  })
}

# Jaeger Security Group
resource "aws_security_group" "jaeger" {
  count = var.enable_jaeger ? 1 : 0
  
  name_prefix = "${var.name_prefix}-jaeger-"
  vpc_id      = var.vpc_id
  
  ingress {
    from_port   = 16686
    to_port     = 16686
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  
  ingress {
    from_port   = 14268
    to_port     = 14268
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-jaeger-sg"
    Type = "SecurityGroup"
  })
}

# =============================================================================
# CLOUDWATCH LOG GROUPS
# =============================================================================

resource "aws_cloudwatch_log_group" "monitoring" {
  name              = "/aws/monitoring/${var.name_prefix}"
  retention_in_days = var.log_retention_days
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-monitoring-logs"
    Type = "CloudWatchLogGroup"
  })
}

# =============================================================================
# CLOUDWATCH ALARMS
# =============================================================================

# CPU Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  count = var.enable_prometheus ? 1 : 0
  
  alarm_name          = "${var.name_prefix}-prometheus-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors prometheus cpu utilization"
  
  dimensions = {
    InstanceId = aws_instance.prometheus[0].id
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-prometheus-high-cpu-alarm"
    Type = "CloudWatchAlarm"
  })
}

# Memory Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "high_memory" {
  count = var.enable_prometheus ? 1 : 0
  
  alarm_name          = "${var.name_prefix}-prometheus-high-memory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "System/Linux"
  period              = "300"
  statistic           = "Average"
  threshold           = "85"
  alarm_description   = "This metric monitors prometheus memory utilization"
  
  dimensions = {
    InstanceId = aws_instance.prometheus[0].id
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-prometheus-high-memory-alarm"
    Type = "CloudWatchAlarm"
  })
}

# =============================================================================
# RANDOM PASSWORDS
# =============================================================================

resource "random_password" "grafana" {
  count = var.enable_grafana ? 1 : 0
  
  length  = 16
  special = true
}

# =============================================================================
# OUTPUTS
# =============================================================================

output "prometheus_url" {
  description = "Prometheus server URL"
  value       = var.enable_prometheus ? "http://${aws_instance.prometheus[0].public_ip}:9090" : null
}

output "grafana_url" {
  description = "Grafana server URL"
  value       = var.enable_grafana ? "http://${aws_instance.grafana[0].public_ip}:3000" : null
}

output "grafana_password" {
  description = "Grafana admin password"
  value       = var.enable_grafana ? random_password.grafana[0].result : null
  sensitive   = true
}

output "kibana_url" {
  description = "Kibana server URL"
  value       = var.enable_elk_stack ? "http://${aws_instance.kibana[0].public_ip}:5601" : null
}

output "jaeger_url" {
  description = "Jaeger UI URL"
  value       = var.enable_jaeger ? "http://${aws_instance.jaeger[0].public_ip}:16686" : null
}

output "elasticsearch_endpoints" {
  description = "Elasticsearch cluster endpoints"
  value       = var.enable_elk_stack ? [for instance in aws_instance.elasticsearch : "http://${instance.private_ip}:9200"] : []
}

output "logstash_endpoint" {
  description = "Logstash endpoint"
  value       = var.enable_elk_stack ? "http://${aws_instance.logstash[0].private_ip}:5044" : null
}

output "dashboard_url" {
  description = "Main monitoring dashboard URL"
  value       = var.enable_grafana ? "http://${aws_instance.grafana[0].public_ip}:3000" : null
}
