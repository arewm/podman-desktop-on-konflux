# Tekton Pipeline Contracts

This directory contains Tekton task and pipeline definitions that serve as "contracts" for the Konflux build pipeline implementation.

## Overview

These YAML specifications define the interface and behavior of each pipeline component. They are contract definitions that will be used to create the actual Tekton resources in the `.tekton/` directory during implementation (Phase 2).

## Task Contracts

### 1. git-submodule-clone.yaml
Clones upstream podman-desktop repository using git submodules.

**Inputs**:
- `url`: Upstream repository URL
- `revision`: Tag or commit to clone
- `submodules`: Boolean (true to enable submodule cloning)

**Outputs**:
- `source` workspace: Cloned source code with submodules initialized

**Validation**:
- Verifies submodule was cloned successfully
- Checks revision exists in upstream

### 2. validate-toolchain.yaml
Validates build environment has required tools and versions.

**Inputs**:
- `required-node-version`: Node.js version requirement
- `required-tools`: List of required tools (pnpm, flatpak-builder, etc.)

**Outputs**:
- Exit code 0 if all tools present, 1 with error message if missing

**Fail-Fast Behavior**:
- Immediately fails pipeline if any tool missing or wrong version
- Provides clear error message indicating what's missing

### 3. apply-patches.yaml
Applies patch files sequentially to source code.

**Inputs**:
- `patches-path`: Directory containing patch files
- `source-path`: Source code directory to patch

**Outputs**:
- Modified source code in workspace
- Patch application log

**Error Handling**:
- Validates each patch with `--dry-run` before applying
- Fails immediately on first patch conflict
- Logs which patch failed and why

### 4. prefetch-dependencies.yaml
Caches npm/pnpm dependencies for hermetic build.

**Inputs**:
- `package-manager`: Tool to use (npm, pnpm, yarn)
- `lockfile-path`: Path to lock file

**Outputs**:
- Cached dependencies in workspace
- Dependency manifest

**Hermeticity**:
- Pre-fetches all dependencies before build
- Sets environment variables to use local cache

### 5. build-flatpak.yaml
Builds flatpak package using multi-stage Containerfile.

**Inputs**:
- `containerfile-path`: Path to Containerfile
- `container-yaml-path`: Path to container.yaml

**Outputs**:
- Flatpak package as OCI artifact
- Build logs

**Stages**:
- Install: Run flatpak-container container-install
- Export: Run flatpak-container container-export
- Final: Package OCI archive

### 6. podman-desktop-build.yaml (Main Pipeline)
Orchestrates all tasks in sequence.

**Tasks**:
1. git-submodule-clone
2. validate-toolchain
3. apply-patches
4. prefetch-dependencies
5. build-application
6. build-flatpak
7. sign-artifact (if secrets available)
8. push-artifact
9. generate-sbom

**Workspaces**:
- `source`: Shared source code
- `cache`: Dependency cache
- `output`: Build artifacts

### 7. tag-release-trigger.yaml
Webhook trigger for upstream tag creation events.

**Trigger Filter**:
- Event type: `push`
- Ref pattern: `refs/tags/v*`
- Repository: podman-desktop/podman-desktop

**Parameters**:
- Extracted tag name
- Commit SHA

**Action**:
- Starts `podman-desktop-build` pipeline
- Passes tag as revision parameter

## Implementation Notes

1. **Task Ordering**: Tasks must execute in defined order due to dependencies
2. **Workspace Sharing**: Source workspace passed between tasks for modifications
3. **Error Propagation**: Any task failure stops pipeline immediately
4. **Logging**: All tasks must log to stdout/stderr for debugging
5. **Validation**: Each task should validate inputs before processing

## Contract Validation

Before implementation, verify:
- All parameters are documented
- Required vs. optional parameters clearly marked
- Expected outputs defined
- Error cases handled
- Logging strategy defined

## Next Steps

Phase 2 (tasks.md generation via `/speckit.tasks`) will convert these contracts into actionable implementation tasks with specific file paths and code examples.
