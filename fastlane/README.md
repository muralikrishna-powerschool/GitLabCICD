fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## Android

### android test

```sh
[bundle exec] fastlane android test
```

Runs all the local Unit Tests

### android generateReleaseBuilds

```sh
[bundle exec] fastlane android generateReleaseBuilds
```

Generate release APKs and aab

### android publishPlayStore

```sh
[bundle exec] fastlane android publishPlayStore
```

Publishes apk to Google Play Store's Internal Track

### android appCenterInternal

```sh
[bundle exec] fastlane android appCenterInternal
```

Publishes release build internally for Smoke test

### android appCenterEnterprise

```sh
[bundle exec] fastlane android appCenterEnterprise
```

Publishes Production builds to enterprise app center

### android buildRC

```sh
[bundle exec] fastlane android buildRC
```

Create Release Candidate build

### android internalBuildRC

```sh
[bundle exec] fastlane android internalBuildRC
```



### android lintRC

```sh
[bundle exec] fastlane android lintRC
```

Process lint warnings

### android appCenter

```sh
[bundle exec] fastlane android appCenter
```

Deploy to app center

### android prepareForReleaseBuild

```sh
[bundle exec] fastlane android prepareForReleaseBuild
```

Organize JIRA and the repository in preparation for a new app release.

### android cleanUpGradle

```sh
[bundle exec] fastlane android cleanUpGradle
```

Clean up Gradle processes

### android increment_minor_version

```sh
[bundle exec] fastlane android increment_minor_version
```

Increment minor version name and version code

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
