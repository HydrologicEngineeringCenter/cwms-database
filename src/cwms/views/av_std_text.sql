insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_STD_TEXT', null,
'
/**
 * Displays standard text information
 *
 * @since CWMS 3.2
 *
 * @field office_id   The office that owns the standard text
 * @field std_text_id The standard text identifier (key)
 * @field long_text   The long text (value) of the standard text, if any
 */
');
create or replace force view av_std_text (
   office_id,
   std_text_id,
   long_text)
as
select a.office_id,
       a.std_text_id,
       b.value as long_text
  from (select o.office_id,
               s.std_text_id,
               s.clob_code
          from at_std_text s,
               cwms_office o
         where s.office_code = o.office_code
       ) a
       left outer join
       (select clob_code,
               value
          from at_clob
       ) b on b.clob_code = a.clob_code
/

begin
	execute immediate 'grant select on av_std_text to cwms_user';
exception
	when others then null;
end;

create or replace public synonym cwms_v_std_text for av_std_text;
