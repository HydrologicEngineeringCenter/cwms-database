CREATE TYPE embankment_obj_t
  /**
   * Holds information about an embankment at a CWMS project
   *
   * @see type embankment_tab_t
   *
   * @member project_location_ref Identifies the CWMS project
   * @member embankment_location  Location information about the embankment
   * @member structure_type       The type of the embankment structure
   * @member upstream_prot_type   The type of upstream protection of the embankment
   * @member downstream_prot_type The type of downstream protection of the embankment
   * @member upstream_sideslope   The slope of the upstream side of the embankment
   * @member downstream_sideslope The slope of the downstream side of the embankment
   * @member structure_length     The length of the embankment
   * @member height_max           The maximum height of the embankment
   * @member top_width            The top width of the embankment
   * @member units_id             The unit of length, height, and width
   */
AS
  OBJECT
  (
    project_location_ref location_ref_t,    --The project this embankment is a child of
    embankment_location location_obj_t,     --The location for this embankment
    structure_type lookup_type_obj_t,       --The lookup code for the type of the embankment structure
    upstream_prot_type lookup_type_obj_t,   --The upstream protection type code for the embankment structure
    downstream_prot_type lookup_type_obj_t, --The downstream protection type codefor the embankment structure
    upstream_sideslope BINARY_DOUBLE,       --Param: ??. The upstream side slope of the embankment structure
    downstream_sideslope BINARY_DOUBLE,     --Param: ??. The downstream side slope of the embankment structure
    structure_length BINARY_DOUBLE,         --Param: Length. The overall length of the embankment structure
    height_max BINARY_DOUBLE,               --Param: Height. The maximum height of the embankment structure
    top_width BINARY_DOUBLE,                --Param: Width. The width at the top of the embankment structure
    units_id VARCHAR2(16)                   --The units id of the lenght, width, and height values
  );
/


create or replace public synonym cwms_t_embankment_obj for embankment_obj_t;

