---
layout: default
title: "Vendor SFTP Test Server"
---

# Vendor SFTP Test Server

A Dockerized SFTP server that simulates the vendor's file-receiving endpoint.
The embossing service uploads encrypted `.gpg` files here after generation.

## Quick start

```bash
cd vendor-sftp-test

# Generate stable host keys (first time only)
mkdir -p host-keys
ssh-keygen -t ed25519 -f host-keys/ssh_host_ed25519_key -N ""
ssh-keygen -t rsa -b 4096 -f host-keys/ssh_host_rsa_key -N ""

# Start the SFTP server
docker compose up -d
```

The server listens on **localhost:2222** with credentials:

| Setting  | Value       |
|----------|-------------|
| Host     | localhost   |
| Port     | 2222        |
| Username | embossing   |
| Password | embossing   |
| Remote   | /upload     |

## Enable transmission in the embossing service

The v2 pipeline reads `embossing.transmission.sftp` from `application.yml`.
Local defaults already point at this server. Turn transmission on with:

```
EMBOSSING_SFTP_ENABLED=true
```

## Verify uploaded files

Uploaded embossing files appear on the host at:

```
vendor-sftp-test/sftp-data/
```

You can also connect manually:

```bash
sftp -P 2222 embossing@localhost
> ls /upload
> exit
```

## Stop

```bash
docker compose down
```

## Notes

- `sftp-data/` and `host-keys/` are gitignored.
- Host key verification is disabled by default in the embossing service for dev
  (`strict-host-key-checking: false`). Enable it in production.
