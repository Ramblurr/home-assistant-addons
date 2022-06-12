#!/bin/bash
# shellcheck disable=SC2034
# ------------------------------------------------------------------------------
# Read and print config.
# ------------------------------------------------------------------------------
declare -x BORG_BASE_DIR
declare -x BORG_CACHE_DIR
declare -x BORG_REPO
declare -x BORG_RSH
declare -x BORG_PASSPHRASE
declare _BORG_TOBACKUP
declare _BORG_SSH_KNOWN_HOSTS
declare _BORG_SSH_KEY
declare _BORG_DEBUG
declare _BORG_SSH_PARAMS
declare _BORG_BACKUP_KEEP_SNAPSHOTS
declare _BORG_COMPRESSION
declare TRIGGER_TIME
declare TRIGGER_DAYS
declare BACKUP_NAME

function get_config {
    bashio::config.exists 'log_level' && bashio::log.level "$(bashio::config 'log_level')"

    bashio::config.exists 'backup_name' && BACKUP_NAME=$(bashio::config 'backup_name') || BACKUP_NAME=""

    BORG_BASE_DIR=/config/borg
    export BORG_BASE_DIR
    BORG_CACHE_DIR="${BORG_BASE_DIR}/cache"
    export BORG_CACHE_DIR

    _BORG_TOBACKUP=/backup/borg_unpacked
    _BORG_SSH_KNOWN_HOSTS="${BORG_BASE_DIR}/known_hosts"
    _BORG_SSH_KEY="${BORG_BASE_DIR}/keys/borg_backup"
    _BORG_DEBUG=""
    _BORG_SSH_PARAMS=""

    bashio::config.require "borg_repo_url"
    bashio::config.require "borg_passphrase"

    BORG_PASSPHRASE=$(bashio::config 'borg_passphrase')
    export BORG_PASSPHRASE

    _BORG_REPO_URL=$(bashio::config 'borg_repo_url')
    _BORG_BACKUP_KEEP_SNAPSHOTS="$(bashio::config 'borg_backup_keep_snapshots' 5)"
    _BORG_COMPRESSION=$(bashio::config 'borg_compression' 'zstd')

    if bashio::config.has_value "borg_backup_debug"; then
        _BORG_DEBUG="--debug"
    fi

    BORG_RSH="ssh -o UserKnownHostsFile=${_BORG_SSH_KNOWN_HOSTS} -i ${_BORG_SSH_KEY} ${_BORG_SSH_PARAMS}"
    export BORG_RSH

    _BORG_HOST=$(python3 /usr/bin/split-repourl.py --host "${_BORG_REPO_URL}")
    _BORG_USER=$(python3 /usr/bin/split-repourl.py --user "${_BORG_REPO_URL}")

    if [[ ( ${#_BORG_USER} -gt 0 ) ]];then
        bashio.log.fatal "borg_repo_url is a local path. This is currently unsupported."
        bashio::exit.nok
    fi

    BORG_REPO=${_BORG_REPO_URL}
    export BORG_REPO

    if bashio::config.has_value "borg_ssh_params"; then
        _BORG_SSH_PARAMS="$(bashio::config 'borg_ssh_params')"
    fi

    TRIGGER_TIME=$(bashio::config 'trigger_time')
    TRIGGER_DAYS=$(bashio::config 'trigger_days')

    export __BASHIO_LOG_TIMESTAMP="%y-%m-%d %T"

    bashio::log.info "---------------------------------------------------"
    bashio::log.info "Borg repo: ${_BORG_REPO_URL}"
    bashio::log.info "Borg host: ${_BORG_HOST}"
    bashio::log.info "Borg user: ${_BORG_USER}"
    bashio::log.info "Borg ssh command: ${BORG_RSH}"
    bashio::log.info "Trigger time: ${TRIGGER_TIME}"
    [[ "$TRIGGER_TIME" != "manual" ]] && bashio::log.info "Trigger days: $(echo "$TRIGGER_DAYS" | xargs)"
    bashio::log.info "---------------------------------------------------"
}
