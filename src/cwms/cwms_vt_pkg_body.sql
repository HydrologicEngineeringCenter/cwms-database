set define off
/* Formatted on 2008/06/26 15:28 (Formatter Plus v4.8.8) */
/* Formatted on 2008/07/14 11:42 (Formatter Plus v4.8.8) */
/* Formatted on 2008/07/17 07:58 (Formatter Plus v4.8.8) */

/* Formatted on 7/7/2011 3:34:16 PM (QP5 v5.163.1008.3004) */

/* Formatted on 8/12/2011 2:24:32 PM (QP5 v5.163.1008.3004) */
/*<TOAD_FILE_CHUNK>*/

CREATE OR REPLACE PACKAGE BODY cwms_vt
AS
	/******************************************************************************
	 NAME: CWMS_VAL
	 PURPOSE:

	 REVISIONS:
	 Ver	 Date  Author	Description
	 --------- ---------- ---------------	------------------------------------
	 1.0	 12/11/2006   1. Created this package body.
	******************************************************************************/
	PROCEDURE store_screening_control (
		p_screening_code					IN NUMBER,
		p_rate_change_disp_int_code	IN NUMBER,
		p_range_active_flag				IN VARCHAR2,
		p_rate_change_active_flag		IN VARCHAR2,
		p_const_active_flag				IN VARCHAR2,
		p_dur_mag_active_flag			IN VARCHAR2,
		p_ignore_nulls 					IN VARCHAR2 DEFAULT 'T'
	)
	IS
		l_rate_change_disp_int_code	NUMBER := NULL;
		l_range_active_flag				VARCHAR2 (1) := NULL;
		l_rate_change_active_flag		VARCHAR2 (1) := NULL;
		l_const_active_flag				VARCHAR2 (1) := NULL;
		l_dur_mag_active_flag			VARCHAR2 (1) := NULL;
		l_ignore_nulls 					BOOLEAN
			:= cwms_util.return_true_or_false (NVL (p_ignore_nulls, 'T'));
	BEGIN
		SELECT	rate_change_disp_interval_code, range_active_flag,
					rate_change_active_flag, const_active_flag,
					dur_mag_active_flag
		  INTO	l_rate_change_disp_int_code, l_range_active_flag,
					l_rate_change_active_flag, l_const_active_flag,
					l_dur_mag_active_flag
		  FROM	at_screening_control
		 WHERE	screening_code = p_screening_code;

		IF l_ignore_nulls
		THEN
			IF p_rate_change_disp_int_code IS NOT NULL
			THEN
				l_rate_change_disp_int_code := p_rate_change_disp_int_code;
			END IF;

			IF p_range_active_flag IS NOT NULL
			THEN
				l_range_active_flag := p_range_active_flag;
			END IF;

			IF p_rate_change_active_flag IS NOT NULL
			THEN
				l_rate_change_active_flag := p_rate_change_active_flag;
			END IF;

			IF p_const_active_flag IS NOT NULL
			THEN
				l_const_active_flag := p_const_active_flag;
			END IF;

			IF p_dur_mag_active_flag IS NOT NULL
			THEN
				l_dur_mag_active_flag := p_dur_mag_active_flag;
			END IF;
		ELSE
			l_rate_change_disp_int_code := p_rate_change_disp_int_code;
			l_range_active_flag := p_range_active_flag;
			l_rate_change_active_flag := p_rate_change_active_flag;
			l_const_active_flag := p_const_active_flag;
			l_dur_mag_active_flag := p_dur_mag_active_flag;
		END IF;

		UPDATE	at_screening_control
			SET	rate_change_disp_interval_code = l_rate_change_disp_int_code,
					range_active_flag = l_range_active_flag,
					rate_change_active_flag = l_rate_change_active_flag,
					const_active_flag = l_const_active_flag,
					dur_mag_active_flag = p_dur_mag_active_flag
		 WHERE	screening_code = p_screening_code;
	END;

	PROCEDURE copy_screening_control (p_screening_code_old	IN NUMBER,
												 p_screening_code_new	IN NUMBER
												)
	IS
		l_const_active_flag				VARCHAR2 (1);
		l_dur_mag_active_flag			VARCHAR2 (1);
		l_range_active_flag				VARCHAR2 (1);
		l_rate_change_active_flag		VARCHAR2 (1);
		l_rate_change_disp_int_code	NUMBER;
	BEGIN
		SELECT	a.const_active_flag, a.dur_mag_active_flag,
					a.range_active_flag, a.rate_change_active_flag,
					a.rate_change_disp_interval_code
		  INTO	l_const_active_flag, l_dur_mag_active_flag,
					l_range_active_flag, l_rate_change_active_flag,
					l_rate_change_disp_int_code
		  FROM	at_screening_control a
		 WHERE	screening_code = p_screening_code_old;

		UPDATE	at_screening_control
			SET	const_active_flag = l_const_active_flag,
					dur_mag_active_flag = l_dur_mag_active_flag,
					range_active_flag = l_range_active_flag,
					rate_change_active_flag = l_rate_change_active_flag,
					rate_change_disp_interval_code = l_rate_change_disp_int_code
		 WHERE	screening_code = p_screening_code_new;
	END;

	---- END of Private calls ----
	---
	--
	FUNCTION get_screening_code_ts_id_count (p_screening_code IN NUMBER)
		RETURN NUMBER
	IS
		l_count	 NUMBER;
	BEGIN
		SELECT	COUNT (*)
		  INTO	l_count
		  FROM	at_screening
		 WHERE	screening_code = p_screening_code;

		RETURN l_count;
	END;

	FUNCTION get_screening_code (p_screening_id	 IN VARCHAR2,
										  p_db_office_id	 IN VARCHAR2 DEFAULT NULL
										 )
		RETURN NUMBER
	IS
		l_screening_code	 NUMBER;
		l_db_office_code	 NUMBER;
	BEGIN
		--
		-- Retrieve the db_office_code...
		l_db_office_code := cwms_util.get_office_code (p_db_office_id);
		--
		-- confirm that screening_id does NOT already exist  -
		--
		l_screening_code :=
			get_screening_code (p_screening_id, l_db_office_code);
		RETURN l_screening_code;
	END;

	FUNCTION get_screening_code (p_screening_id		IN VARCHAR2,
										  p_db_office_code	IN NUMBER DEFAULT NULL
										 )
		RETURN NUMBER
	IS
		l_screening_code	 NUMBER;
	BEGIN
		BEGIN
			SELECT	screening_code
			  INTO	l_screening_code
			  FROM	at_screening_id asi
			 WHERE	UPPER (asi.screening_id) = UPPER (p_screening_id)
						AND asi.db_office_code = p_db_office_code;

			--
			RETURN l_screening_code;
		--
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				cwms_err.raise ('ITEM_DOES_NOT_EXIST',
									 'Screening id: ',
									 p_screening_id
									);
		END;
	END;

	FUNCTION create_screening_code (
		p_screening_id 		 IN VARCHAR2,
		p_screening_id_desc	 IN VARCHAR2,
		p_parameter_id 		 IN VARCHAR2,
		p_parameter_type_id	 IN VARCHAR2 DEFAULT NULL,
		p_duration_id			 IN VARCHAR2 DEFAULT NULL,
		p_db_office_id 		 IN VARCHAR2 DEFAULT NULL
	)
		RETURN NUMBER
	IS
		l_db_office_code			NUMBER;
		l_screening_code			NUMBER;
		l_base_parameter_id		VARCHAR2 (16);
		l_base_parameter_code	NUMBER;
		l_sub_parameter_id		VARCHAR2 (32);
		l_parameter_code			NUMBER;
		l_parameter_type_code	NUMBER := NULL;
		l_duration_code			NUMBER := NULL;
		l_id_already_exists		BOOLEAN;
	BEGIN
		--
		-- Retrieve the db_office_code...
		l_db_office_code := cwms_util.get_office_code (p_db_office_id);
		--
		-- Determine the parameter codes...
		--
		l_base_parameter_id := cwms_util.get_base_id (p_parameter_id);
		l_sub_parameter_id := cwms_util.get_sub_id (p_parameter_id);

		--
		-- GET the Base Parameter Code.
		SELECT	base_parameter_code, base_parameter_id
		  INTO	l_base_parameter_code, l_base_parameter_id
		  FROM	cwms_base_parameter cbp
		 WHERE	UPPER (cbp.base_parameter_id) = UPPER (l_base_parameter_id);

		--
		-- confirm that screening_id does NOT already exist  -
		--
		BEGIN
			l_screening_code :=
				get_screening_code (p_screening_id, l_db_office_code);
			--
			l_id_already_exists := TRUE;
		EXCEPTION
			WHEN OTHERS
			THEN
				l_id_already_exists := FALSE;
		END;

		IF l_id_already_exists
		THEN
			cwms_err.raise ('ITEM_ALREADY_EXISTS',
								 'Screening id: ',
								 p_screening_id
								);
		END IF;

		-- Screening Id does not exist - continue...
		l_parameter_code :=
			cwms_ts.get_parameter_code (
				p_base_parameter_code	=> l_base_parameter_code,
				p_sub_parameter_id		=> l_sub_parameter_id,
				p_office_code				=> l_db_office_code,
				p_create 					=> FALSE
			);

		IF p_parameter_type_id IS NOT NULL
		THEN
			SELECT	parameter_type_code
			  INTO	l_parameter_type_code
			  FROM	cwms_parameter_type cpt
			 WHERE	UPPER (cpt.parameter_type_id) = UPPER (p_parameter_type_id);
		END IF;

		IF p_duration_id IS NOT NULL
		THEN
			SELECT	duration_code
			  INTO	l_duration_code
			  FROM	cwms_duration cd
			 WHERE	UPPER (cd.duration_id) = UPPER (p_duration_id);
		END IF;

		--
		-- Insert new screening_id into database...
		--
		INSERT
			  INTO	at_screening_id (screening_code,
											  db_office_code,
											  screening_id,
											  screening_id_desc,
											  base_parameter_code,
											  parameter_code,
											  parameter_type_code,
											  duration_code
											 )
			VALUES	(
							cwms_seq.NEXTVAL,
							l_db_office_code,
							p_screening_id,
							p_screening_id_desc,
							l_base_parameter_code,
							l_parameter_code,
							l_parameter_type_code,
							l_duration_code
						)
		RETURNING	screening_code
			  INTO	l_screening_code;

		INSERT INTO   at_screening_control (screening_code)
			  VALUES   (l_screening_code);

		store_screening_control (p_screening_code 				 => l_screening_code,
										 p_rate_change_disp_int_code	 => NULL,
										 p_range_active_flag 			 => 'N',
										 p_rate_change_active_flag 	 => 'N',
										 p_const_active_flag 			 => 'N',
										 p_dur_mag_active_flag			 => 'N',
										 p_ignore_nulls					 => 'T'
										);
		COMMIT;
		--
		RETURN l_screening_code;
	--
	END create_screening_code;

	PROCEDURE create_screening_id (
		p_screening_id 		 IN VARCHAR2,
		p_screening_id_desc	 IN VARCHAR2,
		p_parameter_id 		 IN VARCHAR2,
		p_parameter_type_id	 IN VARCHAR2 DEFAULT NULL,
		p_duration_id			 IN VARCHAR2 DEFAULT NULL,
		p_db_office_id 		 IN VARCHAR2 DEFAULT NULL
	)
	IS
		l_screening_code	 NUMBER;
	BEGIN
		l_screening_code :=
			create_screening_code (p_screening_id,
										  p_screening_id_desc,
										  p_parameter_id,
										  p_parameter_type_id,
										  p_duration_id,
										  p_db_office_id
										 );
	END create_screening_id;

	PROCEDURE copy_screening_id (
		p_screening_id_old		  IN VARCHAR2,
		p_screening_id_new		  IN VARCHAR2,
		p_screening_id_desc_new   IN VARCHAR2,
		p_parameter_id_new		  IN VARCHAR2 DEFAULT NULL,
		p_parameter_type_id_new   IN VARCHAR2 DEFAULT NULL,
		p_duration_id_new 		  IN VARCHAR2 DEFAULT NULL,
		p_param_check				  IN VARCHAR2 DEFAULT 'T',
		p_db_office_id 			  IN VARCHAR2 DEFAULT NULL
	)
	IS
		l_param_check				  BOOLEAN := TRUE;
		l_new_id_already_exists   BOOLEAN := FALSE;
		l_db_office_id 			  VARCHAR2 (16);
		l_parameter_id_old		  VARCHAR2 (49);
		l_parameter_id_new		  VARCHAR2 (49);
		l_db_office_code			  NUMBER;
		l_screening_code_new 	  NUMBER;
		l_screening_code_old 	  NUMBER;
		l_parameter_code_new 	  NUMBER;
		l_parameter_code_old 	  NUMBER;
	BEGIN
		IF NVL (UPPER (p_param_check), 'T') = 'F'
		THEN
			l_param_check := FALSE;
		END IF;

		IF p_db_office_id IS NULL
		THEN
			l_db_office_id := cwms_util.user_office_id;
		ELSE
			l_db_office_id := UPPER (p_db_office_id);
		END IF;

		l_db_office_code := cwms_util.get_office_code (l_db_office_id);

		--
		-- Retrieve old screening id info...
		BEGIN
			l_screening_code_old :=
				get_screening_code (p_screening_id_old, l_db_office_id);

			SELECT	parameter_code
			  INTO	l_parameter_code_old
			  FROM	at_screening_id
			 WHERE	screening_code = l_screening_code_old;

			l_parameter_id_old :=
				cwms_util.get_parameter_id (l_parameter_code_old);
		EXCEPTION
			WHEN OTHERS
			THEN
				cwms_err.raise (
					'GENERIC_ERROR',
						'Old Screening id: '
					|| p_screening_id_old
					|| ' not found. Cannot copy to '
					|| p_screening_id_new
				);
		END;

		--
		-- The new screening id should not already exist...
		BEGIN
			l_screening_code_new :=
				get_screening_code (p_screening_id_new, l_db_office_id);
			l_new_id_already_exists := TRUE;
		EXCEPTION
			WHEN OTHERS
			THEN
				-- expecting an exception - i.e., new screening id should not exist.
				NULL;
		END;

		IF l_new_id_already_exists
		THEN
			cwms_err.raise (
				'GENERIC_ERROR',
				'New Screening id: ' || p_screening_id_new || ' already exists.'
			);
		END IF;

		IF p_parameter_id_new IS NULL
		THEN
			l_parameter_id_new := l_parameter_id_old;
		END IF;

		IF l_param_check
		THEN
			IF l_parameter_id_new != l_parameter_id_old
			THEN
				cwms_err.raise (
					'GENERIC_ERROR',
					'The old and new paramaeter id''s do not match. Set the p_param_check to False to override this check.'
				);
			END IF;
		END IF;

		l_screening_code_new :=
			create_screening_code (p_screening_id_new,
										  p_screening_id_desc_new,
										  l_parameter_id_new,
										  p_parameter_type_id_new,
										  p_duration_id_new,
										  p_db_office_id
										 );
		copy_screening_criteria (p_screening_id_old,
										 p_screening_id_new,
										 p_param_check,
										 p_db_office_id
										);
		copy_screening_control (l_screening_code_old, l_screening_code_new);
	END;

	PROCEDURE rename_screening_id (
		p_screening_id_old	IN VARCHAR2,
		p_screening_id_new	IN VARCHAR2,
		p_db_office_id 		IN VARCHAR2 DEFAULT NULL
	)
	IS
		l_db_office_code			NUMBER;
		l_screening_code			NUMBER;
		l_base_parameter_id		VARCHAR2 (16);
		l_base_parameter_code	NUMBER;
		l_id_already_exists		BOOLEAN;
	BEGIN
		--
		-- Retrieve the db_office_code...
		l_db_office_code := cwms_util.get_office_code (p_db_office_id);

		--
		--
		-- Confirm the new screening_id does NOT exist...
		BEGIN
			l_screening_code :=
				get_screening_code (p_screening_id		=> p_screening_id_new,
										  p_db_office_code	=> l_db_office_code
										 );
			--
			l_id_already_exists := TRUE;
		EXCEPTION
			WHEN OTHERS
			THEN
				l_id_already_exists := FALSE;
		END;

		IF l_id_already_exists
		THEN
			-- the rename may simply be changing the case of the
			-- screening id, so only throw an exception if
			-- the nEw and OlD id's are not identical...
			IF p_screening_id_old = p_screening_id_new
			THEN
				cwms_err.raise ('ITEM_ALREADY_EXISTS',
									 'Screening id: ',
									 p_screening_id_new
									);
			ELSIF UPPER (p_screening_id_old) != UPPER (p_screening_id_new)
			THEN
				cwms_err.raise ('ITEM_ALREADY_EXISTS',
									 'Screening id: ',
									 p_screening_id_new
									);
			END IF;
		END IF;

		--
		-- Confirm the old screening_id exists...
		BEGIN
			l_screening_code :=
				get_screening_code (p_screening_id_old, l_db_office_code);
		EXCEPTION
			WHEN OTHERS
			THEN
				cwms_err.raise ('ITEM_DOES_NOT_EXIST',
									 'Screening id: ',
									 p_screening_id_old
									);
		END;

		--
		-- Rename the screening id...
		UPDATE	at_screening_id
			SET	screening_id = p_screening_id_new
		 WHERE	screening_code = l_screening_code;

		--
		COMMIT;
	END;

	PROCEDURE update_screening_id_desc (
		p_screening_id 		 IN VARCHAR2,
		p_screening_id_desc	 IN VARCHAR2,
		p_db_office_id 		 IN VARCHAR2 DEFAULT NULL
	)
	IS
		l_db_office_code		 NUMBER;
		l_screening_code		 NUMBER;
		l_ts_ni_hash			 VARCHAR2 (80);
		l_id_already_exists	 BOOLEAN;
	BEGIN
		--
		--
		-- Confirm the screening_id exists...
		BEGIN
			l_screening_code :=
				get_screening_code (p_screening_id, p_db_office_id);
		EXCEPTION
			WHEN OTHERS
			THEN
				cwms_err.raise ('ITEM_DOES_NOT_EXIST',
									 'Screening id: ',
									 p_screening_id
									);
		END;

		--
		-- Rename the screening id...
		UPDATE	at_screening_id
			SET	screening_id_desc = p_screening_id_desc
		 WHERE	screening_code = l_screening_code;

		COMMIT;
	END update_screening_id_desc;

	--
	--******************************************************************* --
	--******************************************************************* --
	--
	-- delete_screening_id
	--
	--------------------------------------------------------------------- --
	--
	-- By default, delete_screening_id will throw an exception if there are
	-- any ts_codes assigned to the screening_id to be deleted. One can
	-- override this by setting p_cascade to "T".
	PROCEDURE delete_screening_id (
		p_screening_id 		 IN VARCHAR2,
		p_parameter_id 		 IN VARCHAR2,
		p_parameter_type_id	 IN VARCHAR2,
		p_duration_id			 IN VARCHAR2,
		p_cascade				 IN VARCHAR2 DEFAULT 'F',
		p_db_office_id 		 IN VARCHAR2 DEFAULT NULL
	)
	IS
		l_db_office_code	 NUMBER;
		l_screening_code	 NUMBER;
		l_count				 NUMBER;
		l_cascade			 BOOLEAN
			:= cwms_util.return_true_or_false (NVL (p_cascade, 'F'));
	BEGIN
		--
		-- Retrieve the db_office_code...
		l_db_office_code := cwms_util.get_office_code (p_db_office_id);

		--

		-- confirm that ts_screening_id exists  -
		--
		BEGIN
			l_screening_code :=
				get_screening_code (p_screening_id, p_db_office_id);
		EXCEPTION
			WHEN OTHERS
			THEN
				cwms_err.raise ('ITEM_DOES_NOT_EXIST',
									 'Screening id: ',
									 p_screening_id
									);
		END;

		IF l_cascade
		THEN
			DELETE FROM   at_screening
					WHERE   screening_code = l_screening_code;
		ELSE
			SELECT	COUNT (*)
			  INTO	l_count
			  FROM	at_screening
			 WHERE	screening_code = l_screening_code;

			IF l_count > 0
			THEN
				cwms_err.raise (
					'GENERIC ERROR',
						'Cannot delete the Screening id: '
					|| p_screening_id
					|| ' because '
					|| l_count
					|| ' cwms_ts_id(s) is(are) assigned to it. '
				);
			END IF;
		END IF;

		DELETE FROM   at_screening_dur_mag
				WHERE   screening_code = l_screening_code;

		DELETE FROM   at_screening_criteria
				WHERE   screening_code = l_screening_code;

		DELETE FROM   at_screening_control
				WHERE   screening_code = l_screening_code;

		DELETE FROM   at_screening_id
				WHERE   screening_code = l_screening_code;

		COMMIT;
	--
	END delete_screening_id;

	--
	--********************************************************************** -
	--********************************************************************** -
	--
	-- STORE_ALIASES		  -
	--
	-- p_store_rule - Valid store rules are:		-
	-- 	Delete Insert - This will delete all existing aliases -
	-- 	  and insert the new set of aliases   -
	-- 	  in your p_alias_array. This is the -
	-- 	  Default.	  -
	-- 	Replace All  - This will update any pre-existing -
	-- 	  aliases and insert new ones   -
	--
	-- p_ignorenulls - is only valid when the "Replace All" store rull is    -
	--   envoked.
	--   if 'T' then do not update a pre-existing value        -
	--   with a newly passed-in null value.	 -
	--   if 'F' then update a pre-existing value               -
	--   with a newly passed-in null value.	 -
	--*--------------------------------------------------------------------- -
	--
	PROCEDURE copy_screening_criteria (
		p_screening_id_old	IN VARCHAR2,
		p_screening_id_new	IN VARCHAR2,
		p_param_check			IN VARCHAR2 DEFAULT 'T',
		p_db_office_id 		IN VARCHAR2 DEFAULT NULL
	)
	IS
		l_param_check			  BOOLEAN := TRUE;
		l_db_office_id 		  VARCHAR2 (16);
		l_db_office_code		  NUMBER;
		l_screening_code_new   NUMBER;
		l_screening_code_old   NUMBER;
		l_parameter_code_new   NUMBER;
		l_parameter_code_old   NUMBER;
	BEGIN
		IF NVL (UPPER (p_param_check), 'T') = 'F'
		THEN
			l_param_check := FALSE;
		END IF;

		IF p_db_office_id IS NULL
		THEN
			l_db_office_id := cwms_util.user_office_id;
		ELSE
			l_db_office_id := UPPER (p_db_office_id);
		END IF;

		l_db_office_code := cwms_util.get_office_code (l_db_office_id);

		--
		-- Retrieve old screening id info...
		BEGIN
			l_screening_code_old :=
				get_screening_code (p_screening_id_old, l_db_office_id);

			SELECT	parameter_code
			  INTO	l_parameter_code_old
			  FROM	at_screening_id
			 WHERE	screening_code = l_screening_code_old;
		EXCEPTION
			WHEN OTHERS
			THEN
				cwms_err.raise (
					'GENERIC_ERROR',
						'Old Screening id: '
					|| p_screening_id_old
					|| ' not found. Cannot copy to '
					|| p_screening_id_new
				);
		END;

		--
		-- Retrieve new screening id info...
		BEGIN
			l_screening_code_new :=
				get_screening_code (p_screening_id_new, l_db_office_id);

			SELECT	parameter_code
			  INTO	l_parameter_code_new
			  FROM	at_screening_id
			 WHERE	screening_code = l_screening_code_new;
		EXCEPTION
			WHEN OTHERS
			THEN
				cwms_err.raise (
					'GENERIC_ERROR',
						'New Screening id: '
					|| p_screening_id_new
					|| ' not found. Cannot copy to non-existant screening id.'
				);
		END;

		--
		-- check old/new parameter id if p_param_check is true...
		IF l_param_check
		THEN
			IF l_parameter_code_old != l_parameter_code_new
			THEN
				cwms_err.raise (
					'GENERIC_ERROR',
					'The old and new paramaeter id''s do not match. Set the p_param_check to False to override this check.'
				);
			END IF;
		END IF;

		-- new and old check out, perform the copy...

		-- Delete any screening entries in the new screening id...
		DELETE FROM   at_screening_dur_mag
				WHERE   screening_code = l_screening_code_new;

		--
		DELETE FROM   at_screening_criteria
				WHERE   screening_code = l_screening_code_new;

		-- Copy old screening criteria entries into the new screening criteria...
		INSERT INTO   at_screening_criteria
			SELECT	l_screening_code_new, season_start_date, range_reject_lo,
						range_reject_hi, range_question_lo, range_question_hi,
						rate_change_reject_rise, rate_change_reject_fall,
						rate_change_quest_rise, rate_change_quest_fall,
						const_reject_duration_code, const_reject_min,
						const_reject_tolerance, const_reject_n_miss,
						const_quest_duration_code, const_quest_min,
						const_quest_tolerance, const_quest_n_miss,
						estimate_expression
			  FROM	at_screening_criteria
			 WHERE	screening_code = l_screening_code_old;

		INSERT INTO   at_screening_dur_mag
			SELECT	l_screening_code_new, season_start_date, duration_code,
						reject_lo, reject_hi, question_lo, question_hi
			  FROM	at_screening_dur_mag
			 WHERE	screening_code = l_screening_code_old;
	END;

	PROCEDURE store_screening_criteria (
		p_screening_id 						IN VARCHAR2,
		p_unit_id								IN VARCHAR2,
		p_screen_crit_array					IN screen_crit_array,
		p_rate_change_disp_interval_id	IN VARCHAR2,
		p_screening_control					IN screening_control_t,
		p_store_rule							IN VARCHAR2 DEFAULT 'DELETE INSERT',
		p_ignore_nulls 						IN VARCHAR2 DEFAULT 'T',
		p_db_office_id 						IN VARCHAR2 DEFAULT NULL
	)
	IS
		l_store_rule						VARCHAR2 (16)
			:= UPPER (NVL (p_store_rule, cwms_util.delete_insert));
		l_count								NUMBER := p_screen_crit_array.COUNT;
		l_db_office_id 					VARCHAR2 (16);
		l_db_office_code					NUMBER;
		l_screening_code					NUMBER;
		l_rate_change_interval_code	NUMBER;
		l_to_unit_code 					NUMBER;
		l_abstract_param_code			NUMBER;
		l_factor 							NUMBER;
		l_offset 							NUMBER;
		--
		l_range_active_flag				VARCHAR2 (1)
			:= p_screening_control.range_active_flag;
		l_rate_change_active_flag		VARCHAR2 (1)
			:= p_screening_control.rate_change_active_flag;
		l_const_active_flag				VARCHAR2 (1)
			:= p_screening_control.const_active_flag;
		l_dur_mag_active_flag			VARCHAR2 (1)
			:= p_screening_control.dur_mag_active_flag;

		CURSOR l_sc_cur
		IS
			SELECT	*
			  FROM	TABLE (CAST (p_screen_crit_array AS screen_crit_array));

		l_sc_rec 							l_sc_cur%ROWTYPE;
	BEGIN
		IF l_count = 0
		THEN
			cwms_err.raise (
				'GENERIC_ERROR',
				'No screening criteria found in p_screen_crit_array.'
			);
		END IF;

		IF p_db_office_id IS NULL
		THEN
			l_db_office_id := cwms_util.user_office_id;
		ELSE
			l_db_office_id := UPPER (p_db_office_id);
		END IF;

		l_db_office_code := cwms_util.get_office_code (l_db_office_id);

		BEGIN
			l_screening_code :=
				get_screening_code (p_screening_id, l_db_office_id);
		EXCEPTION
			WHEN OTHERS
			THEN
				cwms_err.raise (
					'GENERIC_ERROR',
						'Screening id: '
					|| p_screening_id
					|| ' not found. Cannot store screening criteria.'
				);
		END;

		IF l_store_rule = cwms_util.delete_insert
		THEN
			--
			DELETE FROM   at_screening_dur_mag
					WHERE   screening_code = l_screening_code;

			--
			DELETE FROM   at_screening_criteria
					WHERE   screening_code = l_screening_code;
		--
		ELSIF l_store_rule != cwms_util.replace_all
		THEN
			cwms_err.raise ('INVALID_STORE_RULE',
								 p_store_rule || ' is not yet supported. '
								);
		END IF;

		IF l_rate_change_active_flag != 'N'
		THEN
			SELECT	interval_code
			  INTO	l_rate_change_interval_code
			  FROM	cwms_interval
			 WHERE	UPPER (interval_id) =
							UPPER (p_rate_change_disp_interval_id);
		END IF;

		SELECT	cbp.unit_code, cbp.abstract_param_code
		  INTO	l_to_unit_code, l_abstract_param_code
		  FROM	cwms_base_parameter cbp, at_parameter ap
		 WHERE	parameter_code = (SELECT	parameter_code
											  FROM	at_screening_id
											 WHERE	screening_code = l_screening_code)
					AND cbp.base_parameter_code = ap.base_parameter_code;

		SELECT	factor, offset
		  INTO	l_factor, l_offset
		  FROM	cwms_unit_conversion
		 WHERE	from_unit_id = p_unit_id AND to_unit_code = l_to_unit_code;

		--
		OPEN l_sc_cur;

		LOOP
			FETCH l_sc_cur
			INTO l_sc_rec;

			EXIT WHEN l_sc_cur%NOTFOUND;

			INSERT
			  INTO	at_screening_criteria (screening_code,
													  season_start_date,
													  range_reject_lo,
													  range_reject_hi,
													  range_question_lo,
													  range_question_hi,
													  rate_change_reject_rise,
													  rate_change_reject_fall,
													  rate_change_quest_rise,
													  rate_change_quest_fall,
													  const_reject_duration_code,
													  const_reject_min,
													  const_reject_tolerance,
													  const_reject_n_miss,
													  const_quest_duration_code,
													  const_quest_min,
													  const_quest_tolerance,
													  const_quest_n_miss,
													  estimate_expression
													 )
			VALUES	(
							l_screening_code,
							l_sc_rec.season_start_day
							+ (l_sc_rec.season_start_month - 1) * 30,
							l_sc_rec.range_reject_lo * l_factor + l_offset,
							l_sc_rec.range_reject_hi * l_factor + l_offset,
							l_sc_rec.range_question_lo * l_factor + l_offset,
							l_sc_rec.range_question_hi * l_factor + l_offset,
							l_sc_rec.rate_change_reject_rise * l_factor + l_offset,
							l_sc_rec.rate_change_reject_fall * l_factor + l_offset,
							l_sc_rec.rate_change_quest_rise * l_factor + l_offset,
							l_sc_rec.rate_change_quest_fall * l_factor + l_offset,
							CASE
								WHEN l_sc_rec.const_reject_duration_id IS NOT NULL
								THEN
									(SELECT	 duration_code
										FROM	 cwms_duration
									  WHERE	 UPPER (duration_id) =
													 UPPER (
														 l_sc_rec.const_reject_duration_id
													 ))
								ELSE
									NULL
							END,
							l_sc_rec.const_reject_min * l_factor + l_offset,
							l_sc_rec.const_reject_tolerance * l_factor + l_offset,
							l_sc_rec.const_reject_n_miss,
							CASE
								WHEN l_sc_rec.const_quest_duration_id IS NOT NULL
								THEN
									(SELECT	 duration_code
										FROM	 cwms_duration
									  WHERE	 UPPER (duration_id) =
													 UPPER (
														 l_sc_rec.const_quest_duration_id
													 ))
								ELSE
									NULL
							END,
							l_sc_rec.const_quest_min * l_factor + l_offset,
							l_sc_rec.const_quest_tolerance * l_factor + l_offset,
							l_sc_rec.const_quest_n_miss,
							l_sc_rec.estimate_expression
						);

			l_count := l_sc_rec.dur_mag_array.COUNT;
			DBMS_OUTPUT.put_line ('number of dur mag elements: ' || l_count);

			IF l_count > 0
			THEN
				FOR i IN 1 .. l_count
				LOOP
					DBMS_OUTPUT.put_line (
						i || ' ' || l_sc_rec.dur_mag_array (i).duration_id
					);

					INSERT
					  INTO	at_screening_dur_mag (screening_code,
															 season_start_date,
															 duration_code,
															 reject_lo,
															 reject_hi,
															 question_lo,
															 question_hi
															)
					VALUES	(
									l_screening_code,
									l_sc_rec.season_start_day
									+ (l_sc_rec.season_start_month - 1) * 30,
									(SELECT	 duration_code
										FROM	 cwms_duration
									  WHERE	 UPPER (duration_id) =
													 UPPER (
														 l_sc_rec.dur_mag_array (i).duration_id
													 )),
									l_sc_rec.dur_mag_array (i).reject_lo * l_factor
									+ l_offset,
									l_sc_rec.dur_mag_array (i).reject_hi * l_factor
									+ l_offset,
									l_sc_rec.dur_mag_array (i).question_lo * l_factor
									+ l_offset,
									l_sc_rec.dur_mag_array (i).question_hi * l_factor
									+ l_offset
								);
				END LOOP;
			END IF;
		--
		END LOOP;

		CLOSE l_sc_cur;

		--
		--
		store_screening_control (l_screening_code,
										 l_rate_change_interval_code,
										 l_range_active_flag,
										 l_rate_change_active_flag,
										 l_const_active_flag,
										 l_dur_mag_active_flag,
										 p_ignore_nulls
										);
	END store_screening_criteria;

	--------------------------------------------------------------------------------
	--
	-- get_process_shefit_files is normally called by processSHEFIT. The call lets -
	--   processSHEFIT know if it should use the criteria file and/or OTF -
	--   file passed back in place of any files found (and/or specified) on -
	--   the file system. If the specified DataStream has not been defined in -
	--   the database, then nulls are returned and the "use_db" psuedo-booleans -
	--   return 'F'. processSHEFIT would then default to cirt and OTF files
	--   found on the file system.
	--
	-- Parameters:
	-- p_use_db_crit - OUT - returns a varchar2(1). The returned parameter will be -
	--  "T" if processSHEFIT should use the DB's crit file. "F" indicates that -
	--  processSHEFIT should use the crit file found on the file system.
	-- p_crit_file - OUT - returns a CLOB. This is the processSHEFIT criteria file -
	--  provided by the database.
	-- p_use_db_otf - OUT - returns a varchar2(1). The returned parameter will be
	--   "T" if processSHEFIT should use the DB's otf file. "F" indicates that
	--   processSHEFIT should use the otf file found on the file system.
	-- p_otf_file - OUT - returns a CLOB. This is the processSHEFIT otf file
	--   provide by the database.
	-- p_data_stream - IN - varchar2(16) - required parameter. This is the name of
	--   the datastream.
	-- p_db_office_id - in - varchar2(16) - optional parameter) is the database
	--   office id that this data stream will be/is assigned too. Normally this
	--   is left null and the user's default database office id is used.
	--
	PROCEDURE get_process_shefit_files (
		p_use_db_crit			 OUT VARCHAR2,
		p_crit_file 			 OUT CLOB,
		p_use_db_otf			 OUT VARCHAR2,
		p_otf_file				 OUT CLOB,
		p_data_stream_id	 IN	  VARCHAR2,
		p_db_office_id 	 IN	  VARCHAR2 DEFAULT NULL
	)
	IS
		l_is_data_stream_active   BOOLEAN;
	BEGIN
		cwms_shef.get_process_shefit_files (
			p_use_db_crit		 => p_use_db_crit,
			p_crit_file 		 => p_crit_file,
			p_use_db_otf		 => p_use_db_otf,
			p_otf_file			 => p_otf_file,
			p_data_stream_id	 => p_data_stream_id,
			p_db_office_id 	 => p_db_office_id
		);
	--
	END;

	PROCEDURE assign_screening_id (
		p_screening_id 		IN VARCHAR2,
		p_scr_assign_array	IN screen_assign_array,
		p_db_office_id 		IN VARCHAR2 DEFAULT NULL
	)
	IS
		l_db_office_id 			  VARCHAR2 (16);
		l_db_office_code			  NUMBER;
		l_num 						  NUMBER := p_scr_assign_array.COUNT;
		l_screening_code			  NUMBER;
		l_base_parameter_code	  NUMBER := NULL;
		l_base_parameter_code_a   NUMBER := NULL;
		l_parameter_code			  NUMBER := NULL;
		l_parameter_code_a		  NUMBER := NULL;
		l_parameter_type_code	  NUMBER := NULL;
		l_parameter_type_code_a   NUMBER := NULL;
		l_duration_code			  NUMBER := NULL;
		l_duration_code_a 		  NUMBER := NULL;
		l_sub_parameter_id		  VARCHAR2 (32) := NULL;
		l_ts_code					  NUMBER;
		--
		l_params_match 			  BOOLEAN;
		l_param_types_match		  BOOLEAN;
		l_duration_match			  BOOLEAN;
	BEGIN
		DBMS_OUTPUT.put_line ('starting assign');

		IF l_num < 1
		THEN
			cwms_err.raise (
				'GENERIC_ERROR',
				'No screening id assignments found in p_scr_assign_array.'
			);
		END IF;

		IF p_db_office_id IS NULL
		THEN
			l_db_office_id := cwms_util.user_office_id;
		ELSE
			l_db_office_id := UPPER (p_db_office_id);
		END IF;

		l_db_office_code := cwms_util.get_office_code (l_db_office_id);
		l_screening_code :=
			get_screening_code (p_screening_id, l_db_office_code);

		-- retrieve data for scrrening id...
		SELECT	base_parameter_code, parameter_code, parameter_type_code,
					duration_code
		  INTO	l_base_parameter_code, l_parameter_code, l_parameter_type_code,
					l_duration_code
		  FROM	at_screening_id
		 WHERE	screening_code = l_screening_code;

		SELECT	sub_parameter_id
		  INTO	l_sub_parameter_id
		  FROM	at_parameter
		 WHERE	parameter_code = l_parameter_code;

		FOR i IN 1 .. l_num
		LOOP
			DBMS_OUTPUT.put_line (p_scr_assign_array (i).cwms_ts_id);

			-- cwms_err.RAISE ('GENERIC_ERROR', 'Got here: '||p_scr_assign_array (i).cwms_ts_id);
			SELECT	mvcti.ts_code, atp.base_parameter_code,
						atcts.parameter_code, atcts.parameter_type_code,
						atcts.duration_code
			  INTO	l_ts_code, l_base_parameter_code_a, l_parameter_code_a,
						l_parameter_type_code_a, l_duration_code_a
			  FROM	mv_cwms_ts_id mvcti,
						at_cwms_ts_spec atcts,
						at_parameter atp
			 WHERE	mvcti.ts_code = atcts.ts_code
						AND atcts.parameter_code = atp.parameter_code
						AND UPPER (mvcti.cwms_ts_id) =
								 UPPER (p_scr_assign_array (i).cwms_ts_id)
						AND mvcti.db_office_code = l_db_office_code;

			l_params_match := FALSE;
			l_param_types_match := FALSE;
			l_duration_match := FALSE;

			IF l_sub_parameter_id IS NULL
			THEN
				IF l_base_parameter_code = l_base_parameter_code_a
				THEN
					l_params_match := TRUE;
				END IF;
			ELSE
				IF l_parameter_code = l_parameter_code_a
				THEN
					l_params_match := TRUE;
				END IF;
			END IF;

			IF l_parameter_type_code IS NULL
				OR l_parameter_type_code = l_parameter_type_code_a
			THEN
				l_param_types_match := TRUE;
			END IF;

			IF l_duration_code IS NULL OR l_duration_code = l_duration_code_a
			THEN
				l_duration_match := TRUE;
			END IF;

			IF l_params_match AND l_param_types_match AND l_duration_match
			THEN
				NULL;
			ELSE
				cwms_err.raise (
					'GENERIC_ERROR',
						'The cwms_ts_id: '
					|| p_scr_assign_array (i).cwms_ts_id
					|| ' cannot be assigned to the '
					|| p_screening_id
					|| ' screening id.'
				);
			END IF;
		END LOOP;

		MERGE INTO	 at_screening ats
			  USING	 (SELECT   (SELECT	mvcti.ts_code
										  FROM	mv_cwms_ts_id mvcti
										 WHERE	UPPER (cwms_ts_id) =
														UPPER (a.cwms_ts_id)
													AND mvcti.db_office_code =
															 l_db_office_code)
										  ts_code,
									  CASE
										  WHEN UPPER (a.active_flag) = 'T' THEN 'T'
										  ELSE 'F'
									  END
										  active_flag,
									  (SELECT	mvcti.ts_code
										  FROM	mv_cwms_ts_id mvcti
										 WHERE	UPPER (cwms_ts_id) =
														UPPER (a.resultant_ts_id))
										  resultant_ts_code
							 FROM   TABLE (p_scr_assign_array) a) b
				  ON	 (ats.ts_code = b.ts_code)
		WHEN MATCHED
		THEN
			UPDATE SET
				ats.screening_code = l_screening_code,
				ats.active_flag = b.active_flag,
				ats.resultant_ts_code = b.resultant_ts_code
		WHEN NOT MATCHED
		THEN
			INSERT		 (ts_code,
							  screening_code,
							  active_flag,
							  resultant_ts_code
							 )
				 VALUES	 (
								 b.ts_code,
								 l_screening_code,
								 b.active_flag,
								 b.resultant_ts_code
							 );
	END assign_screening_id;

	PROCEDURE unassign_screening_id (
		p_screening_id 		IN VARCHAR2,
		p_cwms_ts_id_array	IN cwms_ts_id_array,
		p_unassign_all 		IN VARCHAR2 DEFAULT 'F',
		p_db_office_id 		IN VARCHAR2 DEFAULT NULL
	)
	IS
		l_unassign_all 	 BOOLEAN := FALSE;
		l_db_office_id 	 VARCHAR2 (16);
		l_db_office_code	 NUMBER;
		l_num 				 NUMBER := p_cwms_ts_id_array.COUNT;
		l_screening_code	 NUMBER;
	BEGIN
		IF UPPER (NVL (p_unassign_all, 'F')) = 'T'
		THEN
			l_unassign_all := TRUE;
		END IF;

		IF p_db_office_id IS NULL
		THEN
			l_db_office_id := cwms_util.user_office_id;
		ELSE
			l_db_office_id := UPPER (p_db_office_id);
		END IF;

		l_db_office_code := cwms_util.get_office_code (l_db_office_id);
		l_screening_code :=
			get_screening_code (p_screening_id, l_db_office_code);

		IF l_unassign_all
		THEN
			DELETE FROM   at_screening
					WHERE   screening_code = l_screening_code;
		ELSIF l_num < 1
		THEN
			cwms_err.raise ('GENERIC_ERROR',
								 'No cwms_ts_id''s passed-in to unassin.'
								);
		ELSE
			DELETE FROM   at_screening
					WHERE   screening_code = l_screening_code
							  AND ts_code IN
										(SELECT	 mvcti.ts_code
											FROM	 mv_cwms_ts_id mvcti,
													 TABLE (p_cwms_ts_id_array) a
										  WHERE	 UPPER (mvcti.cwms_ts_id) =
														 UPPER (a.cwms_ts_id));
		END IF;
	END unassign_screening_id;

	PROCEDURE val_abs_mag (p_timeseries_data	 IN OUT tsv_array,
								  p_min_reject 		 IN	  BINARY_DOUBLE,
								  p_min_question		 IN	  BINARY_DOUBLE,
								  p_max_question		 IN	  BINARY_DOUBLE,
								  p_max_reject 		 IN	  BINARY_DOUBLE
								 )
	IS
		l_screened_id		 VARCHAR2 (16);
		l_validity_id		 VARCHAR2 (16);
		l_range_id			 VARCHAR2 (16);
		l_changed_id		 VARCHAR2 (16);
		l_repl_cause_id	 VARCHAR2 (16);
		l_repl_method_id	 VARCHAR2 (16);
		l_test_failed_id	 VARCHAR2 (16);
		l_protection_id	 VARCHAR2 (16);
	BEGIN
		FOR x IN p_timeseries_data.FIRST .. p_timeseries_data.LAST
		LOOP
			-- Retrieve existing data quality settings for data. If an undefined data quality code
			-- is set, then reset to zero.
			BEGIN
				SELECT	screened_id, validity_id, range_id, changed_id,
							repl_cause_id, repl_method_id, test_failed_id,
							protection_id
				  INTO	l_screened_id, l_validity_id, l_range_id, l_changed_id,
							l_repl_cause_id, l_repl_method_id, l_test_failed_id,
							l_protection_id
				  FROM	cwms_data_quality cdq
				 WHERE	cdq.quality_code = p_timeseries_data (x).quality_code;
			EXCEPTION
				WHEN NO_DATA_FOUND
				THEN
					IF p_timeseries_data (x).VALUE IS NOT NULL
					THEN
						SELECT	screened_id, validity_id, range_id, changed_id,
									repl_cause_id, repl_method_id, test_failed_id,
									protection_id
						  INTO	l_screened_id, l_validity_id, l_range_id,
									l_changed_id, l_repl_cause_id, l_repl_method_id,
									l_test_failed_id, l_protection_id
						  FROM	cwms_data_quality cdq
						 WHERE	cdq.quality_code = 0;
					ELSE
						SELECT	screened_id, validity_id, range_id, changed_id,
									repl_cause_id, repl_method_id, test_failed_id,
									protection_id
						  INTO	l_screened_id, l_validity_id, l_range_id,
									l_changed_id, l_repl_cause_id, l_repl_method_id,
									l_test_failed_id, l_protection_id
						  FROM	cwms_data_quality cdq
						 WHERE	cdq.quality_code = 5;
					END IF;
			END;

			----
			-- validate data...
			----
			IF l_validity_id != 'MISSING' OR l_protection_id = 'UNPROTECTED'
			THEN
				l_screened_id := 'SCREENED';
				l_range_id := 'NO_RANGE';
				l_changed_id := 'ORIGINAL';
				l_repl_cause_id := 'NONE';
				l_repl_method_id := 'NONE';
				l_protection_id := 'UNPROTECTED';

				-- l_screened := 1;
				IF p_timeseries_data (x).VALUE < p_min_reject
					OR p_timeseries_data (x).VALUE > p_max_reject
				THEN
					l_validity_id := 'REJECTED';
					l_test_failed_id := 'ABSOLUTE_VALUE';
				ELSIF p_timeseries_data (x).VALUE < p_min_question
						OR p_timeseries_data (x).VALUE > p_max_question
				THEN
					l_validity_id := 'QUESTIONABLE';
					l_test_failed_id := 'ABSOLUTE_VALUE';
				ELSE
					l_validity_id := 'OKAY';
					l_test_failed_id := 'NONE';
				END IF;

				SELECT	quality_code
				  INTO	p_timeseries_data (x).quality_code
				  FROM	cwms_data_quality
				 WHERE		 screened_id = 'SCREENED'
							AND range_id = 'NO_RANGE'
							AND changed_id = 'ORIGINAL'
							AND repl_cause_id = 'NONE'
							AND repl_method_id = 'NONE'
							AND protection_id = 'UNPROTECTED'
							AND validity_id = l_validity_id
							AND test_failed_id = l_test_failed_id;
			END IF;
		END LOOP;
	END val_abs_mag;

	-------------------
	-------------------
	-------------------
	--
	-- intended to provide a listing of an office's templates.
	-- The cursor returns the following four columns:
	--  template_id	VARCHAR2 (32),
	--  description	VARCHAR2 (256),
	--  primary_ind_param_id  VARCHAR2 (16),
	--  dep_param_id	 VARCHAR2 (16)
	PROCEDURE cat_tr_templates (p_query_cursor		  OUT SYS_REFCURSOR,
										 p_db_office_code   IN		NUMBER
										)
	AS
	BEGIN
		OPEN p_query_cursor FOR
			SELECT	a.template_id, a.description,
						d.base_parameter_id || SUBSTR ('-', 1, LENGTH (b.sub_parameter_id)) || b.sub_parameter_id primary_ind_param_id,
						e.base_parameter_id || SUBSTR ('-', 1, LENGTH (c.sub_parameter_id)) || c.sub_parameter_id dep_param_id
			  FROM	at_tr_template_id a,
						at_parameter b,
						at_parameter c,
						cwms_base_parameter d,
						cwms_base_parameter e
			 WHERE		 a.db_office_code = p_db_office_code
						AND a.primary_indep_param_code = b.parameter_code
						AND a.dep_param_code = c.parameter_code
						AND d.base_parameter_code = b.base_parameter_code
						AND e.base_parameter_code = c.base_parameter_code;
	END;

	--
	-- intended to provide a listing of an office's templates.
	--  as a pipelined function. See the cat_tr_template

	--
	FUNCTION cat_tr_templates_tab (p_db_office_id IN VARCHAR2 DEFAULT NULL)
		RETURN cat_tr_templates_t
		PIPELINED
	AS
		query_cursor		 SYS_REFCURSOR;
		output_row			 cat_tr_templates_rec_t;
		l_db_office_code	 NUMBER;
	BEGIN
		l_db_office_code := cwms_util.get_office_code (p_db_office_id);
		cat_tr_templates (query_cursor, l_db_office_code);

		LOOP
			FETCH query_cursor
			INTO output_row;

			EXIT WHEN query_cursor%NOTFOUND;
			PIPE ROW (output_row);
		END LOOP;

		CLOSE query_cursor;

		RETURN;
	END;

	FUNCTION get_tr_template_code (p_template_id 	  IN VARCHAR2,
											 p_db_office_code   IN NUMBER
											)
		RETURN NUMBER
	AS
		l_tr_template_code	NUMBER;
	BEGIN
		BEGIN
			SELECT	a.template_code
			  INTO	l_tr_template_code
			  FROM	at_tr_template_id a
			 WHERE	UPPER (a.template_id) = UPPER (p_template_id)
						AND a.db_office_code = p_db_office_code;
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				cwms_err.raise ('ITEM_DOES_NOT_EXIST',
									 'The Template named:',
									 p_template_id
									);
		END;

		RETURN l_tr_template_code;
	END;

	PROCEDURE cat_tr_template_set_masks (
		p_query_cursor 	  OUT SYS_REFCURSOR,
		p_template_id	  IN		VARCHAR2,
		p_db_office_id   IN		VARCHAR2 DEFAULT NULL
	)
	AS
		l_db_office_code		NUMBER;
		l_tr_template_code	NUMBER;
	BEGIN
		l_db_office_code := cwms_util.get_office_code (p_db_office_id);
		l_tr_template_code :=
			get_tr_template_code (p_template_id, l_db_office_code);

		OPEN p_query_cursor FOR
			SELECT	  sequence_no,
						  variable_name,
						  CASE
							  WHEN a.location_code IS NULL
							  THEN
								  NULL
							  WHEN a.location_code = 0
							  THEN
								  '{location_id}'
							  ELSE
								  (SELECT	location_id
									  FROM	av_loc
									 WHERE	unit_system = 'EN'
												AND location_code = a.location_code)
						  END
							  location_mask,
						  --
						  CASE
							  WHEN a.parameter_code IS NULL
							  THEN
								  NULL
							  WHEN a.parameter_code = 0
							  THEN
								  '{parameter_id}'
							  ELSE
								  (SELECT	base_parameter_id
									  FROM	av_parameter
									 WHERE	parameter_code = a.parameter_code)
						  END
							  base_parameter_mask,
						  --
						  CASE
							  WHEN a.parameter_code IS NULL
							  THEN
								  NULL
							  WHEN a.parameter_code = 0
							  THEN
								  NULL
							  ELSE
								  (SELECT	sub_parameter_id
									  FROM	at_parameter
									 WHERE	parameter_code = a.parameter_code)
						  END
							  sub_parameter_mask,
						  --
						  CASE
							  WHEN a.parameter_type_code IS NULL
							  THEN
								  NULL
							  WHEN a.parameter_type_code = 0
							  THEN
								  '{parameter_type_id}'
							  ELSE
								  (SELECT	parameter_type_id
									  FROM	cwms_parameter_type
									 WHERE	parameter_type_code = a.parameter_type_code)
						  END
							  parameter_type_mask,
						  --
						  CASE
							  WHEN a.interval_code IS NULL
							  THEN
								  NULL
							  WHEN a.interval_code = 0
							  THEN
								  '{interval_id}'
							  ELSE
								  (SELECT	interval_id
									  FROM	cwms_interval
									 WHERE	interval_code = a.interval_code)
						  END
							  interval_mask,
						  --
						  CASE
							  WHEN a.duration_code IS NULL
							  THEN
								  NULL
							  WHEN a.duration_code = 0
							  THEN
								  '{duration_id}'
							  ELSE
								  (SELECT	duration_id
									  FROM	cwms_duration
									 WHERE	duration_code = a.duration_code)
						  END
							  duration_mask,
						  --
						  version_mask
				 FROM   (SELECT	sequence_no, variable_name, location_code,
										parameter_code, parameter_type_code,
										interval_code, duration_code, version_mask
							  FROM	(SELECT	 sequence_no,
													 'independent_1' variable_name,
													 LAG (location_code, 1) OVER (ORDER BY sequence_no) location_code,
													 LAG (parameter_code, 1) OVER (ORDER BY sequence_no) parameter_code,
													 LAG (parameter_type_code, 1) OVER (ORDER BY sequence_no) parameter_type_code,
													 LAG (interval_code, 1) OVER (ORDER BY sequence_no) interval_code,
													 LAG (duration_code, 1) OVER (ORDER BY sequence_no) duration_code,
													 LAG (version_mask, 1) OVER (ORDER BY sequence_no) version_mask
											FROM	 at_tr_ts_mask
										  WHERE	 variable_no = 1
													 AND template_code = l_tr_template_code)
							 WHERE	sequence_no > 0
							UNION
							SELECT	sequence_no,
										CASE WHEN variable_no = 1 THEN 'dependent' ELSE 'independent_' || variable_no END variable_name,
										location_code, parameter_code,
										parameter_type_code, interval_code, duration_code,
										version_mask
							  FROM	at_tr_ts_mask
							 WHERE	sequence_no > 0
										AND template_code = l_tr_template_code) a
			ORDER BY   sequence_no, variable_name;
	END;

	FUNCTION cat_tr_template_set_masks_tab (
		p_template_id	  IN VARCHAR2,
		p_db_office_id   IN VARCHAR2 DEFAULT NULL
	)
		RETURN tr_template_set_masks_t
		PIPELINED
	AS
		query_cursor	SYS_REFCURSOR;
		output_row		tr_template_set_masks_rec_t;
	BEGIN
		cat_tr_template_set_masks (query_cursor, p_template_id, p_db_office_id);

		LOOP
			FETCH query_cursor
			INTO output_row;

			EXIT WHEN query_cursor%NOTFOUND;
			PIPE ROW (output_row);
		END LOOP;

		CLOSE query_cursor;

		RETURN;
	END;

	PROCEDURE cat_tr_template_set (
		p_query_cursor 	  OUT SYS_REFCURSOR,
		p_template_id	  IN		VARCHAR2,
		p_db_office_id   IN		VARCHAR2 DEFAULT NULL
	)
	AS
		l_db_office_code		NUMBER;
		l_tr_template_code	NUMBER;
	BEGIN
		l_db_office_code := cwms_util.get_office_code (p_db_office_id);
		l_tr_template_code :=
			get_tr_template_code (p_template_id, l_db_office_code);

		OPEN p_query_cursor FOR
			SELECT	  a.sequence_no, a.transform_id, a.description,
						  a.store_dep_flag, a.unit_system, a.lookup_agency,
						  a.lookup_rating_version, a.scaling_arg_a, a.scaling_arg_b,
						  a.scaling_arg_c
				 FROM   at_tr_template_set a
				WHERE   a.template_code = l_tr_template_code
			ORDER BY   a.sequence_no;
	END;

	FUNCTION cat_tr_template_set_tab (
		p_template_id	  IN VARCHAR2,
		p_db_office_id   IN VARCHAR2 DEFAULT NULL
	)
		RETURN tr_template_set_t
		PIPELINED
	AS
		query_cursor	SYS_REFCURSOR;
		output_row		tr_template_set_rec_t;
	BEGIN
		cat_tr_template_set (query_cursor, p_template_id, p_db_office_id);

		LOOP
			FETCH query_cursor
			INTO output_row;

			EXIT WHEN query_cursor%NOTFOUND;
			PIPE ROW (output_row);
		END LOOP;

		CLOSE query_cursor;

		RETURN;
	END;

	FUNCTION cat_tr_transforms_tab
		RETURN cat_tr_transforms_t
		PIPELINED
	AS
		query_cursor	SYS_REFCURSOR;
		output_row		cat_tr_transforms_rec_t;
	BEGIN
		OPEN query_cursor FOR
			SELECT	transform_id, description
			  FROM	cwms_tr_transformations;

		LOOP
			FETCH query_cursor
			INTO output_row;

			EXIT WHEN query_cursor%NOTFOUND;
			PIPE ROW (output_row);
		END LOOP;

		CLOSE query_cursor;
	END;

	PROCEDURE assign_tr_template (
		p_template_id			 IN VARCHAR2,
		p_cwms_ts_id			 IN VARCHAR2,
		p_active_flag			 IN VARCHAR2 DEFAULT 'T',
		p_event_trigger		 IN VARCHAR2,
		p_reassign_existing	 IN VARCHAR2 DEFAULT 'F',
		p_db_office_id 		 IN VARCHAR2 DEFAULT NULL
	)
	AS
		l_db_office_code	 NUMBER;
		l_cwms_ts_code 	 NUMBER;
		l_template_code	 NUMBER;
		l_active_flag		 VARCHAR2 (1);
		l_event_trigger	 VARCHAR2 (32);
	BEGIN
		--
		l_active_flag := cwms_util.return_t_or_f_flag (p_active_flag);
		l_db_office_code := cwms_util.get_office_code (p_db_office_id);
		l_cwms_ts_code :=
			cwms_ts.get_ts_code (p_cwms_ts_id		 => p_cwms_ts_id,
										p_db_office_code	 => l_db_office_code
									  );
		l_template_code :=
			get_tr_template_code (p_template_id, l_db_office_code);

		--
		IF cwms_util.return_true_or_false (p_reassign_existing)
		THEN
			-- do a merge
			NULL;
		ELSE
			-- do an insert
			INSERT
			  INTO	at_tr_template (ts_code_indep_1,
											 template_code,
											 active_flag,
											 event_trigger
											)
			VALUES	(
							l_cwms_ts_code,
							l_template_code,
							l_active_flag,
							l_event_trigger
						);
		END IF;
	--
	END;

	PROCEDURE unassign_tr_template (p_template_id	 IN VARCHAR2,
											  p_cwms_ts_id 	 IN VARCHAR2,
											  p_db_office_id	 IN VARCHAR2 DEFAULT NULL
											 )
	AS
	BEGIN
		NULL;
	END;

	PROCEDURE delete_tr_template (
		p_template_id					 IN VARCHAR2,
		p_delete_template_cascade	 IN VARCHAR2 DEFAULT 'F',
		p_db_office_id 				 IN VARCHAR2 DEFAULT NULL
	)
	AS
		l_template_code				 NUMBER;
		l_db_office_code				 NUMBER;
		l_delete_template_cascade	 BOOLEAN;
		l_num_assigned 				 NUMBER := 0;
	BEGIN
		l_delete_template_cascade :=
			cwms_util.return_true_or_false (p_delete_template_cascade);
		l_db_office_code := cwms_util.get_office_code (p_db_office_id);
		l_template_code :=
			get_tr_template_code (p_template_id, l_db_office_code);

		--
		-- Determine how many ts_codes have been assigned to this template...
		--
		SELECT	COUNT (*)
		  INTO	l_num_assigned
		  FROM	at_tr_template
		 WHERE	template_code = l_template_code;

		--
		--
		--
		IF NOT l_delete_template_cascade
		THEN
			NULL;
		END IF;

		DELETE FROM   at_tr_ts_mask a
				WHERE   a.template_code = l_template_code;

		DELETE FROM   at_tr_template_set a
				WHERE   a.template_code = l_template_code;

		DELETE FROM   at_tr_template_id a
				WHERE   a.template_code = l_template_code;
	END;

	PROCEDURE rename_tr_template (p_template_id		  IN VARCHAR2,
											p_template_id_new   IN VARCHAR2,
											p_db_office_id 	  IN VARCHAR2 DEFAULT NULL
										  )
	AS
	BEGIN
		NULL;
	END;

	PROCEDURE revise_tr_template_desc (
		p_template_id		IN VARCHAR2,
		description_new	IN VARCHAR2,
		p_db_office_id 	IN VARCHAR2 DEFAULT NULL
	)
	AS
	BEGIN
		NULL;
	END;

	FUNCTION create_tr_template (p_template_id		IN VARCHAR2,
										  p_description		IN VARCHAR2,
										  p_db_office_code	IN NUMBER
										 )
		RETURN NUMBER
	AS
		l_tr_template_code	NUMBER;
	BEGIN
		INSERT
			  INTO	at_tr_template_id (template_code,
												 template_id,
												 db_office_code,
												 description
												)
			VALUES	(
							cwms_seq.NEXTVAL,
							TRIM (p_template_id),
							p_db_office_code,
							p_description
						)
		RETURNING	template_code
			  INTO	l_tr_template_code;

		RETURN l_tr_template_code;
	END;

	PROCEDURE store_tr_template (
		p_template_id			  IN VARCHAR2,
		p_description			  IN VARCHAR2,
		p_primary_indep_mask   IN VARCHAR2,
		p_template_set 		  IN tr_template_set_array,
		p_replace_existing	  IN VARCHAR2 DEFAULT 'F',
		p_db_office_id 		  IN VARCHAR2 DEFAULT NULL
	)
	AS
		l_db_office_id 			VARCHAR2 (16)
											:= cwms_util.get_db_office_id (p_db_office_id);
		l_db_office_code			NUMBER
											:= cwms_util.get_db_office_code (l_db_office_id);
		l_tr_template_code		NUMBER;
		l_tr_template_exists 	BOOLEAN := FALSE;
		l_replace_existing		BOOLEAN
			:= cwms_util.return_true_or_false (p_replace_existing);
		l_base_location_id		VARCHAR2 (16);
		l_sub_location_id 		VARCHAR2 (32);
		l_base_parameter_id		VARCHAR2 (16);
		l_sub_parameter_id		VARCHAR2 (32);
		l_parameter_type_id		VARCHAR2 (16);
		l_interval_id				VARCHAR2 (16);
		l_duration_id				VARCHAR2 (16);
		l_version_id				VARCHAR2 (32);
		l_location_code			NUMBER;
		l_parameter_code			NUMBER;
		l_parameter_type_code	NUMBER;
		l_interval_code			NUMBER;
		l_duration_code			NUMBER;
		--
		l_param_primary_indep	NUMBER;
		l_param_result_dep		NUMBER;
	BEGIN
		BEGIN
			l_tr_template_code :=
				get_tr_template_code (p_template_id, l_db_office_code);
			l_tr_template_exists := TRUE;
		EXCEPTION
			WHEN OTHERS
			THEN
				l_tr_template_code :=
					create_tr_template (p_template_id,
											  p_description,
											  l_db_office_code
											 );
		END;

		IF l_tr_template_exists
		THEN
			IF NOT l_replace_existing
			THEN
				cwms_err.raise (
					'GENERIC_ERROR',
					'ERROR: Unable to store template set. The '
					|| TRIM (p_template_id)
					|| ' already exists and the p_replace_existing parameter was set to "F"'
				);
			END IF;

			--
			-- telplate exists and will be replaced, so clean-out any pre-exisiting -
			-- template entires.
			--
			DELETE FROM   at_tr_ts_mask a
					WHERE   a.template_code = l_tr_template_code;

			DELETE FROM   at_tr_template_set a
					WHERE   a.template_code = l_tr_template_code;
		END IF;

		--
		---
		---- Extract VT data & masks from the p_template_set array.
		---
		--
		FOR i IN 1 .. p_template_set.COUNT
		LOOP
			--
			--- The "i" loop extracts the VT data from the p_template_set array...
			--
			cwms_apex.aa1 ('i= ' || i);

			INSERT
			  INTO	at_tr_template_set (template_code,
												  sequence_no,
												  description,
												  store_dep_flag,
												  unit_system,
												  transform_id,
												  lookup_agency,
												  lookup_rating_version,
												  scaling_arg_a,
												  scaling_arg_b,
												  scaling_arg_c
												 )
			VALUES	(
							l_tr_template_code,
							i,
							p_template_set (i).description,
							p_template_set (i).store_dep_flag,
							p_template_set (i).unit_system,
							p_template_set (i).transform_id,
							p_template_set (i).lookup_agency,
							p_template_set (i).lookup_rating_version,
							p_template_set (i).scaling_arg_a,
							p_template_set (i).scaling_arg_b,
							p_template_set (i).scaling_arg_c
						);

			IF i = 1
			THEN
				--
				---
				---- Set the primary independent varialble
				---- The primary indep's sequence number is "1" and its
				---- variable_no is "0".
				---
				--
				cwms_ts.parse_ts (p_primary_indep_mask,
										l_base_location_id,
										l_sub_location_id,
										l_base_parameter_id,
										l_sub_parameter_id,
										l_parameter_type_id,
										l_interval_id,
										l_duration_id,
										l_version_id
									  );

				INSERT
				  INTO	at_tr_ts_mask (template_code,
												sequence_no,
												variable_no,
												location_code,
												parameter_code,
												parameter_type_code,
												interval_code,
												duration_code,
												version_mask
											  )
				VALUES	(
								l_tr_template_code,
								1,
								0,
								l_location_code,
								l_parameter_code,
								l_parameter_type_code,
								l_interval_code,
								l_duration_code,
								l_version_id
							);
			END IF;

			FOR j IN 1 .. p_template_set (i).array_of_masks.COUNT
			LOOP
				--
				--- The "j" loop extracts the ts masks from the imbedded array_of_masks...
				--
				cwms_apex.aa1 ('i= ' || i || ' j= ' || j);
				cwms_ts.parse_ts (p_template_set (i).array_of_masks (j),
										l_base_location_id,
										l_sub_location_id,
										l_base_parameter_id,
										l_sub_parameter_id,
										l_parameter_type_id,
										l_interval_id,
										l_duration_id,
										l_version_id
									  );
				cwms_apex.aa1 (
						'base param: '
					|| l_base_parameter_id
					|| ' subparam: '
					|| l_sub_parameter_id
				);

				IF UPPER (l_base_parameter_id) = '{PARAMETER}'
				THEN
					l_parameter_code := 0;
				ELSE
					l_parameter_code :=
						cwms_ts.get_parameter_code (
							p_base_parameter_id	 => l_base_parameter_id,
							p_sub_parameter_id	 => l_sub_parameter_id,
							p_office_id 			 => l_db_office_id,
							p_create 				 => 'F'
						);
				END IF;

				cwms_apex.aa1 ('param_code: ' || l_parameter_code);

				INSERT
				  INTO	at_tr_ts_mask (template_code,
												sequence_no,
												variable_no,
												location_code,
												parameter_code,
												parameter_type_code,
												interval_code,
												duration_code,
												version_mask
											  )
				VALUES	(
								l_tr_template_code,
								i,
								j,
								l_location_code,
								l_parameter_code,
								l_parameter_type_code,
								l_interval_code,
								l_duration_code,
								l_version_id
							);
			END LOOP;
		END LOOP;

		UPDATE	at_tr_template_id a
			SET	a.primary_indep_param_code = l_param_primary_indep,
					a.dep_param_code = l_param_result_dep
		 WHERE	a.template_code = l_tr_template_code;
	END;

	PROCEDURE create_tr_ts_mask (p_location_id			IN VARCHAR2,
										  p_parameter_id			IN VARCHAR2,
										  p_parameter_type_id	IN VARCHAR2,
										  p_interval_id			IN VARCHAR2,
										  p_duration_id			IN VARCHAR2,
										  p_version_id 			IN VARCHAR2
										 )
	AS
	BEGIN
		NULL;
	END;
END cwms_vt;
/
/*<TOAD_FILE_CHUNK>*/

SHOW errors;
