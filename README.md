
# Helm Charts

Contains the helm charts to setup a running testbed

## Extra Apply
The extra apply folder contains yaml files which should be applied using kubectl apply -f "file".
They contain extra resources e.g. persistent volumes and might be setup-dependent.

## Password Values
The password_values.yaml.example file should be copied and renamed to "password_values.yaml". It must be additionally given to helm as a values file and handles passwords we do *not* want to commit. After copying the file the passwords need to be entered correctly.
