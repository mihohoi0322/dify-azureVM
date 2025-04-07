#############################
# Resource Group
#############################
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

#############################
# VNet & Subnet
#############################
resource "azurerm_virtual_network" "dify_vnet" {
  name                = var.vnet_dify_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "dify_subnet" {
  name                 = var.subnet_dify_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.dify_vnet.name
  address_prefixes     = ["10.0.10.0/24"]
}

#############################
# サブネットの追加（Windows VM用とBastion用）
#############################
resource "azurerm_subnet" "windows_subnet" {
  name                 = var.windows_subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.dify_vnet.name
  address_prefixes     = [var.windows_subnet_prefix]
}

# Bastion用のサブネット (名前は必ずAzureBastionSubnetにする必要があります)
resource "azurerm_subnet" "bastion_subnet" {
  name                 = var.bastion_subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.dify_vnet.name
  address_prefixes     = [var.bastion_subnet_prefix]
}

#############################
# Network Security Group
#############################
resource "azurerm_network_security_group" "dify_nsg" {
  name                = var.nsg_dify_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # VM 内部からのみ SSH アクセス（10.0.0.0/16）
  security_rule {
    name                       = "SSH-Private"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "*"
    destination_port_range     = "22"
    source_port_range          = "*"
  }

  # Dify の Web UI (HTTP) も内部アクセスのみ許可
  security_rule {
    name                       = "HTTP-Private"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "*"
    destination_port_range     = "80"
    source_port_range          = "*"
  }
}

#############################
# Windows VMのNSG
#############################
resource "azurerm_network_security_group" "windows_nsg" {
  name                = var.windows_nsg_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowHTTPInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    source_port_range          = "*"
    destination_port_range     = "80"
  }

  security_rule {
    name                       = "AllowRDPBastionInbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "10.0.30.0/24" 
    destination_address_prefix = "*"
    source_port_range          = "*"
    destination_port_range     = "3389"
  }
}

#############################
# Network Interface (プライベート IP のみ)
#############################
resource "azurerm_network_interface" "dify_nic" {
  name                = "dify-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.dify_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "dify_nic_assoc" {
  network_interface_id      = azurerm_network_interface.dify_nic.id
  network_security_group_id = azurerm_network_security_group.dify_nsg.id
}

#############################
# Windows用NIC
#############################
resource "azurerm_network_interface" "windows_nic" {
  name                = var.windows_nic_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.windows_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "windows_nic_assoc" {
  network_interface_id      = azurerm_network_interface.windows_nic.id
  network_security_group_id = azurerm_network_security_group.windows_nsg.id
}

#############################
# Virtual Machine
#############################
data "azurerm_platform_image" "ubuntu" {
  location  = azurerm_resource_group.rg.location
  publisher = "Canonical"
  offer     = "ubuntu-24_04-lts"
  sku       = "server"
}

resource "azurerm_virtual_machine" "dify_vm" {
  name                  = var.vm_dify_name
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  vm_size               = var.dify_vm_size
  network_interface_ids = [azurerm_network_interface.dify_nic.id]
  delete_os_disk_on_termination = true

  storage_os_disk {
    name              = "dify-vm-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
    publisher = data.azurerm_platform_image.ubuntu.publisher
    offer     = data.azurerm_platform_image.ubuntu.offer
    sku       = data.azurerm_platform_image.ubuntu.sku
    version   = "latest"
  }

  os_profile {
    computer_name  = var.vm_dify_name
    admin_username = var.dify_admin_username
    admin_password = "P@ssw0rd1234!"  # 本番ではセキュアな方法で管理してください
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = {
    environment = "self-hosted-dify"
  }
}

#############################
# Windows VM (JumpBox)
#############################
resource "azurerm_windows_virtual_machine" "windows_vm" {
  name                = var.windows_vm_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = var.windows_vm_size
  admin_username      = var.windows_admin_username
  admin_password      = "P@ssw0rd1234!"  # 本番環境では安全な方法で管理してください
  network_interface_ids = [
    azurerm_network_interface.windows_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }
}

#############################
# Custom Script Extension to install Dify
#############################
resource "azurerm_virtual_machine_extension" "dify_install" {
  name                 = "dify-install"
  virtual_machine_id   = azurerm_virtual_machine.dify_vm.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"

  settings = <<SETTINGS
{
  "commandToExecute": "bash -c 'apt-get update && apt-get install -y ca-certificates curl gnupg git && install -m 0755 -d /etc/apt/keyrings && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && chmod a+r /etc/apt/keyrings/docker.gpg && echo \"deb [arch=\\\"$(dpkg --print-architecture)\\\" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo \\\"$VERSION_CODENAME\\\") stable\" | tee /etc/apt/sources.list.d/docker.list > /dev/null && apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin && usermod -aG docker difyadmin && git clone https://github.com/langgenius/dify.git /home/difyadmin/dify && cd /home/difyadmin/dify/docker && cp .env.example .env && docker compose up -d'"
}
SETTINGS
}

#############################
# Azure Bastionの設定
#############################
resource "azurerm_public_ip" "bastion_ip" {
  name                = var.bastion_ip_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bastion" {
  name                = var.bastion_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion_subnet.id
    public_ip_address_id = azurerm_public_ip.bastion_ip.id
  }
}