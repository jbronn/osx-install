# OS X Installers

This is a collection of some build scripts that will download what *I* need, and create OS X `pkg` files, so I don't have to manually compile everything when I change machines.  As I do most of my work in VMs, I don't need a lot -- basically libraries to support Python, PostgreSQL and GnuPG.

## Usage

Just run the relevant build script from [`scripts`](./scripts), and the package will appear in the [`pkg`](./pkg) subdirectory.  The only time you'll need privileges is when installing the actual `.pkg` file, like a normal OS X user.

Some depend on the presence on others (e.g., Python 2/3 need OpenSSL, GNU Readline, and pkg-config), and I'll compose meta packages when I get the time.

## Why not alternatives?

In short, I don't like them all.  MacPorts and Fink (yes I'm old, you hipsters) have pretty much gone stale.  I don't like the paths used by [`pkgsrc`](https://pkgsrc.joyent.com/), and I don't feel like patching their build system to put in `/usr/local`.  I consider all those superior to what's, unfortunately, considered the standard for devs on the Mac: Homebrew, here's why:

* The *insane* recommendation of a directory in the system's `PATH` writable by the main user, and then having the audacity of calling it a "security" feature.
* The symlinking of binaries to versioned directories in `Cellar`.  This great idea has been used by such other package luminaries like SCO Unix.
* Questionable patches as part of the build recipes.
* Nothing is GPG-signed or verified.
* It's undependable, especially when upgrading versions.
* I got burned in the early days of GeoDjango by the author's aggressive use of compilation optimization flags, which caused me and my users countless hours of angst.

I concede that I got building hints from its recipes.  I'm grateful to the Homebrew maintainers for that.  However, I'm just too philosphically opposed to let it get near my `/usr/local`.
