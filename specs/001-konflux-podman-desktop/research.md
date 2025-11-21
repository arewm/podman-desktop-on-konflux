# Research: Konflux Onboarding for Podman Desktop

**Date**: 2025-11-19
**Feature**: 001-konflux-podman-desktop
**Status**: Completed

## R001: Konflux Hermetic Build Capabilities

### Decision
Partial hermeticity achievable through dependency prefetching; full network isolation requires custom network policies and may not be initially enforced.

### Rationale
- Konflux supports prefetch-dependencies task for caching npm/pnpm packages
- Network isolation after prefetch is possible but requires explicit network policy configuration
- Elektron binary downloads can be redirected to local mirrors using environment variables
- Initial implementation focuses on dependency prefetching; full hermeticity documented as enhancement

### Alternatives Considered
- **Full hermetic builds with network-off policy**: Requires comprehensive testing of all dependency scenarios, may block builds if any runtime download occurs
- **No hermeticity**: Allows runtime downloads but violates constitution principle and introduces supply chain risk
- **Chosen: Partial hermeticity with prefetch**: Balances security with pragmatic implementation, documents gaps for future hardening

### Implementation Notes
- Use `prefetch-dependencies` Tekton task with pnpm cache
- Set `ELECTRON_MIRROR` and `ELECTRON_SKIP_BINARY_DOWNLOAD` environment variables
- Document GAP-005 in SUPPLY_CHAIN_GAPS.md if runtime downloads still occur
- Monitor build logs for unexpected network activity

##

 R002: Git Submodule Pattern in Konflux

### Decision
Use Konflux git-clone task with submodules parameter enabled; reference upstream via git submodule in build repository.

### Rationale
- Konflux's standard git-clone task supports `submodules: true` parameter
- Submodule approach allows upstream source reference without forking
- Tag/commit pinning achieved via `.gitmodules` file specification
- Pattern aligns with Konflux best practices for upstream source management

### Alternatives Considered
- **Direct clone of upstream**: Requires forking or maintaining separate copy (rejected per spec requirements)
- **Artifact download**: Download release tarballs instead of git clone (loses git metadata and provenance)
- **Chosen: Git submodule with pinned tags**: Maintains upstream relationship, enables tag tracking, preserves provenance

### Implementation Notes
- Add podman-desktop as git submodule in build repository
- Pin submodule to specific release tag (e.g., v1.10.0)
- Update submodule reference when new tagged release should be built
- Submodule path: `upstream/podman-desktop/`

## R003: Patch Application Best Practices

### Decision
Apply patches sequentially using `patch -p1 < file.patch` with explicit error handling and validation; fail build immediately on any patch conflict.

### Rationale
- Standard `patch` command provides clear error messages for conflicts
- Sequential application with numbered patches (001-, 002-) ensures deterministic order
- Explicit error checking after each patch application enables fail-fast behavior
- Patch validation (dry-run) before actual application can detect conflicts early

### Alternatives Considered
- **git-apply**: Git-specific, requires git repository (may not work with extracted source)
- **quilt**: Patch management tool but adds dependency and complexity
- **Chosen: Standard patch command**: Ubiquitous, simple, clear error reporting

### Implementation Notes
- Store patches in `patches/` directory with numbered prefixes
- Create custom Tekton task `apply-patches` that:
  1. Lists patches in numeric order
  2. Runs `patch -p1 --dry-run < patch` for validation
  3. Runs `patch -p1 < patch` for actual application
  4. Exits with error code on failure
- Log patch application status for debugging
- Example: `patches/001-build-fix.patch`, `patches/002-flatpak-config.patch`

## R004: Tagged Release Build Triggers

### Decision
Configure Konflux webhook trigger for upstream repository tag creation events; this pattern may not exist in Konflux docs and may require contribution.

### Rationale
- Konflux supports webhook-based triggers via PipelineAsCode (PAC)
- Tag events can be filtered using GitHub webhook configuration
- Automated builds on tags align with artifact retention policy (tagged releases retained indefinitely, non-tagged for 2 weeks)
- Pattern may be novel and worth documenting for Konflux community

### Alternatives Considered
- **Manual builds only**: Requires manual trigger for each release (rejected - spec requires automation)
- **Branch-based triggers**: Triggers on every commit, not just releases (excessive builds)
- **Chosen: Tag event webhooks**: Precise trigger for release builds, aligns with retention policy

