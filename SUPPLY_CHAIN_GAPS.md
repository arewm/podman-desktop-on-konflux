# Supply Chain Gaps

This document tracks known supply chain hardening limitations for the Podman Desktop on Konflux proof-of-concept. Each gap represents an area where full supply chain security cannot yet be achieved due to technical, tooling, or process constraints.

**Status**: Initial gaps documented based on known infrastructure constraints.

**Last Reviewed**: 2025-01-19

---

## Active Gaps

### GAP-001: No macOS/Windows VM Infrastructure

**Status**: Active | **Risk Level**: Medium | **Discovered**: 2025-01-19

**Description:**
This PoC currently has no access to macOS or Windows VM infrastructure for native builds, platform-specific signing, or notarization. This limits the ability to produce fully-signed, notarized macOS .dmg/.app bundles and Windows .exe installers.

**Root Cause:**
Konflux infrastructure does not currently provide macOS/Windows VM nodes for this project. Multi-platform controller integration (if available) would require such infrastructure to be provisioned.

**Current Mitigation:**
- Focus on Linux-native builds (.AppImage, .flatpak)
- Evaluate cross-compilation tooling (Wine for Windows, rcodesign for macOS signing) as alternatives
- Document which platform-specific features cannot be achieved without VMs

**Potential Future Solutions:**
- Provision macOS/Windows VMs as Tekton nodes (high infrastructure cost, ongoing maintenance)
- Use Konflux multi-platform controller if/when it becomes available to this project
- Implement remote execution via SSH to external VMs (introduces non-hermetic risk, requires strict controls per Principle VI - now removed)
- Limit PoC scope to Linux-only builds if multi-platform is not critical for validation

**Risk Assessment:**
- **Impact if Exploited**: Not a direct security vulnerability; impacts feature completeness rather than security
- **Likelihood**: N/A (infrastructure limitation, not an attack vector)
- **Compensating Controls**: Linux builds can demonstrate Konflux capabilities; macOS/Windows gaps are explicitly documented

**Impact on PoC Goals:**
- **Blocking**: Only if multi-platform builds are required to validate Konflux capabilities
- **Non-Blocking**: If Linux builds are sufficient to demonstrate hermetic builds, OCI artifacts, Chains integration, and supply chain hardening
- **Enhancement**: VM infrastructure would improve completeness but may not be essential for initial validation

**Related Work:**
- Multi-platform controller availability assessment
- Cost/feasibility analysis for VM provisioning

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
