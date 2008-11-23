#!/bin/sh
cd `dirname $0`
openssl dgst -sha1 -binary < $1 | openssl dgst -dss1 -sign dsa_priv.pem | openssl enc -base64
