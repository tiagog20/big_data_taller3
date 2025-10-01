terraform {
  backend "s3" {
    bucket = "miprimeracana"                  # nombre del bucket (sin el arn:aws:s3:::)
    key    = "ec2-pandas/terraform.tfstate"   # la ruta interna donde guardar el estado
    region = "us-east-1"                      # ajusta si tu bucket está en otra región
  }
}
