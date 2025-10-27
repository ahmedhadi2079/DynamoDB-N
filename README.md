# ddb-integration

Terraform for DDB Integration

## Getting started

### Pre-Commit
1. Install pre-commit from https://pre-commit.com/#install
2. Install the Gitleaks Pre-Commit Hook
```bash
pre-commit install
```
3. Test the Installation
```bash
pre-commit run --all-files
```
4. Committing Changes

    Now, every time your team members attempt to commit changes, the pre-commit hook will automatically run Gitleaks to scan for secrets.
