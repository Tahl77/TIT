                    Internet
                        │
                        ▼
              ┌─────────────────┐
              │   EC2 Instance  │
              │  (Nginx Proxy)  │  ◄── Single t3.micro (Free Tier)
              │   + Web Apps    │
              └─────────────────┘
                        │
                        ▼
              ┌─────────────────┐
              │   RDS MySQL     │  ◄── db.t3.micro (Free Tier)
              │   (Free Tier)   │
              └─────────────────┘

EC2 t3.micro:     $0.00/month (Free Tier)
RDS db.t3.micro:  $0.00/month (Free Tier)
EBS 20GB:         $0.00/month (Free Tier)
Data Transfer:    $0.00/month (Free Tier)
Nginx:            $0.00/month (Open Source)
─────────────────────────────────────────
TOTAL:            $0.00/month              