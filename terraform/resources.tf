/*
This file is created to deploy an IaaC on Azure cloud with several custom settings.
All settings in this configuration file tries to fit pratice requeriments.
There are all steps prectice requires like (not in following order but they are.):

-Azure Virtual Network Links to an external site.
-Azure Subnet Links to an external site.
-Azure Network Interface Links to an external site.
-Azure Public IP Links to an external site.
-Azure Network Security Group Links to an external site.
-Azure Network Security Rule Links to an external site.
-Azure Linux Virtual Machine Links to an external site.
-Azure Container Registry Links to an external site.
-Azure Kubernetes Cluster (AKS) Links to an external site.
*/
//1 set resource group to use on AZ
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location_name
}
//2 Kubernetes cluster to use. requeriment of practice
resource "azurerm_kubernetes_cluster" "azkc" {
  name                = "azkc-aks1"
  location            = azurerm_resource_group.azkc.location
  resource_group_name = azurerm_resource_group.azkc.name
  dns_prefix          = "azkcaks1"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_D2_v2"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "Production"
  }
}

output "client_certificate" {
  value     = azurerm_kubernetes_cluster.azkc.kube_config.0.client_certificate
  sensitive = true
}

output "kube_config" {
  value = azurerm_kubernetes_cluster.azkc.kube_config_raw

  sensitive = true
}
// set security group
resource "azurerm_network_security_group" "secgp" {
  name                = "secgp-security-group"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

    security_rule {
    name                       = "httprule"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
//set virtual network
resource "azurerm_virtual_network" "vnet" {
  name                = var.network_name
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}
//set subnet of virtual network
resource "azurerm_subnet" "subnet" {
  name                 = var.subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}
//set network interface
resource "azurerm_network_interface" "nic" {
  name                = "vnic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}
//set a virtual machine of linux SO
resource "azurerm_linux_virtual_machine" "vm" {
  name                = "vm1"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_F2"
  admin_username      = "azureuser"
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  plan {
    name      = "centos-8-stream-free"
    product   = "centos-8-stream-free"
    publisher = "cognosys"
  }


  source_image_reference {
    publisher = "cognosys"
    offer     = "centos-8-stream-free"
    sku       = "centos-8-stream-free"
    version   = "22.03.28"
  }
}
// ACR - important step in practice.
resource "azurerm_container_registry" "acr03" {
  name                = "containerSantiRegistry1"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Premium"
  admin_enabled       = false
  georeplications {
    location                = "East US"
    zone_redundancy_enabled = true
    tags                    = {}
  }
}
// set public ip to get and output ip to connect to az vm
resource "azurerm_public_ip" "pip" {
  name                = "acceptanceTestPublicIp1"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"

  tags = {
    environment = "Production"
  }
}