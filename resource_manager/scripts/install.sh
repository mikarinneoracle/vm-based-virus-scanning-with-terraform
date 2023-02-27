#!/bin/bash

echo "ocarun ALL=(ALL) NOPASSWD:ALL" > /tmp/101-oracle-cloud-agent-run-command
sudo cp /tmp/101-oracle-cloud-agent-run-command /etc/sudoers.d/
