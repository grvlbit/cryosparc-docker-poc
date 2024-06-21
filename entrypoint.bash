#!/bin/bash -x

function setup_user() {
    if ! id -u "${USERNAME}"; then
        make_user
    fi
}

function make_user() {
    # If EXTERNAL_UID is not set, we just use the standard system generated
    #  UID.
    # If we can get a good value, the UID and GID will both be that.
    local uid="1001"
    if [ -n "${EXTERNAL_UID}" ]; then
      uid=" ${EXTERNAL_UID}"
    fi
    echo adduser ${USERNAME} --disabled-password --home ${USER_HOMEDIR} -N --uid ${uid} \
       --shell ${DEFAULT_SHELL} --gecos "User"
    adduser ${USERNAME} --disabled-password --home ${USER_HOMEDIR} -N --uid ${uid} \
       --shell ${DEFAULT_SHELL} --gecos "User"

    add_groups
    local gentry=""
    local suppgrp=()
    local gid=""
    if [ -n "${EXTERNAL_GROUPS}" ]; then
      for gentry in $(echo ${EXTERNAL_GROUPS} | tr "," "\n"); do
        gname=$(echo ${gentry} | cut -d ':' -f 1)
        if [ -z "${gname}" ]; then
          continue
        fi
        local group_id=$(echo ${gentry} | cut -d ':' -f 1)
        if [ -z "${gid}" ]; then
            gid="${group_id}"
        fi
        supgrp+=("$gname")
      done
    fi
    for g in "${supgrp[@]}"; do
        echo adduser ${USERNAME} $g
        adduser ${USERNAME} $g
    done
}

function add_groups() {
    local gentry=""
    local gname=""
    local gid=""
    if [ -n "${EXTERNAL_GROUPS}" ]; then
        for gentry in $(echo ${EXTERNAL_GROUPS} | tr "," "\n"); do
            gname=$(echo ${gentry} | cut -d ':' -f 1)
            gid=$(echo ${gentry} | cut -d ':' -f 2)
            add_group ${gname} ${gid}
        done
    fi
}

function add_group() {
    # If the group exists already, use that.
    # If it doesn't exist but the group id is in use, use a system-
    #  assigned gid.
    # Otherwise, use the group id to create the group.
    local gname=$1
    local gid=$2
    local exgrp=$(getent group ${gname})
    if [ -n "${exgrp}" ]; then
        return
    fi
    if [ -n "${gid}" ]; then
        local exgid=$(getent group ${gid})
        if [ -n "${exgid}" ]; then
            gid=""
        fi
    fi
    local gopt=""
    if [ -n "${gid}" ]; then
        gopt="-g ${gid}"
    fi
    echo groupadd ${gopt} ${gname}
    groupadd ${gopt} ${gname}
}

# ------------------------------------
# This is where the main script starts
# ------------------------------------

echo "----------------------------------------"
echo "Setting up cryosparc user..."
echo "----------------------------------------"

HOMEDIR=${HOMEDIR:="/home"}
export USER_HOMEDIR="${HOMEDIR}/${USERNAME:-"cryosparc"}"
DEFAULT_SHELL="/bin/bash"

sudo=""
if [ "$(id -u)"  -eq 0 ]; then
    if [ -n "${USERNAME}" ]; then
        setup_user
        sudo="sudo -E -u ${USERNAME} "
    else
        echo 1>&2 "Warning: running as UID 0"
    fi
fi

echo "Show user info..."
id ${USERNAME}


echo "----------------------------------------"
echo "Setting up cryosparc directories..."
echo "----------------------------------------"

# ensure we have a cryosparc directory under home
export CRYOSPARC_DATADIR=${USER_HOMEDIR}/cryosparc
echo "Creating cryosparc datadir ${CRYOSPARC_DATADIR}..."
mkdir -p ${CRYOSPARC_DATADIR}
mkdir -p ${CRYOSPARC_DATADIR}/run
mkdir -p ${CRYOSPARC_DATADIR}/cryosparc_database

if [[ ! -e "${CRYOSPARC_DATADIR}/config.sh" ]]; then
    # copy config
    cp ${CRYOSPARC_MASTER_DIR}/config.sh ${CRYOSPARC_DATADIR}/config.sh
fi

if [[ ! -e "${CRYOSPARC_DATADIR}/worker-config.sh" ]]; then
    # copy
    cp ${CRYOSPARC_WORKER_DIR}/config.sh ${CRYOSPARC_DATADIR}/worker-config.sh
fi

chown -R ${USERNAME} ${CRYOSPARC_DATADIR}

# Force generate links of local copied to the global config files
# Basically overwrting the global config files with the local ones
ln -sf ${CRYOSPARC_DATADIR}/config.sh ${CRYOSPARC_MASTER_DIR}/config.sh
ln -sf ${CRYOSPARC_DATADIR}/worker-config.sh ${CRYOSPARC_WORKER_DIR}/config.sh
ln -sf ${CRYOSPARC_DATADIR}/run ${CRYOSPARC_MASTER_DIR}/run

# stupid thing wants to create temp files within the master dir
chown ${USERNAME} ${CRYOSPARC_MASTER_DIR}/
chown ${USERNAME} ${CRYOSPARC_WORKER_DIR}/

ls -lah ${CRYOSPARC_MASTER_DIR}

echo "----------------------------------------"
echo " Drop privileges and start cryosparc..."
echo "----------------------------------------"
exec ${sudo} /cryosparc.sh
