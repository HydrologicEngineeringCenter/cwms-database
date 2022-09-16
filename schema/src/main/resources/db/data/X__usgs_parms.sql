-- 00010 - Temp-Water.Inst in C
insert
  into at_usgs_parameter
 values((select office_code from cwms_office where office_id = 'CWMS'),
        10,
        (select parameter_code
           from at_parameter
          where base_parameter_code = (select base_parameter_code
                                         from cwms_base_parameter
                                        where base_parameter_id = 'Temp'
                                      )
            and sub_parameter_id = 'Water'
        ),
        (select parameter_type_code
           from cwms_parameter_type
          where parameter_type_id = 'Inst'
        ),
        (select unit_code
           from cwms_unit
          where unit_id = 'C'
        ),
        1.0,
        0.0);
-- 00021 - Temp-Air.Inst in F
insert
  into at_usgs_parameter
 values((select office_code from cwms_office where office_id = 'CWMS'),
        21,
        (select parameter_code
           from at_parameter
          where base_parameter_code = (select base_parameter_code
                                         from cwms_base_parameter
                                        where base_parameter_id = 'Temp'
                                      )
            and sub_parameter_id = 'Air'
        ),
        (select parameter_type_code
           from cwms_parameter_type
          where parameter_type_id = 'Inst'
        ),
        (select unit_code
           from cwms_unit
          where unit_id = 'F'
        ),
        1.0,
        0.0);
-- 00045 - Precip.Total in in
insert
  into at_usgs_parameter
 values((select office_code from cwms_office where office_id = 'CWMS'),
        45,
        (select parameter_code
           from at_parameter
          where base_parameter_code = (select base_parameter_code
                                         from cwms_base_parameter
                                        where base_parameter_id = 'Precip'
                                      )
            and sub_parameter_id is null
        ),
        (select parameter_type_code
           from cwms_parameter_type
          where parameter_type_id = 'Total'
        ),
        (select unit_code
           from cwms_unit
          where unit_id = 'in'
        ),
        1.0,
        0.0);
-- 00060 - Flow.Inst in cfs
--
-- USGS specifies this is average discharge over 1 day but then uses it in
-- combination with instantaneous gage heights on hourly or sub-hourly data!
insert
  into at_usgs_parameter
 values((select office_code from cwms_office where office_id = 'CWMS'),
        60,
        (select parameter_code
           from at_parameter
          where base_parameter_code = (select base_parameter_code
                                         from cwms_base_parameter
                                        where base_parameter_id = 'Flow'
                                      )
            and sub_parameter_id is null
        ),
        (select parameter_type_code
           from cwms_parameter_type
          where parameter_type_id = 'Inst'
        ),
        (select unit_code
           from cwms_unit
          where unit_id = 'cfs'
        ),
        1.0,
        0.0);
-- 00061 - Flow.Inst in cfs
insert
  into at_usgs_parameter
 values((select office_code from cwms_office where office_id = 'CWMS'),
        61,
        (select parameter_code
           from at_parameter
          where base_parameter_code = (select base_parameter_code
                                         from cwms_base_parameter
                                        where base_parameter_id = 'Flow'
                                      )
            and sub_parameter_id is null
        ),
        (select parameter_type_code
           from cwms_parameter_type
          where parameter_type_id = 'Inst'
        ),
        (select unit_code
           from cwms_unit
          where unit_id = 'cfs'
        ),
        1.0,
        0.0);
-- 00062 - Elev.Inst in ft
insert
  into at_usgs_parameter
 values((select office_code from cwms_office where office_id = 'CWMS'),
        62,
        (select parameter_code
           from at_parameter
          where base_parameter_code = (select base_parameter_code
                                         from cwms_base_parameter
                                        where base_parameter_id = 'Elev'
                                      )
            and sub_parameter_id is null
        ),
        (select parameter_type_code
           from cwms_parameter_type
          where parameter_type_id = 'Inst'
        ),
        (select unit_code
           from cwms_unit
          where unit_id = 'ft'
        ),
        1.0,
        0.0);
-- 00065 - Stage.Inst in ft
insert
  into at_usgs_parameter
 values((select office_code from cwms_office where office_id = 'CWMS'),
        65,
        (select parameter_code
           from at_parameter
          where base_parameter_code = (select base_parameter_code
                                         from cwms_base_parameter
                                        where base_parameter_id = 'Stage'
                                      )
            and sub_parameter_id is null
        ),
        (select parameter_type_code
           from cwms_parameter_type
          where parameter_type_id = 'Inst'
        ),
        (select unit_code
           from cwms_unit
          where unit_id = 'ft'
        ),
        1.0,
        0.0);
-- 00095 - Cond.Inst in umho/cm
insert
  into at_usgs_parameter
 values((select office_code from cwms_office where office_id = 'CWMS'),
        95,
        (select parameter_code
           from at_parameter
          where base_parameter_code = (select base_parameter_code
                                         from cwms_base_parameter
                                        where base_parameter_id = 'Cond'
                                      )
            and sub_parameter_id is null
        ),
        (select parameter_type_code
           from cwms_parameter_type
          where parameter_type_id = 'Inst'
        ),
        (select unit_code
           from cwms_unit
          where unit_id = 'umho/cm'
        ),
        1.0,
        0.0);
-- 00096 - Conc-Salinity.Inst in mg/l
insert
  into at_usgs_parameter
 values((select office_code from cwms_office where office_id = 'CWMS'),
        96,
        (select parameter_code
           from at_parameter
          where base_parameter_code = (select base_parameter_code
                                         from cwms_base_parameter
                                        where base_parameter_id = 'Conc'
                                      )
            and sub_parameter_id = 'Salinity'
        ),
        (select parameter_type_code
           from cwms_parameter_type
          where parameter_type_id = 'Inst'
        ),
        (select unit_code
           from cwms_unit
          where unit_id = 'mg/l'
        ),
        0.001,
        0.0);
-- 72036 - Stor.Inst in ac-ft
insert
  into at_usgs_parameter
 values((select office_code from cwms_office where office_id = 'CWMS'),
        72036,
        (select parameter_code
           from at_parameter
          where base_parameter_code = (select base_parameter_code
                                         from cwms_base_parameter
                                        where base_parameter_id = 'Stor'
                                      )
            and sub_parameter_id is null
        ),
        (select parameter_type_code
           from cwms_parameter_type
          where parameter_type_id = 'Inst'
        ),
        (select unit_code
           from cwms_unit
          where unit_id = 'ac-ft'
        ),
        1000.0,
        0.0);
commit;
