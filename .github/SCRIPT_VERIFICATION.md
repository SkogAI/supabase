# NPM Scripts Verification

## Purpose

This document describes the automated verification system for npm scripts in this repository.

## Quick Start

```bash
# Run verification
./scripts/verify_npm_scripts.sh
```

## What Gets Verified

The verification script checks:

1. **Prerequisites** - Docker, Supabase CLI, Deno, Node.js, sqlfluff
2. **Script Definitions** - All scripts defined in package.json
3. **File Existence** - Required files and directories
4. **Script Syntax** - Valid JSON and command syntax
5. **Test Coverage** - Test files for functions and database

## Results

The script provides:
- ✅ **Pass/Fail Status** for each check
- ⚠️ **Warnings** for missing optional dependencies
- ⊘ **Skipped** tests that require unavailable tools
- 📊 **Statistics** and success rate
- 📝 **Installation instructions** for missing tools

## Documentation

- **[VERIFICATION_RESULTS.md](../VERIFICATION_RESULTS.md)** - Detailed results
- **[NPM_SCRIPTS_REFERENCE.md](../NPM_SCRIPTS_REFERENCE.md)** - Quick reference
- **[scripts/verify_npm_scripts.sh](../scripts/verify_npm_scripts.sh)** - Verification script

## Integration

### Local Development

Run before committing:
```bash
./scripts/verify_npm_scripts.sh
```

### CI/CD

Can be added to workflows:
```yaml
- name: Verify npm scripts
  run: ./scripts/verify_npm_scripts.sh
```

### Pre-commit Hook

Add to `.git/hooks/pre-commit`:
```bash
#!/bin/bash
./scripts/verify_npm_scripts.sh || exit 1
```

## Maintenance

When adding new npm scripts:
1. Add script to `package.json`
2. Run verification: `./scripts/verify_npm_scripts.sh`
3. Update documentation if needed
4. Commit changes

## Support

For issues or questions:
- Check [VERIFICATION_RESULTS.md](../VERIFICATION_RESULTS.md)
- Review [NPM_SCRIPTS_REFERENCE.md](../NPM_SCRIPTS_REFERENCE.md)
- Open an issue on GitHub

---

**Last Updated:** 2025-10-08  
**Script Version:** 1.0.0
