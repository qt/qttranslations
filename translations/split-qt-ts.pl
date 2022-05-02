#! /usr/bin/perl -w
#############################################################################
##
## Copyright (C) 2022 The Qt Company Ltd.
## Contact: https://www.qt.io/licensing/
##
## This file is part of the translations module of the Qt Toolkit.
##
## $QT_BEGIN_LICENSE:COMM$
##
## Commercial License Usage
## Licensees holding valid commercial Qt licenses may use this file in
## accordance with the commercial license agreement provided with the
## Software or, alternatively, in accordance with the terms contained in
## a written agreement between you and The Qt Company. For licensing terms
## and conditions see https://www.qt.io/terms-conditions. For further
## information use the contact form at https://www.qt.io/contact-us.
##
## $QT_END_LICENSE$
##
##
##
##
##
##
##
##
##############################################################################


use strict;

my @catalogs = ( "qtbase", "qtmultimedia" );

die "Usage: $0 <locale> [<builddir>]\n" if (@ARGV != 1 && @ARGV != 2);
my $lang = $ARGV[0];
my $lupdate = "lupdate -locations relative -no-ui-lines";
$lupdate .=  " -pro-out $ARGV[1]" if (@ARGV == 2);

for my $cat (@catalogs) {
    my $extra = "";
    $extra = " ../../qtactiveqt/src/src.pro ../../qtimageformats/src/src.pro" if ($cat eq "qtbase");
    system("$lupdate ../../$cat/src/src.pro$extra -xts qt_$lang.ts -ts ${cat}_$lang.ts") and die;
}
# qtdeclarative is special: we import it, but it is not part of the meta catalog
system("$lupdate ../../qtdeclarative/src/src.pro -xts qt_$lang.ts -ts qtdeclarative_$lang.ts") and die;

open META, "> qt_$lang.ts" or die;
print META <<EOF ;
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE TS>
<TS version="2.0" language="$lang">
    <dependencies>
EOF
for my $cat (@catalogs) {
    print META "        <dependency catalog=\"${cat}_$lang\"/>\n";
}
print META <<EOF ;
    </dependencies>
</TS>
EOF
close META or die;
