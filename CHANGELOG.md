# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)

## Jansa-1 Alpha-1

### Added
* Reset the User.current_user upon each incoming request [(#736)](https://github.com/ManageIQ/manageiq-api/pull/736)
* Extend the existing provider creation with DDF support [(#723)](https://github.com/ManageIQ/manageiq-api/pull/723)
* Call the `key?` method on objects safely when trying to normalize [(#733)](https://github.com/ManageIQ/manageiq-api/pull/733)

### Fixed
* Change the zone param to zone_name in DDF provider validation [(#738)](https://github.com/ManageIQ/manageiq-api/pull/738)
* Remove container provider resume/pause [(#740)](https://github.com/ManageIQ/manageiq-api/pull/740)

## Ivanchuk-4

### Added
* Allow miq_regions to be edited [(#690)](https://github.com/ManageIQ/manageiq-api/pull/690)
* Allow Zones to be edited and deleted [(#691)](https://github.com/ManageIQ/manageiq-api/pull/691)
* Add support for OpenID-Connect/OAuth2 in the API [(#737)](https://github.com/ManageIQ/manageiq-api/pull/737) and [(#747)](https://github.com/ManageIQ/manageiq-api/pull/747)
* Add compliances subcollection [(#742)](https://github.com/ManageIQ/manageiq-api/pull/742)
* Implemented Create/Edit/Delete resources for /api/policy_profiles [(#749)](https://github.com/ManageIQ/manageiq-api/pull/749)

### Fixed
* Remove container provider resume/pause [(#740)](https://github.com/ManageIQ/manageiq-api/pull/740)

## Ivanchuk-2

### Added
* Expose error messages from ServiceTemplate.orderable?[(#656)](https://github.com/ManageIQ/manageiq-api/pull/656)
* Add endpoints for widget content generation [(#660)](https://github.com/ManageIQ/manageiq-api/pull/660)
* Added validations for the input params for conversion hosts. [(#683)](https://github.com/ManageIQ/manageiq-api/pull/683)

### Fixed
* Create TransformationMapping before Item (FIX CI FAILURE) [(#666)](https://github.com/ManageIQ/manageiq-api/pull/666)
* Fixes the pxe_servers collection actions [(#678)](https://github.com/ManageIQ/manageiq-api/pull/678)
* Include user info in widget generation [(#679)](https://github.com/ManageIQ/manageiq-api/pull/679)

## Ivanchuk-1

### Added
- Append RBAC features for VMRC console request through the API [(#642)](https://github.com/ManageIQ/manageiq-api/pull/642)
- FirmwareRegistry create/list/delete and sync_fw_binaries [(#636)](https://github.com/ManageIQ/manageiq-api/pull/636)
- Add a subcollection under VMs for displaying CD-ROMs [(#605)](https://github.com/ManageIQ/manageiq-api/pull/605)
- Add a subcollection under VMs for displaying disks [(#598)](https://github.com/ManageIQ/manageiq-api/pull/598)
- Include the regions if they're supported with OPTIONS /api/providers [(#581)](https://github.com/ManageIQ/manageiq-api/pull/581)
- Support physical server provisioning [(#578)](https://github.com/ManageIQ/manageiq-api/pull/578)
- Include a list of supported providers in `OPTIONS /api/providers` [(#579)](https://github.com/ManageIQ/manageiq-api/pull/579)
- Add create Git backed automation domain [(#571)](https://github.com/ManageIQ/manageiq-api/pull/571)
- Expose the favicon URL in the branding info endpoints [(#551)](https://github.com/ManageIQ/manageiq-api/pull/551)
- Add delete automate domain support [(#548)](https://github.com/ManageIQ/manageiq-api/pull/548)
- Allow authentication against the _vmdb_session cookie for UI only [(#543)](https://github.com/ManageIQ/manageiq-api/pull/543)
- Authorise action managing tenant quotas for according tenants in API [(#536)](https://github.com/ManageIQ/manageiq-api/pull/536)
- Allow api.yml to be pluggable [(#613)](https://github.com/ManageIQ/manageiq-api/pull/613)
- Added PxeServer create update and delete actions [(#594)](https://github.com/ManageIQ/manageiq-api/pull/594)

### Fixed
- Allow reconfigure vm on OSP provider over Centralized Administration [(#608)](https://github.com/ManageIQ/manageiq-api/pull/608)
- Do not request for basic auth if the auth_requester is set to UI [(#542)](https://github.com/ManageIQ/manageiq-api/pull/542)
- Ensure a users own tasks are the only ones returned when the users role has View/My Tasks [(#526)](https://github.com/ManageIQ/manageiq-api/pull/526)
- Use the new universal methods for suspending/resuming a provider [(#434)](https://github.com/ManageIQ/manageiq-api/pull/434)

## Hammer-9 - Released 2019-07-23

### Fixed
- Allow reconfigure vm on OSP provider over Centralized Administration [(#608)](https://github.com/ManageIQ/manageiq-api/pull/608)

## Hammer-8 - Released 2019-07-02

### Added
- Adjust ConversionHost support check so that it uses resource instead of singleton [(#600)](https://github.com/ManageIQ/manageiq-api/pull/600)

## Hammer-6 - Released 2019-05-22

### Added
- Add ability to enable and disable conversion hosts [(#535)](https://github.com/ManageIQ/manageiq-api/pull/535)

### Fixed
- Fixes conversion_hosts_spec.rb failures [(#524)](https://github.com/ManageIQ/manageiq-api/pull/524)

## Hammer-5 - Released 2019-04-23

### Added
- TransformationMapping: API for adding mapping item [(#546)](https://github.com/ManageIQ/manageiq-api/pull/546)
- [RFE] Add the /api/product_info route with product and branding info [(#438)](https://github.com/ManageIQ/manageiq-api/pull/438)

### Fixed
- Provide the path to the custom branding assets instead of booleans [(#549)](https://github.com/ManageIQ/manageiq-api/pull/549)
- Added logic to support both string and symbol access to keys in dialog hash under options [(#572)](https://github.com/ManageIQ/manageiq-api/pull/572)

## Hammer-4 - Released 2019-03-29

### Fixed
- Remove SQL select from exception error messages. [(#537)](https://github.com/ManageIQ/manageiq-api/pull/537)

## Hammer-3 - Released 2019-03-06

### Fixed
- One semaphore to exclusively load them all [(#550)](https://github.com/ManageIQ/manageiq-api/pull/550)

## Hammer-1 - Released 2019-01-15

### Added
- Add support for sui product features [(#501)](https://github.com/ManageIQ/manageiq-api/pull/501)
- Expose conversion hosts as part of REST API [(#507)](https://github.com/ManageIQ/manageiq-api/pull/507)
- Add subcollection options support for CORS preflight requests [(#495)](https://github.com/ManageIQ/manageiq-api/pull/495)
- transformation mappings `edit` action [(#467)](https://github.com/ManageIQ/manageiq-api/pull/467)
- Endpoint api/cloud_volume_types [(#465)](https://github.com/ManageIQ/manageiq-api/pull/465)
- Use the replacement backend method for searching and valiating VMs [(#463)](https://github.com/ManageIQ/manageiq-api/pull/463)
- Allow bulk assignment and unassignment of tags for users [(#462)](https://github.com/ManageIQ/manageiq-api/pull/462)
- Add best fit API for transformations moving vms to openstack [(#455)](https://github.com/ManageIQ/manageiq-api/pull/455)
- Apis for new servicey things [(#460)](https://github.com/ManageIQ/manageiq-api/pull/460)
- Include task_id in the response when invoking a custom button [(#444)](https://github.com/ManageIQ/manageiq-api/pull/444)
- [RFE] Use Vmdb::Appliance.PRODUCT_NAME instead of calling i18n [(#437)](https://github.com/ManageIQ/manageiq-api/pull/437)
- Added verify_ssl to the list of valid attributes [(#431)](https://github.com/ManageIQ/manageiq-api/pull/431)
- Added support for fetching configuration scripts [(#430)](https://github.com/ManageIQ/manageiq-api/pull/430)
- Add event_streams as subcollection of the physical resources [(#424)](https://github.com/ManageIQ/manageiq-api/pull/424)
- Allow ordering ServiceTemplate with a schedule_time [(#401)](https://github.com/ManageIQ/manageiq-api/pull/401)
- Creating PhysicalStorage controller and adding endpoint configuration [(#397)](https://github.com/ManageIQ/manageiq-api/pull/397)
- Adding Physical Switch power action [(#392)](https://github.com/ManageIQ/manageiq-api/pull/392)
- Creating an endpoint for a PhysicalRack to execute toolbar actions [(#349)](https://github.com/ManageIQ/manageiq-api/pull/349)
- Adding Physical Switches support [(#370)](https://github.com/ManageIQ/manageiq-api/pull/370)
- Adds request_retire action for Vms and Services [(#380)](https://github.com/ManageIQ/manageiq-api/pull/380)
- Creating PhysicalChassis controller and adding endpoint configuration [(#362)](https://github.com/ManageIQ/manageiq-api/pull/362)
- Updated token manager initializer to log the configured server session_store [(#376)](https://github.com/ManageIQ/manageiq-api/pull/376)
- Adding support for collection_names whose plural and singular are the same [(#364)](https://github.com/ManageIQ/manageiq-api/pull/364)
- Implementing change password action for providers endpoint [(#309)](https://github.com/ManageIQ/manageiq-api/pull/309)
- Adding tagging support for additional collections [(#361)](https://github.com/ManageIQ/manageiq-api/pull/361)
- Add update action for templates [(#341)](https://github.com/ManageIQ/manageiq-api/pull/341)
- Add create action for templates [(#337)](https://github.com/ManageIQ/manageiq-api/pull/337)
- Add delete action for templates [(#328)](https://github.com/ManageIQ/manageiq-api/pull/328)
- Added the enterprise_href in the server_info section of the entrypoint [(#351)](https://github.com/ManageIQ/manageiq-api/pull/351)
- Assign and Unassign alert definition profiles [(#348)](https://github.com/ManageIQ/manageiq-api/pull/348)
- Add enterprise collection [(#346)](https://github.com/ManageIQ/manageiq-api/pull/346)
- Add Lans subcollection to Hosts / Providers [(#342)](https://github.com/ManageIQ/manageiq-api/pull/342)
- Add networks subcollection to providers [(#339)](https://github.com/ManageIQ/manageiq-api/pull/339)
- Folders subcollection on providers [(#338)](https://github.com/ManageIQ/manageiq-api/pull/338)
- Add pause and resume actions to Providers [(#334)](https://github.com/ManageIQ/manageiq-api/pull/334)
- Queue chargeback reports of services [(#301)](https://github.com/ManageIQ/manageiq-api/pull/301)
- Return product features for all of a user's groups on the API entrypoint [(#311)](https://github.com/ManageIQ/manageiq-api/pull/311)
- Delete of search filters [(#306)](https://github.com/ManageIQ/manageiq-api/pull/306)
- Allow additional provider parameters to be specified on create [(#279)](https://github.com/ManageIQ/manageiq-api/pull/279)
- Adding support to apply_config_pattern operation via the REST API [(#278)](https://github.com/ManageIQ/manageiq-api/pull/278)
- Adding support of basic PATCH signatures for API resources [(#302)](https://github.com/ManageIQ/manageiq-api/pull/302)
- Return Time in API entrypoint server_info [(#297)](https://github.com/ManageIQ/manageiq-api/pull/297)
- Add Settings API for servers and regions [(#275)](https://github.com/ManageIQ/manageiq-api/pull/275)
- Allow assigning/un-assigning of alert definitions to alert profiles [(#149)](https://github.com/ManageIQ/manageiq-api/pull/149)
- Generic Object Definition OPTIONS: send hashes rather than arrays [(#238)](https://github.com/ManageIQ/manageiq-api/pull/238)
- Use type names directly from GenericObjectDefinition object [(#232)](https://github.com/ManageIQ/manageiq-api/pull/232)
- Add delete for router [(#193)](https://github.com/ManageIQ/manageiq-api/pull/193)
- Add subresource_action_identifier spec helper [(#225)](https://github.com/ManageIQ/manageiq-api/pull/225)
- Adding support for optional token_ttl in the UserTokenService. [(#214)](https://github.com/ManageIQ/manageiq-api/pull/214)
- Adding custom_actions support for /api/cloud_networks [(#200)](https://github.com/ManageIQ/manageiq-api/pull/200)
- Add support for /api/switches [(#191)](https://github.com/ManageIQ/manageiq-api/pull/191)
- Add support for /api/container_volumes [(#190)](https://github.com/ManageIQ/manageiq-api/pull/190)
- Add support for /api/container_templates [(#188)](https://github.com/ManageIQ/manageiq-api/pull/188)
- Adding support for /api/container_images [(#185)](https://github.com/ManageIQ/manageiq-api/pull/185)
- Adding support for /api/container_groups [(#184)](https://github.com/ManageIQ/manageiq-api/pull/184)
- Adding support for /api/cloud_object_store_containers [(#183)](https://github.com/ManageIQ/manageiq-api/pull/183)
- Add custom action support for models already exposed in api that need it [(#163)](https://github.com/ManageIQ/manageiq-api/pull/163)
- Add basic CentralAdmin support to the API [(#472)](https://github.com/ManageIQ/manageiq-api/pull/472)
- Add more CRUD operations to conversion hosts, plus tags [(#513)](https://github.com/ManageIQ/manageiq-api/pull/513)
- Authorise action managing tenant quotas for according tenants in API [(#536)](https://github.com/ManageIQ/manageiq-api/pull/536)

### Fixed
- Seed tenant product features in Spec::Support::API::Helpers [(#508)](https://github.com/ManageIQ/manageiq-api/pull/508)
- Post body changes for `validate_vms_resource ` to include service template_id [(#486)](https://github.com/ManageIQ/manageiq-api/pull/486)
- Ensure ServiceTemplate ordering passes through the submit_workflow flag [(#504)](https://github.com/ManageIQ/manageiq-api/pull/504)
- Don't request HTTP Basic authenticaion when using a token [(#488)](https://github.com/ManageIQ/manageiq-api/pull/488)
- Add flag to initialize field default values [(#485)](https://github.com/ManageIQ/manageiq-api/pull/485)
- Need the user on this call [(#497)](https://github.com/ManageIQ/manageiq-api/pull/497)
- Deny standalone service template ordering when product setting is enabled [(#476)](https://github.com/ManageIQ/manageiq-api/pull/476)
- provide `service_template` to `orderable?` method [(#498)](https://github.com/ManageIQ/manageiq-api/pull/498)
- EMS Cloud Refresh is missing [(#428)](https://github.com/ManageIQ/manageiq-api/pull/428)
- Pass changed dialog field values to resource_action_workflow [(#448)](https://github.com/ManageIQ/manageiq-api/pull/448)
- Expose CloudSubnet creation [(#440)](https://github.com/ManageIQ/manageiq-api/pull/440)
- Allow retirement requests to be created through the api [(#439)](https://github.com/ManageIQ/manageiq-api/pull/439)
- Allow the PUT/PATCH editing of templates and add a test for it [(#435)](https://github.com/ManageIQ/manageiq-api/pull/435)
- Adding Physical Chassis Location LED actions [(#410)](https://github.com/ManageIQ/manageiq-api/pull/410)
- Fixed validation while adding user with multiple groups. [(#427)](https://github.com/ManageIQ/manageiq-api/pull/427)
- Ignore case of the userid when validating it. [(#396)](https://github.com/ManageIQ/manageiq-api/pull/396)
- Fix tests after identifier rename [(#399)](https://github.com/ManageIQ/manageiq-api/pull/399)
- Ensure refresh => true option gets passed for service_template refresh [(#386)](https://github.com/ManageIQ/manageiq-api/pull/386)
- use request_admin_user? [(#385)](https://github.com/ManageIQ/manageiq-api/pull/385)
- Always challenge a user with no/bad credentials [(#359)](https://github.com/ManageIQ/manageiq-api/pull/359)
- Enhanced API to catch Settings validation errors [(#356)](https://github.com/ManageIQ/manageiq-api/pull/356)
- Only allow one cart to be created at a time [(#324)](https://github.com/ManageIQ/manageiq-api/pull/324)
- Make cloud_tenants and flavors subcollections consistent with others [(#321)](https://github.com/ManageIQ/manageiq-api/pull/321)
- Fix error message for required params on metric rollups subcollection [(#308)](https://github.com/ManageIQ/manageiq-api/pull/308)
- AssetDetails model should be AssetDetail [(#291)](https://github.com/ManageIQ/manageiq-api/pull/291)
- Do not return duplicate "edit" action entries [(#318)](https://github.com/ManageIQ/manageiq-api/pull/318)
- Fix picture fetching as an attribute [(#294)](https://github.com/ManageIQ/manageiq-api/pull/294)
- Do not return picture content on create [(#292)](https://github.com/ManageIQ/manageiq-api/pull/292)
- Fix special characters in MIQ_GROUP header [(#287)](https://github.com/ManageIQ/manageiq-api/pull/287)
- Remove groups from editable attributes for users [(#286)](https://github.com/ManageIQ/manageiq-api/pull/286)
- Updating the API so it now returns nil attributes. [(#253)](https://github.com/ManageIQ/manageiq-api/pull/253)
- add image scanning endpoint [(#245)](https://github.com/ManageIQ/manageiq-api/pull/245)
- Update role identifiers for cloud subnets subcollection [(#280)](https://github.com/ManageIQ/manageiq-api/pull/280)
- Update dialog copy product feature [(#262)](https://github.com/ManageIQ/manageiq-api/pull/262)
- Fix regression for expansion of subcollection on a resource [(#261)](https://github.com/ManageIQ/manageiq-api/pull/261)
- Squeeze consecutive slashes in the path portion of the URI [(#228)](https://github.com/ManageIQ/manageiq-api/pull/228)
- Pass `User#userid` instead of `User#id` to queue chargeback report [(#480)](https://github.com/ManageIQ/manageiq-api/pull/480)
- Fix policy spec due to new validation [(#484)](https://github.com/ManageIQ/manageiq-api/pull/484)
- Custom Buttons with dialogs should be running invoke [(#506)](https://github.com/ManageIQ/manageiq-api/pull/506)
- Fix invalid count query [(#520)](https://github.com/ManageIQ/manageiq-api/pull/520)
- Updated service template's ui token info check to use token metadata for requester_type[(#529)](https://github.com/ManageIQ/manageiq-api/pull/529)

## Unreleased as of Sprint 99 ending 2018-11-19

### Added
- Include product features list in the identity section of /api [(#490)](https://github.com/ManageIQ/manageiq-api/pull/490)
- Add custom_button_events subcollection for users tenants and groups [(#464)](https://github.com/ManageIQ/manageiq-api/pull/464)

## Unreleased as of Sprint 96 ending 2018-10-08

### Added
- Display plugins in the product_info under the root route [(#473)](https://github.com/ManageIQ/manageiq-api/pull/473)

## Gaprindashvili-5 - Released 2018-09-07

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

## Gaprindashvili-4

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

## Gaprindashvili-3 released 2018-05-15

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

## Gaprindashvili-2 released 2018-03-06

### Fixed
- Fixed up role identifiers for cloud_networks [(#298)](https://github.com/ManageIQ/manageiq-api/pull/298)
- Fix expand of custom_actions when they are nil [(#305)](https://github.com/ManageIQ/manageiq-api/pull/305)
- Union edit service_dialog API call with other calls [(#285)](https://github.com/ManageIQ/manageiq-api/pull/285)
- Add condition on log warning for service dialogs [(#314)](https://github.com/ManageIQ/manageiq-api/pull/314)
- Ensure request task options are keyed with symbols [(#317)](https://github.com/ManageIQ/manageiq-api/pull/317)

## Gaprindashvili-1

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

### Initial changelog added
