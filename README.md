# Helm charts for setting up the Testbed

This repository belongs to the [main Testbed repository](https://github.com/CRC-901-On-the-Fly-Computing/Testbed). It contains the [helm](https://helm.sh/) charts to setup a running testbed.

## Extra Apply
The `extra_apply` folders contain `yaml` files which should be applied using `kubectl apply -f <file>`.
They contain extra resources, e.g. persistent volumes, and might be setup-dependent.

## Password Values
The `password_values.yaml.example` file should be copied and renamed to `password_values.yaml`. It must be additionally passed to Helm as a values file and handles passwords we do *not* want to commit. After copying the file the passwords need to be entered correctly.
