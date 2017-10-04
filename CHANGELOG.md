# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)


## Unreleased as of Sprint 70 ending 2017-10-02

### Added
- Return miq_groups on api entrypoint  [(#84)](https://github.com/ManageIQ/manageiq-api/pull/84)
- Added support for collection specific hide_resources option. [(#78)](https://github.com/ManageIQ/manageiq-api/pull/78)
- Add VMs subcollection to providers [(#66)](https://github.com/ManageIQ/manageiq-api/pull/66)
- Add a rudimentary event streams API [(#65)](https://github.com/ManageIQ/manageiq-api/pull/65)
- Tags Subcollection on Generic Objects [(#64)](https://github.com/ManageIQ/manageiq-api/pull/64)
- Add/Update/Delete custom Attribute for cloud instances [(#58)](https://github.com/ManageIQ/manageiq-api/pull/58)
- API calls to fetch and update the Automate Workspace [(#21)](https://github.com/ManageIQ/manageiq-api/pull/21)
- Middleware API Endpoints [(#19)](https://github.com/ManageIQ/manageiq-api/pull/19)

### Fixed
- Validate limit if offset is specified [(#90)](https://github.com/ManageIQ/manageiq-api/pull/90)
- Return correct automate_domains and policy_actions href_slugs [(#86)](https://github.com/ManageIQ/manageiq-api/pull/86)

## Unreleased as of Sprint 69 ending 2017-09-18

### Added
- REST API
  - Express ids as uncompressed strings [(#55)](https://github.com/ManageIQ/manageiq-api/pull/55)
  - Load developer bundler stuff in the Gemfile [(#53)](https://github.com/ManageIQ/manageiq-api/pull/53)
  - Generic Objects REST API [(#50)](https://github.com/ManageIQ/manageiq-api/pull/50)
  - Fix generic object definition spec [(#48)](https://github.com/ManageIQ/manageiq-api/pull/48)
  - Allow current group update  [(#44)](https://github.com/ManageIQ/manageiq-api/pull/44)
  - Use OPTIONS /api/providers [(#43)](https://github.com/ManageIQ/manageiq-api/pull/43)
  - OPTIONS - Generic Object Definition [(#42)](https://github.com/ManageIQ/manageiq-api/pull/42)
  - Add a basic ping endpoint [(#39)](https://github.com/ManageIQ/manageiq-api/pull/39)
  - Add PUT to generic object definitions API [(#38)](https://github.com/ManageIQ/manageiq-api/pull/38)
  - Generic Object Definition Actions [(#37)](https://github.com/ManageIQ/manageiq-api/pull/37)
  - Send back full dialog on create and edit [(#32)](https://github.com/ManageIQ/manageiq-api/pull/32)
  - Add API support for additional power operations [(#11)](https://github.com/ManageIQ/manageiq-api/pull/11)
  - Add guest_devices support to the API [(#7)](https://github.com/ManageIQ/manageiq-api/pull/7)

### Fixed
- REST API
  - Preserve contract for expressions of alert definitions [(#46)](https://github.com/ManageIQ/manageiq-api/pull/46)
  - Raise not found error on DELETE [(#17)](https://github.com/ManageIQ/manageiq-api/pull/17)

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
