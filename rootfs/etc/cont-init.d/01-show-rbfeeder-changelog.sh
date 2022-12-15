#!/usr/bin/env bash

white="\e[0;97m"
reset="\e[0m"

# Show latest changelog
echo -e ${white}
zcat /usr/share/doc/rbfeeder/changelog.gz | grep -B9999 -m 1 " --  "
echo -e ${reset}
