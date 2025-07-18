#!/bin/bash
# `az login` should have been run before executing this script:

set -e

cwd=$(pwd)
script_dir=$(dirname $(realpath "$0"))
cd ${script_dir}

if [ "$SKIP_LANGUAGE_SETUP" = "true" ]; then
    echo "Skipping language setup..."
    exit 0
fi

echo "Running language setup..."

# Fetch data:
cp ../data/*.json .

python3 -m pip install -r requirements.txt
python3 clu_setup.py
python3 cqa_setup.py
python3 orchestration_setup.py

# Cleanup:
rm *.json
cd ${cwd}

echo "Language setup complete"
