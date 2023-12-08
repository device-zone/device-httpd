#!/bin/bash

if /usr/bin/tty -s
then
  if test ${0:0:1} = "-"; then
    /usr/libexec/device-status/httpd
  fi
fi

