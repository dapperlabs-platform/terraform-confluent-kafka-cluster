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
