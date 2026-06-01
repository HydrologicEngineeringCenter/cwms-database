delete from at_clob where office_code = 53 and id = '/VIEWDOCS/AV_USER_LIST_MEMBERS';
insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_USER_LIST_MEMBERS', null,
'
/**
 * Displays user-list membership with joined CWMS user identity data
 *
 * @field office_id          The CWMS office identifier that owns the user list
 * @field db_office_code     The numeric office code that owns the user list
 * @field user_list_id       The user list identifier
 * @field user_list_desc     The user list description
 * @field owned_by_userid    The user id of the list owner
 * @field user_id            The member user identifier
 * @field full_name          The member full name
 * @field email              The member email address
 * @field office_symbol      The member office symbol
 * @field member_office_id   The member office id
 * @field add_date           The date the member was added to the list
 * @field added_by_userid    The user id that added the member to the list
 */
');
create or replace view av_user_list_members (
   office_id,
   db_office_code,
   user_list_id,
   user_list_desc,
   owned_by_userid,
   user_id,
   full_name,
   email,
   office_symbol,
   member_office_id,
   add_date,
   added_by_userid)
as
select o.office_id,
       l.db_office_code,
       l.user_list_id,
       l.user_list_desc,
       l.owned_by_userid,
       u.user_id,
       u.full_name,
       u.email,
       u.office_symbol,
       u.office_id as member_office_id,
       m.add_date,
       m.added_by_userid
  from at_user_lists l
  join cwms_office o
    on o.office_code = l.db_office_code
  join at_user_list_members m
    on m.db_office_code = l.db_office_code
   and m.user_list_id = l.user_list_id
  join av_cwms_user u
    on u.user_id = m.userid;

grant select on av_user_list_members to cwms_user;
