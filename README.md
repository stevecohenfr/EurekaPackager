## EurekaPackager - Delivery system with GIT

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


|                     Option                     	|                               Detail                              	|          Required          	            |
|:----------------------------------------------:	|:-----------------------------------------------------------------:	|:--------------------------:	            |
| -c= / --commit=<SHA1 commit>                     	| use the commit sha1 to get files                                  	|             Yes (no if message provided) 	|
| -m= / --message=<message to search in a commit > 	| search a commit using a part of the commit message                	|             Yes (no if commit provided)   |
| -e= / --env=<env short or full name>             	| Create package for specific environment provided in conf.yml file 	|             no (asked if not provided)    |
| *(in developement: )-u / --upgrade*              	| *self upgrade*                                                      	|             no             	            |
| -h / --help                                     	| show help                                                         	|             no             	            |
| -v / --version                                  	| show the script version                                           	|             no             	            |

commit and message options can be used together and several times :

    $ <path/to/scrips>/EurekaPackager.sh -c=c123 -m=atag -c=c5654789 -m=Create

#### Configuration

A configuration in a 'config.yml' file is needed.
This file should be located at the project's root location
(or at the same path where the script is executed)

It's organized as follows :

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
    # Will be used at the end of the package name (eg: My_Project_yyyymmdd.tar.gz)


    environments:
      list: # List of names of the deploy environnements
        - prod
        - preprod
        - integ
        - recette

      prod:               # each environnement listed above has following config. The key must be the same as
        name: Production  # Env full name
        short: p          # shortcut to use in argument or if asked
        suffix: __PROD__  # For env specific lines *
        deploy:
          type: src|sources/pkg|package # type of the delivery to deploy
          user:  test                   # user allowed to deploy on server
          host:  localhost              # the host
          pass: ***                     # /!\ not secure and redundant (asked for ssh after/before script execution and rsync). Use ssh keys instead
          proxy: # TODO : proxy needed to acces on the final deploy server
            user: test
            host: localhost

          target: /var/www # Target where to deliver the target or sources
          commands: # (optional) lists of commands to execute before
            before_scripts:
              - ls -alh
              - pwd
              - date
            after_scripts : # and after deploy
              - ls -alh
              - date

```

\* enviroments_\<env>_suffix property : Environment specific variable affectation

:warning: All other occurrences of this var init and their entire line will be erased

for example: if your project has this affectation
myvar=dummy
myvar__TEST__=dummy_test
myvar__STAG__=dummy_staging
myvar__REL__=dummy_release
myvar__PROD__=dummy_prod

In the PROD package you will only have :
myvar=dummy_prod