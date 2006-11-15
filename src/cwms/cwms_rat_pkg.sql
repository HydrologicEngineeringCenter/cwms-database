-------------------
-- Mike Perryman --
-- 27 Jan 2004   --
-------------------

SET TIME ON
SPOOL cwms_rat.lst
SELECT SYSDATE FROM DUAL;
SET ECHO ON


   
CREATE OR REPLACE PACKAGE cwms_rat
IS
   
   -------------------------------------------------------------------------------
   
   TYPE tab_varchar2_type IS TABLE OF VARCHAR2(19) INDEX BY BINARY_INTEGER; 
   
   -------------------------------------------------------------------------------
   
   log_output_to_table BOOLEAN := FALSE;
   
   -------------------------------------------------------------------------------
   
   PROCEDURE log_output (output_in IN VARCHAR2);
      
   PROCEDURE set_log_output_on;

   PROCEDURE set_log_output_off;

   PROCEDURE clear_log_table;
   
   FUNCTION parse_rating_id
      (
         rating_id_in      IN  VARCHAR2,
         location_out      OUT VARCHAR2,
         subLocation_out   OUT VARCHAR2,
         measured_1_out    OUT VARCHAR2,
         subMeasured_1_out OUT VARCHAR2,
         measured_2_out    OUT VARCHAR2,
         subMeasured_2_out OUT VARCHAR2,
         rated_out         OUT VARCHAR2,
         subRated_out      OUT VARCHAR2,
         rating_type_out   OUT VARCHAR2,
         version_out       OUT VARCHAR2
      )RETURN BOOLEAN;
      
   FUNCTION get_rating_code
      (
         office_in         IN  VARCHAR2, -- office id (e.g. "SWT")
         rating_id_in      IN  VARCHAR2, -- rating id (e.g. "Zenith.Stage:Flow.RatingStream.Test Option")
         case_sensitive_in IN  INTEGER,  -- use case sensitive matching ?
         create_in         IN  INTEGER,  -- create rating code if it doesn't exist ?
         created_out       OUT INTEGER   -- non-zero if code was created
      )RETURN AT_RATING_SPEC.RATING_CODE%TYPE;
   
   FUNCTION create_rating_spec
      (
         office_id_in      IN VARCHAR2, -- office id (e.g. "SWT")
         rating_id_in      IN VARCHAR2, -- rating id (e.g. "Zenith.Stage:Flow.RatingStream.Test Option")
         interpolate_id_in IN VARCHAR2, -- LIN_INTERP, STEP_PREV, etc
         underflow_id_in   IN VARCHAR2, -- NOT_ALLOWED, USE_NEAREST, etc
         overflow_id_in    IN VARCHAR2  -- NOT_ALLOWED, USE_NEAREST, etc
      )RETURN BOOLEAN;
      
   FUNCTION get_rating_ts_clob
      (
         rating_code_in     IN  AT_RATING_SPEC.RATING_CODE%TYPE,
         date_effective_in  IN  VARCHAR2,
         date_activated_out OUT VARCHAR2
      )RETURN CLOB;
   
   FUNCTION get_rating_ts_clob
      (
         rowid_in IN ROWID
      )RETURN CLOB;
      
   FUNCTION get_rating_ts_rowid
      (
         rating_code_in    IN  AT_RATING_SPEC.RATING_CODE%TYPE,
         date_effective_in IN  VARCHAR2,
         create_in         IN  INTEGER,  -- create record if it doesn't exist ?
         created_out       OUT INTEGER   -- non-zero if code was created
      )RETURN ROWID;
   
   FUNCTION get_rating_times_v
      (
         rating_code_in      IN AT_RATING_SPEC.RATING_CODE%TYPE,
         max_return_count_in IN INTEGER := 500
      )RETURN char_time_array;

   PROCEDURE get_rating_info
      (
         office_id_in         IN  VARCHAR2,
         rating_id_in         IN  VARCHAR2,
         case_sensitive_in    IN  INTEGER,
         rating_code_out      OUT AT_RATING_SPEC.RATING_CODE%TYPE,
         rating_id_out        OUT RT_RATING_TYPE.RATING_ID%TYPE,
         interpolation_id_out OUT RT_RATING_TS_INTERP_TYPE.INTERPOLATION_ID%TYPE,
         underflow_id_out     OUT RT_RATING_TS_EXTRAP_TYPE.EXTRAPOLATION_ID%TYPE,
         overflow_id_out      OUT RT_RATING_TS_EXTRAP_TYPE.EXTRAPOLATION_ID%TYPE,
         effective_times_out  OUT char_time_array
      );
      
   PROCEDURE set_behaviors
      (
         rating_code_in          IN AT_RATING_SPEC.RATING_CODE%TYPE,
         interpolate_behavior_in IN RT_RATING_TS_INTERP_TYPE.INTERPOLATION_ID%TYPE,
         underflow_behavior_in   IN RT_RATING_TS_EXTRAP_TYPE.EXTRAPOLATION_ID%TYPE,
         overflow_behavior_in    IN RT_RATING_TS_EXTRAP_TYPE.EXTRAPOLATION_ID%TYPE
      );
   
   PROCEDURE set_activated_time
      (
         rowid_in          IN ROWID,
         date_activated_in IN VARCHAR2
      );
   
   PROCEDURE get_location_and_parameters
      (
         rating_code_in       IN  INTEGER,
         office_id_out        OUT VARCHAR2,
         location_id_out      OUT VARCHAR2,
         sub_location_id_out  OUT VARCHAR2,
         parameter_m1_out     OUT VARCHAR2,
         sub_parameter_m1_out OUT VARCHAR2,
         units_m1_out         OUT VARCHAR2,
         parameter_m2_out     OUT VARCHAR2,
         sub_parameter_m2_out OUT VARCHAR2,
         units_m2_out         OUT VARCHAR2,
         parameter_r_out      OUT VARCHAR2,
         sub_parameter_r_out  OUT VARCHAR2,
         units_r_out          OUT VARCHAR2
      );
      
   FUNCTION delete_rating_ts_records
      (
         rating_code_in          IN INTEGER,
         start_time_in           IN VARCHAR2,
         end_time_in             IN VARCHAR2,
         start_time_inclusive_in IN INTEGER,
         end_time_inclusive_in   IN INTEGER
      )RETURN INTEGER;
   
   FUNCTION get_rating_ts_count
      (
         rating_code_in IN INTEGER
      )RETURN INTEGER;
   
   FUNCTION delete_rating_records
      (
         rating_code_in          IN INTEGER,
         delete_key_in           IN INTEGER,
         delete_data_in          IN INTEGER,
         start_time_in           IN VARCHAR2,
         end_time_in             IN VARCHAR2,
         start_time_inclusive_in IN INTEGER,
         end_time_inclusive_in   IN INTEGER
      )RETURN VARCHAR2;
   
   FUNCTION change_key
      (
         office_in         IN VARCHAR2,
         old_rating_id_in  IN VARCHAR2,
         new_rating_id_in  IN VARCHAR2,
         interpolate_id_in IN VARCHAR2,
         underflow_id_in   IN VARCHAR2,
         overflow_id_in    IN VARCHAR2
      )RETURN VARCHAR2;
   
END cwms_rat;
/
      
--#############################################################################

