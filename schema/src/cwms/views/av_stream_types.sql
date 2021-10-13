insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_STREAM_TYPES', null,
'
/**
 * Displays information about stream types
 *
 * @since CWMS 2.1
 *
 * @field stream_type_id       The Rosgen Stream Classification identifier
 * @field number_of_channels   The number of channels for the stream type
 * @field entrenchment_ratio   The entrenchment ratio for the stream type
 * @field width_to_depth_ratio The width/depth ratio for the stream type
 * @field sunuosity            The sinuosity for the stream type
 * @field slope                The slope for the stream type
 * @field channel_material     The channel material for the stream type
 */
');
CREATE OR REPLACE FORCE VIEW av_stream_types
(
    stream_type_id,
    number_of_channels,
    entrenchment_ratio,
    width_to_depth_ratio,
    sunuosity,
    slope,
    channel_material
)
AS
    SELECT      stream_type_id, number_of_channels, entrenchment_ratio,
                  width_to_depth_ratio, sinuosity, slope, channel_material
         FROM   cwms_stream_type
    ORDER BY   stream_type_id;

/
