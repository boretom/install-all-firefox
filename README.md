![](./firefoxes-versions-shortend.png)

---
## ABOUT

This is a bash script to install all major versions of Firefox on OS X.

It installs all versions starting with 4.0, getting the list of Firefox release from ftp.mozilla.org/pub/mozilla.org/firefox/

Optionally, the script can install Firebug for each version of Firefox too (supported up to version 50).

### What does it do?

1. The `firefoxes.sh` script downloads the latest version of `install-all-firefox.sh` beforerunning to ensure that the script is up to date.

2. The script downloads all of the associated resources (icons) and utilities (seticon) to the `/tmp/firefoxes` directory.

3. The script downloads the `.dmg` files from Mozilla's server into `/tmp/firefoxes`.

4. The script installs the Firefoxes to `/Applications/Firefoxes/`.

5. The script creates a Firefox profile for each installed version of Firefox.

6. The script modifies each Firefox app to launch with its specific profile, disables updates and customises the application icon.

7. The script can optionally download the latest Firebug available for each version of Firefox, and install it upon first launch.

### What else does it do?

You can see which versions of Firefox you've already installed using this script, using the following command:

```bash
$ ./firefoxes.sh
```

or

```bash
$ ./firefoxes.sh status
```

You can specify the `version` to install, or use any of the pre-defined installation groups:

```bash
# Default, installs all versions available
$ ./firefoxes.sh

# You can also use the 'all' keyword to install all versions available
$ ./firefoxes.sh "all"

# 'current' installs the current version of Firefox only (other allowed keywords: 'newest', 'latest')
$ ./firefoxes.sh "current"
$ ./firefoxes.sh "newest"
$ ./firefoxes.sh "latest"

# Specify the versions you would like to install, from the list at the top of this README, separated by spaces
# New: You can now use shorthand for versions, such as: 2, 3, 3.5, 10, 24, etc.
$ ./firefoxes.sh "2 3"
```

You can specify the `locale` to use, from the list of available `locale` options. By default `en-GB` is used.

```
af, ar, be , bg, ca, cs, da, de, el, en-GB, en-US, es-AR, es-ES, eu, fi, fr,
fy-NL, ga-IE, he, hu, it, ja-JP-mac, ko, ku, lt, mk, mn, nb-NO, nl, nn-NO,
pa-IN, pl, pt-BR, pt-PT, ro, ru, sk, sl, sv-SE, tr, uk, zh-CN, zh-TW
```

```bash
$ ./firefoxes.sh "all" "en-US"
```

If you want to just install all versions and leave the installation process unattended, there is a `no_prompt` option, this will default all of the `Y/n` prompts to answering `y`.

```bash
$ ./firefoxes.sh "all" "en-GB" "no_prompt"
```
(You will still need to manually accept the EULA if installing Firefox 2.0.0.20)

If you want to install to a different directory, pass that as the last option. Include a trailing slash.

```bash
$ ./firefoxes.sh "all" "en-GB" "no_prompt" "/Users/myhomedir/Applications/"
```

### Set different github user repository

The default github user is set to 'boretom'. If you want to modify the scripts yourself and run it from your github account, set GITHUB_USER to your own username.

```bash
$ GITHUB_USER=fluffy ./firefoxes.sh status
```

---

## INSTALLATION

From a terminal prompt, enter the following:

```bash
curl -L -O https://github.com/boretom/install-all-firefox/raw/master/firefoxes.sh
chmod +x firefoxes.sh
./firefoxes.sh [version] [locale] [no_prompt] [install_directory]
```

It'll take a little while to grab the `.dmg` files, but it should only need to do this once.
(Until you reboot, and the contents of `/tmp` are deleted.)


---

### Prerequisite Software

```bash
$ brew install imagemagick gs fileicon
```

---
## CREDITS
- [Original script from omgmog](https://github.com/omgmog/install-all-firefox)
- [Firebug](http://getfirebug.com/)
- Thanks to the community for using/reporting issues/making suggestions for features!
- Thanks to Lurst for his [`create_firefox_image_with_version`](https://github.com/LuRsT/create_firefox_image_with_version) tool.
- [fileicon (another replacment for setfileicon)](https://github.com/mklement0/fileicon)
