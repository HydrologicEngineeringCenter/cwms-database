# Time series display units

A time series can have a persistent preferred display unit for each unit system,
`EN` and `SI`. The preference belongs to the time series and applies to every
group containing it. It does not change stored data or the parameter's defaults.

```sql
begin
   cwms_ts.assign_ts_group(
      p_ts_category_id => 'Display',
      p_ts_group_id    => 'Riverbend',
      p_ts_id          => 'Riverbend.Elev.Inst.1Hour.0.Observed',
      p_db_office_id   => 'SWT',
      p_units         => 'm',
      p_unit_system   => 'EN');
end;
/
```

`p_units` and `p_unit_system` are appended to `assign_ts_group`; all seven existing
positional arguments retain their meanings. Omitting `p_units` preserves the
preference. Existing bulk assignment types and routines retain their signatures.
Bulk callers can use `set_ts_display_units` in the same transaction.

Use `set_ts_display_units(ts_id, units, unit_system, office_id)` independently of
group membership. Units must be convertible from the parameter's unit; aliases
are stored as canonical unit identifiers. Pass NULL for `units` to clear a
preference. Unit systems are case insensitive and must be `EN` or `SI`.
Selecting the parameter default also removes the override, so later changes to
that default can take effect.

`get_ts_display_units(ts_id, unit_system, office_id)` returns the preference or
the parameter default. Its last argument, `p_default_units => 'F'`, returns only a
preference that differs from the parameter default. `AV_TS_GRP_ASSGN` appends
`units_en` and `units_si` using that behavior, without changing existing columns
or multiplying assignment rows.

`retrieve_ts_f` consults the preference when units are omitted, then retains the
existing user/office fallback. `retrieve_time_series` uses the preference when the caller
requests `EN` or `SI`. Explicit physical units retain precedence. Parameter-only
lookups cannot select a time series preference and retain their behavior.

Preferences survive data-only deletion and soft deletion/undeletion. Physical
deletion of the time series removes its preferences through the foreign key.

## Installation and validation

Fresh schema builds include `AT_TS_DISPLAY_UNITS`. For an existing schema at the
current main revision, run
`schema/src/updateScripts/update_issue_223-ts_display_units.sql` as the schema
owner from its containing directory. This script creates the table and its
existing-style write guard, installs the service-user read policy, recompiles
the affected packages/view, and fails if those objects have compilation errors.
The feature script is intended to run once and should be included in the next
release migration by the release maintainer; it does not assign a release version.

Use a prepared build tree: `cwms_ts_pkg_body.sql` reads the generated
`schema/src/cwms/defines.sql`. For an isolated migration staging copy that has
not run `autobuild.py`, create that file with `define cwms_schema = CWMS_20`
and `define builduser = CWMS_20` on separate lines before running the migration.
Do not reuse generated definitions for a different schema.

Deploy the database change before enabling preference writes in CDA. Older
clients can continue to use their existing calls after the schema update.

Regression tests live in `test_cwms_ts.sql` alongside existing time series and
group tests. Run them through the repository's utPLSQL test workflow. Include
the ordinary group tests to check positional and bulk assignment compatibility.

To revert a development installation, first preserve any preference rows needed
later, restore the previous package and view definitions, then drop the new
table. DDL commits in Oracle, so rolling back a failed installation requires
restoring definitions rather than issuing a transaction rollback.
