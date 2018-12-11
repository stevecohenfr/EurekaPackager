# EurekaPackager

## Delivery system with GIT

This script allows you to deliver a tar package or sources on a server.

It will ask you information to confirm those provided in arguments and in the config file

### Prerequisites

- Unix environment with bash 4.* or higher
- git
- ssh and rsync (if used for deploy)

### Install

At your project's root folder :

    git clone -b dev https://github.com/ReaperSoon/EurekaPackager.git

this will download this project's dev branch to EurekaPackager folder (rename it at your ease)

Then, create a 'config.yml' file at your project's root folder

### Usage

#### Command

    $ <path/to/scrips>/EurekaPackager.sh [options]

Available Options:


|                     Option                        |                               Detail                              	|          Required          	            |
|:-------------------------------------------------:|:---------------------------------------------------------------------:|:-----------------------------------------:|
| -c= / --commit=<SHA1 commit>                     	| use the commit sha1 (short or long) to get committed files            |             Yes (no if message provided) 	|
| -m= / --message=<message to search in a commit >  | search a commit using a part of the commit message                	|             Yes (no if commit provided)   |
| -b / --branch                                  	| search branch by a part of it's name and get it's changes. Current if none specified as follows : '-b=word in branch name'            |             Yes (if message or commit not provided) |
| -e= / --env=<env short or full name>             	| Create package for specific environment provided in conf.yml file 	|             no (asked if not provided)    |
| -h / --help                                     	| show help                                                         	|             no             	            |
| -v / --version                                  	| show the script version                                           	|             no             	            |
| -i / --interact                                  	| interactive mode. Not enabled by default                              |             no             	            |
| -vv / --verbose                                  	| verbosity : more information provided during process (in progress)    |             no             	            |
| -p / --pack-only                                  | no deploy, package only                                  	            |             no             	            |
| *(TODO : )-u / --upgrade*                      	| *self upgrade*                                                      	|             no             	            |


commit and message options can be used together and several times :

    $ <path/to/scripts>/EurekaPackager.sh -c=c123 -m=atag -c=c5654789 -m=Create

The branch option can only be used once. Any commit or message options will be ignored.

    $ <path/to/scripts>/EurekaPackager.sh -b -c=c123 -m=atag -c=c5654789 -m=Create

will have same result as

    $ <path/to/scripts>/EurekaPackager.sh -b

and will get the differences between the current branch
and the branch set in 'origin_branch' parameter in config.yml
(if not set, default origin branch is 'master')

#### Configuration

A configuration in a 'config.yml' file is needed.
This file should be located at the project's root location
(or at the same path where the script is executed)

It's organized as follows (a skeleton.yml is provided, to copy, rename as 'confi.yml' and fulfill):

```yaml
parameters:  # all config container
  project:
    name: EUREKA    # The project name. Folder with deliveries will have this name
    target_root: .  # path to the folder where the project's main architecture is located and you want to deliver. '.' if is in the same directory

  delivery:
    folder:
      parent: deliveries # local folder with deliveries (relative to path where the script is executed)
      sources: src       # source 'parent' sub-folder name

    suffix_format: _`date +'%Y%m%d'` # suffix to identify the deliveries
    # Will be also used at the end of the package name (eg: My_Project_yyyymmdd.tar.gz)


    environments:
      list: # List of names of the deploy environnements
        - prod
        - release
        - dev

      prod:                   # each environnement has the following config
        name: Production      # Env full name
        short: p              # shortcut to use in argument or if asked
        suffix: __PROD__      # For env specific lines/files*
        origin_branch: master # (optional :'master' branch by default) for branch packing/deploying : original branch to get differences from. 
        deploy:
          type: src|sources/pkg|package # type of the delivery to deploy
          user:  test                   # user allowed to deploy on server
          host:  localhost              # the host
          pass: ***                     # /!\ not secure and redundant. Use ssh keys instead
          # asked for ssh after/before script execution and rsync
          # this line prints the pass before ssh/rsync commands
          proxy: # proxy needed to acces to the final deploy server by an ssh hop
            user: test
            host: localhost
            pass: # [optional]
          target: /var/www # Target where to deliver the target or sources
          commands: # (optional) lists of commands to execute before
            before_scripts:
              - ls -alh
              - pwd
              - date
            after_scripts : # and after deploy
              - ls -alh
              - date

      release : # The key must be the same as provided in the list
      ...
      dev : # each provided env in list property must have it's config
      ...

```

\* enviroments_\<env>_suffix property : Environment specific variable affectation

:warning: All other occurrences of this var init and their entire line will be erased
:warning: Some files aren't supported - yml for example. In this case, use ```\<env>_suffix``` to filename. Ex:
```config__PROD__.yml, config__DEV__.yml ...```


for example: if your project has this affectation

    myvar=dummy
    myvar__TEST__=dummy_test
    myvar__STAG__=dummy_staging
    myvar__REL__=dummy_release
    myvar__PROD__=dummy_prod

In the PROD package / sources you will only have :

    myvar=dummy_prod

---

TODOs / ideas :
- code cleanups / refactors
- self update script
- fetch lib/.*.sh dependencies from web instead of having it locally
- previous point add.: add a yml property letting to choose (web or local)
- ~~branch support~~
- ~~ssh proxy hops support ([Proxies_and_Jump_Hosts](https://en.wikibooks.org/wiki/OpenSSH/Cookbook/Proxies_and_Jump_Hosts) , [ssh hops](https://sellarafaeli.wordpress.com/2014/03/24/copy-local-files-into-remote-server-through-n1-ssh-hops/))~~
