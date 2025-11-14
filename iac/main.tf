terraform {
    required_version = ">= 1.0.0"
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "2.69.0"
    }
  }
  backend "pg" {}
}

variable "do_token" {}

variable "region" {
  default = "nyc1"
}

provider "digitalocean" {
  token = var.do_token
}

resource "digitalocean_vpc" "vpc" {
  name     = "k8s-vpc"
  region   = var.region
}


resource "digitalocean_kubernetes_cluster" "k8s" {
  name   = "cluster-k8s"
  region = var.region
  version = "1.33.1-do.5"
  vpc_uuid = digitalocean_vpc.vpc.id

  node_pool {
    name       = "default"
    size       = "s-2vcpu-2gb"
    node_count = 3
  }
}

resource "digitalocean_database_cluster" "postgres_homolog" {
  name       = "pg-homolog"
  engine     = "pg"
  version    = "17"
  size       = "db-s-1vcpu-1gb"
  region     = var.region
  node_count = 1
  private_network_uuid = digitalocean_vpc.vpc.id
}

resource "digitalocean_database_cluster" "postgres_prod" {
  name       = "pg-prod"
  engine     = "pg"
  version    = "17"
  size       = "db-s-1vcpu-1gb"
  region     = var.region
  node_count = 1
}

resource "local_file" "kubeconfig" {
    content = digitalocean_kubernetes_cluster.k8s.kube_config[0].raw_config
    filename = "kubeconfig.yaml"
}