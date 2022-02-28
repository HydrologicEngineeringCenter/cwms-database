create or replace trigger at_app_log_ingest_control_t01
before insert or update
       on at_app_log_ingest_control
       for each row
declare
   l_ym           yminterval_unconstrained;
   l_ds           dsinterval_unconstrained;
   l_min_max_size integer := 1024;
begin
   -----------------------
   -- validate duration --
   -----------------------
   cwms_util.duration_to_interval(l_ym, l_ds, :new.max_entry_age);
   ----------------------------
   -- validate max_file_size --
   ----------------------------
   if :new.max_file_size < l_min_max_size then
   cwms_err.raise(
      'ERROR',
      'AT_APP_LOG_INGEST_CONTROL.MAX_FILE_SIZE must be at least '||l_min_max_size);
   end if;
   --------------------
   -- validate flags --
   --------------------
   :new.ingest_sub_dirs := upper(:new.ingest_sub_dirs);
   if :new.ingest_sub_dirs not in ('T', 'F') then
      cwms_err.raise('ERROR', 'AT_APP_LOG_INGEST_CONTROL.INGEST_SUB_DIRS must be ''T'' or ''F''');
   end if;
   :new.delete_empty_files := upper(:new.delete_empty_files);
   if :new.delete_empty_files not in ('T', 'F') then
      cwms_err.raise('ERROR', 'AT_APP_LOG_INGEST_CONTROL.DELETE_EMPTY_FILES must be ''T'' or ''F''');
   end if;
end at_app_log_ingest_control_t01;
/