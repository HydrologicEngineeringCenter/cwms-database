
begin
   cwms_text.store_std_text('A', 'NO RECORD','F');
   cwms_text.store_std_text('B', 'CHANNEL DRY','F');
   cwms_text.store_std_text('C', 'POOL STAGE','F');
   cwms_text.store_std_text('D', 'AFFECTED BY WIND','F');
   cwms_text.store_std_text('E', 'ESTIMATED','F');
   cwms_text.store_std_text('F', 'NOT AT STATED TIME','F');
   cwms_text.store_std_text('G', 'GATES CLOSED','F');
   cwms_text.store_std_text('H', 'PEAK STAGE','F');
   cwms_text.store_std_text('I', 'ICE/SHORE ICE','F');
   cwms_text.store_std_text('J', 'INTAKES OUT OF WATER','F');
   cwms_text.store_std_text('K', 'FLOAT FROZEN/FLOATING ICE','F');
   cwms_text.store_std_text('L', 'GAGE FROZEN','F');
   cwms_text.store_std_text('M', 'MALFUNCTION','F');
   cwms_text.store_std_text('N', 'MEAN STAGE FOR THE DAY','F');
   cwms_text.store_std_text('O', 'OBSERVERS READING','F');
   cwms_text.store_std_text('P', 'INTERPOLATED','F');
   cwms_text.store_std_text('Q', 'DISCHARGE MISSING','F');
   cwms_text.store_std_text('R', 'HIGH WATER, NO ACCESS','F');
end;
/

begin
   cwms_text.store_text_filter(
      p_text_filter_id => 'LOCATION',
      p_description    => 'Matches valid CWMS locations',
      p_text_filter    => str_tab_t('in:^[^.-]{0,15}[^. -](-[^. -][^.]{0,31})?$', 'ex:^\W', 'ex:\W$'),
      p_fail_if_exists => 'F',
      p_uses_regex     => 'T',
      p_regex_flags    => null,
      p_office_id      => 'CWMS');

   cwms_text.store_text_filter(
      p_text_filter_id => 'BASE_PARAMETER',
      p_description    => 'Matches valid CWMS base parameters',
      p_text_filter    => str_tab_t('in:^(%|Area|Code|Con[cd]|Count|Currency|Depth|Dir|Dist|Elev|Energy|Evap(Rate)?|Fish|Flow|Frost|Irrad|Opening|pH|Power|Precip|Pres|Rad|Ratio|Speed|SpinRate|Stage|Stor|Temp|Thick|Timing|Travel|Turb[FJN]?|Volt)$'),
      p_fail_if_exists => 'F',
      p_uses_regex     => 'T',
      p_regex_flags    => null,
      p_office_id      => 'CWMS');

   cwms_text.store_text_filter(
      p_text_filter_id => 'PARAMETER',
      p_description    => 'Matches valid CWMS parameters',
      p_text_filter    => str_tab_t('in:^(%|Area|Code|Con[cd]|Count|Currency|Depth|Dir|Dist|Elev|Energy|Evap(Rate)?|Fish|Flow|Frost|Irrad|Opening|pH|Power|Precip|Pres|Rad|Ratio|Speed|SpinRate|Stage|Stor|Temp|Thick|Timing|Travel|Turb[FJN]?|Volt)(-[^.]{1,32})?$'),
      p_fail_if_exists => 'F',
      p_uses_regex     => 'T',
      p_regex_flags    => null,
      p_office_id      => 'CWMS');

   cwms_text.store_text_filter(
      p_text_filter_id => 'PARAMETER_TYPE',
      p_description    => 'Matches valid CWMS parameter types',
      p_text_filter    => str_tab_t('in:^(Total|Max|Min|Const|Ave|Inst)$'),
      p_fail_if_exists => 'F',
      p_uses_regex     => 'T',
      p_regex_flags    => null,
      p_office_id      => 'CWMS');

   cwms_text.store_text_filter(
      p_text_filter_id => 'INTERVAL',
      p_description    => 'Matches valid CWMS intervals',
      p_text_filter    => str_tab_t('in:^(0|~?(1(Minute|Hour|Day|Week|Month|Year|Decade)|([234568]|1[025]|[23]0)Minutes|([23468]|12)Hours|[23456]Days))$'),
      p_fail_if_exists => 'F',
      p_uses_regex     => 'T',
      p_regex_flags    => null,
      p_office_id      => 'CWMS');

   cwms_text.store_text_filter(
      p_text_filter_id => 'DURATION',
      p_description    => 'Matches valid CWMS durations',
      p_text_filter    => str_tab_t('in:^(0|(1(Minute|Hour|Day|Week|Month|Year|Decade)|([234568]|1[025]|[23]0)Minutes|([23468]|12)Hours|[23456]Days)(BOP)?)$'),
      p_fail_if_exists => 'F',
      p_uses_regex     => 'T',
      p_regex_flags    => null,
      p_office_id      => 'CWMS');
end;
/