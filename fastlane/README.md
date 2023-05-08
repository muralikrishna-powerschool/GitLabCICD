fastlane documentation
================
# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```
xcode-select --install
```

Install _fastlane_ using
```
[sudo] gem install fastlane -NV
```
or alternatively using `brew install fastlane`

# Available Actions
## Android
### android test
```
fastlane android test
```
Runs all the local Unit Tests
### android androidTest
```
fastlane android androidTest
```
Runs Connected Android UI Tests in schoologyApp Module
### android javascriptTest
```
fastlane android javascriptTest
```
Runs Javascript Tests
### android uiAutomatorCourseDiscussionTest
```
fastlane android uiAutomatorCourseDiscussionTest
```
Runs UiAutomator Course Discussion Tests
### android uiAutomatorCourseAssignmentTest
```
fastlane android uiAutomatorCourseAssignmentTest
```
Runs UiAutomator Course Assignment Tests
### android uiAutomatorOtherCourseMaterialTest
```
fastlane android uiAutomatorOtherCourseMaterialTest
```
Runs UiAutomator Other Course Material Tests
### android uiAutomatorUnifiedUiTest
```
fastlane android uiAutomatorUnifiedUiTest
```
Runs UiAutomator Unified Ui Tests
### android uiAutomatorGradesAndGroupsTest
```
fastlane android uiAutomatorGradesAndGroupsTest
```
Runs UiAutomator Grades And Groups Tests
### android uiAutomatorLoginAndMessagesTest
```
fastlane android uiAutomatorLoginAndMessagesTest
```
Runs UiAutomator Login and Messages Tests
### android uiAutomatorUpdateTest
```
fastlane android uiAutomatorUpdateTest
```
Runs UiAutomator Update Tests
### android uiAutomatorUserTest
```
fastlane android uiAutomatorUserTest
```
Runs UiAutomator User Tests
### android uiAutomatorDeepLinkTest
```
fastlane android uiAutomatorDeepLinkTest
```
Runs UiAutomator Deep Link Tests
### android send_ui_test_results_to_airtable
```
fastlane android send_ui_test_results_to_airtable
```
Send UI Test Failure data to AirTable
### android connectedIntegrationTests
```
fastlane android connectedIntegrationTests
```
Runs Connected Integration Tests
### android generateReleaseBuilds
```
fastlane android generateReleaseBuilds
```
Generate release APKs and aab
### android publishPlayStore
```
fastlane android publishPlayStore
```
Publishes apk to Google Play Store's Internal Track
### android appCenterInternal
```
fastlane android appCenterInternal
```
Publishes release build internally for Smoke test
### android appCenterEnterprise
```
fastlane android appCenterEnterprise
```
Publishes Production builds to enterprise app center
### android buildRC
```
fastlane android buildRC
```
Create Release Candidate build
### android internalBuildRC
```
fastlane android internalBuildRC
```

### android lintRC
```
fastlane android lintRC
```
Process lint warnings
### android appCenter
```
fastlane android appCenter
```
Deploy to app center
### android prepareForReleaseBuild
```
fastlane android prepareForReleaseBuild
```
Organize JIRA and the repository in preparation for a new app release.
### android cleanUpGradle
```
fastlane android cleanUpGradle
```
Clean up Gradle processes
### android whitesource_scan
```
fastlane android whitesource_scan
```
Use WhiteSource to scan the project's 3rd party dependencies for security vulnerabilities and licence policy violations.
### android increment_minor_version
```
fastlane android increment_minor_version
```
Increment minor version name and version code

----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
