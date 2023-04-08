#!/bin/bash

if [ -z "$1" ]; then
    echo "Please give the Ansible version you want in parameter" >&2
    echo "Example:"   >&2
    echo "    $0 2.10" >&2
    exit 1
fi

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
    [ -z "$ansible_install_dir" ] && err+="ansible_install_dir must be defined in ${conf}\n"
fi
check_error

if [ ! -d "$ansible_install_dir" ]; then
    mkdir "$ansible_install_dir"
    [ $? -ne 0 ] && err+="Failed to created '${ansible_install_dir}'\n"
elif [ ! -w "$ansible_install_dir" ]; then
    err+="'$ansible_install_dir' exists but cannot be written\n"
fi
check_error

ansible_version="${1}"
ansible_dir="${ansible_install_dir}"/"${ansible_version}"

###############################################

# Check if a ssh key is present. If not, create one
t=$(ls -1 "$HOME"/.ssh/id_* 2>/dev/null | wc -l 2>/dev/null)
if [ $t -eq 0 ]; then
    echo -ne "No ssh key found in $HOME/.ssh/. Creating one...\n"
    [ ! -d "$HOME"/.ssh ] && mkdir -p "$HOME"/.ssh
    # If in non-interactive mode, do not prompt for passphrase and generate clear text private key
    if grep i <<<"$-"; then
        ssh-keygen -t rsa -b 4096
    else
        ssh-keygen -t rsa -b 4096 -N "" -f "$HOME"/.ssh/id_rsa
    fi
else
    echo "Found ssh key(s) in $HOME/.ssh/. Skipping creation"
fi

if [ -e "${ansible_dir}" ]; then
    echo "Ansible version ${ansible_version} seems to be already installed in ${ansible_dir}, skipping"
else
    echo "Creating venv..."
    python3 -m venv "${ansible_dir}"
    ret=$?
    [ $ret -ne 0 ] && echo "Failed to create venv" >&2 && exit $ret
fi

_python="${ansible_dir}"/bin/python

echo "Upgrading pip..."
"$_python" -m pip install --upgrade pip

reqs="$(dirname "$0")"/"requirements.txt"
echo "Installing ansible ${ansible_version} and extra packages..."
"$_python" -m pip install wheel
"$_python" -m pip install ansible=="${ansible_version}"

[ -r "$reqs" ] && "$_python" -m pip install -r "$reqs"

if ! grep -q -E "^source ${ansible_install_dir}/[^/]+/bin/activate" "${HOME}/.bashrc"; then
    # If we don't already source any ansible venv, add this one to bashrc
    echo "source ${ansible_dir}/bin/activate" >> "${HOME}/.bashrc"
else
    # If another ansible version was already sourced, replace it
    sed -i -e "s%source ${ansible_install_dir}/[^/]\+/bin/activate%source ${ansible_dir}/bin/activate%" "${HOME}/.bashrc"
fi
echo -e "\nYou will want to activate ansible venv before going further! Run the following:\n"
echo -e "  source ${ansible_dir}/bin/activate\n"
exit 0
