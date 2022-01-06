variable "instance_count" {
  default = "2"
  description = "The number of EC2 instances to create"
  nullable = false
}

variable "instance_type" {
  default = "m5.2xlarge"
  description = "The type of EC2 instances to create"
  nullable = false
}

variable "root_volume_gb" {
  default = "300"
  description = "The size, in GB, of the EC2 instance root volume"
  nullable = false
}

variable "efs_mount" {
  default = "/efs"
  description = "The full directory name of the EFS mount point"
  nullable = false
}

variable "security_group" {
  description = "The Security Group to use when creating AWS objects"
  nullable = false
}

variable "us_east_1b_subnet" {
  description = "The AWS subnet id for the us-east-1b subnet"
  nullable = false
}

variable "us_east_1e_subnet" {
  description = "The AWS subnet id for the us-east-1e subnet"
  nullable = false
}

variable "route53_zone" {
  description = "The name of the Route53 zone in which to create DNS addresses"
  nullable = false
}

variable "ami_owner" {
  description = "The id of the AMI owner"
  nullable = false
}

variable "ami_name_pattern" {
  description = "The pattern of the name of the AMI to use"
  nullable = false
}

variable "authorized_ssh_keys" {
  description = "List of SSH keys for the developers that will log into the cluster"
  type = list(string)
  nullable = false
}

variable "zookeeper_dir" {
  default = "/data/zookeeper"
  description = "The ZooKeeper directory on each EC2 node"
  nullable = false
}

variable "hadoop_dir" {
  default = "/data/hadoop"
  description = "The Hadoop directory on each EC2 node"
  nullable = false
}

variable "accumulo_dir" {
  default = "/data/accumulo"
  description = "The Accumulo directory on each EC2 node"
  nullable = false
}

variable "maven_version" {
  default = "3.8.4"
  description = "The version of Maven to download and install"
  nullable = false
}

variable "zookeeper_version" {
  default = "3.5.9"
  description = "The version of ZooKeeper to download and install"
  nullable = false
}

variable "hadoop_version" {
  default = "3.3.1"
  description = "The version of Hadoop to download and install"
  nullable = false
}

variable "accumulo_version" {
  default = "2.1.0-SNAPSHOT"
  description = "The branch of Accumulo to download and install"
  nullable = false
}

variable "accumulo_repo" {
  default = "https://github.com/apache/accumulo.git"
  description = "URL of the Accumulo git repo"
  nullable = false
}

variable "accumulo_branch_name" {
  default = "main"
  description = "The name of the branch to build and install"
  nullable = false
}

variable "accumulo_testing_repo" {
  default = "https://github.com/apache/accumulo-testing.git"
  description = "URL of the Accumulo Testing git repo"
  nullable = false
}

variable "accumulo_testing_branch_name" {
  default = "main"
  description = "The name of the branch to build and install"
  nullable = false
}

variable "local_sources_dir" {
  default = ""
  description = "Directory on local machine that contains Maven, ZooKeeper or Hadoop binary distributions or Accumulo source tarball"
  nullable = true
}
