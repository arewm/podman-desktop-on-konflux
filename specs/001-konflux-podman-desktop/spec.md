# Feature Specification: Konflux Onboarding for Podman Desktop

**Feature Branch**: `001-konflux-podman-desktop`
**Created**: 2025-11-19
**Status**: Draft
**Input**: User description: "I want to onboard podman-desktop onto Konflux so that it builds properly. I want to use common patterns where it makes sense (https://konflux-ci.dev/docs/patterns/) including the submodule pattern so that I don't need to own the upstream source at all. If any changes are needed for the build, we can use patch files on the upstream repository and then apply them using the pattern to run user scripts on the build pipeline. If a flatpak is needed, we can use other flatpak pipelines as a potential source for information -- for example, https://github.com/owtaylor/centos-stream-flatpak-runtime/."

## Clarifications

### Session 2025-11-19

- Q: Are patches required for upstream podman-desktop to build successfully in Konflux, or can it build without patches? → A: Patches are required for a successful build (P2 must precede P1)
- Q: What upstream source reference strategy should be used (tags, branches, commits)? → A: Pin to specific stable release tags
- Q: How should the system handle patches that conflict with new upstream changes? → A: Fail build, require manual patch update
- Q: What is the build artifact retention policy? → A: Retain tagged release builds indefinitely, non-tagged builds for 2 weeks; also requires ability to trigger builds from tagged events and documentation of this pattern for Konflux if it doesn't exist
- Q: How should missing or incompatible build toolchain versions be handled? → A: Fail fast with clear error, require environment fix

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Patch Application for Build Enablement (Priority: P1)

As a release engineer, I need to apply custom patches to the upstream podman-desktop source during the build process, so that the application can build successfully in the Konflux environment and incorporate necessary modifications for our distribution.

**Why this priority**: This is the foundational capability required before any successful builds are possible. Upstream podman-desktop requires patches to build in Konflux, making patch application the critical first milestone. Without this capability, no builds will succeed.

**Independent Test**: Can be fully tested by creating a simple patch file (e.g., build configuration modification), placing it in the build repository, configuring the pipeline to apply patches, and verifying that the patch application mechanism works correctly (patch is applied to source before build, failures are detected and reported).

**Acceptance Scenarios**:

1. **Given** patch files are stored in the build repository, **When** the build pipeline runs the custom script phase, **Then** all patches are applied to the upstream source before the build begins
2. **Given** a patch fails to apply cleanly, **When** the build executes, **Then** the pipeline fails with a clear error message indicating which patch failed and why
3. **Given** multiple patches exist in dependency order, **When** the build runs, **Then** patches are applied in the correct sequence and all succeed
4. **Given** patches have been applied successfully, **When** the build completes, **Then** the resulting artifacts contain all patched modifications

---

### User Story 2 - Automated Build from Upstream Source (Priority: P2)

As a release engineer, I need podman-desktop to build automatically from the upstream GitHub repository (with patches applied), so that we can deliver builds with minimal maintenance overhead and stay synchronized with upstream releases.

**Why this priority**: Once patch application (P1) is working, this proves the complete build pipeline from source retrieval through successful artifact generation. It validates the upstream source reference pattern and demonstrates end-to-end build capability.

**Independent Test**: Can be fully tested by triggering a build and verifying that it successfully retrieves the upstream podman-desktop source, applies patches, completes the build process, and produces buildable artifacts - all without requiring a forked repository.

**Acceptance Scenarios**:

1. **Given** Konflux is configured with the upstream source reference pointing to podman-desktop repository, **When** a build is triggered, **Then** the pipeline successfully retrieves the upstream source and initiates the build process
2. **Given** the upstream podman-desktop repository contains standard build dependencies and patches are applied, **When** the build executes, **Then** all required dependencies are fetched and the build completes without dependency errors
3. **Given** a successful build has completed, **When** the build artifacts are inspected, **Then** they contain a complete podman-desktop application ready for packaging

---

### User Story 3 - Flatpak Package Generation (Priority: P3)

As a release engineer, I need the build pipeline to produce a flatpak package for podman-desktop, so that users can install and run the application in a sandboxed environment on Linux distributions.

**Why this priority**: Flatpak packaging is important for distribution but depends on having a successful build (P1) and potentially requiring patches (P2) for flatpak-specific configurations. It's an output format rather than core infrastructure.

**Independent Test**: Can be tested independently by configuring flatpak build manifests, triggering the build pipeline, and verifying that a valid flatpak package is produced and can be installed and launched on a test system.

**Acceptance Scenarios**:

1. **Given** flatpak build configuration is present in the repository, **When** the build pipeline completes, **Then** a valid flatpak package file is generated
2. **Given** the flatpak package has been built, **When** it is installed on a Linux system, **Then** the application launches successfully and all core functionality works
3. **Given** podman-desktop has desktop integration requirements, **When** the flatpak is installed, **Then** desktop files, icons, and application metadata are correctly integrated
4. **Given** the flatpak requires specific runtime permissions, **When** examining the package manifest, **Then** all necessary permissions are declared and scoped appropriately

---

### Edge Cases

