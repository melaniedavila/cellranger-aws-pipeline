FROM python:3.6-slim

MAINTAINER MSSM HIMC

ARG CELLRANGER_VERSION
ARG BCL2FASTQ_VERSION

RUN pip3 install --upgrade awscli

# Install bcl2fastq. cellranger mkfastq requires it.
RUN export DEBIAN_FRONTEND=noninteractive \
  && apt-get update \
  && apt-get install -y alien unzip wget \
  && wget https://s3.amazonaws.com/10x-pipeline/software/bcl2fastq/bcl2fastq2-v$BCL2FASTQ_VERSION-linux-x86-64.zip \
  && unzip bcl2fastq2*.zip \
  && alien bcl2fastq2*.rpm \
  && dpkg -i bcl2fastq2*.deb \
  && rm bcl2fastq2*.deb bcl2fastq2*.rpm bcl2fastq2*.zip \
  && apt-get remove -y alien

# don't run containers as root
RUN groupadd -g 999 cellranger \
  && useradd -r -u 999 -g cellranger cellranger \
  && mkdir /home/cellranger \
  && chown -R cellranger:cellranger /home/cellranger

USER cellranger

# Install cellranger
RUN mkdir /home/cellranger/bin \
  && cd /home/cellranger/bin \
  && wget -O - https://s3.amazonaws.com/10x-pipeline/software/cellranger/cellranger-$CELLRANGER_VERSION.tar.gz | tar -xzvf -

# TODO: move this layer up
RUN wget -O /home/cellranger/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.2.2/dumb-init_1.2.2_amd64
RUN chmod +x /home/cellranger//bin/dumb-init

ENV PATH /home/cellranger/bin:/home/cellranger/bin/cellranger-$CELLRANGER_VERSION:$PATH

COPY bin/ /home/cellranger/bin/

WORKDIR /home/cellranger/

ENTRYPOINT ["/home/cellranger/bin/dumb-init"]

CMD ["bash"]
