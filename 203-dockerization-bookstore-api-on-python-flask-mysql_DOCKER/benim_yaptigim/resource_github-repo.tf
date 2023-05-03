resource "github_repository" "bookstore-repo" {
  name        = "bookstore-project"
  description = "this repo includes docker files and belongs to arrow"
  auto_init   = true
  visibility  = "private"
}


resource "github_branch_default" "main" {
  branch     = "main"
  repository = github_repository.bookstore-repo.name
}


resource "github_repository_file" "compose" {
  repository          = github_repository.bookstore-repo.name
  branch              = "main"
  for_each            = toset(var.docker-files)
  file                = each.value
  content             = file(each.value)
  commit_message      = "bookstore repo was created and files were added."
  overwrite_on_create = true
}
