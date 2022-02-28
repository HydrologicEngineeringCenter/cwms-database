/**
 * Displays state counties
 *
 * @since CWMS 2.1
 *
 * @field county_id     A numeric county identifier unique within the state
 * @field county_name   The name of the county
 * @field state_initial The two letter abbreviation of the state the county is in
 */
create or replace force view av_county
(
   county_id,
   county_name,
   state_initial
)
as
select county_id,
       county_name,
       state_initial
  from cwms_county c, cwms_state s
 where s.state_code = c.state_code;
