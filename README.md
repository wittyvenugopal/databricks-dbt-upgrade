# dbt v1 → v2 upgrade lab (Databricks)

A small dbt project written the "dbt 1.x way", plus the steps to check it for dbt v2 **before** you
migrate a real project. Everything here was run end to end on Databricks Free Edition.

- `dbt_project/` – the dbt project (sample data: customers, policies, claims).
  It builds on dbt 1.12. Every line marked `V2:` is something dbt v2 rejects or changes.
- `findings/v1_to_v2.diff` – every change needed to make it run on dbt v2 (autofix + 6 manual edits).
- `resources/` + `databricks.yml` – a Databricks job that builds it on dbt 1.12 and runs the v2 check.
- `local/profiles.yml` – connection profile for running dbt on your laptop.

## Result in one line

**dbt-autofix fixed most issues, 1 issue only showed up on a real v2 compile, 2 were silent (nothing
reported them), and after the fixes dbt v2 built everything (37/37) with output identical to dbt 1.12.**

## What the project uses

| Area | Where |
|---|---|
| Seeds (bronze) | `seeds/` – 4 CSVs, one is a lookup table |
| Macros | `to_pounds`, `clean_code`, `age_band` (CASE + `months_between`), `days_between` (`datediff`), `owner_team` (reads config), `product_channel_pairs` (Jinja loop) |
| Joins | `stg_claims` (left join to lookup), `dim_policy`, `fct_claims` |
| Window functions | `fct_claims` – `row_number()`, running `sum() over` |
| Incremental model | `fct_claims` (merge on `claim_id`) |
| Python model | `claims_summary_py` (runs on Databricks serverless) |
| Snapshot (SCD2) | `snapshots/policies_snapshot.sql` |
| Data tests | built-in (`unique`, `not_null`, `accepted_values`, `relationships`), `dbt_utils` tests, a custom generic test (`positive_value`), a singular test (`tests/`) |
| Unit test | `stg_claims_cleans_codes_and_converts_pence` in `_staging.yml` |
| Package | `dbt_utils` |

**Data tests vs unit tests.** A *data test* is a query over the built table; it fails if it returns rows
(`unique`, `not_null`, ... or your own SQL in `tests/`). dbt 1.8 renamed the YAML key `tests:` to `data_tests:`;
both still work in v2 (this repo uses both). A *unit test* (dbt 1.8+) runs a model on a few fixed input rows
and compares the result to expected rows – it checks the logic, not the data. `dbt build` runs both.

## Check any dbt project locally – step by step

The steps work on any dbt 1.x project, this one or yours. Do it on a **git branch**: autofix edits files in place.
Windows commands shown (`.venv\Scripts\activate`); on Mac/Linux use `source .venv/bin/activate`.

Set these once for your project (the values shown are for this repo):

| | This repo | Your project |
|---|---|---|
| Project folder | `dbt_project` | the folder with your `dbt_project.yml` |
| Profiles | `--profiles-dir ../local` | leave it out if you use `~/.dbt/profiles.yml`; the profile name must match `profile:` in `dbt_project.yml` |
| Adapter | `dbt-databricks` | your adapter, e.g. `dbt-snowflake` (check dbt v2 supports it) |

The commands below use this repo's values – swap in yours.

**0. Install dbt 1.12 + autofix** (keep the folder path short on Windows – long paths break the install)
```
python -m venv .venv
.venv\Scripts\activate
pip install "dbt-core>=1.12,<1.13" "dbt-databricks>=1.12,<2" dbt-autofix
cd dbt_project
dbt deps --profiles-dir ../local
```

**1. Must be clean on 1.12 first** – errors here must be fixed before anything else
```
dbt parse --profiles-dir ../local --no-partial-parse --show-all-deprecations
```
The summary at the end is your to-do list (this repo: 16 deprecation types).

**2. Packages**
```
dbt-autofix packages --dry-run
```

**3. Autofix**
```
dbt-autofix deprecations --dry-run       # see what it will change
dbt-autofix deprecations                 # safe fixes
dbt-autofix deprecations --behavior-change   # renames (e.g. exposure names) – review these
git diff
```

**4. v2 parser (still dbt 1.12)** – stops at the first error, so fix and repeat
```
dbt parse --profiles-dir ../local --use-v2-parser
```

**5. Real dbt v2** in a second venv – the only step that finds every problem.
Keep it separate: dbt 1.12 and dbt v2 both install a `dbt` command.
```
deactivate
cd ..
python -m venv .venv2
.venv2\Scripts\activate
pip install dbt
cd dbt_project
dbt parse   --profiles-dir ../local
dbt compile --profiles-dir ../local      # needs a connection, see below
dbt build   --profiles-dir ../local
```
For compile/build set `DATABRICKS_HOST` (no https://), `DATABRICKS_HTTP_PATH` (SQL warehouse → Connection
details) and `DATABRICKS_TOKEN`. In PowerShell: `$env:DATABRICKS_HOST = "..."`.

Build v2 into a **different schema** from v1 (another target or schema in your profile), or it overwrites the
v1 tables you want to compare against.

**6. Compare** the v1 and v2 tables (row counts, or `select * from a except all select * from b`).
This is the only step that catches silent changes (finding 19).

