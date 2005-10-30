#!/bin/sh
xmlto -m manual-fragments.xsl xhtml manual.xml
xsltproc -o commands.ghp docbook-to-ghp.xslt manual.xml
