output "assets_bucket" {
  value = aws_s3_bucket.assets
}

output "logs_bucket" {
  value = aws_s3_bucket.logs
}

output "root_object_key" {
  value = aws_s3_object.root_object.key
}

output "empty_map_tile_object_key" {
  value = aws_s3_object.empty_map_tile.key
}
