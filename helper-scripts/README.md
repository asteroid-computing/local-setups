# Various Scripts

## dockerclilatest.sh

This script installs and/or updates Docker CLI tools for local development on macOS. It checks for the latest versions of the Docker CLI, Buildx plugin, Docker Compose plugin, and Docker MacOS credentials helper, and updates them if necessary. The script is designed to ensure your Docker tooling is up to date and ready for use.

### Usage

```sh
./dockerclilatest.sh [OPTIONS]
```

#### Options

- `-p`, `--install-path PATH` Specify the install path for Docker CLI tools (default: `~/.astrocompute/bin`)
- `-h`, `--help` Show help message and exit

The script will print the current and latest versions of each tool, and update them if they are out of date.
