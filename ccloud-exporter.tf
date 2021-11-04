locals {
  ccloud_exporter_common_labels = {
    name       = "ccloud-exporter"
    instance   = "ccloud-exporter"
    managed-by = "Terraform"
  }
  ccloud_exporter_name = "${local.lc_name}-ccloud-exporter"
}

resource "kubernetes_service_account" "ccloud_exporter_service_account" {
  count = var.enable_metric_exporters ? 1 : 0

  metadata {
    name      = local.ccloud_exporter_name
    namespace = var.metric_exporters_namespace
    labels    = local.ccloud_exporter_common_labels
  }
}

resource "kubernetes_secret" "ccloud_exporter_config" {
  count = var.enable_metric_exporters ? 1 : 0

  metadata {
    name      = local.ccloud_exporter_name
    namespace = var.metric_exporters_namespace
    labels    = local.ccloud_exporter_common_labels
  }

  data = {
    CCLOUD_API_KEY    = confluentcloud_api_key.ccloud_exporter_api_key[0].key
    CCLOUD_API_SECRET = confluentcloud_api_key.ccloud_exporter_api_key[0].secret
    CCLOUD_CLUSTER    = confluentcloud_kafka_cluster.cluster.id
  }
}

resource "kubernetes_deployment" "ccloud_exporter_deployment" {
  count = var.enable_metric_exporters ? 1 : 0

  #   # if set to true, k8s apply take a long time
  wait_for_rollout = false

  metadata {
    name      = local.ccloud_exporter_name
    namespace = var.metric_exporters_namespace
    labels    = local.ccloud_exporter_common_labels
  }

  spec {
    replicas = 1

    selector {
      match_labels = local.ccloud_exporter_common_labels
    }

    template {
      metadata {
        labels = local.ccloud_exporter_common_labels
        annotations = {
          "prometheus.io/port"   = "2112"
          "prometheus.io/path"   = "/metrics"
          "prometheus.io/scrape" = "true"
        }
      }

      spec {
        service_account_name             = kubernetes_service_account.ccloud_exporter_service_account[0].metadata.0.name
        termination_grace_period_seconds = 300

        container {
          name  = local.ccloud_exporter_name
          image = "dabz/ccloudexporter:${var.ccloud_exporter_image_version}"
          # https://github.com/Dabz/ccloudexporter/releases
          # Repo recommends pointing to master
          image_pull_policy = "Always"

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

          env_from {
            secret_ref {
              name = kubernetes_secret.ccloud_exporter_config[0].metadata.0.name
            }
          }

          port {
            name           = "http"
            container_port = 2112
            protocol       = "TCP"
          }

          readiness_probe {
            http_get {
              path = "/metrics"
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
              path = "/metrics"
              port = "http"
            }

            initial_delay_seconds = 30
            period_seconds        = 15
            timeout_seconds       = 30
            failure_threshold     = 3
            success_threshold     = 1
          }
        }
      }
    }
  }
}
