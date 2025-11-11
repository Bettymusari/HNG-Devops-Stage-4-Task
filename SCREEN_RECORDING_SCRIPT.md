# 5-Minute Screen Recording Script
# VPC Demonstration - BettyM

## Introduction (0:00-0:30)
- [ ] Show terminal and project directory
- [ ] Briefly explain: "I built a complete VPC system from scratch"
- [ ] Show project structure: bin/vpcctl, lib/, configs/

## Demo 1: VPC Creation (0:30-1:30)
- [ ] Run: `sudo ./bin/vpcctl create demo-vpc 10.100.0.0/16`
- [ ] Show successful creation logs
- [ ] Run: `sudo ./bin/vpcctl list`
- [ ] Show the VPC and bridge created

## Demo 2: Subnet Setup (1:30-2:30)
- [ ] Run: `sudo ./bin/vpcctl add-subnet demo-vpc web 10.100.1.0/24 public`
- [ ] Run: `sudo ./bin/vpcctl add-subnet demo-vpc db 10.100.2.0/24 private`
- [ ] Show namespace creation: `ip netns list`
- [ ] Show interfaces: `ip link show | grep veth-`

## Demo 3: Connectivity Testing (2:30-3:30)
- [ ] Test inter-subnet: `sudo ip netns exec ns-demo-web ping -c 2 10.100.2.2`
- [ ] Configure NAT: `sudo ./bin/vpcctl nat demo-vpc`
- [ ] Test internet: `sudo ip netns exec ns-demo-web ping -c 2 8.8.8.8`
- [ ] Show private subnet isolation: `sudo ip netns exec ns-demo-db ping -c 2 8.8.8.8` (should fail)

## Demo 4: Application Deployment (3:30-4:30)
- [ ] Start web server: `sudo ip netns exec ns-demo-web python3 -m http.server 8080 &`
- [ ] Test web server: `sudo ip netns exec ns-demo-web curl -s http://10.100.1.2:8080 | head -5`
- [ ] Apply firewall: `sudo ./bin/vpcctl firewall demo-vpc configs/web-server-policy.json`
- [ ] Show iptables rules: `sudo ip netns exec ns-demo-web iptables -L INPUT -n`

## Demo 5: Cleanup (4:30-5:00)
- [ ] Run cleanup: `sudo ./bin/vpcctl cleanup`
- [ ] Verify cleanup: `ip netns list` (should be empty)
- [ ] Final summary: "Complete VPC lifecycle demonstrated"

## Tips for Recording:
- Speak clearly and explain each step
- Show command output clearly
- Use terminal with good contrast
- Keep within 5-minute limit
- Add text labels if possible
