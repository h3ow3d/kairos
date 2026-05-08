# Kairos k3s Lab Cluster (GNS3)

This repository builds **9 bootable Kairos ISOs** for a k3s lab cluster in GNS3.

- 3 control-plane nodes
- 3 worker nodes
- 3 data nodes
- kube-vip API VIP: `10.0.0.100:6443` on `eth0`

Lab-focused only (simple and minimal). Not production hardened.

## Repository layout

- `cluster/` shared cluster settings reference
- `nodes/` per-node Kairos cloud-config files (one file per VM)
- `manifests/` Kubernetes manifests (reference kube-vip manifest)
- `build/` local build automation script
- `.github/workflows/` GitHub Actions workflow to build ISOs
- `artifacts/` local output directory for generated ISOs
- `gns3/` optional GNS3 notes/exports

## Node and IP plan

All nodes are configured with static IPs in cloud-config:

- `master-1` → `10.0.0.11`
- `master-2` → `10.0.0.12`
- `master-3` → `10.0.0.13`
- `worker-1` → `10.0.0.21`
- `worker-2` → `10.0.0.22`
- `worker-3` → `10.0.0.23`
- `data-1` → `10.0.0.31`
- `data-2` → `10.0.0.32`
- `data-3` → `10.0.0.33`

Shared network settings:

- Gateway: `10.0.0.1`
- DNS: `10.0.0.1`
- kube-vip VIP: `10.0.0.100`

## What this repo produces

- `master-1.iso`
- `master-2.iso`
- `master-3.iso`
- `worker-1.iso`
- `worker-2.iso`
- `worker-3.iso`
- `data-1.iso`
- `data-2.iso`
- `data-3.iso`

Each ISO already embeds the node hostname, static IP configuration, and k3s join/init behavior.

## Build with GitHub Actions

Workflow file: `.github/workflows/build-images.yml`

### Triggers

- `workflow_dispatch` (manual run from Actions tab)
- Pushes to `main` when `nodes/`, `manifests/`, `build/`, workflow file, or `README.md` change

### What the workflow does

1. Validates YAML syntax for all `nodes/*.yaml`
2. Verifies all expected node config files exist
3. Checks shell syntax of `build/build.sh`
4. Builds one ISO per node using AuroraBoot
5. Uploads each ISO as a separate artifact

### Downloading artifacts

1. Open GitHub **Actions**
2. Open a successful **Build Kairos Node ISOs** run
3. Download artifacts named:
   - `master-1-iso`, `master-2-iso`, `master-3-iso`
   - `worker-1-iso`, `worker-2-iso`, `worker-3-iso`
   - `data-1-iso`, `data-2-iso`, `data-3-iso`

## Build locally

Run from repository root:

```bash
./build/build.sh
```

Build a single node ISO:

```bash
./build/build.sh master-1
```

Local output is written to `artifacts/`.

Optional override for base image:

```bash
KAIROS_BASE_IMAGE=ghcr.io/kairos-io/kairos-k3s:latest ./build/build.sh master-1
```

## GNS3 VM creation and boot order

Create 9 VMs in GNS3 and attach the matching ISO to each VM.

Recommended boot order:

1. Boot `master-1` first
2. Wait until k3s is up and VIP `10.0.0.100` is reachable
3. Boot `master-2` and `master-3`
4. Boot all workers and data nodes

## Cluster verification

From a control-plane node:

```bash
kubectl get nodes -o wide
kubectl get pods -A
kubectl get endpoints kubernetes
ping 10.0.0.100
```

## Notes

- `super-secret-token` is hardcoded for lab convenience only.
- For real environments, rotate secrets and apply production hardening.
- `manifests/kube-vip.yaml` is kept as a standalone reference copy.
