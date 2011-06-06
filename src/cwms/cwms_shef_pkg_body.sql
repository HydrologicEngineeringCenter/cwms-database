/* Formatted on 6/2/2011 3:37:08 PM (QP5 v5.163.1008.3004) */
CREATE OR REPLACE PACKAGE BODY cwms_shef
AS
	FUNCTION get_update_crit_file_flag (p_data_stream_id	 IN VARCHAR2,
													p_db_office_id 	 IN VARCHAR2
												  )
		RETURN VARCHAR2
	IS
		l_data_stream_code		  NUMBER
			:= get_data_stream_code (p_data_stream_id   => p_data_stream_id,
											 p_db_office_id	  => p_db_office_id
											);
		l_update_crit_file_flag   VARCHAR2 (1);
	BEGIN
		BEGIN
			SELECT	a.update_crit_file
			  INTO	l_update_crit_file_flag
			  FROM	at_data_stream_id a
			 WHERE	a.data_stream_code = l_data_stream_code;

			RETURN NVL (l_update_crit_file_flag, 'F');
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				cwms_err.raise ('DATA_STREAM_NOT_FOUND', TRIM (p_data_stream_id));
		END;
	END;

	PROCEDURE set_update_crit_file_flag (
		p_update_crit_file_flag   IN VARCHAR2,
		p_data_stream_id			  IN VARCHAR2,
		p_db_office_id 			  IN VARCHAR2
	)
	IS
		l_data_stream_code		  NUMBER
			:= get_data_stream_code (p_data_stream_id   => p_data_stream_id,
											 p_db_office_id	  => p_db_office_id
											);
		l_update_crit_file_flag   VARCHAR2 (1)
			:= cwms_util.return_t_or_f_flag (p_update_crit_file_flag);
	BEGIN
		BEGIN
			UPDATE	at_data_stream_id
				SET	update_crit_file = l_update_crit_file_flag
			 WHERE	data_stream_code = l_data_stream_code;
		EXCEPTION
			WHEN OTHERS
			THEN
				cwms_err.raise ('DATA_STREAM_NOT_FOUND', TRIM (p_data_stream_id));
		END;
	END;

	FUNCTION get_data_stream_code_of_feed (p_data_feed_code IN NUMBER)
		RETURN NUMBER
	IS
		l_data_stream_code	NUMBER;
	BEGIN
		BEGIN
			SELECT	data_stream_code
			  INTO	l_data_stream_code
			  FROM	at_data_feed_id
			 WHERE	data_feed_code = p_data_feed_code;
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				cwms_err.raise ('ERROR',
									 'Data Feed is not assigned to a Data Stream.'
									);
		END;
	END;

	--
	FUNCTION get_data_feed_code (p_data_feed_id		IN VARCHAR2,
										  p_db_office_code	IN NUMBER
										 )
		RETURN NUMBER
	IS
		l_data_feed_code	 NUMBER;
	BEGIN
		BEGIN
			SELECT	a.data_feed_code
			  INTO	l_data_feed_code
			  FROM	at_data_feed_id a
			 WHERE	UPPER (a.data_feed_id) = UPPER (TRIM (p_data_feed_id))
						AND a.db_office_code = p_db_office_code;

			RETURN l_data_feed_code;
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				cwms_err.raise (
					'ERROR',
					'Data Feed: ' || TRIM (p_data_feed_id) || ' not found.'
				);
		END;
	END;

	FUNCTION get_data_feed_code (p_data_feed_id	 IN VARCHAR2,
										  p_db_office_id	 IN VARCHAR2 DEFAULT NULL
										 )
		RETURN NUMBER
	IS
		l_db_office_code	 NUMBER
									 := cwms_util.get_db_office_code (p_db_office_id);
	BEGIN
		RETURN get_data_feed_code (p_data_feed_id 	 => p_data_feed_id,
											p_db_office_code	 => l_db_office_code
										  );
	END;

	PROCEDURE clean_at_shef_crit_file (
		p_data_stream_code	IN NUMBER,
		p_action 				IN VARCHAR2 DEFAULT NULL
	)
	IS
	BEGIN
		NULL;
	END;

	FUNCTION is_data_stream_active (
		p_data_stream_id	 IN VARCHAR2,
		p_db_office_id 	 IN VARCHAR2 DEFAULT NULL
	)
		RETURN BOOLEAN
	IS
		l_active_flag	 VARCHAR2 (1);
	BEGIN
		BEGIN
			SELECT	active_flag
			  INTO	l_active_flag
			  FROM	at_data_stream_id
			 WHERE	data_stream_code =
							cwms_shef.get_data_stream_code (p_data_stream_id,
																	  p_db_office_id
																	 );
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				RETURN FALSE;
		END;

		IF l_active_flag = 'T'
		THEN
			RETURN TRUE;
		ELSE
			RETURN FALSE;
		END IF;
	END;

	FUNCTION get_loc_category_code (p_loc_category_id	 IN VARCHAR2,
											  p_db_office_code	 IN NUMBER
											 )
		RETURN NUMBER
	IS
		l_loc_category_code	 NUMBER;
	BEGIN
		SELECT	a.loc_category_code
		  INTO	l_loc_category_code
		  FROM	at_loc_category a
		 WHERE	UPPER (a.loc_category_id) = UPPER (TRIM (p_loc_category_id))
					AND a.db_office_code IN
							 (p_db_office_code, cwms_util.db_office_code_all);

		RETURN l_loc_category_code;
	END;

	FUNCTION get_loc_group_code (p_loc_category_id	 IN VARCHAR2,
										  p_loc_group_id		 IN VARCHAR2,
										  p_db_office_code	 IN NUMBER
										 )
		RETURN NUMBER
	IS
		l_loc_category_code	 NUMBER
			:= get_loc_category_code (p_loc_category_id, p_db_office_code);
		l_loc_group_code		 NUMBER;
	BEGIN
		SELECT	a.loc_group_code
		  INTO	l_loc_group_code
		  FROM	at_loc_group a
		 WHERE	a.loc_category_code = l_loc_category_code
					AND UPPER (a.loc_group_id) = UPPER (TRIM (p_loc_group_id))
					AND a.db_office_code IN
							 (p_db_office_code, cwms_util.db_office_code_all);

		RETURN l_loc_group_code;
	END;

	FUNCTION get_data_stream_code (p_data_stream_id   IN VARCHAR2,
											 p_db_office_code   IN NUMBER
											)
		RETURN NUMBER
	IS
		l_data_stream_code	NUMBER;
	BEGIN
		BEGIN
			SELECT	a.data_stream_code
			  INTO	l_data_stream_code
			  FROM	at_data_stream_id a
			 WHERE	UPPER (a.data_stream_id) = UPPER (TRIM (p_data_stream_id))
						AND a.db_office_code = p_db_office_code;

			RETURN l_data_stream_code;
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				cwms_err.raise ('DATA_STREAM_NOT_FOUND', TRIM (p_data_stream_id));
		END;
	END;

	FUNCTION get_data_stream_code (p_data_stream_id   IN VARCHAR2,
											 p_db_office_id	  IN VARCHAR2 DEFAULT NULL
											)
		RETURN NUMBER
	IS
		l_db_office_code	 NUMBER
									 := cwms_util.get_db_office_code (p_db_office_id);
	BEGIN
		RETURN get_data_stream_code (p_data_stream_id	=> p_data_stream_id,
											  p_db_office_code	=> l_db_office_code
											 );
	END;

	FUNCTION get_shef_duration_numeric (p_shef_duration_code IN VARCHAR2)
		RETURN VARCHAR2
	IS
		l_shef_duration_code 	  VARCHAR2 (1);
		l_shef_duration_numeric   VARCHAR2 (4);
		l_tmp 						  VARCHAR2 (5)
											  := UPPER (TRIM (p_shef_duration_code));
		l_num 						  NUMBER;
	BEGIN
		IF REGEXP_INSTR (SUBSTR (l_tmp, 1, 1), '[A-Z]') = 1
		THEN
			l_shef_duration_code :=
				UPPER (SUBSTR (TRIM (p_shef_duration_code), 1, 1));

			IF l_shef_duration_code = 'V'
			THEN
				l_shef_duration_numeric :=
					SUBSTR (TRIM (p_shef_duration_code), 2, 4);

				IF LENGTH (l_shef_duration_numeric) != 4
					OR SUBSTR (l_shef_duration_numeric, 1, 1) != '5'
				THEN
					cwms_err.raise (
						'ERROR',
						l_shef_duration_numeric
						|| ' is not a valid SHEF Duration Numeric.'
					);
				END IF;
			ELSE
				BEGIN
					SELECT	a.shef_duration_numeric
					  INTO	l_shef_duration_numeric
					  FROM	cwms_shef_duration a
					 WHERE	a.shef_duration_code = l_shef_duration_code;
				EXCEPTION
					WHEN NO_DATA_FOUND
					THEN
						cwms_err.raise (
							'ERROR',
							l_shef_duration_code
							|| ' is not a valid SHEF duration code.'
						);
				END;
			END IF;
		ELSE
			l_shef_duration_numeric := l_tmp;
		END IF;

		RETURN l_shef_duration_numeric;
	END;



	PROCEDURE store_shef_spec (p_shef_spec 		 IN shef_spec_array,
										p_data_stream_id	 IN VARCHAR2,
										p_db_office_id 	 IN VARCHAR2 DEFAULT NULL
									  )
	IS
	BEGIN
		NULL;
	END;



	----------------------------------------------------
	-- This call can only be called if the office's data stream managment is
	-- set to be DATA STREAMS. An exception is thrown if it is set to DATA FEEDS
	--
	-- If the ts_id passed in is already assigend to another data stream, then
	-- an exceptin is thrown.
	--
	-- If the shef spec and ts id pair do not exist then store
	--
	--  shef spec is:
	--
	--  p_shef_loc_id
	--  p_shef_pe_code
	--  p_shef_tse_code
	--  p_shef_duration_numeric
	--
	-- CASE I
	-- If the shef spec and ts id pair already exists, then if the following
	-- ancillary parameters are the same, then nothing happens.
	--  p_shef_unit_id
	--  p_time_zone_id
	--  p_dayligh_savings
	--  p_interval_utc_offset, p_snap_forward_minutes, or p_snap_backward_minutes
	--  p_ignore_shef_spec
	--
	--  if any one of the ancillary parameters are different, then an exception
	--  is thrown unless p_update_allowed is set to TRUE.
	--
	-- CASE II
	-- CHANGING a shef spec's ts_id assignement...
	-- If the ts_id already exists in this data stream and the
	-- shef spec is unique to this data stream,then the store occurs
	--
	-- If the ts_id already exists and the shef spec is already assigned to another
	-- ts_id in this data stream an exception is thrown - unless the p_update_allowed
	-- flag is set to TRUE. If set to TRUE, then the update occurs and the pre-existing
	-- ts_id will be orphaned.
	--
	-- CHANGING a ts_id's shef spec assignement...
	-- If the shef spec already exists and the ts_id is new to this data stream,
	-- the the store occurs.

	-- If the shef spec already exists and the ts_id is  already assigned to another
	-- shef spec in this data stream then an exception is thrown -
	-- unless the p_update_allowed is set to TRUE. If set to TRUE, then the update
	-- occurs and the pre-existing shef spec is removed orphaning the removed ts_id..
	--



	PROCEDURE store_shef_spec (
		p_cwms_ts_id				  IN VARCHAR2,
		p_data_stream_id			  IN VARCHAR2 DEFAULT NULL,
		p_data_feed_id 			  IN VARCHAR2 DEFAULT NULL,
		p_loc_group_id 			  IN VARCHAR2 DEFAULT 'SHEF Location Id',
		p_shef_loc_id				  IN VARCHAR2 DEFAULT NULL,
		-- normally use loc_group_id
		p_shef_pe_code 			  IN VARCHAR2,
		p_shef_tse_code			  IN VARCHAR2,
		p_shef_duration_code 	  IN VARCHAR2,
		-- e.g., V5002 or simply L   -
		p_shef_unit_id 			  IN VARCHAR2,
		p_time_zone_id 			  IN VARCHAR2,
		p_daylight_savings		  IN VARCHAR2 DEFAULT 'F',
		p_interval_utc_offset	  IN NUMBER DEFAULT NULL,			 -- in minutes.
		p_snap_forward_minutes	  IN NUMBER DEFAULT NULL,
		p_snap_backward_minutes   IN NUMBER DEFAULT NULL,
		p_ts_active_flag			  IN VARCHAR2 DEFAULT 'T',
		p_ignore_shef_spec		  IN VARCHAR2 DEFAULT 'F',
		p_update_allowed			  IN VARCHAR2 DEFAULT 'T',
		p_db_office_id 			  IN VARCHAR2 DEFAULT NULL
	)
	IS
		l_dl_time						  VARCHAR2 (1)
			:= cwms_util.return_t_or_f_flag (NVL (p_daylight_savings, 'F'));
		l_ts_active_flag				  VARCHAR2 (1)
			:= cwms_util.return_t_or_f_flag (NVL (p_ts_active_flag, 'T'));
		l_ignore_shef_spec			  VARCHAR2 (1)
			:= cwms_util.return_t_or_f_flag (NVL (p_ignore_shef_spec, 'F'));
		l_update_allowed				  BOOLEAN
			:= cwms_util.return_true_or_false (
					cwms_util.return_t_or_f_flag (NVL (p_update_allowed, 'T'))
				);
		l_db_office_id 				  VARCHAR2 (16)
												  := cwms_util.get_db_office_id (p_db_office_id);
		l_db_office_code				  NUMBER
			:= cwms_util.get_db_office_code (l_db_office_id);
		l_data_stream_mgt_style 	  VARCHAR2 (32)
			:= get_data_stream_mgt_style (l_db_office_id);
		l_loc_group_id 				  at_loc_group.loc_group_id%TYPE
			:= NVL (TRIM (p_loc_group_id), 'SHEF Location Id');
		--
		l_data_stream_mgt_param 	  VARCHAR2 (20);
		l_ts_code						  NUMBER;
		l_ts_code_set_to				  NUMBER;
		l_ts_code_where				  NUMBER;
		--
		l_data_stream_code			  NUMBER;
		l_data_feed_code				  NUMBER := 0;

		l_spec_exists					  BOOLEAN;
		l_shef_pe_code 				  VARCHAR2 (2) := UPPER (p_shef_pe_code);
		l_shef_tse_code				  VARCHAR2 (3) := UPPER (p_shef_tse_code);
		l_shef_duration_code 		  VARCHAR2 (1);
		l_shef_duration_numeric 	  VARCHAR2 (4);
		l_shef_unit_code				  NUMBER;
		l_shef_time_zone_code		  NUMBER;
		l_shef_spec 					  VARCHAR2 (32) := NULL;
		l_shef_spec_existing 		  VARCHAR2 (32) := NULL;
		l_time_zone_id 				  VARCHAR2 (16) := NVL (p_time_zone_id, 'UTC');
		l_shef_loc_id					  at_loc_group_assignment.loc_alias_id%TYPE
												  := TRIM (p_shef_loc_id);
		l_shef_id						  VARCHAR2 (8) := NULL;
		l_location_code				  NUMBER;
		l_location_id					  VARCHAR2 (49);
		l_loc_group_code				  NUMBER;
		l_tmp 							  NUMBER;
		l_max_len_shef_loc_id		  NUMBER;
		l_existing_ts_id_spec		  at_shef_decode%ROWTYPE;
		l_existing_shef_spec 		  at_shef_decode%ROWTYPE;
		l_at_shef_ignore				  at_shef_ignore%ROWTYPE;
		--
		l_ts_id_exists 				  BOOLEAN := TRUE;
		l_shef_spec_exists			  BOOLEAN := TRUE;
		l_shef_spec_ignored_exists   BOOLEAN := FALSE;
		l_data_stream_id2 			  at_data_stream_id.data_stream_id%TYPE;
		l_data_feed_id2				  at_data_feed_id.data_feed_id%TYPE;
		l_db_office_code2 			  NUMBER;
		l_db_office_id2				  cwms_office.office_id%TYPE;

		--
		--
		FUNCTION do_ancillary_params_match (
			p_shef_spec 				  IN at_shef_decode%ROWTYPE,
			p_shef_unit_code			  IN NUMBER,
			p_shef_time_zone_code	  IN NUMBER,
			p_dl_time					  IN VARCHAR2,
			p_interval_utc_offset	  IN NUMBER,
			p_snap_forward_minutes	  IN NUMBER,
			p_snap_backward_minutes   IN NUMBER,
			p_ignore_shef_spec		  IN VARCHAR2,
			p_ts_active_flag			  IN VARCHAR2
		)
			RETURN BOOLEAN
		IS
			l_interval_utc_offset	  NUMBER;
			l_snap_forward_minutes	  NUMBER;
			l_snap_backward_minutes   NUMBER;
			l_ts_active_flag			  VARCHAR2 (1);
		BEGIN
			SELECT	interval_utc_offset, NVL (interval_forward, -99),
						NVL (interval_backward, -99), active_flag
			  INTO	l_interval_utc_offset, l_snap_forward_minutes,
						l_snap_backward_minutes, l_ts_active_flag
			  FROM	at_cwms_ts_spec
			 WHERE	ts_code = p_shef_spec.ts_code;


			IF p_shef_spec.ignore_shef_spec =
					cwms_util.return_t_or_f_flag (p_ignore_shef_spec)
				AND p_shef_spec.shef_time_zone_code = p_shef_time_zone_code
				AND p_shef_spec.shef_unit_code = p_shef_unit_code
				AND p_shef_spec.dl_time = p_dl_time
				AND l_ts_active_flag = p_ts_active_flag
				AND NVL (p_snap_backward_minutes, -99) = l_snap_backward_minutes
				AND NVL (p_snap_forward_minutes, -99) = l_snap_forward_minutes
			THEN
				IF (p_interval_utc_offset = l_interval_utc_offset)
					OR (p_interval_utc_offset IS NULL
						 AND (l_interval_utc_offset =
									cwms_util.utc_offset_irregular
								OR l_interval_utc_offset =
										cwms_util.utc_offset_undefined))
				THEN
					RETURN TRUE;
				END IF;
			END IF;

			RETURN FALSE;
		END;
	--
	--
	BEGIN
		--
		cwms_apex.aa1 ('in store_shef_spec.');

		IF l_data_stream_mgt_style = data_stream_mgt_style
		THEN
			l_data_stream_mgt_param := 'p_data_stream_id';
			l_max_len_shef_loc_id := 8;
		ELSE
			l_data_stream_mgt_param := 'p_data_feed_id';
			l_max_len_shef_loc_id := 6;
		END IF;

		--======
		--====
		--==
		-- Determine if we're working with a DATA STREAM or a DATA FEED...
		--==
		--====
		--======
		IF p_data_stream_id IS NULL AND p_data_feed_id IS NULL
		THEN
			cwms_err.raise (
				'ERROR',
				'Both the p_data_stream_id and the p_data_feed_id are NULL. Your Data Stream Mgt Sytle is set to: '
				|| l_data_stream_mgt_style
				|| '. This means you need to define a '
				|| l_data_stream_mgt_param
				|| ' parameter.'
			);
		ELSIF p_data_stream_id IS NOT NULL AND p_data_feed_id IS NOT NULL
		THEN
			cwms_err.raise (
				'ERROR',
				'Both the p_data_stream_id and the p_data_feed_id have been defined. Since your using the '
				|| l_data_stream_mgt_style
				|| ' you need to only define the '
				|| l_data_stream_mgt_param
				|| '.'
			);
		END IF;

		IF p_data_feed_id IS NOT NULL
		THEN
			IF l_data_stream_mgt_style = data_feed_mgt_style
			THEN
				l_data_feed_code :=
					get_data_feed_code (p_data_feed_id, l_db_office_code);

				BEGIN
					l_data_stream_code :=
						get_data_stream_code_of_feed (l_data_feed_code);
				EXCEPTION
					WHEN OTHERS
					THEN
						l_data_stream_code := NULL;
				END;
			ELSE
				cwms_err.raise (
					'ERROR',
					'Unable to set the SHEF Spec. You defined a p_data_feed_id, namely: '
					|| p_data_feed_id
					|| '. However, your CWMS Database is set to use the '
					|| data_stream_mgt_style
					|| ' Mgt Style. This means you need to define a Data Stream using p_data_stream_id.'
				);
			END IF;
		ELSE
			IF l_data_stream_mgt_style = data_stream_mgt_style
			THEN
				l_data_stream_code :=
					get_data_stream_code (p_data_stream_id, l_db_office_code);
				l_data_feed_code := NULL;
			ELSE
				cwms_err.raise (
					'ERROR',
					'Unable to set the SHEF Spec. You defined a p_data_stream_id, namely: '
					|| p_data_stream_id
					|| '. However, your system is set to use the '
					|| data_feed_mgt_style
					|| ' Mgt Style. This means you need to define a Data Feed using p_data_feed_id.'
				);
			END IF;
		END IF;

		IF p_cwms_ts_id IS NULL
		THEN
			l_ts_code := NULL;

			IF p_shef_loc_id IS NULL
			THEN
				cwms_err.raise (
					'ERROR',
					'Unable to set this SHEF Spec to be ignored because a p_shef_loc_id was not defined.'
				);
			ELSE
				l_shef_id := TRIM (p_shef_loc_id);
			END IF;
		ELSE
			--======
			--====
			--==
			-- Determine the l_ts_code
			--==
			--====
			--======
			BEGIN
				l_ts_code :=
					cwms_ts.get_ts_code (p_cwms_ts_id		 => p_cwms_ts_id,
												p_db_office_code	 => l_db_office_code
											  );
			EXCEPTION
				WHEN OTHERS
				THEN
					cwms_ts.create_ts_code (p_ts_code				 => l_ts_code,
													p_cwms_ts_id			 => p_cwms_ts_id,
													p_utc_offset			 => NULL,
													p_interval_forward	 => NULL,
													p_interval_backward	 => NULL,
													p_versioned 			 => 'F',
													p_active_flag			 => 'T',
													p_fail_if_exists		 => 'T',
													p_office_id 			 => l_db_office_id
												  );
			END;

			--======
			--====
			--==
			-- Retrieve previous SHEF Spec assignment for this ts_id (should one exist)...
			--==
			--====
			--======
			BEGIN
				SELECT	*
				  INTO	l_existing_ts_id_spec
				  FROM	at_shef_decode
				 WHERE	ts_code = l_ts_code;
			EXCEPTION
				WHEN NO_DATA_FOUND
				THEN
					l_ts_id_exists := FALSE;
			END;

			--======
			--====
			--==
			-- If a SHEF Spec assignment for this TS ID does exist, then confirm
			-- that it exists for the defined p_DATA_STREAM_id or p_DATA_FEED_id.
			-- If it's not, then throw an exception..
			--==
			--====
			--======
			IF l_ts_id_exists
			THEN
				IF l_data_feed_code IS NOT NULL
				THEN
					--
					-- It's a DATA FEED...
					--
					IF l_existing_ts_id_spec.data_feed_code != l_data_feed_code
					THEN
						SELECT	data_feed_id, db_office_code
						  INTO	l_data_feed_id2, l_db_office_code2
						  FROM	at_data_feed_id
						 WHERE	data_feed_code =
										l_existing_ts_id_spec.data_feed_code;

						SELECT	office_id
						  INTO	l_db_office_id2
						  FROM	cwms_office
						 WHERE	office_code = l_db_office_code2;

						cwms_err.raise (
							'ERROR',
								'Unable to set SHEF Spec for TS ID: '
							|| p_cwms_ts_id
							|| ' because it is already assigned in the '
							|| l_db_office_id2
							|| ':'
							|| l_data_feed_id2
							|| ' Data FEED and you are trying to assign SHEF Specs for the '
							|| TRIM (p_data_feed_id)
						);
					END IF;
				ELSE
					--
					-- It's a DATA STREAM...
					--
					IF l_existing_ts_id_spec.data_stream_code !=
							l_data_stream_code
					THEN
						SELECT	data_stream_id, db_office_code
						  INTO	l_data_stream_id2, l_db_office_code2
						  FROM	at_data_stream_id
						 WHERE	data_stream_code =
										l_existing_ts_id_spec.data_stream_code;

						SELECT	office_id
						  INTO	l_db_office_id2
						  FROM	cwms_office
						 WHERE	office_code = l_db_office_code2;

						cwms_err.raise (
							'ERROR',
								'Unable to set SHEF Spec for ts_id: '
							|| p_cwms_ts_id
							|| ' because it is already assigned in the '
							|| l_db_office_id2
							|| ':'
							|| l_data_stream_id2
							|| ' Data STREAM and you are trying to assign SHEF Specs for the '
							|| TRIM (p_data_stream_id)
						);
					END IF;
				END IF;
			END IF;

			--======
			--====
			--==
			--
			--==
			--====
			--======
			l_loc_group_code :=
				get_loc_group_code ('Agency Aliases',
										  l_loc_group_id,
										  l_db_office_code
										 );

			SELECT	a.location_code
			  INTO	l_location_code
			  FROM	at_cwms_ts_spec a
			 WHERE	a.ts_code = l_ts_code;

			cwms_apex.aa1 (
				'store_shef_spec - location code: ' || l_location_code
			);

			--======
			--====
			--==
			-- Confirm that an alias exists for the loc group code and/or matches -
			-- the shef_loc_id passed in...
			--==
			--====
			--======
			BEGIN
				SELECT	a.loc_alias_id
				  INTO	l_shef_id
				  FROM	at_loc_group_assignment a
				 WHERE	a.loc_group_code = l_loc_group_code
							AND a.location_code = l_location_code;
			EXCEPTION
				WHEN NO_DATA_FOUND
				THEN
					--======
					--====
					--==
					-- if a loc_group assignment for this location/group has not already-
					-- been made, then try and make the assignment.
					--==
					--====
					--======
					l_shef_id := NULL;

					--
					IF l_shef_loc_id IS NOT NULL
					THEN
						INSERT
						  INTO	at_loc_group_assignment (location_code,
																	 loc_group_code,
																	 loc_alias_id
																	)
						VALUES	(l_location_code, l_loc_group_code, l_shef_loc_id);
					ELSE
						cwms_err.raise (
							'ERROR',
								'Unable to find a SHEF Location Id for this TS ID: '
							|| p_cwms_ts_id
							|| ' and this Location Group: '
							|| l_loc_group_id
						);
					END IF;
			END;

			IF l_shef_id IS NULL AND l_shef_loc_id IS NULL
			THEN
				cwms_err.raise (
					'ERROR',
					'Unable to set SHEF Spec. A p_shef_loc_id was not defined and a SHEF Location Id/Alias was not found for the '
					|| l_loc_group_id
					|| ' Location Group for this TS ID: '
					|| p_cwms_ts_id
				);
			END IF;

			--======
			--====
			--==
			-- At this point l_shef_id will contain a previous defined SHEF Location
			-- or be NULL if non-was found. l_shef_loc_id will contain the
			-- SHEF Location defined in this call. So at this POINT
			--
			-- 1) if l_shef_id and l_shef_loc_id are not the same, then the
			--  user is trying to change the Allias from l_shef_id to a new
			--  allias l_shef_loc_id - the update_allowed flag needs to be set
			--  in order for this to be allowed.
			--
			-- 2) if both l_shef_id and l_shef_loc_id are the same, then no
			--  changes are being made and we'll use l_shef_id.
			--
			-- 3) if l_shef_id is null from above, then use l_shef_loc_id as
			--  the SHEF Location id
			--==
			--====
			--======
			IF l_shef_id IS NOT NULL AND l_shef_loc_id IS NOT NULL
			THEN
				IF UPPER (l_shef_id) != UPPER (l_shef_loc_id)
				THEN
					--======
					--====
					--==
					-- Change the shef location alias to the newly defined one.
					--==
					--====
					--======
					SELECT	location_id
					  INTO	l_location_id
					  FROM	zav_cwms_ts_id
					 WHERE	ts_code = l_ts_code;


					IF l_update_allowed
					THEN
						cwms_loc.assign_loc_group (
							p_loc_category_id   => 'Agency Aliases',
							p_loc_group_id 	  => l_loc_group_id,
							p_location_id		  => l_location_id,
							p_loc_alias_id 	  => l_shef_loc_id,
							p_db_office_id 	  => l_db_office_id
						);
						l_shef_id := l_shef_loc_id;
					ELSE
						cwms_err.raise (
							'ERROR',
								'The provided SHEF Loc Id: '
							|| l_shef_loc_id
							|| ' does not match the existing SHEF Loc Id: '
							|| l_shef_id
							|| ' set for the "Agency Aliases" Location Group: '
							|| l_loc_group_id
							|| ' and Location ID: '
							|| l_location_id
						);
					END IF;
				END IF;
			ELSIF l_shef_id IS NULL
			THEN
				l_shef_id := l_shef_loc_id;
			END IF;
		END IF;

		l_tmp := NVL (LENGTH (TRIM (l_shef_id)), 0);

		IF l_tmp > l_max_len_shef_loc_id
		THEN
			cwms_err.raise (
				'ERROR',
					'Unable to set SHEF Spec - the SHEF Location id: '
				|| l_shef_id
				|| ' can only be '
				|| l_max_len_shef_loc_id
				|| ' characters in length for '
				|| l_data_stream_mgt_style
				|| '.'
			);
		END IF;

		--
		l_shef_duration_numeric :=
			get_shef_duration_numeric (p_shef_duration_code);

		BEGIN
			SELECT	shef_duration_code
			  INTO	l_shef_duration_code
			  FROM	cwms_shef_duration
			 WHERE	shef_duration_numeric = l_shef_duration_numeric;
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				l_shef_duration_code := 'V';
		END;

		cwms_apex.aa1 (
				'in store_shef_spec - duration: .'
			|| l_shef_duration_numeric
			|| ' - '
			|| l_shef_duration_code
		);

		SELECT	a.unit_code
		  INTO	l_shef_unit_code
		  FROM	cwms_unit a
		 WHERE	a.unit_id = p_shef_unit_id;

		cwms_apex.aa1 (
			'store_shef_spec - shef_unit_coded: ' || l_shef_unit_code
		);

		SELECT	shef_time_zone_code
		  INTO	l_shef_time_zone_code
		  FROM	cwms_shef_time_zone a
		 WHERE	UPPER (a.shef_time_zone_id) = UPPER (l_time_zone_id);

		--===
		--======
		--========
		--
		-- retrieve previous shef_spec for this ts_id (if one exists)
		--

		l_shef_spec :=
				l_shef_id
			|| '.'
			|| l_shef_pe_code
			|| '.'
			|| l_shef_tse_code
			|| '.'
			|| l_shef_duration_numeric;

		IF l_ts_id_exists
		THEN
			l_shef_spec_existing :=
					l_existing_ts_id_spec.shef_loc_id
				|| '.'
				|| l_existing_ts_id_spec.shef_pe_code
				|| '.'
				|| l_existing_ts_id_spec.shef_tse_code
				|| '.'
				|| l_existing_ts_id_spec.shef_duration_numeric;
		END IF;

		BEGIN
			SELECT	*
			  INTO	l_existing_shef_spec
			  FROM	at_shef_decode
			 WHERE		 NVL (data_stream_code, 0) = NVL (l_data_stream_code, 0)
						AND NVL (data_feed_code, 0) = NVL (l_data_feed_code, 0)
						AND shef_loc_id = l_shef_loc_id
						AND shef_pe_code = l_shef_pe_code
						AND shef_tse_code = l_shef_tse_code
						AND shef_duration_numeric = l_shef_duration_numeric;
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				l_shef_spec_exists := FALSE;


				BEGIN
					-- check if SHEF Spec is in at_shef_ignore
					SELECT	*
					  INTO	l_at_shef_ignore
					  FROM	at_shef_ignore
					 WHERE	NVL (data_stream_code, 0) =
									NVL (l_data_stream_code, 0)
								AND NVL (data_feed_code, 0) =
										 NVL (l_data_feed_code, 0)
								AND shef_loc_id = l_shef_loc_id
								AND shef_pe_code = l_shef_pe_code
								AND shef_tse_code = l_shef_tse_code
								AND shef_duration_numeric = l_shef_duration_numeric;
				EXCEPTION
					WHEN NO_DATA_FOUND
					THEN
						l_shef_spec_ignored_exists := TRUE;
				END;
		END;

		IF l_ts_code IS NULL
		THEN
			IF l_shef_spec_ignored_exists
			THEN
				-- Do nothing - SHEF Spec is already ignored
				RETURN;
			ELSIF l_shef_spec_exists
			THEN
				IF l_update_allowed
				THEN
					DELETE FROM   at_shef_decode
							WHERE   ts_code = l_existing_shef_spec.ts_code;

					INSERT
					  INTO	at_shef_ignore (data_stream_code,
													 data_feed_code,
													 shef_loc_id,
													 shef_pe_code,
													 shef_tse_code,
													 shef_duration_numeric
													)
					VALUES	(
									l_data_stream_code,
									l_data_feed_code,
									l_shef_id,
									l_shef_pe_code,
									l_shef_tse_code,
									l_shef_duration_numeric
								);

					RETURN;
				ELSE
					cwms_err.raise (
						'ERROR',
							'Unable to set SHEF Spec: '
						|| l_shef_spec
						|| ' to be ignored because p_update_allowed is FALSE.'
					);
				END IF;
			END IF;
		ELSIF NOT l_shef_spec_exists AND NOT l_ts_id_exists
		THEN
			cwms_apex.aa1 (
					'store_shef_spec - CASE 1: '
				|| l_shef_spec
				|| ':'
				|| p_cwms_ts_id
			);
			--
			-- CASE 1 - Perform the INSERT of the new SHEF Spec...
			--
			cwms_ts.update_ts_id (
				p_ts_code					  => l_ts_code,
				p_interval_utc_offset	  => p_interval_utc_offset,
				-- in minutes.
				p_snap_forward_minutes	  => p_snap_forward_minutes,
				p_snap_backward_minutes   => p_snap_backward_minutes,
				--  p_local_reg_time_zone_id => NULL,
				p_ts_active_flag			  => l_ts_active_flag
			);



			--
			--
			BEGIN
				cwms_apex.aa1 (
					'store_shef_spec - trying to insert into at_shef_decode'
				);

				INSERT
				  INTO	at_shef_decode (ts_code,
												 data_stream_code,
												 data_feed_code,
												 shef_loc_id,
												 shef_pe_code,
												 shef_tse_code,
												 shef_duration_numeric,
												 shef_unit_code,
												 shef_time_zone_code,
												 dl_time,
												 location_code,
												 loc_group_code,
												 shef_duration_code,
												 ignore_shef_spec
												)
				VALUES	(
								l_ts_code,
								l_data_stream_code,
								l_data_feed_code,
								l_shef_id,
								l_shef_pe_code,
								l_shef_tse_code,
								l_shef_duration_numeric,
								l_shef_unit_code,
								l_shef_time_zone_code,
								l_dl_time,
								l_location_code,
								l_loc_group_code,
								l_shef_duration_code,
								l_ignore_shef_spec
							);

				------
				--=======
				RETURN;
			--=======
			------
			EXCEPTION
				WHEN OTHERS
				THEN
					cwms_err.raise (
						'ERROR',
						'Unexpected INSERT ERROR - for the following new SHEF Spec and new TS_ID Pair: '
						|| l_shef_spec
						|| '='
						|| p_cwms_ts_id
					);
			END;
		END IF;

		--
		-- Check if this shef spec matches the l_existing_ts_id_spec's
		-- shef spec
		IF l_ts_id_exists
		THEN
			IF (l_existing_ts_id_spec.data_stream_code
				 || UPPER (l_shef_spec_existing)) =
					(l_data_stream_code || UPPER (l_shef_spec))
			THEN
				-- CASE 2
				-- CASE 2 - the SHEF Spec and ts_id pair already exists...
				-- CASE 2
				cwms_apex.aa1 (
						'store_shef_spec - CASE 2: '
					|| l_shef_spec
					|| ':'
					|| p_cwms_ts_id
				);

				IF do_ancillary_params_match (
						p_shef_spec 				  => l_existing_ts_id_spec,
						p_shef_unit_code			  => l_shef_unit_code,
						p_shef_time_zone_code	  => l_shef_time_zone_code,
						p_dl_time					  => l_dl_time,
						p_interval_utc_offset	  => p_interval_utc_offset,
						p_snap_forward_minutes	  => p_snap_forward_minutes,
						p_snap_backward_minutes   => p_snap_backward_minutes,
						p_ignore_shef_spec		  => l_ignore_shef_spec,
						p_ts_active_flag			  => l_ts_active_flag
					)
				THEN
					cwms_apex.aa1 (
						'store_shef_spec - CASE 2 everything matches so just return: '
						|| l_shef_spec
						|| ':'
						|| p_cwms_ts_id
					);

					-- Everything matches - so there's nothing to do!
					------
					--=======
					RETURN;
				--=======
				------
				ELSIF l_update_allowed
				THEN
					cwms_apex.aa1 (
							'store_shef_spec - CASE 2 updated allowed: '
						|| l_shef_spec
						|| ':'
						|| p_cwms_ts_id
					);

					l_ts_code_set_to := l_ts_code;
					l_ts_code_where := l_ts_code;
				ELSE
					cwms_err.raise (
						'ERROR',
						'Unable to update the Ancillary Parameters for the following SHEF Spec and TS_ID Pair because p_update_allowed set to FALSE: '
						|| l_shef_spec
						|| '='
						|| p_cwms_ts_id
					);
				END IF;
			ELSIF l_update_allowed
			THEN
				-- CASE 3
				-- CASE 3: SHEF Spec is new, ts_id is already assigned
				-- CASE 3 Will reassign the ts_id to the new SHEF Spec
				cwms_apex.aa1 (
						'store_shef_spec - CASE 3 update allowed: '
					|| l_shef_spec
					|| ':'
					|| p_cwms_ts_id
				);

				l_ts_code_set_to := l_ts_code;
				l_ts_code_where := l_ts_code;
			ELSE
				cwms_err.raise (
					'ERROR',
					'Unable to assign new SHEF Spec: ' || l_shef_spec
					|| ' because p_update_allowed is FALSE. The following SHEF Spec=TS ID assignment already exists: '
					|| l_shef_spec_existing
					|| '='
					|| p_cwms_ts_id
				);
			END IF;
		ELSIF l_update_allowed
		THEN
			-- CASE 4
			-- CASE 4: ts_id is new, but the SHEF Spec is already assigned to a different ts_id
			-- CASE 4
			cwms_apex.aa1 (
					'store_shef_spec - CASE 4: '
				|| l_shef_spec
				|| ':'
				|| p_cwms_ts_id
			);

			l_ts_code_set_to := l_ts_code;
			l_ts_code_where := l_existing_shef_spec.ts_code;
		ELSE
			cwms_err.raise (
				'ERROR',
				'Unable to reassign the SHEF Spec to the new TS ID because p_update_allowed is set to FALSE: '
				|| l_shef_spec
				|| '='
				|| p_cwms_ts_id
			);
		END IF;

		--==========================================================================
		--==========================================================================

		cwms_ts.update_ts_id (
			p_ts_code					  => l_ts_code,
			p_interval_utc_offset	  => p_interval_utc_offset,
			-- in minutes.
			p_snap_forward_minutes	  => p_snap_forward_minutes,
			p_snap_backward_minutes   => p_snap_backward_minutes,
			--   p_local_reg_time_zone_id => NULL,
			p_ts_active_flag			  => l_ts_active_flag
		);



		cwms_apex.aa1 ('store_shef_spec - trying to insert into at_shef_decode'
						  );
		cwms_apex.aa1 (
				'store_shef_spec - Acutally Updating: '
			|| l_shef_spec
			|| ':'
			|| p_cwms_ts_id
		);

		UPDATE	at_shef_decode
			SET	ts_code = l_ts_code_set_to,
					data_stream_code = l_data_stream_code,
					shef_loc_id = l_shef_id,
					shef_pe_code = l_shef_pe_code,
					shef_tse_code = l_shef_tse_code,
					shef_duration_numeric = l_shef_duration_numeric,
					shef_unit_code = l_shef_unit_code,
					shef_time_zone_code = l_shef_time_zone_code,
					dl_time = l_dl_time,
					location_code = l_location_code,
					loc_group_code = l_loc_group_code,
					shef_duration_code = l_shef_duration_code,
					data_feed_code = l_data_feed_code,
					ignore_shef_spec = l_ignore_shef_spec
		 WHERE	ts_code = l_ts_code_where;
	END;

	PROCEDURE store_shef_spec_feed (
		p_cwms_ts_id				  IN VARCHAR2,
		p_data_feed_id 			  IN VARCHAR2,
		p_loc_group_id 			  IN VARCHAR2,
		p_shef_loc_id				  IN VARCHAR2 DEFAULT NULL,
		-- normally use loc_group_id
		p_shef_pe_code 			  IN VARCHAR2,
		p_shef_tse_code			  IN VARCHAR2,
		p_shef_duration_code 	  IN VARCHAR2,
		-- e.g., V5002 or simply L   -
		p_shef_unit_id 			  IN VARCHAR2,
		p_time_zone_id 			  IN VARCHAR2,
		p_daylight_savings		  IN VARCHAR2 DEFAULT 'F',    -- psuedo boolean.
		p_interval_utc_offset	  IN NUMBER DEFAULT NULL,			 -- in minutes.
		p_snap_forward_minutes	  IN NUMBER DEFAULT NULL,
		p_snap_backward_minutes   IN NUMBER DEFAULT NULL,
		p_ts_active_flag			  IN VARCHAR2 DEFAULT 'T',
		p_update_allowed			  IN VARCHAR2 DEFAULT 'T',
		p_db_office_id 			  IN VARCHAR2 DEFAULT NULL
	)
	IS
		p_data_stream_id			  VARCHAR2 (16);

		l_db_office_id 			  VARCHAR2 (16)
											  := cwms_util.get_db_office_id (p_db_office_id);
		l_db_office_code			  NUMBER
											  := cwms_util.get_db_office_code (l_db_office_id);
		l_ts_code					  NUMBER;
		--
		l_data_stream_code		  NUMBER;
		l_data_feed_code			  NUMBER;
		l_spec_exists				  BOOLEAN;
		l_shef_pe_code 			  VARCHAR2 (2) := UPPER (p_shef_pe_code);
		l_shef_tse_code			  VARCHAR2 (3) := UPPER (p_shef_tse_code);
		l_shef_duration_code 	  VARCHAR2 (1);
		l_shef_duration_numeric   VARCHAR2 (4);
		l_shef_unit_code			  NUMBER;
		l_shef_time_zone_code	  NUMBER;
		l_time_zone_id 			  VARCHAR2 (16) := NVL (p_time_zone_id, 'UTC');
		l_dl_time					  VARCHAR2 (1)
											  := UPPER (NVL (p_daylight_savings, 'F'));
		l_ts_active_flag			  VARCHAR2 (1)
											  := UPPER (NVL (p_ts_active_flag, 'T'));
		l_shef_loc_id				  VARCHAR2 (8) := UPPER (TRIM (p_shef_loc_id));
		l_shef_id					  VARCHAR2 (8) := NULL;
		l_location_code			  NUMBER;
		l_loc_group_code			  NUMBER;
		l_tmp 						  NUMBER;
	BEGIN
		cwms_apex.aa1 ('in store_shef_spec_feed.');

		--
		IF l_dl_time NOT IN ('T', 'F')
		THEN
			cwms_err.raise ('INVALID_T_F_FLAG', 'p_daylight_savings');
		END IF;

		--
		-- get the ts_code -
		BEGIN
			l_ts_code :=
				cwms_ts.get_ts_code (p_cwms_ts_id		 => p_cwms_ts_id,
											p_db_office_code	 => l_db_office_code
										  );
		EXCEPTION
			WHEN OTHERS
			THEN
				cwms_ts.create_ts_code (p_ts_code				 => l_ts_code,
												p_cwms_ts_id			 => p_cwms_ts_id,
												p_utc_offset			 => NULL,
												p_interval_forward	 => NULL,
												p_interval_backward	 => NULL,
												p_versioned 			 => 'F',
												p_active_flag			 => 'T',
												p_fail_if_exists		 => 'T',
												p_office_id 			 => l_db_office_id
											  );
		END;

		cwms_apex.aa1 ('store_shef_spec_feed - ts_code: ' || l_ts_code);

		l_data_feed_code :=
			get_data_feed_code (p_data_feed_id		=> p_data_feed_id,
									  p_db_office_code	=> l_db_office_code
									 );

		BEGIN
			l_data_stream_code := get_data_stream_code_of_feed (l_data_feed_code);
		EXCEPTION
			WHEN OTHERS
			THEN
				l_data_stream_code := NULL;
		END;

		l_loc_group_code :=
			get_loc_group_code ('Agency Aliases',
									  p_loc_group_id,
									  l_db_office_code
									 );

		SELECT	a.location_code
		  INTO	l_location_code
		  FROM	at_cwms_ts_spec a
		 WHERE	a.ts_code = l_ts_code;

		cwms_apex.aa1 (
			'store_shef_spec_feed - location code: ' || l_location_code
		);

		--
		-- confirm that an alias exists for the loc group code and/or matches  -
		-- the shef_loc_id passed in...
		---
		BEGIN
			SELECT	a.loc_alias_id
			  INTO	l_shef_id
			  FROM	at_loc_group_assignment a
			 WHERE	a.loc_group_code = l_loc_group_code
						AND a.location_code = l_location_code;
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				-- if a loc_group assignment for this location/group has not already-
				-- been made, then try and make the assignment.
				l_shef_id := NULL;

				--
				IF l_shef_loc_id IS NOT NULL
				THEN
					INSERT
					  INTO	at_loc_group_assignment (location_code,
																 loc_group_code,
																 loc_alias_id
																)
					VALUES	(l_location_code, l_loc_group_code, l_shef_loc_id);
				ELSE
					cwms_err.raise (
						'ERROR',
						'Unable to find a SHEF Location Id for this CWMS_TS_ID: '
						|| p_cwms_ts_id
						|| ' and this Location Group: '
						|| p_loc_group_id
					);
				END IF;
		END;

		cwms_apex.aa1 (
				'store_shef_spec_feed - shef id: '
			|| l_shef_loc_id
			|| ' - '
			|| l_shef_id
		);

		IF l_shef_id IS NOT NULL AND l_shef_loc_id IS NOT NULL
		THEN
			IF UPPER (l_shef_id) != UPPER (l_shef_loc_id)
			THEN
				cwms_err.raise (
					'ERROR',
						'The provided SHEF Loc Id: '
					|| l_shef_loc_id
					|| ' does not match an existing SHEF Loc Id: '
					|| l_shef_id
					|| ' set for this Location Group: '
					|| p_loc_group_id
					|| ' and CWMS_TS_ID: '
					|| p_cwms_ts_id
				);
			END IF;
		ELSIF l_shef_id IS NULL
		THEN
			l_shef_id := l_shef_loc_id;
		END IF;

		l_tmp := LENGTH (TRIM (l_shef_id));

		IF l_tmp = 0
		THEN
			cwms_err.raise (
				'ERROR',
				'Unable to set shef spec - No SHEF Id found for this cwms_ts_id and Agency: '
				|| p_loc_group_id
			);
		ELSIF l_tmp > 8
		THEN
			cwms_err.raise (
				'ERROR',
				'SHEF Id is longer than eight characters in length: '
				|| l_shef_id
			);
		END IF;

		--
		l_shef_duration_numeric :=
			get_shef_duration_numeric (p_shef_duration_code);

		BEGIN
			SELECT	shef_duration_code
			  INTO	l_shef_duration_code
			  FROM	cwms_shef_duration
			 WHERE	shef_duration_numeric = l_shef_duration_numeric;
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				l_shef_duration_code := 'V';
		END;

		cwms_apex.aa1 (
				'in store_shef_spec - duration: .'
			|| l_shef_duration_numeric
			|| ' - '
			|| l_shef_duration_code
		);

		SELECT	a.unit_code
		  INTO	l_shef_unit_code
		  FROM	cwms_unit a
		 WHERE	a.unit_id = p_shef_unit_id;

		cwms_apex.aa1 (
			'store_shef_spec - shef_unit_coded: ' || l_shef_unit_code
		);

		SELECT	shef_time_zone_code
		  INTO	l_shef_time_zone_code
		  FROM	cwms_shef_time_zone a
		 WHERE	UPPER (a.shef_time_zone_id) = UPPER (l_time_zone_id);

		cwms_ts.update_ts_id (
			p_ts_code						=> l_ts_code,
			p_interval_utc_offset		=> p_interval_utc_offset,
			-- in minutes.
			p_snap_forward_minutes		=> p_snap_forward_minutes,
			p_snap_backward_minutes 	=> p_snap_backward_minutes,
			p_local_reg_time_zone_id	=> NULL,
			p_ts_active_flag				=> l_ts_active_flag
		);

		--
		--
		-- BEGIN
		cwms_apex.aa1 ('store_shef_spec - trying to insert into at_shef_decode'
						  );

		INSERT
		  INTO	at_shef_decode (ts_code,
										 data_stream_code,
										 data_feed_code,
										 shef_loc_id,
										 shef_pe_code,
										 shef_tse_code,
										 shef_duration_numeric,
										 shef_unit_code,
										 shef_time_zone_code,
										 dl_time,
										 location_code,
										 loc_group_code,
										 shef_duration_code
										)
		VALUES	(
						l_ts_code,
						l_data_stream_code,
						l_data_feed_code,
						l_shef_id,
						l_shef_pe_code,
						l_shef_tse_code,
						l_shef_duration_numeric,
						l_shef_unit_code,
						l_shef_time_zone_code,
						l_dl_time,
						l_location_code,
						l_loc_group_code,
						l_shef_duration_code
					);
	-- EXCEPTION
	--  WHEN OTHERS
	--  THEN
	--   DECLARE
	--  ERROR_CODE NUMBER := SQLCODE;
	--   BEGIN
	--  IF ERROR_CODE = -1
	--  THEN
	--   cwms_err.raise ('SHEF_DUP_TS_ID', p_cwms_ts_id);
	--  ELSE
	--   cwms_apex.aa1 (
	--  'store_shef_spec - trying to update into at_shef_decode'
	--   );
	--   cwms_apex.aa1 (
	--  'store_shef_spec - tse code is:' || l_shef_tse_code
	--   );
	--
	--   UPDATE at_shef_decode
	--  SET shef_loc_id = l_shef_id,
	--  shef_pe_code = l_shef_pe_code,
	--  shef_tse_code = l_shef_tse_code,
	--  shef_duration_numeric = l_shef_duration_numeric,
	--  shef_unit_code = l_shef_unit_code,
	--  shef_time_zone_code = l_shef_time_zone_code,
	--  dl_time = l_dl_time,
	--  location_code = l_location_code,
	--  loc_group_code = l_loc_group_code,
	--  shef_duration_code = l_shef_duration_code
	--  WHERE ts_code = l_ts_code
	--  AND data_feed_code = l_data_feed_code;
	--  END IF;
	--   END;
	-- END;
	END;

	-- ****************************************************************************
	-- cwms_shef.delete_shef_spec is used to delete an existing SHEF spec. SHEF
	-- specs are assigned to pairs of cwms_ts_id and data stream.
	--
	-- p_cwms_ts_id(varchar2(183) - required parameter) and
	-- p_data_stream_id (varchar2(16 - required parameter) -- is the cwms_ts_id
	--   data stream pair whose SHEF spec you wish to delete.
	--
	-- p_db_office_id (varchar2(16) - optional parameter) is the database office
	--   id that this data stream will be/is assigned too. Normally this is
	--   left null and the user's default database office id is used.
	--
	PROCEDURE delete_shef_spec (p_cwms_ts_id		  IN VARCHAR2,
										 p_data_stream_id   IN VARCHAR2,
										 p_db_office_id	  IN VARCHAR2 DEFAULT NULL
										)
	IS
		l_db_office_code		NUMBER
										:= cwms_util.get_db_office_code (p_db_office_id);
		l_cwms_ts_code 		NUMBER
			:= cwms_ts.get_ts_code (p_cwms_ts_id		 => p_cwms_ts_id,
											p_db_office_code	 => l_db_office_code
										  );
		l_data_stream_code	NUMBER;
	BEGIN
		-- Check if data_stream already exists...
		BEGIN
			l_data_stream_code :=
				get_data_stream_code (p_data_stream_id   => p_data_stream_id,
											 p_db_office_code   => l_db_office_code
											);
		EXCEPTION
			WHEN OTHERS
			THEN
				cwms_err.raise ('DATA_STREAM_NOT_FOUND', TRIM (p_data_stream_id));
		END;

		DELETE	at_shef_decode
		 WHERE	ts_code = l_cwms_ts_code
					AND data_stream_code = l_data_stream_code;
	END;

	-- ****************************************************************************
	-- cwms_shef.store_data_stream is used to:
	--  a) create a new data stream entry
	--  b) revise an existing data stream's description and/or active_flag.
	--
	-- p_data_stream_id (varchar2(16) - required parameter)is either a new or
	--   existing data stream id. If the data stream id is new, then a new
	--   data steam is created in the database. If the data stream exists,
	--   then the data stream's description and/or active flag are updated.
	--
	-- p_data_stream_desc (varchar2(128) - optional parameter) is an optional
	--   description field for the data stream.
	--
	-- p_active_flag (optional parameter, can be either "T" or "F" with the default
	--   being "T") Indicates whether this data stream is active ("T") or
	--   inactive ("F"). ProcessSHEFIT will only process data for an active
	--   ("T") data stream.
	--
	-- p_ignore_nulls (optional parameter, can be either "T" or "F" with the
	--   default being "T") Only valid when store_data_stream is being used
	--   to update an existing data stream's active flag. When set to "T"
	--   (the default), a null p_data_stream_desc is ignored - this allows
	--   one to change the active flag without having to pass in the data
	--   stream's description - you can simply leave the description null
	--   and the null will not overwrite any existing description in the
	--   database.
	--
	-- p_db_office_id (varchar2(16) - optional parameter) is the database office
	--   id that this data stream will be/is assigned too. Normally this is
	--   left null and the user's default database office id is used.
	--
	PROCEDURE store_data_stream (
		p_data_stream_id		IN VARCHAR2,
		p_data_stream_desc	IN VARCHAR2 DEFAULT NULL,
		p_active_flag			IN VARCHAR2 DEFAULT 'T',
		p_ignore_nulls 		IN VARCHAR2 DEFAULT 'T',
		p_db_office_id 		IN VARCHAR2 DEFAULT NULL
	)
	IS
		l_db_office_code		NUMBER
										:= cwms_util.get_db_office_code (p_db_office_id);
		l_data_stream_code	NUMBER;
		l_active_flag			VARCHAR2 (1) := NVL (UPPER (p_active_flag), 'T');
		l_ignore_nulls 		VARCHAR2 (1) := NVL (UPPER (p_ignore_nulls), 'T');
		l_data_stream_id		VARCHAR2 (16) := TRIM (p_data_stream_id);
	BEGIN
		IF l_data_stream_id IS NULL
		THEN
			cwms_err.raise ('PARAM_CANNOT_BE_NULL', 'p_data_stream_id');
		END IF;

		IF l_active_flag NOT IN ('T', 'F')
		THEN
			cwms_err.raise ('INVALID_T_F_FLAG', 'p_active_flag');
		END IF;

		IF l_ignore_nulls NOT IN ('T', 'F')
		THEN
			cwms_err.raise ('INVALID_T_F_FLAG', 'p_active_flag');
		END IF;

		-- Check if data_stream already exists...
		BEGIN
			l_data_stream_code :=
				get_data_stream_code (p_data_stream_id   => p_data_stream_id,
											 p_db_office_code   => l_db_office_code
											);
		EXCEPTION
			WHEN OTHERS
			THEN
				l_data_stream_code := NULL;
		END;

		IF l_data_stream_code IS NULL
		THEN												  -- storing a new data stream...
			INSERT
			  INTO	at_data_stream_id (data_stream_code,
												 db_office_code,
												 data_stream_id,
												 data_stream_desc,
												 active_flag,
												 data_stream_mgt_style
												)
			VALUES	(
							cwms_seq.NEXTVAL,
							l_db_office_code,
							l_data_stream_id,
							TRIM (p_data_stream_desc),
							l_active_flag,
							get_data_stream_mgt_style (p_db_office_id)
						);
		ELSE										 -- updating an existing data stream...
			IF p_data_stream_desc IS NULL AND l_ignore_nulls = 'T'
			THEN					  -- update that ignores a null data_stream_desc...
				UPDATE	at_data_stream_id
					SET	data_stream_id = l_data_stream_id,
							active_flag = l_active_flag
				 WHERE	data_stream_code = l_data_stream_code;
			ELSE			-- update that does not ignore a null data_stream_desc...
				UPDATE	at_data_stream_id
					SET	data_stream_id = l_data_stream_id,
							data_stream_desc = TRIM (p_data_stream_desc),
							active_flag = l_active_flag
				 WHERE	data_stream_code = l_data_stream_code;
			END IF;
		END IF;
	END;

	-- ****************************************************************************
	-- cwms_shef.rename_data_stream is used to rename an existing data stream id.
	--
	-- p_data_stream_id _old(varchar2(16) - required parameter)is the id of the
	--   existing data stream id.
	--
	-- p_data_stream_id _newvarchar2(16) - required parameter)is the id that you
	--   are renaming the old data stream name too.
	--
	-- p_db_office_id (varchar2(16) - optional parameter) is the database office
	--   id that this data stream will be/is assigned too. Normally this is
	--   left null and the user's default database office id is used.
	--
	PROCEDURE rename_data_stream (
		p_data_stream_id_old   IN VARCHAR2,
		p_data_stream_id_new   IN VARCHAR2,
		p_db_office_id 		  IN VARCHAR2 DEFAULT NULL
	)
	IS
		l_db_office_code		NUMBER
										:= cwms_util.get_db_office_code (p_db_office_id);
		l_data_stream_code	NUMBER;
		l_tmp 					NUMBER;
		l_case_change			BOOLEAN := FALSE;
	BEGIN
		-- Check if "old" data_stream already exists...
		BEGIN
			l_data_stream_code :=
				get_data_stream_code (p_data_stream_id   => p_data_stream_id_old,
											 p_db_office_code   => l_db_office_code
											);
		EXCEPTION
			WHEN OTHERS
			THEN				  -- old data stream does not exist - cannot rename...
				cwms_err.raise ('CANNOT_RENAME_1', TRIM (p_data_stream_id_old));
		END;

		-- Check if the case of the old id is being changed...
		IF UPPER (TRIM (p_data_stream_id_old)) =
				UPPER (TRIM (p_data_stream_id_new))
		THEN						  -- then old and new are syntactically the same...
			IF TRIM (p_data_stream_id_old) = TRIM (p_data_stream_id_new)
			THEN			-- the old and new are exactly the same - so no rename...
				cwms_err.raise ('CANNOT_RENAME_3', TRIM (p_data_stream_id_old));
			ELSE
				l_case_change := TRUE;
			END IF;
		END IF;

		-- Check if "new" data_stream already exists...
		IF NOT l_case_change
		THEN
			BEGIN
				l_tmp :=
					get_data_stream_code (
						p_data_stream_id	 => p_data_stream_id_new,
						p_db_office_code	 => l_db_office_code
					);
			EXCEPTION
				WHEN OTHERS
				THEN				  -- new datastream does not exist - good thing!...
					l_tmp := NULL;
			END;

			IF l_tmp != NULL
			THEN
				cwms_err.raise ('CANNOT_RENAME_2', TRIM (p_data_stream_id_new));
			END IF;
		END IF;

		-- peform the update...
		UPDATE	at_data_stream_id
			SET	data_stream_id = TRIM (p_data_stream_id_new)
		 WHERE	data_stream_code = l_data_stream_code;
	END;

	-- ****************************************************************************
	-- cwms_shef.delete_data_stream_entries is used to delete all data stream entries
	--   associated with the specified data_stream.
	--
	-- p_data_stream_id(varchar2(16) - required parameter)is the id of the
	--   existing data stream whose entries will be deleted. All entries
	--   for the p_data_stream_id in table at_shef_decode are deleted. This
	--   is the table that is used to build a data streams crit file that's
	--   used by processShefit.
	--
	-- p_db_office_id (varchar2(16) - optional parameter) is the database office
	--   id that this data stream will be/is assigned too. Normally this is
	--   left null and the user's default database office id is used.
	--
	PROCEDURE delete_data_stream_shef_specs (
		p_data_stream_id	 IN VARCHAR2,
		p_db_office_id 	 IN VARCHAR2 DEFAULT NULL
	)
	IS
		l_db_office_code		NUMBER
										:= cwms_util.get_db_office_code (p_db_office_id);
		l_data_stream_code	NUMBER;
	BEGIN
		-- Check if data_stream already exists...
		BEGIN
			l_data_stream_code :=
				get_data_stream_code (p_data_stream_id   => p_data_stream_id,
											 p_db_office_code   => l_db_office_code
											);
		EXCEPTION
			WHEN OTHERS
			THEN
				cwms_err.raise ('DATA_STREAM_NOT_FOUND', TRIM (p_data_stream_id));
		END;

		DELETE FROM   at_shef_decode
				WHERE   data_stream_code = l_data_stream_code;
	END;

	PROCEDURE clear_data_stream (p_data_stream_id	IN VARCHAR2,
										  p_db_office_id		IN VARCHAR2 DEFAULT NULL
										 )
	IS
	BEGIN
		IF get_data_stream_mgt_style != data_stream_mgt_style
		THEN
			cwms_err.raise (
				'ERROR',
				'The CLEAR_DATA_STREAM call can only be called when your site is set to use the '
				|| data_stream_mgt_style
				|| ' Mgt Sytle. Your site is curretly set to use the '
				|| get_data_stream_mgt_style
				|| '.'
			);
		ELSE
			NULL;
		END IF;
	END;

	-- ****************************************************************************
	-- cwms_shef.delete_data_stream is used to delete an existing data stream id.
	--
	-- p_data_stream_id(varchar2(16) - required parameter)is the id of the
	--   existing data stream to be deleted.
	--
	-- p_cascade_all (optional parameter, can be either "T" or "F" with the default
	--   being "F") -- A data stream can only be deleted if there are no
	--   SHEF specs assigned to it. You can force a deletion by setting
	--   p_cascade_all to "T", which will delete all SHEF specs associated
	--   with this data stream. WARNING - this is a very powerfull option -
	--   all SHEF specs are permanently deleted!!
	--
	-- p_db_office_id (varchar2(16) - optional parameter) is the database office
	--   id that this data stream will be/is assigned too. Normally this is
	--   left null and the user's default database office id is used.
	--
	PROCEDURE delete_data_stream (p_data_stream_id	 IN VARCHAR2,
											p_cascade_all		 IN VARCHAR2 DEFAULT 'F',
											p_db_office_id 	 IN VARCHAR2 DEFAULT NULL
										  )
	IS
		l_db_office_code		NUMBER
										:= cwms_util.get_db_office_code (p_db_office_id);
		l_data_stream_code	NUMBER;
		l_cascade_all			VARCHAR2 (1) := NVL (UPPER (p_cascade_all), 'F');
	BEGIN
		IF l_cascade_all NOT IN ('T', 'F')
		THEN
			cwms_err.raise ('INVALID_T_F_FLAG', 'p_cascade_all');
		END IF;

		-- Check if data_stream already exists...
		BEGIN
			l_data_stream_code :=
				get_data_stream_code (p_data_stream_id   => p_data_stream_id,
											 p_db_office_code   => l_db_office_code
											);
		EXCEPTION
			WHEN OTHERS
			THEN
				cwms_err.raise ('DATA_STREAM_NOT_FOUND', TRIM (p_data_stream_id));
		END;

		IF l_cascade_all = 'T'
		THEN						-- delete all shef criteria for this data stream...
			DELETE FROM   at_shef_decode
					WHERE   data_stream_code = l_data_stream_code;
		END IF;

		-- delete data stream from database...
		BEGIN
			UPDATE	at_data_stream_id a
				SET	a.delete_date = SYSDATE
			 WHERE	data_stream_code = l_data_stream_code;
		--  DELETE FROM at_data_stream_id
		--  WHERE data_stream_code = l_data_stream_code;
		EXCEPTION
			WHEN OTHERS
			THEN
				cwms_err.raise ('CANNOT_DELETE_DATA_STREAM',
									 TRIM (p_data_stream_id)
									);
		END;
	END;

	PROCEDURE cat_shef_data_streams (
		p_shef_data_streams		 OUT SYS_REFCURSOR,
		p_db_office_id 		 IN	  VARCHAR2 DEFAULT NULL
	)
	IS
		l_db_office_code	 NUMBER
									 := cwms_util.get_db_office_code (p_db_office_id);
	BEGIN
		OPEN p_shef_data_streams FOR
			SELECT	data_stream_id, db_office_id, data_stream_desc,
              active_flag, UPDATE_CRIT_FILE_FLAG,
              date_of_last_crit_file
			  FROM	av_data_streams
              where db_office_code = l_db_office_code;
	END cat_shef_data_streams;

	FUNCTION cat_shef_data_streams_tab (
		p_db_office_id IN VARCHAR2 DEFAULT NULL
	)
		RETURN cat_data_stream_tab_t
		PIPELINED
	IS
		output_row		cat_data_stream_rec_t;
		query_cursor	SYS_REFCURSOR;
	BEGIN
		cat_shef_data_streams (query_cursor, p_db_office_id);

		LOOP
			FETCH query_cursor
			INTO output_row;

			EXIT WHEN query_cursor%NOTFOUND;
			PIPE ROW (output_row);
		END LOOP;

		CLOSE query_cursor;

		RETURN;
	END cat_shef_data_streams_tab;

	PROCEDURE cat_shef_durations (p_shef_durations OUT SYS_REFCURSOR)
	IS
	BEGIN
		OPEN p_shef_durations FOR
			SELECT	  a.shef_duration_code, a.shef_duration_desc,
						  a.shef_duration_numeric, cd.duration_id
				 FROM   cwms_shef_duration a, cwms_duration cd
				WHERE   a.cwms_duration_code = cd.duration_code(+)
			ORDER BY   TO_NUMBER (a.shef_duration_numeric);
	END cat_shef_durations;

	PROCEDURE cat_shef_time_zones (p_shef_time_zones OUT SYS_REFCURSOR)
	IS
	BEGIN
		OPEN p_shef_time_zones FOR
			SELECT	  shef_time_zone_id, shef_time_zone_desc
				 FROM   cwms_shef_time_zone
			ORDER BY   shef_time_zone_id;
	END cat_shef_time_zones;

	PROCEDURE cat_shef_units (p_shef_units OUT SYS_REFCURSOR)
	IS
	BEGIN
		OPEN p_shef_units FOR
			SELECT	  unit_id shef_unit_id
				 FROM   cwms_unit
			ORDER BY   abstract_param_code, unit_id;
	END cat_shef_units;

	PROCEDURE delete_local_pe_code (p_id_code 		 IN NUMBER,
											  p_db_office_id	 IN VARCHAR2 DEFAULT NULL
											 )
	IS
		l_db_office_code	 NUMBER;
	BEGIN
		l_db_office_code := cwms_util.get_db_office_code (p_db_office_id);

		--
		DELETE FROM   at_shef_pe_codes
				WHERE   id_code = p_id_code;
	END;

	PROCEDURE create_local_pe_code (
		p_shef_pe_code 			  IN VARCHAR2,
		p_shef_tse_code			  IN VARCHAR2,
		p_shef_duration_numeric   IN VARCHAR2,
		p_shef_req_send_code 	  IN VARCHAR2 DEFAULT NULL,
		p_parameter_id 			  IN VARCHAR2,
		p_parameter_type_id		  IN VARCHAR2,
		p_unit_id_en				  IN VARCHAR2,
		p_unit_id_si				  IN VARCHAR2,
		p_description				  IN VARCHAR2 DEFAULT NULL,
		p_notes						  IN VARCHAR2 DEFAULT NULL,
		p_db_office_id 			  IN VARCHAR2 DEFAULT NULL
	)
	IS
		l_num 						 NUMBER;
		l_db_office_code			 NUMBER;
		l_db_office_id 			 VARCHAR2 (16);
		l_shef_pe_code 			 VARCHAR2 (2);
		l_shef_tse_code			 VARCHAR2 (3);
		l_shef_duration_code 	 VARCHAR2 (1);
		l_parameter_code			 NUMBER;
		l_parameter_type_code	 NUMBER;
		l_unit_code_en 			 NUMBER;
		l_unit_code_si 			 NUMBER;
		l_abstract_param_id		 VARCHAR2 (32);
		l_abstract_param_id_en	 VARCHAR2 (32);
		l_abstract_param_id_si	 VARCHAR2 (32);
		l_shef_req_send_code 	 VARCHAR2 (7) := NULL;
	BEGIN
		l_db_office_code := cwms_util.get_db_office_code (p_db_office_id);
		l_db_office_id := cwms_util.get_db_office_id (p_db_office_id);
		l_num := LENGTH (TRIM (p_shef_pe_code));

		IF l_num != 2
		THEN
			cwms_err.raise (
				'GENERIC',
				'Invalid PE Code submitted. PE Code must be two characters in length. You submitted: '
				|| TRIM (p_shef_pe_code)
			);
		END IF;

		l_shef_pe_code := TRIM (p_shef_pe_code);
		l_num := LENGTH (TRIM (p_shef_tse_code));

		IF l_num != 3
		THEN
			cwms_err.raise (
				'GENERIC',
				'Invalid TSE Code submitted. TSE Code must be three characters in length. You submitted: '
				|| TRIM (p_shef_tse_code)
			);
		END IF;

		l_shef_tse_code := TRIM (p_shef_tse_code);

		IF p_shef_req_send_code IS NOT NULL
		THEN
			l_num := LENGTH (TRIM (p_shef_req_send_code));

			IF l_num != 7
			THEN
				cwms_err.raise (
					'GENERIC',
					'Invalid Required Send Code submitted. Requires Send Code must be seven characters in length. You submitted: '
					|| TRIM (p_shef_req_send_code)
				);
			END IF;

			l_shef_req_send_code := TRIM (p_shef_req_send_code);
		END IF;

		BEGIN
			SELECT	csd.shef_duration_code
			  INTO	l_shef_duration_code
			  FROM	cwms_shef_duration csd
			 WHERE	csd.shef_duration_numeric = p_shef_duration_numeric;
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				cwms_err.raise (
					'GENERIC',
					'Invalid SHEF Duration Numeric submitted. You submitted: '
					|| TRIM (p_shef_duration_numeric)
				);
		END;

		l_parameter_code :=
			cwms_ts.get_parameter_code (
				p_base_parameter_id	 => cwms_util.get_base_id (p_parameter_id),
				p_sub_parameter_id	 => cwms_util.get_sub_id (p_parameter_id),
				p_office_id 			 => l_db_office_id,
				p_create 				 => 'T'
			);

		SELECT	cap.abstract_param_id
		  INTO	l_abstract_param_id
		  FROM	at_parameter atp,
					cwms_base_parameter cbp,
					cwms_abstract_parameter cap
		 WHERE		 atp.base_parameter_code = cbp.base_parameter_code
					AND cbp.abstract_param_code = cap.abstract_param_code
					AND atp.parameter_code = l_parameter_code;

		BEGIN
			SELECT	parameter_type_code
			  INTO	l_parameter_type_code
			  FROM	cwms_parameter_type
			 WHERE	UPPER (parameter_type_id) =
							UPPER (TRIM (p_parameter_type_id));
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				cwms_err.raise (
					'GENERIC',
					'Invalid CWMS Parameter Type submitted: '
					|| TRIM (p_parameter_type_id)
				);
		END;

		BEGIN
			SELECT	cu.unit_code, cap.abstract_param_id
			  INTO	l_unit_code_en, l_abstract_param_id_en
			  FROM	cwms_unit cu, cwms_abstract_parameter cap
			 WHERE	cu.abstract_param_code = cap.abstract_param_code
						AND cu.unit_id = TRIM (p_unit_id_en);
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				cwms_err.raise (
					'GENERIC',
					TRIM (p_unit_id_en)
					|| ' is not a recognized unit in the CWMS Database.'
				);
		END;

		BEGIN
			SELECT	cu.unit_code, cap.abstract_param_id
			  INTO	l_unit_code_si, l_abstract_param_id_si
			  FROM	cwms_unit cu, cwms_abstract_parameter cap
			 WHERE	cu.abstract_param_code = cap.abstract_param_code
						AND cu.unit_id = TRIM (p_unit_id_si);
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				cwms_err.raise (
					'GENERIC',
					TRIM (p_unit_id_si)
					|| ' is not a recognized unit in the CWMS Database.'
				);
		END;

		IF l_abstract_param_id_en != l_abstract_param_id_si
		THEN
			cwms_err.raise (
				'GENERIC',
				'The Abstract Parameter types for your English and SI units do not match. The Abstract Parameter Type of your English unit: '
				|| TRIM (p_unit_id_en)
				|| ' is: '
				|| l_abstract_param_id_en
				|| ' and the Abstract Parameter Type of your SI unit: '
				|| TRIM (p_unit_id_si)
				|| ' is: '
				|| l_abstract_param_id_si
			);
		END IF;

		IF l_abstract_param_id_en != l_abstract_param_id
		THEN
			cwms_err.raise (
				'GENERIC',
					'The Abstract Parameter type for your Base Parameter: '
				|| cwms_util.get_base_id (p_parameter_id)
				|| ' is: '
				|| l_abstract_param_id
				|| ', which must match the Abstract Paramter Type of the units you are specifying, which are: '
				|| l_abstract_param_id_si
			);
		END IF;

		INSERT
		  INTO	at_shef_pe_codes (db_office_code,
											shef_pe_code,
											id_code,
											shef_tse_code,
											shef_duration_code,
											shef_req_send_code,
											unit_code_en,
											unit_code_si,
											parameter_code,
											parameter_type_code,
											description,
											notes
										  )
		VALUES	(
						l_db_office_code,
						l_shef_pe_code,
						cwms_seq.NEXTVAL,
						l_shef_tse_code,
						l_shef_duration_code,
						l_shef_req_send_code,
						l_unit_code_en,
						l_unit_code_si,
						l_parameter_code,
						l_parameter_type_code,
						TRIM (p_description),
						TRIM (p_notes)
					);
	END;

	PROCEDURE cat_shef_extremum_codes (p_shef_extremum_codes OUT SYS_REFCURSOR
												 )
	IS
	BEGIN
		OPEN p_shef_extremum_codes FOR
			SELECT	  csec.shef_e_code, csec.description, cd.duration_id
				 FROM   cwms_shef_extremum_codes csec, cwms_duration cd
				WHERE   csec.duration_code = cd.duration_code(+)
			ORDER BY   sequence_no;
	END;

	PROCEDURE cat_shef_pe_codes (
		p_shef_pe_codes		OUT SYS_REFCURSOR,
		p_db_office_id 	IN 	 VARCHAR2 DEFAULT NULL
	)
	IS
		l_db_office_code	 NUMBER
									 := cwms_util.get_db_office_code (p_db_office_id);
	BEGIN
		OPEN p_shef_pe_codes FOR
			SELECT	53, shef_pe_code, shef_tse_code, shef_req_send_code,
						cspec.shef_duration_code, csd.shef_duration_numeric,
						cu1.unit_id unit_id_en, cu2.unit_id unit_id_si,
						cap.abstract_param_id, cbp.base_parameter_id,
						atp.sub_parameter_id, cpt.parameter_type_id,
						cspec.description, cspec.notes
			  FROM	cwms_shef_pe_codes cspec,
						cwms_shef_duration csd,
						cwms_unit cu1,
						cwms_unit cu2,
						cwms_abstract_parameter cap,
						cwms_base_parameter cbp,
						at_parameter atp,
						cwms_parameter_type cpt
			 WHERE		 cspec.shef_duration_code = csd.shef_duration_code
						AND cspec.unit_code_en = cu1.unit_code(+)
						AND cspec.unit_code_si = cu2.unit_code(+)
						AND cu1.abstract_param_code = cap.abstract_param_code(+)
						AND cspec.parameter_code = atp.parameter_code
						AND atp.base_parameter_code = cbp.base_parameter_code
						AND cspec.parameter_type_code = cpt.parameter_type_code
			UNION
			SELECT	id_code, shef_pe_code, shef_tse_code, shef_req_send_code,
						cspec.shef_duration_code, csd.shef_duration_numeric,
						cu1.unit_id unit_id_en, cu2.unit_id unit_id_si,
						cap.abstract_param_id, cbp.base_parameter_id,
						atp.sub_parameter_id, cpt.parameter_type_id,
						cspec.description, cspec.notes
			  FROM	at_shef_pe_codes cspec,
						cwms_shef_duration csd,
						cwms_unit cu1,
						cwms_unit cu2,
						cwms_abstract_parameter cap,
						cwms_base_parameter cbp,
						at_parameter atp,
						cwms_parameter_type cpt
			 WHERE		 cspec.shef_duration_code = csd.shef_duration_code
						AND cspec.unit_code_en = cu1.unit_code(+)
						AND cspec.unit_code_si = cu2.unit_code(+)
						AND cu1.abstract_param_code = cap.abstract_param_code(+)
						AND cspec.parameter_code = atp.parameter_code
						AND atp.base_parameter_code = cbp.base_parameter_code
						AND cspec.parameter_type_code = cpt.parameter_type_code
						AND cspec.db_office_code = l_db_office_code;
	END cat_shef_pe_codes;

	FUNCTION cat_shef_durations_tab
		RETURN cat_shef_dur_tab_t
		PIPELINED
	IS
		output_row		cat_shef_dur_rec_t;
		query_cursor	SYS_REFCURSOR;
	BEGIN
		cat_shef_durations (query_cursor);

		LOOP
			FETCH query_cursor
			INTO output_row;

			EXIT WHEN query_cursor%NOTFOUND;
			PIPE ROW (output_row);
		END LOOP;

		CLOSE query_cursor;

		RETURN;
	END cat_shef_durations_tab;

	FUNCTION cat_shef_extremum_tab
		RETURN cat_shef_extremum_tab_t
		PIPELINED
	IS
		output_row		cat_shef_extremum_rec_t;
		query_cursor	SYS_REFCURSOR;
	BEGIN
		cat_shef_extremum_codes (query_cursor);

		LOOP
			FETCH query_cursor
			INTO output_row;

			EXIT WHEN query_cursor%NOTFOUND;
			PIPE ROW (output_row);
		END LOOP;

		CLOSE query_cursor;

		RETURN;
	END cat_shef_extremum_tab;

	FUNCTION cat_shef_time_zones_tab
		RETURN cat_shef_tz_tab_t
		PIPELINED
	IS
		output_row		cat_shef_tz_rec_t;
		query_cursor	SYS_REFCURSOR;
	BEGIN
		cat_shef_time_zones (query_cursor);

		LOOP
			FETCH query_cursor
			INTO output_row;

			EXIT WHEN query_cursor%NOTFOUND;
			PIPE ROW (output_row);
		END LOOP;

		CLOSE query_cursor;

		RETURN;
	END cat_shef_time_zones_tab;

	FUNCTION cat_shef_units_tab
		RETURN cat_shef_units_tab_t
		PIPELINED
	IS
		output_row		cat_shef_units_rec_t;
		query_cursor	SYS_REFCURSOR;
	BEGIN
		cat_shef_units (query_cursor);

		LOOP
			FETCH query_cursor
			INTO output_row;

			EXIT WHEN query_cursor%NOTFOUND;
			PIPE ROW (output_row);
		END LOOP;

		CLOSE query_cursor;

		RETURN;
	END cat_shef_units_tab;

	FUNCTION cat_shef_pe_codes_tab (p_db_office_id IN VARCHAR2 DEFAULT NULL)
		RETURN cat_shef_pe_codes_tab_t
		PIPELINED
	IS
		output_row		cat_shef_pe_codes_rec_t;
		query_cursor	SYS_REFCURSOR;
	BEGIN
		cat_shef_pe_codes (query_cursor, p_db_office_id);

		LOOP
			FETCH query_cursor
			INTO output_row;

			EXIT WHEN query_cursor%NOTFOUND;
			PIPE ROW (output_row);
		END LOOP;

		CLOSE query_cursor;

		RETURN;
	END cat_shef_pe_codes_tab;

	----------------------------------
	PROCEDURE parse_criteria_record (p_shef_id					  OUT VARCHAR2,
												p_shef_pe_code 			  OUT VARCHAR2,
												p_shef_tse_code			  OUT VARCHAR2,
												p_shef_duration_code 	  OUT VARCHAR2,
												p_units						  OUT VARCHAR2,
												p_unit_sys					  OUT VARCHAR2,
												p_tz							  OUT VARCHAR2,
												p_dltime 					  OUT VARCHAR2,
												p_int_offset				  OUT VARCHAR2,
												p_int_backward 			  OUT VARCHAR2,
												p_int_forward				  OUT VARCHAR2,
												p_cwms_ts_id				  OUT VARCHAR2,
												p_comment					  OUT VARCHAR2,
												p_criteria_record 	  IN		VARCHAR2
											  )
	IS
		l_criteria_record 	  VARCHAR2 (600) := TRIM (p_criteria_record);
		l_record_length		  NUMBER := LENGTH (l_criteria_record);
		l_left_string			  VARCHAR2 (50);
		l_left_length			  NUMBER;
		l_right_string 		  VARCHAR2 (550);
		l_right_length 		  NUMBER;
		l_tmp 					  NUMBER;
		--
		l_shef_id				  VARCHAR2 (8);
		l_shef_pe_code 		  VARCHAR2 (2);
		l_shef_tse_code		  VARCHAR2 (3);
		l_shef_duration_code   VARCHAR2 (4);
		l_cwms_ts_id			  VARCHAR2 (183);
		--
		l_param_id				  VARCHAR2 (32);
		l_param					  VARCHAR2 (32);
		--
		l_dltime 				  VARCHAR2 (32) := NULL;
		l_tz						  VARCHAR2 (32) := NULL;
		l_units					  VARCHAR2 (32) := NULL;
		l_int_offset			  VARCHAR2 (32) := NULL;
		l_int_backward 		  VARCHAR2 (32) := NULL;
		l_int_forward			  VARCHAR2 (32) := NULL;
		l_unit_sys				  VARCHAR2 (32) := NULL;

		--
		TYPE list_of_num_t IS TABLE OF NUMBER;

		l_pos 					  list_of_num_t := list_of_num_t ();
		l_pos_r					  list_of_num_t := list_of_num_t ();
		l_num 					  NUMBER;
		l_end 					  NUMBER;
		l_sub_length			  NUMBER;
		l_sub_string			  VARCHAR2 (64);
	BEGIN
		p_comment := NULL;

		-- Check if the line is commented out, i.e., starts with a "#",
		IF INSTR (l_criteria_record, '#') = 1
		THEN
			p_comment := 'COMMENT - This is a comment line';
			-- THIS IS A COMMENT LINE - IGNORE.
			GOTO fin;
		END IF;

		--
		-- split the line into the right and left parts...
		--
		l_tmp := INSTR (l_criteria_record, '=');

		IF l_tmp IN (0, 1, l_record_length)
		THEN
			p_comment := 'ERROR: Malformed criteria line';
			-- malformed record...
			GOTO fin;
		END IF;

		SELECT	TRIM (SUBSTR (l_criteria_record, 1, l_tmp - 1)),
					TRIM (SUBSTR (l_criteria_record, l_tmp + 1, l_record_length - l_tmp))
		  INTO	l_left_string, l_right_string
		  FROM	DUAL;

		--
		-- split the left side into its four components...
		--
		---- Find the three expected period delimiters...
		----
		FOR i IN 1 .. 3
		LOOP
			l_tmp := INSTR (l_left_string, '.', 1, i);

			IF l_tmp = 0
			THEN
				p_comment := 'ERROR: Malformed SHEF signature';
				-- malformed record...
				GOTO fin;
			ELSE
				l_pos.EXTEND;
				l_pos (i) := l_tmp;
			END IF;
		END LOOP;

		----
		---- SHEF Id...
		l_sub_length := l_pos (1) - 1;

		IF l_sub_length <= 0 OR l_sub_length > 8
		THEN
			p_comment := 'ERROR: SHEF Id is null or longer than 8 characters.';
			-- malformed record...
			GOTO fin;
		ELSE
			l_shef_id := TRIM (SUBSTR (l_left_string, 1, l_sub_length));
		END IF;

		----
		---- SHEF PE Code...
		l_sub_length := l_pos (2) - l_pos (1) - 1;

		IF l_sub_length != 2
		THEN
			p_comment := 'ERROR: SHEF PE code must be 2 characters in length.';
			-- malformed record...
			GOTO fin;
		ELSE
			l_shef_pe_code := TRIM (SUBSTR (l_left_string, l_pos (1) + 1, 2));
		END IF;

		----
		---- SHEF TSE Code...
		l_sub_length := l_pos (3) - l_pos (2) - 1;

		IF l_sub_length != 3
		THEN
			p_comment := 'ERROR: SHEF TSE code must be 3 characters in length.';
			-- malformed record...
			GOTO fin;
		ELSE
			l_shef_tse_code := TRIM (SUBSTR (l_left_string, l_pos (2) + 1, 3));
		END IF;

		----
		---- SHEF Duration Code...
		l_sub_length := LENGTH (l_left_string) - l_pos (3);

		IF l_sub_length < 1 OR l_sub_length > 4
		THEN
			p_comment :=
				'ERROR: SHEF Duration code must be between 1 adn 4 characters long.';
			-- malformed record...
			GOTO fin;
		ELSE
			l_shef_duration_code :=
				TRIM (SUBSTR (l_left_string, l_pos (3) + 1, l_sub_length));
		END IF;

		--
		-- split the right side into its components...
		--
		----
		---- right side is parsed with ';' - need to determine how many elements -
		---- there are...
		----
		l_tmp := 1;
		l_num := 1;
		l_right_length := LENGTH (l_right_string);

		WHILE l_tmp < l_right_length
		LOOP
			l_tmp := INSTR (l_right_string, ';', 1, l_num);

			IF l_tmp = 0
			THEN
				l_tmp := l_right_length;
			ELSE
				l_pos_r.EXTEND;
				l_pos_r (l_num) := l_tmp;
				l_num := l_num + 1;
			END IF;
		END LOOP;

		----
		---- extract the ts_id from the right side...
		----
		IF l_num = 1
		THEN
			l_tmp := l_right_length;
		ELSE
			l_tmp := l_pos_r (1) - 1;
		END IF;

		l_cwms_ts_id := SUBSTR (l_right_string, 1, l_tmp);

		----
		---- extract any of the parameters that are set...
		----
		IF l_num > 1
		THEN
			l_num := l_num - 1;

			FOR i IN 1 .. l_num
			LOOP
				IF i = l_num
				THEN
					l_tmp := l_right_length;
				ELSE
					l_tmp := l_pos_r (i + 1) - 1;
				END IF;

				--
				l_sub_length := l_tmp - l_pos_r (i);

				IF l_sub_length > 0
				THEN
					l_sub_string :=
						SUBSTR (l_right_string, l_pos_r (i) + 1, l_sub_length);
					--
					l_param_id :=
						UPPER (
							SUBSTR (
								l_right_string,
								l_pos_r (i) + 1,
								INSTR (l_right_string, '=', 1, i) - l_pos_r (i) - 1
							)
						);
					l_param :=
						SUBSTR (l_right_string,
								  INSTR (l_right_string, '=', 1, i) + 1,
								  l_tmp - INSTR (l_right_string, '=', 1, i)
								 );

					CASE l_param_id
						WHEN 'DLTIME'
						THEN
							l_dltime := l_param;
						WHEN 'TZ'
						THEN
							l_tz := l_param;
						WHEN 'UNITS'
						THEN
							l_units := l_param;
						WHEN 'INTERVALOFFSET'
						THEN
							l_int_offset := l_param;
						WHEN 'INTERVALBACKWARD'
						THEN
							l_int_backward := l_param;
						WHEN 'INTERVALFORWARD'
						THEN
							l_int_forward := l_param;
						WHEN 'UNITSYS'
						THEN
							l_unit_sys := l_param;
						ELSE
							p_comment :=
								'ERROR: "' || l_sub_string
								|| '" does not contain a valid processSHEFIT parameter.';
							-- malformed record...
							GOTO fin;
					END CASE;
				END IF;
			END LOOP;
		END IF;

	  --
	  -- Prepare to return data...
	  --
	  <<fin>>
		p_shef_id := l_shef_id;
		p_shef_pe_code := l_shef_pe_code;
		p_shef_tse_code := l_shef_tse_code;
		p_shef_duration_code := l_shef_duration_code;
		p_cwms_ts_id := l_cwms_ts_id;
		p_dltime := l_dltime;
		p_tz := l_tz;
		p_units := l_units;
		p_int_offset := l_int_offset;
		p_int_backward := l_int_backward;
		p_int_forward := l_int_forward;
		p_unit_sys := l_unit_sys;
	END;

	PROCEDURE store_shef_crit_file (
		p_data_stream_id	 IN VARCHAR2,
		p_db_office_id 	 IN VARCHAR2 DEFAULT NULL
	)
	IS
		output_row				  VARCHAR2 (400);
		l_shef_crit_lines_rc   SYS_REFCURSOR;
		l_crit_file_clob		  CLOB;
		amount					  BINARY_INTEGER := 0;
		l_data_stream_code	  NUMBER;
		l_tmp 					  NUMBER;
	BEGIN
		cat_shef_crit_lines (p_shef_crit_lines   => l_shef_crit_lines_rc,
									p_data_stream_id	  => p_data_stream_id,
									p_db_office_id 	  => p_db_office_id
								  );
		DBMS_LOB.createtemporary (l_crit_file_clob, TRUE, DBMS_LOB.session);
		/* Opening the temporary LOB is optional: */
		DBMS_LOB.open (l_crit_file_clob, DBMS_LOB.lob_readwrite);

		/* Append the data from the buffer to the end of the LOB: */
		LOOP
			FETCH l_shef_crit_lines_rc
			INTO output_row;

			EXIT WHEN l_shef_crit_lines_rc%NOTFOUND;
			amount := LENGTH (output_row) + 1;
			DBMS_LOB.writeappend (l_crit_file_clob,
										 amount,
										 output_row || CHR (10)
										);
		END LOOP;

		IF amount > 0
		THEN
			l_data_stream_code :=
				get_data_stream_code (p_data_stream_id   => p_data_stream_id,
											 p_db_office_id	  => p_db_office_id
											);
			clean_at_shef_crit_file (
				p_data_stream_code	=> l_data_stream_code,
				p_action 				=> cwms_shef.ten_file_limit
			);

			INSERT
			  INTO	at_shef_crit_file (data_stream_code,
												 creation_date,
												 shef_crit_file
												)
			VALUES	(l_data_stream_code, SYSDATE, l_crit_file_clob);
		END IF;

		DBMS_LOB.close (l_crit_file_clob);
		DBMS_LOB.freetemporary (l_crit_file_clob);

		CLOSE l_shef_crit_lines_rc;
	END;

	PROCEDURE cat_shef_crit_lines (
		p_shef_crit_lines 	  OUT SYS_REFCURSOR,
		p_data_stream_id	  IN		VARCHAR2,
		p_db_office_id 	  IN		VARCHAR2 DEFAULT NULL
	)
	IS
		l_db_office_code		NUMBER
										:= cwms_util.get_db_office_code (p_db_office_id);
		l_data_stream_code	NUMBER
			:= get_data_stream_code (p_data_stream_id, l_db_office_code);
	BEGIN
		OPEN p_shef_crit_lines FOR
			SELECT	CASE
							WHEN a.ignore_shef_spec = 'T'
							THEN
								cwms_shef.ignore_shef_spec
							ELSE
								NULL
						END
						|| a.shef_loc_id
						|| '.'
						|| a.shef_pe_code
						|| '.'
						|| a.shef_tse_code
						|| '.'
						|| a.shef_duration_numeric
						|| '='
						|| b.cwms_ts_id
						|| CASE
								WHEN a.shef_unit_code IS NOT NULL
								THEN
									';Units=' || c.unit_id
							END
						|| CASE
								WHEN a.shef_time_zone_code IS NOT NULL
								THEN
									';TZ=' || d.shef_time_zone_id
							END
						|| ';DLTime='
						|| CASE WHEN a.dl_time = 'T' THEN 'true' ELSE 'false' END
						|| CASE
								WHEN e.interval_offset_id NOT IN
										  (cwms_util.utc_offset_irregular,
											cwms_util.utc_offset_undefined)
								THEN
									';IntervalOffset='
									|| cwms_util.get_interval_string (
											e.interval_utc_offset
										)
									|| CASE
											WHEN e.interval_forward IS NOT NULL
											THEN
												';IntervalForward='
												|| cwms_util.get_interval_string (
														e.interval_forward
													)
										END
									|| CASE
											WHEN e.interval_backward IS NOT NULL
											THEN
												';IntervalBackward='
												|| cwms_util.get_interval_string (
														e.interval_backward
													)
										END
							END
							shef_crit_line
			  FROM	at_shef_decode a,
						mv_cwms_ts_id b,
						cwms_unit c,
						cwms_shef_time_zone d,
						at_cwms_ts_spec e,
						at_base_location f
			 WHERE		 a.ts_code = b.ts_code
						AND a.shef_unit_code = c.unit_code
						AND a.shef_time_zone_code = d.shef_time_zone_code
						AND a.ts_code = e.ts_code
						AND b.base_location_code = f.base_location_code
						AND b.net_ts_active_flag = 'T'
						AND a.data_stream_code = l_data_stream_code
			UNION
			SELECT		cwms_shef.ignore_shef_spec
						|| a.shef_loc_id
						|| '.'
						|| a.shef_pe_code
						|| '.'
						|| a.shef_tse_code
						|| '.'
						|| a.shef_duration_numeric
			  FROM	at_shef_ignore a
			 WHERE	a.data_stream_code = l_data_stream_code;
	END cat_shef_crit_lines;

	FUNCTION cat_shef_crit_lines_tab (
		p_data_stream_id	 IN VARCHAR2,
		p_db_office_id 	 IN VARCHAR2 DEFAULT NULL
	)
		RETURN cat_shef_crit_lines_tab_t
		PIPELINED
	IS
		output_row		cat_shef_crit_lines_rec_t;
		query_cursor	SYS_REFCURSOR;
	BEGIN
		cat_shef_crit_lines (query_cursor, p_data_stream_id, p_db_office_id);

		LOOP
			FETCH query_cursor
			INTO output_row;

			EXIT WHEN query_cursor%NOTFOUND;
			PIPE ROW (output_row);
		END LOOP;

		CLOSE query_cursor;

		RETURN;
	END cat_shef_crit_lines_tab;

	--===============================
	--== Data Feeds =================
	--===============================



	FUNCTION create_data_feed (p_data_feed_id 		IN VARCHAR2,
										p_data_feed_prefix	IN VARCHAR2,
										p_data_feed_desc		IN VARCHAR2,
										p_db_office_id 		IN VARCHAR2 DEFAULT NULL
									  )
		RETURN NUMBER
	IS
		l_db_office_code		NUMBER
										:= cwms_util.get_db_office_code (p_db_office_id);
		l_data_feed_id 		VARCHAR2 (32) := p_data_feed_id;
		l_data_feed_prefix	VARCHAR2 (3) := p_data_feed_prefix;
		l_data_feed_desc		VARCHAR2 (128) := p_data_feed_desc;
		l_data_feed_code		NUMBER;
	BEGIN
		INSERT
			  INTO	at_data_feed_id (data_feed_code,
											  data_feed_id,
											  db_office_code,
											  data_feed_prefix,
											  data_feed_desc
											 )
			VALUES	(
							cwms_seq.NEXTVAL,
							l_data_feed_id,
							l_db_office_code,
							l_data_feed_prefix,
							l_data_feed_desc
						)
		RETURNING	data_feed_code
			  INTO	l_data_feed_code;

		RETURN l_data_feed_code;
	END;

	-- ****************************************************************************
	-- cwms_shef.delete_data_feed is used to delete an existing data feed id.
	--
	-- p_data_feed_id(varchar2(32) - required parameter)is the id of the
	--   existing data stream to be deleted.
	--
	-- p_cascade_all (optional parameter, can be either "T" or "F" with the default
	--   being "F") -- A data feed can only be deleted if there are no
	--   SHEF specs assigned to it. You can force a deletion by setting
	--   p_cascade_all to "T", which will delete all SHEF specs associated
	--   with this data feed. WARNING - this is a very powerfull option -
	--   all SHEF specs are permanently deleted!!
	--
	-- p_db_office_id (varchar2(16) - optional parameter) is the database office
	--   id that this data feed will be/is assigned too. Normally this is
	--   left null and the user's default database office id is used.
	--



	PROCEDURE delete_data_feed (p_data_feed_id	IN VARCHAR2,
										 p_cascade_all 	IN VARCHAR2 DEFAULT 'F',
										 p_db_office_id	IN VARCHAR2 DEFAULT NULL
										)
	IS
		l_data_feed_code	 NUMBER
			:= get_data_feed_code (p_data_feed_id	 => p_data_feed_id,
										  p_db_office_id	 => p_db_office_id
										 );
		l_cascade_all		 BOOLEAN := FALSE;
		l_num 				 NUMBER;
	BEGIN
		IF UPPER (TRIM (p_db_office_id)) IN ('T', 'TRUE')
		THEN
			l_cascade_all := TRUE;
		END IF;

		SELECT	COUNT (*)
		  INTO	l_num
		  FROM	at_shef_decode
		 WHERE	data_feed_code = l_data_feed_code;

		IF l_num > 0
		THEN
			IF l_cascade_all
			THEN
				DELETE FROM   at_shef_decode
						WHERE   data_feed_code = l_data_feed_code;
			ELSE
				cwms_err.raise (
					'ERROR',
					'Unable to delete Data Feed: ' || TRIM (p_data_feed_id)
					|| ' because one or more SHEF specs are currently assigned to it. Set the p_cascade_all parameter to TRUE.'
				);
			END IF;
		END IF;

		--
		DELETE FROM   at_data_feed_id
				WHERE   data_feed_code = l_data_feed_code;
	END;

	FUNCTION rename_data_feed (p_data_feed_id_old	IN VARCHAR2,
										p_data_feed_id_new	IN VARCHAR2,
										p_db_office_id 		IN VARCHAR2 DEFAULT NULL
									  )
		RETURN NUMBER
	IS
		l_db_office_code	 NUMBER;
	BEGIN
		NULL;
	END;

	-- benign error if already assigned.

	PROCEDURE assign_data_feed (
		p_data_stream_id			IN VARCHAR2,
		p_data_feed_id 			IN VARCHAR2,
		p_stream_db_office_id	IN VARCHAR2 DEFAULT NULL,
		p_feed_db_office_id		IN VARCHAR2 DEFAULT NULL
	)
	IS
		l_data_stream_code	NUMBER
			:= get_data_stream_code (p_data_stream_id   => p_data_stream_id,
											 p_db_office_id	  => p_stream_db_office_id
											);
		l_data_feed_code		NUMBER
			:= get_data_feed_code (p_data_feed_id	 => p_data_feed_id,
										  p_db_office_id	 => p_feed_db_office_id
										 );
	BEGIN
		UPDATE	at_data_feed_id
			SET	data_stream_code = l_data_stream_code
		 WHERE	data_feed_code = l_data_feed_code;

		UPDATE	at_shef_decode
			SET	data_stream_code = l_data_stream_code
		 WHERE	data_feed_code = l_data_feed_code;
	END;



	PROCEDURE unassign_data_feed (
		p_data_feed_id 		 IN VARCHAR2,
		p_feed_db_office_id	 IN VARCHAR2 DEFAULT NULL
	)
	IS
		l_data_feed_code	 NUMBER
			:= get_data_feed_code (p_data_feed_id	 => p_data_feed_id,
										  p_db_office_id	 => p_feed_db_office_id
										 );
	BEGIN
		UPDATE	at_data_feed_id
			SET	data_stream_code = NULL
		 WHERE	data_feed_code = l_data_feed_code;

		UPDATE	at_shef_decode
			SET	data_stream_code = NULL
		 WHERE	data_feed_code = l_data_feed_code;
	END;


	PROCEDURE cat_shef_data_feeds (
		p_shef_data_feeds 	  OUT SYS_REFCURSOR,
		p_db_office_id 	  IN		VARCHAR2 DEFAULT NULL
	)
	IS
		l_db_office_code	 NUMBER;
	BEGIN
		IF p_db_office_id IS NULL
		THEN
			OPEN p_shef_data_feeds FOR
				SELECT	  a.data_feed_code, a.data_feed_id, a.data_feed_prefix,
							  a.data_feed_desc, c.data_stream_id,
							  c.active_flag data_stream_active_flag, b.office_id
					 FROM   at_data_feed_id a, cwms_office b, at_data_stream_id c
					WHERE   a.db_office_code = b.office_code
							  AND a.data_stream_code = c.data_stream_code(+)
				ORDER BY   UPPER (a.data_feed_id);
		ELSE
			l_db_office_code := cwms_util.get_db_office_code (p_db_office_id);

			OPEN p_shef_data_feeds FOR
				SELECT	  a.data_feed_code, a.data_feed_id, a.data_feed_prefix,
							  a.data_feed_desc, c.data_stream_id,
							  c.active_flag data_stream_active_flag, b.office_id
					 FROM   at_data_feed_id a, cwms_office b, at_data_stream_id c
					WHERE 		a.db_office_code = b.office_code
							  AND a.data_stream_code = c.data_stream_code(+)
							  AND a.db_office_code = l_db_office_code
				ORDER BY   UPPER (a.data_feed_id);
		END IF;
	END;

	FUNCTION cat_shef_data_feeds_tab (p_db_office_id IN VARCHAR2 DEFAULT NULL)
		RETURN cat_data_feed_tab_t
		PIPELINED
	IS
		output_row		cat_data_feed_rec_t;
		query_cursor	SYS_REFCURSOR;
	BEGIN
		cat_shef_data_feeds (query_cursor, p_db_office_id);

		LOOP
			FETCH query_cursor
			INTO output_row;

			EXIT WHEN query_cursor%NOTFOUND;
			PIPE ROW (output_row);
		END LOOP;

		CLOSE query_cursor;

		RETURN;
	END cat_shef_data_feeds_tab;


	PROCEDURE set_data_feed_prefix (
		p_data_feed_id 		IN VARCHAR2,
		p_data_feed_prefix	IN VARCHAR2,
		p_db_office_id 		IN VARCHAR2 DEFAULT NULL
	)
	IS
	BEGIN
		UPDATE	at_data_feed_id
			SET	data_feed_prefix = p_data_feed_prefix
		 WHERE	UPPER (data_feed_id) = UPPER (TRIM (p_data_feed_id))
					AND db_office_code =
							 cwms_util.get_db_office_code (p_db_office_id);
	END;


	PROCEDURE set_data_feed_desc (p_data_feed_id 	 IN VARCHAR2,
											p_data_feed_desc	 IN VARCHAR2,
											p_db_office_id 	 IN VARCHAR2 DEFAULT NULL
										  )
	IS
	BEGIN
		UPDATE	at_data_feed_id
			SET	data_feed_desc = p_data_feed_desc
		 WHERE	UPPER (data_feed_id) = UPPER (TRIM (p_data_feed_id))
					AND db_office_code =
							 cwms_util.get_db_office_code (p_db_office_id);
	END;

	PROCEDURE rename_data_feed (p_data_feed_id_old	 IN VARCHAR2,
										 p_data_feed_id_new	 IN VARCHAR2,
										 p_db_office_id		 IN VARCHAR2 DEFAULT NULL
										)
	IS
		l_data_feed_code	 NUMBER
			:= get_data_feed_code (p_data_feed_id	 => p_data_feed_id_old,
										  p_db_office_id	 => p_db_office_id
										 );
	BEGIN
		UPDATE	at_data_feed_id
			SET	data_feed_id = TRIM (p_data_feed_id_new)
		 WHERE	data_feed_code = l_data_feed_code;
	END;

	--

	PROCEDURE convert_data_stream_to_feed (
		p_data_stream_id		IN VARCHAR2,
		p_data_feed_id 		IN VARCHAR2 DEFAULT NULL,
		p_data_feed_prefix	IN VARCHAR2 DEFAULT NULL,
		p_data_feed_desc		IN VARCHAR2 DEFAULT NULL,
		p_db_office_id 		IN VARCHAR2 DEFAULT NULL
	)
	IS
		l_data_feed_id 		VARCHAR2 (32)
										:= NVL (p_data_feed_id, TRIM (p_data_stream_id));
		l_db_office_code		NUMBER
			:= cwms_util.get_db_office_code (p_office_id => p_db_office_id);
		l_data_stream_code	NUMBER
			:= get_data_stream_code (p_data_stream_id   => p_data_stream_id,
											 p_db_office_code   => l_db_office_code
											);
		l_data_feed_code		NUMBER;
	BEGIN
		l_data_feed_code :=
			create_data_feed (p_data_feed_id 		=> l_data_feed_id,
									p_data_feed_prefix	=> p_data_feed_prefix,
									p_data_feed_desc		=> p_data_feed_desc,
									p_db_office_id 		=> p_db_office_id
								  );

		UPDATE	at_shef_decode
			SET	data_feed_code = l_data_feed_code, data_stream_code = NULL
		 WHERE	data_stream_code = l_data_stream_code;

		UPDATE	at_data_stream_id
			SET	active_flag = 'F', delete_date = SYSDATE
		 WHERE	data_stream_code = l_data_stream_code;
	END;



	FUNCTION get_data_stream_mgt_style (
		p_db_office_id IN VARCHAR2 DEFAULT NULL
	)
		RETURN VARCHAR2
	IS
		l_data_stream_mgt_style   VARCHAR2 (32);
		l_db_office_id 			  VARCHAR2 (16)
			:= cwms_util.get_db_office_id (p_db_office_id);
		l_db_office_code			  NUMBER
			:= cwms_util.get_db_office_code (l_db_office_id);
	BEGIN
		RETURN cwms_properties.get_property (
					 p_category 	=> 'Office_Pref.' || l_db_office_id,
					 p_id 			=> 'DATA_STREAM_MGT_STYLE',
					 p_default		=> 'DATA STREAMS',
					 p_office_id	=> p_db_office_id
				 );
	END;



	PROCEDURE set_data_stream_mgt_style (
		p_data_stream_mgt_style   IN VARCHAR2,
		p_db_office_id 			  IN VARCHAR2 DEFAULT NULL
	)
	IS
		l_data_stream_mgt_style   VARCHAR2 (32);
		l_mgt_style 				  VARCHAR2 (32)
											  := UPPER (TRIM (p_data_stream_mgt_style));
		l_cur 						  SYS_REFCURSOR;
		l_db_office_id 			  VARCHAR2 (16)
			:= cwms_util.get_db_office_id (p_db_office_id);
		l_db_office_code			  NUMBER
			:= cwms_util.get_db_office_code (l_db_office_id);
		l_data_stream_id			  VARCHAR2 (16);
		l_data_stream_desc		  VARCHAR2 (128);
		l_delete_date				  DATE;
	BEGIN
		l_data_stream_mgt_style :=
			get_data_stream_mgt_style (p_db_office_id => p_db_office_id);

		IF l_mgt_style = l_data_stream_mgt_style
		THEN
			-- you're already where we want to be, so return.
			RETURN;
		END IF;

		--
		--
		IF l_mgt_style = 'DATA FEEDS'
		THEN
			cwms_properties.set_property (
				p_category	  => 'Office_Pref.' || l_db_office_id,
				p_id			  => 'DATA_STREAM_MGT_STYLE',
				p_value		  => 'DATA FEEDS',
				p_comment	  => 'Use NWD Data Feed Managment Scheme.',
				p_office_id   => p_db_office_id
			);


			OPEN l_cur FOR
				SELECT	data_stream_id, data_stream_desc
				  FROM	at_data_stream_id
				 WHERE	db_office_code = l_db_office_code
							AND delete_date IS NULL;

			LOOP
				FETCH l_cur
				INTO l_data_stream_id, l_data_stream_desc;

				EXIT WHEN l_cur%NOTFOUND;

				convert_data_stream_to_feed (
					p_data_stream_id		=> l_data_stream_id,
					p_data_feed_id 		=> NULL,
					p_data_feed_prefix	=> NULL,
					p_data_feed_desc		=> l_data_stream_desc,
					p_db_office_id 		=> p_db_office_id
				);
			END LOOP;

			CLOSE l_cur;
		ELSIF l_mgt_style = 'DATA STREAMS'
		THEN
			l_delete_date := SYSDATE;

			OPEN l_cur FOR
				SELECT	data_stream_id
				  FROM	at_data_stream_id
				 WHERE	db_office_code = l_db_office_code
							AND delete_date IS NULL;

			LOOP
				FETCH l_cur
				INTO l_data_stream_id;

				EXIT WHEN l_cur%NOTFOUND;


				store_shef_crit_file (p_data_stream_id   => l_data_stream_id,
											 p_db_office_id	  => l_db_office_id
											);
			END LOOP;



			DELETE FROM   at_shef_decode
					WHERE   data_feed_code IN
								  (SELECT	data_feed_code
									  FROM	at_data_feed_id
									 WHERE	db_office_code = l_db_office_code);

			DELETE FROM   at_shef_decode
					WHERE   data_stream_code IN
								  (SELECT	data_stream_code
									  FROM	at_data_stream_id
									 WHERE	db_office_code = l_db_office_code);

			UPDATE	at_data_stream_id
				SET	delete_date = l_delete_date
			 WHERE	db_office_code = l_db_office_code;

			DELETE FROM   at_data_feed_id
					WHERE   db_office_code = l_db_office_code;

			cwms_properties.set_property (
				p_category	  => 'Office_Pref.' || l_db_office_id,
				p_id			  => 'DATA_STREAM_MGT_STYLE',
				p_value		  => 'DATA STREAMS',
				p_comment	  => 'Use Standard CWMS Data Streams Managment Scheme.',
				p_office_id   => p_db_office_id
			);
		ELSE
			cwms_err.raise (
				'ERROR',
				TRIM (p_data_stream_mgt_style)
				|| ' is not a recognized Data Stream Managment Style.'
			);
		END IF;
	END;
--
END cwms_shef;
/