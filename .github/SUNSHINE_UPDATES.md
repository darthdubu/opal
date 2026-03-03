# Sunshine Updates via GitHub Actions

Opal uses Sunshine for in-app updates, backed by GitHub Releases.

## Required Secret

Set this repository secret before publishing tags:

- `EDDSA_PRIVATE_KEY_BASE64`: private signing key generated from Sunshine setup.

## Release Flow

1. Bump versions in:
   - `Cargo.toml` (`workspace.package.version`)
   - `Sources/OpalNext/BuildInfo.swift` (`opalVersion`)
   - `Opal/Sources/Opal/SettingsView.swift` (About display)
2. Commit and push to `main`.
3. Create and push a tag that matches the version:
   - `git tag vX.Y.Z`
   - `git push origin vX.Y.Z`

The `release.yml` workflow will:

- Build `Opal` and package `Opal.app`
- Produce `Opal.zip`
- Sign zip with Ed25519 and produce `Opal.sig`
- Generate `update-manifest.json` for Sunshine
- Upload all three assets to the GitHub Release for that tag

## Validation

The release workflow fails if tag version does not match:

- `Cargo.toml` version
- `Sources/OpalNext/BuildInfo.swift` version
