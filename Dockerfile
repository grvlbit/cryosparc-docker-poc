# Adapted from https://github.com/slaclab/cryosparc-docker/blob/master/Dockerfile
# and https://github.com/unlhcc/docker-cryosparc/blob/master/Dockerfile

FROM ubuntu:jammy

RUN apt-get update && \
    apt-get -y install iputils-ping curl ed jq sudo

ENV CRYOSPARC_ROOT_DIR /opt/cryosparc
RUN mkdir -p ${CRYOSPARC_ROOT_DIR}
WORKDIR ${CRYOSPARC_ROOT_DIR}

ARG CRYOSPARC_VERSION=4.5.1
ENV CRYOSPARC_FORCE_USER=true

# install master
ENV CRYOSPARC_MASTER_DIR ${CRYOSPARC_ROOT_DIR}/cryosparc_master

# install with local tarball
COPY master-v${CRYOSPARC_VERSION}.tar.gz .
RUN --mount=type=secret,id=CRYOSPARC_LICENSE_ID\
  tar -xzf master-v${CRYOSPARC_VERSION}.tar.gz \
        && cd ${CRYOSPARC_MASTER_DIR} \
  && bash ./install.sh --license "$(cat /run/secrets/CRYOSPARC_LICENSE_ID)" --yes --allowroot \
  && sed -i 's/^export CRYOSPARC_LICENSE_ID=.*$/export CRYOSPARC_LICENSE_ID=TBD/g' ${CRYOSPARC_MASTER_DIR}/config.sh

# or install with remote download
#RUN --mount=type=secret,id=CRYOSPARC_LICENSE_ID\
#  curl -L https://get.cryosparc.com/download/master-v${CRYOSPARC_VERSION}/$(cat /run/secrets/CRYOSPARC_LICENSE_ID) | tar -xz \
#        && cd ${CRYOSPARC_MASTER_DIR} \
#  && bash ./install.sh --license "$(cat /run/secrets/CRYOSPARC_LICENSE_ID)" --yes --allowroot \
#  && sed -i 's/^export CRYOSPARC_LICENSE_ID=.*$/export CRYOSPARC_LICENSE_ID=TBD/g' ${CRYOSPARC_MASTER_DIR}/config.sh

# install worker
ENV CRYOSPARC_WORKER_DIR ${CRYOSPARC_ROOT_DIR}/cryosparc_worker

# install with local tarball
COPY worker-v${CRYOSPARC_VERSION}.tar.gz .
RUN --mount=type=secret,id=CRYOSPARC_LICENSE_ID\
  tar -xzf worker-v${CRYOSPARC_VERSION}.tar.gz \
  && cd ${CRYOSPARC_WORKER_DIR} \
  && bash ./install.sh --license "$(cat /run/secrets/CRYOSPARC_LICENSE_ID)" --yes --standalone \
  && sed -i 's/^export CRYOSPARC_LICENSE_ID=.*$/export CRYOSPARC_LICENSE_ID=TBD/g' ${CRYOSPARC_WORKER_DIR}/config.sh 

# or install with remote download
#RUN --mount=type=secret,id=CRYOSPARC_LICENSE_ID\
#  curl -L https://get.cryosparc.com/download/worker-v${CRYOSPARC_VERSION}/$(cat /run/secrets/CRYOSPARC_LICENSE_ID) | tar -xz \
#  && cd ${CRYOSPARC_WORKER_DIR} \
#  && bash ./install.sh --license "$(cat /run/secrets/CRYOSPARC_LICENSE_ID)" --yes --standalone \
#  && sed -i 's/^export CRYOSPARC_LICENSE_ID=.*$/export CRYOSPARC_LICENSE_ID=TBD/g' ${CRYOSPARC_WORKER_DIR}/config.sh 

ENV PATH=/opt/cryosparc/cryosparc_master/bin:/opt/cryosparc/cryosparc_worker/bin:$PATH

COPY entrypoint.bash /entrypoint.bash
COPY cryosparc.sh /cryosparc.sh

EXPOSE 39000

ENTRYPOINT /entrypoint.bash
