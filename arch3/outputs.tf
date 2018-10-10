output "elb-dns" {
  value = "${aws_elb.elb-external.dns_name}"
}

output "elb-dns" {
  value = "${aws_elb.elb-internal.dns_name}"
}