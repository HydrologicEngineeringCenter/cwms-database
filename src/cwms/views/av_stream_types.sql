SHOW ERRORS;

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
