# do.bash

Build and automation system written in Bash

## Usage

Add this repository as a submodule inside your project, for Go projects we recommend adding it under the `_do` folder since the go tool will ignore anything under a folder with underscore prefix.

```bash
git submodule add https://github.com/divoxx/do.bash.git _do
```

Create a do.bash file, which will define the configuration and serve as an executable entry point to the build tool. Here is an example configuration file:

```bash
#!/usr/bin/env bash

# Detect current file's path
_dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" && pwd )"

# Config
export APP_NAME="my-app"
export PACKAGE="github.com/doximity/auth-api"
export RELEASE_S3_S3CFG="${_dir}/_misc/s3cfg"
export RELEASE_S3_BUCKET="my-app.releases"

# Production deployment
export PROD_DEPLOY_HOSTS="deploy@ds1321.bbg deploy@ds745.sea03"
export PROD_DEPLOY_PATH="/srv/data/apps/${APP_NAME}_production"
export PROD_DEPLOY_PLATFORM="linux_amd64"

function do_build {
  # run any commands necessary to build your binary
  # $1 is the location where the binary should be placed
  go build -o "${1}"
}

# Dispatching to the library
source "${_dir}/_do/lib/dispatch.bash"
dispatch "${@}"
```

Make sure `do.bash` is an executable:

```bash
chmod a+x do.bash
./do.bash
```

### Config Variables

`APP_NAME`
`*_DEPLOY_PATH`
`*_DEPLOY_HOSTS`
`*_DEPLOY_PLATFORM`
`RELEASE_S3_S3CFG`
`RELEASE_S3_BUCKET`
