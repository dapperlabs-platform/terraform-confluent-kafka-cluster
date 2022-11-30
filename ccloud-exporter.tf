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


resource "kubernetes_secret" "ccloud_exporter_config_file" {
  count = var.enable_metric_exporters ? 1 : 0

  metadata {
    name      = "${local.ccloud_exporter_name}-config-file"
    namespace = var.metric_exporters_namespace
    labels    = local.ccloud_exporter_common_labels
  }

  data = {
    "config.yaml" = templatefile(
      "${path.module}/templates/ccloud-exporter.yaml",
      {
        cluster_id = confluentcloud_kafka_cluster.cluster.id
      }
    )
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
    annotations = var.ccloud_exporter_annotations
  }

  spec {
    replicas = 1

    # Kill all existing Pods before creating new ones
    # to avoid possible rate limiting
    strategy {
      type = "Recreate"
    }

    selector {
      match_labels = local.ccloud_exporter_common_labels
    }

    template {
      metadata {
        labels = local.ccloud_exporter_common_labels
        annotations = merge(
          {
          "prometheus.io/port"   = "2112"
          "prometheus.io/path"   = "/metrics"
          "prometheus.io/scrape" = "true"
        },
          var.ccloud_exporter_annotations,
        )
      }

      spec {
        service_account_name             = kubernetes_service_account.ccloud_exporter_service_account[0].metadata.0.name
        termination_grace_period_seconds = 300
        node_selector                    = var.exporters_node_selector

        container {
          name  = local.ccloud_exporter_name
          image = "dabz/ccloudexporter:${var.ccloud_exporter_image_version}"
          # https://github.com/Dabz/ccloudexporter/releases
          # Repo recommends pointing to master
          image_pull_policy = "Always"

          args = ["-config", "/opt/docker/conf/config.yaml"]

          resources {
            requests = var.ccloud_exporter_container_resources.requests
            limits   = var.ccloud_exporter_container_resources.limits
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.ccloud_exporter_config[0].metadata.0.name
            }
          }

          volume_mount {
            mount_path = "/opt/docker/conf/"
            name       = "config"
            read_only  = true
          }

          port {
            name           = "http"
            container_port = 2112
            protocol       = "TCP"
          }

          readiness_probe {
            http_get {
              path = "/health"
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
              path = "/health"
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
            secret_name = kubernetes_secret.ccloud_exporter_config_file[0].metadata.0.name
          }
        }
      }
    }
  }
}
