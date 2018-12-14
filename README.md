# ManageIQ::Api

ManageIQ::Api is a plugin to be used in the [ManageIQ project][ManageIQ]. It forms
the public REST API for ManageIQ.

[![Gem Version](https://badge.fury.io/rb/manageiq-api.svg)](http://badge.fury.io/rb/manageiq-api)
[![Build Status](https://travis-ci.org/ManageIQ/manageiq-api.svg?branch=master)](https://travis-ci.org/ManageIQ/manageiq-api)
[![Code Climate](https://codeclimate.com/github/ManageIQ/manageiq-api.svg)](https://codeclimate.com/github/ManageIQ/manageiq-api)
[![Test Coverage](https://codeclimate.com/github/ManageIQ/manageiq-api/badges/coverage.svg)](https://codeclimate.com/github/ManageIQ/manageiq-api/coverage)
[![Dependency Status](https://gemnasium.com/ManageIQ/manageiq-api.svg)](https://gemnasium.com/ManageIQ/manageiq-api)
[![Security](https://hakiri.io/github/ManageIQ/manageiq-api/master.svg)](https://hakiri.io/github/ManageIQ/manageiq-api/master)

[![Chat](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/ManageIQ/api?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

## Contributing

### Prerequisites

It is assumed you have met all prerequisites for installing the
ManageIQ app, as described
[here](https://github.com/ManageIQ/guides/blob/master/developer_setup.md)

### Setup

First, fork/clone the project, ideally in the same directory where you
store the main [ManageIQ app][ManageIQ]:

```bash
git clone git@github.com:username/manageiq-api.git
```

Next, run the setup script:

```bash
bin/setup
```

This should be sufficient to meet all development dependencies, and is
to be run only once the first time you setup the plugin. During
development, if you need to update the dependencies you can do so by
running:

```bash
bin/update
```

For more details on the development setup for the ManageIQ ecosystem,
please refer to the [general guide][plugin guide].


### Running the tests

To run the entire suite:

```bash
bundle exec rake
```

Or, to run an individual test:

```bash
bundle exec rspec spec/path/to/spec.rb:<line number>
```

### Development

Generally development is done by pointing your local clone of the
[ManageIQ app][ManageIQ] to your local branch of the plugin, as
described in [this section][local gem guide] of the general developer
setup guide.

### Submitting a pull request

Please read [CONTRIBUTING.md](/CONTRIBUTING.md) for more details on
creating and submitting a pull request to ManageIQ::Api.

## License

See [LICENSE.txt](/LICENSE.txt).


[ManageIQ]: https://github.com/ManageIQ/manageiq
[plugin guide]: https://github.com/ManageIQ/guides/blob/master/developer_setup/plugins.md
[local gem guide]: https://github.com/ManageIQ/guides/blob/master/developer_setup/plugins.md#dependency-on-a-local-gem
