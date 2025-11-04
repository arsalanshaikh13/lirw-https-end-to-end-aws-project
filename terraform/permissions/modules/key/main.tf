resource "aws_key_pair" "client_key" {
    key_name = "client_key"
    public_key = file("./modules/key/client_key.pub")
}
resource "aws_key_pair" "server_key" {
    key_name = "server_key"
    public_key = file("./modules/key/server_key.pub")
}

resource "aws_key_pair" "nat-bastion" {
  key_name   = "nat-bastion-key"
  public_key = file("./modules/key/nat-bastion.pub")
}