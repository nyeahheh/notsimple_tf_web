

#----------------------------------------------------------
# ACS730 - Mid Term Exam
#
#
#----------------------------------------------------------

# Data source for AMI id
data "aws_ami" "latest_amazon_linux" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "my_amazon" {
  ami                         = data.aws_ami.latest_amazon_linux.id
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.web_key.id
  subnet_id                   = aws_subnet.public_subnet_2.id
  security_groups             = [aws_security_group.web_sg.id]
  associate_public_ip_address = true
  user_data                   = file("${path.module}/install_httpd.sh")

  lifecycle {
    create_before_destroy = true
  }


  tags = {
    Name  = "brokenMidterm"
    Owner = "Cranky Neil"
  }
}

# Attach EBS volume
resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.web_ebs.id
  instance_id = aws_instance.my_amazon.id
}



# Adding SSH key to Amazon EC2
resource "aws_key_pair" "web_key" {
  key_name   = "midterm.pub"
  public_key = file("midterm.pub")
}

# Variable to signal the current environment 
variable "env" {
  default     = "midterm"
  type        = string
  description = "Deployment Environment"
}

variable "prefix" {
  type        = string
  default     = "midterm"
  description = "Name prefix"
}

variable "default_tags" {
  default = {
    "Owner" = "Niall",
    "App"   = "Web"
  }
  type        = map(any)
  description = "Default tags to be applied to all AWS resources"
}


# Create another EBS volume
resource "aws_ebs_volume" "web_ebs" {
  availability_zone = data.aws_availability_zones.available.names[1]
  size              = 40
}


# Elastic IP
resource "aws_eip" "static_eip" {
  instance = aws_instance.my_amazon.id
  tags = merge(var.default_tags,
    {
      "Name" = "midterm-eip"
    }
  )
}
