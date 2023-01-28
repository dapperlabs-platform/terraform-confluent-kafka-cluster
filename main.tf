terraform {
  required_providers {
    confluentcloud = {
      source  = "Mongey/confluentcloud"
      version = ">= 0.0.12"
    }
    kafka = {
      source  = "Mongey/kafka"
      version = ">= 0.2.11"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2"
    }
    grafana = {
      source  = "grafana/grafana"
      version = "~> 1.20"
    }
  }
}

locals {
  name    = "${var.environment}-${var.name}"
  lc_name = lower(local.name)
  topic_readers = flatten([
    for name, values in var.topics :
    [for user in values.acl_readers : { topic : name, user : user }]
  ])
  readers_map = { for v in local.topic_readers : "${v.topic}/${v.user}" => v }
  readers_set = toset([
    for r in local.topic_readers : r.user
  ])
  topic_writers = flatten([
    for name, values in var.topics :
    [for user in values.acl_writers : { topic : name, user : user }]
  ])
  writers_map = { for v in local.topic_writers : "${v.topic}/${v.user}" => v }
  bootstrap_servers = [
    replace(confluentcloud_kafka_cluster.cluster.bootstrap_servers, "SASL_SSL://", "")
  ]

  # Since Mongey's Confluent provider doesn't provide rest endpoint url
  # we should build it ourselves basing on the assumption that domain
  # name is the same as in bootstrap_servers
  rest_api_endpoint = replace(confluentcloud_kafka_cluster.cluster.bootstrap_servers, "/^SASL_SSL:\\/\\/(.*):([0-9]+)$/", "https://$1:443")
  service_accounts = distinct(
    concat(
      [for v in local.readers_map : v.user],
      [for v in local.writers_map : v.user]
    )
  )
}

resource "random_pet" "pet" {}

resource "confluentcloud_environment" "environment" {
  name = local.name
}

resource "confluentcloud_api_key" "admin_api_key" {
  cluster_id     = confluentcloud_kafka_cluster.cluster.id
  environment_id = confluentcloud_environment.environment.id
}

resource "confluentcloud_service_account" "service_accounts" {
  for_each    = toset(local.service_accounts)
  name        = "${local.lc_name}-${each.value}${var.add_service_account_suffix ? "-${random_pet.pet.id}" : ""}"
  description = "${each.value} service account"
}

resource "confluentcloud_api_key" "new_service_account_api_keys" {
  for_each       = toset(local.service_accounts)
  cluster_id     = confluentcloud_kafka_cluster.cluster.id
  environment_id = confluentcloud_environment.environment.id
  user_id        = confluentcloud_service_account.service_accounts[each.value].id
}

resource "confluentcloud_api_key" "ccloud_exporter_api_key" {
  count = var.enable_metric_exporters ? 1 : 0

  environment_id = confluentcloud_environment.environment.id
  description    = "${local.name} ccloud exporter api key"
}

resource "confluentcloud_service_account" "kafka_lag_exporter" {
  count = var.enable_metric_exporters ? 1 : 0

  name        = "${local.lc_name}-kafka-lag-exporter"
  description = "Kafka lag exporter service account"
}

resource "confluentcloud_api_key" "kafka_lag_exporter_api_key" {
  count = var.enable_metric_exporters ? 1 : 0

  description    = "${local.name} kafka lag exporter api key"
  environment_id = confluentcloud_environment.environment.id
  cluster_id     = confluentcloud_kafka_cluster.cluster.id
  user_id        = confluentcloud_service_account.kafka_lag_exporter[0].id
}

resource "kafka_acl" "kafka_lag_exporter_read_topic" {
  count = var.enable_metric_exporters ? 1 : 0

  resource_name       = "*"
  resource_type       = "Topic"
  acl_principal       = "User:${confluentcloud_service_account.kafka_lag_exporter[0].id}"
  acl_host            = "*"
  acl_operation       = "Read"
  acl_permission_type = "Allow"
}

resource "kafka_acl" "kafka_lag_exporter_describe_topic" {
  count = var.enable_metric_exporters ? 1 : 0

  resource_name       = "*"
  resource_type       = "Topic"
  acl_principal       = "User:${confluentcloud_service_account.kafka_lag_exporter[0].id}"
  acl_host            = "*"
  acl_operation       = "Describe"
  acl_permission_type = "Allow"
}

resource "kafka_acl" "kafka_lag_exporter_describe_consumer_group" {
  count = var.enable_metric_exporters ? 1 : 0

  resource_name       = "*"
  resource_type       = "Group"
  acl_principal       = "User:${confluentcloud_service_account.kafka_lag_exporter[0].id}"
  acl_host            = "*"
  acl_operation       = "Describe"
  acl_permission_type = "Allow"
}

resource "confluentcloud_kafka_cluster" "cluster" {
  name             = local.name
  service_provider = var.service_provider
  region           = var.gcp_region
  availability     = var.availability
  environment_id   = confluentcloud_environment.environment.id
  cku              = var.cku
  deployment = {
    sku = var.cluster_tier
  }
  network_egress  = var.network_egress
  network_ingress = var.network_ingress
  storage         = var.storage
}

resource "kafka_topic" "topics" {
  for_each           = var.topics
  name               = each.key
  replication_factor = each.value.replication_factor
  partitions         = each.value.partitions
  config             = try(each.value.config, {})
}

resource "kafka_acl" "readers" {
  for_each = local.readers_map

  resource_name       = each.value.topic
  resource_type       = "Topic"
  acl_principal       = "User:${confluentcloud_service_account.service_accounts[each.value.user].id}"
  acl_host            = "*"
  acl_operation       = "Read"
  acl_permission_type = "Allow"
}

resource "kafka_acl" "group_readers" {
  for_each = local.readers_set

  resource_name       = "*"
  resource_type       = "Group"
  acl_principal       = "User:${confluentcloud_service_account.service_accounts[each.value].id}"
  acl_host            = "*"
  acl_operation       = "Read"
  acl_permission_type = "Allow"
}

resource "kafka_acl" "writers" {
  for_each = local.writers_map

  resource_name       = each.value.topic
  resource_type       = "Topic"
  acl_principal       = "User:${confluentcloud_service_account.service_accounts[each.value.user].id}"
  acl_host            = "*"
  acl_operation       = "Write"
  acl_permission_type = "Allow"
}
