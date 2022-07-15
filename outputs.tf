output "service_account_credentials" {
  description = <<EOF
  Map containing service account credentials.
  Keys are service account names provided to topics as readers and writers.
  Values are objects with key and secret values.
  EOF
  value       = { for name, v in confluentcloud_api_key.service_account_api_keys : name => { key : v.key, secret : v.secret } }
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
