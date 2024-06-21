# cryosparc-docker-poc

> [!NOTE]
> This docker image is a proof-of-concept.
> Please handle with care and don't use with production data!

The idea is to create a containerized version of CryoSPARC that can be used in a
HPC system to provide CryoSPARC instances to the users. As most HPC systems
don't expose docker to its users, the image will be run by apptainer instead.

## Prerequisites

To build this container you need a valid license vor CryoSparc.
You may obtain a license for CryoSparc via https://cryosparc.com/download/.

## Container environment variables

Container environment variables can be passed to the container during `docker
run ...` using `-e VARIABLE=value` syntax.

| var | required | description |
| ---- | ------- | ----------- |
| CRYOSPARC_LICENSE_ID | yes | license id to associate with cryosparc instance |
| USERNAME | no | username of cryosparc user inside the container. Should match the local username (default: cryosparc)|
| EXTERNAL_UID | no | UID of cryosparc user inside the container. Should match the local username (default: 1001)|
| EXTERNAL_GROUPS | no | list of groups to add to cryosparc user inside the container. Format: <name>:<gid>,<name2>:<gid2> (default: '')|
| HOMEDIR | no | path to home directories (default: /home/)|
| LSCRATCH | no | path to local scratch directories (default: /tmp/$USER/)|
| MAIL | no | mail address for cryosparc login (default: $USER@localhost)|
| CRYOSPARC_CACHE_DIR | no | directory for cryosparc cache (default: $LSCRATCH/cryosparc)|
| CRYOSPARC_CACHE_QUOTA | no | cryosparc cache directory quota (default: 2500000)|
| CRYOSPARC_CACHE_FREE | no | cryosparc cache directory reserved (default: 5000)|
| CRYOSPARC_WORKER_NOGPU | no | set to true if worker has no GPU (default: 0)|

## Mounting directories

To enable persistent storage and access to data, the following directories
(inside the container) should to be mapped to directories outside the container:

- home dir
- storage to actual research data
- scratch directory

## Running the container

### docker

To run the image directly through docker (for testing) use

    docker run --platform linux/amd64 \
        -e CRYOSPARC_LICENSE_ID=${CRYOSPARC_LICENSE_ID} \
        -e USERNAME=grvlbit -e EXTERNAL_UID=1234 \
        -e EXTERNAL_GROUPS=cryo:1001,micro:902
        -e MAIL=grvlbit@localhost \
        -e CRYOSPARC_WORKER_NOGPU=1 \
        --mount type=bind,source=$(pwd)/cryosparc-data,target=/home/grvlbit/cryosparc \
        -p 39000:39000 grvlbit/cryosparc-docker-poc

### apptainer

First, convert the docker image to sif:

    export APPTAINER_TMPDIR=$SCRATCH
    apptainer build cryosparc-docker-poc.sif docker://grvlbit/cryosparc-docker-poc

Set the license:

    export CRYOSPARC_LICENSE_ID=XXXXXX


## Building

To build the image locally, run
```
export DOCKER_BUILDKIT=1
export CRYOSPARC_LICENSE_ID=XXXXXX
docker build  --platform linux/amd64 --progress=plain --secret id=CRYOSPARC_LICENSE_ID -t cryosparc --load .
```

replacing `XXXXXX` with a valid CryoSparc license ID.

## Contributing

1. Fork it
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Acknowledgements

This work is based on the work of [slaclab/cryosparc-docker](https://github.com/slaclab/cryosparc-docker). Without the people at slaclab this would not exist.
