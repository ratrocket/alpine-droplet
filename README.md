# Digital Ocean Alpine Linux Image Generator

## Note

Forked from https://github.com/benpye/alpine-droplet.  There's an
[article](https://curlybracket.co.uk/blog/running-alpine-linux-on-digital-ocean/)
that goes along with this repo.  ([Archive
link](https://web.archive.org/web/20240222015631/https://curlybracket.co.uk/blog/running-alpine-linux-on-digital-ocean/))

## Deprectation warning in Github Action

Using "set-output" is deprecated, but they're delaying its removal, so
I'm not going to worry about it now.  I don't understand how to modify
the line using "set-output" by the example in the following link, so...

More info:

https://github.blog/changelog/2022-10-11-github-actions-deprecating-save-state-and-set-output-commands/

## List of Alpine branches

To provide argument to `--branch` for the `alpine-make-vm-image` script,
which in my version of this, is required (just to get a good filename).

https://alpinelinux.org/releases/

(UPDATE: the `build-image.sh` gets the latest explicit version number
using lynx and a bunch of other stuff.)

## Dealing with the git submodule

([Git submodule
docs](https://git-scm.com/book/en/v2/Git-Tools-Submodules))

### initial setup

After you clone this repo, to set up the submodule:

- `cd alpine-make-vm-image/`
- `git submodule init`
- `git submodule update`

OR, you can git clone with the `--recurse-submodules` switch:

`git clone --recurse-submodules https://github.com/ratrocket/alpine-droplet`

### keeping the submodule up-to-date

Method 1:

`cd alpine-make-vm-image`, `git fetch`, `git merge`

To show changes: `cd ..`, `git diff --submodule`

(can do `git config --global diff.submodule log` to not have to use
`--submodule` switch)

Method 2:

`git submodule update --remote`

## Resume (mostly) original README

![Build Status](https://github.com/ratrocket/alpine-droplet/actions/workflows/build.yml/badge.svg?branch=master)

This is a tool to generate an Alpine Linux custom image for Digital
Ocean. This ensures that the droplet will correctly configure networking
and SSH on first boot using Digital Ocean's metadata service. To use
this tool make sure you have `qemu-nbd`, `qemu-img`, `bzip2` and
`e2fsprogs` installed. This will not work under the Windows Subsystem
for Linux (WSL) as it mounts the image during generation.

Once these prerequisites are installed run:

```bash
# ./build-image.sh
```

Note: Need root permission.

This will produce `alpine-virt-image-{version}-{timestamp}.qcow2.bz2`
which can then be uploaded to Digital Ocean and used to create your
droplet. Check out their instructions at
https://blog.digitalocean.com/custom-images/ for uploading the image and
creating your droplet.

The image will have a user named "alp" that is in the wheel group, so
ready to `doas`, but `doas` isn't installed yet.  `bash` and `ufw` are
installed, and `ufw` is configured fairly restrictively (see setup.sh).

Also, the repo is setup to run a Github Action on pushing to master that
will run `build-image.sh` for you and put the generated image
[here](https://github.com/ratrocket/alpine-droplet/tags).

~~In this commit, the script will produce alpine `version 3.15` image. If
you wanna build latest version, you can pull latest
[alpine-make-vm-image repo](https://github.com/alpinelinux/alpine-make-vm-image):
`git submodule foreach git pull origin master`.~~  This doesn't apply.

## TODO

[DONE enough] Get name of image to be
`alpine-virt-image-{version}-{hash}-{timestamp}.qcow2.bz2` where version
is the alpine version (eg, "3.15") and hash is a commit hash from the
alpine repo.  I realize the hash might be pushing it -- version alone
would ok!

UPDATE: partially done.  Got the version number, I'll give up on the
hash.
