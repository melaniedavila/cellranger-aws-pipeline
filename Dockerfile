# SOFTWARE VERSIONS:
# bcl2fastq: 2.20.0
# cellranger: 2.2.0

FROM python:3.6

MAINTAINER MSSM HIMC

RUN pip3 install --upgrade \
  awscli
  pyyaml

# Install bcl2fastq. cellranger mkfastq requires it.
RUN export DEBIAN_FRONTEND=noninteractive \
  && apt-get update \
  && apt-get install -y alien unzip wget \
  && wget https://s3.amazonaws.com/10x-pipeline/software/bcl2fastq/bcl2fastq2-v2.20.0-linux-x86-64.zip \
  && unzip bcl2fastq2*.zip \
  && alien bcl2fastq2*.rpm \
  && dpkg -i bcl2fastq2*.deb \
  && rm bcl2fastq2*.deb bcl2fastq2*.rpm bcl2fastq2*.zip \
  && apt-get remove -y alien

# Install cellranger
RUN wget https://s3.amazonaws.com/10x-pipeline/software/cellranger/cellranger-2.2.0.tar.gz \
  && mv cellranger-2.2.0.tar.gz /opt/ \
  && cd /opt/ \
  && tar -xzvf cellranger-2.2.0.tar.gz \
  && rm -f cellranger-2.2.0.tar.gz

# path
ENV PATH /opt/cellranger-2.2.0:$PATH

RUN groupadd -g 999 user && \
    useradd -r -u 999 -g user user
USER user

# We add an entrypoint in order to avoid entering a python REPL upon running the docker image.
ENTRYPOINT ["echo", "hello"]
