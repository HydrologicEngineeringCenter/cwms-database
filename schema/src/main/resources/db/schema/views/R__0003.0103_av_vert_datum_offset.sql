insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_VERT_DATUM_OFFSET', null,'
/**
 * Displays information on vertical datum offsets
 *
 * @since CWMS 2.1
 *
 * @field office_id           Office that owns the location
 * @field location_id         The location of the vertical datum offset
 * @field vertical_datum_id_1 The first vertical datum
 * @field vertical_datum_id_2 The second vertical datum
 * @field effective_date      The effective date of the offset
 * @field offset              The offset to add to a value in the first vertical datum to generate a value in the second vertical datum
 * @field description         A description (source of offset, etc...)
 */
');
create or replace force view av_vert_datum_offset(
   office_id,
   location_id,
   vertical_datum_id_1,
   vertical_datum_id_2,
   effective_date,
   offset,
   description)
as
   select o.office_id,
          bl.base_location_id || substr('-', 1, length(pl.sub_location_id)) || pl.sub_location_id as location_id,
          d.vertical_datum_id_1,
          d.vertical_datum_id_2,
          d.effective_date,
          d.offset,
          d.description
     from at_vert_datum_offset d,
          at_physical_location pl,
          at_base_location bl,
          cwms_office o
    where pl.location_code = d.location_code
      and bl.base_location_code = pl.base_location_code
      and o.office_code = bl.db_office_code
/