### Implementation Notes
- Configure GitHub webhook for repository tag creation
- Create `.tekton/triggers/tag-release.yaml` with event filter for `push` events with `refs/tags/v*` pattern
- Webhook payload extracts tag name for submodule update
- Validate pattern exists in Konflux docs; if not, document in `docs/patterns/tag-triggered-builds.md` for community contribution
- Test with manual tag creation before enabling production webhooks

## R005: Flatpak Build on Konflux

### Decision
Use multi-stage Containerfile approach with flatpak-container tooling, following centos-stream-flatpak-runtime pattern.

### Rationale
- centos-stream-flatpak-runtime demonstrates proven pattern for Konflux flatpak builds
- Multi-stage build (install, export, final) separates concerns and optimizes image size
- `flatpak-container container-install` and `flatpak-container container-export` are standard tools
- container.yaml defines flatpak runtime, SDK, packages, and environment variables

### Alternatives Considered
- **Flatpak-builder directly**: Standard flatpak tool but less Konflux-optimized
- **Custom build scripts**: Reinvents wheel, doesn't follow Konflux patterns
- **Chosen: flatpak-container multi-stage**: Proven pattern, optimized for containers, aligns with Konflux ecosystem

### Implementation Notes
- Create `Containerfile` with three stages:
  1. Install stage: Copy container.yaml, run `flatpak-container container-install`
  2. Export stage: Mount install output, run `flatpak-container container-export`
  3. Final stage: Use exported OCI archive
- Create `container.yaml` defining:
  - Runtime ID (e.g., `io.podman_desktop.PodmanDesktop`)
  - Branch/version
  - SDK base
  - Required packages (desktop integration, runtime libraries)
  - Environment variables
  - Cleanup commands
- Reference centos-stream-flatpak-runtime for structure examples
- Test flatpak installation with `flatpak install --user <oci-ref>`

## R006: Build Toolchain Availability

### Decision
Use custom builder image with pinned Node.js and pnpm versions; validate toolchain before build with fail-fast check.

### Rationale
- Standard Konflux builder images may not include specific Node.js/pnpm/Electron versions required by podman-desktop
- Custom builder image allows toolchain version pinning for reproducibility
- Fail-fast toolchain validation (per spec requirement) enables early error detection
- Validation script checks for required tools and versions before proceeding

### Alternatives Considered
- **Use standard builder images**: Risk of version mismatches, may not have pnpm
- **Install tools at build time**: Slower, defeats prefetching benefits, adds network dependency
- **Chosen: Custom builder image with validation**: Reproducible, fast, fail-fast on incompatibility

### Implementation Notes
- Create `builder.Containerfile` based on Konflux base builder
- Install specific Node.js version (check podman-desktop `.nvmrc` or package.json engines)
- Install pnpm globally
- Install Electron build dependencies
- Create `validate-toolchain.yaml` Tekton task:
  - Check `node --version` matches required version
  - Check `pnpm --version` exists
  - Check `flatpak-builder --version` exists
  - Exit with error code 1 and clear message if any check fails
- Run validation task as first step in build pipeline

## Summary of Decisions

| Research Item | Decision | Impact |
|---------------|----------|--------|
| R001: Hermetic Builds | Partial hermeticity with prefetch | Document GAP-005, enable future hardening |
| R002: Git Submodules | Use Konflux git-clone with submodules | Standard pattern, no custom implementation needed |
| R003: Patch Application | Sequential patch with fail-fast | Clear error reporting, deterministic ordering |
| R004: Tag Triggers | Webhook for tag events | May require Konflux docs contribution |
| R005: Flatpak Build | Multi-stage flatpak-container pattern | Follow proven centos-stream-flatpak-runtime approach |
| R006: Toolchain | Custom builder image with validation | Reproducible builds, fail-fast on incompatibility |

## Supply Chain Gaps Identified

Based on research, the following gaps must be documented in SUPPLY_CHAIN_GAPS.md:

- **GAP-001**: npm package dependencies not reproducible from source (inherent to npm ecosystem)
- **GAP-002**: Manual patch maintenance without automated upstream change validation
- **GAP-003**: Custom builder image required; toolchain not hermetically packaged from source
- **GAP-004**: Multi-architecture builds (arm64, ppc64le) deferred
- **GAP-005**: Potential runtime npm/Electron downloads despite prefetching (requires monitoring)

## Next Phase

Proceed to Phase 1 (Design & Contracts) with research findings incorporated.
