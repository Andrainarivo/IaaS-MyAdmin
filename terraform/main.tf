module "networks" {
  source = "./modules/networks"
  region = var.region
}

module "firewalls" {
  source       = "./modules/firewalls"
  network_name = module.networks.vpc_name
}

module "registry" {
  source = "./modules/registry"
  region = var.region
}

module "instances" {
  source     = "./modules/instances"
  project_id = var.project_id
  zone       = var.zone
  subnet_id  = module.networks.subnet_id
  k3s_token  = var.k3s_token
}