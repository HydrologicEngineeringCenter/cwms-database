/*
 * Copyright (c) 2026
 * United States Army Corps of Engineers - Hydrologic Engineering Center (USACE/HEC)
 * All Rights Reserved.  USACE PROPRIETARY/CONFIDENTIAL.
 * Source may not be released without written approval from HEC
 */

CREATE OR REPLACE FORCE VIEW AV_PUBLISHED_TS (
    OFFICE_ID,
    LOCATION_ID,
    PUBLISHED_ID,
    NAMESPACE,
    PUBLIC_NAME,
    BASE_PARAMETER_CODE,
    CWMS_TS_ID,
    TS_CODE,
    LOCATION_CODE
) AS
SELECT
    tsi.db_office_id,
    tsi.location_id,
    p.published_id,
    p.namespace,
    p.public_name,
    p.base_parameter_code,
    tsi.cwms_ts_id,
    m.ts_code,
    m.location_code
FROM
    at_published_ts m
JOIN
    cwms_published_id p ON m.published_id = p.published_id
JOIN
    at_physical_location loc ON m.location_code = loc.location_code
JOIN
    cwms_v_ts_id tsi ON m.ts_code = tsi.ts_code;

COMMENT ON TABLE AV_PUBLISHED_TS IS 'Provides a clean join between AT_PUBLISHED_TS, CWMS_PUBLISHED_ID, AT_PHYSICAL_LOCATION, and CWMS_V_TS_ID for the CDA REST API';
