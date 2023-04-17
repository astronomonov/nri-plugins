# Demo setup

This is work in progress

## How to use

1. Install [helm](https://helm.sh/) for installing Prometheus chart.

2. Install [pipenv](https://pypi.org/project/pipenv/) for plotting graphs.

### Running the scripts together

3. Run the script, for example:

```console
template=~/nri-plugins/build/images/nri-resource-policy-template-deployment.yaml topology_aware=~/nri-plugins/build/images/nri-resource-policy-topology-aware-deployment.yaml balloons=~/nri-plugins/build/images/nri-resource-policy-balloons-deployment.yaml ./scripts/run-tests.sh
```

4. Run `pipenv shell`.

5. Run `pipenv install`.

6. Generate graphs with `plot-graphs.py`. If you use labels `baseline`, `template`, `topology-aware`, and `balloons` you can use the `post-run.sh` script.

7. Remove all files from the output directory to not have overlapping labels (filenames).

### Running the scripts individually

3. Configure cluster to desired state.

4. Run the `pre-run.sh` script. This deploys Jaeger and Prometheus. Example:

```console
./scripts/pre-run.sh
```

```console
usage: ./scripts/pre-run.sh -p <use prometheus: "true" or "false">
```

5. Wait for the Jaeger and Prometheus pods to be ready.

6. Run the test with `run-test.sh`. Example:

```console
./scripts/run-test.sh -n 10 -i 9 -l baseline
```

```console
usage: ./scripts/run-test.sh
    -n <number of stress-ng containers in increment>
    -i <increments>
    -l <filename label>
    -s <time to sleep waiting to query results>
```

7. To remove installed resources, run `destroy-deployment.sh`.

8. Repeat steps 1-5 for each desired setup and **label each setup with different labels that are not substrings of each other**.

9. Run `pipenv shell`.

10. Run `pipenv install`.

11. Generate graphs with `plot-graphs.py`. If you use labels `baseline`, `template`, `topology-aware`, and `balloons` you can use the `post-run.sh` script.

12. Remove all files from the output directory to not have overlapping labels (filenames).

## How to setup tracing

https://github.com/containerd/containerd/blob/main/docs/tracing.md
