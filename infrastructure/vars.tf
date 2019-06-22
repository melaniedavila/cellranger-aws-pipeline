variable "environment" {}
variable "cellranger_bcl2fastq_version_pairs" {
  # Don't change this default
  default = [
    {
      cellranger_version = "2.2.0",
      bcl2fastq_version = "2.20.0"
    },
    {
      cellranger_version = "3.0.2",
      bcl2fastq_version = "2.20.0"
    }
  ]
}
