#!/bin/bash
# This builds a .deb package for installing MobileTerminal using
# Cydia as described here: http://www.saurik.com/id/7
#
# This script is executed by the "deb" XCode target.

set -e
set -u

if [ ! `which dpkg-deb` ]; then
  echo "Could not find dpkg-debg command to build package";
  exit 1
fi

APP_NAME=Terminal
PACKAGE_NAME=MobileTerminal
CONTROL_FILE=control.def

if [ ${DEB_VERSION-_} ]; then
  DEB_VERSION=1
fi
SVN_VERSION=`svnversion $SRCROOT | sed 's/^.*://'`

# Make sure the iPhone app has already been built
APPLICATION_DIR=$BUILT_PRODUCTS_DIR/$APP_NAME.app
if [ ! -d $APPLICATION_DIR ]; then
  echo "Application directory does not exist: $APPLICATION_DIR";
  exit 1
fi

# The directory where the .deb file is being packaged
DEB_BUILD_DIR=$DERIVED_FILE_DIR/$PACKAGE_NAME
DEB_METADATA_DIR=$DEB_BUILD_DIR/DEBIAN
DEB_APP_DIR=$DEB_BUILD_DIR/Applications
while [ true ]; do
  # This is the .deb package version, put in the control file and deb filename.
  VERSION="$SVN_VERSION-$DEB_VERSION"
  DEB_DST=$TARGET_BUILD_DIR/$PACKAGE_NAME-$VERSION.deb
  if [ ! -f $DEB_DST ]; then
    echo "Building $DEB_DST"
    break
  fi
  DEB_VERSION=$((DEB_VERSION + 1))
done

# Build the .deb metadata
mkdir -p $DEB_METADATA_DIR
grep -v "^#" $SRCROOT/control.def | sed "s/VERSION/$VERSION/" > $DEB_METADATA_DIR/control

# Copy the actual application
mkdir -p $DEB_APP_DIR
cp -rp $APPLICATION_DIR $DEB_APP_DIR/

# Don't copy OS X metadata files
export COPYFILE_DISABLE
export COPY_EXTENDED_ATTRIBUTES_DISABLE

dpkg-deb --build $DEB_BUILD_DIR $DEB_DST
exit 0
