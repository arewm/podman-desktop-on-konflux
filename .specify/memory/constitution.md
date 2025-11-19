<!--
SYNC IMPACT REPORT
Version: 0.0.0 → 1.0.0
Initial constitution creation for Podman Desktop on Konflux project

MODIFIED PRINCIPLES: None (initial creation)
ADDED SECTIONS:
  - All core principles (I-VI)
  - Security & Compliance section
  - Development Workflow section
  - Governance section

REMOVED SECTIONS: None

TEMPLATES REQUIRING UPDATES:
  ✅ plan-template.md - Constitution Check section compatible
  ✅ spec-template.md - Requirements align with principles
  ✅ tasks-template.md - Task structure supports principle-driven development

FOLLOW-UP TODOS:
  - Document macOS/Windows VM infrastructure gap in SUPPLY_CHAIN_GAPS.md (completed)
-->

# Podman Desktop on Konflux Constitution

## Core Principles

### I. Production-Grade Proof of Concept & Supply Chain Transparency

This project is a proof-of-concept that MUST demonstrate production-quality solutions to real-world challenges. All implementations MUST be fully functional—no stubs, templates, or placeholders are acceptable as "complete." Supply chain hardening gaps MUST be explicitly documented.

**Rules:**
- Code MUST be production-ready and fully functional, not demonstration scaffolding
- Template code or stub implementations MUST NOT be merged as completed work
- All build scripts, Tekton tasks, and automation MUST handle real-world edge cases (errors, retries, validation)
- Supply chain hardening gaps (areas where security cannot yet be fully achieved) MUST be documented in `SUPPLY_CHAIN_GAPS.md`
- Each documented gap MUST include:
  - Clear description of the security limitation
  - Root cause (technical constraint, missing tooling, compliance blocker)
  - Potential mitigation strategies for future work
  - Risk assessment (impact if exploited)
- Closing supply chain gaps MUST be tracked as follow-on work with explicit acceptance criteria

**Rationale:** This proof-of-concept exists to validate that Podman Desktop CAN be built securely on Konflux, not just that it theoretically could be. Stakeholders need production-grade evidence to make adoption decisions. Documenting unsolved gaps prevents false confidence and guides future hardening efforts.

### II. OCI Artifact Encapsulation

Build outputs MUST be encapsulated as OCI artifacts (trusted container image blobs) for immutable storage and provenance tracking.

**Rules:**
- Binaries (`.exe`, `.dmg`, `.AppImage`, `.flatpak`) MUST be packaged and pushed to OCI registry as artifacts
- Each artifact MUST have a unique immutable digest (SHA256)
- Artifact lineage (source commit → build → artifact) MUST be traceable via OCI metadata
- Artifact retrieval MUST use exact digests (via `oras pull`, `skopeo`, or equivalent)
- Alternative packaging formats (Flatpak, etc.) are acceptable if they support OCI-based distribution

**Rationale:** OCI artifacts provide immutable, auditable, and supply-chain-secured storage. This architecture enables secure handoffs between build and downstream consumers. Release pipeline specifics (e.g., GitHub Releases publication) are out of scope for this repository but MUST consume OCI artifacts.

### III. Provenance via Chains Integration

Build artifacts MUST have verifiable provenance via Tekton Chains integration, enabling consumers to validate that artifacts were produced by the official build pipeline.

**Rules:**
- OS-level signing (P12/PFX certificates) MUST be implemented for runtime trust (prevents "untrusted developer" warnings)
- Apple/Windows signing certificates MUST be injected as Kubernetes Secrets with RBAC restrictions
- Tekton Chains MUST be configured to automatically generate and sign provenance attestations
- Provenance attestations MUST be attached to OCI artifacts
- Consumers MUST be able to verify artifact provenance using standard tooling (`cosign verify-attestation`, etc.)

