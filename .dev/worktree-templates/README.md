# Worktree Templates

This directory contains templates that automatically configure worktrees for different development patterns.

## Overview

When creating a worktree with `.github/scripts/create-worktree.sh`, the appropriate template is automatically applied based on the worktree type (feature, bugfix, or hotfix).

## Template Structure

Each template directory contains:

- **`setup.sh`** - Auto-executed setup script that:
  - Copies environment variables
  - Installs dependencies
  - Starts Supabase
  - Resets database
  - Generates types
  - Displays type-specific checklist

- **`.env.example`** - Template environment variables

- **Type-specific files**:
  - Feature: `README.md` with workflow guide
  - Bugfix: `testing-checklist.md` for thorough bug testing
  - Hotfix: `deployment-checklist.md` for critical production fixes

## Templates

### Feature Template (`.dev/worktree-templates/feature/`)

For new features and enhancements that branch from `develop`.

**Includes**:
- Full development workflow guide
- Database migration examples
- RLS policy templates
- Edge function development guide
- Commit message examples

**Setup script**:
- Configures development environment
- Runs database migrations
- Generates TypeScript types
- Shows feature development checklist

### Bugfix Template (`.dev/worktree-templates/bugfix/`)

For bug fixes that branch from `develop`.

**Includes**:
- Comprehensive testing checklist
- Bug reproduction guide
- Root cause analysis steps
- Test-driven fix workflow

**Setup script**:
- Same as feature setup
- Emphasizes testing requirements

### Hotfix Template (`.dev/worktree-templates/hotfix/`)

For critical production fixes that branch from `master`.

**Includes**:
- Critical deployment checklist
- Production testing requirements
- Rollback planning
- Sign-off requirements

**Setup script**:
- Same base setup as feature
- Displays critical warnings
- Emphasizes production safety

## Usage

### Automatic (Recommended)

Templates are automatically applied when using the worktree creation script:

```bash
# Creates worktree and runs feature template setup
.github/scripts/create-worktree.sh 42 feature

# Creates worktree and runs bugfix template setup
.github/scripts/create-worktree.sh 87 bugfix

# Creates worktree and runs hotfix template setup
.github/scripts/create-worktree.sh 201 hotfix
```

### Manual

If you created a worktree manually, you can run the setup script:

```bash
cd .dev/worktree/my-worktree
bash ../../worktree-templates/feature/setup.sh
```

## Customizing Templates

### Adding Files to Templates

Place any files in the template directory that should be copied to new worktrees.

### Modifying Setup Scripts

Edit `setup.sh` in each template to customize the initialization process:

```bash
# Example: Add custom initialization
echo "Running custom setup..."
npm run custom:command
```

### Creating New Templates

1. Create new directory: `.dev/worktree-templates/my-type/`
2. Add `setup.sh` script
3. Add `.env.example`
4. Add any other template files
5. Update `create-worktree.sh` to recognize the new type

## Template Files

### setup.sh

All setup scripts follow this pattern:

1. **Environment Setup**
   - Copy `.env.example` to `.env`
   - Check/create environment file

2. **Dependency Installation**
   - Check for `node_modules`
   - Run `npm install` if needed

3. **Supabase Setup**
   - Check if Supabase is running
   - Start Supabase if needed
   - Reset database to apply migrations

4. **Type Generation**
   - Generate TypeScript types from schema

5. **Display Checklist**
   - Show type-specific checklist
   - Display useful commands
   - Provide next steps

### .env.example

Template environment variables that are copied to `.env` in new worktrees:

```bash
# Required
SUPABASE_OPENAI_API_KEY=your-openai-api-key-here

# Optional type-specific variables
CUSTOM_VAR=value
```

## Benefits

- **Consistency**: Every developer gets the same setup
- **Speed**: Automated setup saves time
- **Best Practices**: Templates enforce conventions
- **Documentation**: Type-specific guides are always available
- **Reduced Errors**: Automated setup prevents missing steps

## Troubleshooting

### Setup script fails

```bash
# Run setup script with debug output
bash -x ../../worktree-templates/feature/setup.sh
```

### Dependencies not installing

```bash
# Manual dependency installation
npm install
```

### Supabase won't start

```bash
# Check Docker is running
docker info

# Stop and restart Supabase
supabase stop
supabase start
```

### Types not generating

```bash
# Ensure Supabase is running
supabase status

# Manually generate types
npm run types:generate
```

## Related Documentation

- [Git Worktrees Guide](../../docs/WORKTREES.md)
- [Development Conventions](../../docs/CONVENTIONS.md)
- [Contributing Guide](../../CONTRIBUTING.md)
- [Worktree Creation Script](../../.github/scripts/create-worktree.sh)

## Examples

### Feature Worktree

```bash
.github/scripts/create-worktree.sh 42 feature
```

Output:
```
Creating worktree:
  Path: .dev/worktree/feature-add-user-profiles-42
  Branch: feature/add-user-profiles-42
  Base: develop

✓ Worktree created successfully!

Running feature template setup...

🚀 Setting up feature worktree...

📋 Creating .env from template...
   ✓ .env created (update with your API keys)

📦 Installing npm dependencies...
   ✓ Dependencies installed

🔍 Checking Supabase status...
   ✓ Supabase is running

🗄️  Applying database migrations...
   ✓ Database reset complete

📝 Generating TypeScript types...
   ✓ Types generated

✅ Feature Worktree Setup Complete!

📋 Feature Development Checklist:
   - [ ] Create migration: npm run migration:new <name>
   - [ ] Add RLS policies for new tables
   - [ ] Test RLS: npm run test:rls
   - [ ] Generate types: npm run types:generate
   - [ ] Write edge function tests
   - [ ] Update documentation
   - [ ] Test locally before pushing
```

### Bugfix Worktree

```bash
.github/scripts/create-worktree.sh 87 bugfix
```

Shows bug testing checklist and emphasizes reproducing the bug before fixing.

### Hotfix Worktree

```bash
.github/scripts/create-worktree.sh 201 hotfix
```

Shows critical warnings and deployment checklist for production fixes.

## Best Practices

1. **Don't skip template setup** - It ensures consistency
2. **Update .env with real values** - Templates use placeholders
3. **Follow type-specific checklists** - They prevent missing steps
4. **Keep templates simple** - Add only what's universally needed
5. **Document custom changes** - If you modify templates

## Contributing

To improve templates:

1. Test changes in a real worktree
2. Ensure setup script is idempotent (can run multiple times safely)
3. Keep setup fast (avoid unnecessary operations)
4. Add helpful output messages
5. Update this README with changes

---

**Questions?** See [CONVENTIONS.md](../../docs/CONVENTIONS.md) or ask in discussions.
