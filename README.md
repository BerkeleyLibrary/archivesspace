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

### _toolbar.html.erb override

We are overriding the resources/_toolbar.html.erb view so the numbered_cs option is checked for resource EAD export. There is a check in the build.yml to 
ensure the checksum for the Aspace _toolbar.html.erb hasn't changed if we upgrade Aspace versions. If it does the build will fail. If it fails for that reason the
files/plugins/local/frontend/views/resources/_toolbar.html.erb file (override file) will need to be updated to reflect the new toolbar (frontend/app/views/resources/_toolbar.html.erb).

### Configuration File

Since ASpace's built-in `ENV['APPCONFIG_']` configuration method doesn't always work (particularly when parsing JSON), we template the config.rb file directly into the image at runtime. You're free to modify that file as you see fit in testing. Note that the version included in this repo is purely for development, and any changes to it in a long-lived environment would need to be coordinated. Any long lived configuration changes should be made in the docker swarm stack file. Those values will override what's in the config.rb. 

## Release and Deployment

ASpace releases are tagged according the semver version of the underlying ArchivesSpace release followed by a monotonically increasing internal version suffix:

| Git Tag  | ASpace Version | Internal Version | Image Tags             |
| -------- | -------------- | ---------------- | ---------------------- |
| 4.1.1    | 4.1.1          | N/A              | 4.1.1, 4.1, 4          |
| 4.1.1-1  | 4.1.1          | 1                | 4.1.1-1, 4.1.1, 4.1, 4 |
| 4.1.2-1  | 4.1.2          | 1                | 4.1.2-1, 4.1.2, 4.1, 4 |
| 4.1.2-2  | 4.1.2          | 2                | 4.1.2-2, 4.1.2, 4.1, 4 |
| 4.2.1-1  | 4.2.1          | 1                | 4.2.1-1, 4.2.1, 4.2, 4 |

Follow these guidelines when crafting a release:

1. If the underlying ASpace version changes, update the first part of the tag accordingly.
2. Omit the suffix when creating the first release of a given ASpace version with no additional Library IT customizations.
3. Start the suffix at 1 when making changes that maintain a given ASpace version.
4. Increment the suffix by 1 when making additional changes of the same ASpace version.

### Tracked Image Tags

ASpace follows Library IT's typical latest and major version tracking process:

- Staging: `:latest` (merges to the main branch)
- Production: `:4` (any 4.x release, including those with `-{internal_version}` suffixes.

That is, merging to the main branch triggers a staging deployment, while creating a `4.x` release triggers a production deployment.
