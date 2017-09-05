# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)

## Unreleased as of Sprint 68 ending 2017-09-04

### Added
- REST API
  - Adds Metric Rollups as a subcollection to services and vms [(#33)](https://github.com/ManageIQ/manageiq-api/pull/33)
  - Generic Object Definition CRUD [(#15)](https://github.com/ManageIQ/manageiq-api/pull/15)
  - Metric rollups api [(#4)](https://github.com/ManageIQ/manageiq-api/pull/4)

## Unreleased as of Sprint 67 ending 2017-08-21

### Fixed
- REST API
  - Require credentials when creating a provider [(#16)](https://github.com/ManageIQ/manageiq-api/pull/16)
  - Check if the User.current_user is set before calling userid [(#13)](https://github.com/ManageIQ/manageiq-api/pull/13)
  - Don't require authorization for OPTIONS [(#8)](https://github.com/ManageIQ/manageiq-api/pull/8)
