#!/bin/sh -ef

help() {
	printf %s 'NAME
	svh - dead simple sv helper

SYNOPSIS
	svh [OPTIONS] commands ...

OPTIONS
	-u
		User mode
	-v
		Passed to sv (if called)
	-w
		Passed to sv (if called)
	-h
		Help

COMMANDS
	If an undefined command is supplied it will be passed to sv along with any other
	remaining arguments.

	log [directory]
		Shows the logs for directory if supplied, otherwise exits with code 1 and
		prints valid log directories. Assumes logs are stored in
		/var/log/socklog/$directory/current (i.e. assumes socklog is being used).

	enable service
		Enables a service (i.e. ln -s /etc/sv/$service $SVDIR/)

	disable service
		Disables a service (i.e. unlink $SVDIR/$service)

ENVIRONMENT
	SVDIR   Is used by sv if sv is called AND if -u is not set.

	XDG_CONFIG_HOME 
		Determines where the user service directory should be
		($XDG_CONFIG_HOME/service/). Defaults to $HOME/.config/

	PAGER   Pager to be used when viewing logs (defaults to less).

' >&2; exit 1;
}

err() { printf '%s\n' "svh: $1" >&2; exit 1; }

USERSVDIR="${XDG_CONFIG_HOME:-$HOME/.config}/service/"

while getopts "uvwh" o; do
	case "$o" in
		u) export SVDIR="$USERSVDIR";;
		v) SVARGS="${SVARGS} -v";;
		w) SVARGS="${SVARGS} -w";;
		h | *) help;;
	esac
done
shift $((OPTIND-1))

[ ! "$SVDIR" ] && SVDIR='/var/service/'

case "$1" in
	log)
		[ ! "$2" ] && ls '/var/log/socklog' >&2 && exit 1
		${PAGER:-less} "/var/log/socklog/$2/current"
		;;
	enable)
		[ ! "$2" ] && err 'No service provided'
		ln -s "/etc/sv/$2/" "$SVDIR"
		;;
	disable)
		[ ! "$2" ] && err 'No service provided'
		unlink "$SVDIR/$2"
		;;
	*)
		# shellcheck disable=2086 # globbing disabled
		exec sv $SVARGS "$@"
		;;
esac

