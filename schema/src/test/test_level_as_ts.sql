CREATE OR REPLACE package &&cwms_schema..test_level_as_ts as

--%suite(Test level-as-ts retrieval code)
--%beforeall (setup)
--%afterall(teardown)
--%rollback(manual)

--%test (Test RETRIEVE_LOC_LVL_VALUES3)
procedure retrieve_level;

procedure setup;
procedure teardown;
END test_level_as_ts;
/
grant execute on test_level_as_ts to cwms_user;
CREATE OR REPLACE PACKAGE BODY &&cwms_schema..test_level_as_ts
AS
   --------------------------------------------------------------------------------
   -- procedure retrieve_level
   --------------------------------------------------------------------------------
   PROCEDURE retrieve_level
   IS
      location varchar(25) := 'test_level_as_ts';
      level_id varchar(50) := location || '.Flow.Ave.1Day.Regulating';
      seasonal_data seasonal_value_tab_t := seasonal_value_tab_t(
         seasonal_value_t(0, 0, 121.5),
         seasonal_value_t(0, 15, 150.3),
         seasonal_value_t(0, 30, 155.5),
         seasonal_value_t(0, 45, 160.3),
         seasonal_value_t(0, 60, 165.5),
         seasonal_value_t(0, 75, 166.3),
         seasonal_value_t(0, 90, 168.5),
         seasonal_value_t(0, 105, 170.3),
         seasonal_value_t(0, 120, 165.5),
         seasonal_value_t(0, 135, 160.3),
         seasonal_value_t(0, 150, 155.5),
         seasonal_value_t(0, 165, 150.3),
         seasonal_value_t(0, 180, 145.5),
         seasonal_value_t(0, 195, 140.3),
         seasonal_value_t(0, 210, 135.5),
         seasonal_value_t(0, 225, 130.3),
         seasonal_value_t(0, 240, 127.5),
         seasonal_value_t(0, 255, 124.3),
         seasonal_value_t(0, 270, 121.5),
         seasonal_value_t(0, 285, 126.3),
         seasonal_value_t(0, 300, 131.5),
         seasonal_value_t(0, 315, 144.3),
         seasonal_value_t(0, 330, 152.5),
         seasonal_value_t(0, 345, 160.3),
         seasonal_value_t(0, 360, 165.5),
         seasonal_value_t(0, 375, 160.3),
         seasonal_value_t(0, 390, 155.5),
         seasonal_value_t(0, 405, 150.3),
         seasonal_value_t(0, 420, 143.5));

      effective_date date := TO_DATE('2026-03-07 20:00:00', 'YYYY-MM-DD HH24:MI:SS');
      origin date := TO_DATE('2026-03-07 20:00:00', 'YYYY-MM-DD HH24:MI:SS');
      minutes number(3) := 435;
      units varchar2(3) := 'cms';
      office_id varchar2(3) := '&&office_id';

      specified_times ztsv_array := ztsv_array(
         ztsv_type(TO_DATE('2026-03-07 20:00:00', 'YYYY-MM-DD HH24:MI:SS'), 0, 0),
         ztsv_type(TO_DATE('2026-03-07 20:15:00', 'YYYY-MM-DD HH24:MI:SS'), 0, 0),
         ztsv_type(TO_DATE('2026-03-07 20:30:00', 'YYYY-MM-DD HH24:MI:SS'), 0, 0),
         ztsv_type(TO_DATE('2026-03-07 20:45:00', 'YYYY-MM-DD HH24:MI:SS'), 0, 0),
         ztsv_type(TO_DATE('2026-03-07 21:00:00', 'YYYY-MM-DD HH24:MI:SS'), 0, 0),
         ztsv_type(TO_DATE('2026-03-07 21:15:00', 'YYYY-MM-DD HH24:MI:SS'), 0, 0),
         ztsv_type(TO_DATE('2026-03-07 21:30:00', 'YYYY-MM-DD HH24:MI:SS'), 0, 0),
         ztsv_type(TO_DATE('2026-03-07 21:45:00', 'YYYY-MM-DD HH24:MI:SS'), 0, 0),
         ztsv_type(TO_DATE('2026-03-07 22:00:00', 'YYYY-MM-DD HH24:MI:SS'), 0, 0),
         ztsv_type(TO_DATE('2026-03-07 22:15:00', 'YYYY-MM-DD HH24:MI:SS'), 0, 0),
         ztsv_type(TO_DATE('2026-03-07 22:30:00', 'YYYY-MM-DD HH24:MI:SS'), 0, 0),
         ztsv_type(TO_DATE('2026-03-07 22:45:00', 'YYYY-MM-DD HH24:MI:SS'), 0, 0),
         ztsv_type(TO_DATE('2026-03-07 23:00:00', 'YYYY-MM-DD HH24:MI:SS'), 0, 0),
         ztsv_type(TO_DATE('2026-03-07 23:15:00', 'YYYY-MM-DD HH24:MI:SS'), 0, 0),
         ztsv_type(TO_DATE('2026-03-07 23:30:00', 'YYYY-MM-DD HH24:MI:SS'), 0, 0),
         ztsv_type(TO_DATE('2026-03-07 23:45:00', 'YYYY-MM-DD HH24:MI:SS'), 0, 0),
         ztsv_type(TO_DATE('2026-03-08 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 0, 0),
         ztsv_type(TO_DATE('2026-03-08 00:15:00', 'YYYY-MM-DD HH24:MI:SS'), 0, 0),
         ztsv_type(TO_DATE('2026-03-08 00:30:00', 'YYYY-MM-DD HH24:MI:SS'), 0, 0),
         ztsv_type(TO_DATE('2026-03-08 00:45:00', 'YYYY-MM-DD HH24:MI:SS'), 0, 0),
         ztsv_type(TO_DATE('2026-03-08 01:00:00', 'YYYY-MM-DD HH24:MI:SS'), 0, 0),
         ztsv_type(TO_DATE('2026-03-08 01:15:00', 'YYYY-MM-DD HH24:MI:SS'), 0, 0),
         ztsv_type(TO_DATE('2026-03-08 01:30:00', 'YYYY-MM-DD HH24:MI:SS'), 0, 0),
         ztsv_type(TO_DATE('2026-03-08 01:45:00', 'YYYY-MM-DD HH24:MI:SS'), 0, 0),
         ztsv_type(TO_DATE('2026-03-08 02:00:00', 'YYYY-MM-DD HH24:MI:SS'), 0, 0),
         ztsv_type(TO_DATE('2026-03-08 02:15:00', 'YYYY-MM-DD HH24:MI:SS'), 0, 0),
         ztsv_type(TO_DATE('2026-03-08 02:30:00', 'YYYY-MM-DD HH24:MI:SS'), 0, 0),
         ztsv_type(TO_DATE('2026-03-08 02:45:00', 'YYYY-MM-DD HH24:MI:SS'), 0, 0),
         ztsv_type(TO_DATE('2026-03-08 03:00:00', 'YYYY-MM-DD HH24:MI:SS'), 0, 0)
         );
      ts_values ztsv_array := ztsv_array();
      current_date date;
      type map is table of boolean index by varchar2(50);
      date_map map;
   BEGIN
      cwms_loc.CREATE_LOCATION(p_location_id=>location, p_db_office_id=>office_id,
                               p_elevation=>120, p_elev_unit_id=>'m', p_latitude=>76.5,
                               p_longitude=>-121.7, p_time_zone_id=>'UTC',
                               p_vertical_datum=>'NGVD29', p_horizontal_datum=>'NAD83',
                               p_public_name=>'Test Location', p_active=>'T');
      commit;
      dbms_output.put_line(level_id);

      cwms_level.STORE_LOCATION_LEVEL4(p_location_level_id=>level_id, p_level_value=>null,
                                       p_level_units=>units, p_effective_date=>effective_date,
                                       p_interval_origin=>origin, p_interval_minutes=>minutes,
                                       p_seasonal_values=>seasonal_data, p_office_id=>office_id,
                                       p_fail_if_exists=>'F', p_timezone_id=>'UTC');
      commit;
      ts_values := cwms_level.RETRIEVE_LOC_LVL_VALUES3(p_specified_times=>specified_times,
                                          p_location_level_id=>level_id,
                                          p_level_units=>units,
                                          p_office_id=>office_id);

      date_map := map();

      for i in 1..ts_values.count loop
         current_date := ts_values(i).date_time;

         if (date_map.exists(current_date)) then
            raise_application_error(-20001, 'Duplicate date found: ' || current_date);
         end if;

         date_map(current_date) := true;
      end loop;

      dbms_output.put_line('No duplicate dates found in specified_times array');
   END retrieve_level;
   PROCEDURE setup
   IS
      location varchar(25) := 'test_level_as_ts';
      office_id varchar2(3) := '&&office_id';
   BEGIN
      cwms_loc.CREATE_LOCATION(p_location_id=>location, p_db_office_id=>office_id,
                               p_elevation=>120, p_elev_unit_id=>'m', p_latitude=>76.5,
                               p_longitude=>-121.7, p_time_zone_id=>'UTC',
                               p_vertical_datum=>'NGVD29', p_horizontal_datum=>'NAD83',
                               p_public_name=>'Test Location', p_active=>'T');
   END;
   PROCEDURE teardown
   IS
      location varchar(25) := 'test_level_as_ts';
      office_id varchar2(3) := '&&office_id';
   BEGIN
      cwms_loc.DELETE_LOCATION_CASCADE(p_location_id=>location, p_db_office_id=>office_id);
   END teardown;
END test_level_as_ts;
/
SHOW ERRORS
/