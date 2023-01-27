## NOTE: This is deprecated and no longer being used on new projects.

We're using this module now:

https://github.com/dapperlabs-platform/terraform-confluent-official-kafka-cluster

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

[Kafka-lag-exporter](https://github.com/seglo/kafka-lag-exporter) and [ccloud-exporter](https://github.com/Dabz/ccloudexporter) resources:

- 1 K8S Service account
- 1 K8S Secret with credentials and configs
- 1 K8S Deployment

## Additional information

The module outputs a map of service account credentials, keyed by the names provided to the `acl_` variables. Use this output as input to a separate module or resource that saves it for application use.

> `reader` service accounts are granted read access to all groups. See `group_readers` resource.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_confluentcloud"></a> [confluentcloud](#requirement\_confluentcloud) | >= 0.0.12 |
| <a name="requirement_grafana"></a> [grafana](#requirement\_grafana) | ~> 1.20 |
| <a name="requirement_kafka"></a> [kafka](#requirement\_kafka) | >= 0.2.11 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_confluentcloud"></a> [confluentcloud](#provider\_confluentcloud) | >= 0.0.12 |
| <a name="provider_grafana"></a> [grafana](#provider\_grafana) | ~> 1.20 |
| <a name="provider_kafka"></a> [kafka](#provider\_kafka) | >= 0.2.11 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >= 2 |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [confluentcloud_api_key.admin_api_key](https://registry.terraform.io/providers/Mongey/confluentcloud/latest/docs/resources/api_key) | resource |
| [confluentcloud_api_key.ccloud_exporter_api_key](https://registry.terraform.io/providers/Mongey/confluentcloud/latest/docs/resources/api_key) | resource |
| [confluentcloud_api_key.kafka_lag_exporter_api_key](https://registry.terraform.io/providers/Mongey/confluentcloud/latest/docs/resources/api_key) | resource |
| [confluentcloud_api_key.service_account_api_keys](https://registry.terraform.io/providers/Mongey/confluentcloud/latest/docs/resources/api_key) | resource |
| [confluentcloud_environment.environment](https://registry.terraform.io/providers/Mongey/confluentcloud/latest/docs/resources/environment) | resource |
| [confluentcloud_kafka_cluster.cluster](https://registry.terraform.io/providers/Mongey/confluentcloud/latest/docs/resources/kafka_cluster) | resource |
| [confluentcloud_service_account.kafka_lag_exporter](https://registry.terraform.io/providers/Mongey/confluentcloud/latest/docs/resources/service_account) | resource |
| [confluentcloud_service_account.service_accounts](https://registry.terraform.io/providers/Mongey/confluentcloud/latest/docs/resources/service_account) | resource |
| [grafana_dashboard.ccloud_exporter](https://registry.terraform.io/providers/grafana/grafana/latest/docs/resources/dashboard) | resource |
| [grafana_dashboard.kafka_lag_exporter](https://registry.terraform.io/providers/grafana/grafana/latest/docs/resources/dashboard) | resource |
| [grafana_folder.confluent_cloud](https://registry.terraform.io/providers/grafana/grafana/latest/docs/resources/folder) | resource |
| [kafka_acl.group_readers](https://registry.terraform.io/providers/Mongey/kafka/latest/docs/resources/acl) | resource |
| [kafka_acl.kafka_lag_exporter_describe_consumer_group](https://registry.terraform.io/providers/Mongey/kafka/latest/docs/resources/acl) | resource |
| [kafka_acl.kafka_lag_exporter_describe_topic](https://registry.terraform.io/providers/Mongey/kafka/latest/docs/resources/acl) | resource |
| [kafka_acl.kafka_lag_exporter_read_topic](https://registry.terraform.io/providers/Mongey/kafka/latest/docs/resources/acl) | resource |
| [kafka_acl.readers](https://registry.terraform.io/providers/Mongey/kafka/latest/docs/resources/acl) | resource |
| [kafka_acl.writers](https://registry.terraform.io/providers/Mongey/kafka/latest/docs/resources/acl) | resource |
| [kafka_topic.topics](https://registry.terraform.io/providers/Mongey/kafka/latest/docs/resources/topic) | resource |
| [kubernetes_deployment.ccloud_exporter_deployment](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment) | resource |
| [kubernetes_deployment.lag_exporter_deployment](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment) | resource |
| [kubernetes_secret.ccloud_exporter_config](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.ccloud_exporter_config_file](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.lag_exporter_config](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_service_account.ccloud_exporter_service_account](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account) | resource |
| [kubernetes_service_account.lag_exporter_service_account](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account) | resource |
| [random_pet.pet](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/pet) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_add_service_account_suffix"></a> [add\_service\_account\_suffix](#input\_add\_service\_account\_suffix) | Add pet name suffix to service account names to avoid collision | `bool` | `false` | no |
| <a name="input_availability"></a> [availability](#input\_availability) | Cluster availability. LOW or HIGH | `string` | `"LOW"` | no |
| <a name="input_ccloud_exporter_annotations"></a> [ccloud\_exporter\_annotations](#input\_ccloud\_exporter\_annotations) | CCloud exporter annotations | `map(string)` | `{}` | no |
| <a name="input_ccloud_exporter_container_resources"></a> [ccloud\_exporter\_container\_resources](#input\_ccloud\_exporter\_container\_resources) | Container resource limit configuration | `map(map(string))` | <pre>{<br>  "limits": {<br>    "cpu": "500m",<br>    "memory": "2Gi"<br>  },<br>  "requests": {<br>    "cpu": "250m",<br>    "memory": "1Gi"<br>  }<br>}</pre> | no |
| <a name="input_ccloud_exporter_image_version"></a> [ccloud\_exporter\_image\_version](#input\_ccloud\_exporter\_image\_version) | Exporter Image Version | `string` | `"latest"` | no |
| <a name="input_cku"></a> [cku](#input\_cku) | Number of CKUs | `number` | `null` | no |
| <a name="input_cluster_tier"></a> [cluster\_tier](#input\_cluster\_tier) | Cluster tier | `string` | `"BASIC"` | no |
| <a name="input_create_grafana_dashboards"></a> [create\_grafana\_dashboards](#input\_create\_grafana\_dashboards) | Whether to create grafana dashboards with default metric exporter panels | `bool` | `false` | no |
| <a name="input_enable_metric_exporters"></a> [enable\_metric\_exporters](#input\_enable\_metric\_exporters) | Whether to deploy kafka-lag-exporter and ccloud-exporter in a kubernetes cluster | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Application environment that uses the cluster | `string` | n/a | yes |
| <a name="input_exporters_node_selector"></a> [exporters\_node\_selector](#input\_exporters\_node\_selector) | K8S Deployment node selector for metric exporters | `map(string)` | `null` | no |
| <a name="input_gcp_region"></a> [gcp\_region](#input\_gcp\_region) | GCP region in which to deploy the cluster. See https://docs.confluent.io/cloud/current/clusters/regions.html | `string` | n/a | yes |
| <a name="input_grafana_datasource"></a> [grafana\_datasource](#input\_grafana\_datasource) | Name of Grafana data source where Kafka metrics are stored | `string` | `null` | no |
| <a name="input_kafka_lag_exporter_annotations"></a> [kafka\_lag\_exporter\_annotations](#input\_kafka\_lag\_exporter\_annotations) | Lag exporter annotations | `map(string)` | `{}` | no |
| <a name="input_kafka_lag_exporter_container_resources"></a> [kafka\_lag\_exporter\_container\_resources](#input\_kafka\_lag\_exporter\_container\_resources) | Container resource limit configuration | `map(map(string))` | <pre>{<br>  "limits": {<br>    "cpu": "500m",<br>    "memory": "2Gi"<br>  },<br>  "requests": {<br>    "cpu": "250m",<br>    "memory": "1Gi"<br>  }<br>}</pre> | no |
| <a name="input_kafka_lag_exporter_image_version"></a> [kafka\_lag\_exporter\_image\_version](#input\_kafka\_lag\_exporter\_image\_version) | See https://github.com/seglo/kafka-lag-exporter/releases | `string` | n/a | yes |
| <a name="input_kafka_lag_exporter_log_level"></a> [kafka\_lag\_exporter\_log\_level](#input\_kafka\_lag\_exporter\_log\_level) | Lag exporter log level | `string` | `"INFO"` | no |
| <a name="input_metric_exporters_namespace"></a> [metric\_exporters\_namespace](#input\_metric\_exporters\_namespace) | Namespace to deploy exporters to | `string` | `"sre"` | no |
| <a name="input_name"></a> [name](#input\_name) | Kafka cluster identifier. Will be prepended by the environment value in Confluent cloud | `string` | n/a | yes |
| <a name="input_network_egress"></a> [network\_egress](#input\_network\_egress) | Network egress limit(MBps) | `number` | `100` | no |
| <a name="input_network_ingress"></a> [network\_ingress](#input\_network\_ingress) | Network ingress limit(MBps) | `number` | `100` | no |
| <a name="input_service_provider"></a> [service\_provider](#input\_service\_provider) | Confluent cloud service provider. AWS, GCP, Azure | `string` | `"gcp"` | no |
| <a name="input_storage"></a> [storage](#input\_storage) | Storage limit(GB) | `number` | `5000` | no |
| <a name="input_topics"></a> [topics](#input\_topics) | Kafka topic definitions.<br>  Object map keyed by topic name with topic configuration values as well as reader and writer ACL lists.<br>  Values provided to the ACL lists will become service accounts with { key, secret } objects output by service\_account\_credentials | <pre>map(<br>    object({<br>      replication_factor = number<br>      partitions         = number<br>      config             = object({})<br>      acl_readers        = list(string)<br>      acl_writers        = list(string)<br>    })<br>  )</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_admin_api_key"></a> [admin\_api\_key](#output\_admin\_api\_key) | Admin user api key and secret |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | Cluster ID |
| <a name="output_kafka_url"></a> [kafka\_url](#output\_kafka\_url) | URL to connect your Kafka clients to |
| <a name="output_rest_api_endpoint"></a> [rest\_api\_endpoint](#output\_rest\_api\_endpoint) | REST API endpoint to manage the cluster |
| <a name="output_service_account_credentials"></a> [service\_account\_credentials](#output\_service\_account\_credentials) | Map containing service account credentials.<br>  Keys are service account names provided to topics as readers and writers.<br>  Values are objects with key and secret values. |