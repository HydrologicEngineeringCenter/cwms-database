insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_STREAM_REACH', null,'
/**
 * Displays information about stream reaches
 *
 * @since CWMS 2.1
 *
 * @field stream_reach_location_code The reach location
 * @field stream_location_code       The stream that the reach is on
 * @field upstream_location_code     The upstream location of the reach
 * @field downstream_location_code   The downstream location of the reach
 * @field configuration_code         The configuration of the reach
 * @field comments                   Additional comments on the reach
 * @field upstream_bank              Bank for the upstream location
 * @field upstream_station           Station for the upstream location
 * @field downstream_bank            Bank for the downstream location
 * @field downstream_station         Station for the downstream location
 */
');

create or replace force view av_stream_reach as
select
    sr.stream_reach_location_code,
    sr.stream_location_code,
    sr.upstream_location_code,
    sr.downstream_location_code,
    sr.configuration_code,
    sr.comments,
    upl.bank as upstream_bank,
    upl.station as upstream_station,
    downl.bank as downstream_bank,
    downl.station as downstream_station
from
    at_stream_reach sr
    join at_stream_location upl on sr.upstream_location_code = upl.location_code
    join at_stream_location downl on sr.downstream_location_code = downl.location_code
/