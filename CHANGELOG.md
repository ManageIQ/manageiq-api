# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)


## Gaprindashvili-6

### Added
- Add basic CentralAdmin support to the API [(#472)](https://github.com/ManageIQ/manageiq-api/pull/472)

### Fixed
- Deep symbolize keys when parsing options [(#312)](https://github.com/ManageIQ/manageiq-api/pull/312)
- Include task_id in the response when invoking a custom button [(#444)](https://github.com/ManageIQ/manageiq-api/pull/444)
- Make cloud_tenants and flavors subcollections consistent with others [(#321)](https://github.com/ManageIQ/manageiq-api/pull/321)
- Add flag to initialize field default values [(#485)](https://github.com/ManageIQ/manageiq-api/pull/485)

## Gaprindashvili-5

### Added
- Pass option to retain dialog values so they're not rerun [(#406)](https://github.com/ManageIQ/manageiq-api/pull/406)
- Add support for /api/orchestration_stacks [(#453)](https://github.com/ManageIQ/manageiq-api/pull/453)
- Add ServiceTemplate#schedules subcollection [(#412)](https://github.com/ManageIQ/manageiq-api/pull/412)
- Add DELETE service_templates/X/schedules/X [(#414)](https://github.com/ManageIQ/manageiq-api/pull/414)
- Edit schedules for service templates [(#417)](https://github.com/ManageIQ/manageiq-api/pull/417)
- Request cancel [(#421)](https://github.com/ManageIQ/manageiq-api/pull/421)
- Allow ordering ServiceTemplates with a schedule_time [(#400)](https://github.com/ManageIQ/manageiq-api/pull/400)
- Add support for /api/orchestration_stacks [(#196)](https://github.com/ManageIQ/manageiq-api/pull/196)

### Fixed
- Permit concurrent loads to avoid a deadlock [(#416)](https://github.com/ManageIQ/manageiq-api/pull/416)
- Ensure 'submit_workflow' is true when adding a service to a cart [(#426)](https://github.com/ManageIQ/manageiq-api/pull/426)
- Set user when queueing VM actions [(#326)](https://github.com/ManageIQ/manageiq-api/pull/326)
- Symbolize schedule data [(#436)](https://github.com/ManageIQ/manageiq-api/pull/436)

## Gaprindashvili-4 - Released 2018-07-16

### Added
- Transformation Mappings Read and Create [(#313)](https://github.com/ManageIQ/manageiq-api/pull/313)
- Add lans collection with read and show [(#325)](https://github.com/ManageIQ/manageiq-api/pull/325)
- Add support for validate_vms action on transformation_mappings [(#358)](https://github.com/ManageIQ/manageiq-api/pull/358)
- Delete API for transformation_mappings [(#383)](https://github.com/ManageIQ/manageiq-api/pull/383)
- Allow ordering of service templates resource [(#316)](https://github.com/ManageIQ/manageiq-api/pull/316)
- Add archive/unarchive actions to ServiceTemplate [(#389)](https://github.com/ManageIQ/manageiq-api/pull/389)

### Fixed
- Downcase userid to match how it is stored in the DB. [(#371)](https://github.com/ManageIQ/manageiq-api/pull/371)
- In list of services, fetch RBAC-filtered vms subcollection [(#404)](https://github.com/ManageIQ/manageiq-api/pull/404)

## Gaprindashvili-3 - Released 2018-05-15

### Added
- Adding support for /api/containers primary collection. [(#332)](https://github.com/ManageIQ/manageiq-api/pull/332)
- Allow multiple role identifiers for cloud volume [(#299)](https://github.com/ManageIQ/manageiq-api/pull/299)

### Fixed
- Update role identifiers for tasks collection [(#296)](https://github.com/ManageIQ/manageiq-api/pull/296)
- Allow read-only access to quotas subcollection [(#283)](https://github.com/ManageIQ/manageiq-api/pull/283)
- Default section to "metadata" across custom attributes add action [(#320)](https://github.com/ManageIQ/manageiq-api/pull/320)
- Ensure array is returned for subcollections [(#322)](https://github.com/ManageIQ/manageiq-api/pull/322)
- Raise bad request when current_group is specified on edit [(#329)](https://github.com/ManageIQ/manageiq-api/pull/329)
- Fix specifying of additional attributes on pictures [(#327)](https://github.com/ManageIQ/manageiq-api/pull/327)
- Add svc_catalog_provision product feature to service dialog queries [(#343)](https://github.com/ManageIQ/manageiq-api/pull/343)
- Add refresh parameter to ResourceActionWorkflow initialization [(#365)](https://github.com/ManageIQ/manageiq-api/pull/365)

## Gaprindashvili-2 - Released 2018-03-07

### Fixed
- Fixed up role identifiers for cloud_networks [(#298)](https://github.com/ManageIQ/manageiq-api/pull/298)
- Fix expand of custom_actions when they are nil [(#305)](https://github.com/ManageIQ/manageiq-api/pull/305)
- Union edit service_dialog API call with other calls [(#285)](https://github.com/ManageIQ/manageiq-api/pull/285)
- Add condition on log warning for service dialogs [(#314)](https://github.com/ManageIQ/manageiq-api/pull/314)
- Ensure request task options are keyed with symbols [(#317)](https://github.com/ManageIQ/manageiq-api/pull/317)

## Gaprindashvili-1 - Released 2018-02-01

### Added
- Tasks: delete support [(#220)](https://github.com/ManageIQ/manageiq-api/pull/220)
- Do not expand custom actions on collection searches [(#204)](https://github.com/ManageIQ/manageiq-api/pull/204)
- Adds custom action support for models that are g/yes [(#213)](https://github.com/ManageIQ/manageiq-api/pull/213)
- Removes final .first from custom action specs [(#216)](https://github.com/ManageIQ/manageiq-api/pull/216)
- Fixes custom actions spec tests to not use anything.first [(#215)](https://github.com/ManageIQ/manageiq-api/pull/215)
- Add support for /api/container_projects [(#182)](https://github.com/ManageIQ/manageiq-api/pull/182)
- Custom actions on generic objects [(#194)](https://github.com/ManageIQ/manageiq-api/pull/194)
- Add support for Physical Servers refresh [(#189)](https://github.com/ManageIQ/manageiq-api/pull/189)
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
- Return miq_groups on api entrypoint  [(#84)](https://github.com/ManageIQ/manageiq-api/pull/84)
- Added support for collection specific hide_resources option. [(#78)](https://github.com/ManageIQ/manageiq-api/pull/78)
- Add VMs subcollection to providers [(#66)](https://github.com/ManageIQ/manageiq-api/pull/66)
- Add a rudimentary event streams API [(#65)](https://github.com/ManageIQ/manageiq-api/pull/65)
- Tags Subcollection on Generic Objects [(#64)](https://github.com/ManageIQ/manageiq-api/pull/64)
- Add/Update/Delete custom Attribute for cloud instances [(#58)](https://github.com/ManageIQ/manageiq-api/pull/58)
- API calls to fetch and update the Automate Workspace [(#21)](https://github.com/ManageIQ/manageiq-api/pull/21)
- Middleware API Endpoints [(#19)](https://github.com/ManageIQ/manageiq-api/pull/19)
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
- Adds Metric Rollups as a subcollection to services and vms [(#33)](https://github.com/ManageIQ/manageiq-api/pull/33)
- Generic Object Definition CRUD [(#15)](https://github.com/ManageIQ/manageiq-api/pull/15)
- Metric rollups api [(#4)](https://github.com/ManageIQ/manageiq-api/pull/4)
- Mask password attributes from AutomateWorkspace [(#168)](https://github.com/ManageIQ/manageiq-api/pull/168)
- API Enhancement making the system token a one-time token. [(#178)](https://github.com/ManageIQ/manageiq-api/pull/178)

### Fixed
- Ensure that correct target is passed to resource_search on dialog refresh [(#246)](https://github.com/ManageIQ/manageiq-api/pull/246)
- Return 404 error if perform an action against a non existent Physical Server [(#202)](https://github.com/ManageIQ/manageiq-api/pull/202)
- Don't return non-existent hrefs [(#251)](https://github.com/ManageIQ/manageiq-api/pull/251)
- Fix custom actions hrefs [(#252)](https://github.com/ManageIQ/manageiq-api/pull/252)
- Return property method actions on Generic Object subresources [(#247)](https://github.com/ManageIQ/manageiq-api/pull/247)
- Only require read priviliges to show cloud volumes [(#254)](https://github.com/ManageIQ/manageiq-api/pull/254)
- ExtManagementSystem#destroy_queue returns a task id [(#257)](https://github.com/ManageIQ/manageiq-api/pull/257)
- Specify a target and resource action when retrieving a service dialog [(#231)](https://github.com/ManageIQ/manageiq-api/pull/231)
- Specify a target and resource when refreshing a dialog field [(#233)](https://github.com/ManageIQ/manageiq-api/pull/233)
- Return correct subcollection actions [(#243)](https://github.com/ManageIQ/manageiq-api/pull/243)
- Validate section values for adding new custom attributes via the API [(#240)](https://github.com/ManageIQ/manageiq-api/pull/240)
- Dialog field/tab deletion [(#239)](https://github.com/ManageIQ/manageiq-api/pull/239)
- Don't translate model names sent over API [(#237)](https://github.com/ManageIQ/manageiq-api/pull/237)
- Return correct action responses for bulk delete [(#180)](https://github.com/ManageIQ/manageiq-api/pull/180)
- Return put and patch edit actions for resources [(#179)](https://github.com/ManageIQ/manageiq-api/pull/179)
- Gracefully fail on resource create [(#195)](https://github.com/ManageIQ/manageiq-api/pull/195)
- Add deep symbolization to CustomButton `visibility` field [(#206)](https://github.com/ManageIQ/manageiq-api/pull/206)
- Add a set_current_group method for users [(#176)](https://github.com/ManageIQ/manageiq-api/pull/176)
- Reflect session timeout settings updates in the UI requester type [(#199)](https://github.com/ManageIQ/manageiq-api/pull/199)
- Build href_slug from type [(#212)](https://github.com/ManageIQ/manageiq-api/pull/212)
- deep symbolize the options field [(#211)](https://github.com/ManageIQ/manageiq-api/pull/211)
- Use destroy_queue for provider delete [(#217)](https://github.com/ManageIQ/manageiq-api/pull/217)
- Rolling back system token OTP logic [(#219)](https://github.com/ManageIQ/manageiq-api/pull/219)
- Fix links in the case when there are no incoming query params [(#221)](https://github.com/ManageIQ/manageiq-api/pull/221)
- Fixes an issue where no userid gets retrieved for the token [(#223)](https://github.com/ManageIQ/manageiq-api/pull/223)
- Fix Generic Object Creation [(#122)](https://github.com/ManageIQ/manageiq-api/pull/122)
- Allow service templates to be specified for service orders [(#115)](https://github.com/ManageIQ/manageiq-api/pull/115)
- Fix return of orchestration stacks for a service [(#110)](https://github.com/ManageIQ/manageiq-api/pull/110)
- Do not allow removal of all miq groups  [(#107)](https://github.com/ManageIQ/manageiq-api/pull/107)
- Return correct version href  [(#87)](https://github.com/ManageIQ/manageiq-api/pull/87)
- Validate limit if offset is specified [(#90)](https://github.com/ManageIQ/manageiq-api/pull/90)
- Return correct automate_domains and policy_actions href_slugs [(#86)](https://github.com/ManageIQ/manageiq-api/pull/86)
- Preserve contract for expressions of alert definitions [(#46)](https://github.com/ManageIQ/manageiq-api/pull/46)
- Raise not found error on DELETE [(#17)](https://github.com/ManageIQ/manageiq-api/pull/17)
- Require credentials when creating a provider [(#16)](https://github.com/ManageIQ/manageiq-api/pull/16)
- Check if the User.current_user is set before calling userid [(#13)](https://github.com/ManageIQ/manageiq-api/pull/13)
- Don't require authorization for OPTIONS [(#8)](https://github.com/ManageIQ/manageiq-api/pull/8)
- Add decorator for VNC Console [(#167)](https://github.com/ManageIQ/manageiq-api/pull/167)
- Fix coercing of string to 0 in parse_id [(#173)](https://github.com/ManageIQ/manageiq-api/pull/173)
- Don't respond with 400 on ArgumentError [(#174)](https://github.com/ManageIQ/manageiq-api/pull/174)
- Update dialog copy product feature [(#262)](https://github.com/ManageIQ/manageiq-api/pull/262)
- Fix regression for expansion of subcollection on a resource [(#261)](https://github.com/ManageIQ/manageiq-api/pull/261)

### Removed
- Remove Middleware API [(#255)](https://github.com/ManageIQ/manageiq-api/pull/255)
