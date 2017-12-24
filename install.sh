#!/bin/bash

# This script installs secure_delete_thunar. It is meant to be run by your
# distro's package creation too. In my case, Arch Linux's pacman is targeted

PKG_ROOT="/"
BASE_DIR="usr/local/"

help_and_exit(){
  cat 1>&2 << EOF
install.sh:

Install secure_delete_thunar. This script is designed for distro packaging
tools.

	USE:
./install.sh [--root <root dir>] [--base-dir <base dir>] install

	OPTIONS:

	--root		The root relative to where you want this isntalled, i.e
			\$pkgdir with Arch's makepkg. THIS DEFAULTS TO SYSTEM
			ROOT "/"!!!

	--base-dir	Base directory. Defaults to "usr/local". Change to
			"/usr" for package compiles

EOF
  exit 1
}

switch_checker() {
  while [ ! -z "$1" ];do
   case "$1" in
    --help|-\?)
     help_and_exit
     ;;
    --root)
     PKG_ROOT="${2}"
     shift
     ;;
    --base-dir)
     BASE_DIR="${2}"
     shift
     ;;
    *)
     PARMS+="${1}"
     ;;
   esac
   shift
  done
}

main(){
  echo root: $PKG_ROOT base: $BASE_DIR
  exit
  [ "$1" == "install" ] || help_and_exit
  install -Dm 644 shred.png ${PKG_ROOT}/${BASE_DIR}/icons/shred.png
  install -Dm 755 srm_guified.sh ${PKG_ROOT}/${BASE_DIR}/thunar_srm/srm_guified.sh
  install -Dm 755 LICENSE ${PKG_ROOT}/${BASE_DIR}/thunar_srm/LICENSE
  install -Dm 644 secure_delete.uca.xml ${PKG_ROOT}/${BASE_DIR}/thunar_srm/secure_delete.uca.xml
  install -Dm 644 secure_delete.uca.xml ${PKG_ROOT}/etc/xdg/Thunar/secure_delete.uca.xml
}

switch_checker "${@}"
main "$PARAMS"
