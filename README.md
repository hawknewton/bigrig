# Shipper

Shipper manages and coordinates the lifecycle of multiple Docker containers
in a composite deployment strategy so you don't have to.

In it's simplist form, docker looks super-easy to use.  Whip up a Dockerfile,
fire that badboy up, and you're all done, right?  Well, unfortunately
in reality it's rarely that straightforward.

# Scope

We want to make three things easier:
* Development
* Environemnt-specific configuration
* Serpation of Opertaional Concerns

## shipper.json

```json
{
  "containers": [
    {
      "name": "web",
      "ports": ["80:80"],
      "tag": "hawknewton/show-env"
    },
    {
      "name": "logger",
      "volumes-from": ["web"]
    }
  ],

  "development": {
    "web": "path/to/web/Dockerfile"
  },

  "environments": {
    "development": {
      "use_ssl": false,
      "service_url": "http://localhost:8080/my-microservice"
    },

    "qa": {
      "use_ssl": true,
      "service_url": "http://qa.hawknewton.com/my-microservice"
    },

    "production": {
      "use_ssl": true,
      "service_url": "https://service.hawknewton.com/"
    }
  }
}
```

## Development

We strive to bring the developer's environment as close to production as
possible.  The developer uses the same `shipper.json` in development
that eventually pushes their code to production.

## Environment-specific configuration

Unless you're ecosystem consists of the simplest possible deployment strategy
you're likely going to need to be able to deploy your app to different
environments and you'll need the ability to configure the application in an
environment-specific way.

Shipper lets you specify environment-specific configuration for all your
environments in one place.  Having a single source-of-record for all your
environemnt details means it's easier to configure a new environemnt and it's
easier to see the differences between environments.

## Seperation of Operational Concerns

There' this thing called **Seperatrion of operational concerns** and it's one
of the core princpals that makes Docker attractive in the first place.  I
don't care about the operating system outside beyone what's immediately
required to make my app go, and in many cases this might be all you need.

That being said, when the scope of your app grows beyond a single process
you've got two choices:
* Add more processes to your dockerized application
* Spin up more than one container and each one with a distinct job

There are those that might argue you shouldn't run more than one process
per container and if you count yourself among them Shipper might be for you.
