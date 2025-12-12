Simple flake to set up postgres in current directory. No need to set up postgres globally on your NixOS for a single project anymore.

Checks if the port is open before starting the shell or creating the database data directory.

# Get to the shell and set up the db:
```
nix develop
# or
direnv allow
```

# Start Postgres process
```
nix run &
# or
postgres &
```

# Kill Postgres process
```
pg_ctl -D ./db stop
```
