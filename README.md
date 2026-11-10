# mc-serverpack

Custom datapack and server resource pack for our Minecraft server.

```
datapack/        raw datapack files (pack.mcmeta at the root)
resourcepack/    raw resource pack files (pack.mcmeta at the root)
MC_VERSION       Minecraft version of this release line (used in zip names)
scripts/build.sh builds both zips into dist/
```

## Datapack contents

- Mob heads (all skulls/heads incl. wall variants) are mineable with a pickaxe (`minecraft:mineable/pickaxe` tag).

## Resource pack contents

### Playing cards

Item models in the `vapors_cards` namespace. There are three styles: `classic`, `sepia` and `r_b_contrast`.

- `vapors_cards:<style>_cards`: a single card, selected via `custom_model_data` (float):
  `1`–`13` spades, `14`–`26` diamonds, `27`–`39` clubs, `40`–`52` hearts (ace → king each),
  `53` black joker, `54` red joker, otherwise the card back. Held cards in third person show the back.
- `vapors_cards:<style>_deck_stack`: a deck.

```mcfunction
give @s paper[item_model="vapors_cards:classic_cards",custom_model_data={floats:[40f]}]
```

See [resourcepack/CREDITS.md](resourcepack/CREDITS.md) for credits.

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
   - `datapack-<version>.<mc_version>.zip` – deployed to exaroton automatically (see below)
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
otherwise players may keep a stale cached copy. The exaroton deploy below does this automatically.

## Deployment (exaroton)

For the **latest** release, the Release workflow runs [scripts/deploy-exaroton.sh](scripts/deploy-exaroton.sh), which uses the
[exaroton API](https://developers.exaroton.com) to:

1. upload the datapack as `<level-name>/datapacks/mc-serverpack.zip` (stable name, replaced on every release)
2. set `resource-pack-sha1` in `server.properties`
3. announce and restart the server if it is online (otherwise the changes apply on next start)

Setup in the GitHub repo settings → *Secrets and variables* → *Actions*:

| Kind     | Name                 | Value                                                        |
|----------|----------------------|--------------------------------------------------------------|
| Secret   | `SERVER_TOKEN`       | API token from https://exaroton.com/account/                 |
| Secret   | `SERVER_ID`          | server ID (shown in the server URL / `GET /v1/servers/`)     |

Remove any manually uploaded datapack zip from `datapacks/`, otherwise both are loaded.
