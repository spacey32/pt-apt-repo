# Pillarium Apt Repository

Signed apt repository for Pillarium packages (spacer-greeter, cadet, pillarium).

## Add the repository

```
curl -fsSL https://spacey32.github.io/pt-apt-repo/install.sh | sudo bash
```

Then install packages:

```
sudo apt install spacer-greeter cadet pillarium
```

## Manual setup

If you prefer to add it by hand (fixes `NO_PUBKEY` errors):

```
curl -fsSL https://spacey32.github.io/pt-apt-repo/dists/stable/pillarium-repo.gpg.key \
    | gpg --dearmor \
    | sudo tee /usr/share/keyrings/pillarium-repo.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/pillarium-repo.gpg] https://spacey32.github.io/pt-apt-repo stable main" \
    | sudo tee /etc/apt/sources.list.d/pillarium.list >/dev/null
sudo apt update
```

If you still see `NO_PUBKEY`, check that the `[signed-by=...]` path points at the
dearmored keyring above (not the raw ASCII key) and that the `apt update` output
shows the repository being fetched without key warnings.