locals {
  common_labels = {
    name       = "kafka-lag-exporter"
    instance   = "kafka-lag-exporter"
    managed-by = "Terraform"
  }
  lag_exporter_name = "${local.lc_name}-kafka-lag-exporter"
}

resource "kubernetes_service_account" "lag_exporter_service_account" {
  count = var.enable_lag_exporter ? 1 : 0

  metadata {
    name      = local.lag_exporter_name
    namespace = var.lag_exporter_namespace
    labels    = local.common_labels
  }
}

resource "kubernetes_secret" "lag_exporter_config" {
  count = var.enable_lag_exporter ? 1 : 0

  metadata {
    name      = local.lag_exporter_name
    namespace = var.lag_exporter_namespace
    labels    = local.common_labels
  }

  data = {
    "application.conf" = templatefile(
      "${path.module}/templates/application.conf", {
        username         = confluentcloud_api_key.kafka_lag_exporter_api_key[0].key
        password         = confluentcloud_api_key.kafka_lag_exporter_api_key[0].secret
        namespace        = var.lag_exporter_namespace
        bootstrapBrokers = local.bootstrap_servers[0]
    })
    "logback.xml" = file("${path.module}/templates/logback.xml")
  }
}

resource "kubernetes_deployment" "lag_exporter_deployment" {
  count = var.enable_lag_exporter ? 1 : 0

  #   # if set to true, k8s apply take a long time
  wait_for_rollout = false

  metadata {
    name      = local.lag_exporter_name
    namespace = var.lag_exporter_namespace
    labels    = local.common_labels
  }

  spec {
    replicas = 1

    selector {
      match_labels = local.common_labels
    }

    template {
      metadata {
        labels = local.common_labels
        annotations = {
          "prometheus.io/port"   = "9090"
          "prometheus.io/path"   = "/"
          "prometheus.io/scrape" = "true"
        }
      }

      spec {
        service_account_name             = kubernetes_service_account.lag_exporter_service_account[0].metadata.0.name
        termination_grace_period_seconds = 300

        container {
          image             = "lightbend/kafka-lag-exporter:${var.lag_exporter_image_version}"
          name              = local.lag_exporter_name
          image_pull_policy = "IfNotPresent"

          resources {
            limits = {
              cpu    = "500m"
              memory = "256Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "128Mi"
            }
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
