# ArchivesSpace

This repo Dockerizes ArchivesSpace. In a nutshell:

```sh
# Populate your local .env file with secrets (e.g. OCLC keys)
cp .env.example .env

# Build the stack
docker compose build

# Run it all
docker compose up -d
```

### Database Initialization

The database is initialized by an "updater" service which simply runs `scripts/setup-database.sh` and exits. Docker should retry it continuously until it succeeds.

### Secrets

We've added an entrypoint.sh shim script which loads files from `/run/secrets` into the environment before running a given command. Secrets can be added there using Docker's normal methods, but read from the application using `ENV`.

### Configuration File

Since ASpace's built-in `ENV['APPCONFIG_']` configuration method doesn't always work (particularly when parsing JSON), we template the config.rb file directly into the image at runtime. You're free to modify that file as you see fit in testing. Note that the version included in this repo is purely for development, and any changes to it in a long-lived environment would need to be coordinated.
