# Git Hooks

This directory contains git hooks that are shared with the team.

## Setup

To enable these hooks, run:

```bash
git config core.hooksPath .githooks
```

This only needs to be done once per clone of the repository.

## Available Hooks

### pre-commit

Automatically formats Gleam code before each commit using `gleam format`.
