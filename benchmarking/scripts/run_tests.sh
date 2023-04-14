#!/usr/bin/env bash

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
BASE_DIR="$(realpath "${SCRIPT_DIR}/..")"

PARAMS="$*"
if [ -z "$PARAMS" ]; then
    PARAMS="-n 10 -i 9"
fi

run_test() {
    local test=$1

    echo "Executing: ${SCRIPT_DIR}/run_test.sh $PARAMS -l $test"
    ${SCRIPT_DIR}/run_test.sh $PARAMS -l $test
}

cleanup_resource_policy() {
    # Remove all deployments of nri-plugins
    kubectl -n kube-system delete ds nri-resource-policy
}

cleanup_all() {
    kubectl delete deployment stress-ng
    cleanup_resource_policy
}

echo "***********"
echo "Note that you must install nri-resource-policy plugin images manually before running this script."
echo "***********"

if [ -z "$topology_aware" -o -z "$template" -o -z "$balloons" ]; then
    echo "Cannot find topology-aware, balloons or template deployment yaml file. Set it before for example like this:"
    echo "topology_aware=<dir>/nri-resource-policy-topology-aware-deployment.yaml balloons=<dir>/nri-resource-policy-balloons-deployment.yaml template=<dir>/nri-resource-policy-template-deployment.yaml ./scripts/run_tests.sh"
    echo
    echo "Using only partial resource policy deployments in the test:"
else
    echo "Using these resource policy deployments in the test:"
fi

echo "topology_aware : $topology_aware"
echo "balloons       : $balloons"
echo "template       : $template"

cleanup_all

# Note that with this script, we always run the baseline and then
# those resource policy tests that user has supplied deployment file.
for test in baseline template topology-aware balloons
do
    if [ $test = template ]; then
	if [ ! -f "$template" ]; then
	    continue
	fi

	kubectl apply -f "$template"
    elif [ $test = topology-aware ]; then
	if [ ! -f "$topology-aware" ]; then
	    continue
	fi

	kubectl apply -f "$topology_aware"
    elif [ $test = balloons ]; then
	if [ ! -f "$balloons" ]; then
	    continue
	fi

	kubectl apply -f "$balloons"
    fi

    run_test $test
    cleanup_resource_policy
done

cleanup_all
