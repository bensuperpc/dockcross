#!/usr/bin/env bash

set -e
set -o pipefail

PYTHON=python
while [ $# -gt 0 ]; do
  case "$1" in
    -python)
      PYTHON=$2
      shift
      ;;
    *)
      echo "Usage: Usage: ${0##*/} [-python /path/to/bin/python]"
      exit 1
      ;;
  esac
  shift
done

cd /tmp

# Todo: Need to update base image from Debian Stretch for the required Python
# 3.6 or later
curl -# -LO https://bootstrap.pypa.io/pip/get-pip.py
<<<<<<< HEAD
=======
#curl -# -LO https://bootstrap.pypa.io/pip/2.7/get-pip.py
>>>>>>> 9adf96c16b00759a9f7f69be3e61b5e16cdd6ac4
${PYTHON} get-pip.py --ignore-installed
rm get-pip.py

${PYTHON} -m pip install --upgrade --ignore-installed setuptools
${PYTHON} -m pip install --ignore-installed conan
