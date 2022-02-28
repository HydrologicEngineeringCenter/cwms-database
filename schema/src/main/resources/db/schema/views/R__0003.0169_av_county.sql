/**
 * Displays location URLs
 *
 * @since CWMS 3.1 - JDK
 *
 * @field db_office_id  	the database owner of the location
 * @field location_code 	The location code of the location.
 * @field url_id		a short description of the the URL. Also the grouping/classification of the URL (i.e. "Local URL Link" or "National URL Link")
 * @field url_address   	The URL
 * @field url_title 	 	The title for URL display
 */
create or replace view av_county
as
SELECT l.db_Office_id
     , lu.location_code
     , l.location_id
     , lu.url_id
     , lu.url_address
     , lu.url_title
  FROM at_location_url lu
     , av_loc l
 WHERE lu.location_code = l.location_code
   AND l.unit_System = 'EN';

 CREATE OR REPLACE PUBLIC SYNONYM cwms_v_location_url FOR av_location_URL;
