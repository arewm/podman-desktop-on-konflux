# Implementation Plan: Konflux Onboarding for Podman Desktop

**Branch**: `001-konflux-podman-desktop` | **Date**: 2025-11-19 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-konflux-podman-desktop/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Onboard podman-desktop to Konflux CI/CD platform using upstream source reference pattern (git submodules), custom patch application for build enablement, and flatpak package generation. Build pipeline must support tagged release triggers, artifact retention for releases only, fail-fast error handling, and follow Konflux best practices. Implementation prioritizes patch application capability (P1) before successful builds (P2) before flatpak packaging (P3).

## Technical Context

**Language/Version**: Bash scripting (pipeline), YAML (Tekton/Konflux manifests), Containerfile
**Primary Dependencies**: Konflux platform, Tekton Chains, git submodules, flatpak-builder tooling, patch utilities
**Storage**: OCI registry for build artifacts and flatpak packages
**Testing**: Pipeline execution tests, patch application validation, flatpak installation verification
**Target Platform**: Konflux (Kubernetes-based CI/CD), Linux x86_64 builds
**Project Type**: CI/CD infrastructure (build pipeline configuration)
**Performance Goals**: Build completion <45 minutes, failure detection <5 minutes
**Constraints**: No forked repositories, patches required for builds, tagged releases retained indefinitely (non-tagged for 2 weeks), hermetic builds
**Scale/Scope**: Single application (podman-desktop), 3 priority levels, automated tag-based triggers

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Production-Grade Proof of Concept

- ✅ **Production-ready code**: Pipeline must handle real-world edge cases (network failures, patch conflicts, toolchain validation)
- ✅ **No stubs/templates**: All Tekton tasks and scripts must be fully functional
- ⚠️ **Supply chain gaps**: Document gaps in SUPPLY_CHAIN_GAPS.md:
  - GAP-001: Upstream podman-desktop dependencies not reproducible from source (npm packages)
  - GAP-002: Patch files maintained manually, not automatically validated against upstream changes
  - GAP-003: Build toolchain versions assumed available in Konflux environment (no hermetic toolchain packaging)

### OCI Artifact Encapsulation

- ✅ **OCI packaging**: Flatpak packages pushed to OCI registry as artifacts
- ✅ **Immutable digests**: All artifacts referenced by SHA256 digest
- ✅ **Traceability**: Lineage from source tag → build → artifact via provenance

### Provenance via Chains Integration

- ✅ **Tekton Chains**: Automatic provenance attestation generation and signing
- ✅ **Attestation attachment**: Provenance attached to OCI artifacts
- ⚠️ **OS-level signing**: Flatpak signing may differ from P12/PFX certificate signing (document as implementation detail)

### Cross-Platform Build Compatibility

- ✅ **Linux-native builds**: Focus on Linux x86_64 flatpak only (per spec scope)
- N/A **Windows/macOS**: Explicitly out of scope for initial implementation, deferred to future work
- ⚠️ **Supply chain gap**: Multi-architecture (arm64, ppc64le) deferred to future work (GAP-004)

### Test-Driven Development

- ✅ **Pipeline TDD**: Tekton tasks tested in isolation before integration
- ✅ **Direct execution**: Manual pipeline triggers against cluster for fast feedback. Prompt for access if cluster connections are not in memory
- ✅ **Verification tests**: Patch application, build success, flatpak installation all verified

### Hermetic Build Integrity

- ⚠️ **Network isolation**: Konflux supports network restricted build phase after dependency prefetch with the HERMETIC parameter. This is not critical for the initial implementation and can be deferred as a gap in the future.
- ✅ **Dependency prefetching**: npm/pnpm dependencies fetched before build
- ✅ **Version pinning**: Upstream podman-desktop has lock files (pnpm-lock.yaml)
- ⚠️ **Supply chain gap**: Runtime npm/Electron downloads may occur despite prefetch (GAP-005 - requires research)

### Security & Compliance

- ✅ **Secrets management**: Signing certificates stored as Kubernetes Secrets with RBAC
- ✅ **SBOM generation**: Generate SBOM for flatpak packages (the buildah tasks should handle this for us)
- ✅ **Provenance verification**: Standard tooling (cosign verify-attestation) supported but this doesn't need to be verified

### Development Workflow

- ✅ **Development testing**: Use a dedicated remote instance to run pipelines for testing
- ✅ **Branching standard**: 001-konflux-podman-desktop follows ###-feature-name pattern
- ✅ **Documentation**: All decisions documented in specs/001-konflux-podman-desktop/

## Project Structure

### Documentation (this feature)

```text
specs/001-konflux-podman-desktop/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
│   ├── tekton-pipeline.yaml     # Konflux pipeline definition
│   ├── git-submodule.yaml       # Submodule configuration task
│   ├── patch-application.yaml   # Patch task definition
│   └── flatpak-build.yaml       # Flatpak build task definition
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
.tekton/
├── podman-desktop-build.yaml        # Main build pipeline
├── components/
│   └── podman-desktop.yaml          # Component configuration
├── tasks/
│   ├── git-submodule-clone.yaml     # Custom task: clone with submodules
│   ├── apply-patches.yaml           # Custom task: apply patch files
│   ├── validate-toolchain.yaml      # Custom task: check build environment
│   └── build-flatpak.yaml           # Custom task: flatpak build
└── triggers/
    └── tag-release.yaml             # Trigger on upstream tag events

patches/
├── 001-build-fix.patch              # Example patch for build enablement
└── README.md                        # Patch management documentation

podman-desktop                       # Submodule containing remote source
├── Containerfile                    # Multi-stage flatpak build container
└── container.yaml                   # Flatpak manifest configuration

.devcontainer/
└── devcontainer.json                 # Local development environment

SUPPLY_CHAIN_GAPS.md                  # Supply chain hardening gaps documentation
```

