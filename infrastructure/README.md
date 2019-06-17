# Infrastructure

The AWS infrastructure that implements the cellranger pipeline is
managed by us using terraform.

## Prereqs

* Your AWS credentials should be present in `~/.aws/credentials`.

## TODO

* [Setup remote state.](https://www.terraform.io/docs/state/remote.html)

## Common errors

### "Cannot delete, found existing JobQueue relationship"

Run `terraform destroy -target=aws_batch_job_queue.<name>` and then
re-run `terraform apply`.
