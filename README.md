# ArchivesSpace

This repo Dockerizes ArchivesSpace. In a nutshell:

```sh
# Populate your local .env file with secrets (e.g. OCLC keys)
cp .env.example .env

# Build the stack / pull dependencies
docker compose build
docker compose pull

# Run it all
docker compose up --wait

# Open ASpace in your browser
open http://localhost:8080
```

For ArchivesSpace v4+, consult their excellent [new documentation site](https://docs.archivesspace.org/).

### Database Initialization

* The database is initialized by an "updater" service which simply runs `scripts/setup-database.sh` and exits. Docker should retry it continuously until it succeeds.
* To test migrations with real data, add a dump to the `db/dumps/` directory. The updater still runs against this, making it helpful for testing whether your data will survive a migration.

### Secrets

We've added a `docker-entrypoint.sh` shim script which loads files from `/run/secrets` into the environment before running a given command. Secrets can be added there using Docker's normal methods, but read from the application using `ENV`.

### Configuration File

Since ASpace's built-in `ENV['APPCONFIG_']` configuration method doesn't always work (particularly when parsing JSON), we template the config.rb file directly into the image at runtime. You're free to modify that file as you see fit in testing. Note that the version included in this repo is purely for development, and any changes to it in a long-lived environment would need to be coordinated.
