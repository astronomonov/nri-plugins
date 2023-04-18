#!/usr/bin/env bash

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
BASE_DIR="$(realpath "${SCRIPT_DIR}/..")"

LOG_DIR="$BASE_DIR/output"
RUNTIME=${RUNTIME:-containerd}
OUTPUT_PREFIX=""

mkdir -p "$LOG_DIR"

PARAMS="$*"
if [ -z "$PARAMS" ]; then
    PARAMS="-n 10 -i 9"
fi

if [ ! -z "$PREFIX" ]; then
    PARAMS="$PARAMS -p \"$PREFIX\""
    OUTPUT_PREFIX="${PREFIX}-"
fi

get_pod_name() {
    local pod
    local timeout=20

    pod=$(until kubectl get pods -n kube-system | awk '/nri-resource-policy-/ { print $1 }'
	  do
	      timeout=$(( $timeout - 1 ))
	      if [ "$timeout" == "0" ]; then
		  echo "Timeout while waiting nri resource policy plugin to start" > /dev/tty
		  exit 1
	      fi
	      sleep 1
	  done)

    if [ -z "$pod" ]; then
	echo "Pod not found" > /dev/tty
	exit 1
    fi

    kubectl wait --timeout=10s --for=condition=Ready -n kube-system pod/$pod >/dev/null 2>&1
    if [ $? -ne 0 ]; then
	echo "Pod $pod not ready" > /dev/tty
	exit 1
    fi

    echo $pod
}

pod=""

START_TIME=$(date +%s)

run_test() {
    local test=$1

    # Let resource policy plugin to start
    sleep 1

    pod=$(get_pod_name)

    local prefix=${OUTPUT_PREFIX}$(date -u +"%Y%m%dT%H%M%SZ" -d "@${START_TIME}")

    kubectl -n kube-system logs "$pod" -f > "$LOG_DIR/$prefix-$test.log" 2>&1 &

    echo "Executing: ${SCRIPT_DIR}/run-test.sh $PARAMS -l $test"
    echo "Log file: $LOG_DIR/$prefix-$test.log"

    local current_time=$(date +"%Y-%m-%d %H:%M:%S")

    ${SCRIPT_DIR}/run-test.sh $PARAMS -l $test

    journalctl --since="$current_time" -u $RUNTIME > "$LOG_DIR/$prefix-$RUNTIME-$test.log"
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

baseline="${baseline:-true}"

if [ -z "$topology_aware" -o -z "$template" -o -z "$balloons" ]; then
    echo "Cannot find topology-aware, balloons or template deployment yaml file. Set it before for example like this:"
    echo "topology_aware=<dir>/nri-resource-policy-topology-aware-deployment.yaml balloons=<dir>/nri-resource-policy-balloons-deployment.yaml template=<dir>/nri-resource-policy-template-deployment.yaml ./scripts/run-tests.sh"
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

    # Install necessary deployments with the pre-run.sh script.
    # Unfortunately can not be done once before all tests
    # because some old Prometheus timeseries remain otherwise.
    ${SCRIPT_DIR}/pre-run.sh

    run_test $test
    cleanup_all
done
