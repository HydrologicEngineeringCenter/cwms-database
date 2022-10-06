/**
back from
*/    


DECLARE
BEGIN
   INSERT INTO at_display_units
      SELECT 44, a.parameter_code, 'EN', b.display_unit_code_en
        FROM at_parameter a, cwms_base_parameter b
       WHERE a.base_parameter_code = b.base_parameter_code
         AND a.sub_parameter_id IS NULL;

   INSERT INTO at_display_units
      SELECT 44, a.parameter_code, 'SI', b.display_unit_code_si
        FROM at_parameter a, cwms_base_parameter b
       WHERE a.base_parameter_code = b.base_parameter_code
         AND a.sub_parameter_id IS NULL;
END;
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 301, 'SI',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = '%'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 301)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 301, 'EN',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = '%'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 301)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 302, 'SI',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = '%'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 302)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 302, 'EN',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = '%'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 302)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 303, 'SI',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = 'mg/l'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 303)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 303, 'EN',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = 'ppm'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 303)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 304, 'SI',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = 'mg/l'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 304)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 304, 'EN',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = 'ppm'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 304)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 305, 'SI',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = 'mg/l'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 305)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 305, 'EN',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = 'ppm'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 305)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 306, 'SI',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = 'mg/l'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 306)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 306, 'EN',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = 'ppm'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 306)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 307, 'SI',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = 'mg/l'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 307)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 307, 'EN',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = 'ppm'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 307)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 308, 'SI',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = 'g/l'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 308)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 308, 'EN',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = 'g/l'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 308)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 309, 'SI',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = 'mm'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 309)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 309, 'EN',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = 'in'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 309)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 310, 'SI',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = 'mm'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 310)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 310, 'EN',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = 'in'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 310)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 311, 'SI',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = 'cms'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 311)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 311, 'EN',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = 'cfs'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 311)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 312, 'SI',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = 'cms'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 312)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 312, 'EN',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = 'cfs'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 312)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 313, 'SI',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = 'cms'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 313)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 313, 'EN',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = 'cfs'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 313)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 314, 'SI',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = 'cms'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 314)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 314, 'EN',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = 'cfs'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 314)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 315, 'SI',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = 'cms'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 315)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 315, 'EN',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = 'cfs'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 315)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 316, 'SI',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = 'C'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 316)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 316, 'EN',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = 'F'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 316)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 317, 'SI',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = 'C'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 317)
            )
/
INSERT INTO at_display_units
            (db_office_code, parameter_code, unit_system,
             display_unit_code
            )
     VALUES (44, 317, 'EN',
             (SELECT a.unit_code
                FROM cwms_unit a, at_parameter b, cwms_base_parameter c
               WHERE unit_id = 'F'
                 AND b.base_parameter_code = c.base_parameter_code
                 AND a.abstract_param_code = c.abstract_param_code
                 AND b.parameter_code = 317)
            )
/
