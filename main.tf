terraform {
 required_providers {
    equinix = {
  source  = "equinix/equinix"
      version = "1.13.0"
   }
  }
}
provider "equinix" {
  # Configuration options
   # Credentials for only Equinix Metal resources
 auth_token = "5DeAUudqaVwRJsuuTMpa2xrrqSwpj1X7"
}
#specs of server and machine
resource "equinix_metal_device" "web2" {
  hostname = "camiloteda"
  plan = "c3.small.x86"
  metro = "da"
  operating_system = "ubuntu_20_04"
  billing_cycle = "hourly"
  project_id = "d0418d98-86af-417a-a50a-331c989ffe63"
}
resource "equinix_metal_device" "web3" {
hostname = "camilotedc"
plan = "c3.small.x86"
metro = "dc"
 operating_system = "ubuntu_20_04"
  billing_cycle = "hourly"
  project_id = "d0418d98-86af-417a-a50a-331c989ffe63"
}
resource "equinix_metal_vlan" "vlan2" {
  description = "VLAN in Dallas"
 metro = "da"
 project_id = "d0418d98-86af-417a-a50a-331c989ffe63"
vxlan=1008
}
resource "equinix_metal_vlan" "vlan3" {
  description = "VLAN in Ashburn"
 metro = "dc"
 project_id = "d0418d98-86af-417a-a50a-331c989ffe63"
vxlan=1008
}
