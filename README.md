# Setup Ansible Node Manager
Setup scripts for Ansible Node Manager. Debian or Ubuntu only. Based on python3 venv.

## Configuration

Rename `ansible-nm.conf.example` to `ansible-nm.conf` and adjust values to fit your needs.

- `ansible_user`: This user will be created by the script, and added to sudo group. It will be the Ansible user (owner of the ssh management key, etc.)
- `ansible_install_dir`: The directory that will contain python virtual environments for each new Ansible version

## First run

The first time you run these scripts, connect as your default user or root, and run `00_prepare_sys_for_ansible.sh` with elevated privileges. This will install prerequisites, do a full upgrade and reboot if a new kernel has been installed.

Once this script is done (and reboot complete if needed), connect as your user defined in `ansible-nm.conf`. With the example, we connect as `myuser`. Execute (WITHOUT `sudo`) the script `01_install_ansible.sh`, with the ansible version as argument. A venv is created in `$ansible_install_dir`, and a line to source this venv is added in `$HOME/.bashrc`.

## Run it again!

Once you have executed these scripts once, you can re-execute it. The first one will just update/upgrade/dist-upgrade the system, and reboot if a new kernel is installed.

The second one will install the given Ansible version if a venv does not already exist for this version.

## Example

First run:

```bash
# ansible-nm.conf
ansible_user='myuser'
ansible_install_dir='/home/myuser/ansible'
```

```console
# Connect as sudoer or root
sysadmin@ansible-nm$ sudo ./00_prepare_sys_for_ansible.sh
(...)
sysadmin@ansible-nm$ exit

# Connect as your ansible user
myuser@ansible-nm$ ./01_install_ansible.sh 2.9
(...)
myuser@ansible-nm$ source /home/myuser/ansible/2.9/bin/activate
(2.9) myuser@ansible-nm$ grep "source /home/myuser/ansible" $HOME/.bashrc
source /home/myuser/ansible/2.9/bin/activate
```

Later runs:

```console
# Couple months later, just connect as your ansible user
(2.9) myuser@ansible-nm$ sudo ./00_prepare_sys_for_ansible.sh # Just a system upgrade, optional
(2.9) myuser@ansible-nm$ ./01_install_ansible.sh 2.10         # Install Ansible 2.10

(2.9) myuser@ansible-nm$ grep "source /home/myuser/ansible" $HOME/.bashrc
source /home/myuser/ansible/2.10/bin/activate
```

At next logon, or if you source it now, Ansible 2.10 venv will be used

## Script details

### `00_prepare_sys_for_ansible.sh`

- Requires root privileges
- Parse config file, check for errors
- Create user `$ansible_user` if it does not exist
- Add user `$ansible_user` to the group `sudo` if not already sudoer
- Update, upgrade, dist-upgrade
- Install packages. Some of them are not absolutely required (such as `vim`), but hey I like my environment
- Reboot if a new kernel is installed

### `01_install_ansible.sh VERSION`

- Does not require root privileges (and should not be used as root, regarding Ansible best practices)
- Parse config file, check for errors
- Create `$ansible_install_dir` if it does not already exist
- Check if an ssh key exist in `$HOME/.ssh/`, and create one if there is none (rsa4096). This check is only based on filename `id_*`. It is only meant to speed up node manager setup for lab environments. Delete this key if you don't need it, or import your key before running the script, under a name starting with `id_`.
- Create venv "VERSION" in `$ansible_install_dir` if it does not exist
- Upgrade `pip`, install `wheel` and `ansible==VERSION` (venv only)
- Install any packages listed in requirements.txt
- Check if a `source` line corresponding to the venv exists in `$HOME/.bashrc`. If it's found, it is replaced with the newly created venv. If it's not found, it's appended to the end of the file.

