#!/bin/sh
#
# Copyright (c) 2009 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
#
# This script is part of the google-chrome package.
#
# It creates the repository configuration file for package updates, and it
# monitors that config to see if it has been disabled by the overly aggressive
# distro upgrade process (e.g.  intrepid -> jaunty). When this situation is
# detected, the respository will be re-enabled. If the respository is disabled
# for any other reason, this won't re-enable it.
#
# This functionality can be controlled by creating the $DEFAULTS_FILE and
# setting "repo_add_once" and/or "repo_reenable_on_distupgrade" to "true" or
# "false" as desired. An empty $DEFAULTS_FILE is the same as setting both values
# to "false".

# System-wide package configuration.
DEFAULTS_FILE="/etc/default/google-chrome"

# sources.list setting for google-chrome updates.
REPOCONFIG="deb http://dl.google.com/linux/chrome/deb/ stable main"

APT_GET="`which apt-get 2> /dev/null`"
APT_CONFIG="`which apt-config 2> /dev/null`"

SOURCES_PREAMBLE="### THIS FILE IS AUTOMATICALLY CONFIGURED ###
# You may comment out this entry, but any other modifications may be lost.\n"

# Parse apt configuration and return requested variable value.
apt_config_val() {
  APTVAR="$1"
  if [ -x "$APT_CONFIG" ]; then
    "$APT_CONFIG" dump | sed -e "/^$APTVAR /"'!d' -e "s/^$APTVAR \"\(.*\)\".*/\1/"
  fi
}

# Install the repository signing key (see also:
# https://www.google.com/linuxrepositories/)
install_key() {
  APT_KEY="`which apt-key 2> /dev/null`"
  if [ -x "$APT_KEY" ]; then
    "$APT_KEY" add - >/dev/null 2>&1 <<KEYDATA
-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v1.4.2.2 (GNU/Linux)

mQGiBEXwb0YRBADQva2NLpYXxgjNkbuP0LnPoEXruGmvi3XMIxjEUFuGNCP4Rj/a
kv2E5VixBP1vcQFDRJ+p1puh8NU0XERlhpyZrVMzzS/RdWdyXf7E5S8oqNXsoD1z
fvmI+i9b2EhHAA19Kgw7ifV8vMa4tkwslEmcTiwiw8lyUl28Wh4Et8SxzwCggDcA
feGqtn3PP5YAdD0km4S4XeMEAJjlrqPoPv2Gf//tfznY2UyS9PUqFCPLHgFLe80u
QhI2U5jt6jUKN4fHauvR6z3seSAsh1YyzyZCKxJFEKXCCqnrFSoh4WSJsbFNc4PN
b0V0SqiTCkWADZyLT5wll8sWuQ5ylTf3z1ENoHf+G3um3/wk/+xmEHvj9HCTBEXP
78X0A/0Tqlhc2RBnEf+AqxWvM8sk8LzJI/XGjwBvKfXe+l3rnSR2kEAvGzj5Sg0X
4XmfTg4Jl8BNjWyvm2Wmjfet41LPmYJKsux3g0b8yzQxeOA4pQKKAU3Z4+rgzGmf
HdwCG5MNT2A5XxD/eDd+L4fRx0HbFkIQoAi1J3YWQSiTk15fw7RMR29vZ2xlLCBJ
bmMuIExpbnV4IFBhY2thZ2UgU2lnbmluZyBLZXkgPGxpbnV4LXBhY2thZ2VzLWtl
eW1hc3RlckBnb29nbGUuY29tPohjBBMRAgAjAhsDBgsJCAcDAgQVAggDBBYCAwEC
HgECF4AFAkYVdn8CGQEACgkQoECDD3+sWZHKSgCfdq3HtNYJLv+XZleb6HN4zOcF
AJEAniSFbuv8V5FSHxeRimHx25671az+uQINBEXwb0sQCACuA8HT2nr+FM5y/kzI
A51ZcC46KFtIDgjQJ31Q3OrkYP8LbxOpKMRIzvOZrsjOlFmDVqitiVc7qj3lYp6U
rgNVaFv6Qu4bo2/ctjNHDDBdv6nufmusJUWq/9TwieepM/cwnXd+HMxu1XBKRVk9
XyAZ9SvfcW4EtxVgysI+XlptKFa5JCqFM3qJllVohMmr7lMwO8+sxTWTXqxsptJo
pZeKz+UBEEqPyw7CUIVYGC9ENEtIMFvAvPqnhj1GS96REMpry+5s9WKuLEaclWpd
K3krttbDlY1NaeQUCRvBYZ8iAG9YSLHUHMTuI2oea07Rh4dtIAqPwAX8xn36JAYG
2vgLAAMFB/wKqaycjWAZwIe98Yt0qHsdkpmIbarD9fGiA6kfkK/UxjL/k7tmS4Vm
CljrrDZkPSQ/19mpdRcGXtb0NI9+nyM5trweTvtPw+HPkDiJlTaiCcx+izg79Fj9
KcofuNb3lPdXZb9tzf5oDnmm/B+4vkeTuEZJ//IFty8cmvCpzvY+DAz1Vo9rA+Zn
cpWY1n6z6oSS9AsyT/IFlWWBZZ17SpMHu+h4Bxy62+AbPHKGSujEGQhWq8ZRoJAT
G0KSObnmZ7FwFWu1e9XFoUCt0bSjiJWTIyaObMrWu/LvJ3e9I87HseSJStfw6fki
5og9qFEkMrIrBCp3QGuQWBq/rTdMuwNFiEkEGBECAAkFAkXwb0sCGwwACgkQoECD
D3+sWZF/WACfeNAu1/1hwZtUo1bR+MWiCjpvHtwAnA1R3IHqFLQ2X3xJ40XPuAyY
/FJG
=Quqp
-----END PGP PUBLIC KEY BLOCK-----
KEYDATA
  fi
}

