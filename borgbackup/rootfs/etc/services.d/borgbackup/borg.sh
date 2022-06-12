#!/bin/bash
declare BACKUP_TIME
declare SNAP_SLUG
declare SNAP_NAME

# ------------------------------------------------------------------------------
# Create the backup name by replacing all name patterns.
#
# Returns the final name on stdout
# ------------------------------------------------------------------------------
function generate_backup_name {
    local name
    local theversion
    local thetype
    local thedate

    if [ -n "$BACKUP_NAME" ]; then
        # get all values
        theversion=$(ha core info --raw-json | jq -r .data.version)
        thetype="Full"
        thedate=$(date +'%Y-%m-%d %H:%M')

        # replace the string patterns with the real values
        name="$BACKUP_NAME"
        name=${name/\{version\}/$theversion}
        name=${name/\{type\}/$thetype}
        name=${name/\{date\}/$thedate}
    else
        name="Borg Backup $(date +'%Y-%m-%d %H:%M')"
    fi

    echo "$name"
}

# ------------------------------------------------------------------------------
# Create a new backup (full or partial).
# ------------------------------------------------------------------------------
function create_backup {
    local args

    SNAP_NAME=$(generate_backup_name)

    args=()
    args+=("--name" "$SNAP_NAME")
    [ -n "$BACKUP_PWD" ] && args+=("--password" "$BACKUP_PWD")

    # TODO partial backups, exclusions go here

    # run the command
    bashio::log.info "Creating backup \"${SNAP_NAME}\""
    SNAP_SLUG="$(ha backups new "${args[@]}" --raw-json | jq -r .data.slug)"
}

# shellcheck disable=SC2120
function add_borg_host_to_known_hosts {
    bashio::log.info "Adding borg host to known_hosts"
    if ! bashio::fs.file_exists "${_BORG_SSH_KNOWN_HOSTS}"; then
        bashio::log.info "Adding host ${_BORG_HOST} into ${_BORG_SSH_KNOWN_HOSTS}"
        ssh-keyscan "${_BORG_HOST}" >> "${_BORG_SSH_KNOWN_HOSTS}"
    fi
}


function generate_ssh_key {
    if ! bashio::fs.file_exists "${_BORG_SSH_KEY}"; then
        bashio::log.info "Generating borg backup ssh keys..."
        ssh-keygen -t ed25519 -C "home assistant borg" -N '' -f "${_BORG_SSH_KEY}"
        bashio::log.info "key generated"
    fi
}

function show_ssh_key {
    bashio::log.info "Your ssh key to use for borg backup host"
    bashio::log.info "************ SNIP **********************"
    echo
    cat "${_BORG_SSH_KEY}.pub"
    echo
    bashio::log.info "************ SNIP **********************"
}

function init_borg_repo {
    if ! bashio::fs.directory_exists "${BORG_BASE_DIR}/.config/borg/security"; then
        bashio::log.info "Initializing backup repository..."
        borg init --encryption=repokey-blake2 --debug
        bashio::log.info "Initialized backup repository"
    fi
}

# ------------------------------------------------------------------------------
# Run borg create to move the backups offsite
# ------------------------------------------------------------------------------
function borg_create {
    local tgzdir
    local targz
    local backup_file
    BACKUP_TIME=$(date  +'%Y-%m-%d-%H:%M')
    bashio::log.info "Preparing backup file for borg"

    mkdir -p "${_BORG_TOBACKUP}/${SNAP_SLUG}"
    bashio::log.debug "Created staging dir ${_BORG_TOBACKUP}/${SNAP_SLUG}"
    backup_file="/backup/${SNAP_SLUG}.tar"
    bashio::log.debug "Unpacking HA backup ${backup_file}"
    tar -C "${_BORG_TOBACKUP}/${SNAP_SLUG}" -xf "${backup_file}"
    bashio::log.debug "Unpacking child tarballs"
    for targz in "${_BORG_TOBACKUP}"/"${SNAP_SLUG}"/*.tar.gz ; do
      # shellcheck disable=SC2001
      tgzdir=$(echo "${targz}" | sed -e 's/.tar.gz//g')
      mkdir -p "${tgzdir}"
      tar -C "${tgzdir}" -zxf "${targz}"
      rm -f "${targz}" # remove compressed file
      bashio::log.debug "Removed "
    done

    bashio::log.info "Running borg create"
    borg create "${_BORG_DEBUG}" --compression "${_BORG_COMPRESSION}" --stats ::"${BACKUP_TIME}" "${_BORG_TOBACKUP}/${SNAP_SLUG}"
    bashio::log.info "End borg create --stats..."
    # cleanup
    rm -rf  "${_BORG_TOBACKUP}" /tmp/borg_backup_$$

}

function clean_old_snapshots {
    local all_snaps
    local discard_snaps
    local snap
    local slug
    ha snapshots reload
    all_snaps=$(ha backups --raw-json|jq '.data.backups[].name' -r| sort | wc -l)
    discard_snaps=$((all_snaps - _BORG_BACKUP_KEEP_SNAPSHOTS))
    all_snaps=$(ha backups --raw-json|jq '.data.backups[].name' -r| sort | head -n ${discard_snaps})
    for snap in $all_snaps ; do
        slug=$(ha backups --raw-json |jq -r '.data.backups[]|select (.name=="'"${snap}"'")|.slug')
        bashio::log.info "Removing backup ${snap}: ${slug}"
        ha backups remove "${slug}"
        bashio::log.info "Removed backup ${snap}: ${slug}"
    done
    bashio::log.info "Cleanup of old backups done"
}
