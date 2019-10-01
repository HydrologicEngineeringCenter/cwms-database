insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_TSV_COUNT_MINUTE', null,
'
/**
 * Displays per minute insert/delete/update statistics for AT_TSV tables 
 *
 * @since CWMS 18.1.3                                                        
 *
 * @field data_entry_date      Minute at which insert/updates/deletes happened
 * @field inserts              Number of inserts to TSV tables in the last one minute
 * @field updates              Number of updates to TSV tables in the last one minute
 * @field deletes              Number of deletes to TSV tables in the last one minute
 */
');
create or replace force view av_tsv_count_minute(
   data_entry_date,
   inserts,
   updates,
   deletes,
   total)                                         
as
   select data_entry_date,    
          inserts,
          updates,
          deletes,
	  inserts+updates+deletes total
     from (select data_entry_date,inserts,updates,deletes from at_tsv_count) ;

create or replace public synonym cwms_v_tsv_count for av_tsv_count_minute;
                                               
