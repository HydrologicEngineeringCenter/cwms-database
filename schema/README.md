# CWMS Database Standards

# File naming

We use flyway to manage database updates which has some specific needs.
There are repeatable and versioned migrations.

For versioned migrations we use the following (starting at db/migration)

`V<year>/<major>/V<year.major.minor>__<brief description>.sql`

For example:
`V2022/1/V2022.1.2__rearrange_at_sec_tables.sql

Repeatable migrations are those files that start with R__

we will use the following to handle ordering:
anything in [] is optional

| Component | Format |
| -------- | --------|
| Package spec | R__0000_[aaaa_]_<name>.sql |
| Views | R__0001_[aaaa_]_<name>.sql |
| Triggers | R__0002_[aaaa_]_<name>.sql |
| Type bodies | R__0003_[aaaa_]_<name>.sql |
| Package bodies | R__0004_[aaaa_]_<name>.sql |

where aaaa is four letters used if any storing is required within the repeatable scripts during first run.

there is also

```
afterMigrate.sql
or afterMigration__<name>.sql
```
For any operations that should always run after any update.


and

```
afterClean.sql
afterClean__<name>.sql
```
To finalize cleanup. Note that files are run in alphabetical (lexographical) order.

Flyway will drop the CWMS_20 and CWMS_DBA schema objects quite fully but some things like profiles and roles are
not automatically dropped.
