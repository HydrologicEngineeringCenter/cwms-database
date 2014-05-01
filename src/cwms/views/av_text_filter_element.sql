---------------------
-- AV_RATING_LOCAL --
---------------------
insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_TEXT_FILTER_ELEMENT', null,
'
/**
 * Displays information on text filter elements stored in the database
 *
 * @since CWMS 2.2
 *
 * @field text_filter_code Unique numeric code identifying the text filter in the database
 * @field office_id        The office owning the text filter
 * @field text_filter_id   The text identifier (name) of the text filter
 * @field is_regex         A flag (T/F) specifying whether the text filter uses regular expressions
 * @field element_sequence The order in which this element is applied
 * @field inclusion        Specifies whether this element is used include or exclude text 
 * @field filter_text      The glob-style wildcard mask or regular expression used to match text for this element 
 * @field regex_flags      The Oracle regular expression flags (match parameter) used with this element
 */
');
create or replace force view av_text_filter_element(
   text_filter_code,
   office_id,
   text_filter_id,
   is_regex,
   element_sequence,
   inclusion,
   filter_text,
   regex_flags)
as
     select tf.text_filter_code,
            o.office_id,
            tf.text_filter_id,
            tf.is_regex,
            tfe.element_sequence,
            case when tfe.include = 'T' then 'INCLUDE' else 'EXCLUDE' end as inclusion,
            tfe.filter_text,
            nvl(tfe.regex_flags, tf.regex_flags) as regex_flags
       from at_text_filter tf, at_text_filter_element tfe, cwms_office o
      where o.office_code = tf.office_code and tf.text_filter_code = tfe.text_filter_code
   order by 2, 3, 4
/