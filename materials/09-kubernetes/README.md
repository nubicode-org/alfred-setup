# Kubernetes: companion material

Goes with the **Kubernetes** course on Alfred Learning. In the course nothing is applied: you author
manifests and work the failures as scenarios. Here you apply them to a real cluster on your laptop,
made by [kind](https://kind.sigs.k8s.io), and watch the reconciliation loop happen.

Needs Docker running, and the image from [08-containers](../08-containers/).

## Start a cluster and deploy

```bash
kind create cluster --name alfred --config kind-config.yaml     # about a minute
kubectl get nodes                                               # three nodes, Ready

docker build -t alfred-hello:dev ../08-containers/app
kind load docker-image alfred-hello:dev --name alfred           # kind cannot see your local images otherwise

kubectl apply -f manifests/
kubectl -n alfred rollout status deployment/hello
kubectl -n alfred get pods -o wide                              # spread across the two workers

kubectl -n alfred port-forward service/hello 8080:80            # then, in another terminal:
curl -s localhost:8080
```

## Things to try, from the course

1. **The loop.** `kubectl -n alfred delete pod <one of them>`, then `kubectl -n alfred get pods -w`.
   A new one appears: the deployment's desired state did not change.
2. **A selector that matches nothing.** Edit `20-service.yaml` to `app: helo`, apply, and
   `kubectl -n alfred get endpointslices`. The service still resolves; it has nowhere to send traffic.
   Put it back.
3. **A config change that does not apply.** Change `greeting` in `10-deployment.yaml`, apply, and
   curl again: still the old text. `kubectl -n alfred rollout restart deployment/hello`, then it changes.
4. **A stuck rollout.** `kubectl -n alfred set image deployment/hello web=alfred-hello:missing`. With
   `maxUnavailable: 0` the old pods keep serving while the new one cannot pull.
   `kubectl -n alfred rollout undo deployment/hello`.
5. **Pending on an idle cluster.** Raise `requests.memory` to `64Gi` and apply. `kubectl -n alfred
   describe pod <the new one>` says exactly which resource refused it.
6. **A drain and a disruption budget.** `kubectl drain alfred-worker --ignore-daemonsets`: it evicts
   one pod at a time to respect `minAvailable: 2`. `kubectl uncordon alfred-worker` afterwards. Then
   set `minAvailable: 3` and drain again: it waits forever, which is the course's last scenario.
7. **Who can do what.** `kubectl auth can-i delete pods -n alfred --as=system:serviceaccount:alfred:default`.

## Network policies

A policy is only as good as the network plugin enforcing it: a cluster without support accepts the
object and ignores it, silently. Recent kind releases enforce policies with their default plugin;
prove it on yours instead of assuming. The probe runs in the `default` namespace, because `alfred`
refuses pods that run as root. With `30-networkpolicy.yaml` applied, traffic to port 8080
is allowed, and anything else is not:

```bash
kubectl run probe --rm -it --image=busybox:1.37 --restart=Never -- \
  wget -qO- -T 3 http://hello.alfred.svc/          # answers: port 8080 is allowed

kubectl -n alfred delete networkpolicy allow-http-to-hello
kubectl run probe --rm -it --image=busybox:1.37 --restart=Never -- \
  wget -qO- -T 3 http://hello.alfred.svc/          # times out if the default deny is enforced

kubectl apply -f manifests/30-networkpolicy.yaml    # put it back
```

If the second request still answers, your cluster does not enforce policies.

## Clean up

```bash
kind delete cluster --name alfred
```

## Helm

The course reads charts more than it writes them. Render one locally to see exactly what it would
create, without installing anything:

```bash
helm create demo                  # a starter chart, in ./demo
helm template my-release ./demo   # the manifests it would apply
helm lint ./demo
```
