/**
 * Displays information on location group membership
 *
 * @since CWMS 2.1
 *
 * @field category_id            Location category (parent of location group)
 * @field group_id               Location group (child of location group)
 * @field location_code          Unique numeric code identfying the location
 * @field db_office_id           Office that owns the location
 * @field base_location_id       Base location of the location
 * @field sub_location_id        Sub-location, if any, of the location
 * @field location_id            The location
 * @field alias_id               The alias, if any, for the location in this location group
 * @field attribute              The numeric attribute, if any, for this location with respect to the location group (can be used for ordering, etc...)
 * @field ref_location_id        The referenced location, if any, for this location with repect to the location group
 * @field shared_alias_id        The alias, if any, shared by all members of the location group
 * @field shared_ref_location_id The referenced location, if any, shared by all members of the location group
 */
CREATE OR REPLACE VIEW av_loc_grp_assgn
(
    category_id,
    GROUP_ID,
    location_code,
    db_office_id,
    base_location_id,
    sub_location_id,
    location_id,
    alias_id,
    attribute,
    ref_location_id,
    shared_alias_id,
    shared_ref_location_id
)
AS
    SELECT    atlc.loc_category_id, atlg.loc_group_id, atlga.location_code,
                co.office_id db_office_id, abl.base_location_id,
                atpl.sub_location_id,
                abl.base_location_id || SUBSTR ('-', 1, LENGTH (atpl.sub_location_id)) || atpl.sub_location_id location_id,
                atlga.loc_alias_id, atlga.loc_attribute,
                abl2.base_location_id || SUBSTR ('-', 1, LENGTH (atpl2.sub_location_id)) || atpl2.sub_location_id ref_location_id,
                atlg.shared_loc_alias_id,
                abl3.base_location_id || SUBSTR ('-', 1, LENGTH (atpl3.sub_location_id)) || atpl3.sub_location_id shared_ref_location_id
      FROM    at_physical_location atpl,
                at_base_location abl,
                at_loc_group_assignment atlga,
                at_loc_group atlg,
                at_loc_category atlc,
                cwms_office co,
                at_physical_location atpl2,
                at_base_location abl2,
                at_physical_location atpl3,
                at_base_location abl3
     WHERE         atlga.location_code = atpl.location_code
                AND atpl.base_location_code = abl.base_location_code
                AND atlga.loc_group_code = atlg.loc_group_code
                AND atlg.loc_category_code = atlc.loc_category_code
                AND abl.db_office_code = co.office_code
                AND atpl2.location_code(+) = atlga.loc_ref_code
                AND atpl2.base_location_code = abl2.base_location_code(+)
                AND atpl3.location_code(+) = atlg.shared_loc_ref_code
                AND atpl3.base_location_code = abl3.base_location_code(+)
/