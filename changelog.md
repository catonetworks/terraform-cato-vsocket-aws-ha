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