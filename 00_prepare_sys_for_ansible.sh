#!/bin/bash

function check_error () {
    [ ! -z "$err" ] && echo -e "Error:\n$err" >&2 && exit 1
}

conf="$(dirname "$0")"/"ansible-nm.conf"
err=''
if [ ! -f "$conf" ]; then
    err+="Config file $conf does not exists\n"
elif [ ! -r "$conf" ]; then
    err+="Config file $conf is not readable\n"
else
    source "$conf"
    if [ -z "$ansible_user" ]; then
        err+="ansible_user must be defined in ${conf}\n"
    elif ! grep -E -q '^[a-z_]([a-z0-9_-]{0,31}|[a-z0-9_-]{0,30}\$)$' <<< "$ansible_user"; then
        err+="ansible_user must be a valid linux username\n"
    fi
fi
[ $EUID -ne 0 ] && err+="This script must be run as root\n"

check_error

if ! id -u "${ansible_user}" &>/dev/null; then
    echo "Creating user ${ansible_user}..."
    adduser "${ansible_user}"
    [ $? -ne 0 ] && err+="Failed to create user ${ansible_user}\n"
fi
check_error

# If your user is not sudoer, add him to sudo group
sudo -l -U "${ansible_user}" | sed '1!d' | grep -q "not allowed"
res=$?
if [ $res -eq 0 ]; then
    echo "Adding user ${ansible_user} to group sudo..."
    usermod -aG sudo "${ansible_user}"
    [ $? -ne 0 ] && err+="Failed to add $ansible_user to group sudo\n"
fi
check_error

kernel_count="$(ls -1 /boot | wc -l)"

echo "Upgrading system..."
apt-get update
apt-get upgrade      -y --fix-missing
apt-get dist-upgrade -y --fix-missing
apt-get -y install python3 python3-venv python3-pip git wget curl vim sshpass

check="$(ls -1 /boot | wc -l)"
if [ $kernel_count -ne $check ]; then
    echo "New kernel has been installed. Rebooting in 10sec. You can CTRL+C to skip reboot"
    sleep 10
    reboot
fi
exit 0
