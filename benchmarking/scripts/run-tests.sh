#!/usr/bin/env bash

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
BASE_DIR="$(realpath "${SCRIPT_DIR}/..")"

PARAMS="$*"
if [ -z "$PARAMS" ]; then
    PARAMS="-n 10 -i 9"
fi

run_test() {
    local test=$1

    echo "Executing: ${SCRIPT_DIR}/run-test.sh $PARAMS -l $test"
    ${SCRIPT_DIR}/run-test.sh $PARAMS -l $test
}

cleanup_resource_policy() {
    # Remove all deployments of nri-plugins
    kubectl -n kube-system delete ds nri-resource-policy
}

cleanup_all() {
    ${SCRIPT_DIR}/destroy-deployment.sh $PARAMS
    cleanup_resource_policy
}

baseline="${baseline:-true}"

echo "***********"
echo "Note that you must install nri-resource-policy plugin images manually before running this script."
echo "***********"

if [ -z "$topology_aware" -a -z "$template" -a -z "$balloons" ]; then
    echo "No topology-aware, balloons or template deployment yaml files set. Set at least one for example like this:"
    echo "topology_aware=<dir>/nri-resource-policy-topology-aware-deployment.yaml balloons=<dir>/nri-resource-policy-balloons-deployment.yaml template=<dir>/nri-resource-policy-template-deployment.yaml ./scripts/run_tests.sh"
    echo
    echo "Using only partial resource policy deployments in the test:"
else
    echo "Using these resource policy deployments in the test:"
fi

echo "baseline       : ${baseline:-skipped}"
echo "topology_aware : ${topology_aware:-skipped}"
echo "balloons       : ${balloons:-skipped}"
echo "template       : ${template:-skipped}"

cleanup_all

# Note that with this script, we always run the baseline unless user
# sets "baseline=0" when starting the script, and those resource policy
# tests that user has supplied deployment file.
for test in baseline template topology_aware balloons
do
    # Install necessary deployments with the pre-run.sh script.
    # Unfortunately can not be done once before all tests
    # because some old Prometheus timeseries remain otherwise.
    ${SCRIPT_DIR}/pre-run.sh

    if [ $test = baseline ]; then
        if [ -z "$baseline" -o "$baseline" != "true" ]; then
            continue
        fi
    elif [ $test = template ]; then
        if [ -z "$template" -o ! -f "$template" ]; then
            continue
        fi

	kubectl apply -f "$template"
    elif [ $test = topology_aware ]; then
	if [ -z "$topology_aware" -o ! -f "$topology_aware" ]; then
	    continue
	fi

        kubectl apply -f "$topology_aware"
    elif [ $test = balloons ]; then
        if [ -z "$balloons" -o ! -f "$balloons" ]; then
            continue
        fi

        kubectl apply -f "$balloons"
    fi

    run_test $test
    cleanup_all
done
