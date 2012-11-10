# Cloud Encrypted Sync

Cloud Encrypted Sync (CES) is a command line tool distributed as a Ruby gem for syncing a local
folder to cloud storage via external adapters, with localy managed encryption (you control the
keys).

Even though you could simply use CES to backup a local folder to the cloud, it's original
intended purpose is to sync a folder across multiple computers, so it should work for that,
too.

## Installation

    gem install cloud_encrypted_sync

In addition to this gem you'll also need to install an adapter gem for the particular cloud
you want to backup to.  At the time of this writing, the only available adapter is for Amazon
S3, although anyone can create an adapter to work with other clouds. Search rubygems.org for
"cloud encrypted sync" to find out if someone has already created an adapter for your
preferred cloud.

## Getting started

CES runs as a command line tool and takes options as CLI arguments and/or from a config file.
Arguments passed at the command line take precedence over those in the config file.

### Creating a valid encryption key and initialization vector.

TODO

### Example

    ces --adapter=s3 --bucket=my-backup-bucket --s3-credentials=ACCESS_KEY_ID,SECRET_ACCESS_KEY --encryption-key=MYENCRYPTIONKEY --initialization-vector=VALIDINITIALIZATIONVECTOR

## Configuration

Configuration options may be passed to CES via the command line, or via a config yaml file.

The default location for the config file is `~/.cloud_encrypted_sync/config.rc.yml`

### Available Settings

CES requires the following configuration settings. Any of thse may alternatively be placed in
the `config.rc.yml` execpt for `--data-dir` (which tells CES which folder contains the config
file to use).

* `--adapter=ADAPTERNAME` The name of the adapter to use. See instructions for your preferred
adapter for instructions of what to place here.
* `--encryption-key=XXX`  The encryption key (shocking, I know).
* `--initialization-vector=III` Initialization vector to use for encryption.

In addition to these settings, your chosen adapter will probably also have additional adapter
specific settings as well, such as credentials to log into your cloud storage account. Adapter
specific settings may work the same the the above standard settings in that they may be included
on the command or in the `config.rc.yml` file (unless the adapter author breaks convention and
tries to do something weird).

## Creating your own adapter

TODO