**Structure Decision**: This is a CI/CD infrastructure project focused on Konflux pipeline configuration rather than application code. The structure follows Konflux conventions (`.tekton/` directory for pipelines and tasks) with additional support for patch management and flatpak build configuration.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Network isolation uncertainty (hermetic builds) | Upstream podman-desktop has npm/Electron dependencies that may download at build time | Must research Konflux's network policy capabilities and npm prefetching patterns before assuming full hermeticity is achievable |
| Manual patch maintenance (GAP-002) | Patches required for build enablement but no automated validation against upstream changes exists | Automated patch validation would require complex diff analysis and upstream change detection - deferred as enhancement |
| Build toolchain assumption (GAP-003) | Assuming Node.js/pnpm/Electron toolchain available in Konflux environment | Alternative of hermetically packaging entire toolchain adds significant complexity - validate environment first, then enhance if needed |

## Phase 0: Research Tasks

*Research unknowns from Technical Context and identify best practices.*

### R001: Konflux Hermetic Build Capabilities

**Question**: Does Konflux support network-off build execution after dependency prefetch? What are the standard patterns for npm/pnpm dependency isolation?

**Research areas**:
- Konflux documentation on hermetic builds
- Network policy configuration in Konflux pipelines
- npm/pnpm caching and offline-mode patterns
- Electron binary prefetch strategies (ELECTRON_MIRROR, ELECTRON_SKIP_BINARY_DOWNLOAD)

**Decision criteria**: Determine if full network isolation is achievable or if partial hermeticity (with documented gaps) is acceptable

### R002: Git Submodule Pattern in Konflux

**Question**: What is the recommended Konflux pattern for building from upstream repositories using git submodules?

**Research areas**:
- Konflux docs on upstream source patterns
- Existing examples of submodule-based builds in Konflux
- Git submodule initialization in Tekton tasks
- Tag/commit pinning strategies for reproducibility

**Decision criteria**: Identify whether existing Konflux patterns exist or if this requires documentation contribution

### R003: Patch Application Best Practices

**Question**: What are the standard patterns for applying patches in Konflux build pipelines? How should patch failures be handled and reported?

**Research areas**:
- Patch command (`patch -p1`) error handling
- Sequential patch application with dependency ordering
- Patch verification and validation
- Error message formatting for clear diagnostics

**Decision criteria**: Define patch application workflow that integrates cleanly with Konflux error reporting

### R004: Tagged Release Build Triggers

**Question**: How does Konflux detect and trigger builds from upstream repository tag events? Does this pattern exist in Konflux documentation or need to be created?

**Research areas**:
- Konflux webhook/trigger configuration for tag events
- GitHub webhook integration for tag creation
- Tag-based artifact retention policies
- Existing Konflux examples of tag-triggered builds

**Decision criteria**: Determine if pattern exists or requires documentation contribution to Konflux community

### R005: Flatpak Build on Konflux

**Question**: What is the standard approach for building flatpak packages on Konflux? Are there existing examples (e.g., centos-stream-flatpak-runtime patterns)?

**Research areas**:
- Flatpak-container tooling usage in Konflux
- Multi-stage Containerfile patterns for flatpak builds
- container.yaml manifest structure for desktop applications
- Flatpak signing and verification in Konflux

**Decision criteria**: Identify reusable patterns from existing Konflux flatpak builds

### R006: Build Toolchain Availability

**Question**: What build toolchain (Node.js, pnpm, Electron dependencies) is available in standard Konflux builder images? What versions are supported?

**Research areas**:
- Konflux base builder images and available tools
- Custom builder image requirements for podman-desktop
- Toolchain version pinning strategies
- Validation script patterns for toolchain verification (fail-fast requirement)

**Decision criteria**: Determine if standard images suffice or custom builder image needed

## Phase 1: Design & Contracts

*Completed after research.md provides answers to R001-R006.*

### Data Model (data-model.md)

Key entities from spec:
- Upstream Source Reference (repository URL, tag, submodule config)
- Patch File (content, order, target files, status)
- Build Artifact (binaries, flatpak, metadata, digest)
- Build Pipeline Configuration (phases, scripts, dependencies)
- Flatpak Manifest (runtime, permissions, packages)
- Build Container Definition (stages, base images)
- Custom Build Script (patch application, validation)

### API Contracts (contracts/)

Tekton pipeline contracts:
- **git-submodule-clone.yaml**: Task to clone upstream with submodule reference
- **apply-patches.yaml**: Task to apply patches with error handling
- **validate-toolchain.yaml**: Task to check build environment (fail-fast)
- **build-flatpak.yaml**: Task for multi-stage flatpak build
- **podman-desktop-build.yaml**: Main pipeline orchestrating all tasks
- **tag-release.yaml**: Trigger configuration for upstream tag events

### Quickstart (quickstart.md)

Developer onboarding:
1. Prerequisites (Konflux access, repository permissions)
2. Local devcontainer setup for pipeline testing
3. Manual pipeline trigger for testing
4. Patch file creation and validation workflow
5. Tag-based build trigger testing
6. Artifact verification and retrieval

