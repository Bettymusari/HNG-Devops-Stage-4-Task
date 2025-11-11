# 🏗️ Building a VPC From Scratch on Linux  
### (HNG DevOps Internship – Stage 4 Task)

This project recreates the core functionality of a cloud VPC (like AWS VPC) using **only Linux primitives**:

- Network namespaces  
- veth pairs  
- Linux bridges  
- Routing tables  
- NAT using iptables  

Then I wrapped everything into a **CLI tool** called `vpcctl` to automate VPC creation, subnet provisioning, NAT, peering, and cleanup.

---

## ✅ What I Built

I designed and implemented:

| Feature | Description |
|---------|-------------|
| **VPC & Subnet creation** | Creates bridges + namespaces for public/private subnets |
| **Routing** | Configures routing tables per namespace |
| **NAT Gateway** | Allows internet access from public subnet via `eth0` |
| **VPC Peering** | Enables traffic between two VPCs |
| **Security Groups** | JSON-based ingress firewall rules (iptables) |
| **Full Cleanup** | Removes all bridges, namespaces, veth pairs, NAT rules |

---

## 🏗️ Architecture Flow

vpcctl (CLI)
↓
/lib scripts
↓
───────────────────────────────────────────
Creates:
✔ Bridges (br-<vpc>)
✔ Namespaces (ns-<subnet>)
✔ veth pairs (veth-<shortened>)
✔ Routing tables + NAT
✔ Firewall rules (per subnet)
───────────────────────────────────────────

---

## 📁 Project Structure

vpc-project/
├── bin/
│ └── vpcctl # Main CLI controller
├── lib/
│ ├── create.sh # VPC creation
│ ├── subnet.sh # Subnet creation
│ ├── nat.sh # NAT / internet access
│ ├── peer.sh # VPC peering
│ ├── firewall.sh # Security groups via JSON config
│ ├── list.sh # Resource listing
│ └── cleanup.sh # Complete teardown
├── configs/
│ └── web-server-policy.json # Example firewall rules
└── README.md


---

## 🧪 Commands I Used (Exact Steps)

### ✅ Create VPC + Subnets
```bash
sudo ./bin/vpcctl create myfirstvpc 10.0.0.0/16
sudo ./bin/vpcctl add-subnet myfirstvpc public 10.0.1.0/24
sudo ./bin/vpcctl add-subnet myfirstvpc private 10.0.2.0/24
sudo ./bin/vpcctl nat myfirstvpc
sudo ./bin/vpcctl list

✅ Peering Two VPCs
sudo ./bin/vpcctl create secondvpc 10.1.0.0/16
sudo ./bin/vpcctl add-subnet secondvpc public 10.1.1.0/24
sudo ./bin/vpcctl peer myfirstvpc secondvpc

✅ Apply Security Group Rules
sudo ./bin/vpcctl firewall myfirstvpc configs/web-server-policy.json

✅ Full Cleanup

sudo ./bin/vpcctl cleanup
🔥 Advanced Features Implemented
Feature	Result
Interface name auto-shortening	Avoids Linux 15-char limit
Proper subnet isolation	Private subnet cannot reach internet
Peering route control	VPCs only communicate after peering
Aggressive cleanup	No leftover veth or bridges

🧠 Problems I Faced & Solutions
Problem	Fix
veth names too long	Added auto-truncate logic → veth-myf-pub-h
Subnets not communicating	Added correct routes into bridge
VPCs communicating without peering	Blocked via iptables
Cleanup left dangling interfaces	Wrote recursive teardown logic

🔒 Firewall Policy Example (configs/web-server-policy.json)

{
  "subnet": "10.0.1.0/24",
  "ingress": [
    {"port": 80, "protocol": "tcp", "action": "allow"},
    {"port": 8080, "protocol": "tcp", "action": "allow"},
    {"port": 22, "protocol": "tcp", "action": "deny"},
    {"port": 443, "protocol": "tcp", "action": "allow"}
  ]
}
✅ Test Results (Validation)
Test	Status
Public → Internet (NAT)	✅
Private → Internet	❌ (expected)
Peering between VPCs	✅
Ping within VPC subnets	✅
Security group applied	✅

🧠 What I Learned
How VPCs actually work behind AWS/GCP/Azure

Deep understanding of Linux networking

Bash automation & debugging network failures

Designing tools that self-clean resources (like Terraform destroy)

Requirements
Linux (tested on Ubuntu)

sudo access

Tools: ip, iptables, bridge-utils, jq

Python3 (optional for web server testing)

📄 License
MIT — free for learning, modifying, and experimentation.

---

## 📸 Evidence (Screenshots)
All execution screenshots are available in the `/screenshots` folder.

---

## 🧠 Key Learnings
- Cloud networking is abstraction built on Linux networking fundamentals.
- AWS VPC is not magic — it’s bridges, routes, namespaces, NAT, and firewall rules under the hood.
- I now understand what actually happens when clicking **“Create VPC”** in a cloud console.

---

## 🏁 Final Summary
This project successfully demonstrates:

✅ Linux networking (namespaces, bridges, routing, NAT)  
✅ VPC isolation and peering implementation  
✅ Shell scripting and automation  
✅ Subnet security and controlled internet access  

---

⭐ If you found this useful, please give the repo a star!

--

## 👩‍💻 Author
**Betty Musari** (HNG DevOps Internship – Stage 4 Task)

🔗 **Hashnode Blog:** https://hashnode.com/@bettymusari  
🔗 **GitHub Repo:** https://github.com/Bettymusari/HNG-Devops-Stage-4-Task

"I didn’t just learn VPC — I built one."
