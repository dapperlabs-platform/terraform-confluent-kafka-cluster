locals {
  # Given the following api key resources:
  # v1/reader, v1/writer, v2/reader, v2/writer
  # return
  #  { 
  #    v1 = [{reader = {key, secret}}, {writer = {key, secret}}]
  #    v2 = [{reader = {key, secret}}, {writer = {key, secret}}]
  #  }
  key_list_by_version = { for name, v in confluentcloud_api_key.service_account_api_keys :
    (split("/", name)[0]) => { split("/", name)[1] = { key : v.key, secret : v.secret } }...
  }
  # given key_list_by_version
  # return
  #  { 
  #    v1 = {
  #      reader = {key, secret} 
  #      writer = {key, secret}
  #    }
  #    v2 = {
  #      reader = {key, secret}
  #      writer = {key, secret}
  #    }
  #  }
  output_credentials = {
    for version, key_list in local.key_list_by_version : version => merge(key_list...)
  }
}

output "service_account_credentials" {
  description = <<EOF
  Map of map containing service account credentials.
  Keys are versions provided in var.service_account_key_versions.
  Values are maps whose keys are service account names provided to topics as readers and writers, 
  whose values are objects with key and secret values.
  { v1 = { reader = {key, secret}, writer = {key, secret} }, v2 = { reader = {key, secret}, writer = {key, secret} } }
  EOF
  value       = local.output_credentials
  sensitive   = true
}

output "kafka_url" {
  description = "URL to connect your Kafka clients to"
  value       = local.bootstrap_servers
}

output "cluster_id" {
  description = "Cluster ID"
  value       = confluentcloud_kafka_cluster.cluster.id
}

output "rest_api_endpoint" {
  description = "REST API endpoint to manage the cluster"
  value       = local.rest_api_endpoint
}

output "admin_api_key" {
  description = "Admin user api key and secret"
  value       = confluentcloud_api_key.admin_api_key
  sensitive   = true
}
