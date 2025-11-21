# Supply Chain Gaps

This document tracks known supply chain hardening limitations for the Podman Desktop on Konflux proof-of-concept. Each gap represents an area where full supply chain security cannot yet be achieved due to technical, tooling, or process constraints.

**Status**: Initial gaps documented based on known infrastructure constraints.

**Last Reviewed**: 2025-01-19

---

## Active Gaps

### GAP-001: Upstream npm Package Dependencies Not Reproducible from Source

**Status**: Active | **Risk Level**: Medium | **Discovered**: 2025-11-19

**Description:**
Podman Desktop depends on npm packages that are not built from source. These packages are fetched from the npm registry and trusted implicitly, introducing a supply chain risk since they could be compromised at the registry level.

**Root Cause:**
npm ecosystem inherently relies on pre-built packages from centralized registries. Building all transitive dependencies from source would require significant infrastructure and tooling that doesn't exist in the npm ecosystem.

**Current Mitigation:**
- Use lock files (pnpm-lock.yaml) to pin exact versions and checksums
- Leverage Konflux's dependency prefetching with checksum verification
- SBOM generation captures all dependencies for audit

**Potential Future Solutions:**
- Implement source-based builds for critical dependencies
- Use npm package signing and verification tools
- Advocate for ecosystem-wide reproducible builds in npm

**Risk Assessment:**
- **Impact if Exploited**: Malicious code in dependencies could compromise builds
- **Likelihood**: Medium (npm registry attacks have occurred historically)
- **Compensating Controls**: Lock files, checksums, SBOM, provenance attestation

**Related Work:**
- npm registry security initiatives
- Sigstore npm signing integration

---

### GAP-002: Manual Patch Maintenance Without Automated Validation

**Status**: Active | **Risk Level**: Low | **Discovered**: 2025-11-19

**Description:**
Patches are manually created and maintained. When upstream podman-desktop changes, there is no automated system to validate that patches still apply cleanly or function correctly.

**Root Cause:**
Patch validation requires understanding semantic changes in upstream code. Automated tools can detect conflicts but not semantic breakage.

**Current Mitigation:**
- Patches numbered sequentially for deterministic ordering
- Test patch application with --dry-run before actual application
- Fail-fast on patch conflicts

**Potential Future Solutions:**
- Automated testing that validates patch functionality
- CI checks that test patches against upstream releases
- Patch regeneration automation

**Risk Assessment:**
- **Impact if Exploited**: Patch conflicts could cause build failures
- **Likelihood**: Medium (upstream changes frequently)
- **Compensating Controls**: Fail-fast error handling, manual testing

**Related Work:**
- Quilt or similar patch management tools
- Automated patch rebasing workflows

---

### GAP-003: Build Toolchain Not Hermetically Packaged

**Status**: Active | **Risk Level**: Medium | **Discovered**: 2025-11-19

**Description:**
Build toolchain (Node.js, pnpm, Electron) is assumed available in Konflux environment but not built from source or hermetically packaged.

**Root Cause:**
Custom builder images use pre-built toolchain binaries from upstream sources (e.g., Node.js official binaries). Hermetically building the entire toolchain from source is extremely complex.

**Current Mitigation:**
- Pin specific toolchain versions in custom builder image
- Validate toolchain presence and versions with fail-fast checks
- Document toolchain provenance

**Potential Future Solutions:**
- Build toolchain from source (high complexity)
- Use hermetically built toolchain distributions if available
- Improve toolchain validation and integrity checks

**Risk Assessment:**
- **Impact if Exploited**: Compromised toolchain could inject malicious code
- **Likelihood**: Low (official Node.js builds are signed and audited)
- **Compensating Controls**: Version pinning, validation, builder image from trusted source

**Related Work:**
- Hermetic toolchain initiatives
- Reproducible builds for compilers and interpreters

---

### GAP-004: Multi-Architecture Builds Deferred

**Status**: Active | **Risk Level**: Low | **Discovered**: 2025-11-19

**Description:**
Initial implementation focuses on x86_64 Linux builds only. arm64, ppc64le, and other architectures are not supported.

**Root Cause:**
Multi-architecture builds require either emulation (slow) or native builder nodes for each architecture. This is deferred as an enhancement to keep initial scope manageable.

**Current Mitigation:**
- Focus on x86_64 Linux (primary platform)
- Document architecture limitation
- Design pipeline to support future multi-arch expansion

**Potential Future Solutions:**
- Add QEMU emulation for cross-architecture builds
- Provision native builder nodes for arm64/ppc64le
- Use Konflux multi-platform controller when available

