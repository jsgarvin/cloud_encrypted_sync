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

Example
    ces --adapter=s3 --bucket=my-backup-bucket --s3-credentials=ACCESS_KEY_ID,SECRET_ACCESS_KEY --encryption-key=MYENCRYPTIONKEY --initialization-vector=VALIDINITIALIZATIONVECTOR

## Configuration

Configuration options may be passed to CES via the command line, or via a config yaml file.

The default location for the config file is `your-home-directory/.cloud_encrypted_sync/config.rc.yml

#TODO  Add list of accepted config options

## Creating additional adapters


