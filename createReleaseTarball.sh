#!/bin/sh

VERSION=`cat Info.plist | grep BundleVersion -A1 | grep string | cut -d '>' -f 2 | cut -d '<' -f 1`
if [ -d ../releases/$VERSION ]; then
	echo -n "../releases/$VERSION already exists. Overwrite? [yN] "
	read answer

	if [ $answer = y ] || [ $answer = Y ]; then
		rm -rf ../releases/$VERSION
	else
		echo "aborting"
		exit
	fi
fi

mkdir -p ../releases/$VERSION
SIGNDIR=$PWD/sign
TARGETDIR=$PWD/../releases/$VERSION
TARGET=$TARGETDIR/Theremin_${VERSION}.tbz

echo Creating $TARGET ...

cd ../../build/Release
tar -jcf $TARGET Theremin.app
cp -R Theremin.app.dSYM $TARGETDIR/

if [ -e $SIGNDIR/dsa_priv.pem ]; then
	echo "DSA Key: "
	KEY=`$SIGNDIR/sign.sh $TARGET`
	echo $KEY
	echo $KEY >$TARGET.dsasign
else
	echo "Private key not available, stopping."
	exit
fi

cat >$TARGET.appcast << EOF
<item>
	<title>Theremin Version $VERSION</title>
	<description></description>
	<pubDate>`date -u`</pubDate>
	<enclosure sparkle:dsaSignature="$KEY" sparkle:version="$VERSION" url="http://theremin.amd.co.at/$VERSION/`basename $TARGET`" length="`ls -la $TARGET | awk '{print $5}'`" type="application/octet-stream"/>
</item>
EOF

