# resource "ncloud_login_key" "loginkey" {
#   key_name = "nh-test-key"
# }

# resource "ncloud_vpc" "test" {
#   ipv4_cidr_block = "10.0.0.0/16"
# }

# vpc portal에서 가져오기
data "ncloud_vpc" "test" {
  name = var.vpc_name
}

# subnet portal에서 가져오기
data "ncloud_subnet" "test" {
  id = var.subnet_id
  vpc_no = data.ncloud_vpc.test.vpc_no
}

# subnet portal에서 가져오기
data "ncloud_access_control_group" "test" {
  for_each = var.server
  name = each.value.acg_name
  vpc_no = data.ncloud_vpc.test.vpc_no
}


# resource "ncloud_subnet" "test" {
#   vpc_no         = ncloud_vpc.test.vpc_no
#   subnet         = cidrsubnet(ncloud_vpc.test.ipv4_cidr_block, 8, 1)
#   zone           = "KR-1"
#   network_acl_no = ncloud_vpc.test.default_network_acl_no
#   subnet_type    = "PUBLIC"
#   usage_type     = "GEN"
# }

# resource "ncloud_server" "server" {
#   subnet_no                 = ncloud_subnet.test.id
#   name                      = "my-tf-server-1"
#   server_image_product_code = "SW.VSVR.OS.LNX64.UBNTU.SVR1604.B050"
#   login_key_name            = ncloud_login_key.loginkey.key_name
# }

data "ncloud_server_image" "server_image" {
  filter {
    name = "product_name"
    values = ["centos-7.3-64"]
  }
}

data "ncloud_server_product" "product" {
  server_image_product_code = data.ncloud_server_image.server_image.id

  filter {
    name = "product_code"
    values = ["HDD"]
    regex = true
  }
  filter {
    name = "cpu_count"
    values = ["2"]
  }
  filter {
    name = "memory_size"
    values = ["4GB"]
  }
  filter {
    name = "product_type"
    values = ["HICPU"]
    /* Server Spec Type  STAND
    STAND
    HICPU
    HIMEM
    */
  }
}

resource "ncloud_server" "server" {
  for_each = var.server
#   vpc_no = data.ncloud_vpc.test.vpc_no
  subnet_no = data.ncloud_subnet.test.id
  name = each.value.server_name
  login_key_name = each.value.login_key_name
  
  server_image_product_code = data.ncloud_server_image.server_image.id //"SPSW0LINUX000139"
  server_product_code = data.ncloud_server_product.product.id

  # server_product_code = "SPSVRSTAND000004"
  # login_key_name            = ncloud_login_key.loginkey.key_name

#     tag_list {
#       tag_key = "samplekey1"
#       tag_value = "samplevalue1"
#     }

#     tag_list {
#       tag_key = "samplekey2"
#       tag_value = "samplevalue2"
#     }
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
  stop_instance_before_detaching = "false"
  # description = "${ncloud_server.server[each.value.server_key] - }"
  depends_on = [ncloud_server.server]
}
