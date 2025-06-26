# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This repository contains a Nix flake configuration for macOS (aarch64-darwin) using nix-darwin and home-manager. The configuration manages system settings, installed packages, and user configurations for a development environment.

## Common Commands

```bash
# Rebuild the system configuration
darwin-rebuild switch --flake ~/projects/nix/.#Mac
```

## Architecture

The flake.nix defines:
- **System Configuration** (darwin): macOS system defaults, keyboard mappings, services, and fonts
- **Home Manager Configuration**: User-specific packages and program configurations

Always refer to flake.nix for current configuration details as it changes frequently.