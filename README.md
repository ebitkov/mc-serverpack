# mc-serverpack

Custom datapack and server resource pack for our Minecraft server.

```
datapack/        raw datapack files (pack.mcmeta at the root)
resourcepack/    raw resource pack files (pack.mcmeta at the root)
MC_VERSION       Minecraft version of this release line (used in zip names)
scripts/build.sh builds both zips into dist/
```

## Versioning

We use [semver](https://semver.org), starting at `1.0.0`.

| Part  | Meaning                                                        |
|-------|----------------------------------------------------------------|
| MAJOR | large feature update, breaking change                          |
| MINOR | one release line per Minecraft version, own branch `MAJOR.MINOR.x` |
| PATCH | fixes and small additions within a release line                |

| Branch  | Minecraft | Data pack format | Resource pack format |
|---------|-----------|------------------|----------------------|
| `1.0.x` | 26.3      | 121.0            | 97.1                 |

`main` tracks the newest release line. Older `x.y.x` branches only receive patches.

### Starting a new release line (e.g. new MC version)

1. On `main`, update `MC_VERSION` and both `pack.mcmeta` files to the new pack formats, and port the packs.
2. Create the branch: `git switch -c 1.1.x && git push -u origin 1.1.x`
3. Add the line to the table above.

## Releasing

1. Make sure the commit is on its release branch (e.g. `1.0.x`) and pushed.
2. Tag and push:
   ```sh
   git tag v1.0.0
   git push origin v1.0.0
   ```
3. The [Release workflow](.github/workflows/release.yml) validates the tag against the branch,
   builds the packs and creates a GitHub release with:
   - `datapack-<version>.<mc_version>.zip` – download and upload to the server manually
     (e.g. `datapack-1.0.0.26.3.zip`)
   - `resourcepack-<version>.<mc_version>.zip`
   - `resourcepack.zip` + `resourcepack.zip.sha1` – stable name for the public URL

Only the highest version overall is marked **latest**, so a late patch on an older line
(e.g. `1.0.5` after `1.1.0`) never replaces the resource pack served to players.

Build locally with `scripts/build.sh 1.0.0`.

## Server setup

`server.properties`:

```properties
resource-pack=https://github.com/ebitkov/mc-serverpack/releases/latest/download/resourcepack.zip
resource-pack-sha1=<sha1 from the release notes>
require-resource-pack=true
```

Minecraft caches resource packs by SHA-1: update `resource-pack-sha1` after every release,
otherwise players may keep a stale cached copy.