# Set variables for the locations of the apt sources lists.
find_apt_sources() {
  APTDIR=$(apt_config_val Dir)
  APTETC=$(apt_config_val 'Dir::Etc')
  APT_SOURCES="$APTDIR$APTETC$(apt_config_val 'Dir::Etc::sourcelist')"
  APT_SOURCESDIR="$APTDIR$APTETC$(apt_config_val 'Dir::Etc::sourceparts')"
}

# Update the Google repository if it's not set correctly.
# Note: this doesn't necessarily enable the repository, it just makes sure the
# correct settings are available in the sources list.
# Returns:
# 0 - no update necessary
# 2 - error
update_bad_sources() {
  if [ ! "$REPOCONFIG" ]; then
    return 0
  fi

  find_apt_sources

  SOURCELIST="$APT_SOURCESDIR/google-chrome.list"
  # Don't do anything if the file isn't there, since that probably means the
  # user disabled it.
  if [ ! -r "$SOURCELIST" ]; then
    return 0
  fi

  # Basic check for active configurations (non-blank, non-comment lines).
  ACTIVECONFIGS=$(grep -v "^[[:space:]]*\(#.*\)\?$" "$SOURCELIST" 2>/dev/null)

  # Check if the correct repository configuration is in there.
  REPOMATCH=$(grep "^[[:space:]#]*\b$REPOCONFIG\b" "$SOURCELIST" \
    2>/dev/null)

  # Check if the correct repository is disabled.
  MATCH_DISABLED=$(echo "$REPOMATCH" | grep "^[[:space:]]*#" 2>/dev/null)

  # Now figure out if we need to fix things.
  BADCONFIG=1
  if [ "$REPOMATCH" ]; then
    # If it's there and active, that's ideal, so nothing to do.
    if [ ! "$MATCH_DISABLED" ]; then
      BADCONFIG=0
    else
      # If it's not active, but neither is anything else, that's fine too.
      if [ ! "$ACTIVECONFIGS" ]; then
        BADCONFIG=0
      fi
    fi
  fi

  if [ $BADCONFIG -eq 0 ]; then
    return 0
  fi

  # At this point, either the correct configuration is completely missing, or
  # the wrong configuration is active. In that case, just abandon the mess and
  # recreate the file with the correct configuration. If there were no active
  # configurations before, create the new configuration disabled.
  DISABLE=""
  if [ ! "$ACTIVECONFIGS" ]; then
    DISABLE="#"
  fi
  printf "$SOURCES_PREAMBLE" > "$SOURCELIST"
  printf "$DISABLE$REPOCONFIG\n" >> "$SOURCELIST"
  if [ $? -eq 0 ]; then
    return 0
  fi
  return 2
}

