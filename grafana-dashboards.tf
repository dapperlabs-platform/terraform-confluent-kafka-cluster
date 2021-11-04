resource "grafana_folder" "confluent_cloud" {
  count = var.create_grafana_dashboards ? 1 : 0
  title = "${local.name} Confluent Cloud"
}

resource "grafana_dashboard" "ccloud_exporter" {
  count  = var.create_grafana_dashboards ? 1 : 0
  folder = grafana_folder.confluent_cloud[0].id
  config_json = templatefile(
    "${path.module}/templates/ccloud-exporter.json",
    {
      datasource = var.grafana_datasource
    }
  )
}

resource "grafana_dashboard" "kafka_lag_exporter" {
  count  = var.create_grafana_dashboards ? 1 : 0
  folder = grafana_folder.confluent_cloud[0].id
  config_json = templatefile(
    "${path.module}/templates/kafka-lag-exporter.json",
    {
      datasource = var.grafana_datasource
    }
  )
}
