#!/bin/bash

# convert existing nmap xml outputs to html
for file in *.xml
do
	xsltproc -o "${file/%.xml/.html}" nmap-bootstrap.xsl "$file" 
done

