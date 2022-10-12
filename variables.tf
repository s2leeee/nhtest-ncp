variable "access_key" {}
variable "secret_key" {}

variable "vpc_name" {}
variable "subnet_id" {}


variable "server" {
    type = map(object({
        server_name = string
        os_version = string   // Image Name
        product_code = string
        cpu_count = string
        memory_size = string
        product_type = string
        login_key_name = string
        acg_name    = string
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
