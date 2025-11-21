# Quickstart: Konflux Onboarding for Podman Desktop

**Feature**: 001-konflux-podman-desktop
**Last Updated**: 2025-11-19

## Overview

This guide helps developers get started with the Konflux build pipeline for podman-desktop. It covers local development setup, pipeline testing, and common workflows.

## Prerequisites

### Required Access
- Konflux platform account with build permissions
- GitHub repository access (podman-desktop/podman-desktop)
- OCI registry credentials (for artifact push/pull)

### Local Tools
- **Podman**: Container runtime (NOT Docker per constitution)
- **gh CLI**: GitHub command-line tool
- **kubectl/oc**: Kubernetes CLI for pipeline interaction
- **tekton CLI (tkn)**: Tekton pipeline CLI
- **Text editor**: VS Code with devcontainer support recommended

### Knowledge Prerequisites
- Basic understanding of Tekton pipelines
- Familiarity with git submodules
- Understanding of patch file format
- Flatpak packaging concepts

## Local Development Setup

### 1. Clone Repository

```bash
git clone https://github.com/YOUR_ORG/podman-desktop-on-konflux.git
cd podman-desktop-on-konflux
git checkout 001-konflux-podman-desktop
```

### 2. Start Devcontainer

```bash
# Open in VS Code with devcontainer extension
code .

# Or manually with Podman
podman build -t konflux-dev .devcontainer
podman run -it -v $(pwd):/workspace konflux-dev
```

### 3. Initialize Git Submodule

```bash
# Add upstream podman-desktop as submodule
git submodule add https://github.com/podman-desktop/podman-desktop.git podman-desktop

# Pin to specific release tag
cd podman-desktop
git checkout v1.10.0  # Replace with desired version
cd ..

# Commit submodule configuration
git add .gitmodules podman-desktop
git commit -m "Add podman-desktop submodule at v1.10.0"
```

### 4. Configure Konflux Access

```bash
# Login to Konflux cluster
oc login <konflux-api-url>

# Verify access to namespace
kubectl get pipelines -n <your-namespace>

# Verify Tekton pipelines are visible
tkn pipeline list -n <your-namespace>

# Configure OCI registry credentials (if needed)
kubectl create secret docker-registry oci-creds \
  --docker-server=<registry-url> \
  --docker-username=<username> \
  --docker-password=<password> \
  -n <your-namespace>
```

## Common Workflows

### Workflow 1: Create and Test a Patch

**Scenario**: You need to modify upstream source to enable builds in Konflux.

```bash
# 1. Make changes in submodule
cd podman-desktop
# ... edit files ...

# 2. Generate patch file
git diff > ../patches/001-build-fix.patch

# 3. Test patch application
cd ..
patch -p1 --dry-run < patches/001-build-fix.patch

# 4. If successful, commit patch
git add patches/001-build-fix.patch
git commit -m "Add patch for Konflux build compatibility"
```

### Workflow 2: Trigger Manual Pipeline Build

**Scenario**: Test the build pipeline with current configuration.

```bash
# 1. Ensure all changes are pushed
git push origin 001-konflux-podman-desktop

# 2. Trigger pipeline via tkn CLI
tkn pipeline start podman-desktop-build \
  -w source=source-pvc \
  -p revision=001-konflux-podman-desktop \
  -p submodules=true \
  --showlog

# 3. Monitor pipeline execution
tkn pipelinerun logs -f <pipelinerun-name>

# 4. Check task status
tkn pipelinerun describe <pipelinerun-name>
```

### Workflow 3: Test Patch Application Task Locally

**Scenario**: Validate patch application logic before running full pipeline.

```bash
# 1. Create test workspace
mkdir -p /tmp/test-workspace/source
cp -r . /tmp/test-workspace/source/

# 2. Run patch task directly
tkn task start apply-patches \
  -w source=/tmp/test-workspace/source \
  -p patches-path=patches \
  -p source-path=podman-desktop \
  --showlog

# 3. Verify patches applied
cd /tmp/test-workspace/source/podman-desktop
git diff --stat
```

### Workflow 4: Update to New Upstream Release

**Scenario**: A new podman-desktop version (v1.11.0) is released.

```bash
# 1. Update submodule reference
cd podman-desktop
git fetch --tags
git checkout v1.11.0
cd ..

# 2. Test existing patches
for patch in patches/*.patch; do
  echo "Testing $patch..."
  patch -p1 --dry-run < "$patch" || echo "CONFLICT: $patch"
done

# 3. Update conflicting patches if needed
# ... regenerate patches for new version ...

# 4. Commit submodule update
git add podman-desktop
git commit -m "Update podman-desktop to v1.11.0"

# 5. Push and trigger tagged build
git tag v1.11.0-konflux
git push --tags
```

### Workflow 5: Verify Flatpak Build Locally

**Scenario**: Test flatpak generation before pushing to Konflux.

