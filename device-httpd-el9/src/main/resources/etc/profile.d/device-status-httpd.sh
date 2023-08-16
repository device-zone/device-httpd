#!/bin/bash

if /usr/bin/tty -s
then
  /usr/libexec/device-status/httpd
fi

