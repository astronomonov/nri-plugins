#!/usr/bin/env bash

# For plotting graphs.

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
BASE_DIR="$(realpath "${SCRIPT_DIR}/..")"

python3 plot-graphs.py -o "${BASE_DIR}/output/traces.png" -l "topology-aware-jaeger,balloons-jaeger,template-jaeger,baseline-jaeger" "${BASE_DIR}/output"
python3 plot-graphs.py -o "${BASE_DIR}/output/resource_usage.png" -l "topology-aware-prometheus,balloons-prometheus,template-prometheus" "${BASE_DIR}/output"
