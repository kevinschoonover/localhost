The external disk (exFAT, UUID `86E8-882E`) is mounted at `/opt/appdata` by
`fileSystems."/opt/appdata"` in `modules/hosts/honeypot/hardware-configuration.nix`.
Docker waits for that mount (`RequiresMountsFor`), so the containers never start
against the empty directory underneath it.

If the disk was attached after boot, mount it and recreate the stack so every
container binds the real disk:

```bash
sudo systemctl start opt-appdata.mount
docker compose up -d --force-recreate
```
