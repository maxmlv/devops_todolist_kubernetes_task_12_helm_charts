# Validation Instructions

This document describes how to verify that the `todoapp` Helm chart deployed correctly to the local `kind` cluster.

## 1. Run the bootstrap script

```bash
./bootstrap.sh
```

The script creates the `kind` cluster, installs `metrics-server` and the `ingress-nginx` controller, and deploys the `todoapp` Helm chart.

## 2. Verify the cluster is up

```bash
kubectl cluster-info
kubectl get nodes
```

Expect one `control-plane` node and two `worker` nodes, all in `Ready` status.

## 3. Verify all workloads are running

```bash
kubectl get all -A
```

Check for:
- `ingress-nginx-controller` pod: `1/1 Running`, scheduled on the control-plane node (`kubectl get pod -n ingress-nginx -o wide`)
- `mysql-0` and `mysql-1` (StatefulSet): `1/1 Running` in the `mysql` namespace
- `todoapp` deployment: `2/2 Running` in the `todoapp` namespace
- `metrics-server`: `1/1 Running` in `kube-system`

An example of `kubectl get all,cm,secret,ing -A` command output is in [output.log](output.log)

## 4. Verify namespaces and resources

```bash
kubectl get namespaces
kubectl get secrets -n todoapp
kubectl get secrets -n mysql
kubectl get serviceaccount,role,rolebinding -n todoapp
```

Confirm the `todoapp` and `mysql` namespaces exist, secrets (`todoapp-secret`, `mysql-secrets`) are present with the expected keys, and the RBAC objects (`ServiceAccount`, `Role`, `RoleBinding`) were created.

## 5. Verify the ingress is routing correctly

```bash
kubectl get ingress -n todoapp
```

Expect `CLASS: nginx`, `ADDRESS: localhost`, `PORTS: 80`.

Then test the app through the ingress:

```bash
curl -v http://localhost/
```

Expect an HTTP response from the `todoapp` service.

## 6. Verify autoscaling is configured

```bash
kubectl get hpa -n todoapp
```

Expect `MINPODS: 2`, `MAXPODS: 5`, with current CPU/memory usage reported (not `<unknown>` — if it shows `<unknown>`, `metrics-server` isn't ready yet or is misconfigured).

## 7. Verify MySQL connectivity from the app

```bash
kubectl exec -n todoapp deploy/todoapp-deployment -- printenv | grep DB_
```

Confirm the expected environment variables (e.g. `DB_PASSWORD`) are populated from the Secret (values will appear base64-decoded, as real strings, not raw base64).

## 8. Tear down (optional, for a clean re-test)

```bash
kind delete cluster
```

Re-run `bootstrap.sh` from a clean state to confirm the whole flow is reproducible end-to-end.
