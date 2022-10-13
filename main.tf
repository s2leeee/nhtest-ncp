# resource "ncloud_login_key" "loginkey" {
#   key_name = "nh-test-key"
# }

# resource "ncloud_vpc" "test" {
#   ipv4_cidr_block = "10.0.0.0/16"
# }

# vpc portal에서 가져오기
data "ncloud_vpc" "test" {
  count = var.is_portal_vpc == false ? 0 : 1
  name = var.vpc_name
}

resource "ncloud_vpc" "vpc" {
  count = var.is_portal_vpc == false ? 1 : 0
  name = var.vpc_new_name
  ipv4_cidr_block = var.vpc_ipv4_cidr_block
}

# resource "ncloud_network_acl" "nacl" {
#   count = var.is_portal_vpc == false ? 1 : 0
#   vpc_no = ncloud_vpc.vpc[0].id
#   name = var.network_acl_name
#   //description  = 
# }

# subnet portal에서 가져오기
data "ncloud_subnet" "test" {
  count = var.is_portal_subnet == false ? 0 : 1
  id = var.subnet_id
  vpc_no = data.ncloud_vpc.test[0].vpc_no
}

resource "ncloud_subnet" "subnet" {
  count = var.is_portal_subnet == false ? 1 : 0
  vpc_no = ncloud_vpc.vpc[0].id
  subnet = var.subnet
  zone = var.zone
  network_acl_no = var.is_portal_vpc == false ? ncloud_vpc.vpc[0].default_network_acl_no : data.ncloud_vpc.test[0].default_network_acl_no
  subnet_type = var.subnet_type // PUBLIC(Public) | PRIVATE(Private)
  name = var.subnet_name
  usage_type = var.subnet_usage_type               // GEN(General) | LOADB(For load balancer)
}


# acg portal에서 가져오기
data "ncloud_access_control_group" "test" {
  //for_each = var.server
  count = var.is_portal_acg == false ? 0 : 1
  name = var.acg_name //each.value.acg_name
  vpc_no = var.is_portal_vpc == false ? ncloud_vpc.vpc[0].vpc_no : data.ncloud_vpc.test[0].vpc_no
}

resource "ncloud_access_control_group" "acg" {
  count = var.is_portal_acg == false ? 1 : 0
  name = var.acg_new_name
  vpc_no = var.is_portal_vpc == false ? ncloud_vpc.vpc[0].id : data.ncloud_vpc.test[0].id
}

resource "ncloud_access_control_group_rule" "acg-rule" {
  count = var.is_portal_acg == false ? 1 : 0
  access_control_group_no = ncloud_access_control_group.acg[0].id

  dynamic "inbound" {
    for_each = var.acg_inbound_rule
    content {
      protocol    = inbound.value.protocol       // TCP | UDP | ICMP
      ip_block    = inbound.value.ip_block
      port_range  = inbound.value.port_range
      //description = each.value.description
    }
  }
  dynamic "outbound" {
    for_each = var.acg_outbound_rule
    content {
      protocol    = outbound.value.protocol
      ip_block    = outbound.value.ip_block
      port_range  = outbound.value.port_range
      //description = each.value.description
    }
  }
}

resource "ncloud_network_interface" "nic" {
    for_each = var.server
    name = "${each.value.server_name}-nic"
    subnet_no = var.is_portal_subnet == false ? ncloud_subnet.subnet[0].id :  data.ncloud_subnet.test[0].id
    access_control_groups = var.is_portal_acg == false ?  [ncloud_vpc.vpc[0].default_access_control_group_no, ncloud_access_control_group.acg[0].id] : [data.ncloud_access_control_group.test[0].id]
}

data "ncloud_server_image" "server_image" {
  for_each = var.server
  filter {
    name = "product_name"
    values = [each.value.os_version]
  }
}

data "ncloud_server_product" "product" {
  for_each = var.server
  server_image_product_code = data.ncloud_server_image.server_image[each.key].id

  filter {
    name = "product_code"
    values = [each.value.product_code]
    regex = true
  }
  filter {
    name = "cpu_count"
    values = [each.value.cpu_count]
  }
  filter {
    name = "memory_size"
    values = [each.value.memory_size]
  }
  filter {
    name = "product_type"
    values = [each.value.product_type]
    /* Server Spec Type
    STAND
    HICPU
    HIMEM
    */
  }
}

resource "ncloud_server" "server" {
  for_each = var.server
  # vpc_no = data.ncloud_vpc.test.vpc_no
  subnet_no = var.is_portal_subnet == false ? ncloud_subnet.subnet[0].id :  data.ncloud_subnet.test[0].id
  name = each.value.server_name
  login_key_name = each.value.login_key_name
  
  server_image_product_code = data.ncloud_server_image.server_image[each.key].id
  server_product_code = data.ncloud_server_product.product[each.key].id
  
  network_interface {
    network_interface_no = ncloud_network_interface.nic[each.key].id
    order = 0
  }
  # server_image_product_code = "SPSW0LINUX000139"
  # server_product_code = "SPSVRSTAND000004"
}

resource "ncloud_public_ip" "public_ip" {
  for_each = var.server
  server_instance_no = ncloud_server.server[each.key].id
  depends_on = [ncloud_server.server]
}

resource "ncloud_block_storage" "storage" {
  for_each = var.server_storage
  server_instance_no = ncloud_server.server[each.value.server_key].id
  name = each.value.storage_name
  size = each.value.disk_size
  stop_instance_before_detaching = "true"	
  # description = "${ncloud_server.server[each.value.server_key] - }"
  depends_on = [ncloud_server.server]
}
