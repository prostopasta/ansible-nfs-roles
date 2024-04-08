ansible-nfs-client
==================

This Ansible role mounts the file shares as Systemd service with automount support.

Works for Ubuntu 22.04 LTS (Jammy Jellyfish) and probably for all other Debian-based if you use systemd (not tested).

Role creates a Systemd service for mounting common file shares (NFS, CIFS, etc).

So you can use your **mount-point** as Systemd service, for example:

    systemctl status mount-point.mount
    systemctl start mount-point.mount
    systemctl stop mount-point.mount


Role Variables
--------------

| Variable    | Description        |
|-------------|--------------------|
| mounts      | A dictionary of mounts which required to be mounted. Check Linux `man 5 systemd.mount` or Ubuntu's [systemd.mount(5))](https://manpages.ubuntu.com/manpages/jammy/man5/systemd.mount.5.html) man-page for more info |


Share Options
-------------

| Option      | Description                |
|-------------|----------------------------|
| ShareName   | Description of the Service |
| share       | Share path to mount from   |
| mount       | Folder path to mount in    |
| type        | Mount type (check `man mount` page), for example: `nfs` |
| options     | Options, username, etc..., for example: `auto`  |
| automount   | When `false` the service will be mounted by **systemd** at boot time, and if `true` share will be also auto-mounted by **automount** |


Example Playbook
----------------

    - hosts: localhost
      become: true
      gather_facts: yes

      vars:
        mounts:
          PublicShare:
            share: 10.1.1.251:/mnt/public
            mount: /opt/publicshare
            type: nfs
            options: auto
            automount: true

      roles:
        - role: ansible-nfs-client


Author Information
------------------
[Pavel Statsenko](https://github.com/prostopasta)
