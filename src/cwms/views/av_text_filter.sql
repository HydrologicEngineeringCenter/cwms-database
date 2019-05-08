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
 */
');
create or replace force view av_text_filter(
   text_filter_code,
   office_id,
   text_filter_id,
   description,
   is_regex)
as
     select tf.text_filter_code,
            o.office_id,
            tf.text_filter_id,
            tf.description,
            tf.is_regex
       from at_text_filter tf, cwms_office o
      where o.office_code = tf.office_code
   order by 2, 3;
/
