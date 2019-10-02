insert into at_clob values (cwms_seq.nextval, 53, '/VIEWDOCS/AV_TSV_COUNT_DAY', null,
'
/**
 * Displays per day insert/delete/update statistics for AT_TSV tables 
 *
 * @since CWMS 18.1.3                                                        
 *
 * @field day                  Day on which insert/updates/deletes happened
 * @field inserts              Number of inserts to TSV tables on this day 
 * @field updates              Number of updates to TSV tables  on this day
 * @field deletes              Number of deletes to TSV tables on this day 
 * @field total                Total number of inserts/updates/deletes to TSV tables on this day 
 */
');
create or replace force view av_tsv_count_day(
   day,
   inserts,
   updates,
   deletes,
   total)                                         
as
	SELECT t "Day",
       		i "Inserts",
       		u "Updates",
       		d "Deletes",
       		i+u+d "Total"
FROM
 (SELECT trunc(from_tz(data_entry_date,'UTC') at LOCAL) t,
         sum(inserts) i,
         sum(updates) u,
         sum(deletes) d
  FROM   at_tsv_count
  GROUP BY trunc(from_tz(data_entry_date,'UTC') at LOCAL));

create or replace public synonym cwms_v_tsv_count_day for av_tsv_count_day;
                                               
