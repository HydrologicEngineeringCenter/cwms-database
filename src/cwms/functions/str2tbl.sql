CREATE OR REPLACE FUNCTION str2tbl (p_str     IN VARCHAR2,
                                    p_delim   IN VARCHAR2 DEFAULT ',')
   RETURN str2tblType
   PIPELINED
AS
   l_str   LONG DEFAULT p_str || p_delim;
   l_n     NUMBER;
BEGIN
   LOOP
      l_n := INSTR (l_str, p_delim);
      EXIT WHEN (NVL (l_n, 0) = 0);
      PIPE ROW (LTRIM (RTRIM (SUBSTR (l_str, 1, l_n - 1))));
      l_str := SUBSTR (l_str, l_n + 1);
   END LOOP;

   RETURN;
END;
/
