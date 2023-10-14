data "hcloud_ssh_key" "ssh_key" {
  name = var.ssh_key
}

resource "hcloud_server" "web" {
  count       = var.server_count
  image       = var.image
  server_type = var.server_type
  location    = var.location
  name        = format("%s-%03d", var.server_name, count.index + 1)
  ssh_keys    = [data.hcloud_ssh_key.ssh_key.id]
  connection {
    user        = "root"
    host        = hcloud_server.web[count.index].ipv4_address
    private_key = file(var.hcloud_ssh_key_local_path)
  }
}

resource "null_resource" "installansible" {
  count = var.server_count
  connection {
      user = "root"
      host = hcloud_server.web[count.index].ipv4_address
      private_key = file(var.hcloud_ssh_key_local_path)
  }
  provisioner "remote-exec" {
   inline = [
      "sudo apt update -y",
      "sudo apt dist-update -y",
      "sudo apt install software-properties-common -y",
      "sudo apt-add-repository --yes --update ppa:ansible/ansible -y",
      "sudo apt install ansible -y"
    ]
  }
}


resource "local_file" "fileappend" {
  content  = "[hetzner-cloud]\n${join("\n", hcloud_server.web.*.ipv4_address)}"
  filename = format("%s/play-book/ansible-hosts-config", path.root)
}


resource "null_resource" "runansible" {
  count = "1"
  provisioner "local-exec" {
    command = "cd play-book && ansible-playbook -i ansible-hosts-config website.yml --extra-vars 'ssh_port=${var.ssh_port} ssh_user_keyfile_path=${var.ssh_user_keyfile_path}'"
  }
   depends_on = [
    null_resource.installansible,
  ]
}

resource "null_resource" "restartnodes" {
  count = var.server_count
  connection {
      user = "root"
      host = hcloud_server.web[count.index].ipv4_address
      private_key = file(var.hcloud_ssh_key_local_path)
  }
  provisioner "remote-exec" {
   inline = [
      "(sleep 20; echo hi) &"
    ]
  }
  depends_on = [
    null_resource.runansible,
  ]
}


output "ip" {
    value = join(",", hcloud_server.web.*.ipv4_address)
}


output "Done" {
  value = "\n If you did not have printed any errors, then your simple js website is provisioned successfully :) \nDo not forget to delete variables.tf, since it contains sensitive information!"
}
