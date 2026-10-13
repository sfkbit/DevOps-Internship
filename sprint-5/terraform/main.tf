resource "terraform_data" "migration_test" {
  input = "Sprint 5 state migration test"
}

resource "terraform_data" "lock_test" {
  input = "Temporary state locking demonstration"

  provisioner "local-exec" {
    command = "sleep 30"
  }
}
