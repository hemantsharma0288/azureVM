data "azurerm_subnet" "subnet" {
  name                 = "${var.subnet_name}"
  virtual_network_name = "${var.vnet_name}"
  resource_group_name  = "${var.vnet_resource_group_name}"
}

data "azurerm_resource_group" "main" {
  name = "${var.resource_group_name}"
}

locals {
  master_custom_data = "${var.custom_data != "" ? var.custom_data : var.master_custom_data}"
  worker_custom_data = "${var.custom_data != "" ? var.custom_data : var.worker_custom_data}"
  master_username    = "${var.master_username != "" ? var.master_username : var.admin_username}"
  worker_username    = "${var.worker_username != "" ? var.worker_username : var.admin_username}"
}

module "master_loadbalancer" {
  source = "git::ssh://git@scm.starbucks.com/terraform-modules/azure_load_balancer"

  resource_group_name = "${data.azurerm_resource_group.main.name}"
  type                = "${var.master_lb_type}"
  prefix              = "${var.resource_prefix}${var.master_lb_prefix}"
  subnet_id           = "${data.azurerm_subnet.subnet.id}"
  private_ip_address  = "${var.master_lb_private_ip_address}"

  "lb_port" = "${var.master_lb_port}"
}

module "kube_master" {
  source = "git::ssh://git@scm.starbucks.com/terraform-modules/azure_linux_vm"

  resource_group_name     = "${data.azurerm_resource_group.main.name}"
  node_count              = "${var.master_node_count}"
  subnet_id               = "${data.azurerm_subnet.subnet.id}"
  backend_address_pool_id = "${module.master_loadbalancer.lb_backend_address_pool_id}"
  vm_name                 = "${var.resource_prefix}${var.master_vm_name}"
  vm_size                 = "${var.master_vm_size}"
  os_disk_size_gb         = "${var.master_os_disk_size_gb}"

  availability_set_name = "${var.resource_prefix}${var.master_availability_set_name}"

  admin_username = "${local.master_username}"
  ssh_key_path   = "${var.ssh_key_path}"
  custom_data    = "${local.master_custom_data}"

  vm_os_publisher = "${var.vm_os_publisher}"
  vm_os_offer     = "${var.vm_os_offer}"
  vm_os_sku       = "${var.vm_os_sku}"
  vm_os_version   = "${var.vm_os_version}"

  data_disk            = "${var.master_data_disk}"
  managed_disk_size_gb = "${var.master_managed_disk_size_gb}"

  boot_diagnostics_storage_uri = "${var.boot_diagnostics_storage_uri}"
}

module "worker_loadbalancer" {
  source = "git::ssh://git@scm.starbucks.com/terraform-modules/azure_load_balancer"

  resource_group_name = "${data.azurerm_resource_group.main.name}"
  type                = "${var.worker_lb_type}"
  prefix              = "${var.resource_prefix}${var.worker_lb_prefix}"
  subnet_id           = "${data.azurerm_subnet.subnet.id}"
  private_ip_address  = "${var.worker_lb_private_ip_address}"

  "lb_port" = "${var.worker_lb_port}"
}

module "kube_worker" {
  source = "git::ssh://git@scm.starbucks.com/terraform-modules/azure_linux_vm"

  resource_group_name     = "${data.azurerm_resource_group.main.name}"
  node_count              = "${var.worker_node_count}"
  subnet_id               = "${data.azurerm_subnet.subnet.id}"
  backend_address_pool_id = "${module.worker_loadbalancer.lb_backend_address_pool_id}"
  vm_name                 = "${var.resource_prefix}${var.worker_vm_name}"
  vm_size                 = "${var.worker_vm_size}"
  os_disk_size_gb         = "${var.worker_os_disk_size_gb}"

  availability_set_name = "${var.resource_prefix}${var.worker_availability_set_name}"

  admin_username = "${local.worker_username}"
  ssh_key_path   = "${var.ssh_key_path}"
  custom_data    = "${local.worker_custom_data}"

  vm_os_publisher = "${var.vm_os_publisher}"
  vm_os_offer     = "${var.vm_os_offer}"
  vm_os_sku       = "${var.vm_os_sku}"
  vm_os_version   = "${var.vm_os_version}"

  data_disk            = "${var.worker_data_disk}"
  managed_disk_size_gb = "${var.worker_managed_disk_size_gb}"

  boot_diagnostics_storage_uri = "${var.boot_diagnostics_storage_uri}"
}
