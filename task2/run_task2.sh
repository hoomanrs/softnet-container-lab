#!/bin/bash

# Clean up existing containers and links
docker rm -f hs1 rt1 hs2 2>/dev/null
sudo ip link delete veth-hs1 2>/dev/null
sudo ip link delete veth-hs2 2>/dev/null

echo "--- Building Topology ---"
# Create containers with no networking
docker run -itd --name hs1 --privileged --net none alpine sh
docker run -itd --name rt1 --privileged --net none alpine sh
docker run -itd --name hs2 --privileged --net none alpine sh

# Create veth pairs
sudo ip link add veth-hs1 type veth peer name veth-rt1-e1
sudo ip link add veth-hs2 type veth peer name veth-rt1-e2

# Get PIDs for namespace attachment
pid_hs1=$(docker inspect -f '{{.State.Pid}}' hs1)
pid_rt1=$(docker inspect -f '{{.State.Pid}}' rt1)
pid_hs2=$(docker inspect -f '{{.State.Pid}}' hs2)

# Move interfaces into containers
sudo ip link set veth-hs1 netns $pid_hs1
sudo ip link set veth-rt1-e1 netns $pid_rt1
sudo ip link set veth-hs2 netns $pid_hs2
sudo ip link set veth-rt1-e2 netns $pid_rt1

echo "--- Configuring IPs & Routes ---"
# Configure Router (rt1)
docker exec rt1 sh -c "
  ip link set veth-rt1-e1 up
  ip link set veth-rt1-e2 up
  ip addr add 192.168.10.1/24 dev veth-rt1-e1
  ip addr add 192.168.20.1/24 dev veth-rt1-e2
  ip -6 addr add 2001:db8:10::1/64 dev veth-rt1-e1
  ip -6 addr add 2001:db8:20::1/64 dev veth-rt1-e2
  sysctl -w net.ipv4.ip_forward=1
  sysctl -w net.ipv6.conf.all.forwarding=1
"

# Configure Host 1 (hs1)
docker exec hs1 sh -c "
  ip link set veth-hs1 up
  ip addr add 192.168.10.2/24 dev veth-hs1
  ip -6 addr add 2001:db8:10::2/64 dev veth-hs1
  ip route add default via 192.168.10.1
  ip -6 route add default via 2001:db8:10::1
"

# Configure Host 2 (hs2)
docker exec hs2 sh -c "
  ip link set veth-hs2 up
  ip addr add 192.168.20.2/24 dev veth-hs2
  ip -6 addr add 2001:db8:20::2/64 dev veth-hs2
  ip route add default via 192.168.20.1
  ip -6 route add default via 2001:db8:20::1
"

echo "Done! Your manual lab is now live.
