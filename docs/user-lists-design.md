# User Lists Design

## Decision

This feature uses a dedicated `user-lists` model.

We are not reusing `AT_SEC_USER_GROUPS` and `AT_SEC_USERS` for this feature.

## Why

The existing security tables already support user-to-group membership, but they are tied to CWMS security semantics:

- privilege-group meaning is inferred from numeric code ranges
- existing views label those groups as security or TS-collection groups
- package logic treats those groups as administrative/security objects

That makes them the wrong abstraction for general purpose applications such as "I need a list of users given a user defined `name`"

## User List Model

The user-list model keeps user identity in the existing table:

- `AT_SEC_CWMS_USERS`

And adds two dedicated tables:

- `AT_USER_LISTS`
- `AT_USER_LIST_MEMBERS`

This keeps the new feature separate from privilege management while still reusing the current user rows.

## Scope

The local schema change implements:

- a table for list definitions
- a table for list membership
- a read view that returns list members with joined user identity data

It does not add PL/SQL CRUD APIs.

## Table Design

### `AT_USER_LISTS`

Stores list metadata.

Columns:

- `DB_OFFICE_CODE`
- `USER_LIST_ID`
- `USER_LIST_DESC`
- `OWNED_BY_USERID`
- `CREATE_DATE`
- `LAST_UPDATE_DATE`

Notes:

- `USER_LIST_ID` is the list identifier and display name
- lists are office-scoped
- ownership is optional

### `AT_USER_LIST_MEMBERS`

Stores the many-to-many relationship between lists and users.

Columns:

- `DB_OFFICE_CODE`
- `USER_LIST_ID`
- `USERID`
- `ADD_DATE`
- `ADDED_BY_USERID`

## Constraints

The implementation avoids new PL/SQL triggers.

Instead it uses relational constraints:

- primary keys
- foreign keys
- uppercase `CHECK` constraints for identifier columns

That keeps the change closer to plain SQL and easier to port later.

## Retrieval

The primary retrieval shape is a view:

- `AV_USER_LIST_MEMBERS`

That view joins:

- `AT_USER_LISTS`
- `AT_USER_LIST_MEMBERS`
- `CWMS_OFFICE`
- `AV_CWMS_USER`

This gives a direct way to query a list and get:

- list id
- office id
- member user id
- member full name
- member email

## Example Query

```sql
select user_list_id,
       office_id,
       user_id,
       full_name,
       email
  from av_user_list_members
 where office_id = :office_id
   and user_list_id = :user_list_id
 order by full_name, user_id;
```

## Requirements

This approach set the following requirements:

- reuse existing user rows
- support named user lists
- return members with name and email
- avoid introducing new PL/SQL for the core model
- keep the design easier to migrate to PostgreSQL or another relational database later

## Local Implementation

The local schema change adds:

- `AT_USER_LISTS`
- `AT_USER_LIST_MEMBERS`
- `AV_USER_LIST_MEMBERS`

It also updates the schema include files so these objects are created as part of the local build.
