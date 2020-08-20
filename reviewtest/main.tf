variable "cloudflare_email" {}
variable "cloudflare_api_key" {}
variable "do_db_connection_string" {}
locals {
  name = "delphai-review-test"
  az_location = "West Europe"
  node_size = "Standard_D2_v2"
  domains = [
     "delphai.xyz",
    "delphai.pink"
  ]
}

terraform {
  backend "azurerm" {
    resource_group_name  = "base-infrastructure-terraform"
    key                  = "base-infrastructure.tfstate"
    storage_account_name = "delphaidevelopment"
    container_name       = "delphai-development-terraform-state"
  }
}

provider "azurerm" {
  features {}
}
provider "cloudflare" {
  version = "~> 2.0"
  email = var.cloudflare_email
  api_key = var.cloudflare_api_key
}

provider "kubernetes" {
  load_config_file       = "false"
  host                   = module.base_cluster.cluster.kube_config.0.host
  username               = module.base_cluster.cluster.kube_config.0.username
  password               = module.base_cluster.cluster.kube_config.0.password
  client_certificate     = base64decode(module.base_cluster.cluster.kube_config.0.client_certificate)
  client_key             = base64decode(module.base_cluster.cluster.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(module.base_cluster.cluster.kube_config.0.cluster_ca_certificate)
}
provider "helm" {
  kubernetes {
    load_config_file       = "false"
    host                   = module.base_cluster.cluster.kube_config.0.host
    username               = module.base_cluster.cluster.kube_config.0.username
    password               = module.base_cluster.cluster.kube_config.0.password
    client_certificate     = base64decode(module.base_cluster.cluster.kube_config.0.client_certificate)
    client_key             = base64decode(module.base_cluster.cluster.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(module.base_cluster.cluster.kube_config.0.cluster_ca_certificate)
  }
}

module "base_cluster" {
  source = "../modules/base-infrastructure"
  az_location = local.az_location
  node_size = local.node_size
  name = local.name
  domains = local.domains
}

module "elasticsearch" {
  source = "../modules/elasticsearch"
  domain = local.domains[1]
  kube_context = local.name
  ingress_enabled = true
}

module "gloo" {
  source = "../modules/gloo"
  domains = local.domains
}

module "nginx_ingress" {
  source = "../modules/nginx-ingress"
  domains = local.domains
}

module "do_db_connection_string" {
  source = "../modules/kubernetes-secret"
  name = "do-db-connection-string"
  data = {
    "connection-string" = var.do_db_connection_string
  }
}