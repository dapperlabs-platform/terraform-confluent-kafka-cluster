locals {
  lag_exporter_common_labels = {
    name       = "kafka-lag-exporter"
    instance   = "kafka-lag-exporter"
    managed-by = "Terraform"
  }
  lag_exporter_name = "${local.lc_name}-kafka-lag-exporter"
}

resource "kubernetes_service_account" "lag_exporter_service_account" {
  count = var.enable_metric_exporters ? 1 : 0

  metadata {
    name      = local.lag_exporter_name
    namespace = var.metric_exporters_namespace
    labels    = local.lag_exporter_common_labels
  }
}

resource "kubernetes_secret" "lag_exporter_config" {
  count = var.enable_metric_exporters ? 1 : 0

  metadata {
    name      = local.lag_exporter_name
    namespace = var.metric_exporters_namespace
    labels    = local.lag_exporter_common_labels
  }

  data = {
    "application.conf" = templatefile(
      "${path.module}/templates/application.conf", {
        username         = confluentcloud_api_key.kafka_lag_exporter_api_key[0].key
        password         = confluentcloud_api_key.kafka_lag_exporter_api_key[0].secret
        namespace        = var.metric_exporters_namespace
        bootstrapBrokers = local.bootstrap_servers[0]
        clusterName      = local.lc_name
    })
    "logback.xml" = file("${path.module}/templates/logback.xml")
  }
}

resource "kubernetes_deployment" "lag_exporter_deployment" {
  count = var.enable_metric_exporters ? 1 : 0

  #   # if set to true, k8s apply take a long time
  wait_for_rollout = false

  metadata {
    name        = local.lag_exporter_name
    namespace   = var.metric_exporters_namespace
    labels      = local.lag_exporter_common_labels
    annotations = var.kafka_lag_exporter_annotations
  }

  spec {
    replicas = 1

    selector {
      match_labels = local.lag_exporter_common_labels
    }

    template {
      metadata {
        labels = local.lag_exporter_common_labels
        annotations = merge(
          {
            "prometheus.io/port"   = "9090"
            "prometheus.io/path"   = "/"
            "prometheus.io/scrape" = "true"
          },
          var.kafka_lag_exporter_annotations,
        )
      }

      spec {
        service_account_name             = kubernetes_service_account.lag_exporter_service_account[0].metadata.0.name
        termination_grace_period_seconds = 300
        node_selector                    = var.exporters_node_selector

        container {
          name              = local.lag_exporter_name
          image             = "seglo/kafka-lag-exporter:${var.kafka_lag_exporter_image_version}"
          image_pull_policy = "IfNotPresent"

          resources {
            requests = var.kafka_lag_exporter_container_resources.requests
            limits   = var.kafka_lag_exporter_container_resources.limits
          }
          volume_mount {
            mount_path = "/opt/docker/conf/"
            name       = "config"
            read_only  = true
          }

          port {
            name           = "http"
            container_port = 9090
            protocol       = "TCP"
          }

          readiness_probe {
            http_get {
              path = "/"
              port = "http"
            }

            initial_delay_seconds = 30
            period_seconds        = 15
            timeout_seconds       = 30
            failure_threshold     = 3
            success_threshold     = 1
          }

          liveness_probe {
            http_get {
              path = "/"
              port = "http"
            }

            initial_delay_seconds = 30
            period_seconds        = 15
            timeout_seconds       = 30
            failure_threshold     = 3
            success_threshold     = 1
          }
        }

        volume {
          name = "config"
          secret {
            secret_name = kubernetes_secret.lag_exporter_config[0].metadata.0.name
          }
        }
      }
    }
  }
}

resource "confluent_service_account" "kafka_lag_exporter" {
  count = var.enable_metric_exporters ? 1 : 0

  display_name = "${local.lc_name}-kafka-lag-exporter${var.add_service_account_suffix ? "-${random_pet.pet.id}" : ""}"
  description  = "Kafka lag exporter service account"
}

resource "confluent_role_binding" "kafka_lag_exporter_cluster_role_binding" {
  count = var.enable_metric_exporters ? 1 : 0

  principal   = "User:${confluent_service_account.kafka_lag_exporter[0].id}"
  role_name   = "CloudClusterAdmin"
  crn_pattern = confluent_kafka_cluster.cluster.rbac_crn
}

resource "confluent_api_key" "kafka_lag_exporter_api_key" {
  count = var.enable_metric_exporters ? 1 : 0

  display_name = "${local.name}-kafka-lag-exporter${var.add_service_account_suffix ? "-${random_pet.pet.id}" : ""}-api-key"
  description  = "${local.name} Kafka lag exporter api key"
  owner {
    id          = confluent_service_account.kafka_lag_exporter[0].id
    api_version = confluent_service_account.kafka_lag_exporter[0].api_version
    kind        = confluent_service_account.kafka_lag_exporter[0].kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.cluster.id
    api_version = confluent_kafka_cluster.cluster.api_version
    kind        = confluent_kafka_cluster.cluster.kind

    environment {
      id = confluent_environment.environment.id
    }
  }
  depends_on = [
    confluent_role_binding.kafka_lag_exporter_cluster_role_binding
  ]
}

# Topic Readers ACL
resource "confluent_kafka_acl" "kafka_lag_exporter_read_topic" {
  count = var.enable_metric_exporters ? 1 : 0

  kafka_cluster {
    id = confluent_kafka_cluster.cluster.id
  }
  resource_type = "TOPIC"
  resource_name = "*"
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.kafka_lag_exporter[0].id}"
  host          = "*"
  operation     = "READ"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.cluster.rest_endpoint
  credentials {
    key    = confluent_api_key.kafka_lag_exporter_api_key[0].id
    secret = confluent_api_key.kafka_lag_exporter_api_key[0].secret
  }
}

# Topic Describe ACL
resource "confluent_kafka_acl" "kafka_lag_exporter_describe_topic" {
  count = var.enable_metric_exporters ? 1 : 0

  kafka_cluster {
    id = confluent_kafka_cluster.cluster.id
  }
  resource_type = "TOPIC"
  resource_name = "*"
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.kafka_lag_exporter[0].id}"
  host          = "*"
  operation     = "DESCRIBE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.cluster.rest_endpoint
  credentials {
    key    = confluent_api_key.kafka_lag_exporter_api_key[0].id
    secret = confluent_api_key.kafka_lag_exporter_api_key[0].secret
  }
}

# Topic Describe Group ACL
resource "confluent_kafka_acl" "kafka_lag_exporter_describe_consumer_group" {
  count = var.enable_metric_exporters ? 1 : 0

  kafka_cluster {
    id = confluent_kafka_cluster.cluster.id
  }
  resource_type = "GROUP"
  resource_name = "*"
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.kafka_lag_exporter[0].id}"
  host          = "*"
  operation     = "DESCRIBE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.cluster.rest_endpoint
  credentials {
    key    = confluent_api_key.kafka_lag_exporter_api_key[0].id
    secret = confluent_api_key.kafka_lag_exporter_api_key[0].secret
  }
}