**Rationale:** OS-level signing ensures end-user trust (apps run without warnings). Chains integration provides cryptographic proof that artifacts were built by Konflux pipelines from specific source commits, enabling supply chain security validation.

### IV. Cross-Platform Build Compatibility via Linux Tooling

Platform-specific builds (Windows, macOS, Linux) SHOULD be compilable from Linux containers using cross-compilation tools where technically feasible.

**Rules:**
- Linux builds MUST be native (standard compilation)
- Windows builds SHOULD use Wine/Mono-based tooling (`electronuserland/builder:wine`) if cross-compilation is viable
- macOS signing SHOULD use `rcodesign` (Linux-compatible alternative to Apple `codesign`) where applicable
- Multi-architecture builds (amd64, arm64) SHOULD leverage Konflux's multi-platform controller if available
- Platform build constraints (missing VM infrastructure, tooling gaps) MUST be documented as supply chain gaps

**Rationale:** Konflux runs on Linux. Cross-compilation maximizes automation and reduces infrastructure dependencies. However, some platform-specific tasks (macOS notarization, Windows-specific tooling) may require VM infrastructure that is currently unavailable. These gaps MUST be documented rather than ignored.

### V. Test-Driven Development for Pipeline Iteration

Build pipeline components (Tekton tasks, build scripts, dependency manifests) MUST follow TDD principles to enable fast feedback loops and isolated testing.

**Rules:**
- New Tekton tasks MUST have tests written before implementation
- Tasks MUST be testable in isolation via direct pipeline triggers (slash commands, manual invocation)
- PipelineAsCode (PAC) SHOULD be used for driving changes via push/pull events
- Pipeline tests MUST be runnable directly on cluster without requiring full PR workflow
- Changes to critical components (`artifacts.lock.yaml`, signing scripts, Containerfiles) MUST include verification tests
- Red-Green-Refactor cycle strictly enforced for infrastructure code

**Rationale:** Build pipelines are critical infrastructure. TDD ensures reliability and prevents regressions. Isolated testing enables faster iteration cycles than full integration testing. Direct pipeline execution (slash commands, manual triggers) allows developers to validate changes without waiting for PR automation.

### VI. Hermetic Build Integrity

Builds MUST execute in hermetic, network-isolated environments after dependency fetching to ensure reproducibility and prevent supply chain attacks.

**Rules:**
- Network access MUST be disabled during build execution phase
- All external dependencies (npm packages, binaries, build tools) MUST be pre-fetched and cached
- Dependency manifests (`yarn.lock`, `artifacts.lock.yaml`) MUST be complete and version-pinned
- Build processes MUST NOT attempt runtime downloads or external API calls
- Environment variables (`ELECTRON_SKIP_BINARY_DOWNLOAD`, `ELECTRON_MIRROR`) MUST redirect to local caches

**Rationale:** Hermetic builds ensure reproducibility, prevent supply chain attacks, enable offline/airgapped deployments, and guarantee build artifacts match source code exactly. While important, hermeticity is a technical implementation detail supporting the higher-level goals of production-grade PoC and provenance.

## Security & Compliance

### Secrets Management

- Signing certificates (P12, PFX) MUST be stored as Kubernetes Secrets with RBAC restrictions
- Secrets MUST NOT appear in logs, environment variable dumps, or artifact metadata
- Rotation procedures MUST be documented and executed quarterly (or per organizational policy)
- Expired certificates MUST trigger build failures, not warnings

### Dependency Auditing

- `yarn audit` and security scanning MUST run during dependency fetch phase
- Critical vulnerabilities (CVSS ≥ 8.0) MUST block builds unless explicitly waived with justification
- Dependency updates MUST be tracked in `artifacts.lock.yaml` changelog
- Supply chain attestation (SLSA Level 3) MUST be achieved for all OCI artifacts

### Compliance Verification

