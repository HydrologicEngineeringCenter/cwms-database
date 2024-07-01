insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_STREAM_REACH', null, '
/**
 * Contains non-geographic information for stream reaches
 *
 * @field stream_reach_location_code The reach location code
 * @field reach_id                   The location ID of the reach
 * @field stream_location_code       The stream location code that the reach is on
 * @field stream_id                  The stream location ID that the reach is on
 * @field upstream_location_code     The upstream location code of the reach
 * @field upstream_location_id       The upstream location ID of the reach
 * @field upstream_bank              Bank for the upstream location
 * @field upstream_station           Station for the upstream location
 * @field downstream_location_code   The downstream location code of the reach
 * @field downstream_location_id     The downstream location ID of the reach
 * @field downstream_bank            Bank for the downstream location
 * @field downstream_station         Station for the downstream location
 * @field configuration_code         The configuration code of the reach
 * @field configuration_id           The configuration id of the reach
 * @field comments                   Additional comments on the reach
 * @field office_id                  The office ID that owns this reach in the database
 * @field station_units              The unit of the station values (mi or km)
 */
');

create or replace force view av_stream_reach as
select distinct
    sr.stream_reach_location_code,
    rl.location_id as reach_id,
    sr.stream_location_code,
    sl.location_id as stream_id,
    sr.upstream_location_code,
    ul.location_id as upstream_location_id,
    upl.bank as upstream_bank,
    upl.station as upstream_station,
    sr.downstream_location_code,
    dl.location_id as downstream_location_id,
    downl.bank as downstream_bank,
    downl.station as downstream_station,
    case
        when sl.unit_system = 'EN' then 'mi'
        else 'km'
        end as station_units,
    sr.configuration_code,
    cfg.configuration_id,
    sr.comments,
    sl.db_office_id as office_id
from
    at_stream_reach sr
    inner join at_stream_location upl on sr.upstream_location_code = upl.location_code
    inner join av_loc ul on sr.upstream_location_code = ul.location_code
    inner join at_stream_location downl on sr.downstream_location_code = downl.location_code
    inner join av_loc dl on sr.downstream_location_code = dl.location_code
    inner join cwms_v_loc sl on sr.stream_location_code = sl.location_code
    inner join av_loc rl on sr.stream_reach_location_code = rl.location_code
    inner join at_configuration cfg on sr.configuration_code = cfg.configuration_code
/
