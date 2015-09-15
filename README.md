[![Build Status](https://travis-ci.org/constantcontact/bigrig.svg?branch=master)](https://travis-ci.org/constantcontact/bigrig)
# Bigrig

Bigrig is a light wrapper around docker-compose allowing you to author your
docker-compose.yml including ERB interpolation.

Additionally, you have the ability to pass flags to bigrig enabling
**profiles** which are made available within the context of your ERB
template.

## Usage

`bigrig [-P profile]... <any docker-compose switches or options>`

bigrig will read a file called `docker-compose.yml.erb`.  Additionally,
within the context of the ERB an array is present including all currently
active profiles as well as helper methods.

## docker-compose.yml.erb
A quick example:

```erb
webapp:
  image: my-webapp-image

<% if dev_profile_active? %>
dev_database:
  image: mysql
<% end %>
```

When bigrig is invoked with the dev profile active the dev_database container
will be started along with the webapp container.

```
bigrig -P dev up
```

