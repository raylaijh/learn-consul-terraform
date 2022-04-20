locals {

  # config-aws-iam.tf
  ecs_service_role = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/ecs.amazonaws.com/AWSServiceRoleForECS"


  # config-aws-vpc.tf
  ap_global_name = var.ecs_ap_globals.global_prefix
  vpc_azs        = [
    "us-east-1a",
    "us-east-1b",
    "us-east-1c",
    "us-east-1d"
  ]
  unique_vpc     = "${var.cluster_cidrs.ecs_cluster.name}-${random_id.random.b64_url}"


  # config-aws-secrets_manager.tf
  secrets_values        = {
    bootstrap_token = hcp_consul_cluster.example.consul_root_token_secret_id
    gossip_key      = jsondecode(base64decode(hcp_consul_cluster.example.consul_config_file))["encrypt"]
    consul_ca_cert  = base64decode(hcp_consul_cluster.example.consul_ca_file)
  }
  bootstrap_token_name  = "${local.ap_global_name}-bootstrap-token"
  bootstrap_token_name2 = "${local.ap_global_name}-bootstrap-token2"
  gossip_key_name       = "${local.ap_global_name}-gossip-key"
  consul_ca_cert_name   = "${local.ap_global_name}-consul-ca-cert"


  # config-aws-security_groups.tf
  security_group_name          = "example-client-app-alb"
  ingress_cidr_block           = "0.0.0.0/0"
  egress_cidr_block            = "0.0.0.0/0"
  security_group_resource_name = "${local.ap_global_name}-${local.security_group_name}"


  # config-hcp-consul_cluster.tf
  cluster_tier        = "development"
  hcp_consul_public   = true
  hcp_connect_enabled = true
  unique_consul       = "${var.hcp_datacenter_name}-${random_id.random.b64_url}"


  # config-hcp-hvn.tf
  unique_hvn = "${var.hvn_settings.name.main-hvn}-${random_id.random.b64_url}"

  # config-hcp-network_peering.tf
  peering_id           = "${hcp_hvn.server.hvn_id}-peering"
  peering_id_hvn_route = "${local.peering_id}-route"


# reader-hashicups.tf
  acl_base                     = var.ecs_ap_globals.acl_controller.prefix
  acl_controller_log_path_base = "${var.ecs_ap_globals.base_cloudwatch_path.hashicups}/acl_controller"
  clusters                     = {
    one = var.ecs_ap_globals.ecs_clusters.one.name
    two = var.ecs_ap_globals.ecs_clusters.two.name
  }
  acl_prefixes = {
    cluster_one = "${local.acl_base}-${local.clusters.one}"
    cluster_two = "${local.acl_base}-${local.clusters.two}"
    logs        = var.ecs_ap_globals.acl_controller.logs_prefix
  }
  admin_partitions = {
    one = var.ecs_ap_globals.admin_partitions_identifiers.partition-one
    two = var.ecs_ap_globals.admin_partitions_identifiers.partition-two
  }
  consul_dc     = var.hcp_datacenter_name
  log_path_base = var.ecs_ap_globals.base_cloudwatch_path.hashicups
  log_paths     = {
    private_hashicups_services = "${local.log_path_base}/${local.admin_partitions.one}/services"
    private_hashicups_apps     = "${local.log_path_base}/${local.admin_partitions.two}/apps"

    public_hashicups_services = "${local.log_path_base}/${local.admin_partitions.two}/services"
    public_hashicups_apps     = "${local.log_path_base}/${local.admin_partitions.two}/apps"
  }
  launch_fargate = var.ecs_ap_globals.ecs_capacity_providers[0]
  namespace      = var.ecs_ap_globals.namespace_identifiers.global
  service_tag    = "TASK_DEFINITION"
    env_vars = {
      public_api_url = {
        name  = "NEXT_PUBLIC_PUBLIC_API_URL"
        value = "http://${aws_lb.example_client_app.dns_name}:8081"
      }
    }
  retry_join_url = jsondecode(base64decode(hcp_consul_cluster.example.consul_config_file))["retry_join"]


  # reader-aws-load_balancer.tf
  load_balancer_name         = local.ap_global_name
  load_balancer_target_group = "${local.ap_global_name}-target-group"
  load_balancer_type         = "application"
  lb_listener_type           = "forward"


  # reader-consul-service_defaults.tf
  consul_service_defaults_protocols = {
    tcp = "tcp"
  }

  # outputs.tf
  consul_ui = hcp_consul_cluster.example.consul_public_endpoint_url
  hashicups_url = "http://${aws_lb.example_client_app.dns_name}"


  tasks_count = length(keys(var.ecs_ap_globals.task_families))
  # task objects
  tnames = {
    frontend    = data.consul_service.each["frontend"].name
    payments    = data.consul_service.each["payments"].name
    postgres    = data.consul_service.each["postgres"].name
    public-api  = data.consul_service.each["public-api"].name
    product-api = data.consul_service.each["product-api"].name
  }
}