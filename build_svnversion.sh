#!/bin/bash
#
# Writes the current SVN version to svnversion.h
#
# This script is executed by the svnversion XCode target.

set -e
set -u

SVN_VERSION=`svnversion $SRCROOT | sed 's/^:.*://'`
echo "#define SVN_VERSION ((int)strtol(\"$SVN_VERSION\", NULL, 10))" > $SRCROOT/svnversion.h
