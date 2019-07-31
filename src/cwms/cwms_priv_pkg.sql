/* Formatted on 2007/03/30 12:38 (Formatter Plus v4.8.8) */
CREATE OR REPLACE PACKAGE cwms_priv AUTHID CURRENT_USER
AS
   PROCEDURE passwd (p_username IN VARCHAR2, p_password IN VARCHAR2);
   PRAGMA DEPRECATE (passwd, 'This method is no longer supported through client-side API. All Oracle account administration is done by the Oracle DBA.');
END cwms_priv;
/