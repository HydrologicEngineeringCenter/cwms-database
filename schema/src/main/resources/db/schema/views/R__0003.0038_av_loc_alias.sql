/**
 * Displays information about location aliases
 *
 * @since CWMS 2.0
 *
 * @field category_id      Location category (parent of location group)
 * @field group_id         Location group (child of location category)
 * @field location_code    Unique number identifying the location
 * @field db_office_id     Office owning the location
 * @field base_location_id Base location of the location
 * @field sub_location_id  Sub-location of the location, if any
 * @field location_id      The location
 * @field alias_id         The alias for the location in this category/group
 */
CREATE OR REPLACE VIEW av_loc_alias
(
    category_id,
    GROUP_ID,
    location_code,
    db_office_id,
    base_location_id,
    sub_location_id,
    location_id,
    alias_id
)
AS
    SELECT    atlc.loc_category_id, atlg.loc_group_id, atlga.location_code,
                co.office_id db_office_id, abl.base_location_id,
                atpl.sub_location_id,
                abl.base_location_id || SUBSTR ('-', 1, LENGTH (atpl.sub_location_id)) || atpl.sub_location_id location_id,
                atlga.loc_alias_id
      FROM    at_physical_location atpl,
                at_base_location abl,
                at_loc_group_assignment atlga,
                at_loc_group atlg,
                at_loc_category atlc,
                cwms_office co
     WHERE         atlga.location_code = atpl.location_code
                AND atpl.base_location_code = abl.base_location_code
                AND atlga.loc_group_code = atlg.loc_group_code
                AND atlg.loc_category_code = atlc.loc_category_code
                AND atlga.loc_alias_id IS NOT NULL
                AND abl.db_office_code = co.office_code
/
