# OS X Installers

This is a collection of some build scripts that will download what *I* need, and create OS X `pkg` files, so I don't have to manually compile everything when I change machines.  As I do most of my work in VMs, I don't need a lot -- basically libraries to support Python, PostgreSQL and GnuPG.

## Usage

Just run the relevant build script from [`scripts`](./scripts), and the package will appear in the [`pkg`](./pkg) subdirectory.  The only time you'll need privileges is when installing the actual `.pkg` file, like a normal OS X user.  Described below is the order for building:

Build and install GnuPG:

```
./scripts/gnupg.sh && sudo installer -pkg pkg/gnupg.pkg -target /
```

Now do basic libraries, starting with `pkg-config`:

```
for pkg in pkg-config readline xz; do
  ./scripts/${pkg}.sh
  sudo installer -pkg pkg/${pkg}.pkg -target /
done
```

GnuTLS and its prereqs are needed for Emacs:

```
for pkg in gmp nettle gettext gnutls jansson texinfo; do
  ./scripts/${pkg}.sh
  sudo installer -pkg pkg/${pkg}.pkg -target /
done
```

Emacs is built as a normal macOS app:

```
./scripts/emacs.sh
# Drag pkg/emacs/29.4/Emacs.app /Applications
```

Python requires SQLite3 and OpenSSL; OpenSSL is also required for PostgreSQL:

```
./scripts/openssl.sh && sudo installer -pkg pkg/openssl.pkg -target /
./scripts/sqlite.sh && sudo installer -pkg pkg/sqlite.pkg -target /
```

## Why not alternatives?

In short, I don't like them all.  MacPorts and Fink (yes I'm old, you hipsters) have pretty much gone stale.  I don't like the paths used by [`pkgsrc`](https://pkgsrc.joyent.com/), and I don't feel like patching their build system to put in `/usr/local`.  I consider all those superior to what's, unfortunately, considered the standard for devs on the Mac: Homebrew, here's why:

* The *insane* recommendation of a directory in the system's `PATH` writable by the main user, and then having the audacity of calling it a "security" feature.
* The symlinking of binaries to versioned directories in `Cellar`.  This great idea has been used by such other package luminaries like SCO Unix.
* Questionable patches as part of the build recipes.
* Nothing is GPG-signed or verified.
* Test suites aren't run.
* It's undependable, especially when upgrading versions.
* I got burned in the early days of GeoDjango by the author's aggressive use of compilation optimization flags, which caused me and my users countless hours of angst.

I concede that I got building hints from its recipes.  I'm grateful to the Homebrew maintainers for that.  However, I'm just too philosphically opposed to let it get near my `/usr/local`.
