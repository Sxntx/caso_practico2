
/*
Outputs file include all outputs we want to console show
This file include public ip output as a requiriment to practice.

VIP -> virtual public ip
*/
output "vip" {
  value = azurerm_public_ip.pip.ip_address
}
