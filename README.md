# Kairos k3s Lab Cluster (GNS3)

Minimal repository layout for a Kairos-based **k3s** lab cluster in GNS3.

## Layout

- `cluster/` shared cluster settings
- `nodes/` Kairos cloud-config files per node role
- `manifests/` Kubernetes manifests to copy onto nodes
- `gns3/` optional GNS3 project notes/exports

## Cluster architecture (3/3/3)

- 3 control-plane nodes (masters)
- 3 worker nodes
- 3 data nodes (tainted for stateful workloads)

```
                      +----------------------+
                      |  kube-vip VIP        |
                      |  10.0.0.100:6443     |
                      +----------+-----------+
                                 |
              +------------------+------------------+
              |                  |                  |
         master-1            master-2           master-3
        (init server)       (join server)      (join server)
              |
   +----------+-----------+
   |                      |
 worker-1..3          data-1..3
(node-role=worker)   (node-role=data, NoSchedule)
```

## kube-vip HA behavior

- kube-vip runs as a **static pod** on all master nodes.
- It advertises API VIP `10.0.0.100` over L2 using **ARP mode** on `eth0`.
- API clients and joining nodes always use `https://10.0.0.100:6443`.
- If one master fails, VIP leadership moves to another master.

## Boot flow

1. Boot the first master with `nodes/master-init.yaml`.
   - Installs k3s server with `--cluster-init`
   - Applies master taint (`NoSchedule`)
   - Writes kube-vip manifest to `/var/lib/rancher/k3s/server/manifests/kube-vip.yaml`
2. Boot the other two masters with `nodes/master-join.yaml`.
   - Join via VIP (`https://10.0.0.100:6443`)
   - Use same token
   - Also run kube-vip static pod
3. Boot worker nodes with `nodes/worker.yaml`.
   - Join as k3s agents
   - Label: `node-role=worker`
4. Boot data nodes with `nodes/data.yaml`.
   - Join as k3s agents
   - Label: `node-role=data`
   - Taint: `node-role=data:NoSchedule`

## Node config summary

- Token: `super-secret-token`
- VIP: `10.0.0.100`
- API port: `6443`
- Interface: `eth0`
- k3s install method: official script `https://get.k3s.io`

## Using these configs in Kairos

Apply one cloud-config file per VM instance:

- `nodes/master-init.yaml` for exactly one bootstrap master
- `nodes/master-join.yaml` for the remaining masters
- `nodes/worker.yaml` for worker VMs
- `nodes/data.yaml` for data VMs

After boot, verify from a master:

```bash
kubectl get nodes -o wide
kubectl get pods -n kube-system -l name=kube-vip
```

For manual/static pod reuse, `manifests/kube-vip.yaml` contains the same kube-vip definition expected at:

`/var/lib/rancher/k3s/server/manifests/kube-vip.yaml`

---

Lab-focused only (simple and minimal). Not production hardened.
