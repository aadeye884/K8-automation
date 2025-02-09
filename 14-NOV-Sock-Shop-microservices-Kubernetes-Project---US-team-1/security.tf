resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow ssh inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "CLUSTER_SG" {
  name        = "CLUSTER_SG"
  description = "Allow TLS Inbound"
  vpc_id      = module.vpc.vpc_id


  ingress {
    description = "allow ssh acess"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    name = "CLUSTER_SG"
  }
}

# resource "aws_security_group" "k8_nodes" {
#   name        = "k8_nodes"
#   description = "sec group for k8 nodes"
#   vpc_id      = module.vpc.vpc_id

#   ingress {
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["${var.vpc_cidr}"]
#   }

#   ingress {
#     from_port   = -1
#     to_port     = -1
#     protocol    = "icmp"
#     cidr_blocks = ["${var.vpc_cidr}"]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

# }
# resource "aws_security_group" "k8_masters" {
#   name        = "k8_masters"
#   description = "sec group for k8 master nodes"
#   vpc_id      = module.vpc.vpc_id

#   ingress {
#     #Kubernetes API server
#     from_port   = 6443
#     to_port     = 6443
#     protocol    = "tcp"
#     cidr_blocks = ["${var.vpc_cidr}"]
#   }

#   ingress {
#     #etcd server client API
#     from_port   = 2379
#     to_port     = 2380
#     protocol    = "tcp"
#     cidr_blocks = ["${var.vpc_cidr}"]
#   }

#   ingress {
#     #Kubelet API
#     from_port   = 10250
#     to_port     = 10250
#     protocol    = "tcp"
#     cidr_blocks = ["${var.vpc_cidr}"]
#   }

#   ingress {
#     #kube-scheduler
#     from_port   = 10259
#     to_port     = 10259
#     protocol    = "tcp"
#     cidr_blocks = ["${var.vpc_cidr}"]
#   }

#   ingress {
#     #kube-controller-manager
#     from_port   = 10257
#     to_port     = 10257
#     protocol    = "tcp"
#     cidr_blocks = ["${var.vpc_cidr}"]
#   }

# }

resource "aws_security_group" "k8_workers" { #   name        = "k8_workers"
  description = "sec group for k8 worker nodes"
  vpc_id      = module.vpc.vpc_id

  ingress {
    #Kubelet API
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  ingress {
    #NodePort Services†
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }
}
#Jenkins SG
resource "aws_security_group" "Jenkins_SG" {
  name        = "Jenkins_SG"
  description = "Allow ssh inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

/* Create Jenkins_lb Security Group */
resource "aws_security_group" "jenkins_lbSG" {
  name        = "jenkins_lbSG"
  description = "Allow TLS inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow http from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow http from VPC"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Jenkins_lbSG"
  }
}