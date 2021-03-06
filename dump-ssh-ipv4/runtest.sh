#!/usr/bin/env bash

# Copyright (c) 2016 Red Hat, Inc. All rights reserved.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Author: Song Qihan<qsong@redhat.com>
# Update: Qiao Zhao <qzhao@redhat.com>

# Source necessary library
. ../lib/kdump.sh
. ../lib/crash.sh
. ../lib/log.sh

# This is a muli-host tests has to be ran on both Server/Client.
ssh_sysrq_test()
{
    if [ -z "${SERVERS}" -o -z "${CLIENTS}" ]; then
        log_error "No Server or Client hostname"
    fi

    export SERVERS=${SERVERS}
    export CLIENTS=${CLIENTS}

    # port used for client/server sync
    local done_sync_port
    done_sync_port=35413

    if [[ ! -f "${C_REBOOT}" ]]; then
        kdump_prepare
        prepare_for_multihost
        config_ssh

        if [[ $(get_role) == "client" ]]; then
            kdump_restart
            report_system_info

            trigger_sysrq_crash

            log_info "- Notifying server that test is done at client."
            send_notify_signal "${SERVERS}" ${done_sync_port}
            log_error "- Failed to trigger crash."
        fi
        if [[ $(get_role) == "server" ]]; then
            log_info "- Waiting for signal at ${done_sync_port} from client that test is done at client."
            wait_for_signal ${done_sync_port}

            log_info "- Checking vmcore on ssh server."
            validate_vmcore_exists  flat
        fi
    else
        rm -f "${C_REBOOT}"

        log_info "- Sending signal server that crash is done at client."
        send_notify_signal "${SERVERS}" ${done_sync_port}
        log_info "- Client is rebooted back to 1st kernel successfully."
    fi
    ready_to_exit
}

log_info "- Start"
ssh_sysrq_test "$@"