CREATE OR REPLACE PACKAGE BODY cwms_rat
IS
   
   -------------------------------------------------------------------------------
   PROCEDURE log_output (output_in IN VARCHAR2)
      
   IS
   
   BEGIN
      
      IF log_output_to_table THEN
         INSERT 
            INTO 
               ratings_log (time, message) 
            VALUES 
               (
                  TO_CHAR(CURRENT_TIMESTAMP, 'YYYY-MM-DD HH24:MI:SS.SSSSS'),
                  SUBSTR(output_in, 1, 256)
               );
      END IF;
      
      DBMS_OUTPUT.PUT_LINE(output_in);
      
   END log_output;
   -------------------------------------------------------------------------------
   PROCEDURE set_log_output_on  IS BEGIN log_output_to_table := TRUE;  END;
   -------------------------------------------------------------------------------
   PROCEDURE set_log_output_off IS BEGIN log_output_to_table := FALSE; END;
   -------------------------------------------------------------------------------
   PROCEDURE clear_log_table IS BEGIN DELETE FROM ratings_log WHERE time > ' '; END;
   -------------------------------------------------------------------------------
   FUNCTION parse_rating_id
      (
         rating_id_in      IN  VARCHAR2,
         location_out      OUT VARCHAR2,
         subLocation_out   OUT VARCHAR2,
         measured_1_out    OUT VARCHAR2,
         subMeasured_1_out OUT VARCHAR2,
         measured_2_out    OUT VARCHAR2,
         subMeasured_2_out OUT VARCHAR2,
         rated_out         OUT VARCHAR2,
         subRated_out      OUT VARCHAR2,
         rating_type_out   OUT VARCHAR2,
         version_out       OUT VARCHAR2
      )
      
      RETURN BOOLEAN
      
      ------------------------------------------------------------------------------------------
      -- This function parses a rating id (e.g. "Zenith.Stage:Flow.RatingStream.Test Option") --
      -- into its component parts.                                                            --
      --                                                                                      --
      -- TRUE is returned on success.                                                         --
      -- FALSE is returned on failure.                                                        --
      --                                                                                      --
      -- Mike Perryman                                                                        --
      -- January, 2004                                                                        --
      ------------------------------------------------------------------------------------------
   
   IS
   
      l_startPosition PLS_INTEGER;
      l_dotPosition   PLS_INTEGER;
      l_dashPosition  PLS_INTEGER;
      l_colonPosition PLS_INTEGER;
      l_commaPosition PLS_INTEGER;
      l_parse_error   EXCEPTION;
      l_buffer        VARCHAR2(128);
      
   BEGIN
      
      l_startPosition := 1;
      --
      -- location and sub-location
      --
      BEGIN
         --
         -- grab the location portion
         --
         l_dotPosition := INSTR(rating_id_in, '.', l_startPosition);
         IF l_dotPosition < l_startPosition THEN
            RAISE l_parse_error;
         END IF;
         l_buffer := SUBSTR(rating_id_in, l_startPosition, l_dotPosition - l_startPosition);
         --
         -- split around the '-' character, if it exists
         --
         l_dashPosition := INSTR(l_buffer, '-');
         IF l_dashPosition > 0 THEN
            IF l_dashPosition = 1 THEN 
               RAISE l_parse_error;
            END IF;
            location_out := SUBSTR(l_buffer, 1, l_dashPosition - 1);
            subLocation_out := SUBSTR(l_buffer, l_dashPosition + 1);
         ELSE
            location_out := l_buffer;
            subLocation_out := NULL;
         END IF;
         l_startPosition := l_dotPosition + 1;
      EXCEPTION
         WHEN OTHERS THEN
            LOG_OUTPUT('Cannot parse location from rating id : ' || rating_id_in);
            RETURN FALSE;
      END;
      --
      -- parameters and sub-parameters
      --
      BEGIN
         --
         -- mark the parameters portion
         --
         l_dotPosition := INSTR(rating_id_in, '.', l_startPosition);
         IF l_dotPosition < l_startPosition THEN
            RAISE l_parse_error;
         END IF;
         -- 
         -- mark the measured1, measured2, and rated portions
         --
         l_colonPosition := INSTR(rating_id_in, ':', l_startPosition);
         IF l_colonPosition <= l_startPosition OR l_colonPosition >= l_dotPosition THEN
            RAISE l_parse_error;
         END IF;
         l_commaPosition := INSTR(rating_id_in, ',', l_startPosition);
         IF l_commaPosition > l_startPosition AND l_commaPosition < l_colonPosition THEN
            --
            -- measured1
            --
            l_buffer := SUBSTR(rating_id_in, l_startPosition, l_commaPosition - l_startPosition);
            --
            -- split around the '-' character, if it exists
            --
            l_dashPosition := INSTR(l_buffer, '-');
            IF l_dashPosition > 0 THEN
               IF l_dashPosition = 1 THEN 
                  RAISE l_parse_error;
               END IF;
               measured_1_out := SUBSTR(l_buffer, 1, l_dashPosition - 1);
               subMeasured_1_out := SUBSTR(l_buffer, l_dashPosition + 1);
            ELSE
               measured_1_out := l_buffer;
               subMeasured_1_out := NULL;
            END IF;
            l_startPosition := l_commaPosition + 1;
            --
            -- measured2
            --
            l_buffer := SUBSTR(rating_id_in, l_startPosition, l_colonPosition - l_startPosition);
            --
            -- split around the '-' character, if it exists
            --
            l_dashPosition := INSTR(l_buffer, '-');
            IF l_dashPosition > 0 THEN
               IF l_dashPosition = 1 THEN 
                  RAISE l_parse_error;
               END IF;
               measured_2_out := SUBSTR(l_buffer, 1, l_dashPosition - 1);
               subMeasured_2_out := SUBSTR(l_buffer, l_dashPosition + 1);
            ELSE
               measured_2_out := l_buffer;
               subMeasured_2_out := NULL;
            END IF;
         ELSE
            --
            -- measured1 only
            --
            l_buffer := SUBSTR(rating_id_in, l_startPosition, l_colonPosition - l_startPosition);
            --
            -- split around the '-' character, if it exists
            --
            l_dashPosition := INSTR(l_buffer, '-');
            IF l_dashPosition > 0 THEN
               IF l_dashPosition = 1 THEN 
                  RAISE l_parse_error;
               END IF;
               measured_1_out := SUBSTR(l_buffer, 1, l_dashPosition - 1);
               subMeasured_1_out := SUBSTR(l_buffer, l_dashPosition + 1);
            ELSE
               measured_1_out := l_buffer;
               subMeasured_1_out := NULL;
            END IF;
            measured_2_out     := NULL;
            subMeasured_2_out  := NULL;
         END IF;
         l_startPosition := l_colonPosition + 1;
         --
         -- rated
         --
         l_buffer := SUBSTR(rating_id_in, l_startPosition, l_dotPosition - l_startPosition);
         l_dashPosition := INSTR(l_buffer, '-');
         IF l_dashPosition > 0 THEN
            IF l_dashPosition = 1 THEN 
               RAISE l_parse_error;
            END IF;
            rated_out := SUBSTR(l_buffer, 1, l_dashPosition - 1);
            subRated_out := SUBSTR(l_buffer, l_dashPosition + 1);
         ELSE
            rated_out := l_buffer;
            subRated_out := NULL;
         END IF;
         l_startPosition := l_dotPosition + 1;
      EXCEPTION
         WHEN OTHERS THEN
            LOG_OUTPUT('Cannot parse parameters from rating id : ' || rating_id_in);
            RETURN FALSE;
      END;
      --
      -- rating type
      --
      BEGIN
         l_dotPosition := INSTR(rating_id_in, '.', l_startPosition);
         IF l_dotPosition < l_startPosition THEN
            RAISE l_parse_error;
         END IF;
         rating_type_out := SUBSTR(rating_id_in, l_startPosition, l_dotPosition - l_startPosition);
         rating_type_out := UPPER(SUBSTR(rating_type_out, 7)); -- (e.g 'RatingStream' => 'STREAM')
         l_startPosition := l_dotPosition + 1;
      EXCEPTION
         WHEN OTHERS THEN
            LOG_OUTPUT('Cannot parse rating type from rating id : ' || rating_id_in);
            RETURN FALSE;
      END;
      --
      -- version
      --
      BEGIN
         IF l_startPosition >= LENGTH(rating_id_in) THEN
            version_out := NULL;
         ELSE
            version_out := SUBSTR(rating_id_in, l_startPosition);
         END IF;
      EXCEPTION
         WHEN OTHERS THEN
            LOG_OUTPUT('Cannot parse version from rating id : ' || rating_id_in);
            RETURN FALSE;
      END;
      
      /*
      LOG_OUTPUT('rating_id_in :      ' || rating_id_in);
      LOG_OUTPUT('location_out :      ' || location_out);
      LOG_OUTPUT('subLocation_out :   ' || subLocation_out);
      LOG_OUTPUT('measured_1_out :    ' || measured_1_out);
      LOG_OUTPUT('subMeasured_1_out : ' || subMeasured_1_out);
      LOG_OUTPUT('measured_2_out :    ' || measured_2_out);
      LOG_OUTPUT('subMeasured_2_out : ' || subMeasured_2_out);
      LOG_OUTPUT('rated_out :         ' || rated_out);
      LOG_OUTPUT('subRated_out :      ' || subRated_out);
      LOG_OUTPUT('rating_type_out :   ' || rating_type_out);
      LOG_OUTPUT('version_out :       ' || version_out);
      */
         
      RETURN TRUE;
      
   END parse_rating_id;
   -------------------------------------------------------------------------------
   FUNCTION get_rating_code
      (
         office_in         IN  VARCHAR2, -- office id (e.g. "SWT")
         rating_id_in      IN  VARCHAR2, -- rating id (e.g. "Zenith.Stage:Flow.RatingStream.Test Option")
         case_sensitive_in IN  INTEGER,  -- use case sensitive matching ?
         create_in         IN  INTEGER,  -- create rating code if it doesn't exist ?
         created_out       OUT INTEGER   -- non-zero if code was created
      )
   
      RETURN AT_RATING_SPEC.RATING_CODE%TYPE
   
      
      --------------------------------------------------------------------------------------------
      -- This function returns the value in the RATING_CODE field of the AT_RATING_SPEC         --
      -- table that corresponds to a specified CWMS rating identifier for the specified office. --
      --                                                                                        --
      -- The caller specifies whether to perform a case-sensitive or case-insensitive match     --
      -- and whether to create a new rating code for the specified information if one doesn't   --
      -- already exist.                                                                         --
      --                                                                                        --
      -- A negative number is returned if the code doesn't exist and/or can't be created.       --
      --                                                                                        --
      -- The office identifier is passed in as a string.                                        --
      -- The rating identifier is passed in as a string.                                        --
      -- The case-sensitive flag is passed in as a boolean.                                     --
      -- The create flag is passed in as a boolean.                                             --
      -- The rating code is passed back as the same type as the field.                          --
      --                                                                                        --
      -- Mike Perryman                                                                          --
      -- USACE HEC                                                                              --
      -- January 2004                                                                           --
      --------------------------------------------------------------------------------------------
      
   
   IS
   
      --
      -- defined constants for error return
      --
      L_NOT_FOUND   CONSTANT AT_RATING_SPEC.RATING_CODE%TYPE :=  -1;
      L_INVALID_ID  CONSTANT AT_RATING_SPEC.RATING_CODE%TYPE :=  -2;
      L_CANT_CREATE CONSTANT AT_RATING_SPEC.RATING_CODE%TYPE :=  -3;
      L_NULLSTR     CONSTANT VARCHAR2(1)                     := '~'; -- "NULL" string
      --
      -- variables anchored to types of table fields
      --
      l_location          AT_CWMS_NAME.CWMS_ID%TYPE                 := NULL;
      l_subLocation       AT_RATING_SPEC.SUBCWMS_ID%TYPE            := NULL;
      
      l_parameter_m1      RT_PARAMETER.PARAMETER_ID%TYPE            := NULL;
      l_subParameter_m1   AT_RATING_SPEC.MEAS1_SUBPARAMETER_ID%TYPE := NULL;
      l_parameter_code_m1 RT_PARAMETER.PARAMETER_CODE%TYPE          := NULL;
      
      l_parameter_m2      RT_PARAMETER.PARAMETER_ID%TYPE            := NULL;
      l_subParameter_m2   AT_RATING_SPEC.MEAS2_SUBPARAMETER_ID%TYPE := NULL;
      l_parameter_code_m2 RT_PARAMETER.PARAMETER_CODE%TYPE          := NULL;
      
      l_parameter_r       RT_PARAMETER.PARAMETER_ID%TYPE            := NULL;
      l_subParameter_r    AT_RATING_SPEC.RATED_SUBPARAMETER_ID%TYPE := NULL;
      l_parameter_code_r  RT_PARAMETER.PARAMETER_CODE%TYPE          := NULL;
      
      l_rating_type       RT_RATING_TYPE.RATING_ID%TYPE             := NULL;
      l_version           AT_RATING_SPEC.VERSION%TYPE               := NULL;
      l_rating_type_code  RT_RATING_TYPE.RATING_TYPE_CODE%TYPE      := NULL;
      l_can_be_compound   RT_RATING_TYPE.CAN_BE_COMPOUND%TYPE       := NULL;
      l_rating_code       AT_RATING_SPEC.RATING_CODE%TYPE           := L_NOT_FOUND;
      --
      -- others
      --
      l_office_id     VARCHAR(16);
      l_rating_id     VARCHAR2(512);
      l_created       INTEGER;
   
   BEGIN
   
      created_out := 0;
      
      --
      -- break the rating_id into component parts
      --
      IF case_sensitive_in <> 0 THEN
         l_office_id := office_in;
         l_rating_id := rating_id_in;
      ELSE
         l_office_id := UPPER(office_in);
         l_rating_id := UPPER(rating_id_in);
      END IF;
      
      IF NOT parse_rating_id
         (l_rating_id,
          l_location,
          l_subLocation,
          l_parameter_m1,
          l_subParameter_m1,
          l_parameter_m2,
          l_subParameter_m2,
          l_parameter_r,
          l_subParameter_r,
          l_rating_type,
          l_version) THEN
         RETURN L_INVALID_ID;
      END IF;
      --
      -- get the rating type code and determine whether it can be compound
      --
      BEGIN
         SELECT
            rating_type_code,
            can_be_compound
            INTO
               l_rating_type_code,
               l_can_be_compound
            FROM
               rt_rating_type
            WHERE
               rating_id = l_rating_type;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            LOG_OUTPUT(rating_id_in 
                     || ' contains an unknown rating type.');
            RETURN L_INVALID_ID;
         WHEN OTHERS THEN
            LOG_OUTPUT('Error retrieving rating type for rating id : ' 
                     || rating_id_in 
                     || ' : ' 
                     || SQLCODE 
                     || ' : ' || SQLERRM);
            RETURN L_INVALID_ID;
      END;
      IF l_can_be_compound = 0 AND l_parameter_m2 IS NOT NULL THEN
         LOG_OUTPUT('Rating type for rating id : ' 
                  || rating_id_in 
                  || ' cannot be compound, but measured_2 parameter is specified.');
         RETURN L_INVALID_ID;
      END IF;
                                                            
      --
      -- get the measured_1 parameter code
      --
      BEGIN
         IF case_sensitive_in <> 0 THEN
            SELECT 
               parameter_code 
               INTO 
                  l_parameter_code_m1 
               FROM 
                  rt_parameter
               WHERE 
                  parameter_id = l_parameter_m1;
         ELSE
            SELECT 
               parameter_code 
               INTO 
                  l_parameter_code_m1 
               FROM 
                  rt_parameter
               WHERE 
                  parameter_id_uc = l_parameter_m1;
         END IF;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            LOG_OUTPUT(rating_id_in 
                     || ' contains an unknown measured_1 parameter : '
                     || l_parameter_m1);
            RETURN L_INVALID_ID;
         WHEN OTHERS THEN
            LOG_OUTPUT('Error retrieving measured_1 parameter code for rating id : ' 
                     || rating_id_in 
                     || ' : ' 
                     || SQLCODE 
                     || ' : ' 
                     || SQLERRM);
            RETURN L_INVALID_ID;
      END;
      
      --
      -- get the measured_2 parameter code
      --
      IF l_parameter_m2 IS NOT NULL THEN
         BEGIN
            IF case_sensitive_in <> 0 THEN
               SELECT 
                  parameter_code 
                  INTO 
                     l_parameter_code_m2 
                  FROM 
                     rt_parameter 
                  WHERE 
                     parameter_id = l_parameter_m2;
            ELSE
               SELECT 
                  parameter_code 
                  INTO 
                     l_parameter_code_m2 
                  FROM 
                     rt_parameter 
                  WHERE 
                     parameter_id_uc = l_parameter_m2;
            END IF;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               LOG_OUTPUT(rating_id_in 
                        || ' contains an unknown measured_2 parameter : '
                        || l_parameter_m2);
               RETURN L_INVALID_ID;
            WHEN OTHERS THEN
               LOG_OUTPUT('Error retrieving measured_2 parameter code for rating id : ' 
                        || rating_id_in 
                        || ' : ' 
                        || SQLCODE 
                        || ' : ' 
                        || SQLERRM);
               RETURN L_INVALID_ID;
         END;
      END IF;
      
      --
      -- get the rated parameter code
      --
      BEGIN
         IF case_sensitive_in <> 0 THEN
            SELECT 
               parameter_code 
               INTO 
                  l_parameter_code_r 
               FROM 
                  rt_parameter 
               WHERE 
                  parameter_id = l_parameter_r;
         ELSE
            SELECT 
               parameter_code 
               INTO 
                  l_parameter_code_r 
               FROM 
                  rt_parameter 
               WHERE 
                  parameter_id_uc = l_parameter_r;
         END IF;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            LOG_OUTPUT(rating_id_in 
                     || ' contains an unknown rated parameter : '
                     || l_parameter_r);
            RETURN L_INVALID_ID;
         WHEN OTHERS THEN
            LOG_OUTPUT('Error retrieving rated parameter code for rating id : ' 
                     || rating_id_in 
                     || ' : ' 
                     || SQLCODE 
                     || ' : ' 
                     || SQLERRM);
            RETURN L_INVALID_ID;
      END;
         
      
      --
      -- find the rating_code for the rating_id
      --
      --LOG_OUTPUT('GET_RATING_SPEC : l_office_id         = ' || NVL(l_office_id, L_NULLSTR));
      --LOG_OUTPUT('GET_RATING_SPEC : l_location          = ' || NVL(l_location, L_NULLSTR));
      --LOG_OUTPUT('GET_RATING_SPEC : l_subLocation       = ' || NVL(l_subLocation, L_NULLSTR));
      --LOG_OUTPUT('GET_RATING_SPEC : l_parameter_code_m1 = ' || l_parameter_code_m1);
      --LOG_OUTPUT('GET_RATING_SPEC : l_subParameter_m1   = ' || NVL(l_subParameter_m1, L_NULLSTR));
      --IF l_parameter_code_m2 IS NULL THEN
      --   LOG_OUTPUT('GET_RATING_SPEC : l_parameter_code_m2 = NULL');
      --ELSE
      --   LOG_OUTPUT('GET_RATING_SPEC : l_parameter_code_m2 = ' || l_parameter_code_m2);
      --END IF;
      --LOG_OUTPUT('GET_RATING_SPEC : l_subParameter_m2   = ' || NVL(l_subParameter_m2, L_NULLSTR));
      --LOG_OUTPUT('GET_RATING_SPEC : l_parameter_code_r  = ' || l_parameter_code_r);
      --LOG_OUTPUT('GET_RATING_SPEC : l_subParameter_r    = ' || NVL(l_subParameter_r, L_NULLSTR));
      --LOG_OUTPUT('GET_RATING_SPEC : l_rating_type_code  = ' || l_rating_type_code);
      --LOG_OUTPUT('GET_RATING_SPEC : l_version           = ' || NVL(l_version, L_NULLSTR));
      BEGIN
         IF case_sensitive_in <> 0 THEN
            --
            -- case sensitive match
            --
            IF l_parameter_m2 IS NULL THEN
               --
               -- no measured_2 parameter specified
               --
               SELECT
                  RS.rating_code
                  INTO
                     l_rating_code
                  FROM
                     at_office         O,
                     at_rating_spec    RS,
                     at_point_location PL,
                     at_cwms_name      CN
                  WHERE
                     --
                     -- office
                     --
                     O.office_id = l_office_id
                     AND CN.office_code = O.office_code
                     --
                     -- location and sub-location
                     --
                     AND CN.cwms_id = l_location
                     AND PL.cwms_code = CN.cwms_code
                     AND RS.location_code = PL.location_code
                     AND NVL(RS.subcwms_id, L_NULLSTR) = NVL(l_subLocation, L_NULLSTR)
                     --
                     -- measured_1 parameter and sub-parameter
                     --
                     AND RS.meas1_param_code = l_parameter_code_m1
                     AND NVL(RS.meas1_subparameter_id, L_NULLSTR) = NVL(l_subParameter_m1, L_NULLSTR)
                     --
                     -- measured_2 parameter and sub-parameter
                     --
                     AND RS.meas2_param_code IS NULL
                     --
                     -- rated parameter and sub-parameter
                     --
                     AND RS.rated_param_code = l_parameter_code_r
                     AND NVL(RS.rated_subparameter_id, L_NULLSTR) = NVL(l_subParameter_r, L_NULLSTR)
                     --
                     -- rating type
                     --
                     AND RS.rating_type_code = l_rating_type_code
                     --
                     -- version
                     --
                     AND NVL(RS.version, L_NULLSTR) = NVL(l_version, L_NULLSTR);
            ELSE
               --
               -- measured_2 parameter specified
               --
               SELECT
                  RS.rating_code
                  INTO
                     l_rating_code
                  FROM
                     at_office         O,
                     at_rating_spec    RS,
                     at_point_location PL,
                     at_cwms_name      CN
                  WHERE
                     --
                     -- office
                     --
                     O.office_id = l_office_id
                     AND CN.office_code = O.office_code
                     --
                     -- location and sub-location
                     --
                     AND CN.cwms_id = l_location
                     AND PL.cwms_code = CN.cwms_code
                     AND RS.location_code = PL.location_code
                     AND NVL(RS.subcwms_id, L_NULLSTR) = NVL(l_subLocation, L_NULLSTR)
                     --
                     -- measured_1 parameter and sub-parameter
                     --
                     AND RS.meas1_param_code = l_parameter_code_m1
                     AND NVL(RS.meas1_subparameter_id, L_NULLSTR) = NVL(l_subParameter_m1, L_NULLSTR)
                     --
                     -- measured_2 parameter and sub-parameter
                     --
                     AND RS.meas2_param_code = l_parameter_code_m2
                     AND NVL(RS.meas2_subparameter_id, L_NULLSTR) = NVL(l_subParameter_m2, L_NULLSTR)
                     --
                     -- rated parameter and sub-parameter
                     --
                     AND RS.rated_param_code = l_parameter_code_r
                     AND NVL(RS.rated_subparameter_id, L_NULLSTR) = NVL(l_subParameter_r, L_NULLSTR)
                     --
                     -- rating type
                     --
                     AND RS.rating_type_code = l_rating_type_code
                     --
                     -- version
                     --
                     AND NVL(RS.version, L_NULLSTR) = NVL(l_version, L_NULLSTR);
            END IF;
         ELSE
            --
            -- case insensitive match
            --
            IF l_parameter_m2 IS NULL THEN
               --
               -- no measured_2 parameter specified
               --
               SELECT
                  RS.rating_code
                  INTO
                     l_rating_code
                  FROM
                     at_office         O,
                     at_rating_spec    RS,
                     at_point_location PL,
                     at_cwms_name      CN
                  WHERE
                     --
                     -- office
                     --
                     UPPER(O.office_id) = l_office_id
                     AND CN.office_code = O.office_code
                     --
                     -- location and sub-location
                     --
                     AND CN.cwms_id_uc = l_location
                     AND PL.cwms_code = CN.cwms_code
                     AND RS.location_code = PL.location_code
                     AND NVL(RS.subcwms_id_uc, L_NULLSTR) = NVL(l_subLocation, L_NULLSTR)
                     --
                     -- measured_1 parameter and sub-parameter
                     --
                     AND RS.meas1_param_code = l_parameter_code_m1
                     AND NVL(RS.meas1_subparameter_id_uc, L_NULLSTR) = NVL(l_subParameter_m1, L_NULLSTR)
                     --
                     -- measured_2 parameter and sub-parameter
                     --
                     AND RS.meas2_param_code IS NULL
                     --
                     -- rated parameter and sub-parameter
                     --
                     AND RS.rated_param_code = l_parameter_code_r
                     AND NVL(RS.rated_subparameter_id_uc, L_NULLSTR) = NVL(l_subParameter_r, L_NULLSTR)
                     --
                     -- rating type
                     --
                     AND RS.rating_type_code = l_rating_type_code
                     --
                     -- version
                     --
                     AND NVL(RS.version_uc, L_NULLSTR) = NVL(l_version, L_NULLSTR);
            ELSE
               --
               -- measured_2 parameter specified
               --
               SELECT
                  RS.rating_code
                  INTO
                     l_rating_code
                  FROM
                     at_office         O,
                     at_rating_spec    RS,
                     at_point_location PL,
                     at_cwms_name      CN
                  WHERE
                     --
                     -- office
                     --
                     UPPER(O.office_id) = l_office_id
                     AND CN.office_code = O.office_code
                     --
                     -- location and sub-location
                     --
                     AND CN.cwms_id_uc = l_location
                     AND PL.cwms_code = CN.cwms_code
                     AND RS.location_code = PL.location_code
                     AND NVL(RS.subcwms_id_uc, L_NULLSTR) = NVL(l_subLocation, L_NULLSTR)
                     --
                     -- measured_1 parameter and sub-parameter
                     --
                     AND RS.meas1_param_code = l_parameter_code_m1
                     AND NVL(RS.meas1_subparameter_id_uc, L_NULLSTR) = NVL(l_subParameter_m1, L_NULLSTR)
                     --
                     -- measured_2 parameter and sub-parameter
                     --
                     AND RS.meas2_param_code = l_parameter_code_m2
                     AND NVL(RS.meas2_subparameter_id_uc, L_NULLSTR) = NVL(l_subParameter_m2, L_NULLSTR)
                     --
                     -- rated parameter and sub-parameter
                     --
                     AND RS.rated_param_code = l_parameter_code_r
                     AND NVL(RS.rated_subparameter_id_uc, L_NULLSTR) = NVL(l_subParameter_r, L_NULLSTR)
                     --
                     -- rating type
                     --
                     AND RS.rating_type_code = l_rating_type_code
                     --
                     -- version
                     --
                     AND NVL(RS.version_uc, L_NULLSTR) = NVL(l_version, L_NULLSTR);
            END IF;
         END IF;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            l_rating_code := L_NOT_FOUND;
         WHEN OTHERS THEN
            LOG_OUTPUT('Error retrieving rating code for rating id : ' 
                     || rating_id_in 
                     || ' : ' 
                     || SQLCODE 
                     || ' : ' 
                     || SQLERRM);
            RETURN L_INVALID_ID;
      END;
      
      IF l_rating_code = L_NOT_FOUND AND create_in <> 0 THEN
         IF create_rating_spec(office_in, rating_id_in, NULL, NULL, NULL) THEN
            created_out := 1;
            RETURN get_rating_code(office_in, rating_id_in, 1, 0, l_created);
         ELSE
            RETURN L_CANT_CREATE;
         END IF;
      END IF;
   
      RETURN l_rating_code;
   
   EXCEPTION
      WHEN OTHERS THEN
         LOG_OUTPUT('Error retrieving rating code for rating id : ' 
                  || rating_id_in 
                  || ' : ' 
                  || SQLCODE 
                  || ' : ' 
                  || SQLERRM);
         RETURN L_INVALID_ID;
   END get_rating_code;
   -------------------------------------------------------------------------------
   FUNCTION create_rating_spec
      (
         office_id_in      IN VARCHAR2, -- office id (e.g. "SWT")
         rating_id_in      IN VARCHAR2, -- rating id (e.g. "Zenith.Stage:Flow.RatingStream.Test Option")
         interpolate_id_in IN VARCHAR2, -- LIN_INTERP, STEP_PREV, etc
         underflow_id_in   IN VARCHAR2, -- NOT_ALLOWED, USE_NEAREST, etc
         overflow_id_in    IN VARCHAR2  -- NOT_ALLOWED, USE_NEAREST, etc
      )
      
      RETURN BOOLEAN
   
      --------------------------------------------------------------------
      -- This function creates a new entry in the AT_RATING_SPEC table. --
      --                                                                --
      -- In the process, it may need to create new entries in the       --
      -- AT_OFFICE, AT_CWMS_NAME, and AT_POINT_LOCATION tables.         --
      --                                                                --
      -- TRUE is returned on success.                                   --
      -- FALSE is returned on failure.                                  --
      --                                                                --
      -- Mike Perryman                                                  --
      -- January 2004                                                   --
      --------------------------------------------------------------------
   
   IS
   
      --
      -- variables anchored to types of table fields
      --
      l_office_code       AT_OFFICE.OFFICE_CODE%TYPE                := NULL;
      l_cwms_code         AT_CWMS_NAME.CWMS_CODE%TYPE               := NULL;
      l_location_code     AT_POINT_LOCATION.LOCATION_CODE%TYPE      := NULL;
      
      l_location          AT_CWMS_NAME.CWMS_ID%TYPE                 := NULL;
      l_subLocation       AT_RATING_SPEC.SUBCWMS_ID%TYPE            := NULL;
      
      l_parameter_m1      RT_PARAMETER.PARAMETER_ID%TYPE            := NULL;
      l_subParameter_m1   AT_RATING_SPEC.MEAS1_SUBPARAMETER_ID%TYPE := NULL;
      l_parameter_code_m1 RT_PARAMETER.PARAMETER_CODE%TYPE          := NULL;
      
      l_parameter_m2      RT_PARAMETER.PARAMETER_ID%TYPE            := NULL;
      l_subParameter_m2   AT_RATING_SPEC.MEAS2_SUBPARAMETER_ID%TYPE := NULL;
      l_parameter_code_m2 RT_PARAMETER.PARAMETER_CODE%TYPE          := NULL;
      
      l_parameter_r       RT_PARAMETER.PARAMETER_ID%TYPE            := NULL;
      l_subParameter_r    AT_RATING_SPEC.RATED_SUBPARAMETER_ID%TYPE := NULL;
      l_parameter_code_r  RT_PARAMETER.PARAMETER_CODE%TYPE          := NULL;
      
      l_rating_type       RT_RATING_TYPE.RATING_ID%TYPE             := NULL;
      l_version           AT_RATING_SPEC.VERSION%TYPE               := NULL;
      l_rating_type_code  RT_RATING_TYPE.RATING_TYPE_CODE%TYPE      := NULL;
      
      --
      -- others
      --
      l_str           VARCHAR2(64);
      l_missing_value NUMBER        := -3.40282346638528860E+38;
   
   BEGIN
      
      --
      -- break the rating_id into component parts
      --
      IF NOT parse_rating_id
         (rating_id_in,
          l_location,
          l_subLocation,
          l_parameter_m1,
          l_subParameter_m1,
          l_parameter_m2,
          l_subParameter_m2,
          l_parameter_r,
          l_subParameter_r,
          l_rating_type,
          l_version) 
      THEN
         RETURN FALSE;
      END IF;
      
      --
      -- make sure we have valid parameter codes and rating code
      --
      BEGIN
         l_str := 'measured_1';
         SELECT 
            parameter_code 
            INTO 
               l_parameter_code_m1 
            FROM 
               rt_parameter 
            WHERE 
               parameter_id_uc = UPPER(l_parameter_m1);
         IF l_parameter_m2 IS NOT NULL THEN
            l_str := 'measured_2';
            SELECT 
               parameter_code 
               INTO 
                  l_parameter_code_m2 
               FROM 
                  rt_parameter 
               WHERE 
                  parameter_id_uc = UPPER(l_parameter_m2);
         END IF;
         l_str := 'rated';
         SELECT 
            parameter_code 
            INTO 
               l_parameter_code_r 
            FROM 
               rt_parameter 
            WHERE 
               parameter_id_uc = UPPER(l_parameter_r);
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            LOG_OUTPUT(rating_id_in 
                     || ' contains an unknown ' 
                     || l_str 
                     || ' parameter.');
            RETURN FALSE;
         WHEN OTHERS THEN
            LOG_OUTPUT('Error retrieving ' 
                     || l_str 
                     || ' parameter code for rating id : ' 
                     || rating_id_in 
                     || ' : ' 
                     || SQLCODE 
                     || ' : ' 
                     || SQLERRM);
            RETURN FALSE;
      END;
      BEGIN
         SELECT 
            rating_type_code
            INTO 
               l_rating_type_code
            FROM 
               rt_rating_type 
            WHERE 
               rating_id = l_rating_type;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            LOG_OUTPUT(rating_id_in 
                     || ' contains an unknown rating type.');
            RETURN FALSE;
         WHEN OTHERS THEN
            LOG_OUTPUT('Error retrieving rating type for rating id : ' 
                     || rating_id_in 
                     || ' : ' 
                     || SQLCODE 
                     || ' : ' 
                     || SQLERRM);
            RETURN FALSE;
      END;
      
      --
      -- get the office code
      --
      FOR pass IN 1 .. 2 LOOP
         BEGIN
            SELECT 
               office_code 
               INTO 
                  l_office_code 
               FROM 
                  at_office 
               WHERE 
                  office_id = office_id_in;
            EXIT;
         EXCEPTION
            WHEN OTHERS THEN
               IF pass = 2 THEN
                  LOG_OUTPUT('Error retrieving office code for office id : ' 
                           || office_id_in 
                           || ' : ' 
                           || SQLCODE 
                           || ' : ' 
                           || SQLERRM);
                  ROLLBACK;
                  RETURN FALSE;
               ELSE
                  BEGIN
                     INSERT INTO at_office (office_id) VALUES (office_id_in);
                  EXCEPTION
                     WHEN OTHERS THEN
                        LOG_OUTPUT('Error inserting into AT_OFFICE for office_id : ' 
                                 || office_id_in 
                                 || ' : ' 
                                 || SQLCODE 
                                 || ' : ' 
                                 || SQLERRM);
                        ROLLBACK;
                        RETURN FALSE;
                  END;
               END IF;
         END;
      END LOOP;
      
      --
      -- get the cwms code
      --
      FOR pass IN 1 .. 2 LOOP
         BEGIN
            SELECT 
               cwms_code 
               INTO 
                  l_cwms_code 
               FROM 
                  at_cwms_name 
               WHERE 
                  office_code = l_office_code AND cwms_id = l_location;
         EXCEPTION
            WHEN OTHERS THEN
               IF pass = 2 THEN
                  LOG_OUTPUT('Error retrieving cwms_code for office/location : ' 
                           || office_id_in 
                           || '/' 
                           || l_location 
                           || ' : ' 
                           || SQLCODE 
                           || ' : ' 
                           || SQLERRM);
                  ROLLBACK;
                  RETURN FALSE;
               ELSE
                  BEGIN
                     INSERT INTO at_cwms_name (office_code, cwms_id) VALUES (l_office_code, l_location);
                  EXCEPTION
                     WHEN OTHERS THEN
                        LOG_OUTPUT('Error inserting into AT_CWMS_NAME for office/location : ' 
                                 || office_id_in 
                                 || '/' 
                                 || l_location 
                                 || ' : ' 
                                 || SQLCODE 
                                 || ' : ' 
                                 || SQLERRM);
                        ROLLBACK;
                        RETURN FALSE;
                  END;
               END IF;
         END;
      END LOOP;
      
      --
      -- get the location code
      --
      FOR pass IN 1 .. 2 LOOP
         BEGIN
            SELECT 
               location_code 
               INTO 
                  l_location_code 
               FROM 
                  at_point_location 
               WHERE 
                  cwms_code = l_cwms_code;
         EXCEPTION
            WHEN OTHERS THEN
               IF pass = 2 THEN
                  LOG_OUTPUT('Error retrieving location_code for office/location : ' 
                           || office_id_in 
                           || '/' 
                           || l_location 
                           || ' : ' 
                           || SQLCODE 
                           || ' : ' 
                           || SQLERRM);
                  ROLLBACK;
                  RETURN FALSE;
               ELSE
                  BEGIN
                     l_str := 'getting next location sequence value';                           
                     SELECT seq_loca.NEXTVAL INTO l_location_code FROM dual;
                     l_str := 'inserting into AT_PHYSICAL_LOCATION';                           
                     INSERT 
                        INTO 
                           at_physical_location
                           (
                              location_code,
                              zone_code,
                              county_code,
                              state_code,
                              location_type,
                              elevation,
                              longitude,
                              latitude,
                              description,
                              vertical_datum
                           )
                        VALUES
                        (
                            l_location_code,
                            0,
                            0,
                            0,
                            'Unknown',
                            l_missing_value,
                            l_missing_value,
                            l_missing_value,
                            NULL,
                            NULL
                        );
                     l_str := 'inserting into AT_POINT_LOCATION';                           
                     INSERT 
                        INTO 
                           at_point_location 
                           (
                              location_code,
                              cwms_code
                           )
                        VALUES
                           (
                              l_location_code,
                              l_cwms_code
                           );
                  EXCEPTION
                     WHEN OTHERS THEN
                        LOG_OUTPUT('Error '
                                 || l_str
                                 || ' for office/location : ' 
                                 || office_id_in 
                                 || '/' 
                                 || l_location 
                                 || ' : ' 
                                 || SQLCODE 
                                 || ' : ' 
                                 || SQLERRM);
                        ROLLBACK;
                        RETURN FALSE;
                  END;
               END IF;
         END;
      END LOOP;
      
      --
      -- finally, create the rating spec
      --
      BEGIN
         INSERT 
            INTO 
               at_rating_spec
               (
                  location_code,
                  subcwms_id,
                  rating_type_code,
                  meas1_param_code, 
                  meas2_param_code,
                  rated_param_code,
                  meas1_subparameter_id,
                  meas2_subparameter_id,
                  rated_subparameter_id,
                  version,
                  interpolation_type_code,
                  underflow_type_code,
                  overflow_type_code
               )
            VALUES
               (
                  l_location_code,
                  l_subLocation,
                  l_rating_type_code,
                  l_parameter_code_m1,
                  l_parameter_code_m2,
                  l_parameter_code_r,
                  l_subParameter_m1,
                  l_subParameter_m2,
                  l_subParameter_r,
                  l_version,
                  interpolate_id_in,
                  underflow_id_in,
                  overflow_id_in
               );
      EXCEPTION
         WHEN OTHERS THEN
            LOG_OUTPUT('Error inserting into AT_RATING_SPEC for rating id : ' 
                     || rating_id_in 
                     || ' : ' 
                     || SQLCODE 
                     || ' : ' 
                     || SQLERRM);
            ROLLBACK;
            RETURN FALSE;
      END;
      
      COMMIT;
      RETURN TRUE;
               
   END create_rating_spec;
   -------------------------------------------------------------------------------
   FUNCTION get_rating_ts_clob
      (
         rating_code_in     IN  AT_RATING_SPEC.RATING_CODE%TYPE,
         date_effective_in  IN  VARCHAR2,
         date_activated_out OUT VARCHAR2
      )
      
      RETURN CLOB
      
   IS
      
      l_clob           CLOB         := NULL;
      l_date_activated VARCHAR2(19) := NULL;
      
   BEGIN
      
      SELECT 
         rating_data,
         TO_CHAR(date_activated, 'YYYY-MM-DD HH24:MI:SS')
         INTO 
            l_clob,
            l_date_activated
         FROM 
            at_rating_ts_spec 
         WHERE 
            rating_code = rating_code_in 
            AND date_effective = TO_TIMESTAMP(date_effective_in, 'YYYY-MM-DD HH24:MI:SS');
      
      date_activated_out := l_date_activated;
      RETURN l_clob;
      
   EXCEPTION
      
      WHEN OTHERS THEN 
         log_output(SQLERRM);
         RETURN l_clob;
      
   END get_rating_ts_clob;
   -------------------------------------------------------------------------------
   FUNCTION get_rating_ts_clob
      (
         rowid_in IN ROWID
      )
      
      RETURN CLOB
      
   IS
      
      l_clob CLOB := NULL;
      
   BEGIN
      
      SELECT 
         rating_data
         INTO 
            l_clob
         FROM 
            at_rating_ts_spec 
         WHERE 
            ROWID = rowid_in;
      
      RETURN l_clob;
      
   EXCEPTION
      
      WHEN OTHERS THEN 
         log_output(SQLERRM);
         RETURN l_clob;
      
   END get_rating_ts_clob;
   -------------------------------------------------------------------------------
   FUNCTION get_rating_ts_rowid
      (
         rating_code_in    IN  AT_RATING_SPEC.RATING_CODE%TYPE,
         date_effective_in IN  VARCHAR2,
         create_in         IN  INTEGER,  -- create record if it doesn't exist ?
         created_out       OUT INTEGER   -- non-zero if code was created
      )
      
      RETURN ROWID
      
   IS
      
      l_row            ROWID := NULL;
      l_date_effective DATE  := TO_TIMESTAMP(date_effective_in, 'YYYY-MM-DD HH24:MI:SS');
      
   BEGIN
      
      created_out := 0;
      
      FOR pass IN 1 .. 2 LOOP
         BEGIN
            SELECT 
               ROWID 
               INTO 
                  l_row
               FROM 
                  at_rating_ts_spec 
               WHERE 
                  rating_code = rating_code_in 
                  AND date_effective = l_date_effective;
            EXIT;
         EXCEPTION
            WHEN OTHERS THEN
               IF pass = 2 THEN
                  LOG_OUTPUT('Error retrieving rowid : ' 
                                       || SQLCODE 
                                       || ' : ' 
                                       || SQLERRM);
                  ROLLBACK;
                  EXIT;
               ELSIF create_in = 0 THEN
                  EXIT;
               ELSE
                  BEGIN
                     INSERT 
                        INTO 
                           at_rating_ts_spec 
                           (
                              rating_code,
                              date_effective,
                              date_activated
                           )
                        VALUES
                           (
                              rating_code_in,
                              l_date_effective,
                              NULL
                           );
                     COMMIT;
                     created_out := 1;
                  EXCEPTION
                     WHEN OTHERS THEN
                        LOG_OUTPUT('Error inserting into AT_RATING_TS_SPEC : ' 
                                             || SQLCODE 
                                             || ' : ' 
                                             || SQLERRM);
                        EXIT;
                  END;
               END IF;
         END;
      END LOOP;
      
      RETURN l_row;
         
   END get_rating_ts_rowid;
   -------------------------------------------------------------------------------
   FUNCTION get_rating_times_v
      (
         rating_code_in      IN AT_RATING_SPEC.RATING_CODE%TYPE,
         max_return_count_in IN INTEGER := 500
      )
      
      RETURN char_time_array
      
   IS
      
      l_result_set char_time_array;
   
      CURSOR l_cursor IS
         SELECT 
            TO_CHAR(date_effective, 'yyyy-mm-dd hh24:mi:ss')
            FROM
               at_rating_ts_spec
            WHERE
               rating_code = rating_code_in
            ORDER BY
               date_effective;
      
   BEGIN
      
      OPEN l_cursor;
      FETCH l_cursor
         BULK COLLECT INTO
            l_result_set
         LIMIT
            max_return_count_in;
      
      CLOSE l_cursor;
      
      RETURN l_result_set;
      
   END get_rating_times_v;
   -------------------------------------------------------------------------------
   PROCEDURE get_rating_info
      (
         office_id_in         IN  VARCHAR2,
         rating_id_in         IN  VARCHAR2,
         case_sensitive_in    IN  INTEGER,
         rating_code_out      OUT AT_RATING_SPEC.RATING_CODE%TYPE,
         rating_id_out        OUT RT_RATING_TYPE.RATING_ID%TYPE,
         interpolation_id_out OUT RT_RATING_TS_INTERP_TYPE.INTERPOLATION_ID%TYPE,
         underflow_id_out     OUT RT_RATING_TS_EXTRAP_TYPE.EXTRAPOLATION_ID%TYPE,
         overflow_id_out      OUT RT_RATING_TS_EXTRAP_TYPE.EXTRAPOLATION_ID%TYPE,
         effective_times_out  OUT char_time_array
      )
      
   IS
      
      l_underflow_code     AT_RATING_SPEC.UNDERFLOW_TYPE_CODE%TYPE;
      l_overflow_code      AT_RATING_SPEC.OVERFLOW_TYPE_CODE%TYPE;
      l_created            INTEGER;
      
   BEGIN
      
      rating_id_out        := NULL;
      interpolation_id_out := NULL;
      underflow_id_out     := NULL;
      overflow_id_out      := NULL;
      
      rating_code_out := get_rating_code(office_id_in, rating_id_in, case_sensitive_in, 0, l_created);
      
      IF rating_code_out > 0 THEN
         
         SELECT
            RT.rating_id,
            IT.interpolation_id,
            RS.underflow_type_code,
            RS.overflow_type_code
            INTO
               rating_id_out,
               interpolation_id_out,
               l_underflow_code,
               l_overflow_code
            FROM
               rt_rating_type RT,
               rt_rating_ts_interp_type IT,
               at_rating_spec RS
            WHERE
               RS.rating_code = rating_code_out
               AND RT.rating_type_code = RS.rating_type_code
               AND IT.interpolation_type_code = RS.interpolation_type_code;
               
         SELECT 
            extrapolation_id 
            INTO 
               underflow_id_out 
            FROM 
               rt_rating_ts_extrap_type 
            WHERE 
               extrapolation_type_code = l_underflow_code;
         
         SELECT 
            extrapolation_id 
            INTO 
               overflow_id_out 
            FROM 
               rt_rating_ts_extrap_type 
            WHERE 
               extrapolation_type_code = l_overflow_code;
         
         effective_times_out := get_rating_times_v(rating_code_out); 
         
      END IF;
      
   END get_rating_info;
   -------------------------------------------------------------------------------
   PROCEDURE set_behaviors
      (
         rating_code_in          IN AT_RATING_SPEC.RATING_CODE%TYPE,
         interpolate_behavior_in IN RT_RATING_TS_INTERP_TYPE.INTERPOLATION_ID%TYPE,
         underflow_behavior_in   IN RT_RATING_TS_EXTRAP_TYPE.EXTRAPOLATION_ID%TYPE,
         overflow_behavior_in    IN RT_RATING_TS_EXTRAP_TYPE.EXTRAPOLATION_ID%TYPE
      )
      
   IS
      
      l_interpolate_code RT_RATING_TS_INTERP_TYPE.INTERPOLATION_TYPE_CODE%TYPE;
      l_underflow_code   RT_RATING_TS_EXTRAP_TYPE.EXTRAPOLATION_TYPE_CODE%TYPE;
      l_overflow_code    RT_RATING_TS_EXTRAP_TYPE.EXTRAPOLATION_TYPE_CODE%TYPE;
      
      CURSOR rating IS
         SELECT
         interpolation_type_code,
         underflow_type_code,
         overflow_type_code
         FROM
            at_rating_spec
         WHERE
            rating_code = rating_code_in
         FOR UPDATE OF
            interpolation_type_code,
            underflow_type_code,
            overflow_type_code;
      
   BEGIN
      
      IF interpolate_behavior_in IS NOT NULL THEN
         SELECT 
            interpolation_type_code
            INTO 
               l_interpolate_code 
            FROM 
               rt_rating_ts_interp_type
            WHERE
               interpolation_id = interpolate_behavior_in;
      END IF;
      
      IF underflow_behavior_in IS NOT NULL THEN
         SELECT 
            extrapolation_type_code 
            INTO 
               l_underflow_code 
            FROM 
               rt_rating_ts_extrap_type
            WHERE
               extrapolation_id = underflow_behavior_in;
      END IF;
      
      IF overflow_behavior_in IS NOT NULL THEN
         SELECT 
            extrapolation_type_code 
            INTO 
               l_overflow_code 
            FROM 
               rt_rating_ts_extrap_type
            WHERE
               extrapolation_id = overflow_behavior_in;
      END IF;
      
      FOR rating_rec IN rating LOOP -- should only be one!
         IF interpolate_behavior_in IS NOT NULL THEN
            IF rating_rec.interpolation_type_code <> l_interpolate_code THEN
               UPDATE at_rating_spec
                  SET interpolation_type_code = l_interpolate_code
                  WHERE CURRENT OF rating;
            END IF;
         END IF;
         IF underflow_behavior_in IS NOT NULL THEN
            IF rating_rec.underflow_type_code <> l_underflow_code THEN
               UPDATE at_rating_spec
                  SET underflow_type_code = l_underflow_code
                  WHERE CURRENT OF rating;
            END IF;
         END IF;
         IF overflow_behavior_in IS NOT NULL THEN
            IF rating_rec.overflow_type_code <> l_overflow_code THEN
               UPDATE at_rating_spec
                  SET overflow_type_code = l_overflow_code
                  WHERE CURRENT OF rating;
            END IF;
         END IF;
      END LOOP;
      
      COMMIT;

   END set_behaviors;
   -------------------------------------------------------------------------------
   PROCEDURE set_activated_time
      (
         rowid_in          IN ROWID,
         date_activated_in IN VARCHAR2
      )
      
   IS
      
   BEGIN
      
      UPDATE
      at_rating_ts_spec
      SET
         date_activated = TO_TIMESTAMP(date_activated_in, 'YYYY-MM-DD HH24:MI:SS')
      WHERE
         ROWID = rowid_in;

   END set_activated_time;
   -------------------------------------------------------------------------------
   PROCEDURE get_location_and_parameters
      (
         rating_code_in       IN  INTEGER,
         office_id_out        OUT VARCHAR2,
         location_id_out      OUT VARCHAR2,
         sub_location_id_out  OUT VARCHAR2,
         parameter_m1_out     OUT VARCHAR2,
         sub_parameter_m1_out OUT VARCHAR2,
         units_m1_out         OUT VARCHAR2,
         parameter_m2_out     OUT VARCHAR2,
         sub_parameter_m2_out OUT VARCHAR2,
         units_m2_out         OUT VARCHAR2,
         parameter_r_out      OUT VARCHAR2,
         sub_parameter_r_out  OUT VARCHAR2,
         units_r_out          OUT VARCHAR2
      )
      
   IS
      
      l_parameter_m1_code RT_PARAMETER.PARAMETER_CODE%TYPE;
      l_parameter_m2_code RT_PARAMETER.PARAMETER_CODE%TYPE;
      l_parameter_r_code RT_PARAMETER.PARAMETER_CODE%TYPE;
      
   BEGIN
      
      office_id_out        := NULL;
      location_id_out      := NULL;
      sub_location_id_out  := NULL;
      parameter_m1_out     := NULL;
      sub_parameter_m1_out := NULL;
      units_m1_out         := NULL;
      parameter_m2_out     := NULL;
      sub_parameter_m2_out := NULL;
      units_m2_out         := NULL;
      parameter_r_out      := NULL;
      sub_parameter_r_out  := NULL;
      units_r_out          := NULL;
      
      SELECT
         AO.office_id,
         CN.cwms_id,
         RS.subcwms_id,
         RS.meas1_param_code,
         RS.meas1_subparameter_id,
         RS.meas2_param_code,
         RS.meas2_subparameter_id,
         RS.rated_param_code,
         RS.rated_subparameter_id
         INTO
            office_id_out,
            location_id_out,
            sub_location_id_out,
            l_parameter_m1_code,
            sub_parameter_m1_out,
            l_parameter_m2_code,
            sub_parameter_m2_out,
            l_parameter_r_code,
            sub_parameter_r_out
         FROM
            at_office AO,
            at_cwms_name CN,
            at_point_location PL,
            at_rating_spec RS
         WHERE
            RS.rating_code = rating_code_in
            AND PL.location_code = RS.location_code
            AND CN.cwms_code = PL.cwms_code
            AND AO.office_code = CN.office_code;
      
      SELECT
         RP.parameter_id,
         RU.unit_id
         INTO
            parameter_m1_out,
            units_m1_out
         FROM
            rt_parameter RP,
            rt_unit RU
         WHERE
            RP.parameter_code = l_parameter_m1_code
            AND RU.unit_code = RP.unit_code;
      
      IF l_parameter_m2_code IS NOT NULL THEN
         SELECT
            RP.parameter_id,
            RU.unit_id
            INTO
               parameter_m2_out,
               units_m2_out
            FROM
               rt_parameter RP,
               rt_unit RU
            WHERE
               RP.parameter_code = l_parameter_m2_code
               AND RU.unit_code = RP.unit_code;
      END IF;
      
      SELECT
         RP.parameter_id,
         RU.unit_id
         INTO
            parameter_r_out,
            units_r_out
         FROM
            rt_parameter RP,
            rt_unit RU
         WHERE
            RP.parameter_code = l_parameter_r_code
            AND RU.unit_code = RP.unit_code;
      
   EXCEPTION
      
      WHEN NO_DATA_FOUND THEN RETURN;
      
      WHEN OTHERS THEN
         LOG_OUTPUT('Error retrieving location and parameter information for rating code : ' 
                  || rating_code_in 
                  || ' : ' 
                  || SQLCODE 
                  || ' : ' || SQLERRM);
         RETURN;
         
   END get_location_and_parameters;
   -------------------------------------------------------------------------------
   FUNCTION delete_rating_ts_records
      (
         rating_code_in          IN INTEGER,
         start_time_in           IN VARCHAR2,
         end_time_in             IN VARCHAR2,
         start_time_inclusive_in IN INTEGER,
         end_time_inclusive_in   IN INTEGER
      )
      
      RETURN INTEGER
      
   IS
      
   BEGIN
      
      IF start_time_in IS NOT NULL THEN
         IF end_time_in IS NOT NULL THEN
            IF start_time_inclusive_in = 0 THEN
               IF end_time_inclusive_in = 0 THEN
                  --
                  -- exclusive start time, exclusive end time
                  --
                  DELETE 
                     FROM 
                        at_rating_ts_spec 
                     WHERE 
                        rating_code = rating_code_in
                        AND date_effective > TO_TIMESTAMP(start_time_in, 'YYYY-MM-DD HH24:MI:SS')
                        AND date_effective < TO_TIMESTAMP(end_time_in, 'YYYY-MM-DD HH24:MI:SS');
               ELSE
                  --
                  -- exclusive start time, inclusive end time
                  --
                  DELETE 
                     FROM 
                        at_rating_ts_spec 
                     WHERE 
                        rating_code = rating_code_in
                        AND date_effective > TO_TIMESTAMP(start_time_in, 'YYYY-MM-DD HH24:MI:SS')
                        AND date_effective <= TO_TIMESTAMP(end_time_in, 'YYYY-MM-DD HH24:MI:SS');
               END IF;
            ELSIF end_time_inclusive_in = 0 THEN
               --
               -- inclusive start time, exclusive end time
               --
               DELETE 
                  FROM 
                     at_rating_ts_spec 
                  WHERE 
                     rating_code = rating_code_in
                     AND date_effective >= TO_TIMESTAMP(start_time_in, 'YYYY-MM-DD HH24:MI:SS')
                     AND date_effective < TO_TIMESTAMP(end_time_in, 'YYYY-MM-DD HH24:MI:SS');
            ELSE
               --
               -- inclusive start time, inclusive end time
               --
               DELETE 
                  FROM 
                     at_rating_ts_spec 
                  WHERE 
                     rating_code = rating_code_in
                     AND date_effective >= TO_TIMESTAMP(start_time_in, 'YYYY-MM-DD HH24:MI:SS')
                     AND date_effective <= TO_TIMESTAMP(end_time_in, 'YYYY-MM-DD HH24:MI:SS');
            END IF;
         ELSE
            IF start_time_inclusive_in = 0 THEN
               --
               -- exclusive start time, no end time
               --
               DELETE 
                  FROM 
                     at_rating_ts_spec 
                  WHERE 
                     rating_code = rating_code_in
                     AND date_effective > TO_TIMESTAMP(start_time_in, 'YYYY-MM-DD HH24:MI:SS');
            ELSE
               --
               -- inclusive start time, no end time
               --
               DELETE 
                  FROM 
                     at_rating_ts_spec 
                  WHERE 
                     rating_code = rating_code_in
                     AND date_effective >= TO_TIMESTAMP(start_time_in, 'YYYY-MM-DD HH24:MI:SS');
            END IF;
         END IF;
      ELSIF end_time_in IS NOT NULL THEN
         IF end_time_inclusive_in = 0 THEN
            --
            -- no start time, exclusive end time
            --
            DELETE 
               FROM 
                  at_rating_ts_spec 
               WHERE 
                  rating_code = rating_code_in
                  AND date_effective < TO_TIMESTAMP(end_time_in, 'YYYY-MM-DD HH24:MI:SS');
         ELSE
            --
            -- no start time, inclusive end time
            --
            DELETE 
               FROM 
                  at_rating_ts_spec 
               WHERE 
                  rating_code = rating_code_in
                  AND date_effective <= TO_TIMESTAMP(end_time_in, 'YYYY-MM-DD HH24:MI:SS');
         END IF;
      ELSE
         --
         -- no start time, no end time
         --
         DELETE 
            FROM 
               at_rating_ts_spec 
            WHERE 
               rating_code = rating_code_in;
      END IF;
      
      
      RETURN SQL%ROWCOUNT;
      
   END delete_rating_ts_records;
   -------------------------------------------------------------------------------
   FUNCTION get_rating_ts_count
      (
         rating_code_in IN INTEGER
      )
      
      RETURN INTEGER
      
   IS
      
      l_record_count INTEGER   := NULL;
      
   BEGIN
      
      SELECT
         COUNT(*)
         INTO
            l_record_count
         FROM
            at_rating_ts_spec
         WHERE
            rating_code = rating_code_in;
      
      RETURN l_record_count;
      
   EXCEPTION
      
      WHEN NO_DATA_FOUND THEN l_record_count := 0;
      
      WHEN OTHERS THEN
         BEGIN
            LOG_OUTPUT('Error retrieving rating count for rating code : ' 
                     || rating_code_in 
                     || ' : ' 
                     || SQLCODE 
                     || ' : ' || SQLERRM);
            
            l_record_count := -1;
         END;
         
      RETURN l_record_count;
         
   END get_rating_ts_count;
   -------------------------------------------------------------------------------
   FUNCTION delete_rating_records
      (
         rating_code_in          IN INTEGER,
         delete_key_in           IN INTEGER,
         delete_data_in          IN INTEGER,
         start_time_in           IN VARCHAR2,
         end_time_in             IN VARCHAR2,
         start_time_inclusive_in IN INTEGER,
         end_time_inclusive_in   IN INTEGER
      ) 
      
      RETURN VARCHAR2
      
   IS
      
      l_data_count INTEGER      := NULL;
      l_deleted_count INTEGER   := 0;
      l_result_str VARCHAR2(64) := NULL;
      
   BEGIN
      
      IF delete_data_in = 0 AND delete_key_in = 0 THEN
         RETURN 'No action specified.';
      END IF;
      
      --------------------------------------
      -- delete data records if specified --
      --------------------------------------
      l_data_count := get_rating_ts_count(rating_code_in);
      IF l_data_count <> 0 THEN
         IF delete_data_in = 0 THEN
            RETURN 'Cannot delete key, ' || l_data_count || ' data records exist.';
         END IF;
         l_deleted_count := delete_rating_ts_records(rating_code_in,
                                                     start_time_in,
                                                     end_time_in,
                                                     start_time_inclusive_in,
                                                     end_time_inclusive_in);
         l_data_count := get_rating_ts_count(rating_code_in);
         IF l_data_count <> 0 THEN
            RETURN 'Cannot delete key, ' || l_data_count || ' data records still exist.';
         END IF;
      END IF;
      l_result_str := l_deleted_count || ' data record(s) deleted';
      ------------------------------------
      -- delete key record if specified --
      ------------------------------------
      IF delete_key_in <> 0 THEN
         IF delete_data_in <> 0 THEN
            l_result_str := l_result_str || ', ';
         END IF;
         DELETE FROM at_rating_spec WHERE rating_code = rating_code_in;
         l_result_str := l_result_str || SQL%ROWCOUNT || ' key record(s) deleted.';
      ELSE
         l_result_str := l_result_str || '.';
      END IF;
      
      COMMIT;
      RETURN l_result_str;
      
   END delete_rating_records ;
   -------------------------------------------------------------------------------
   FUNCTION change_key
      (
         office_in         IN VARCHAR2,
         old_rating_id_in  IN VARCHAR2,
         new_rating_id_in  IN VARCHAR2,
         interpolate_id_in IN VARCHAR2,
         underflow_id_in   IN VARCHAR2,
         overflow_id_in    IN VARCHAR2
      )
      
      RETURN VARCHAR2
      
   IS
      
      l_old_code       at_rating_spec.rating_code%TYPE                       := NULL;
      l_created        INTEGER                                               := NULL;
      
      l_old_param_m1   at_rating_spec.meas1_param_code%TYPE                  := NULL;
      l_old_param_m2   at_rating_spec.meas2_param_code%TYPE                  := NULL;
      l_old_param_r    at_rating_spec.rated_param_code%TYPE                  := NULL;
      l_old_type_code  rt_rating_type.rating_type_code%TYPE                  := NULL;
         
      l_new_location   at_point_location.location_code%TYPE                  := NULL;
      l_new_param_m1   at_rating_spec.meas1_param_code%TYPE                  := NULL;
      l_new_param_m2   at_rating_spec.meas2_param_code%TYPE                  := NULL;
      l_new_param_r    at_rating_spec.rated_param_code%TYPE                  := NULL;
      l_new_type_code  rt_rating_type.rating_type_code%TYPE                  := NULL;
      l_new_interp     rt_rating_ts_interp_type.interpolation_type_code%TYPE := NULL;
      l_new_underflow  rt_rating_ts_extrap_type.extrapolation_type_code%TYPE := NULL;
      l_new_overflow   rt_rating_ts_extrap_type.extrapolation_type_code%TYPE := NULL;
      
      l_location       at_cwms_name.cwms_id%TYPE                             := NULL;
      l_sub_location   at_rating_spec.subcwms_id%TYPE                        := NULL;
      l_measured_1     rt_parameter.parameter_id%TYPE                        := NULL;
      l_sub_measured_1 at_rating_spec.meas1_subparameter_id%TYPE             := NULL;
      l_measured_2     rt_parameter.parameter_id%TYPE                        := NULL;
      l_sub_measured_2 at_rating_spec.meas2_subparameter_id%TYPE             := NULL;
      l_rated          rt_parameter.parameter_id%TYPE                        := NULL;
      l_sub_rated      at_rating_spec.rated_subparameter_id%TYPE             := NULL;
      l_rating_type    rt_rating_type.rating_id%TYPE                         := NULL;
      l_version        at_rating_spec.version%TYPE                           := NULL;
      
   BEGIN
      
      --
      -- get the rating code for the existing key
      --
      l_old_code := get_rating_code(office_in, old_rating_id_in, 0, 0, l_created);
      IF l_old_code <= 0 THEN
         RETURN 'Rating ID does not exist for office '
            || office_in
            || ' : '
            || old_rating_id_in;
      END IF;
      
      --
      -- parse the new rating id
      --
      IF NOT parse_rating_id(
               new_rating_id_in,
               l_location,
               l_sub_location,
               l_measured_1,
               l_sub_measured_1,
               l_measured_2,
               l_sub_measured_2,
               l_rated,
               l_sub_rated,
               l_rating_type,
               l_version)
      THEN
         RETURN 'Rating ID '
            || new_rating_id_in
            || ' is not valid.';
      END IF;
      
      --
      -- get the location code
      --
      BEGIN
         SELECT
            PL.location_code
            INTO
               l_new_location
            FROM 
               at_point_location PL,
               at_cwms_name CN,
               at_office AO
            WHERE
               AO.office_id = upper(office_in)
               AND CN.office_code = AO.office_code
               AND CN.cwms_id_uc = upper(l_location)
               AND PL.cwms_code = CN.cwms_code;
      EXCEPTION
         WHEN OTHERS THEN
            RETURN 'Rating ID '
               || new_rating_id_in
               || ' has invalid location ('
               || l_location
               || ') for office '
               || office_in
               || '.';
      END;
      
      --
      -- get the measured 1 parameter code
      --
      BEGIN
         SELECT
            parameter_code
            INTO
               l_new_param_m1
            FROM
               rt_parameter
            WHERE
               parameter_id_uc = upper(l_measured_1);
      EXCEPTION
         WHEN OTHERS THEN
            RETURN 'Rating ID '
               || new_rating_id_in
               || ' has invalid measured_1 parameter ('
               || l_measured_1
               || ')';
      END;
      
      --
      -- get the measured 2 parameter code
      --
      IF l_measured_2 IS NOT NULL AND LENGTH(l_measured_2) > 0 THEN
         BEGIN
            SELECT
               parameter_code
               INTO
                  l_new_param_m2
               FROM
                  rt_parameter
               WHERE
                  parameter_id_uc = upper(l_measured_2);
         EXCEPTION
            WHEN OTHERS THEN
               RETURN 'Rating ID '
                  || new_rating_id_in
                  || ' has invalid measured_2 parameter ('
                  || l_measured_2
                  || ')';
         END;
      END IF;
      
      --
      -- get the rated parameter code
      --
      BEGIN
         SELECT
            parameter_code
            INTO
               l_new_param_r
            FROM
               rt_parameter
            WHERE
               parameter_id_uc = upper(l_rated);
      EXCEPTION
         WHEN OTHERS THEN
            RETURN 'Rating ID '
               || new_rating_id_in
               || ' has invalid rated parameter ('
               || l_rated
               || ')';
      END;
      
      --
      -- get the rating type code
      --
      BEGIN
         SELECT
            rating_type_code
            INTO
               l_new_type_code
            FROM 
               rt_rating_type
            WHERE
               rating_id = l_rating_type;
      EXCEPTION
         WHEN OTHERS THEN
            RETURN 'Rating ID '
               || new_rating_id_in
               || ' has invalid rating type ('
               || l_rating_type
               || ')';
      END;
      
      --
      -- get the interpolation type code
      --
      BEGIN
         SELECT
            interpolation_type_code
            INTO
               l_new_interp
            FROM 
               rt_rating_ts_interp_type
            WHERE
               interpolation_id = interpolate_id_in;
      EXCEPTION
         WHEN OTHERS THEN
            RETURN 'Interpolation ID '
               || interpolate_id_in
               || ' is invalid.';
      END;
      
      --
      -- get the underflow type code
      --
      BEGIN
         SELECT
            extrapolation_type_code
            INTO
               l_new_underflow
            FROM 
               rt_rating_ts_extrap_type
            WHERE
               extrapolation_id = underflow_id_in;
      EXCEPTION
         WHEN OTHERS THEN
            RETURN 'Underflow ID '
               || underflow_id_in
               || ' is invalid.';
      END;
      
      --
      -- get the overflow type code
      --
      BEGIN
         SELECT
            extrapolation_type_code
            INTO
               l_new_overflow
            FROM 
               rt_rating_ts_extrap_type
            WHERE
               extrapolation_id = overflow_id_in;
      EXCEPTION
         WHEN OTHERS THEN
            RETURN 'Overflow ID '
               || overflow_id_in
               || ' is invalid.';
      END;
      
      --
      -- restrict changing parameters and rating type if we have actual ratings already
      --
      IF get_rating_ts_count(l_old_code) > 0 THEN
         SELECT
            rating_type_code,
            meas1_param_code,
            meas2_param_code,
            rated_param_code
            INTO
               l_old_type_code,
               l_old_param_m1,
               l_old_param_m2,
               l_old_param_r
            FROM
               at_rating_spec
            WHERE
               rating_code = l_old_code;
         
         IF l_new_type_code <> l_old_type_code THEN
            RETURN 'Cannot change rating types with existing ratings.';
         END IF;
         IF l_new_param_m1 <> l_old_param_m1 THEN
            RETURN 'Cannot change measured_1 parameters with existing ratings.';
         END IF;
         IF l_new_param_m2 IS NOT NULL OR l_old_param_m2 IS NOT NULL THEN
            IF (l_new_param_m2 IS NULL AND l_old_param_m2 IS NOT NULL) 
               OR (l_new_param_m2 IS NOT NULL AND l_old_param_m2 IS NULL)
               OR (l_new_param_m2 <> l_old_param_m2)
            THEN
               RETURN 'Cannot change measured_2 parameters with existing ratings.';
            END IF;
         END IF;
         IF l_new_param_r <> l_old_param_r THEN
            RETURN 'Cannot change rated parameters with existing ratings.';
         END IF;
           
      END IF;
   
      --
      -- everything checks out OK, so update the record
      --
      BEGIN
         UPDATE
            at_rating_spec
            SET
               location_code = l_new_location,
               subcwms_id = l_sub_location,
               rating_type_code = l_new_type_code,
               meas1_param_code = l_new_param_m1,
               meas2_param_code = l_new_param_m2,
               rated_param_code = l_new_param_r,
               meas1_subparameter_id = l_sub_measured_1,
               meas2_subparameter_id = l_sub_measured_2,
               rated_subparameter_id = l_sub_rated,
               version = l_version,
               interpolation_type_code = l_new_interp,
               underflow_type_code = l_new_underflow,
               overflow_type_code = l_new_overflow
            WHERE
               rating_code = l_old_code;
         
         RETURN 'OK';
         
      EXCEPTION
         WHEN OTHERS THEN
            RETURN 'Error updating rating id : ' 
               || old_rating_id_in 
               || ' : ' 
               || SQLCODE 
               || ' : ' || SQLERRM;
      END;
      
                                       
      
   END change_key;
   -------------------------------------------------------------------------------
   
END cwms_rat;
/


SPOOL OFF
SET ECHO OFF
SET TIME OFF

