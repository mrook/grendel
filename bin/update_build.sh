#!/bin/sh
perl -i -pe "s/#Build (\\d+)#/sprintf(\"#Build %d#\",\$1+1)/e" /opt/cvs/Grendel/build_version.txt
