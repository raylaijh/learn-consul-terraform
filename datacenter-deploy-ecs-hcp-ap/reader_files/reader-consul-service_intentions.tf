locals {
  tasks_count = length(keys(var.ecs_ap_globals.task_families))
  tnames = {
    frontend    = data.consul_service.each["frontend"].name
    payments    = data.consul_service.each["payments"].name
    postgres    = data.consul_service.each["postgres"].name
    public-api  = data.consul_service.each["public-api"].name
    product-api = data.consul_service.each["product-api"].name
  }
}

resource "consul_config_entry" "product_api_intentions_to_public_api_on_part2" {
  kind      = "service-intentions"
  name      = local.tnames.product-api
  namespace = var.ecs_ap_globals.namespace_identifiers.global
  partition = var.ecs_ap_globals.admin_partitions_identifiers.partition-one

  config_json = jsonencode({
    Sources = [
      {
        Action     = "allow"
        Type       = "consul"
        Precedence = 9
        Name       = local.tnames.public-api
        Namespace  = var.ecs_ap_globals.namespace_identifiers.global
        Partition  = consul_admin_partition.partition-two.name
      }
    ]
  })

  depends_on = [local.tnames.public-api, local.tnames.product-api ] #module.acl_controller["clust2"].client_token_secret_arn, module.acl_controller["clust1"].client_token_secret_arn]
}

resource "consul_config_entry" "public_api_intentions_to_frontend_on_part2" {
  kind = "service-intentions"
  name      = var.ecs_ap_globals.task_families.public-api
  namespace = var.ecs_ap_globals.namespace_identifiers.global
  partition = consul_admin_partition.partition-two.name
  config_json = jsonencode({
    Sources = [
      {
        Action     = "allow"
        Type       = "consul"
        Precedence = 9
        Name       = local.tnames.frontend
        Namespace  = var.ecs_ap_globals.namespace_identifiers.global
        Partition  = consul_admin_partition.partition-two.name
      }
    ]
  })

  depends_on = [local.tnames.public-api, local.tnames.frontend ] #module.acl_controller["clust2"].client_token_secret_arn, module.acl_controller["clust1"].client_token_secret_arn]
}

resource "consul_config_entry" "payments_intentions_to_public_api_on_part2" {
  kind      = "service-intentions"
  name      = local.tnames.payments
  namespace = var.ecs_ap_globals.namespace_identifiers.global
  partition = var.ecs_ap_globals.admin_partitions_identifiers.partition-one

  config_json = jsonencode({
    Sources = [
      {
        Action     = "allow"
        Type       = "consul"
        Precedence = 9
        Name       = local.tnames.public-api
        Namespace  = var.ecs_ap_globals.namespace_identifiers.global
        Partition  = consul_admin_partition.partition-two.name
      }
    ]
  })
  depends_on = [local.tnames.public-api, local.tnames.payments] #module.acl_controller["clust2"].client_token_secret_arn, module.acl_controller["clust1"].client_token_secret_arn]

}

resource "consul_config_entry" "postgres_intentions_to_product_api_on_default" {
  kind      = "service-intentions"
  name      = local.tnames.postgres
  partition = var.ecs_ap_globals.admin_partitions_identifiers.partition-one
  config_json = jsonencode({
    Sources = [
      {
        Action     = "allow"
        Precedence = 9
        Type       = "consul"
        Name       = local.tnames.product-api
        Namespace  = var.ecs_ap_globals.namespace_identifiers.global
        Partition  = var.ecs_ap_globals.admin_partitions_identifiers.partition-one

      }
    ],
  })
  depends_on = [local.tnames.postgres, local.tnames.product-api]
}

resource "consul_config_entry" "deny_all" {
  kind = "service-intentions"
  name = "*"

  config_json = jsonencode({
    Sources = [
      {
        Action     = "deny"
        Name       = "*"
        Precedence = 9
        Type       = "consul"
        Namespace  = "*"
      }
    ]
  })
  depends_on = [consul_admin_partition.partition-two]
}


