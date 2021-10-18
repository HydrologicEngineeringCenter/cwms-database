insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_BASIN', null,
'
/**
 * Displays basin information
 *
 * @since CWMS 2.1
 *
 * @field office_id                  The office that owns this basin
 * @field basin_id                   The text identifier of this basin
 * @field primary_stream_id          The identifier of the primary stream that flows through this basin
 * @field parent_basin_id            The identifier of a larger basin that encompasses this basin
 * @field sort_order                 A number that specifies the sort order of this basin with respect to other basins that have the same parent basin
 * @field total_drainage_area        The total area of this basin
 * @field contributing_drainage_area The drainage area that contributes flow to the downstream extent
 * @field area_unit                  The unit the drainages areas are expressed in
 * @field basin_code                 The unique numeric code that identifies the basin in the database
 * @field primary_stream_code        The unique numeric code that identifies the primary stream in the database
 * @field parent_basin_code          The unique numeric code that identifies the parent basin in the database
 */
');
create or replace force view av_basin(
   office_id,
   basin_id,
   primary_stream_id,
   parent_basin_id,
   sort_order,
   total_drainage_area,
   contributing_drainage_area,
   area_unit,
   basin_code,
   primary_stream_code,
   parent_basin_code)
as
   select o.office_id,
          bl1.base_location_id || substr('-', 1, length(pl1.sub_location_id)) || pl1.sub_location_id as basin_id,
          bl2.base_location_id || substr('-', 1, length(pl2.sub_location_id)) || pl2.sub_location_id as primary_stream_id,
          bl3.base_location_id || substr('-', 1, length(pl3.sub_location_id)) || pl3.sub_location_id as parent_basin_id,
          b.sort_order,
          to_number(b.total_drainage_area * cu.factor + cu.offset) as total_drainange_area,
          to_number(b.contributing_drainage_area * cu.factor + cu.offset) as contributing_drainage_area,
          cu.to_unit_id as area_unit,
          b.basin_location_code as basin_code,
          b.primary_stream_code,
          b.parent_basin_code
     from at_basin b,
          at_base_location bl1,
          at_physical_location pl1,
          at_base_location bl2,
          at_physical_location pl2,
          at_base_location bl3,
          at_physical_location pl3,
          cwms_unit_conversion cu,
          cwms_office o
    where pl1.location_code = b.basin_location_code
      and bl1.base_location_code = pl1.base_location_code
      and o.office_code = bl1.db_office_code
      and pl2.location_code(+) = b.primary_stream_code
      and bl2.base_location_code(+) = pl2.base_location_code
      and pl3.location_code(+) = b.parent_basin_code
      and bl3.base_location_code(+) = pl3.base_location_code
      and cu.from_unit_id = cwms_util.get_default_units('Area', 'SI')
/