**7. Outside the project** – check job definitions, CI and scripts by hand (e.g. `-m` → `-s`);
`dbt-autofix jobs` only covers dbt Cloud jobs.

## Findings

| # | Issue (example in this repo) | Found by | Fix |
|---|---|---|---|
| 1 | `source-paths`, `data-paths` in dbt_project.yml | v1 warning, v2 parser **error** | autofix |
| 2 | `target-path`, `log-path` in dbt_project.yml | v1 warning | autofix (removes them) |
| 3 | config without `+` (`materialized: view`) | v1 warning | autofix |
| 4 | custom config keys (`+owner_team`, `pii_level` in `config()`, `contains_pii`, `data_owner` in the Python model) | v1 warning, v2 parser **error** | autofix (moves to `meta`) |
| 5 | `config.get("owner_team")` in a macro | – | autofix (→ `config.meta_get`) |
| 6 | test arguments not under `arguments:` | v1 warning | autofix |
| 7 | `tags`, `meta`, `freshness` as top-level properties | v1 warning | autofix (→ `config:`) |
| 8 | custom top-level YAML key, standalone YAML anchor | v1 warning | autofix (anchor is expanded inline) |
| 9 | duplicate YAML key (`description` twice) | v1 warning | autofix (keeps the **second**) |
| 10 | orphaned `{% endmacro %}` | v1 warning | autofix |
| 11 | exposure name with a space | v1 warning, v2 parser **error** | autofix `--behavior-change` |
| 12 | `modules.itertools` in a macro | v1 warning only – **v2 parser misses it**, v2 compile **fails** | manual: two `for` loops |
| 13 | `warn_error_options: include:` | v1 + v2 warning | manual: `include` → `error` |
| 14 | `dbt_modules` in `clean-targets` | – | manual: `dbt_packages` |
| 15 | `dbt run -m ...` in job commands | v1 warning | manual: `-s` (autofix `jobs` is for dbt Cloud only) |
| 16 | misspelt property (`desciption:`) | v1 warning, v2 parser **error** | autofix (renames it) |
| 17 | seed and model with the same name (`dispute_types`) | v1 warning (v1 quietly picks the seed), v2 parser **error** "ambiguous ref" | manual: rename the model |
| 18 | `require-dbt-version: [..., "<2.0.0"]` | **nothing** – v2 ignores it and runs anyway | manual: widen to `<3.0.0` |
| 19 | `modules.pytz` object attribute (`.zone`) | **nothing** – v2 compiles it to `''` | manual: plain string; found only by comparing output |

Already **errors on 1.12** (fix before anything else): duplicate `{% docs %}` names, model file names with spaces,
`modules-path` in dbt_project.yml, a model listed twice in YAML.

**Not a problem in v2** (tested): `tests:` instead of `data_tests:`, unit tests, Python models, code after
`return()` (same output), a disabled model calling a macro/var that no longer exists, SQL-block snapshots,
`invalidate_hard_deletes`, incremental merge, `dbt_utils` 1.x, a custom `generate_schema_name`,
`tests:` config in dbt_project.yml.
Jinja: `modules.re`, `modules.datetime`, `"{}".format()`, `%` formatting, `zip`, `namespace`, `dict.update`,
`adapter.dispatch`, `run_query`, `statement`/`load_result`, `graph.nodes`, `api.Relation`, `dbt_utils.star`.
Databricks SQL: `qualify`, lambdas (`transform(arr, x -> ...)`), `:` JSON paths, `::` casts, `pivot`, `group by all`.

## Run it on Databricks (Free Edition works)

Needs the Databricks CLI with a configured profile and a SQL warehouse named "Serverless Starter Warehouse"
(Free Edition has one; otherwise `--var warehouse_id=<id>`).
```
databricks bundle deploy -p <profile>
databricks bundle run v2_readiness_check -p <profile>
```
The job runs `dbt deps`, `dbt build` (1.12), `dbt run -m fct_claims`, `dbt parse --use-v2-parser`.
Expected: the first three pass, the last **fails** with `'source-paths' cannot be specified` = "not v2-ready".
Apply `findings/v1_to_v2.diff` (`git apply findings/v1_to_v2.diff`) and all four commands pass
(tested: 1.12 build PASS=37 with zero deprecation warnings, v2 parser clean; only `-m` still warns, finding 15).
Tables land in `workspace.dbt_upgrade_lab_<you>` (+ `_bronze`, `_snapshots`).

Clean up: `databricks bundle destroy -p <profile>`, then drop the schemas.

## Gotchas

- The v2 parser reports **one error at a time**. Run autofix first, then the parser.
- The v2 parser only parses. Jinja that fails at run time (`modules.itertools`) needs a real v2 `dbt compile`.
- Some changes are silent (findings 18, 19): no warning, no error. Only comparing v1 and v2 output finds them.
- Windows: autofix writes CRLF line endings (`.gitattributes` here normalises them); keep venv paths short.
- Git Bash turns `/sql/1.0/...` into a Windows path – set `DATABRICKS_HTTP_PATH` from PowerShell or cmd.

Tested 2026-11-20: dbt-core 1.12.7, dbt-databricks 1.13.1, dbt-autofix 0.22.6, dbt 2.0.12, Databricks Free Edition (serverless).
