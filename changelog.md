# Changelog

## 0.0.1 (2025-04-26)

### Features
- Initial version of AWS HA module

## 0.0.3 (2025-04-26)

### Features
- Updating readme to reflect all module vars
- Fixing vars to reflect required paerams correctly

## 0.0.5 (2024-05-07)

### Features
- Added optional license resource and inputs used for commercial site deployments

## 0.0.6 (2024-05-12)

### Features
- Removing unnecessary region variable

## 0.0.8 (2024-05-13)

### Features
- Updating iam role name creation to be unique with site name, filtering out invalid characters
- Reordered sleep null resources to better accommodate deployment of second instance

## 0.0.9 (2024-06-27)

### Features 
- Refactored module to use templated api calls with `terraform_data` 
- Updated ec2 call for vSockets to use `user_data_base64` and `gp3` type disks
- Separated code into separate files, `data.tf`, `locals.tf` 
- Updated modules with `site_location.tf` to dynamically determine site_location based on AWS region 
- Set module to use `routed_networks` to enable network creation 
- removed unused variables 
- updated README with additional verbiage
- Updated outputs with descriptions 

## 0.0.10 (2025-07-16)

### Features
 - Update Site_Location to Latest Revision
 - Version Lock Cato Provider to 0.0.30 or Greater

## 0.0.11 (2025-08-01)

### Features
 - Updated to use latest provider version 
  - Adjusted routed_networks call to include interface_index 
 - Version Lock to Provider version 0.0.38 or greater

## 0.0.12 (2026-02-18)
### Features
- Reverted to provider version 0.0.57 to address local_ip and gateway api param issue in state

## 0.0.13 (2026-03-12)
### Features
- Updated instances to encrypt drive, and migrated to new convention of attaching interfaces.

## 0.0.14 (2026-03-19)
### Features
- Updated reboot and sleep function sequence to fix issue introduced by migration to new interface attachment convention 

## 0.0.16 (2026-03-30)

### Features
- Update module adding lifecycle.ignore_changes for ami on socket instance

## 0.0.17 (2026-04-10)
### Features
- Updated version of provider adding in lastest SDK with updated ENUM values for accounSnapshot and license
