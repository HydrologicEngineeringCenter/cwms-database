create type vert_datum_offset_t
/**
 * Holds a vertical datum conversion offset for a location
 *
 * @since CWMS 2.2
 *
 * @field location            The location the offset applies to
 * @field vertical_datum_id_1 The first vertical datum. Must be one of 'NGVD29', 'NAVD88', 'LOCAL' or 'STAGE'
 * @field vertical_datum_id_2 The second vertical datum. Must be one of 'NGVD29', 'NAVD88', 'LOCAL' or 'STAGE'
 * @field effective_date      The date and time the offset became effective.  The date 01-JAN-1000 represents a long-ago effective date
 * @field time_zone           The time zone of the effective date field
 * @field offset              The offset that must be ADDED to an elevation WRT to the first vertical datum to generate an elevation WRT to the second veritcal datum
 * @field unit                The unit of the offset
 * @field description         A description of the offset
 *
 * @see type location_ref_t
 * @see type vert_datum_offset_tab_t
 *
 */
as object(
   location            location_ref_t,
   vertical_datum_id_1 varchar2(16),
   vertical_datum_id_2 varchar2(16),
   effective_date      date,
   time_zone           varchar2(28),
   offset              binary_double,
   unit                varchar2(16),
   description         varchar2(64));
/
  

create or replace public synonym cwms_t_vert_datum_offset for vert_datum_offset_t;

