# Bigrig

Bigrig manages and coordinates the lifecycle of multiple Docker containers
in a composite deployment strategy so you don't have to.

In its simplest form, docker looks super-easy to use.  Whip up a Dockerfile,
fire that badboy up, and you're all done, right?  Well, unfortunately
in reality it's rarely that straightforward.

# Scope

We want to make three things easier:
* Development
* Environemnt-specific configuration
* Separation of Operational Concerns

## Environment-specific configuration

Unless your ecosystem consists of the simplest possible deployment strategy,
you're likely going to need to be able to deploy your application to different
environments and you'll need the ability to configure the application in an
environment-specific way.

Bigrig lets you specify environment-specific configuration for all your
environments in one place.  Having a single source-of-record for all
environment details means it's easier to configure a new environment and it's
easier to see the differences between environments.

## Separation of Operational Concerns

There's this thing called **Separation of operational concerns** and it's one
of the core principles that makes Docker attractive in the first place.  I
don't care about the operating system beyond what's immediately
required to make my app go, and in many cases this might be all you need.

That being said, when the scope of your app grows beyond a single process
you've got two choices:
* Add more processes to your Docker-ized application
* Spin up more than one container and each one with a distinct job

There are those that might argue you shouldn't run more than one process
per container and if you count yourself among them Bigrig might be for you.

## bigrig.json

The below Bigrig metadata would be part of the project
`hawknewton/my-awesome-app`, sitting next to a Dockerfile that knows how to
generate a docker image.

```json
{
  "containers": {
    "my-awesome-app": {
      "ports": ["80:80"],
      "repo": "hawknewton/my-awesome-app",
      "path": ".",
      "env": {
        "USE_SSL": true,
        "CACHE_TIMEOUT": "3600"
      }
    },

    "logger": {
      "repo": "hawknewton/logger",
      "tag": "1.2.3",
      "volumes-from": ["my-awesome-app"]
    }
  },

  "profiles": {
    "qa": {
      "my-awesome-app": {
        "CACHE_TIMEOUT": "10"
      }
    },

    "qa-1": {
      "my-awesome-app": {
        "hosts": [ "qa-1-database.company.com:database" ]
      }
    },

    "qa-2": {
      "my-awesome-app": {
        "hosts": [ "qa-2-database.company.com:database" ]
      }
    },

    "production": {
      "my-awesome-app": {
        "hosts": [ "proddb12.company.com:database" ]
      }
    },

    "dev": {
      "web": {
        "env": {
          "USE_SSL": false,
          "CACHE_TIMEOUT": "1"
        },
        "links": [ "awesome-app-db:database" ]
      },

      "awesome-app-db": {
        "tag": "mysql:5.5",
        "env": {
          "MYSQL_ROOT_PASSWORD": "rootpasswordhere",
          "MYSQL_USER": "awesomeuser",
          "MYSQL_PASSWORD": "awesomespassword",
          "MYSQL_DATABASE": "awesome_db"
        }
      }
    }
  }
}
```

A few things:
* You can start Bigrig with more than one active profile. In the example
  above, you'd probably start the individual QA environments with a
  specific profile (`qa-1`, for example) and the broader **environment class**
  `qa`.
* I've included the hostname `database` for illustrative purposes, but I'd
  advocate using something more sophisticated like a service registry to avoid
  needing environment-specific profile entries for anything but the simplest
  deployments.
* If two profiles override the same value the profile declared later in
  `bigrig.json` wins.

## Development

We strive to bring the developer's environment as close to production as
possible (as well as the other way around).  The developer uses
`bigrig.json` to develop their code and production uses `bigrig.json`
to start the application.

## QA/Production

When building your application bigrig will create an **immutable** version of
your `bigrig.json` that will always have the same **deterministic** behavior when
run. Additionally, it'll build, tag, and push all containers that contain a
`path` entry.

For example given a bigrig.json that looks like this:

```json
{
  "containers": {
    "my-awesome-app": {
      "ports": ["80:80"],
      "repo": "hawknewton/my-awesome-app",
      "path": ".",
      "env": {
        "USE_SSL": true,
        "CACHE_TIMEOUT": "3600"
      }
    }
  }
}
```

Running `bigrig ship 1.2.3` builds the Dockerfile in the current directory,
tags the resulting image, pushes that image, and creates `bigrig-1.2.3.json`
that looks like this:

```json
{
  "containers": {
    "hawknewton/my-awesome-app": {
      "ports": ["80:80"],
      "repo": "hawknewton/my-awesome-app",
      "tag": "1.2.3",
      "env": {
        "USE_SSL": true,
        "CACHE_TIMEOUT": "3600"
      }
    }
  }
}
```

TODO
====
* Error handling is pretty bad
* Add model validation

See Also
========
* The docker guys look to be renaming `fig` to `compose`.  If they added
  profile support this project would become largely redundant.
