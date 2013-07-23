/* Formatted on 6/16/2011 8:41:17 AM (QP5 v5.163.1008.3004) */
CREATE OR REPLACE PACKAGE BODY cwms_ts_id
AS
	PROCEDURE refresh_at_cwms_ts_id
	IS
	BEGIN
		EXECUTE IMMEDIATE 'truncate table at_cwms_ts_id';

		--
		INSERT INTO   at_cwms_ts_id
			SELECT	*
			  FROM	zav_cwms_ts_id;
	END refresh_at_cwms_ts_id;

	PROCEDURE get_denorm_params_acts (
		p_cwms_ts_spec   IN		at_cwms_ts_spec%ROWTYPE,
		p_cwms_ts_id		  OUT at_cwms_ts_id%ROWTYPE
	)
	IS
	BEGIN
		p_cwms_ts_id.ts_code := p_cwms_ts_spec.ts_code;
		p_cwms_ts_id.location_code := p_cwms_ts_spec.location_code;
		p_cwms_ts_id.parameter_code := p_cwms_ts_spec.parameter_code;
		p_cwms_ts_id.version_id := p_cwms_ts_spec.version;
		p_cwms_ts_id.interval_utc_offset := p_cwms_ts_spec.interval_utc_offset;
		p_cwms_ts_id.ts_active_flag := p_cwms_ts_spec.active_flag;
		p_cwms_ts_id.version_flag := p_cwms_ts_spec.version_flag;

		--
		SELECT	cbp.base_parameter_id, ap.sub_parameter_id, u.unit_id,
					cap.abstract_param_id
		  INTO	p_cwms_ts_id.base_parameter_id, p_cwms_ts_id.sub_parameter_id,
					p_cwms_ts_id.unit_id, p_cwms_ts_id.abstract_param_id
		  FROM	at_parameter ap
					JOIN cwms_base_parameter cbp
						USING (base_parameter_code)
					JOIN cwms_unit u
						USING (unit_code)
					JOIN cwms_abstract_parameter cap
						ON (u.abstract_param_code = cap.abstract_param_code)
		 WHERE	parameter_code = p_cwms_ts_id.parameter_code;

		--
		SELECT	cpt.parameter_type_id
		  INTO	p_cwms_ts_id.parameter_type_id
		  FROM	cwms_parameter_type cpt
		 WHERE	parameter_type_code = p_cwms_ts_spec.parameter_type_code;

		--
		SELECT	ci.interval_id, ci.interval
		  INTO	p_cwms_ts_id.interval_id, p_cwms_ts_id.interval
		  FROM	cwms_interval ci
		 WHERE	interval_code = p_cwms_ts_spec.interval_code;

		--
		SELECT	cd.duration_id
		  INTO	p_cwms_ts_id.duration_id
		  FROM	cwms_duration cd
		 WHERE	duration_code = p_cwms_ts_spec.duration_code;

		--
		SELECT	co.office_id, abl.base_location_id, apl.sub_location_id,
					NVL (apl.active_flag, 'T'), abl.db_office_code,
					base_location_code, NVL (abl.active_flag, 'T')
		  INTO	p_cwms_ts_id.db_office_id, p_cwms_ts_id.base_location_id,
					p_cwms_ts_id.sub_location_id, p_cwms_ts_id.loc_active_flag,
					p_cwms_ts_id.db_office_code, p_cwms_ts_id.base_location_code,
					p_cwms_ts_id.base_loc_active_flag
		  FROM	at_physical_location apl
					JOIN at_base_location abl
						USING (base_location_code)
					JOIN cwms_office co
						ON (co.office_code = abl.db_office_code)
		 WHERE	location_code = p_cwms_ts_id.location_code;

		--
		p_cwms_ts_id.location_id :=
				p_cwms_ts_id.base_location_id
			|| SUBSTR ('-', 1, LENGTH (p_cwms_ts_id.sub_location_id))
			|| p_cwms_ts_id.sub_location_id;
		--
		p_cwms_ts_id.parameter_id :=
				p_cwms_ts_id.base_parameter_id
			|| SUBSTR ('-', 1, LENGTH (p_cwms_ts_id.sub_parameter_id))
			|| p_cwms_ts_id.sub_parameter_id;
		--
		p_cwms_ts_id.cwms_ts_id :=
				p_cwms_ts_id.location_id
			|| '.'
			|| p_cwms_ts_id.parameter_id
			|| '.'
			|| p_cwms_ts_id.parameter_type_id
			|| '.'
			|| p_cwms_ts_id.interval_id
			|| '.'
			|| p_cwms_ts_id.duration_id
			|| '.'
			|| p_cwms_ts_id.version_id;
		--
		p_cwms_ts_id.net_ts_active_flag :=
			CASE
				WHEN		p_cwms_ts_id.base_loc_active_flag = 'T'
					  AND p_cwms_ts_id.loc_active_flag = 'T'
					  AND p_cwms_ts_id.ts_active_flag = 'T'
				THEN
					'T'
				ELSE
					'F'
			END;
	END get_denorm_params_acts;

	PROCEDURE get_denorm_params_apl (
		p_cwms_ts_spec 		  IN		at_cwms_ts_spec%ROWTYPE,
		p_loc_active_flag 	  IN		VARCHAR2,
		p_sub_location_id 	  IN		VARCHAR2,
		p_base_location_code   IN		NUMBER,
		p_cwms_ts_id				  OUT at_cwms_ts_id%ROWTYPE
	)
	IS
	BEGIN
		BEGIN
			SELECT	*
			  INTO	p_cwms_ts_id
			  FROM	at_cwms_ts_id
			 WHERE	ts_code = p_cwms_ts_spec.ts_code;

			--
			p_cwms_ts_id.base_location_code := p_base_location_code;
		--
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				--
				p_cwms_ts_id.base_location_code := p_base_location_code;
				--
				p_cwms_ts_id.ts_code := p_cwms_ts_spec.ts_code;
				p_cwms_ts_id.location_code := p_cwms_ts_spec.location_code;
				p_cwms_ts_id.parameter_code := p_cwms_ts_spec.parameter_code;
				p_cwms_ts_id.version_id := p_cwms_ts_spec.version;
				p_cwms_ts_id.interval_utc_offset :=
					p_cwms_ts_spec.interval_utc_offset;
				p_cwms_ts_id.ts_active_flag := p_cwms_ts_spec.active_flag;
				p_cwms_ts_id.version_flag := p_cwms_ts_spec.version_flag;



				SELECT	cbp.base_parameter_id, ap.sub_parameter_id, u.unit_id,
							cap.abstract_param_id
				  INTO	p_cwms_ts_id.base_parameter_id,
							p_cwms_ts_id.sub_parameter_id, p_cwms_ts_id.unit_id,
							p_cwms_ts_id.abstract_param_id
				  FROM	at_parameter ap
							JOIN cwms_base_parameter cbp
								USING (base_parameter_code)
							JOIN cwms_unit u
								USING (unit_code)
							JOIN cwms_abstract_parameter cap
								ON (u.abstract_param_code = cap.abstract_param_code)
				 WHERE	parameter_code = p_cwms_ts_spec.parameter_code;

				--
				p_cwms_ts_id.parameter_id :=
						p_cwms_ts_id.base_parameter_id
					|| SUBSTR ('-', 1, LENGTH (p_cwms_ts_id.sub_parameter_id))
					|| p_cwms_ts_id.sub_parameter_id;

				--
				SELECT	cpt.parameter_type_id
				  INTO	p_cwms_ts_id.parameter_type_id
				  FROM	cwms_parameter_type cpt
				 WHERE	parameter_type_code = p_cwms_ts_spec.parameter_type_code;

				--
				SELECT	ci.interval_id, ci.interval
				  INTO	p_cwms_ts_id.interval_id, p_cwms_ts_id.interval
				  FROM	cwms_interval ci
				 WHERE	interval_code = p_cwms_ts_spec.interval_code;

				--
				SELECT	cd.duration_id
				  INTO	p_cwms_ts_id.duration_id
				  FROM	cwms_duration cd
				 WHERE	duration_code = p_cwms_ts_spec.duration_code;

				--
				SELECT	co.office_id, abl.base_location_id, abl.db_office_code,
							NVL (abl.active_flag, 'T')
				  INTO	p_cwms_ts_id.db_office_id, p_cwms_ts_id.base_location_id,
							p_cwms_ts_id.db_office_code,
							p_cwms_ts_id.base_loc_active_flag
				  FROM		at_base_location abl
							JOIN
								cwms_office co
							ON (co.office_code = abl.db_office_code)
				 WHERE	base_location_code = p_cwms_ts_id.base_location_code;
		END;


		p_cwms_ts_id.sub_location_id := p_sub_location_id;
		p_cwms_ts_id.loc_active_flag := p_loc_active_flag;
		--
		p_cwms_ts_id.location_id :=
				p_cwms_ts_id.base_location_id
			|| SUBSTR ('-', 1, LENGTH (p_cwms_ts_id.sub_location_id))
			|| p_cwms_ts_id.sub_location_id;
		--
		p_cwms_ts_id.cwms_ts_id :=
				p_cwms_ts_id.location_id
			|| '.'
			|| p_cwms_ts_id.parameter_id
			|| '.'
			|| p_cwms_ts_id.parameter_type_id
			|| '.'
			|| p_cwms_ts_id.interval_id
			|| '.'
			|| p_cwms_ts_id.duration_id
			|| '.'
			|| p_cwms_ts_id.version_id;
		--
		p_cwms_ts_id.net_ts_active_flag :=
			CASE
				WHEN		p_cwms_ts_id.base_loc_active_flag = 'T'
					  AND p_cwms_ts_id.loc_active_flag = 'T'
					  AND p_cwms_ts_id.ts_active_flag = 'T'
				THEN
					'T'
				ELSE
					'F'
			END;
	END get_denorm_params_apl;

	PROCEDURE delete_from_at_cwms_ts_id (p_ts_code IN NUMBER)
	IS
	BEGIN
		DELETE FROM   at_cwms_ts_id
				WHERE   ts_code = p_ts_code;
	END delete_from_at_cwms_ts_id;

	PROCEDURE merge_into_at_cwms_ts_id (p_cwms_ts_id IN at_cwms_ts_id%ROWTYPE)
	IS
		l_rowcnt   NUMBER;
	BEGIN
		SELECT	COUNT (*)
		  INTO	l_rowcnt
		  FROM	at_cwms_ts_id
		 WHERE	ts_code = p_cwms_ts_id.ts_code;

		IF l_rowcnt = 0
		THEN
			INSERT INTO   at_cwms_ts_id
				  VALUES   p_cwms_ts_id;
		ELSE
			UPDATE	at_cwms_ts_id
				SET	db_office_code = p_cwms_ts_id.db_office_code,
						base_location_code = p_cwms_ts_id.base_location_code,
						location_code = p_cwms_ts_id.location_code,
						loc_active_flag = p_cwms_ts_id.loc_active_flag,
						parameter_code = p_cwms_ts_id.parameter_code,
						ts_active_flag = p_cwms_ts_id.ts_active_flag,
						net_ts_active_flag = p_cwms_ts_id.net_ts_active_flag,
						db_office_id = p_cwms_ts_id.db_office_id,
						cwms_ts_id = p_cwms_ts_id.cwms_ts_id,
						unit_id = p_cwms_ts_id.unit_id,
						abstract_param_id = p_cwms_ts_id.abstract_param_id,
						base_location_id = p_cwms_ts_id.base_location_id,
						sub_location_id = p_cwms_ts_id.sub_location_id,
						location_id = p_cwms_ts_id.location_id,
						base_parameter_id = p_cwms_ts_id.base_parameter_id,
						sub_parameter_id = p_cwms_ts_id.sub_parameter_id,
						parameter_id = p_cwms_ts_id.parameter_id,
						parameter_type_id = p_cwms_ts_id.parameter_type_id,
						interval_id = p_cwms_ts_id.interval_id,
						duration_id = p_cwms_ts_id.duration_id,
						version_id = p_cwms_ts_id.version_id,
						interval = p_cwms_ts_id.interval,
						interval_utc_offset = p_cwms_ts_id.interval_utc_offset,
						version_flag = p_cwms_ts_id.version_flag
			 WHERE	ts_code = p_cwms_ts_id.ts_code;
		END IF;
	END merge_into_at_cwms_ts_id;

	PROCEDURE touched_acts (p_cwms_ts_spec IN at_cwms_ts_spec%ROWTYPE)
	IS
		l_cwms_ts_id	at_cwms_ts_id%ROWTYPE;
		l_rowcnt 		NUMBER;
	BEGIN
		IF p_cwms_ts_spec.delete_date IS NULL
		THEN
			get_denorm_params_acts (p_cwms_ts_spec, l_cwms_ts_id);

			merge_into_at_cwms_ts_id (l_cwms_ts_id);
		ELSE
			delete_from_at_cwms_ts_id (p_cwms_ts_spec.ts_code);
		END IF;
	END touched_acts;

	PROCEDURE touched_apl (p_location_code 		 IN NUMBER,
								  p_loc_active_flag		 IN VARCHAR2,
								  p_sub_location_id		 IN VARCHAR2,
								  p_base_location_code	 IN NUMBER
								 )
	IS
		l_cwms_ts_id	at_cwms_ts_id%ROWTYPE;
	BEGIN
		FOR l_cwms_ts_spec_rec
			IN (SELECT	 *
					FROM	 at_cwms_ts_spec
				  WHERE	 location_code = p_location_code AND delete_date IS NULL)
		LOOP
			get_denorm_params_apl (
				p_cwms_ts_spec 		  => l_cwms_ts_spec_rec,
				p_loc_active_flag 	  => p_loc_active_flag,
				p_sub_location_id 	  => p_sub_location_id,
				p_base_location_code   => p_base_location_code,
				p_cwms_ts_id			  => l_cwms_ts_id
			);
			merge_into_at_cwms_ts_id (l_cwms_ts_id);
		END LOOP;
	END touched_apl;

	PROCEDURE get_denorm_params_abl (
		p_cwms_ts_spec 			 IN	  at_cwms_ts_spec%ROWTYPE,
		p_db_office_code			 IN	  NUMBER,
		p_base_loc_active_flag	 IN	  VARCHAR2,
		p_base_location_code 	 IN	  NUMBER,
		p_base_location_id		 IN	  VARCHAR2,
		p_cwms_ts_id					 OUT at_cwms_ts_id%ROWTYPE
	)
	IS
	BEGIN
		BEGIN
			SELECT	*
			  INTO	p_cwms_ts_id
			  FROM	at_cwms_ts_id
			 WHERE	ts_code = p_cwms_ts_spec.ts_code;
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				--
				p_cwms_ts_id.db_office_code := p_db_office_code;
				--
				p_cwms_ts_id.ts_code := p_cwms_ts_spec.ts_code;
				p_cwms_ts_id.location_code := p_cwms_ts_spec.location_code;
				p_cwms_ts_id.parameter_code := p_cwms_ts_spec.parameter_code;
				p_cwms_ts_id.version_id := p_cwms_ts_spec.version;
				p_cwms_ts_id.interval_utc_offset :=
					p_cwms_ts_spec.interval_utc_offset;
				p_cwms_ts_id.ts_active_flag := p_cwms_ts_spec.active_flag;
				p_cwms_ts_id.version_flag := p_cwms_ts_spec.version_flag;

				--
				SELECT	cbp.base_parameter_id, ap.sub_parameter_id, u.unit_id,
							cap.abstract_param_id
				  INTO	p_cwms_ts_id.base_parameter_id,
							p_cwms_ts_id.sub_parameter_id, p_cwms_ts_id.unit_id,
							p_cwms_ts_id.abstract_param_id
				  FROM	at_parameter ap
							JOIN cwms_base_parameter cbp
								USING (base_parameter_code)
							JOIN cwms_unit u
								USING (unit_code)
							JOIN cwms_abstract_parameter cap
								ON (u.abstract_param_code = cap.abstract_param_code)
				 WHERE	parameter_code = p_cwms_ts_spec.parameter_code;

				--
				p_cwms_ts_id.parameter_id :=
						p_cwms_ts_id.base_parameter_id
					|| SUBSTR ('-', 1, LENGTH (p_cwms_ts_id.sub_parameter_id))
					|| p_cwms_ts_id.sub_parameter_id;


				--
				SELECT	cpt.parameter_type_id
				  INTO	p_cwms_ts_id.parameter_type_id
				  FROM	cwms_parameter_type cpt
				 WHERE	parameter_type_code = p_cwms_ts_spec.parameter_type_code;

				--
				SELECT	ci.interval_id, ci.interval
				  INTO	p_cwms_ts_id.interval_id, p_cwms_ts_id.interval
				  FROM	cwms_interval ci
				 WHERE	interval_code = p_cwms_ts_spec.interval_code;

				--
				SELECT	cd.duration_id
				  INTO	p_cwms_ts_id.duration_id
				  FROM	cwms_duration cd
				 WHERE	duration_code = p_cwms_ts_spec.duration_code;

				--
				SELECT	office_id
				  INTO	p_cwms_ts_id.db_office_id
				  FROM	cwms_office
				 WHERE	office_code = p_cwms_ts_id.db_office_code;

				--
				SELECT	apl.sub_location_id, NVL (apl.active_flag, 'T')
				  INTO	p_cwms_ts_id.sub_location_id,
							p_cwms_ts_id.loc_active_flag
				  FROM	at_physical_location apl
				 WHERE	location_code = p_cwms_ts_id.location_code;
		END;

		--
		p_cwms_ts_id.base_loc_active_flag := p_base_loc_active_flag;
		p_cwms_ts_id.base_location_code := p_base_location_code;
		p_cwms_ts_id.base_location_id := p_base_location_id;
		--
		p_cwms_ts_id.location_id :=
				p_cwms_ts_id.base_location_id
			|| SUBSTR ('-', 1, LENGTH (p_cwms_ts_id.sub_location_id))
			|| p_cwms_ts_id.sub_location_id;
		--
		p_cwms_ts_id.cwms_ts_id :=
				p_cwms_ts_id.location_id
			|| '.'
			|| p_cwms_ts_id.parameter_id
			|| '.'
			|| p_cwms_ts_id.parameter_type_id
			|| '.'
			|| p_cwms_ts_id.interval_id
			|| '.'
			|| p_cwms_ts_id.duration_id
			|| '.'
			|| p_cwms_ts_id.version_id;
		--
		p_cwms_ts_id.net_ts_active_flag :=
			CASE
				WHEN		p_cwms_ts_id.base_loc_active_flag = 'T'
					  AND p_cwms_ts_id.loc_active_flag = 'T'
					  AND p_cwms_ts_id.ts_active_flag = 'T'
				THEN
					'T'
				ELSE
					'F'
			END;
	END get_denorm_params_abl;

	PROCEDURE touched_abl (p_db_office_code			IN NUMBER,
								  p_base_location_code		IN NUMBER,
								  p_base_loc_active_flag	IN VARCHAR2,
								  p_base_location_id 		IN VARCHAR2
								 )
	IS
		l_cwms_ts_id	at_cwms_ts_id%ROWTYPE;
	BEGIN
		FOR l_cwms_ts_spec_rec
			IN (SELECT	 *
					FROM	 at_cwms_ts_spec
				  WHERE	 location_code IN
								 (SELECT   location_code
									 FROM   at_physical_location
									WHERE   base_location_code IN p_base_location_code)
							 AND delete_date IS NULL)
		LOOP
			get_denorm_params_abl (
				p_cwms_ts_spec 			 => l_cwms_ts_spec_rec,
				p_db_office_code			 => p_db_office_code,
				p_base_loc_active_flag	 => p_base_loc_active_flag,
				p_base_location_code 	 => p_base_location_code,
				p_base_location_id		 => p_base_location_id,
				p_cwms_ts_id				 => l_cwms_ts_id
			);
			merge_into_at_cwms_ts_id (l_cwms_ts_id);
		END LOOP;
	END touched_abl;

	PROCEDURE get_denorm_params_api (
		p_cwms_ts_spec 			IN 	 at_cwms_ts_spec%ROWTYPE,
		p_base_parameter_code	IN 	 NUMBER,
		p_sub_parameter_id		IN 	 VARCHAR2,
		p_cwms_ts_id					OUT at_cwms_ts_id%ROWTYPE
	)
	IS
	BEGIN
		BEGIN
			SELECT	*
			  INTO	p_cwms_ts_id
			  FROM	at_cwms_ts_id
			 WHERE	ts_code = p_cwms_ts_spec.ts_code;

			p_cwms_ts_id.sub_parameter_id := p_sub_parameter_id;
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				p_cwms_ts_id.sub_parameter_id := p_sub_parameter_id;
				--
				p_cwms_ts_id.parameter_code := p_cwms_ts_spec.parameter_code;
				--
				p_cwms_ts_id.ts_code := p_cwms_ts_spec.ts_code;
				p_cwms_ts_id.location_code := p_cwms_ts_spec.location_code;
				p_cwms_ts_id.version_id := p_cwms_ts_spec.version;
				p_cwms_ts_id.interval_utc_offset :=
					p_cwms_ts_spec.interval_utc_offset;
				p_cwms_ts_id.ts_active_flag := p_cwms_ts_spec.active_flag;
				p_cwms_ts_id.version_flag := p_cwms_ts_spec.version_flag;

				--
				SELECT	cbp.base_parameter_id, u.unit_id, cap.abstract_param_id
				  INTO	p_cwms_ts_id.base_parameter_id, p_cwms_ts_id.unit_id,
							p_cwms_ts_id.abstract_param_id
				  FROM	cwms_base_parameter cbp
							JOIN cwms_unit u
								USING (unit_code)
							JOIN cwms_abstract_parameter cap
								ON (u.abstract_param_code = cap.abstract_param_code)
				 WHERE	cbp.base_parameter_code = p_base_parameter_code;

				--
				SELECT	cpt.parameter_type_id
				  INTO	p_cwms_ts_id.parameter_type_id
				  FROM	cwms_parameter_type cpt
				 WHERE	parameter_type_code = p_cwms_ts_spec.parameter_type_code;

				--
				SELECT	ci.interval_id, ci.interval
				  INTO	p_cwms_ts_id.interval_id, p_cwms_ts_id.interval
				  FROM	cwms_interval ci
				 WHERE	interval_code = p_cwms_ts_spec.interval_code;

				--
				SELECT	cd.duration_id
				  INTO	p_cwms_ts_id.duration_id
				  FROM	cwms_duration cd
				 WHERE	duration_code = p_cwms_ts_spec.duration_code;

				--
				SELECT	co.office_id, abl.base_location_id, apl.sub_location_id,
							NVL (apl.active_flag, 'T'), abl.db_office_code,
							base_location_code, NVL (abl.active_flag, 'T')
				  INTO	p_cwms_ts_id.db_office_id, p_cwms_ts_id.base_location_id,
							p_cwms_ts_id.sub_location_id,
							p_cwms_ts_id.loc_active_flag,
							p_cwms_ts_id.db_office_code,
							p_cwms_ts_id.base_location_code,
							p_cwms_ts_id.base_loc_active_flag
				  FROM	at_physical_location apl
							JOIN at_base_location abl
								USING (base_location_code)
							JOIN cwms_office co
								ON (co.office_code = abl.db_office_code)
				 WHERE	location_code = p_cwms_ts_id.location_code;

				--
				p_cwms_ts_id.location_id :=
						p_cwms_ts_id.base_location_id
					|| SUBSTR ('-', 1, LENGTH (p_cwms_ts_id.sub_location_id))
					|| p_cwms_ts_id.sub_location_id;
		--

		END;

		--
		p_cwms_ts_id.parameter_id :=
				p_cwms_ts_id.base_parameter_id
			|| SUBSTR ('-', 1, LENGTH (p_cwms_ts_id.sub_parameter_id))
			|| p_cwms_ts_id.sub_parameter_id;


		p_cwms_ts_id.cwms_ts_id :=
				p_cwms_ts_id.location_id
			|| '.'
			|| p_cwms_ts_id.parameter_id
			|| '.'
			|| p_cwms_ts_id.parameter_type_id
			|| '.'
			|| p_cwms_ts_id.interval_id
			|| '.'
			|| p_cwms_ts_id.duration_id
			|| '.'
			|| p_cwms_ts_id.version_id;
		--
		p_cwms_ts_id.net_ts_active_flag :=
			CASE
				WHEN		p_cwms_ts_id.base_loc_active_flag = 'T'
					  AND p_cwms_ts_id.loc_active_flag = 'T'
					  AND p_cwms_ts_id.ts_active_flag = 'T'
				THEN
					'T'
				ELSE
					'F'
			END;
	END get_denorm_params_api;

	PROCEDURE touched_api (p_parameter_code		  IN NUMBER,
								  p_base_parameter_code   IN NUMBER,
								  p_sub_parameter_id 	  IN VARCHAR2
								 )
	IS
		l_cwms_ts_id	at_cwms_ts_id%ROWTYPE;
	BEGIN
		FOR l_cwms_ts_spec_rec
			IN (SELECT	 *
					FROM	 at_cwms_ts_spec
				  WHERE	 parameter_code = p_parameter_code
							 AND delete_date IS NULL)
		LOOP
			get_denorm_params_api (
				p_cwms_ts_spec 			=> l_cwms_ts_spec_rec,
				p_base_parameter_code	=> p_base_parameter_code,
				p_sub_parameter_id		=> p_sub_parameter_id,
				p_cwms_ts_id				=> l_cwms_ts_id
			);
			merge_into_at_cwms_ts_id (l_cwms_ts_id);
		END LOOP;
	END touched_api;
END cwms_ts_id;
/
show errors
