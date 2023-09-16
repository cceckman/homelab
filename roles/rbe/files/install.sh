#! /bin/sh
#
python3 -m venv env
env/bin/python -m pip install --upgrade setuptools pip wheel
env/bin/python -m pip install --editable .

