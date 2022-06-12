# borgbackup for home assistant

## ⚠️ Do Not Use

This addon has a fatal flaw: it attempts to extract the entire HA backup
tarballs inside HA supervisor in order to run `borg create` on the extract
files.

This will break your HA install if you have > 50% of your hard disk used.

I suggest using [Thomas Mauerer's
samba-backup](https://github.com/thomasmauerer/hassio-addons/tree/master/samba-backup)
instead.

A proper borg solution would not rely on HA's built in snaphots (but that has
its own disadvantages)

## About

This addon is based on:

* [Thomas Mauerer's samba-backup](https://github.com/thomasmauerer/hassio-addons/tree/master/samba-backup)
* and [bmanojlovic's borg-backup addon](https://github.com/bmanojlovic/home-assistant-borg-backup)

Home assistant is very nice system, but every system can crash or disks it
resides on can stop spinning eventually, so we need to keep configuration and
data safe with some kind of backup, this addon provides exactly that. More
about borgbackup could be found at [borgbackup](https://www.borgbackup.org/)
website

Few things this addon provides to you are:

* automation of backups
* compression of backups
* deduplication of backups

The first is done by home assistant but last two are benefits that
[borgbackup](https://www.borgbackup.org/) provides.

## Install

1) Add `https://github.com/ramblurr/home-assistant-addons` into supervisor
   addons-store
2) Install Borg-Backup addon
3) Configure the system and addon for backups

## Configuration

To configure the addon you must provide the following **required** configuration
values:

```yaml
borg_repo_url: user@host:path/to/rep
borg_passphrase: a-long-random-passphrase
```

When first run addon will provide in its logs information of ssh key that you
should set on borg backup server. Example key how it should look like is shown
bellow.

```console
[00:01:07] INFO: Your ssh key to use for borg backup host
[00:01:07] INFO: ************ SNIP **********************
ssh-rsa AAAAB3N... root@local-borg-backup
[00:01:07] INFO: ************ SNIP **********************
```

Alternatively you can create the `borg/keys/borg_backup{,.pub}` files yourself,
don't forget to `chmod 0600` them.

## Automation

In Automation add something like this in Configuration -> Automations

1) click + symbol
2) skip Almond if you have it
3) add Name `Automatic borg backup`
4) in trigger section set "trigger type" to `Time`
5) on line stating "At" set time at which you would like backup to be done
    02:02:02
6) in actions set `call service` if not already set
7) for service set `hassio.start_addon`
8) in "Service data" add above installed addon. Exact name of
   "`xxxx_borg-backup`" in configuration should be provided to you by system when
   you open from "supervisor dashboard" and going to addon page (look at URL of
   borg-backup)
    addon: xxxx_borg-backup
9) save, sit and relax as it should work now :)

## Contact and issues

Use [issue
tracker](https://github.com/bmanojlovic/home-assistant-borg-backup/issues) on
github for any issue with this addon.
