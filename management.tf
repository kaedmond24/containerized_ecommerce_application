#############################################
# Create Jenkins Management infrastrucuture #
#############################################

# >>>>> Configure AWS Provider <<<<< #
provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region     = var.region
}


########################
# Create EC2 Instances #
########################

# >>>>> Jenkins Management Server <<<<< #
resource "aws_instance" "jnk_management_server" {
  ami                         = var.ami
  instance_type               = var.instance_type
  vpc_security_group_ids      = [var.default_security_sg]
  key_name                    = var.key_name
  subnet_id                   = var.default_subnet_id
  associate_public_ip_address = "true"

  user_data = file("jnk_mgr_setup.sh")

  tags = {
    Name : "jenkins_management_server",
    Project : "deployment 8",
    Jenkins : "Manager"
  }

}

# >>>>> Jenkins IaC Server <<<<< #
resource "aws_instance" "jnk_iac_server" {
  ami                         = var.ami
  instance_type               = var.instance_type
  vpc_security_group_ids      = [var.default_security_sg]
  key_name                    = var.key_name
  subnet_id                   = var.default_subnet_id
  associate_public_ip_address = "true"

  user_data = file("jnk_iac_setup.sh")

  tags = {
    Name : "jenkins_iac_server",
    Project : "Deployment 8",
    Jenkins : "Agent"
  }
}

# >>>>> Jenkins Container Server <<<<< #
resource "aws_instance" "jnk_container_server" {
  ami                         = var.ami
  instance_type               = var.instance_type
  vpc_security_group_ids      = [var.default_security_sg]
  key_name                    = var.key_name
  subnet_id                   = var.default_subnet_id
  associate_public_ip_address = "true"

  user_data = file("jnk_container_setup.sh")

  tags = {
    Name : "jenkins_container_server",
    Project : "deployment 8",
    Jenkins : "Agent"
  }
}


##########################
# IP Address Output Data #
##########################

# >>>>> Jenkins Management Server Public IP <<<<< #
output "jnk_management_server_public_ip" {
  value = aws_instance.jnk_management_server.public_ip
}

# >>>>> Jenkins IaC Server Public IP <<<<< #
output "jnk_iac_server_public_ip" {
  value = aws_instance.jnk_iac_server.public_ip
}

# >>>>> Jenkins Container Server Public IP <<<<< #
output "jnk_container_server_public_ip" {
  value = aws_instance.jnk_container_server.public_ip
}






