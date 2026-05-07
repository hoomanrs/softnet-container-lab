# clab-softnet — Simple 2-Node ContainerLab Topology

**Purpose:** Minimal containerlab topology with dual-stack IPv4/IPv6 support

---

## Goal

A simple 2-node containerlab topology:
- Two Ubuntu nodes (node1, node2) connected by a single p2p link on eth1
- IPv4: `10.0.0.0/24`
- IPv6: `fc00::/64`

---

## Repository Structure

```
clab-softnet/
├── containerlab/
│   ├── basic-lab.clab.yml      # 2-node topology (node1 <-> node2)
│   ├── Dockerfile              # Ubuntu 24.04 image (sleep infinity as PID 1)
│   ├── bin/
│   │   └── entrypoint.sh       # Network configuration script (called via exec)
│   ├── configs/                # Per-node configuration
│   │   ├── node1.cfg
│   │   └── node2.cfg
│   ├── deploy.sh               # Deploy helper
│   └── destroy.sh              # Destroy helper
├── scripts/
│   └── build-image.sh          # Build custom Docker image
├── PLAN.md                     # Architecture and design notes
├── README.md                   # This file
└── TROUBLESHOOTING.md          # Debug guide
```

---

## Prerequisites

- [containerlab](https://containerlab.dev)
- docker
- Linux

---

## Quick Start

### 1. Build Docker Image

```bash
cd containerlab
docker build -t clab-ubuntu-softnet:latest .
```

Or use the helper script:

```bash
./scripts/build-image.sh
```

### 2. Deploy Topology

```bash
cd containerlab
containerlab deploy -t basic-lab.clab.yml
```

Containerlab will:
1. Start both containers (`sleep infinity` as PID 1)
2. Create the `node1:eth1 <-> node2:eth1` veth link
3. Run `bash /entrypoint.sh` inside each container via `exec`

The entrypoint output is shown directly in the deploy log.

### 3. Verify Connectivity

```bash
# Check node status
containerlab inspect -t basic-lab.clab.yml

# IPv4 ping
docker exec clab-basic-lab-node1 ping -c 3 10.0.0.2

# IPv6 ping
docker exec clab-basic-lab-node1 ping -6 -c 3 fc00::2
```

### 4. Destroy Topology

```bash
cd containerlab
containerlab destroy -t basic-lab.clab.yml --cleanup
```

---

## Configuration

### IP Addressing

| Node  | eth1 IPv4    | eth1 IPv6   | Peer IPv4 | Peer IPv6 |
|-------|-------------|-------------|-----------|-----------|
| node1 | 10.0.0.1/24 | fc00::1/64  | 10.0.0.2  | fc00::2   |
| node2 | 10.0.0.2/24 | fc00::2/64  | 10.0.0.1  | fc00::1   |

Each config file (`configs/node1.cfg`, `configs/node2.cfg`) defines all six values:
`NODE_IP`, `NODE_PREFIX`, `NODE_IP6`, `NODE_PREFIX6`, `PEER_IP`, `PEER_IP6`

### Network Topology

```
    +----------+       +----------+
    |  node1   | eth1  |  node2   |
    |10.0.0.1  |-------|10.0.0.2  |
    |fc00::1   |       |fc00::2   |
    +----------+       +----------+
```

---

## How exec Works

The topology uses containerlab's `exec` to run the entrypoint after links are created:

```yaml
nodes:
  node1:
    binds:
      - configs/node1.cfg:/etc/nodes/node1.cfg:ro
    exec:
      - bash /entrypoint.sh
```

This guarantees `eth1` already exists when the script runs — no polling loop needed.
The container stays alive via `CMD ["sleep", "infinity"]` in the Dockerfile.

---

## Commands Reference

```bash
# Deploy
containerlab deploy -t basic-lab.clab.yml

# Inspect
containerlab inspect -t basic-lab.clab.yml

# Shell access
docker exec -it clab-basic-lab-node1 bash
docker exec -it clab-basic-lab-node2 bash

# Destroy
containerlab destroy -t basic-lab.clab.yml --cleanup
```

---

## Troubleshooting

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

---

## License

GNU General Public License v3.0
