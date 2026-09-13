# UnrealIRCd Docker

Docker image for running an [UnrealIRCd](https://www.unrealircd.org/) IRC server (v6.2.7) based on Alpine Linux.

Source: [github.com/adator85/unrealircd-docker](https://github.com/adator85/unrealircd-docker)

## Folder Structure

```
Unrealircd-docker/
├── compose.yml
├── Dockerfile
└── volumes/
    ├── conf/         (auto-generated)
    ├── data/         (auto-generated)
    ├── cache/        (auto-generated)
    ├── tmp/          (auto-generated)
    └── logs/         (auto-generated)
```

## Pull Image

```bash
docker pull adator85/unrealircd:latest
```

## Setup

Create a `volumes` folder in the same location as your `compose.yml` and add the following:

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

## First Run

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

Refer to the [UnrealIRCd Configuration Guide](https://www.unrealircd.org/docs/Configuration) to configure your server.

## Ports

| Port | Protocol | Description |
|------|----------|-------------|
| 6667 | TCP | IRC (plaintext) |
| 6697 | TCP | IRC over SSL/TLS |

## Volumes

| Container Path | Host Path | Description |
|----------------|-----------|-------------|
| `/home/ircd/unrealircd/conf` | `./volumes/conf` | Configuration files |
| `/home/ircd/unrealircd/data` | `./volumes/data` | Persistent data |
| `/home/ircd/unrealircd/cache` | `./volumes/cache` | Cache |
| `/home/ircd/unrealircd/tmp` | `./volumes/tmp` | Temporary files |
| `/home/ircd/unrealircd/logs` | `./volumes/logs` | Log files |

## Execute Commands in a Running Container

```bash
# Reload configuration
docker exec -it unrealircd-server /home/ircd/unrealircd/unrealircd rehash

# Check server status
docker exec -it unrealircd-server /home/ircd/unrealircd/unrealircd status
```

## Stop

```bash
docker compose down
```
