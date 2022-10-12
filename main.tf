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
  subnet_no = data.ncloud_subnet.test.id
  name = each.value.server_name
  login_key_name = each.value.login_key_name
  
  server_image_product_code = data.ncloud_server_image.server_image[each.key].id
  server_product_code = data.ncloud_server_product.product[each.key].id
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
