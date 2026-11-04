# Release builds

`.github/workflows/release.yml` builds the universal Release app on a GitHub runner and wraps
it in a `.pkg` that installs `Dau.app` into `/Applications`; the package postinstall clears
quarantine and opens the app, which installs and enables the input method itself (D37), so a
fresh install needs no logout.

Run it by hand (Actions → Release package → Run workflow) or push a `v*` tag; a tag also
attaches the package to a GitHub release.

## Two signing modes

| Secrets present | Signature | App Group (shared settings) |
|---|---|---|
| `MACOS_CERT_P12`, `MACOS_CERT_PASSWORD`, `KEYCHAIN_PASSWORD` | Apple Development, team 433PH64SVW | works |
| none | throwaway self-signed, no team in the signature | **rejected** — installs and runs, but the app and the input method cannot share settings |

A self-signed signature reports `TeamIdentifier=not set`, and containermanagerd requires the
group name to carry the signature team ID. Carrying `com.apple.developer.team-identifier`
with such a signature also makes the kernel kill the app at exec, so the script drops it.

To enable the working mode, export the Apple Development identity once:

```sh
security export -t identities -f pkcs12 -o cert.p12 "Apple Development: <name> (<ID>)"
base64 -i cert.p12 | gh secret set MACOS_CERT_P12 --repo <owner>/dau
gh secret set MACOS_CERT_PASSWORD --repo <owner>/dau   # the .p12 password
gh secret set KEYCHAIN_PASSWORD --repo <owner>/dau     # any throwaway password
```

## Scripts

- `build-pkg.sh <version>` — packages the build already in `build/DerivedData.noindex`
  (signs the package too, and keeps it unsigned if the identity cannot sign packages).
- `sign-app.sh <app> <identity>` — signs the input method and the host app inside out,
  with rendered entitlements (the Xcode build itself runs with signing disabled).
- `pkg/postinstall` — quarantine, stop the old copies, launch the app for the console user.
