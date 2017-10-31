# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)


## Unreleased as of Sprint 72 ending 2017-10-30

### Added
- Custom Button CRUD API [(#140)](https://github.com/ManageIQ/manageiq-api/pull/140)
- Add security group subcollection actions [(#137)](https://github.com/ManageIQ/manageiq-api/pull/137)
- Container Nodes Collection [(#129)](https://github.com/ManageIQ/manageiq-api/pull/129)
- encrypt/decrypt for Automate Workspace objects [(#124)](https://github.com/ManageIQ/manageiq-api/pull/124)
- Allow update to request task as a subcollection of request [(#117)](https://github.com/ManageIQ/manageiq-api/pull/117)
- Paginate all the things [(#113)](https://github.com/ManageIQ/manageiq-api/pull/113)
- Add flavors create delete to api [(#14)](https://github.com/ManageIQ/manageiq-api/pull/14)

### Fixed
- Add symbolization to data for Custom Buttons to fix a UI icon issue [(#151)](https://github.com/ManageIQ/manageiq-api/pull/151)
- Return correct href for collections on Index [(#150)](https://github.com/ManageIQ/manageiq-api/pull/150)
- Add `deep_symbolize_keys` to `custom_button_sets` data [(#148)](https://github.com/ManageIQ/manageiq-api/pull/148)
- Return only id attributes if specified [(#144)](https://github.com/ManageIQ/manageiq-api/pull/144)
- Blacklist Config Values [(#135)](https://github.com/ManageIQ/manageiq-api/pull/135)
- Symbolize parameters before sending to backend [(#133)](https://github.com/ManageIQ/manageiq-api/pull/133)
- Raise not found on DELETE  [(#20)](https://github.com/ManageIQ/manageiq-api/pull/20)

## Unreleased as of Sprint 71 ending 2017-10-16

### Added
- Return image_href and extension for Pictures [(#127)](https://github.com/ManageIQ/manageiq-api/pull/127)
- Return picture href for generic objects subcollections [(#126)](https://github.com/ManageIQ/manageiq-api/pull/126)
- Update task description for Generic Object methods [(#118)](https://github.com/ManageIQ/manageiq-api/pull/118)
- Allow generic object definition picture to be removed via edit [(#116)](https://github.com/ManageIQ/manageiq-api/pull/116)
- Picture support for Generic Object Definitions [(#114)](https://github.com/ManageIQ/manageiq-api/pull/114)
- Remove required filters from event streams [(#112)](https://github.com/ManageIQ/manageiq-api/pull/112)
- Search for resources based on href_slug  for automate workspace [(#109)](https://github.com/ManageIQ/manageiq-api/pull/109)
- Custom Button Set CRUD API [(#101)](https://github.com/ManageIQ/manageiq-api/pull/101)
- add_provider_vms action for Services [(#100)](https://github.com/ManageIQ/manageiq-api/pull/100)
- Generic Object method calling  [(#93)](https://github.com/ManageIQ/manageiq-api/pull/93)
- Add ability to set custom attributes on services via api [(#85)](https://github.com/ManageIQ/manageiq-api/pull/85)
- Added support for arbitrary resource identifier. [(#83)](https://github.com/ManageIQ/manageiq-api/pull/83)
- Add security group subcollection to providers and vms [(#81)](https://github.com/ManageIQ/manageiq-api/pull/81)
- Generic Objects Subcollection [(#57)](https://github.com/ManageIQ/manageiq-api/pull/57)

### Fixed
- Fix Generic Object Creation [(#122)](https://github.com/ManageIQ/manageiq-api/pull/122)
- Allow service templates to be specified for service orders [(#115)](https://github.com/ManageIQ/manageiq-api/pull/115)
- Fix return of orchestration stacks for a service [(#110)](https://github.com/ManageIQ/manageiq-api/pull/110)
- Do not allow removal of all miq groups  [(#107)](https://github.com/ManageIQ/manageiq-api/pull/107)
- Return correct version href  [(#87)](https://github.com/ManageIQ/manageiq-api/pull/87)

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
