DECLARE
    l_pkg_body_text   VARCHAR2 (2056)
        := '
CREATE OR REPLACE PACKAGE BODY cwms_crypt
AS
    l_cwms_key          RAW (64)
        := HEXTORAW (
               ''8FE6C72733B0B4AA41051BA4FC625CDD3DAF1A54BE0328AF2658B9CA36964275'');
    l_cwms_iv           RAW (64) := HEXTORAW (''29EFBC9A67418F7E'');
    l_encryption_type   PLS_INTEGER
        :=                                            -- total encryption type
             DBMS_CRYPTO.ENCRYPT_AES256
           + DBMS_CRYPTO.CHAIN_CBC
           + DBMS_CRYPTO.PAD_PKCS5;

    FUNCTION ENCRYPT (val VARCHAR2)
        RETURN RAW
    IS
    BEGIN
	cwms_sec.confirm_cwms_schema_user;
        RETURN DBMS_CRYPTO.ENCRYPT (src   => UTL_I18N.STRING_TO_RAW(val,''utf8''), 
               typ   => l_encryption_type,
               key   => l_cwms_key,
               iv    => l_cwms_iv);
    END ENCRYPT;

    FUNCTION DECRYPT (val RAW)
        RETURN VARCHAR2
    IS
    BEGIN
	cwms_sec.confirm_pd_or_schema_user(cwms_util.get_user_id);
        RETURN UTL_I18N.RAW_TO_CHAR (DBMS_CRYPTO.DECRYPT (src   => val,
                                    typ   => l_encryption_type,
                                    key   => l_cwms_key,
				    iv    => l_cwms_iv),''utf8'');
    END DECRYPT;
END cwms_crypt;';
BEGIN
    SYS.DBMS_DDL.CREATE_WRAPPED (l_pkg_body_text); 
END;
/
