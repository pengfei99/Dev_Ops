#!/bin/bash
echo "Current User home"
eval echo ~$USER

echo "All the services started up in runlevel 3"
ls /etc/rc3.d/S*

home
