# Ansible роли для настройки NFS сервера и клиента

<!-- TOC -->

- [Ansible роли для настройки NFS сервера и клиента](#ansible-%D1%80%D0%BE%D0%BB%D0%B8-%D0%B4%D0%BB%D1%8F-%D0%BD%D0%B0%D1%81%D1%82%D1%80%D0%BE%D0%B9%D0%BA%D0%B8-nfs-%D1%81%D0%B5%D1%80%D0%B2%D0%B5%D1%80%D0%B0-%D0%B8-%D0%BA%D0%BB%D0%B8%D0%B5%D0%BD%D1%82%D0%B0)
  - [Что требовалось сделать](#%D1%87%D1%82%D0%BE-%D1%82%D1%80%D0%B5%D0%B1%D0%BE%D0%B2%D0%B0%D0%BB%D0%BE%D1%81%D1%8C-%D1%81%D0%B4%D0%B5%D0%BB%D0%B0%D1%82%D1%8C)
    - [Плейбук для NFS-сервера](#%D0%BF%D0%BB%D0%B5%D0%B9%D0%B1%D1%83%D0%BA-%D0%B4%D0%BB%D1%8F-nfs-%D1%81%D0%B5%D1%80%D0%B2%D0%B5%D1%80%D0%B0)
      - [Плейбук для сервера на основе Ubuntu 22.04 LTS](#%D0%BF%D0%BB%D0%B5%D0%B9%D0%B1%D1%83%D0%BA-%D0%B4%D0%BB%D1%8F-%D1%81%D0%B5%D1%80%D0%B2%D0%B5%D1%80%D0%B0-%D0%BD%D0%B0-%D0%BE%D1%81%D0%BD%D0%BE%D0%B2%D0%B5-ubuntu-2204-lts)
    - [Плейбук для NFS-клиентов](#%D0%BF%D0%BB%D0%B5%D0%B9%D0%B1%D1%83%D0%BA-%D0%B4%D0%BB%D1%8F-nfs-%D0%BA%D0%BB%D0%B8%D0%B5%D0%BD%D1%82%D0%BE%D0%B2)
      - [Плейбук на основе **ansible.posix.mount** для Linux на основе RedHat и Ubuntu](#%D0%BF%D0%BB%D0%B5%D0%B9%D0%B1%D1%83%D0%BA-%D0%BD%D0%B0-%D0%BE%D1%81%D0%BD%D0%BE%D0%B2%D0%B5-ansibleposixmount-%D0%B4%D0%BB%D1%8F-linux-%D0%BD%D0%B0-%D0%BE%D1%81%D0%BD%D0%BE%D0%B2%D0%B5-redhat-%D0%B8-ubuntu)
      - [Плейбук с поддержкой **systemd** и **automount** для Linux на основе Ubuntu](#%D0%BF%D0%BB%D0%B5%D0%B9%D0%B1%D1%83%D0%BA-%D1%81-%D0%BF%D0%BE%D0%B4%D0%B4%D0%B5%D1%80%D0%B6%D0%BA%D0%BE%D0%B9-systemd-%D0%B8-automount-%D0%B4%D0%BB%D1%8F-linux-%D0%BD%D0%B0-%D0%BE%D1%81%D0%BD%D0%BE%D0%B2%D0%B5-ubuntu)
  - [Дополнительно](#%D0%B4%D0%BE%D0%BF%D0%BE%D0%BB%D0%BD%D0%B8%D1%82%D0%B5%D0%BB%D1%8C%D0%BD%D0%BE)
    - [Тестовая среда на основе Virtualbox + Vagrant](#%D1%82%D0%B5%D1%81%D1%82%D0%BE%D0%B2%D0%B0%D1%8F-%D1%81%D1%80%D0%B5%D0%B4%D0%B0-%D0%BD%D0%B0-%D0%BE%D1%81%D0%BD%D0%BE%D0%B2%D0%B5-virtualbox--vagrant)

<!-- /TOC -->

## Что требовалось сделать

### 1. Плейбук для NFS-сервера

Написать **Ansible** роль, которая будет конфигурировать серверную часть **NFS**: роль должна уметь установить необходимые для работы **NFS** сервера пакеты, и внести минимально необходимые конфигурационные параметры, запустить демона `nfs` при первичной установке или перезапустить его в случае внесения изменений в конфигурации уже работающего **nfs**-сервера.

#### 1.1 Плейбук для сервера на основе Ubuntu 22.04 LTS

```bash
# ssh nfs-server
$ cat setup-nfs-server.yml
---
- hosts: all
  become: true
  gather_facts: yes

  vars:
    nfs_exports: [ "/mnt/public *(rw,insecure,nohide,all_squash,anonuid=33,no_subtree_check)" ]

  roles:
  - role: ansible-nfs-server

$ ansible-playbook setup-nfs-server.yml
```
---

### 2. Плейбук для NFS-клиентов

Написать **Ansible** роль, которая будет конфигурировать клиентскую часть **NFS**: роль должна уметь на стороне клиента установить необходимые пакеты, примонтировать сетевой **nfs**-ресурс с помощью **systemd**-юнита и желательно сделать вариант юнита **automount**.

Подготовлены 2 плейбука:
  - На основе **ansible.posix.mount** - `simple-nfs-posix.mount.yml`
  - С поддержкой **systemd** и **automount** - `setup-nfs-client.yml`

#### 2.1 Плейбук на основе **ansible.posix.mount** для Linux на основе RedHat и Ubuntu

```bash
# ssh nfs-client
$ cat simple-nfs-posix.mount.yml
---
- name: Simple NFS posix.mount
  hosts: all
  become: true
  gather_facts: yes

  vars:
    nfs_share: "192.168.56.251:/mnt/public"
    nfs_mountpoint: "/share"
    nfs_permissions: '0777'
    nfs_options: 'rw,sync'
    owner: root
    group: root

  tasks:
    - name: Ensure required utilities present for Redhat-based
      ansible.builtin.yum:
        name:
          - nfs-utils
          - nfs4-acl-tools
        state: present
      when: ansible_os_family == 'RedHat'

    - name: Ensure required utilities present for Debian-based
      ansible.builtin.apt:
        name:
          - nfs-common
          - nfs4-acl-tools
        state: present
      when: ansible_os_family == 'Debian'

    - name: Ensure mountpoint exist
      ansible.builtin.file:
        path: "{{ nfs_mountpoint }}"
        state: directory
        mode: "{{ nfs_permissions }}"
        owner: "{{ owner }}"
        group: "{{ group }}"

    - name: Mount NFS network share
      ansible.posix.mount:
        src: "{{ nfs_share }}"
        path: "{{ nfs_mountpoint }}"
        fstype: nfs
        opts: "{{ nfs_options }}"
        state: mounted

$ ansible-playbook simple-nfs-posix.mount.yml
```

#### 2.2 Плейбук с поддержкой **systemd** и **automount** для Linux на основе Ubuntu

```bash
# ssh nfs-client
$ cat setup-nfs-client.yml
---
- hosts: all
  become: true
  gather_facts: yes

  vars:
    mounts:
      PublicShare:
        share: 192.168.56.251:/mnt/public
        mount: /opt/publicshare
        type: nfs
        options: auto
        automount: true

  roles:
    - role: ansible-nfs-client

$ ansible-playbook setup-nfs-client.yml
```

## Дополнительно
### Тестовая среда на основе Virtualbox + Vagrant
Для целей создания демо-стенда возможно использовать связку **Vagrant** и **VirtualBox**.

Стенд содержит конфигурацию для 3-х ВМ:
  - Виртуалка для Ansible-контроллера
    - `controller.ansible.local (controller)`
  - 2 вирт.машины для сервера и клиента
    - `host01.ansible.local (host01)`
    - `host02.ansible.local (host02)`

```bash
$ cd ansible-lab-vagrant\
$ vagrant up
$ vagrant ssh controller

$ cd ~/ansible-nfs-roles
$ ansible-playbook -l servers setup-nfs-server.yml
$ ansible-playbook -l clients setup-nfs-client.yml
```