alter table at_streamflow_meas modify (ctrl_cond_id varchar2(20));
alter table cwms_usgs_rating_ctrl_cond modify (ctrl_cond_id varchar2(20));
insert into cwms_usgs_rating_ctrl_cond values ('Unknown',              'The stream control conditions are unknown.'                );
insert into cwms_usgs_rating_ctrl_cond values ('Unspecifed',           'The stream control conditions were not specified.'         );
insert into cwms_usgs_rating_ctrl_cond values ('Clear',                'The stream control was clear of any obstructions.'         );
insert into cwms_usgs_rating_ctrl_cond values ('FillControlChanged',   'The stream control was filled.'                            );
insert into cwms_usgs_rating_ctrl_cond values ('ScourControlChanged',  'The stream control has scour conditions.'                  );
insert into cwms_usgs_rating_ctrl_cond values ('DebrisLight',          'The stream control was lightly covered with debris.'       );
insert into cwms_usgs_rating_ctrl_cond values ('DebrisModerate',       'The stream control was moderately covered with debris.'    );
insert into cwms_usgs_rating_ctrl_cond values ('DebrisHeavy',          'The stream control was heavily covered with debris.'       );
insert into cwms_usgs_rating_ctrl_cond values ('VegetationLight',      'The stream control was lightly covered with moss/algae.'   );
insert into cwms_usgs_rating_ctrl_cond values ('VegetationModerate',   'The stream control was moderately covered with moss/algae.');
insert into cwms_usgs_rating_ctrl_cond values ('VegetationHeavy',      'The stream control was heavily covered with moss/algae.'   );
insert into cwms_usgs_rating_ctrl_cond values ('IceAnchor',            'The stream control is covered with anchor ice.'            );
insert into cwms_usgs_rating_ctrl_cond values ('IceCover',             'The stream control was covered by ice.'                    );
insert into cwms_usgs_rating_ctrl_cond values ('IceShore',             'The stream control has shore ice.'                         );
insert into cwms_usgs_rating_ctrl_cond values ('Submerged',            'The stream control was submerged.'                         );
insert into cwms_usgs_rating_ctrl_cond values ('NoFlow',               'There was no flow over the stream control.'                );

