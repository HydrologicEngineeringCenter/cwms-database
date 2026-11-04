/*
 * Copyright (c) 2026
 * United States Army Corps of Engineers - Hydrologic Engineering Center (USACE/HEC)
 * All Rights Reserved.  USACE PROPRIETARY/CONFIDENTIAL.
 * Source may not be released without written approval from HEC
 */

CREATE OR REPLACE FORCE VIEW AV_A2W_ATTRIBUTES (
    OFFICE_ID,
    LOCATION_ID,
    LOCATION_CODE,
    DATE_REFRESHED,
    NOTES,
    DISPLAY_FLAG,
    LAKE_SUMMARY_TF,
    OPENING_SOURCE_OBJ
) AS
SELECT
    l.db_office_id,
    l.location_id,
    attr.location_code,
    attr.date_refreshed,
    attr.notes,
    attr.display_flag,
    attr.lake_summary_tf,
    attr.opening_source_obj
FROM
    at_a2w_attributes attr
JOIN
    av_loc l ON l.location_code = attr.location_code
WHERE
    l.unit_system = 'SI';

COMMENT ON TABLE AV_A2W_ATTRIBUTES IS 'Provides a clean join between AT_A2W_ATTRIBUTES and AV_LOC for the CDA REST API and CMA';