```bash
# 1. Build flatpak container locally
podman build -f podman-desktop/Containerfile -t podman-desktop-flatpak:test .

# 2. Extract flatpak artifact
podman create --name temp-container podman-desktop-flatpak:test
podman cp temp-container:/output/podman-desktop.flatpak ./test-build.flatpak
podman rm temp-container

# 3. Install flatpak locally (user install)
flatpak install --user test-build.flatpak

# 4. Test flatpak launch
flatpak run io.podman_desktop.PodmanDesktop

# 5. Uninstall after testing
flatpak uninstall --user io.podman_desktop.PodmanDesktop
```

### Workflow 6: Monitor Tagged Release Builds

**Scenario**: Verify automated builds trigger when upstream tags are created.

```bash
# 1. Check trigger configuration
kubectl get triggers -n <your-namespace>
kubectl describe trigger tag-release -n <your-namespace>

# 2. Monitor webhook deliveries (via GitHub)
gh api repos/podman-desktop/podman-desktop/hooks/<hook-id>/deliveries

# 3. Watch for triggered pipeline runs
tkn pipelinerun list --label triggers.tekton.dev/trigger=tag-release

# 4. View triggered build logs
tkn pipelinerun logs -f <triggered-pipelinerun>
```

## Troubleshooting

### Issue: Patch Fails to Apply

**Symptoms**: `apply-patches` task fails with conflict error

**Diagnosis**:
```bash
# Check patch against current source
cd podman-desktop
git checkout <target-version>
patch -p1 --dry-run < ../patches/<failing-patch>
```

**Solutions**:
1. **Regenerate patch**: Make changes manually and recreate patch
2. **Update source version**: Ensure submodule is at correct tag
3. **Check patch order**: Verify patches apply in correct sequence

### Issue: Build Toolchain Not Found

**Symptoms**: `validate-toolchain` task fails

**Diagnosis**:
```bash
# Check builder image contents
podman run --rm <builder-image> node --version
podman run --rm <builder-image> pnpm --version
```

**Solutions**:
1. **Update builder image**: Modify `builder.Containerfile` with required tools
2. **Check version requirements**: Compare with upstream `package.json` engines
3. **Rebuild custom builder**: `podman build -f builder.Containerfile -t custom-builder:latest .`

### Issue: Network Isolation Breaks Build

**Symptoms**: Build fails with download errors despite prefetch

**Diagnosis**:
```bash
# Check build logs for network activity
tkn pipelinerun logs <pipelinerun> | grep -i "download\|fetch\|http"
```

**Solutions**:
1. **Document GAP-005**: Add to SUPPLY_CHAIN_GAPS.md if runtime download occurs
2. **Enhance prefetch**: Add missing dependencies to prefetch task
3. **Configure mirrors**: Set `ELECTRON_MIRROR` and similar environment variables

### Issue: Flatpak Installation Fails

**Symptoms**: Generated flatpak won't install

**Diagnosis**:
```bash
# Validate flatpak bundle
flatpak info --show-metadata test-build.flatpak

# Check for missing dependencies
flatpak run --command=ldd io.podman_desktop.PodmanDesktop /app/bin/podman-desktop
```

**Solutions**:
1. **Add runtime dependencies**: Update `podman-desktop/container.yaml` packages list
2. **Check permissions**: Verify flatpak permissions in manifest
3. **Validate manifest**: `flatpak-builder --show-manifest podman-desktop/container.yaml`

## Best Practices

### Patch Management
- **Number patches**: Use `001-`, `002-` prefixes for ordering
- **Describe patches**: Add comment header explaining purpose
- **Test before committing**: Always validate with `--dry-run`
- **Document target version**: Note which upstream version patch applies to

### Pipeline Testing
- **Test tasks in isolation**: Use `tkn task start` before full pipeline
- **Check logs frequently**: Monitor for unexpected behavior
- **Validate workspaces**: Ensure shared data persists between tasks

### Version Control
- **Pin submodule commits**: Always reference specific tags, not branches
- **Tag builds**: Create repository tags for release builds
- **Document changes**: Update CHANGELOG.md for each version bump

### Security
- **Never commit secrets**: Use Kubernetes Secrets for credentials
- **Verify signatures**: Check provenance attestations on artifacts
- **Audit dependencies**: Review SBOM for each build

## Next Steps

After completing quickstart:

1. **Read spec.md**: Understand full feature requirements
2. **Review plan.md**: See overall implementation strategy
3. **Check research.md**: Understand design decisions
4. **Explore contracts/**: Review Tekton task specifications
5. **Wait for tasks.md**: Implementation tasks generated in Phase 2 (`/speckit.tasks`)

## Additional Resources

- [Konflux Documentation](https://konflux-ci.dev/docs/)
- [Tekton Pipelines](https://tekton.dev/docs/pipelines/)
- [Flatpak Developer Documentation](https://docs.flatpak.org/)
- [Podman Desktop GitHub](https://github.com/podman-desktop/podman-desktop)
- [Git Submodules Guide](https://git-scm.com/book/en/v2/Git-Tools-Submodules)

## Support

For questions or issues:
- **Spec questions**: Review `specs/001-konflux-podman-desktop/spec.md`
- **Implementation details**: Check `specs/001-konflux-podman-desktop/plan.md`
- **Konflux issues**: Consult Konflux documentation or community
- **Pipeline failures**: Review `tkn pipelinerun logs` and error messages
