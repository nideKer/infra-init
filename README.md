# infra-init

Bootstrap scripts for quickly preparing new Debian/Ubuntu servers (DevOps tools, Docker, user shell config, basic hardening).

---

## 1. Initial setup on a fresh server

> First login on a new Debian/Ubuntu server: follow the steps in order.

### 1.1. Login as `root`

Login as `root` (via console or SSH), then:

If you switch to root using `su`, use `su -` to get the proper root environment (PATH, /usr/sbin, etc.) before running commands like usermod.

```bash
apt-get update && apt-get install -y sudo git
```

This installs `sudo` and `git` so you can bootstrap everything from a non-root user.

---

### 1.2. Create an admin user and add to `sudo`

Replace `USERNAME` with your actual admin username (for example, `ndk`, `admin`, `devops`, etc.):

```bash
adduser USERNAME
usermod -aG sudo USERNAME
```

Optionally add an SSH key for this user so you don’t use password logins:

```bash
mkdir -p /home/USERNAME/.ssh
chmod 700 /home/USERNAME/.ssh
nano /home/USERNAME/.ssh/authorized_keys   # paste your public key here
chmod 600 /home/USERNAME/.ssh/authorized_keys
chown -R USERNAME:USERNAME /home/USERNAME/.ssh
```

Then exit the `root` session:

```bash
exit
```

Reload SSH session

---

### 1.3. Clone infra-init and run bootstrap

Log in as the new admin user:

```bash
ssh USERNAME@your-server
```

Clone the repo and run the main init script:

```bash
git clone https://your.git.server/infra-init.git
cd infra-init
sudo ./init.sh
```

What `init.sh` does:

* runs base common setup (for example, disables IPv6 via `sysctl`),
* runs OS-specific setup if `os/$ID/$VERSION_ID/base.sh` exists,
* installs common DevOps tools (mc, htop, git, curl, etc.),
* installs and configures Docker,
* creates `/opt/repo` owned by your user,
* runs `bootstrap_user.sh` for the calling user (bashrc, aliases, gitconfig, ssh config).
* set system timezone Europe/Kyiv and enables NTP (check by `timedatectl`)

After this, the host is ready for role-specific configuration or application deployment.

After bootstrap, configure your Git identity:
Global personal identity (for GitHub):

  ```bash
  git config --global user.name "Your Name"
  git config --global user.email "you@gmail.com"
```

Or per-repo identity (for company / client repos):

```bash
cd /path/to/repo
git config user.name "Your Name"
git config user.email "dev@gmail.com"
```

---

### 1.4. (Optional) Set hostname

If you want to change the hostname:

```bash
sudo hostnamectl set-hostname my-hostname
```

Optionally add it to `/etc/hosts`:

```bash
sudo nano /etc/hosts
# 192.168.0.22   my-hostname
```

---

## 2. SSH hardening (optional but recommended)

Once you have:

* a working `sudo` user, and
* confirmed SSH key-based login works for that user,

…you can apply SSH hardening.

The hardening snippet is stored in `common/conf/sshd-hardening.conf` and is applied by a helper script.

### 2.1. Apply SSH hardening

From the repo root:

```bash
cd infra-init
sudo ./init_ssh_hardening.sh
```

The script will:

* install the hardening snippet into `/etc/ssh/sshd_config.d/10-infra-hardening.conf`,
* run `sshd -t` to validate configuration,
* reload the SSH daemon if the config is valid.

> **Important:** Do not close your current SSH session yet.
>
> Open a new terminal and check that you can log in again via SSH as your non-root user. Only after that is confirmed, it’s safe to close the old session.

The hardening typically enforces:

* Protocol 2 only,
* `PermitRootLogin no` (no direct root login),
* key-only auth (`PasswordAuthentication no`),
* disabled X11 forwarding, tightened idle client handling, and some safe defaults.

If you want to change the SSH port (e.g. from `22` to `5022`), edit `common/conf/sshd-hardening.conf` (the `Port` line) and run `sudo ./ssh_hardening.sh` again.

---

## 3. Setup static IP & DNS (reference)

This section is for servers where you want a static IP and manually managed DNS.

### 3.1. Check interfaces and routes

Useful `ip` commands (modern replacement for `ifconfig`/`route`):

```bash
# all interfaces, compact
ip -brief link

# all addresses, compact
ip -brief addr

# detailed info for one interface
ip addr show dev ens192

# routing table (default gateway, routes)
ip route
```

---

### 3.2. Configure static IP (`/etc/network/interfaces`)

Edit the interfaces file:

```bash
sudo nano /etc/network/interfaces
```

Example static config:

```bash
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

source /etc/network/interfaces.d/*

# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
allow-hotplug ens192
auto    ens192
iface   ens192 inet static
    address 192.168.0.25
    netmask 255.255.255.0
    gateway 192.168.0.1
    dns-nameservers 192.168.0.1 1.1.1.1
```

Apply changes (or reboot) to get the new address.

---

### 3.3. Set DNS

For a simple static DNS setup, you can manage `/etc/resolv.conf` directly:

```bash
sudo bash -c 'cat >/etc/resolv.conf <<"EOF"
# Static resolv.conf
nameserver 192.168.0.2
nameserver 1.1.1.1
options timeout:2 attempts:3
EOF'
```

Verify DNS:

```bash
cat /etc/resolv.conf
ping -c3 security.debian.org
```

If DNS works and you previously had a DHCP client managing DNS (like `dhcpcd`), you can disable it (if present):

```bash
sudo systemctl stop dhcpcd || sudo systemctl stop dhcpcd5 || true
sudo systemctl disable dhcpcd || sudo systemctl disable dhcpcd5 || true
```

If these units do not exist on your system, the commands will print an error and continue; this is safe to ignore.
