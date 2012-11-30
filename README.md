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
you want to backup to.  At the time of this writing, the author has provided two adapters, one
for Amazon S3 ([cloud_encrypted_sync_s3_adapter](https://github.com/jsgarvin/cloud_encrypted_sync_s3_adapter))
and one for local filesystems ([clound_encrypted_sync_filesystem_adapter](https://github.com/jsgarvin/cloud_encrypted_sync_filesystem_adapter))
which has been tested to work with [Ubuntu One](https://one.ubuntu.com/referrals/referee/2304745/)
and [Dropbox](http://db.tt/X7KUvsGn "Dropbox") folders, and should work well with any other cloud
storage service that uses similar "magic" folders on the local file system. In addition, anyone can
create an adapter to work with other clouds. Search rubygems.org for "cloud encrypted sync" to find
out if someone has already created an adapter for your preferred cloud.

## Getting started

CES runs as a command line tool and takes options as CLI arguments and/or from a config file.
Arguments passed at the command line take precedence over those in the config file.

### Example (assuming CES S3 Adapter gem is installed)

    ces --adapter s3 \
      --s3-bucket my-backup-bucket \
      --s3-access-key-id ACCESS_KEY_ID \
      --s3-access-id SECRET_ACCESS_KEY \
      --encryption-key MYENCRYPTIONKEY \
      /path/to/source/folder

## Configuration

Configuration options may be passed to CES via the command line, or via a config yaml file.

The default location for the config file is `~/.cloud_encrypted_sync/config.rc.yml`

### Available Settings

CES requires the following configuration settings. Any of these may alternatively be placed in
the `config.rc.yml` except for `--data-dir` (which tells CES which folder contains the config
file to use).

* `--adapter ADAPTERNAME` The name of the adapter to use. See instructions for your preferred
adapter for instructions of what to place here.
* `--encryption-key XXX`  The encryption key (shocking, I know).

In addition to these settings, your chosen adapter will probably also have additional adapter
specific settings as well, such as credentials to log into your cloud storage account. Adapter
specific settings may work the same the the above standard settings in that they may be included
on the command or in the `config.rc.yml` file (unless the adapter author breaks convention and
tries to do something weird).

## Creating your own adapter

To create your own adapter to a cloud storage service, you'll need to do the following.

* Create a Ruby Gem named `cloud_encrypted_sync_*_adapter` where `*` is the name of your adapter.
  It is recommended that you name your adapter after the cloud service that it interfaces to.
  (eg. cloud_encrypted_sync_s3_adapter ). CES will not be able to find and load your adapter
  unless it precisely matches this naming convention.
* Your gem needs to provide a class within the `CloudEncryptedSync::Adapters` namespace that
  inherites from `Template`. The name of this class will determine the value that users pass with
  `--adaper` on the command line to select your adapter.  For instance, if you name your class
  `MySuperDooperAdapter`, then users will need to pass `--adapter my_super_dooper_adapter` at the
  command line to select your adapter.
* See the [Baseline](https://github.com/jsgarvin/cloud_encrypted_sync_baseline_adapter/blob/master/lib/baseline/adapter.rb)
  class in [cloud_encrypted_sync_baseline_adapter](https://github.com/jsgarvin/cloud_encrypted_sync_baseline_adapter "Cloud Encrypted Sync Baseline Adapter")
  for a list of methods that your adapter class needs to respond to, what arguments they need to
  accept, and what values they're expected to return.

Note: [cloud_encrypted_sync_baseline_adapter](https://github.com/jsgarvin/cloud_encrypted_sync_baseline_adapter "Cloud Encrypted Sync Baseline Adapter")
is a forkable repository that should make the above steps easier. Simply fork it, rename it,
update it as necessary, and push it to rubygems.org.

### Testing your adapter locally before publishing to rubygems.org

It is likely that, before publishing your new adapter to rubygems.org, you'll want to build and
install your gem locally to test it with CES. When you do this you'll also want to have the CES
gem itself built and installed locally, rather than installed from rubygems.org. It has been found
that when CES has been installed from rubygems.org, it is unable to find and load locally built
adapters, and visa-versa. The CES author is very interested in any patches that provide an elegant
solution to this annoyance.

[![Code Climate](https://codeclimate.com/badge.png)](https://codeclimate.com/github/jsgarvin/cloud_encrypted_sync)