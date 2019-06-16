#!/usr/bin/env bash

CELLRANGER_BCL2FASTQ_VERSIONS="2.2.0 2.20.0
3.0.2 2.20.0"

main() {
  local make_target cellranger_version bcl2fastq_version

  make_target="${1:-build}"

  while read cellranger_version bcl2fastq_version; do
    CELLRANGER_VERSION="$cellranger_version" BCL2FASTQ_VERSION="$bcl2fastq_version" make "$make_target"
  done <<<"$CELLRANGER_BCL2FASTQ_VERSIONS"
}

main "$@"