- What happens when upstream podman-desktop repository introduces breaking changes to its build process?
- When patches conflict with new upstream changes, the build fails immediately and requires manual patch updates before proceeding
- What happens when the git submodule reference points to a commit that no longer exists in upstream?
- How does the pipeline handle network failures during upstream repository cloning?
- What happens when the flatpak runtime dependencies change or become unavailable?
- How does the system handle builds when upstream includes platform-specific code that may not build in the Konflux environment?
- When build toolchain versions required by podman-desktop are not available or incompatible, the build fails immediately with clear error messages identifying missing/incompatible versions and required fixes

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST use git submodule pattern to reference upstream podman-desktop repository without requiring a fork
- **FR-002**: System MUST support referencing specific stable release tags from upstream podman-desktop repository (e.g., v1.2.3)
- **FR-003**: Build pipeline MUST successfully fetch all required dependencies for podman-desktop
- **FR-004**: Build pipeline MUST execute all build steps required for podman-desktop (install dependencies, compile, package)
- **FR-005**: System MUST support storing patch files in the build repository separate from upstream source
- **FR-006**: Build pipeline MUST apply patch files to upstream source before the build phase begins
- **FR-007**: Build pipeline MUST use user scripts to execute patch application and any custom build preparation
- **FR-008**: System MUST fail the build if any patch fails to apply cleanly
- **FR-009**: Build pipeline MUST produce verification that patches were applied successfully
- **FR-010**: System MUST support generating flatpak packages from the built podman-desktop application
- **FR-011**: Flatpak configuration MUST include all necessary runtime dependencies, environment variables, and permissions for podman-desktop
- **FR-012**: Build pipeline MUST validate that generated flatpak packages are installable
- **FR-013**: System MUST maintain build artifacts indefinitely for tagged release builds, and for 2 weeks for non-tagged builds
- **FR-013a**: System MUST support triggering builds automatically from upstream tagged release events
- **FR-014**: Build pipeline MUST produce detailed logs for troubleshooting build failures
- **FR-014a**: Build pipeline MUST validate toolchain version requirements before build and fail fast with clear error messages if versions are missing or incompatible
- **FR-015**: System MUST support triggering builds manually for initial setup and testing
- **FR-016**: Build pipeline MUST support execution of custom scripts during the build process
- **FR-017**: Flatpak build MUST follow standard flatpak build patterns
- **FR-018**: System MUST support RPM dependency prefetching if required by build process

### Key Entities

- **Upstream Source Reference**: Pointer to the upstream podman-desktop repository, includes repository URL, stable release tag reference (e.g., v1.2.3), and update strategy
- **Patch File**: Modification to be applied to upstream source, includes patch content, target files, application order, and success/failure status
- **Build Artifact**: Output from successful build, includes application binaries, flatpak package, build metadata, and verification checksums
- **Build Pipeline Configuration**: Defines build phases, custom scripts for patch application, dependencies, and artifact outputs
- **Flatpak Manifest**: Configuration describing flatpak package structure, runtime requirements, environment variables, package dependencies, and permissions
- **Build Container Definition**: Build environment specification including required stages for flatpak package creation
- **Custom Build Script**: User-defined script executed during the build process for applying patches and custom build preparation

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Builds complete successfully from upstream source within 45 minutes of pipeline initiation
- **SC-002**: Build pipeline handles updates to upstream podman-desktop source with minimal manual intervention
- **SC-003**: Patch application succeeds with clear failure messages when conflicts occur
- **SC-004**: Generated flatpak packages install successfully on standard Linux distributions without manual dependency resolution
- **SC-005**: Build artifacts are reproducible - identical inputs produce identical outputs
- **SC-006**: Build failures are detected and reported within 5 minutes of occurrence
- **SC-007**: Build pipeline requires zero manual steps to execute end-to-end
- **SC-008**: Documentation enables new team members to understand the build process within one reading session

## Scope *(mandatory)*

### In Scope

- Configuration of build pipeline for podman-desktop on Konflux platform
- Implementation of upstream source reference pattern for source management
- Setup of custom script execution for patch application in build pipeline
- Creation of patch management workflow
- Flatpak package generation configuration
- Build verification and artifact validation
- Documentation of build process and troubleshooting
- Dependency prefetching configuration if needed
- Configuration of automated builds triggered from upstream tagged release events
- Build artifact retention policy implementation (indefinite retention for tagged releases, 2-week retention for non-tagged builds)
- Documentation of tagged release build pattern for Konflux community (if pattern doesn't currently exist)

### Out of Scope

- Modifications to upstream podman-desktop source code (all changes via patches)
- Distribution or deployment of built packages to end users
- Maintenance of runtime infrastructure for running podman-desktop
- User support or documentation for podman-desktop application itself
- Performance optimization of podman-desktop application
- Security scanning or vulnerability assessment of podman-desktop (beyond build-time checks)
- Multi-architecture builds beyond x86_64 (arm64, ppc64le support is future work)
- Windows or macOS builds (Linux flatpak only)
- Long-term retention of non-tagged build artifacts (retained for 2 weeks, then automatically deleted)

## Dependencies & Assumptions *(mandatory)*

### Dependencies

- Konflux platform availability and access
- Upstream podman-desktop repository accessibility (github.com/podman-desktop/podman-desktop)
- Build environment supports required build toolchain for desktop applications
- Flatpak runtime and SDK availability
- Upstream source reference and custom script patterns are available in Konflux
- Flatpak build tooling available in build environment

### Assumptions

- Upstream podman-desktop maintains stable build process across minor versions
- Konflux provides sufficient resources for desktop application builds
- Network connectivity to upstream repository and package registries is reliable
- Patch files will be maintained in standard unified diff format
- Build environment supports custom script execution for build customization
- Initial focus is on Linux x86_64 flatpak builds
- Build pipeline has access to necessary credentials and permissions
- Flatpak build dependencies and base images are accessible
- Initial builds will be triggered manually for testing and validation