**Risk Assessment:**
- **Impact if Exploited**: N/A (not a security issue, feature limitation)
- **Likelihood**: N/A
- **Compensating Controls**: N/A

**Related Work:**
- Konflux multi-platform support
- buildah/podman multi-arch build features

---

### GAP-005: Potential Runtime npm/Electron Downloads Despite Prefetching

**Status**: Active | **Risk Level**: Medium | **Discovered**: 2025-11-19

**Description:**
Even with dependency prefetching, some npm packages or Electron binaries may attempt runtime downloads during the build phase, breaking network isolation.

**Root Cause:**
Some npm packages have install scripts that download native binaries at install time. Electron may download binaries despite prefetch if environment variables are not correctly configured.

**Current Mitigation:**
- Configure ELECTRON_MIRROR and ELECTRON_SKIP_BINARY_DOWNLOAD environment variables
- Use dependency prefetch task to cache all packages
- Monitor build logs for unexpected network activity

**Potential Future Solutions:**
- Enable network-off build execution after prefetch phase
- Comprehensive testing of offline build scenarios
- Patch problematic packages to disable runtime downloads

**Risk Assessment:**
- **Impact if Exploited**: Runtime downloads could fetch compromised binaries
- **Likelihood**: Medium (depends on package install scripts)
- **Compensating Controls**: Prefetch checksums, environment variables, monitoring

**Related Work:**
- Konflux hermetic build capabilities
- npm offline-mode enhancements

---

## Closed Gaps

*None yet. When gaps are resolved, they will be moved here with closure date and resolution method.*

---

## Gap Template

When documenting a new gap, use this format:

```markdown
### GAP-XXX: [Brief Title]

**Status**: Active | **Risk Level**: Critical/High/Medium/Low | **Discovered**: YYYY-MM-DD

**Description:**
[Clear explanation of what security property cannot be achieved]

**Root Cause:**
[Technical constraint, missing tooling, compliance blocker, or other fundamental limitation]

**Current Mitigation:**
[Any partial controls or compensating measures currently in place]

**Potential Future Solutions:**
- [Strategy 1: description and feasibility]
- [Strategy 2: description and feasibility]

**Risk Assessment:**
- **Impact if Exploited**: [What could go wrong]
- **Likelihood**: [How likely is exploitation]
- **Compensating Controls**: [What reduces the risk]

**Related Work:**
- [Links to issues, upstream bugs, standard body work, etc.]
```

---

## Example Gaps (for reference only)

These examples illustrate the type of gaps that might be documented:

### Example: macOS Notarization Remote Execution

**Status**: Example | **Risk Level**: Medium | **Discovered**: 2025-01-19

**Description:**
macOS notarization requires Apple's proprietary notarization service, which cannot be invoked from Linux containers. This forces the use of remote execution (SSH to macOS VM), breaking build hermeticity.

**Root Cause:**
Apple's notarization is a closed-source, macOS-only process requiring Xcode command-line tools. No open-source or Linux-compatible alternative exists.

**Current Mitigation:**
- Remote execution is logged and audited
- SSH keys are rotated and stored as Kubernetes Secrets
- VM access is restricted via RBAC

**Potential Future Solutions:**
- Use rcodesign's notarization support (if/when it supports Apple's notary service)
- Advocate for Apple to provide Linux-compatible notarization API
- Deploy macOS-based Tekton nodes (high infrastructure cost)

**Risk Assessment:**
- **Impact if Exploited**: Compromised macOS VM could inject malicious code into signed .dmg files
- **Likelihood**: Low (requires VM compromise + credential theft)
- **Compensating Controls**: RHTAS signing of final OCI artifact, VM isolation, audit logging

**Related Work:**
- rcodesign issue: [hypothetical link]
- Konflux macOS runner RFC: [hypothetical link]

---

## Gap Review Schedule

- **Quarterly Review**: Every 3 months, review all active gaps for:
  - Changes in upstream tooling (new releases, new features)
  - New mitigation strategies discovered
  - Risk level adjustments based on threat landscape

- **Closure Criteria**: A gap can be closed when:
  - Technical solution is implemented and verified in production
  - Compensating controls reduce risk to acceptable level (with stakeholder sign-off)
  - Architectural change eliminates the need (e.g., dropping macOS support)

---

## Contributing

When you discover a new supply chain gap:

1. Document it using the template above
2. Assign the next sequential GAP-XXX number
3. Set appropriate risk level (Critical/High/Medium/Low)
4. Link to related issues or tracking work
5. Discuss in PR review to validate risk assessment
