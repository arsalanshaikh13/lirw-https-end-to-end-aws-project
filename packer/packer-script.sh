#!/bin/bash
set -euo pipefail
pwd
if [ -f "../modules/asg/ami_ids/backend_ami.txt" ]; then
    echo "backend ami already exists"
    # exit 0 # how to safely exit?
else
    echo "creating a new packer image for backend ami"
    cd ../packer/backend
    # sudo chmod +x build_ami.sh
    chmod +x build_ami.sh
    ./build_ami.sh
fi
if [ -f "../modules/asg/ami_ids/frontend_ami.txt" ]; then
    echo "frontend ami already exists"
    # exit 0
else
    echo "creating a new packer image for frontend ami"
    cd ../packer/frontend
    # sudo chmod +x build_ami.sh
    chmod +x build_ami.sh
    ./build_ami.sh
fi

cd ../../root