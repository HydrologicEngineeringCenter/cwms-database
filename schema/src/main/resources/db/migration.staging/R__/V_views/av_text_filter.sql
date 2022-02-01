whenever sqlerror continue
delete from at_clob where id = '/VIEWDOCS/AV_TEXT_FILTER';
whenever sqlerror exit
insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_TEXT_FILTER', null,
'
/**
 * Displays information on text filters stored in the database
 *
 * @since CWMS 2.2
 *
 * @field text_filter_code Unique numeric code identifying the text filter in the database
 * @field office_id        The office owning the text filter
 * @field text_filter_id   The text identifier (name) of the text filter
 * @field description      The description of the text filter
 * @field is_regex         A flag (T/F) specifying whether the text filter uses regular expressions (T) or glob wildcards (F)
 * @field configuration_id The text identifier of the configuration to which the text filter belongs
 */
');
create or replace force view av_text_filter(
   text_filter_code,
   office_id,
   text_filter_id,
   description,
   is_regex,
   configuration_id)
as
     select tf.text_filter_code,
            o.office_id,
            tf.text_filter_id,
            tf.description,
            tf.is_regex,
            c.configuration_id
       from at_text_filter tf,
            at_configuration c,
            cwms_office o
      where o.office_code = tf.office_code
        and c.configuration_code = tf.configuration_code
   order by 2, 3;
/

begin
	execute immediate 'grant select on av_text_filter to cwms_user';
exception
	when others then null;
end;
/


create or replace public synonym cwms_v_text_filter for av_text_filter;
