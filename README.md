# asdf-mongodb-tools

[SonarScanner CLI](https://github.com/SonarSource/sonar-scanner-cli) plugin for [asdf](https://github.com/asdf-vm/asdf) version manager

## Install (pre-0.16.0)

```
asdf plugin-add sonar https://github.com/exzeo-devops/asdf-sonar.git
```

## Install (> 0.16.0)

```
asdf plugin add sonar https://github.com/exzeo-devops/asdf-sonar.git
```

### Environment Variable Options

- ASDF_SONAR_OVERWRITE_ARCH: force the plugin to use a specified processor architecture rather than the automatically detected value. Useful, for example, for allowing users on M1 Macs to install `amd64` binaries when there's no `arm64` binary available.

## Use

Check out the [asdf](https://github.com/asdf-vm/asdf) readme for instructions on how to install and manage versions of SonarScanner CLI.
