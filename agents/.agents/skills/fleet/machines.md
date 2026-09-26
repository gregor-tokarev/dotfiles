# Machines

Macbook m5 pro - current cockpit
vds.fleet - vpn server located in Amsterdam that passes connection through. 3x-ui with vless and amneziavpn both setup on this server. Vless for bypassing Russia internet restrictions. Public ip: 72.56.80.131. Connect with `ssh vds.fleet` for adding new vpn profiles.

atlas.fleet - Worker, running Omarchy Linux. SSH as `gregor` with `ssh atlas.fleet`; fleet IP `10.8.1.7`. The native Amnezia service is `fleet-amnezia.service`. T3 Code and kache run as persistent user services with lingering enabled.

sokolov.fleet - Worker, NiPoGi mini PC running Ubuntu 26.04.1 LTS. SSH as `gregor` with `ssh gregor@sokolov.fleet`; fleet IP `10.8.1.8`. Its unique Amnezia profile is managed by `fleet-amnezia.service` on interface `fleet0`. Fleet-only SSH is `sshd-fleet.service`; authenticated LAN SSH remains separate. T3 Code listens at `http://sokolov.fleet:3773` under the persistent user service `t3-code.service`; kache uses `kache.service`. User lingering is enabled. MediaTek MT7902 Wi-Fi and Bluetooth use DKMS backports for Linux 7.0, installed under `/usr/src/mt7902*`; review/remove those backports when moving to a kernel with native MT7902 support. Worker firewall policy is `/etc/fleet/firewall.nft`; VDS also blocks workers from initiating connections to cockpit VPN addresses.
