# Dependency upgrade review — 2026-08-25

All nine Dependabot branches were updated onto `main` before review. Each PR is mergeable and passes the repository's test, lint, Ruby security, JavaScript security, and GitGuardian checks.

## Recommendations

| PR | Upgrade | Recommendation | Review notes |
| --- | --- | --- | --- |
| [#11](https://github.com/srolandmarshall/ffl-draft-2026/pull/11) | `solid_queue` 1.4.0 → 1.7.0 | Merge | Ruby 3.4 satisfies the newer Ruby requirement. Fibers and batches are opt-in; the existing worker configuration is unchanged. Production image build passed. |
| [#10](https://github.com/srolandmarshall/ffl-draft-2026/pull/10) | `image_processing` 1.14.0 → 2.0.3 | Merge with included fix | Version 2 no longer installs image backends transitively. The PR now explicitly declares `ruby-vips` with deferred loading. Full local tests, lint, importmap audit, CI, and production image build passed. |
| [#9](https://github.com/srolandmarshall/ffl-draft-2026/pull/9) | `tailwindcss-rails` 4.4.0 → 4.6.0 | Merge | Remains on Tailwind Rails v4. Production asset precompilation passed with Tailwind CLI 4.3.3. |
| [#8](https://github.com/srolandmarshall/ffl-draft-2026/pull/8) | `csv` 3.3.5 → 3.3.6 | Merge | Patch-level change; all CI and security checks passed. |
| [#6](https://github.com/srolandmarshall/ffl-draft-2026/pull/6) | `bootsnap` 1.24.6 → 1.25.0 | Merge | Boot/cache update; all CI and security checks passed. |
| [#5](https://github.com/srolandmarshall/ffl-draft-2026/pull/5) | `thruster` 0.1.22 → 0.1.25 | Merge | Patch-level proxy update. Production image build passed with the upgraded Linux binary. |
| [#4](https://github.com/srolandmarshall/ffl-draft-2026/pull/4) | `solid_cable` 3.0.12 → 4.0.2 | Merge last | Largest runtime change in the set. The existing adapter configuration and schema work unchanged in tests; CI and production image build passed. |
| [#2](https://github.com/srolandmarshall/ffl-draft-2026/pull/2) | `actions/checkout` v6 → v7 | Merge | The workflow uses ordinary `pull_request` and `push` triggers, so the new fork protections do not alter current behavior. Fresh CI passed. |
| [#1](https://github.com/srolandmarshall/ffl-draft-2026/pull/1) | `actions/cache` v4 → v6 | Merge | GitHub-hosted runner 2.336.0 is newer than the action's minimum runner version. Existing cache inputs remain compatible and fresh CI passed. |

## Suggested merge order

1. Workflow actions: #1, #2.
2. Low-risk library updates: #8, #6, #9.
3. Runtime packages: #5, #10, #11.
4. Solid Cable major update: #4.

Bundler PRs each modify `Gemfile.lock`. If GitHub marks a later one dirty after an earlier merge, update that branch from `main` and rerun CI before merging it.

## Verification performed

- Updated all nine branches from current `main` and confirmed every PR is mergeable.
- Confirmed all five repository checks pass on each PR.
- Reproduced and fixed #10's missing Vips backend and CI native-library loading failure.
- Ran #10 locally: 110 tests, 781 assertions, no failures; 167 RuboCop files, no offenses; importmap audit clean.
- Built production Docker images successfully for #11, #10, #9, #5, and #4, including bundle installation, Bootsnap precompilation, and Rails asset precompilation.

## Upstream references

- [Solid Queue releases](https://github.com/rails/solid_queue/releases)
- [Image Processing installation](https://github.com/janko/image_processing#installation)
- [Tailwind CSS for Rails releases](https://github.com/rails/tailwindcss-rails/releases)
- [Bootsnap changelog](https://github.com/rails/bootsnap/blob/main/CHANGELOG.md)
- [Thruster changelog](https://github.com/basecamp/thruster/blob/main/CHANGELOG.md)
- [Solid Cable releases](https://github.com/rails/solid_cable/releases)
- [Checkout changelog](https://github.com/actions/checkout/blob/main/CHANGELOG.md)
- [Cache action compatibility notes](https://github.com/actions/cache#whats-new)
