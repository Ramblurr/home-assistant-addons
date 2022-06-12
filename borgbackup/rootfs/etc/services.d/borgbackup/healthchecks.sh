#!/bin/bash

function hc_start {
    if bashio::config.has_value "borg_healthchecks_url"; then
        curl -fsS --retry 5 -o /dev/null "$(bashio::config 'borg_healthchecks_url')/start"
    fi
}

function hc_fail {
    if bashio::config.has_value "borg_healthchecks_url"; then
        curl -fsS --retry 5 -o /dev/null "$(bashio::config 'borg_healthchecks_url')/fail"
    fi
}

function hc_finish {
    if bashio::config.has_value "borg_healthchecks_url"; then
        curl -fsS --retry 5 -o /dev/null "$(bashio::config 'borg_healthchecks_url')"
    fi
}
