# ADR 0001: Local-first modular Flutter application

- Status: Accepted
- Date: 2026-08-19

## Context

Countora must work without sign-in across mobile, desktop, and web while remaining maintainable and testable.

## Decision

Use Flutter as one cross-platform UI codebase. Keep timer/domain logic independent from widgets and plugins. Use explicit adapter interfaces for persistence and local notifications. Persist local state only; do not add a backend for the initial product.

## Consequences

The app remains usable offline and avoids account/privacy complexity. Platform notification behavior still requires target-specific verification. The persistence adapter can be replaced later without rewriting the domain model.
