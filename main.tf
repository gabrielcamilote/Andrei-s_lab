terraform {
  required_providers {
    equinix = {
      source  = "equinix/equinix"
     }
  }
}
 # Configuration options
  # Credentials for only Equinix Metal resources
provider "equinix" {
  auth_token = ""
  client_id = ""
  client_secret = ""

}
# Create a new VLAN in metro "da"
resource "equinix_metal_vlan" "vlandallas" {
  description = "VLAN in Dallas"
  metro       = "da"
  project_id  = "d0418d98-86af-417a-a50a-331c989ffe63"
  vxlan       = 2007
}

# Create a new server in metro "da"
resource "equinix_metal_device" "test" {
  hostname         = "CamiloteDallas"
  plan             = "c3.small.x86"
  metro            = "da"
  operating_system = "ubuntu_20_04"
  billing_cycle    = "hourly"
  project_id       = "d0418d98-86af-417a-a50a-331c989ffe63"
  user_data = format("#!/bin/bash\napt update\napt install vlan\nmodprobe 8021q\necho '8021q' >> /etc/modules-load.d/networking.conf\nip link add link bond0 name bond0.%g type vlan id %g\nip addr add 192.168.100.1/24 brd 192.168.100.255 dev bond0.%g\nip link set dev bond0.%g up", equinix_metal_vlan.vlandallas.vxlan, equinix_metal_vlan.vlandallas.vxlan, equinix_metal_vlan.vlandallas.vxlan, equinix_metal_vlan.vlandallas.vxlan)
}

resource "equinix_metal_port_vlan_attachment" "test" {
  device_id = equinix_metal_device.test.id
  port_name = "bond0"
  vlan_vnid = equinix_metal_vlan.vlandallas.vxlan
}

# Create a new VLAN in metro "dc"
resource "equinix_metal_vlan" "vlanwdc" {
  description = "VLAN in Virginia"
  metro       = "dc"
  project_id  = "d0418d98-86af-417a-a50a-331c989ffe63"
  vxlan       = 2007
}

# Create a new Server in metro "dc"
resource "equinix_metal_device" "test2" {
  hostname         = "CamiloteWDC"
  plan             = "c3.small.x86"
  metro            = "dc"
  operating_system = "ubuntu_20_04"
  billing_cycle    = "hourly"
  project_id       = "d0418d98-86af-417a-a50a-331c989ffe63"
  user_data = format("#!/bin/bash\napt update\napt install vlan\nmodprobe 8021q\necho '8021q' >> /etc/modules-load.d/networking.conf\nip link add link bond0 name bond0.%g type vlan id %g\nip addr add 192.168.100.2/24 brd 192.168.100.255 dev bond0.%g\nip link set dev bond0.%g up", equinix_metal_vlan.vlanwdc.vxlan, equinix_metal_vlan.vlanwdc.vxlan, equinix_metal_vlan.vlanwdc.vxlan,equinix_metal_vlan.vlanwdc.vxlan)
}

resource "equinix_metal_port_vlan_attachment" "test2" {
  device_id = equinix_metal_device.test2.id
  port_name = "bond0"
  vlan_vnid = equinix_metal_vlan.vlanwdc.vxlan
}

## Create VC via dedicated port in metro "da"
/* this is the "Interconnection ID" of the "DA-Metal-to-Fabric-Dedicated-Redundant-Port" via Metal's portal*/
data "equinix_metal_connection" "metal_port" {
  connection_id = "8b255653-4128-4101-ac3b-1e6fabf01341"
}

resource "equinix_metal_virtual_circuit" "metalda_vc" {
  connection_id = "8b255653-4128-4101-ac3b-1e6fabf01341"
  project_id    = "d0418d98-86af-417a-a50a-331c989ffe63"
  port_id       = data.equinix_metal_connection.metal_port.ports[0].id
  vlan_id       = equinix_metal_vlan.vlandallas.vxlan
  nni_vlan      = equinix_metal_vlan.vlandallas.vxlan
  name          = "Camilote-tf-vc"
}
## Request a Metal connection and get a z-side token from Metal
resource "equinix_metal_connection" "example" {
  name               = "Camilote-tf-metal-port"
  project_id         = "d0418d98-86af-417a-a50a-331c989ffe63"
  type               = "shared"
  redundancy         = "primary"
  metro         = "dc"
  speed              = "10Gbps"
  service_token_type = "z_side"
  contact_email      = "gcamilote@equinix.com"
  vlans              = [equinix_metal_vlan.vlanwdc.vxlan]
}

## Use the token from "equinix_metal_connectio.example" to setup VC in fabric portal:
 /* A-side port is  your Metal owned dedicated port in Equinix Fabric portal */

resource "equinix_fabric_connection" "vcvc" {
  name = "vc-metalport-fabric"
  type = "EVPL_VC"
  bandwidth = 50
  notifications {
    type   = "ALL"
    emails = ["gcamilote@equinix.com"]
  }
  order {
    purchase_order_number = ""
  }
  a_side {
    access_point {
      type = "COLO"
      port {
        uuid = "cda2f88f-4ff4-ff45-f2e0-320a5c00a3ed"
      }
      link_protocol {
        type     = "DOT1Q"
        vlan_tag = equinix_metal_vlan.vlandallas.vxlan
      }
      location {
        metro_code  = "da"
      }
    }
  }
  z_side {
   service_token {
      uuid = equinix_metal_connection.example.service_tokens.0.id
    }
  }
}
