# Patch Management for Podman Desktop on Konflux

This directory contains patches applied to the upstream podman-desktop source before building. Patches enable build compatibility with Konflux environment without forking the upstream repository.

## Purpose

Patches address:
- Build configuration incompatibilities
- Platform-specific dependencies
- Flatpak-specific requirements
- Build script modifications for Konflux

## Patch Naming Convention

Patches must follow this naming pattern:

```
NNN-brief-description.patch
```

Where:
- `NNN`: Three-digit sequence number (001, 002, 003, ...)
- `brief-description`: Lowercase hyphenated description
- `.patch`: File extension

**Example**: `001-build-fix.patch`, `002-flatpak-config.patch`

## Patch Application Order

Patches are applied sequentially in numeric order. The apply-patches task processes them as:

```bash
for patch in patches/*.patch; do
  patch -p1 < "$patch"
done
```

**IMPORTANT**: Patch order matters if patches modify related code. Use sequence numbers to control order.

## Creating a Patch

### Method 1: Generate from Git Diff (Recommended)

1. Make changes in the podman-desktop submodule:

```bash
cd podman-desktop
# Make your edits...
git diff > ../patches/NNN-description.patch
cd ..
```

2. Verify the patch applies cleanly:

```bash
patch -p1 --dry-run < patches/NNN-description.patch
```

3. Add patch header documentation (optional but recommended):

```bash
cat > patches/NNN-description.patch << 'EOF'
# Patch: Brief description
# Upstream Version: v1.9.1
# Reason: Why this patch is needed
# Conflicts: Known conflicts with other patches (if any)

<generated diff content>
EOF
```

### Method 2: Manual Patch File Creation

```bash
diff -Naur podman-desktop.orig/file.txt podman-desktop/file.txt > patches/NNN-description.patch
```

## Testing Patches

Before committing a patch, validate it:

```bash
# Dry-run test (doesn't modify files)
patch -p1 --dry-run < patches/NNN-description.patch

# Check for conflicts with existing patches
cd podman-desktop
git checkout v1.9.1  # Reset to clean state
cd ..
for patch in patches/*.patch; do
  echo "Testing $patch..."
  patch -p1 --dry-run < "$patch" || echo "CONFLICT in $patch"
done
```

## Updating Patches for New Upstream Versions

When upgrading the podman-desktop submodule:

1. Update submodule to new tag:

```bash
cd podman-desktop
git fetch --tags
git checkout v1.10.0  # New version
cd ..
```

2. Test all patches:

```bash
for patch in patches/*.patch; do
  echo "Testing $patch against v1.10.0..."
  patch -p1 --dry-run < "$patch"
  if [ $? -ne 0 ]; then
    echo "PATCH CONFLICT: $patch needs updating"
  fi
done
```

3. For conflicting patches:
   - Manually re-apply changes to new code
   - Regenerate patch using Method 1 above
   - Update patch header with new version

4. Commit submodule and updated patches:

```bash
git add podman-desktop patches/
git commit -m "chore: update to podman-desktop v1.10.0 with refreshed patches"
```

## Patch Application in Pipeline

The `.tekton/tasks/apply-patches.yaml` task applies patches during build:

1. **Clone**: Upstream source cloned via git submodule
2. **Validate**: Each patch tested with --dry-run
3. **Apply**: Patches applied sequentially
4. **Fail-Fast**: Pipeline stops on first patch failure

## Troubleshooting

### Patch Fails to Apply

**Error**: `patch: **** malformed patch at line N`

**Solution**: Check patch format - must be unified diff format:

```bash
diff -u original.txt modified.txt > patch.patch
```

### Patch Conflicts

**Error**: `Hunk #N FAILED at line M`

**Solutions**:
1. Regenerate patch against current upstream version
2. Check if upstream already fixed the issue (patch no longer needed)
3. Resolve conflict manually and regenerate patch

### Wrong Patch Order

**Symptom**: Later patches fail because earlier patches weren't applied

**Solution**: Renumber patches to apply in correct dependency order

### Binary Files

**Error**: `Cannot create binary patch`

**Solution**: Patches only work for text files. For binary files:
- Use custom build script to copy files
- Document in SUPPLY_CHAIN_GAPS.md
- Consider if binary modification is necessary

## Best Practices

1. **Minimal Patches**: Only patch what's necessary for Konflux builds
2. **Document Intent**: Add patch headers explaining why the change is needed
3. **Upstream First**: Try to fix issues upstream before patching
4. **Test Regularly**: Validate patches against new upstream releases
5. **Version Tracking**: Note which upstream version each patch targets

## Example Patch Structure

```patch
# Patch: Enable Flatpak build compatibility
# Upstream Version: v1.9.1
# Reason: Flatpak runtime requires different environment setup
# Conflicts: None
# Upstream Issue: https://github.com/podman-desktop/podman-desktop/issues/XXXX

diff --git a/package.json b/package.json
index 1234567..abcdefg 100644
--- a/package.json
+++ b/package.json
@@ -10,7 +10,7 @@
   "scripts": {
-    "build": "electron-builder",
+    "build": "electron-builder --linux --target=dir",
   },
```

## Related Documentation

- [Konflux Build Pipeline](../../.tekton/podman-desktop-build.yaml)
- [Apply Patches Task](../../.tekton/tasks/apply-patches.yaml)
- [Upstream Podman Desktop](https://github.com/podman-desktop/podman-desktop)
- [Git Patch Documentation](https://git-scm.com/docs/git-format-patch)

## Support

For questions about patch management:
- Review this README
- Check `.tekton/tasks/apply-patches.yaml` implementation
- Consult [quickstart.md](../../specs/001-konflux-podman-desktop/quickstart.md) workflows
