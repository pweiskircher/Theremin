#!/bin/sh

find Source -name "*.m" -or -name "*.h" | xargs genstrings -o English.lproj