# Add the Google repository to the apt sources.
# Returns:
# 0 - sources list was created
# 2 - error
create_sources_lists() {
  if [ ! "$REPOCONFIG" ]; then
    return 0
  fi

  find_apt_sources

  SOURCELIST="$APT_SOURCESDIR/google-chrome.list"
  if [ -d "$APT_SOURCESDIR" ]; then
    printf "$SOURCES_PREAMBLE" > "$SOURCELIST"
    printf "$REPOCONFIG\n" >> "$SOURCELIST"
    if [ $? -eq 0 ]; then
      return 0
    fi
  fi
  return 2
}

# Remove our custom sources list file.
# Returns:
# 0 - successfully removed, or not configured
# !0 - failed to remove
clean_sources_lists() {
  if [ ! "$REPOCONFIG" ]; then
    return 0
  fi

  find_apt_sources

  rm -f "$APT_SOURCESDIR/google-chrome.list" \
        "$APT_SOURCESDIR/google-chrome-stable.list"
}

# Detect if the repo config was disabled by distro upgrade and enable if
# necessary.
handle_distro_upgrade() {
  if [ ! "$REPOCONFIG" ]; then
    return 0
  fi

  find_apt_sources
  SOURCELIST="$APT_SOURCESDIR/google-chrome.list"
  if [ -r "$SOURCELIST" ]; then
    REPOLINE=$(grep -E "^[[:space:]]*#[[:space:]]*$REPOCONFIG[[:space:]]*# disabled on upgrade to .*" "$SOURCELIST")
    if [ $? -eq 0 ]; then
      sed -i -e "s,^[[:space:]]*#[[:space:]]*\($REPOCONFIG\)[[:space:]]*# disabled on upgrade to .*,\1," \
        "$SOURCELIST"
      LOGGER=$(which logger 2> /dev/null)
      if [ "$LOGGER" ]; then
        "$LOGGER" -t "$0" "Reverted repository modification: $REPOLINE."
      fi
    fi
  fi
}

DEFAULT_ARCH="i386"

get_lib_dir() {
  if [ "$DEFAULT_ARCH" = "i386" ]; then
    LIBDIR=lib/i386-linux-gnu
  elif [ "$DEFAULT_ARCH" = "amd64" ]; then
    LIBDIR=lib/x86_64-linux-gnu
  else
    echo Unknown CPU Architecture: "$DEFAULT_ARCH"
    exit 1
  fi
}

## MAIN ##
DEFAULTS_FILE="/etc/default/google-chrome"
if [ -r "$DEFAULTS_FILE" ]; then
  . "$DEFAULTS_FILE"
fi

if [ "$repo_add_once" = "true" ]; then
  install_key
  create_sources_lists
  RES=$?
  # Sources creation succeeded, so stop trying.
  if [ $RES -ne 2 ]; then
    sed -i -e 's/[[:space:]]*repo_add_once=.*/repo_add_once="false"/' "$DEFAULTS_FILE"
  fi
else
  update_bad_sources
fi

if [ "$repo_reenable_on_distupgrade" = "true" ]; then
  handle_distro_upgrade
fi
