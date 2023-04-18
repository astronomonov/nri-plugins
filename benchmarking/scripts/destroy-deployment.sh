#!/usr/bin/env bash

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
BASE_DIR="$(realpath "${SCRIPT_DIR}/..")"

WORKLOAD="stress-ng"

usage () {
    cat << EOF
usage: $0
    -w <workload/template to destroy (default: stress-ng)>
EOF
    exit 1
}

while getopts ":n:i:l:s:w:" option; do
    case ${option} in
        n) ;;
        i) ;;
        l) ;;
        s) ;;
        w)
            WORKLOAD="${OPTARG}"
            ;;
        \?)
            usage
    esac
done

case $WORKLOAD in
    */*.yaml) ;;
    *) WORKLOAD="${BASE_DIR}/manifests/${WORKLOAD}-deployment.yaml";;
esac

kubectl delete -f $WORKLOAD
kubectl delete -f "${BASE_DIR}/manifests/jaeger-deployment.yaml"
helm uninstall -n monitoring prometheus
