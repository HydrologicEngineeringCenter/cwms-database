create type vert_datum_offset_tab_t
/**
 * Holds a table of loc_lvl_cur_max_ind_t records.
 *
 * @since CWMS 2.2
 *
 * @see type vert_datum_offset_t
 */
as table of vert_datum_offset_t;
/
    

create or replace public synonym cwms_t_vert_datum_offset_tab for vert_datum_offset_tab_t;

