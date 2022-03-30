variable "name" {
  description = "Kafka cluster identifier. Will be prepended by the environment value in Confluent cloud"
  type        = string
}

variable "environment" {
  description = "Application environment that uses the cluster"
  type        = string
}

variable "gcp_region" {
  description = "GCP region in which to deploy the cluster. See https://docs.confluent.io/cloud/current/clusters/regions.html"
  type        = string
}

variable "availability" {
  description = "Cluster availability. LOW or HIGH"
  type        = string
  default     = "LOW"
}

variable "storage" {
  description = "Storage limit(GB)"
  type        = number
  default     = 5000
}

variable "network_egress" {
  description = "Network egress limit(MBps)"
  type        = number
  default     = 100
}

variable "network_ingress" {
  description = "Network ingress limit(MBps)"
  type        = number
  default     = 100
}

variable "cluster_tier" {
  description = "Cluster tier"
  type        = string
  default     = "BASIC"
}

variable "cku" {
  description = "Number of CKUs"
  type        = number
  default     = null
}

variable "service_provider" {
  description = "Confluent cloud service provider. AWS, GCP, Azure"
  type        = string
  default     = "gcp"
}

variable "topics" {
  description = <<EOF
  Kafka topic definitions.
  Object map keyed by topic name with topic configuration values as well as reader and writer ACL lists.
  Values provided to the ACL lists will become service accounts with { key, secret } objects output by service_account_credentials
  EOF
  type = map(
    object({
      replication_factor = number
      partitions         = number
      config             = object({})
      acl_readers        = list(string)
      acl_writers        = list(string)
    })
  )
}

variable "add_service_account_suffix" {
  description = "Add pet name suffix to service account names to avoid collision"
  type        = bool
  default     = false
}
