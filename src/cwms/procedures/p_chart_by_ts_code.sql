CREATE OR REPLACE PROCEDURE P_CHART_BY_TS_CODE 
                            (  p_ts_code    IN cwms_v_ts_id.TS_CODE%TYPE 
                             , p_days       IN NUMBER DEFAULT 5  
                             , p_date_start IN DATE   DEFAULT SYSDATE - 30
                             , p_date_end   IN DATE   DEFAULT SYSDATE
                             , xmlcalldate  IN NUMBER DEFAULT NULL 
                              )
                              IS
tmpVar NUMBER;

BEGIN

--htp.p('Hello Jeremy from chart wrapper'); 

cwms_cma.p_chart_by_ts_code( p_ts_code   
                         ,   p_days       
                         ,   p_date_start
                         ,   p_date_end
                         ,   xmlcalldate 
                            ) ;


END P_CHART_BY_TS_CODE;
/
