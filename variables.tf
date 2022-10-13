variable "access_key" {}
variable "secret_key" {}

variable "vpc_name" {}
variable "subnet_id" {}

variable "acg_name" {}

variable "server" {
    type = map(object({
        server_name = string
        os_version = string   // Image Name
        product_code = string
        cpu_count = string
        memory_size = string
        product_type = string
        login_key_name = string
        //acg_name    = string
        //server_image_product_code = string
    }))
}

variable "server_storage" {
    type = map(object({
        server_key = string     // server 인스턴스 key
        storage_name = string
        disk_type = string      // SSD | HDD
        disk_size = string      // "10"
    }))
}


// 내용 추가
variable "is_portal_vpc" {
    type = bool
}
variable "is_portal_subnet" {
    type = bool
}
variable "is_portal_acg" {
    type = bool
}

// vpc, network_acl 생성
variable "vpc_new_name" {}
variable "vpc_ipv4_cidr_block" {}
# variable "network_acl_name" {}

// subnet 생성
variable "subnet" {}
variable "zone" {}
variable "subnet_type" {}
variable "subnet_name" {}
variable "subnet_usage_type" {}

// acg 생성
variable "acg_new_name" {}          // variable "server" -> acg_name 주석처리


# variable "acg_inbound_rule"{
#     type = map(object({
#         protocol = string
#         ip_block = string
#         port_range = string
#     }))
# }
# variable "acg_outbound_rule"{
#     type = map(object({
#         protocol = string
#         ip_block = string
#         port_range = string
#     }))
# }

variable "acg_inbound_rule"{
    type = list(object({
        protocol = string
        ip_block = string
        port_range = string
    }))
}
variable "acg_outbound_rule"{
    type = list(object({
        protocol = string
        ip_block = string
        port_range = string
    }))
}

