resource "local_file" "ansible_inventory" {
  content = templatefile("${path.root}/templates/inventry.tftpl",
    {
      masters-dns   = aws_instance.masters.*.private_dns,
      masters-ip    = aws_instance.masters.*.private_ip,
      masters-id    = aws_instance.masters.*.id,
      workers-dns   = aws_instance.workers.*.private_dns,
      workers-ip    = aws_instance.workers.*.private_ip,
      workers-id    = aws_instance.workers.*.id
      clusterlb-dns = aws_instance.clusterlb.*.private_dns,
      clusterlb-ip  = aws_instance.clusterlb.*.private_ip,
      clusterlb-id  = aws_instance.clusterlb.*.id
    }
  )
  filename = "${path.root}/inventory"
}

# waiting for bastion server user data init.
# TODO: Need to switch to signaling based solution instead of waiting. 
resource "time_sleep" "wait_for_ansible_init" {
  depends_on = [aws_instance.ansible]

  create_duration = "120s"

  triggers = {
    "always_run" = timestamp()
  }
}

resource "null_resource" "provisioner" {
  depends_on = [
    local_file.ansible_inventory,
    time_sleep.wait_for_ansible_init,
    aws_instance.ansible
  ]

  triggers = {
    "always_run" = timestamp()
  }

  provisioner "file" {
    source      = "${path.root}/inventory"
    destination = "/home/ubuntu/inventory"

    connection {
      type        = "ssh"
      host        = aws_instance.ansible.public_ip
      user        = var.ssh_user
      private_key = tls_private_key.ssh.private_key_pem
      agent       = false
      insecure    = true
    }
  }
}

resource "local_file" "ansible_vars_file" {
  content  = <<-DOC

        master_ip: ${aws_instance.masters[0].private_ip}
        clusterlb_ip: ${aws_instance.clusterlb.private_ip}
        DOC
  filename = "ansible/ansible_vars_file.yml"
}

resource "null_resource" "copy_ansible_playbooks" {
  depends_on = [
    null_resource.provisioner,
    time_sleep.wait_for_ansible_init,
    aws_instance.ansible,
    local_file.ansible_vars_file
  ]

  triggers = {
    "always_run" = timestamp()
  }

  provisioner "file" {
    source      = "${path.root}/ansible"
    destination = "/home/ubuntu/ansible/"

    connection {
      type        = "ssh"
      host        = aws_instance.ansible.public_ip
      user        = var.ssh_user
      private_key = tls_private_key.ssh.private_key_pem
      insecure    = true
      agent       = false
    }
  }
}

resource "null_resource" "run_ansible" {
  depends_on = [
    null_resource.provisioner,
    null_resource.copy_ansible_playbooks,
    aws_instance.masters,
    aws_instance.workers,
    module.vpc,
    aws_instance.ansible,
    time_sleep.wait_for_ansible_init
  ]

  triggers = {
    always_run = timestamp()
  }

  connection {
    type        = "ssh"
    host        = aws_instance.ansible.public_ip
    user        = var.ssh_user
    private_key = tls_private_key.ssh.private_key_pem
    insecure    = true
    agent       = false
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'starting ansible playbooks...'",
      "sleep 60 && ansible-playbook -i /home/ubuntu/inventory /home/ubuntu/ansible/play.yml ",
    ]
  }
}

resource "null_resource" "run_clusterlb" {
  depends_on = [
    null_resource.provisioner,
    null_resource.copy_ansible_playbooks,
    aws_instance.masters,
    aws_instance.workers,
    module.vpc,
    aws_instance.ansible,
    time_sleep.wait_for_ansible_init,
    null_resource.run_ansible
  ]

  triggers = {
    always_run = timestamp()
  }

  connection {
    type        = "ssh"
    host        = aws_instance.ansible.public_ip
    user        = var.ssh_user
    private_key = tls_private_key.ssh.private_key_pem
    insecure    = true
    agent       = false
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'starting ansible playbooks...'",
      "sleep 60 && ansible-playbook -i /home/ubuntu/inventory /home/ubuntu/ansible/clusterplay.yml ",
    ]
  }
}

resource "null_resource" "run_deployment" {
  depends_on = [
    null_resource.provisioner,
    null_resource.copy_ansible_playbooks,
    aws_instance.masters,
    aws_instance.workers,
    module.vpc,
    aws_instance.ansible,
    time_sleep.wait_for_ansible_init,
    null_resource.run_ansible
    null_resource.run_clusterlb
  ]

  triggers = {
    always_run = timestamp()
  }

  connection {
    type        = "ssh"
    host        = aws_instance.ansible.public_ip
    user        = var.ssh_user
    private_key = tls_private_key.ssh.private_key_pem
    insecure    = true
    agent       = false
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'starting ansible playbooks...'",
      "sleep 60 && ansible-playbook -i /home/ubuntu/inventory /home/ubuntu/ansible/deployment.yml ",
    ]
  }
}