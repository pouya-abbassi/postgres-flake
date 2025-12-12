{
  description = "Description for the project";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable"; # 2025-12-12
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        # To import an internal flake module: ./other.nix
        # To import an external flake module:
        #   1. Add foo to inputs
        #   2. Add foo as a parameter to the outputs function
        #   3. Add here: foo.flakeModule

      ];
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
      perSystem = { config, self', inputs', pkgs, system, ... }: {
        # Per-system attributes can be defined here. The self' and inputs'
        # module parameters provide easy access to attributes of the same
        # system.

        apps.default = {
          type = "app";
          program = "${pkgs.postgresql}/bin/postgres";
        };

        devShells.default = pkgs.mkShell {
          nativeBuildInputs = (with pkgs; [
            iproute2
            postgresql
            postgresql.pg_config
          ]);
          shellHook = ''
            # init the db with
            export PGDATA="$(pwd)/db"
            export PGHOST="$(pwd)"
            export PGPORT="5432"
            export PGDB="db"
            export PGUSER="dbuser"
            export PGPASS="11223344"

            if [[ $(ss -ln | grep $PGPORT) ]]; then
               echo "Port '$PGPORT' is in use." && exit 1
            fi

            if [[ ! $(grep listen_addresses $PGDATA/postgresql.conf) ]]; then
              echo "db does not exist, creating "
              initdb -D $PGDATA --no-locale --encoding=UTF8

              echo "listen_addresses = 'localhost'" >> $PGDATA/postgresql.conf
              echo "port = $PGPORT" >> $PGDATA/postgresql.conf
              echo "unix_socket_directories = '$PGHOST'" >> $PGDATA/postgresql.conf

              # ...create a user and database for the project.
              echo "CREATE USER $PGUSER WITH PASSWORD '$PGPASS';" | postgres --single -E postgres
              echo "CREATE DATABASE $PGDB WITH OWNER $PGUSER" | postgres --single -E postgres
              echo "GRANT ALL PRIVILEGES ON SCHEMA public TO $PGUSER" | postgres --single -E postgres
            fi

            ## Command to run postgres as an app
            # postgres &

            ## command to access the db after start
            # psql -h localhost dbuser # or postgres

            ## command to kill the db
            # pg_ctl -D ./db stop

            # trap "pg_ctl -D ./db stop" EXIT
          '';
        };
      };
      flake = {
        # The usual flake attributes can be defined here, including system-
        # agnostic ones like nixosModule and system-enumerating ones, although
        # those are more easily expressed in perSystem.

      };
    };
}
