# Tasks: Konflux Onboarding for Podman Desktop

**Input**: Design documents from `/specs/001-konflux-podman-desktop/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Not explicitly requested in specification - focus on implementation and manual validation

**Organization**: Tasks grouped by user story (P1: Patch Application, P2: Automated Build, P3: Flatpak Generation) to enable independent implementation and testing

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

This is a CI/CD infrastructure project following Konflux conventions:
- `.tekton/` for pipelines and tasks
- `patches/` for upstream source modifications
- `podman-desktop/` for git submodule (upstream source)
- `.devcontainer/` for local development environment

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [ ] T001 Create repository structure per plan.md (.tekton/, patches/, .devcontainer/)
- [ ] T002 Initialize git repository with branch 001-konflux-podman-desktop
- [ ] T003 [P] Create .devcontainer/devcontainer.json for local pipeline testing
- [ ] T004 [P] Create .gitignore for temporary build artifacts
- [ ] T005 [P] Create SUPPLY_CHAIN_GAPS.md documenting GAP-001 through GAP-005
- [ ] T006 Add upstream podman-desktop as git submodule at podman-desktop/
- [ ] T007 Pin submodule to specific release tag (e.g., v1.10.0)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T008 Create .tekton/podman-desktop-build.yaml skeleton pipeline structure
- [ ] T009 [P] Create .tekton/components/podman-desktop.yaml component configuration
- [ ] T010 [P] Create patches/README.md documenting patch management workflow

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Patch Application for Build Enablement (Priority: P1) 🎯 MVP

**Goal**: Enable custom patches to be applied to upstream podman-desktop source during build process

**Independent Test**:
1. Create a sample patch file in patches/
2. Trigger apply-patches task manually
3. Verify patch applies cleanly and source is modified
4. Verify patch failure is detected and reported clearly

### Implementation for User Story 1

- [ ] T011 [US1] Implement .tekton/tasks/apply-patches.yaml based on contracts/apply-patches.yaml specification
- [ ] T012 [US1] Add apply-patches task to main pipeline in .tekton/podman-desktop-build.yaml
- [ ] T013 [US1] Create example patch patches/001-build-fix.patch (placeholder for actual build fixes)
- [ ] T014 [US1] Update patches/README.md with patch creation and testing instructions
- [ ] T015 [US1] Test apply-patches task in isolation with example patch
- [ ] T016 [US1] Verify patch failure scenarios report clear error messages

**Checkpoint**: Patch application is fully functional and can be tested independently

---

## Phase 4: User Story 2 - Automated Build from Upstream Source (Priority: P2)

**Goal**: Enable podman-desktop to build automatically from upstream GitHub repository with patches applied

**Independent Test**:
1. Trigger full pipeline build manually
2. Verify upstream source is cloned via submodule
3. Verify patches are applied successfully
4. Verify build completes end-to-end
5. Verify build artifacts are produced

**Dependencies**: Requires User Story 1 (P1) patch application capability

### Implementation for User Story 2

- [ ] T017 [P] [US2] Create .tekton/tasks/git-submodule-clone.yaml for cloning with submodules
- [ ] T018 [P] [US2] Create .tekton/tasks/validate-toolchain.yaml for fail-fast environment checks
- [ ] T019 [US2] Add git-submodule-clone task to main pipeline before apply-patches
- [ ] T020 [US2] Add validate-toolchain task to main pipeline as first step
- [ ] T021 [US2] Configure pipeline workspace for source code sharing between tasks
- [ ] T022 [US2] Configure pipeline parameters (revision, submodules flag, etc.)
- [ ] T023 [US2] Add dependency prefetching task reference (use standard Konflux task)
- [ ] T024 [US2] Add build execution task reference (use standard Konflux buildah task)
- [ ] T025 [US2] Configure artifact output and OCI registry push
- [ ] T026 [US2] Test full pipeline execution from source clone through artifact generation
- [ ] T027 [US2] Verify build completion meets 45-minute timeout requirement (SC-001)
- [ ] T028 [US2] Verify build failures are detected within 5 minutes (SC-006)

**Checkpoint**: Complete automated build from upstream source is functional

---

## Phase 5: User Story 3 - Flatpak Package Generation (Priority: P3)

**Goal**: Enable build pipeline to produce flatpak packages for podman-desktop

**Independent Test**:
1. Trigger flatpak build pipeline
2. Verify flatpak package is generated
3. Install flatpak package locally: `flatpak install --user <oci-ref>`
4. Launch application: `flatpak run io.podman_desktop.PodmanDesktop`
5. Verify desktop integration (icons, metadata) is correct

**Dependencies**: Requires User Story 2 (P2) successful build capability

### Implementation for User Story 3

- [ ] T029 [P] [US3] Create podman-desktop/Containerfile with multi-stage flatpak build
- [ ] T030 [P] [US3] Create podman-desktop/container.yaml flatpak manifest
- [ ] T031 [US3] Configure flatpak runtime, SDK, and package dependencies in container.yaml
- [ ] T032 [US3] Configure flatpak permissions and environment variables in container.yaml
- [ ] T033 [US3] Create .tekton/tasks/build-flatpak.yaml task for flatpak generation
- [ ] T034 [US3] Add build-flatpak task to main pipeline after source build
- [ ] T035 [US3] Configure SBOM generation for flatpak artifacts (use standard buildah SBOM generation)
- [ ] T036 [US3] Test flatpak build locally: `podman build -f podman-desktop/Containerfile`
- [ ] T037 [US3] Extract and test flatpak installation from built container
- [ ] T038 [US3] Verify flatpak package meets installability requirement (SC-004)
- [ ] T039 [US3] Add flatpak validation step to pipeline (FR-012)

**Checkpoint**: Flatpak package generation is complete and validated

---

## Phase 6: Tag-Triggered Builds & Artifact Retention

**Goal**: Enable automated builds from upstream tagged releases with appropriate retention policies

**Independent Test**:
1. Create test tag in upstream submodule reference
2. Trigger webhook (or simulate tag event)
3. Verify build is triggered automatically
4. Verify artifact retention policy is applied correctly
5. Verify tagged release builds are marked for indefinite retention

### Implementation

- [ ] T040 [P] Create .tekton/triggers/tag-release.yaml webhook trigger configuration
- [ ] T041 [P] Configure GitHub webhook for upstream repository tag events
- [ ] T042 Configure artifact retention logic (indefinite for tagged, 2 weeks for non-tagged)
- [ ] T043 Add tagging metadata to build artifacts (source_tag, retention_policy)
- [ ] T044 Test tag-triggered build workflow end-to-end
- [ ] T045 Verify artifact retention policy enforcement
- [ ] T046 Document tagged release build pattern for Konflux community (if novel)

**Checkpoint**: Automated tagged release builds are functional

---

## Phase 7: Pipeline Hardening & Error Handling

**Goal**: Implement robust error handling, logging, and resilience requirements

**Independent Test**:
1. Trigger builds with intentional failures (patch conflicts, missing dependencies, etc.)
2. Verify clear error messages for each failure type
3. Verify build logs contain sufficient troubleshooting information
4. Verify timeout and resource requirements are met

### Implementation

- [ ] T047 [P] Add detailed logging to all custom Tekton tasks
- [ ] T048 [P] Implement error handling for upstream repository access failures (FR-014)
- [ ] T049 [P] Implement error handling for dependency fetch failures (FR-014)
- [ ] T050 [P] Implement error handling for build compilation failures (FR-014)
- [ ] T051 [P] Implement error handling for flatpak validation failures (FR-014)
- [ ] T052 Configure pipeline timeout enforcement (45 minutes per SC-001)
- [ ] T053 Configure failure detection and notification (5 minutes per SC-006)
- [ ] T054 Test edge case: upstream source reference points to non-existent tag
- [ ] T055 Test edge case: flatpak runtime dependency unavailable
- [ ] T056 Test edge case: platform-specific code build failures
- [ ] T057 Verify all error scenarios produce actionable troubleshooting information

**Checkpoint**: Pipeline handles errors gracefully with clear diagnostics

---

## Phase 8: Documentation & Validation

**Goal**: Complete documentation and validate against quickstart.md workflows

**Independent Test**:
1. Follow quickstart.md from scratch as new developer
2. Verify all workflows execute successfully
3. Verify documentation is accurate and complete

### Implementation

- [ ] T058 [P] Update quickstart.md with actual pipeline names and paths
- [ ] T059 [P] Create patches/README.md with complete patch management workflow
- [ ] T060 [P] Document pipeline trigger procedures in quickstart.md
- [ ] T061 [P] Document troubleshooting scenarios in quickstart.md
- [ ] T062 Validate quickstart.md Workflow 1: Create and Test a Patch
- [ ] T063 Validate quickstart.md Workflow 2: Trigger Manual Pipeline Build
- [ ] T064 Validate quickstart.md Workflow 3: Test Patch Application Task Locally
- [ ] T065 Validate quickstart.md Workflow 4: Update to New Upstream Release
- [ ] T066 Validate quickstart.md Workflow 5: Verify Flatpak Build Locally
- [ ] T067 Validate quickstart.md Workflow 6: Monitor Tagged Release Builds
- [ ] T068 [P] Add architecture decision records for key design choices
- [ ] T069 [P] Update SUPPLY_CHAIN_GAPS.md with observed runtime behavior

**Checkpoint**: Documentation is complete and validated

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Story 1 (Phase 3)**: Depends on Foundational - No dependencies on other stories
- **User Story 2 (Phase 4)**: Depends on Foundational AND User Story 1 (requires patch application)
- **User Story 3 (Phase 5)**: Depends on Foundational AND User Story 2 (requires successful build)
- **Tag Triggers (Phase 6)**: Depends on User Stories 1-3 completion (requires full pipeline)
- **Hardening (Phase 7)**: Depends on all user stories (tests full pipeline)
- **Documentation (Phase 8)**: Depends on all implementation phases

### User Story Dependencies

- **User Story 1 (P1)**: Independent after Foundational - Patch application capability
- **User Story 2 (P2)**: Depends on User Story 1 - Needs patches to be applied during build
- **User Story 3 (P3)**: Depends on User Story 2 - Needs successful build before flatpak packaging

### Within Each User Story

- Tasks marked [P] can run in parallel (different files)
- Sequential dependencies within stories as indicated by task descriptions
- Checkpoint validation after each story before proceeding

### Parallel Opportunities

- **Setup Phase**: T003, T004, T005 can run in parallel
- **User Story 1**: T013, T014 can run in parallel
- **User Story 2**: T017, T018 can run in parallel
- **User Story 3**: T029, T030, T031, T032 can run in parallel
- **Phase 6**: T040, T041 can run in parallel
- **Phase 7**: T047-T051 can run in parallel
- **Phase 8**: T058-T061, T068-T069 can run in parallel

---

## Parallel Example: User Story 3

```bash
# Launch all flatpak configuration tasks together:
Task: "Create podman-desktop/Containerfile with multi-stage flatpak build"
Task: "Create podman-desktop/container.yaml flatpak manifest"
Task: "Configure flatpak runtime, SDK, and package dependencies in container.yaml"
Task: "Configure flatpak permissions and environment variables in container.yaml"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T007)
2. Complete Phase 2: Foundational (T008-T010)
3. Complete Phase 3: User Story 1 (T011-T016)
4. **STOP and VALIDATE**: Test patch application independently
5. Verify patch application meets acceptance scenarios from spec.md

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 (Patch Application) → Test independently → Validate (MVP!)
3. Add User Story 2 (Automated Build) → Test independently → Validate
4. Add User Story 3 (Flatpak Generation) → Test independently → Validate
5. Add Tag Triggers (Phase 6) → Test tagged release workflow → Validate
6. Add Hardening (Phase 7) → Test error scenarios → Validate
7. Complete Documentation (Phase 8) → Validate all workflows

### Sequential Implementation (Recommended)

Given the dependencies between user stories (P2 requires P1, P3 requires P2):

1. **Week 1**: Setup + Foundational + User Story 1 (Patch Application)
   - Milestone: Can apply patches to upstream source
2. **Week 2**: User Story 2 (Automated Build from Upstream)
   - Milestone: Can build podman-desktop with patches applied
3. **Week 3**: User Story 3 (Flatpak Generation)
   - Milestone: Can produce installable flatpak packages
4. **Week 4**: Tag Triggers + Hardening + Documentation
   - Milestone: Production-ready automated builds

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently validatable against spec.md acceptance scenarios
- Stop at any checkpoint to validate story independently
- Pipeline testing requires remote Konflux cluster access (per plan.md constitution)
- Commit after each task or logical group
- Follow TDD approach for pipeline tasks: write task contract, test manually, implement
- Avoid: same file conflicts, assumptions about toolchain availability
