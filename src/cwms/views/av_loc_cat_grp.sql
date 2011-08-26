insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_LOC_CAT_GRP', null,
'
/**
 * Displays information about location categories and groups
 *
 * @since CWMS 2.0
 *
 * @field cat_db_office_id       Office that owns the location category
 * @field loc_category_id        Location category (parent of location group)
 * @field loc_category_desc      Description of location category
 * @field grp_db_office_id       Office that owns the location group
 * @field loc_group_id           Location group
 * @field loc_group_desc         Description of the loction group
 * @field shared_loc_alias_id    The alias, if any, shared by all members of the location group
 * @field shared_ref_location_id The referenced location, if any, shared by all members of the location group
 */
');
CREATE OR REPLACE VIEW av_loc_cat_grp
(
    cat_db_office_id,
    loc_category_id,
    loc_category_desc,
    grp_db_office_id,
    loc_group_id,
    loc_group_desc,
    shared_loc_alias_id,
    shared_ref_location_id
)
AS
    SELECT    co.office_id cat_db_office_id, loc_category_id, loc_category_desc,
                coo.office_id grp_db_office_id, loc_group_id, loc_group_desc,
                shared_loc_alias_id,
                abl.base_location_id || SUBSTR ('-', 1, LENGTH (atpl.sub_location_id)) || atpl.sub_location_id shared_ref_location_id
      FROM    cwms_office co,
                cwms_office coo,
                at_loc_category atlc,
                at_loc_group atlg,
                at_physical_location atpl,
                at_base_location abl
     WHERE         atlc.db_office_code = co.office_code
                AND atlg.db_office_code = coo.office_code(+)
                AND atlc.loc_category_code = atlg.loc_category_code(+)
                AND atpl.location_code(+) = atlg.shared_loc_ref_code
                AND atpl.base_location_code = abl.base_location_code(+)
/