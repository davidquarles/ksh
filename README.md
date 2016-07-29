# Usage
  `ksh POD [FLAGS] [-- COMMAND]`

###### Note that POD uses pattern-matching, strict equality is not required. COMMAND defaults to `bash` if not specified.

### Flags:
    -c, --container="": Container name.  This actually uses pattern-matching, strict equality is not required.  If a single container can not be deterministically selected (or if this arg is omitted for multi-container pods), you will be prompted to choose a container.
    --context="": The name of the kubeconfig context to use
    --namespace="": If present, the namespace scope for this CLI request.
