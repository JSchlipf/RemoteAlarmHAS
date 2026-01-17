# RemoteAlarmHAS

Home Assistant on BalenaCloud with nginx reverse proxy and SSH access.

## Overview

This project sets up Home Assistant on BalenaCloud with:
- **nginx** as a reverse proxy to access Home Assistant via public URL
- **code-server** (VS Code in the browser) accessible via `/code/` path
- **SSH access** for device management

## Project Structure

```
.
├── docker-compose.yml    # Docker Compose configuration
├── balena.yml            # Balena-specific configuration
├── nginx/
│   └── nginx.conf        # nginx reverse proxy configuration
└── homeassistant/
    └── Dockerfile        # Home Assistant Dockerfile
```

## Setup Instructions

### 1. Prerequisites

- A BalenaCloud account
- Balena CLI installed (`npm install -g balena-cli`)
- Your device added to BalenaCloud

### 2. Deploy to BalenaCloud

1. **Create a new application** in BalenaCloud dashboard
2. **Add your device** to the application
3. **Push this repository** to BalenaCloud:

```bash
balena push <app-name>
```

Or if you've already initialized the git remote:

```bash
git remote add balena <your-balena-git-url>
git push balena main
```

### 3. Enable Public Device URL

1. Go to your device in the BalenaCloud dashboard
2. Navigate to **Device Configuration**
3. Enable **Public Device URL**
4. This will give you a public URL like: `https://<device-uuid>.balena-devices.com`

The nginx service listens on port 80, which BalenaCloud will expose through the public URL.

### 4. SSH Access Setup

#### Option A: SSH to Containers (SCP Support)

Each container runs an SSH daemon for direct SSH/SCP access:

**Home Assistant Container:**
```bash
# SSH access (uses host network, port 22)
ssh root@<device-ip>
# Default password: root (change via SSH_ROOT_PASSWORD env var)

# SCP file transfer
scp file.yaml root@<device-ip>:/config/
scp root@<device-ip>:/config/configuration.yaml ./
```

**Set SSH Password:**
- Add `SSH_ROOT_PASSWORD=your-password` for Home Assistant container

#### Option B: Using Balena CLI (Device SSH)

1. **Add your SSH public key** to BalenaCloud:
   - Go to **Preferences → SSH Keys** in BalenaCloud dashboard
   - Add your public SSH key

2. **SSH into your device**:
```bash
balena device ssh <device-uuid>
# Or if you're in the app directory:
balena ssh <device-uuid>
```

#### Option C: Direct SSH (Development Mode)

If your device is in development mode, you can SSH directly:

```bash
ssh root@<device-ip> -p 22222
```

**Note**: For production devices, you must use Balena CLI with your SSH key added to BalenaCloud.

### 5. Access Services

Once deployed and the Public Device URL is enabled:

#### Home Assistant
- **Via Public URL**: `http://<device-uuid>.balena-devices.com`
- **Via Local Network**: `http://<device-ip>:80` (nginx) or `http://<device-ip>:8123` (direct to Home Assistant)

#### Code Server (VS Code in Browser)
- **Via Public URL**: `http://<device-uuid>.balena-devices.com/code`
- **Via Local Network**: `http://<device-ip>:8080` (direct to code-server)

**Default Password**: `coder` (change via `CODE_SERVER_PASSWORD` environment variable)

## Configuration

### Timezone

Set your timezone using the `TZ` environment variable in the BalenaCloud dashboard:
- Go to **Device Variables**
- Add: `TZ=America/New_York` (or your timezone)

### Home Assistant Configuration

Home Assistant configuration files are stored in the `homeassistant_data` volume. You can access them via SSH, code-server, or through the BalenaCloud dashboard.

**Important: Reverse Proxy Configuration**

To access Home Assistant through nginx, ensure your `configuration.yaml` includes reverse proxy settings:

```yaml
http:
  use_x_forwarded_for: true
  trusted_proxies:
    - 127.0.0.1
    - ::1
    - 172.17.0.0/16
    - 172.16.0.0/12
```

This configuration should already be present if you've set up Home Assistant through this project. If you need to add it manually, edit `configuration.yaml` via code-server at `/code` or via SSH.

### Code Server Configuration

Code Server (VS Code in the browser) is accessible at `/code/` path through nginx. To change the password:

1. Go to **Device Variables** in BalenaCloud dashboard
2. Add: `CODE_SERVER_PASSWORD=your-secure-password`

Code Server files are stored in the `code-server_data` volume.

### nginx Configuration

The nginx configuration is located in `nginx/nginx.conf`. It:
- Proxies requests to Home Assistant on port 8123 (root path `/`)
- Proxies requests to code-server on port 8080 (path `/code/`)
- Handles WebSocket connections for both Home Assistant and code-server
- Sets appropriate headers for proper proxying

## Troubleshooting

### Public URL not working

1. Ensure nginx service is running: Check in BalenaCloud dashboard
2. Verify port 80 is exposed: Check `docker-compose.yml` or `balena.yml`
3. Check nginx logs: `balena logs nginx-proxy`

### WebSocket issues

If you experience issues with WebSocket connections:
- **Home Assistant**: Verify the `/api/websocket` location block in `nginx/nginx.conf`
- **Code Server**: Verify the `/code/ws` location block in `nginx/nginx.conf`
- Check that `proxy_set_header Upgrade` and `Connection` headers are set for both services

### Code Server not accessible

1. Ensure code-server service is running: Check in BalenaCloud dashboard
2. Verify you're accessing it at `/code` path (with or without trailing slash)
3. Check code-server logs: `balena logs code-server`
4. Verify the password is set correctly via `CODE_SERVER_PASSWORD` environment variable
5. Access code-server at `/code/` path (with trailing slash)

### SSH connection issues

1. Ensure your SSH key is added to BalenaCloud
2. For production devices, use `balena ssh` command
3. Check device is online in BalenaCloud dashboard

### mDNS / Device Discovery

mDNS (multicast DNS) is enabled for device discovery (e.g., `.local` hostnames). This is achieved by using `network_mode: host` for all containers, which allows them to receive multicast traffic directly from the network.

**Note**: With host networking:
- All containers share the host's network namespace
- Ports are directly on the host (no port mappings needed)
- Home Assistant SSH is on port 22 (standard)

## Additional Resources

- [BalenaCloud Documentation](https://docs.balena.io/)
- [Home Assistant Documentation](https://www.home-assistant.io/docs/)
- [Code Server Documentation](https://coder.com/docs)
- [nginx Documentation](https://nginx.org/en/docs/)

## License

This project is open source and available under the MIT License.
