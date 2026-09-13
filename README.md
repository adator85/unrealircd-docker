# UnrealIRCd Docker

Docker image for running an [UnrealIRCd](https://www.unrealircd.org/) IRC server (v6.2.7) based on Alpine Linux.

## Quick Start

```bash
docker compose up -d
```

## Build

```bash
docker build -t unrealircd:latest .
```

## Ports

| Port | Protocol | Description |
|------|----------|-------------|
| 6667 | TCP | IRC (plaintext) |
| 6697 | TCP | IRC over SSL/TLS |

## Volumes

The following volumes are mounted for persistence:

| Container Path | Host Path | Description |
|----------------|-----------|-------------|
| `/home/ircd/unrealircd/conf` | `./volumes/conf` | Configuration files |
| `/home/ircd/unrealircd/data` | `./volumes/data` | Persistent data |
| `/home/ircd/unrealircd/cache` | `./volumes/cache` | Cache |
| `/home/ircd/unrealircd/tmp` | `./volumes/tmp` | Temporary files |
| `/home/ircd/unrealircd/logs` | `./volumes/logs` | Log files |

## First Run

On first startup, if `volumes/conf/unrealircd.conf` is missing, the entrypoint copies a default configuration and exits with an error. **You must edit `volumes/conf/unrealircd.conf`** before starting the server:

```bash
# Start once to generate default config (it will exit with an error)
docker compose up -d

# Stop the container
docker compose down

# Edit the configuration file
nano volumes/conf/unrealircd.conf

# Start again
docker compose up -d
```

## Compose Example

```yaml
services:
  unrealircd:
    image: unrealircd:latest
    container_name: unrealircd-server
    restart: unless-stopped
    ports:
      - "6667:6667"
      - "6697:6697"
    volumes:
      - ./volumes/conf:/home/ircd/unrealircd/conf
      - ./volumes/data:/home/ircd/unrealircd/data
      - ./volumes/cache:/home/ircd/unrealircd/cache
      - ./volumes/tmp:/home/ircd/unrealircd/tmp
      - ./volumes/logs:/home/ircd/unrealircd/logs
```

## Configuration

Edit `volumes/conf/unrealircd.conf` to customize your server. The provided config includes:

- Server name: `irc.local.org`
- Ports: 6667 (plain), 6697 (TLS), 6901 (server links)
- Oper user: `adator` (password hash in config)
- WebSocket on port 8006
- JSON-RPC API on port 8600

## Stop

```bash
docker compose down
```
