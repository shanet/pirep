variable "name_prefix" {}
variable "vpc_id" {}

resource "aws_service_discovery_private_dns_namespace" "this" {
  name = "${var.name_prefix}.internal"
  vpc  = var.vpc_id
}

# API Gateway discovers ECS tasks through this service. It requires SRV records since it needs both the IP and port of each task.
resource "aws_service_discovery_service" "web" {
  name = "web"

  dns_config {
    namespace_id   = aws_service_discovery_private_dns_namespace.this.id
    routing_policy = "MULTIVALUE"

    dns_records {
      ttl  = 10 # seconds
      type = "SRV"
    }
  }

  # Let ECS report task health based on the container health check. `failure_threshold` is deprecated (AWS always uses 1),
  # but without any arguments the provider omits the block when creating the service and then plans to replace it forever.
  health_check_custom_config {
    failure_threshold = 1
  }
}

output "service_web" {
  value = aws_service_discovery_service.web
}
