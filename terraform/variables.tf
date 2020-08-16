variable "region" {
  description = "Region to deploy VPC"
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "Existing VPC to use (specify this, if you don't want to create new VPC)"
  default     = ""
}

variable "cidr" {
  description = "The CIDR block for the VPC. Default value is a valid CIDR, but not acceptable by AWS and should be overriden"
  default     = "10.10.0.0/16"
}

variable "subnet_id_primary" {
    description = "Existing Subnet id primary to use"
    default = ""
}

variable "subnet_id_secondary" {
    description = "Existing Subnet id secondary"
    default = ""
}

variable "subnet_id_third" {
    description = "Existing Subnet id third"
    default = ""
}

variable "subnet_id_fourth" {
    description = "Existing Subnet id third"
    default = ""
}

variable "subnet_cidr_primary" {
    description = "The CIDR block for the 1st subnet"
    default = "10.10.101.0/24"
}

variable "subnet_cidr_secondary" {
    description = "The CIDR block for the 2nd subnet"
    default = "10.10.102.0/24"
}

variable "subnet_cidr_third" {
    description = "The CIDR block for the 3rd subnet"
    default = "10.10.103.0/24"
}

variable "subnet_cidr_fourth" {
    description = "The CIDR block for the 3rd subnet"
    default = "10.10.104.0/24"
}

variable "cidr_block_sec_grp_ssh" {
    description = "The CIDR block for the 3rd subnet"
    default = "0.0.0.0/0"
}

variable "cidr_block_sec_grp_https" {
    description = "The CIDR block for the 3rd subnet"
    default = "0.0.0.0/0"
}

variable "cidr_block_sec_grp_http" {
    description = "The CIDR block for the 3rd subnet"
    default = "0.0.0.0/0"
}

variable "cidr_block_sec_grp_webapp" {
    description = "The CIDR block for the 3rd subnet"
    default = "0.0.0.0/0"
}

variable "cidr_block_sec_grp_outbound" {
    description = "The CIDR block for the 3rd subnet"
    default = "0.0.0.0/0"
}

variable "db_master_password" {
    description = "Password for master db in RDS"
    type = string
}

variable "db_master_username" {
    description = "Username for master db in RDS"
    type = string
    default = "rupesh"
}

variable "publicly_accessible" {
    description = "Public accessibility of RDS subnet ip"
    default = false
}


variable "ssh_key_name" {
    description = "SSH key name for ec2"
    default = "my-key"
}

variable "port2" {
    description = "Frontend port"
    default = 8080
}

variable "db_port" {
    description = "DB port"
    default = 5432
}

variable "storage_rds" {
    description = "Allocate storage for RDS"
    default = 8
}

variable "rds_engine" {
    description = "RDS Engine"
    default = "postgres"
}

variable "rds_db" {
    description = "RDS DBname"
    default = "postgres"
}

variable "rds_engine_version" {
    description = "RDS Engine Version"
    default = "9.6.11"
}

variable "rds_instance_class" {
    description = "RDS Instance Class"
    default = "db.t2.micro"
}

variable "rds_instance_name" {
    description = "RDS Instance Name"
    default = "IADRDS"
}

variable "ami_image_name" {
    description = "AMI image name"
    default = "IAD"
}

variable "root_block_device_volume_type" {
    description = "Root Block device Volume type"
    default = "gp2"
}

variable "root_block_device_volume_size" {
    description = "Root Block device Volume size"
    default = 20
}

variable "access_key"{
    description = "access key id"
}

variable "secret_key"{
    description = "secret access key"
}

variable "ami_owner" {
    description = "User that created the ami"
    default = 515171748973
}

variable "ec2_tag_value" {
    description = "EC2 tag value"
    default = "IAD_ec2"
}