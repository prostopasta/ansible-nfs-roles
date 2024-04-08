# Ansible роли для настройки NFS сервера и клиента


## Что требовалось сделать

1. Написать **Ansible** роль, которая будет конфигурировать серверную часть **NFS**: роль должна уметь установить необходимые для работы **NFS** сервера пакеты, и внести минимально необходимые конфигурационные параметры, запустить демона `nfs` при первичной установке или перезапустить его в случае внесения изменений в конфигурации уже работающего **nfs**-сервера.

    #### 1.1 Плейбук для **NFS**-сервера

    ```bash
    # ssh nfs-server
    $ cat setup-nfs-server.yml
    ---
    - hosts: localhost
      become: true
      gather_facts: yes

      vars:
        nfs_exports: [ "/mnt/public *(rw,insecure,nohide,all_squash,anonuid=33,no_subtree_check)" ]

      roles:
      - role: ansible-nfs-server

    $ ansible-playbook setup-nfs-server.yml
    ```
---

2. Написать **Ansible** роль, которая будет конфигурировать клиентскую часть **NFS**: роль должна уметь на стороне клиента установить необходимые пакеты, примонтировать сетевой **nfs**-ресурс с помощью **systemd**-юнита и желательно сделать вариант юнита **automount**.

    Подготовлены два плейбука:
      - На основе **ansible.posix.mount** - `simple-nfs-posix.mount.yml`
      - С поддержкой **systemd** и **automount** - `setup-nfs-client.yml`

    #### 2.1 Плейбук на основе **ansible.posix.mount**

    ```bash
    # ssh nfs-client
    $ cat simple-nfs-posix.mount.yml
    ---
    - name: Simple NFS posix.mount
      hosts: localhost
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

    #### 2.2 Плейбук с поддержкой **systemd** и **automount**

    ```bash
    # ssh nfs-client
    $ cat setup-nfs-client.yml
    ---
    - hosts: localhost
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
Для целей создания демо-стенда возможно использовать связку **Vagrant** и **VirtualBox** (см. замечание). 

Стенд содержит 3 ВМ:
  - Виртуалка для Ansible-контроллера
    - `controller.ansible.local (controller)`
  - 2 вирт.машины для сервера и клиента
    - `host01.ansible.local (host01)`
    - `host02.ansible.local (host02)`

```bash
cd ansible-lab-vagrant\
vagrant up
vagrant ssh controller
```

**Замечание:**
В момент написания этого readme еще не была решена проблема авторизации по SSH, в связи с чем плейбуки тестировались лишь локально.