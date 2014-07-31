#!/bin/sh

# First install with
#   sudo port install xpdf +no_mangle_names
# See also: http://osiris.laya.com/coding/dylib_linking.html

cp /opt/local/bin/pdftotext ./

LIBS="libz.1.dylib libpaper.1.dylib"

for LIB in $LIBS; do
    cp /opt/local/lib/$LIB ./
    install_name_tool \
	-change /opt/local/lib/$LIB \ @executable_path/../Frameworks/$LIB \
	pdftotext
done
