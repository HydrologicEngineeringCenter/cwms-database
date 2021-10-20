insert
  into cwms_base_parameter
       (base_parameter_code,
        base_parameter_id,
        abstract_param_code,
        unit_code,
        display_unit_code_si,
        display_unit_code_en,
        long_name,
        description
       )
values (48,
        'Probability',
        (select abstract_param_code from cwms_abstract_parameter where abstract_param_id='None'),
        (select unit_code from cwms_unit where unit_id='n/a'),
        (select unit_code from cwms_unit where unit_id='n/a'),
        (select unit_code from cwms_unit where unit_id='n/a'),
        'Probability',
        'Expected fraction of all events for a specific event'
       );
commit;
