/* Formatted on 5/22/2015 2:45:05 PM (QP5 v5.269.14213.34769) */
/*
This corrects a known problem.

<details class=”gory”>
Once upon a time the validation code in the rating_template_t object type didn’t
barf on the illegal value of NEAREST for the in-range lookup behavior.  For 
out-of-range-low NEAREST equates to NEXT and for out-of-range-high NEAREST 
equates to PREVIOUS.  For in-range lookups, the PREVIOUS and NEXT are equally 
near, so it doesn’t make sense in that context.  In addition to 
PREVIOUS/NEXT/NEAREST, which refer to positions in the lookup table, there are 
also LOWER/HIGHER/CLOSEST which refer to the *values* in the lookup table.  
CLOSEST *is* a valid in-range lookup behavior because it will select the NEXT or
PREVIOUS value based on the difference between those values and the value to be 
looked up.  (Yes, the value *could* be exactly halfway between the LOWER and 
HIGER values but at least it’s not *guaranteed* to be so.)  The reason for the 
two sets of lookup behaviors is to allow for lookup tables that increase in 
value with increasing position (as all CWMS table-based ratings are required to 
do) as well as those that decrease in value with increasing position and to 
provide separate sets of semantics for dealing with positions vs. values.

The validation code was tightened up sometime later, but no effort was made to 
go and modify all rating templates in all databases until now. The following
update statements corrects this issue.
</details>

*/

update at_rating_ind_param_spec
   set in_range_rating_method =
          (select rating_method_code
             from cwms_rating_method
            where rating_method_id = 'CLOSEST')
 where in_range_rating_method = (select rating_method_code
                                   from cwms_rating_method
                                  where rating_method_id = 'NEAREST');


update at_rating_spec
   set in_range_rating_method =
          (select rating_method_code
             from cwms_rating_method
            where rating_method_id = 'CLOSEST')
 where in_range_rating_method = (select rating_method_code
                                   from cwms_rating_method
                                  where rating_method_id = 'NEAREST');

commit;