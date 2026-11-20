# noctalia-osk

Fedora's [Noctalia](https://github.com/noctalia-dev/noctalia) package, rebuilt with
the lock-screen on-screen keyboard from upstream PR
[noctalia-dev/noctalia#5233](https://github.com/noctalia-dev/noctalia/pull/5233),
for [LegionForge](https://github.com/shad0wcrawl3r/LegionForge) on handhelds without
a keyboard. It adds `[lockscreen] keyboard = "auto" | "always" | "never"`.

## How releases work

- `.github/workflows/release.yml` runs daily, on changes to `patches/`, `build/` or
  `REVISION`, and by hand. It looks up Fedora 45's current `noctalia` version and,
  if there's no release for it yet, builds one.
- **Tag:** `<fedora noctalia EVR>-r<REVISION>`, e.g. `5.5.0-3.fc45-r1`. Bump `REVISION`
  when the patch or build changes for the same Fedora version.
- **Assets:** the RPM (release suffix `.lfosk`) and `SHA256SUMS`. Each RPM has a
  GitHub build-provenance attestation. Releases are immutable.
- **When Fedora's noctalia already includes the feature,** the release instead holds
  `upstream-has-feature.txt`, which tells consumers to use Fedora's package.
- **The build fails loudly** if the patch no longer applies.

## Verify a download

```sh
gh release download 5.5.0-3.fc45-r1 -R shad0wcrawl3r/noctalia-osk
sha256sum -c SHA256SUMS
gh attestation verify noctalia-*.rpm -R shad0wcrawl3r/noctalia-osk \
  --signer-workflow shad0wcrawl3r/noctalia-osk/.github/workflows/release.yml
```

## Build locally

```sh
podman build -f build/Containerfile -t noctalia-osk .
podman cp "$(podman create noctalia-osk):/out/." ./out/
```

## Licence

The build scripts are MIT (`LICENSE`). The patch comes from upstream Noctalia (MIT);
see its header for the pinned source commit and audit notes. Noctalia itself keeps
its own licence.
