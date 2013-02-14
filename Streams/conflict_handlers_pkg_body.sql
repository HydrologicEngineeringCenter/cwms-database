-- Create the package body:

CREATE OR REPLACE PACKAGE BODY conflict_handlers
AS
   PROCEDURE resolve_conflicts (
      MESSAGE             IN ANYDATA,
      error_stack_depth   IN NUMBER,
      error_numbers       IN DBMS_UTILITY.number_array,
      error_messages      IN emsg_array)
   IS
      lcr               SYS.lcr$_row_record;
      ret               PLS_INTEGER;
      vc                VARCHAR2 (30);
      errlog_rec        errorlog%ROWTYPE;
      l_anydata         ANYDATA;
      l_apply_name      VARCHAR2 (30);
      l_err_code        NUMBER;
      l_err_msg         VARCHAR2 (2000);
      l_old_values      SYS.lcr$_row_list;
      l_new_values      SYS.lcr$_row_list;
      l_change_values   SYS.lcr$_row_list;
   BEGIN
      -- Access the error number from the top of the stack.
      errlog_rec.text := NULL;

      -- Check for the ORA error, and gather relevant information
      IF error_numbers (1) = 1             -- Primary key constraint violation
      THEN
         l_anydata := DBMS_STREAMS.GET_INFORMATION ('CONSTRAINT_NAME');
         ret := l_anydata.GetVarchar2 (errlog_rec.text);
      END IF;

      -- Get the name of the capture process (Sender)
      -- and the name of the apply process.
      l_anydata := DBMS_STREAMS.get_information ('SENDER');
      ret := l_anydata.getvarchar2 (errlog_rec.sender);
      l_apply_name := DBMS_STREAMS.get_streams_name ();

      -- Access the LCR to gather other relevant information to log.
      ret := MESSAGE.getobject (lcr);
      errlog_rec.errnum := error_numbers (1);
      errlog_rec.errmsg := error_messages (1);
      errlog_rec.object_name := lcr.get_object_name ();
      errlog_rec.command_type := lcr.get_command_type ();

      -- Insert all relevant information in the errorlog table.
      -- Commit will be automatically done. No need to commit.
      INSERT INTO &STREAMS_USER..errorlog
           VALUES (SYSDATE,
                   l_apply_name,
                   errlog_rec.sender,
                   errlog_rec.object_name,
                   errlog_rec.command_type,
                   errlog_rec.errnum,
                   errlog_rec.errmsg,
                   errlog_rec.text,
                   lcr);

      -- Check the Command Type and take action to resolve conflict.

      IF lcr.get_command_type = 'INSERT' AND error_numbers (1) = 1 -- Primary Key constraint violation
      THEN
         NULL;                             -- Ignore the LCR as the row exists
      END IF;

      IF lcr.get_command_type = 'DELETE' AND error_numbers (1) = 1403 -- Row not found to delete.
      THEN
         NULL;                                              -- Ignore the LCR.
      END IF;

      -- Take action if row did not exist for UPDATE.
      -- The pre-built conflict handler should handle the conflict if
      -- the row was found with column values mismatched.
      -- Following logic
      IF lcr.get_command_type = 'UPDATE' AND error_numbers (1) = 1403
      THEN
         -- Since all columns are supplementally logged, the
         -- original LCR for UPDATE will contain all the
         -- columns of the row with old and new values.
         -- Save all the old and all the new values.
         l_old_values := lcr.get_values ('OLD', 'Y');
         l_new_values := lcr.get_values ('NEW', 'Y');

         -- Prepare to overlay old values with changed new values
         l_change_values := l_old_values;

         -- Loop through old and new values to combine unchanged and changed
         -- values in the LCR.
         FOR i IN 1 .. l_new_values.COUNT
         LOOP
            FOR j IN 1 .. l_change_values.COUNT
            LOOP
               IF l_new_values (i).column_name =
                     l_change_values (j).column_name
               THEN
                  l_change_values (j).data := l_new_values (i).data;
               END IF;
            END LOOP;
         END LOOP;

         -- Set the changed values in the LCR as new values.
         lcr.set_values ('NEW', l_change_values);
         -- For insert we must remove all old columns and values.
         lcr.set_values ('OLD', NULL);
         -- Change the LCR command type to insert the row.
         lcr.set_command_type ('INSERT');
         -- Execute the LCR with conflict resolution set to true.
         lcr.execute (TRUE);
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         l_err_code := SQLCODE;
         l_err_msg := SUBSTR (SQLERRM, 1, 2000);

         INSERT INTO &STREAMS_USER..errorlog (logdate,
                                         errnum,
                                         errmsg,
                                         text)
              VALUES (SYSDATE,
                      l_err_code,
                      l_err_msg,
                      errlog_rec.text);
   END resolve_conflicts;
END conflict_handlers;
/

SHOW ERRORS
