# holbertonschool.com - Recon Notes

## IP Ranges

- `35.180.27.154` — AWS EC2, eu-west-3, Paris
- `52.47.143.83` — AWS EC2, eu-west-3, Paris (yriry2.holbertonschool.com)
- `198.202.211.1` — current A record

## DNS

- NS: AWS Route 53
- MX: Google Workspace

## Open Ports

- `35.180.27.154`: 80
- `52.47.143.83`: 80, 443

## Technologies & Frameworks

- nginx/1.18.0 (Ubuntu) — 35.180.27.154
- nginx/1.21.6 — 52.47.143.83
- Discourse — yriry2.holbertonschool.com (Level2 Forum)
- Let's Encrypt — TLS (TLSv1.2, TLSv1.3)
- AWS EC2 — all hosts
- AWS Route 53 — DNS
- Google Workspace — email

## Security Headers (yriry2.holbertonschool.com)

- X-Frame-Options: SAMEORIGIN
- X-Content-Type-Options: nosniff
- X-Download-Options: noopen
- X-XSS-Protection: 0