- Each build MUST generate SBOM (Software Bill of Materials) via Syft or equivalent
- SBOM MUST be attached to OCI artifact metadata
- Provenance attestations MUST be verifiable via standard tooling
- Compliance reports (dependency audit, SBOM, signature verification) MUST be archived for audit trails

### Platform Build Constraints

This PoC does NOT currently have access to macOS/Windows VM infrastructure for native builds or platform-specific operations (notarization, Windows-specific signing, etc.).

**Constraint Handling:**
- If multi-platform builds are NOT required for initial PoC validation, focus on Linux-native builds and cross-compilation where viable
- If multi-platform builds ARE required (e.g., for multi-platform controller integration), document this as a blocking infrastructure gap
- If VM infrastructure would improve the process but is not strictly required, document as an enhancement gap with workarounds
- All platform-specific constraints MUST be tracked in `SUPPLY_CHAIN_GAPS.md` with clear impact assessment

### Supply Chain Gaps Tracking

This project MUST maintain `SUPPLY_CHAIN_GAPS.md` at repository root documenting all known supply chain hardening limitations.

**Required Contents:**
- Each gap MUST be numbered (GAP-001, GAP-002, etc.) for trackability
- Each gap MUST include: description, root cause, potential mitigations, risk level (Critical/High/Medium/Low)
- Gaps MUST be reviewed quarterly and updated as tooling/processes improve
- Closed gaps MUST remain documented with closure date and resolution method

**Examples of Supply Chain Gaps:**
- No macOS/Windows VM infrastructure (blocks native builds, notarization, platform-specific signing)
- macOS notarization requiring Apple-proprietary tooling (if cross-compilation insufficient)
- Third-party binary dependencies not reproducible from source
- Build-time secrets stored in Kubernetes Secrets (not hardware-backed key store)
- Dependency lock files requiring manual review for upstream compromises

## Development Workflow

### Containerized Development

- All development MUST occur within devcontainers (Podman-based, NOT Docker)
- Host dependencies MUST be minimal (Podman, gh CLI, text editor)
- Python dependencies MUST use virtual environments (`venv`) within devcontainers
- Devcontainer configurations (`.devcontainer/`) MUST be version-controlled

### Branching & Commit Standards

- Feature branches MUST follow `###-feature-name` pattern (e.g., `001-hermetic-builds`)
- Commits MUST reference tasks or specifications (e.g., `feat(T012): add artifacts.lock.yaml`)
- Pre-commit hooks MUST enforce linting, formatting, and basic validation
- Merge to `main` MUST require passing CI checks (tests, builds, security scans)

### Documentation Requirements

- All architectural decisions (e.g., "why Wine for Windows builds") MUST be documented in `specs/`
- Build script changes MUST update corresponding `.md` files (e.g., `specs/###-feature/plan.md`)
- User-facing changes MUST include quickstart guide updates

## Governance

### Amendment Procedure

1. Propose change via issue or pull request with rationale
2. Discuss impact on existing principles and templates
3. Update constitution with version bump (MAJOR/MINOR/PATCH)
4. Propagate changes to affected templates (plan, spec, tasks)
5. Document migration path for existing features
6. Require approval from project maintainers before merge

### Versioning Policy

- **MAJOR**: Backward incompatible governance changes (e.g., removing a principle, changing core workflow)
- **MINOR**: New principle added or significant expansion of existing principle
- **PATCH**: Clarifications, wording improvements, typo fixes

### Compliance Review

- All pull requests MUST verify compliance with constitution principles
- Templates (`plan-template.md`, `spec-template.md`, `tasks-template.md`) MUST include constitution checks
- Violations MUST be justified in writing (see `plan-template.md` Complexity Tracking section)
- Unjustified violations MUST block merge

### Runtime Development Guidance

For ongoing development practices and agent-specific guidance, refer to `.specify/templates/agent-file-template.md` and command-specific workflows in `.specify/templates/commands/`.

**Version**: 1.0.0 | **Ratified**: 2025-01-19 | **Last Amended**: 2025-01-19
