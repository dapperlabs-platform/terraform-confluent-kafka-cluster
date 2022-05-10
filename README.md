# Confluent Kafka cluster

https://www.confluent.io/confluent-cloud/

https://registry.terraform.io/providers/Mongey/confluentcloud/latest/docs

https://registry.terraform.io/providers/Mongey/kafka/latest/docs

## What does this do?

Creates a Confluent Cloud Kafka cluster, topics, service accounts, ACLs and optionally metric exporter K8S deployments as recommended by Confluent Cloud on [this blog post](https://www.confluent.io/blog/monitor-kafka-clusters-with-prometheus-grafana-and-confluent/) (see parts 1 and 2).

## How to use this module?

```hcl
module "confluent-kafka-cluster" {
  source                            = "github.com/dapperlabs-platform/terraform-confluent-kafka-cluster?ref=tag"
  confluent_cloud_username          = "<username>"
  confluent_cloud_password          = "<password>"
  name                              = "cluster-name"
  environment                       = "staging"
  gcp_region                        = "us-west1"
  enable_metric_exporters           = true
  kafka_lag_exporter_image_version  = "<lookup>"
  metric_exporters_namespace        = "sre"
  create_grafana_dashboards         = true
  grafana_datasource                = "Default Datasource"
  topics = {
    "topic-1" = {
      replication_factor = 3
      partitions         = 1
      config = {
        "cleanup.policy" = "delete"
      }
      acl_readers = ["user1"]
      acl_writers = ["user2"]
    }
  }
}
```

## Resources created

- 1 Confluent Cloud environment
- 1 Kafka cluster
- 1 Service account for each distinct entry in `acl_readers` and `acl_writers` variables
- Topics

### If `enable_metric_exporters` is set to true

[Kafka-lag-exporter](https://github.com/lightbend/kafka-lag-exporter) and [ccloud-exporter](https://github.com/Dabz/ccloudexporter) resources:

- 1 K8S Service account
- 1 K8S Secret with credentials and configs
- 1 K8S Deployment

## Additional information

The module outputs a map of service account credentials, keyed by the names provided to the `acl_` variables. Use this output as input to a separate module or resource that saves it for application use.

> `reader` service accounts are granted read access to all groups. See `group_readers` resource.

## Requirements

- Terraform >= 1.0.0
- Mongey/confluentcloud >= 0.0.12
- Mongey/kafka >= 0.2.11
- grafana/grafana >= 1.14.0

## Inputs

| Name                                                                                                                                                                                                                                    | Description                                                                                                  | Type   | Default | Required |
| --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------ | ------ | ------- | :------: |
| name                                                                                                                                                                                                                                    | Kafka cluster identifier. Will be prepended by the environment value in Confluent cloud                      | string |         |    x     |
| environment                                                                                                                                                                                                                             | Application environment that uses the cluster                                                                | string |         |    x     |
| gcp_region                                                                                                                                                                                                                              | GCP region in which to deploy the cluster. See https://docs.confluent.io/cloud/current/clusters/regions.html | string |         |    x     |
| availability                                                                                                                                                                                                                            | Cluster availability. LOW or HIGH                                                                            | string | LOW     |          |
| storage                                                                                                                                                                                                                                 | Storage limit(GB)                                                                                            | number | 5000    |          |
| network_egress                                                                                                                                                                                                                          | Network egress limit(MBps)                                                                                   | number | 100     |          |
| network_ingress                                                                                                                                                                                                                         | Network ingress limit(MBps)                                                                                  | number | 100     |          |
| cluster_tier                                                                                                                                                                                                                            | Cluster tier                                                                                                 | string | BASIC   |          |
| service_provider                                                                                                                                                                                                                        | Confluent cloud service provider. AWS, GCP, Azure                                                            | string | GCP     |          |
| topics                                                                                                                                                                                                                                  | Kafka topic definitions.                                                                                     |
| Object map keyed by topic name with topic configuration values as well as reader and writer ACL lists. Values provided to the ACL lists will become service accounts with { key, secret } objects output by service_account_credentials | list(object)                                                                                                 |        | x       |
| enable_metric_exporters                                                                                                                                                                                                                 | Whether to deploy metrics exporters                                                                          | bool   |         |  false   |
| metric_exporters_namespace                                                                                                                                                                                                              | K8S Namespace in which to deploy metrics exporters                                                           | string |         |   sre    |
| kafka_lag_exporter_image_version                                                                                                                                                                                                        | Kafka lag exporter image version                                                                             | string |         |          |
| create_grafana_dashboards                                                                                                                                                                                                               | Whether to create Grafana dashboards                                                                         | bool   |         |  false   |
| grafana_datasource                                                                                                                                                                                                                      | Grafana datasource to use in dashboards                                                                      | string |         |   null   |
