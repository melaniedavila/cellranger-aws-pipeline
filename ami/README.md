# Cellranger Pipeline AWS AMI

The Cellranger Pipeline has been designed to work with 1 TB of disk
space, as recommended by [10x Genomics][10x Genomics]. The 1 TB of
disk space is provided by the Cellranger Pipeline's AMI.

## Building a new AMI

Generally, if the current AMI works then there isn't much reason to
create a new one. Reasons for creating a new AMI might be:

* A job requires more than 1 TB of disk space.
* We need to apply a critical security update.
* We need to use a more up-to-date source AMI.

If you're sure you need to create a new AMI, you'll first need to
install [the Packer CLI](https://www.packer.io/downloads.html) (we
used Packer v1.4.1), which is the tool we use to automate our AMI
builds. After that, you can run `make ami` from the root of this
repo. After building the AMI, you'll need to configure the Batch
Compute Environment to use the new AMI.

[10x Genomics](https://support.10xgenomics.com/single-cell-gene-expression/software/overview/system-requirements)
