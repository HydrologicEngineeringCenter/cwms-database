create or replace type body loc_lvl_indicator_cond_t
as
   constructor function loc_lvl_indicator_cond_t(
      p_indicator_value            in number,
      p_expression                 in varchar2,
      p_comparison_operator_1      in varchar2,
      p_comparison_value_1         in binary_double,
      p_comparison_unit            in number,
      p_connector                  in varchar2,
      p_comparison_operator_2      in varchar2,
      p_comparison_value_2         in binary_double,
      p_rate_expression            in varchar2,
      p_rate_comparison_operator_1 in varchar2,
      p_rate_comparison_value_1    in binary_double,
      p_rate_comparison_unit       in number,
      p_rate_connector             in varchar2,
      p_rate_comparison_operator_2 in varchar2,
      p_rate_comparison_value_2    in binary_double,
      p_rate_interval              in interval day to second,
      p_description                in varchar2)
   return self as result
   is
   begin
      init(p_indicator_value,
           p_expression,
           p_comparison_operator_1,
           p_comparison_value_1,
           p_comparison_unit,
           p_connector,
           p_comparison_operator_2,
           p_comparison_value_2,
           p_rate_expression,
           p_rate_comparison_operator_1,
           p_rate_comparison_value_1,
           p_rate_comparison_unit,
           p_rate_connector,
           p_rate_comparison_operator_2,
           p_rate_comparison_value_2,
           p_rate_interval,
           p_description);
         return;
   end loc_lvl_indicator_cond_t;

   constructor function loc_lvl_indicator_cond_t(
      p_row in urowid)
      return self as result
   is
      l_rec at_loc_lvl_indicator_cond%rowtype;
   begin
      select *
        into l_rec
        from at_loc_lvl_indicator_cond
       where rowid = p_row;
      init(l_rec.level_indicator_value,
           l_rec.expression,
           l_rec.comparison_operator_1,
           l_rec.comparison_value_1,
           l_rec.comparison_unit,
           l_rec.connector,
           l_rec.comparison_operator_2,
           l_rec.comparison_value_2,
           l_rec.rate_expression,
           l_rec.rate_comparison_operator_1,
           l_rec.rate_comparison_value_1,
           l_rec.rate_comparison_unit,
           l_rec.rate_connector,
           l_rec.rate_comparison_operator_2,
           l_rec.rate_comparison_value_2,
           l_rec.rate_interval,
           l_rec.description);

      return;
   end loc_lvl_indicator_cond_t;


   member procedure init(
      p_indicator_value            in number,
      p_expression                 in varchar2,
      p_comparison_operator_1      in varchar2,
      p_comparison_value_1         in binary_double,
      p_comparison_unit            in number,
      p_connector                  in varchar2,
      p_comparison_operator_2      in varchar2,
      p_comparison_value_2         in binary_double,
      p_rate_expression            in varchar2,
      p_rate_comparison_operator_1 in varchar2,
      p_rate_comparison_value_1    in binary_double,
      p_rate_comparison_unit       in number,
      p_rate_connector             in varchar2,
      p_rate_comparison_operator_2 in varchar2,
      p_rate_comparison_value_2    in binary_double,
      p_rate_interval              in interval day to second,
      p_description                in varchar2)
   is
      l_expression                 varchar2(128) := trim(upper(p_expression));
      l_comparison_operator_1      varchar2(2)   := trim(upper(p_comparison_operator_1));
      l_connector                  varchar2(3)   := trim(upper(p_connector));
      l_comparison_operator_2      varchar2(2)   := trim(upper(p_comparison_operator_2));
      l_rate_expression            varchar2(128) := trim(upper(p_rate_expression));
      l_rate_comparison_operator_1 varchar2(2)   := trim(upper(p_rate_comparison_operator_1));
      l_rate_connector             varchar2(3)   := trim(upper(p_rate_connector));
      l_rate_comparison_operator_2 varchar2(2)   := trim(upper(p_rate_comparison_operator_2));
      l_description                varchar2(256) := trim(p_description);

      function tokenize_expression(
         p_expr    in varchar2,
         p_is_rate in boolean)
      return str_tab_t
      is
         l_expr   varchar2(128) := p_expr;
         l_tokens str_tab_t;
      begin
         if p_expr is not null then
            ---------------------------------------------------------------
            -- replace V, L, L1, L2, R with ARG1, ARG2, ARG2, ARG3, ARG4 --
            ---------------------------------------------------------------
            if p_is_rate then
               if regexp_instr(p_expr, '(^|\(|[[:space:]])(-?)(V|L[12]?)([[:space:]]|\)|$)') > 0 then
                  cwms_err.raise('ERROR', 'Cannot reference variables V, L, L1, or L2 in rate expression');
               end if;
               l_expr := regexp_replace(l_expr, '(^|\(|[[:space:]])(-?)R([[:space:]]|\)|$)',   '\1\2ARG4\3');
            else
               if regexp_instr(p_expr, '(^|\(|[[:space:]])(-?)R([[:space:]]|\)|$)') > 0 then
                  cwms_err.raise('ERROR', 'Cannot reference variable R in non-rate expression');
               end if;
               l_expr := regexp_replace(p_expr, '(^|\(|[[:space:]])(-?)V([[:space:]]|\)|$)',   '\1\2ARG1\3');
               l_expr := regexp_replace(l_expr, '(^|\(|[[:space:]])(-?)L1?([[:space:]]|\)|$)', '\1\2ARG2\3');
               l_expr := regexp_replace(l_expr, '(^|\(|[[:space:]])(-?)L2([[:space:]]|\)|$)',  '\1\2ARG3\3');
            end if;
            -------------------------------
            -- tokenize algebraic or RPN --
            -------------------------------
            if instr(l_expr, '(') > 0 then
               l_tokens := cwms_util.tokenize_algebraic(l_expr);
            else
               l_tokens := cwms_util.tokenize_rpn(l_expr);
               if l_tokens.count > 1 and
                  l_tokens(l_tokens.count) not in
                  ('+','-','*','/','//','%','^','ABS','ACOS','ASIN','ATAN','CEIL',
                   'COS','EXP','FLOOR','LN','LOG', 'SIGN','SIN','TAN','TRUNC')
               then
                  l_tokens := cwms_util.tokenize_algebraic(l_expr);
               end if;
            end if;
         end if;
         return l_tokens;
      end;
   begin
      -------------------
      -- sanity checks --
      -------------------
      if p_indicator_value not in (1,2,3,4,5) then
         cwms_err.raise(
            'INVALID_ITEM',
            p_indicator_value,
            'location level indicator value');
      end if;
      if l_expression is null then
         cwms_err.raise('ERROR', 'Comparison expression must be specified');
      end if;
      if regexp_instr(l_expression, '(^|\(|[[:space:]])-?R([[:space:]]|\)|$)') > 0 then
         cwms_err.raise('ERROR', 'Expression cannot reference rate variable R');
      end if;
      if l_expression is not null then
         if regexp_instr(l_rate_expression, '(^|\(|[[:space:]])-?V([[:space:]]|\)|$)') > 0 or
            regexp_instr(l_rate_expression, '(^|\(|[[:space:]])-?L1?([[:space:]]|\)|$)') > 0 or
            regexp_instr(l_rate_expression, '(^|\(|[[:space:]])-?L2([[:space:]]|\)|$)') > 0
         then
            cwms_err.raise('ERROR', 'Rate expression cannot reference non-rate variables V, L (or L1) and L2');
         end if;
      end if;
      if l_comparison_operator_1 not in ('LT','LE','EQ','NE','GE','GT') then
         cwms_err.raise(
            'INVALID_ITEM',
            l_comparison_operator_1,
            'comparison operator');
      end if;
      if nvl(l_rate_comparison_operator_1, 'EQ') not in ('LT','LE','EQ','NE','GE','GT') then
         cwms_err.raise(
            'INVALID_ITEM',
            l_rate_comparison_operator_1,
            'rate comparison operator');
      end if;
      if nvl(l_connector, 'AND') not in ('AND','OR') then
         cwms_err.raise(
            'INVALID_ITEM',
            l_connector,
            'compound comparison connection operator');
      end if;
      if nvl(l_rate_connector, 'AND') not in ('AND','OR') then
         cwms_err.raise(
            'INVALID_ITEM',
            l_rate_connector,
            'compound rate comparison connection operator');
      end if;
      if nvl(l_comparison_operator_2, 'EQ') not in ('LT','LE','EQ','NE','GE','GT') then
         cwms_err.raise(
            'INVALID_ITEM',
            l_comparison_operator_2,
            'comparison operator');
      end if;
      if nvl(l_rate_comparison_operator_2, 'EQ') not in ('LT','LE','EQ','NE','GE','GT') then
         cwms_err.raise(
            'INVALID_ITEM',
            l_rate_comparison_operator_2,
            'rate comparison operator');
      end if;
      if p_comparison_value_1 is null then
         cwms_err.raise('ERROR', 'Comparison value must be specified');
      end if;
      if p_connector             is null or
         p_comparison_operator_2 is null or
         p_comparison_value_2    is null
      then
         if p_connector             is not null or
            p_comparison_operator_2 is not null or
            p_comparison_value_2    is not null
         then
            cwms_err.raise(
               'ERROR',
               'Secondary comparison parameters must all be specified or all be null');
         end if;
      end if;
      if p_rate_connector             is null or
         p_rate_comparison_operator_2 is null or
         p_rate_comparison_value_2    is null
      then
         if p_rate_connector             is not null or
            p_rate_comparison_operator_2 is not null or
            p_rate_comparison_value_2    is not null
         then
            cwms_err.raise(
               'ERROR',
               'Secondary rate comparison parameters must all be specified or all be null');
         end if;
      end if;
      if p_comparison_unit is not null then
         declare
            l_code number(14);
         begin
            select unit_code
              into l_code
              from cwms_unit
             where unit_code = p_comparison_unit;
         exception
            when no_data_found then
               cwms_err.raise(
                  'INVALID_ITEM',
                  p_comparison_unit,
                  'CWMS unit code');
         end;
      end if;
      if p_rate_comparison_unit is not null then
         declare
            l_code number(14);
         begin
            select unit_code
              into l_code
              from cwms_unit
             where unit_code = p_rate_comparison_unit;
         exception
            when no_data_found then
               cwms_err.raise(
                  'INVALID_ITEM',
                  p_rate_comparison_unit,
                  'CWMS unit code');
         end;
      end if;
      --------------------
      -- set the values --
      --------------------
      indicator_value            := p_indicator_value;
      expression                 := l_expression;
      comparison_operator_1      := l_comparison_operator_1;
      comparison_value_1         := p_comparison_value_1;
      comparison_unit            := p_comparison_unit;
      connector                  := l_connector;
      comparison_operator_2      := l_comparison_operator_2;
      comparison_value_2         := p_comparison_value_2;
      rate_expression            := l_rate_expression;
      rate_comparison_operator_1 := l_rate_comparison_operator_1;
      rate_comparison_value_1    := p_rate_comparison_value_1;
      rate_comparison_unit       := p_rate_comparison_unit;
      rate_connector             := l_rate_connector;
      rate_comparison_operator_2 := l_rate_comparison_operator_2;
      rate_comparison_value_2    := p_rate_comparison_value_2;
      rate_interval              := p_rate_interval;
      description                := l_description;
      factor                     := 1.0;
      offset                     := 0.0;
      rate_factor                := 1.0;
      rate_offset                := 0.0;
      interval_factor            := 1.0;
      expression_tokens          := tokenize_expression(expression, false);
      rate_expression_tokens     := tokenize_expression(rate_expression, true);
      uses_reference :=
         case regexp_instr(expression, '(^|\(|[[:space:]])-?L2([[:space:]]|\)|$)') > 0
            when true  then 'T'
            when false then 'F'
         end;
   end init;


   member procedure store(
      p_level_indicator_code in number)
   is
   begin
      cwms_level.store_loc_lvl_indicator_cond(
         p_level_indicator_code,
         indicator_value,
         expression,
         comparison_operator_1,
         comparison_value_1,
         comparison_unit,
         connector,
         comparison_operator_2,
         comparison_value_2,
         rate_expression,
         rate_comparison_operator_1,
         rate_comparison_value_1,
         rate_comparison_unit,
         rate_connector,
         rate_comparison_operator_2,
         rate_comparison_value_2,
         rate_interval,
         description,
         'F',
         'F');

   end store;
   
   -----------------------------------------------------------------------------
   -- member fields factor and offset must previously be set to provide any
   -- necessary units conversion for the comparison
   --
   -- p_rate must be specified for the interval indicated in the member field
   -- rate_interval
   -----------------------------------------------------------------------------
   member function eval_expression(      
      p_value   in binary_double,
      p_level   in binary_double,
      p_level_2 in binary_double)
   return binary_double
   is  
      l_arguments double_tab_t;
   begin
      -------------------------------------------------
      -- evaluate the expression with the parameters --
      -------------------------------------------------
      l_arguments := new double_tab_t();
      l_arguments.extend(4);
      l_arguments(1) :=  p_value   * factor + offset;
      l_arguments(2) :=  p_level   * factor + offset;
      l_arguments(3) :=  p_level_2 * factor + offset;
      return cwms_util.eval_tokenized_expression(expression_tokens, l_arguments); -- may return null
   end eval_expression;
   
   member function eval_rate_expression(      
      p_rate in binary_double)
   return binary_double
   is
      l_arguments double_tab_t;
   begin
      l_arguments := new double_tab_t();
      l_arguments.extend(4);
      l_arguments(4) := (p_rate * rate_factor + rate_offset) * interval_factor;
      return cwms_util.eval_tokenized_expression(rate_expression_tokens, l_arguments); -- may return null
   end eval_rate_expression;
   
   member function is_set(
      p_value   in binary_double,
      p_level   in binary_double,
      p_level_2 in binary_double,
      p_rate    in binary_double)
   return boolean
   is
      l_result       binary_double;
      l_comparison_1 boolean;
      l_comparison_2 boolean;
      l_is_set       boolean;
      l_arguments    double_tab_t;
   begin
      -------------------------------------------------
      -- evaluate the expression with the parameters --
      -------------------------------------------------
      l_arguments := new double_tab_t();
      l_arguments.extend(4);
      l_arguments(1) :=  p_value   * factor + offset;
      l_arguments(2) :=  p_level   * factor + offset;
      l_arguments(3) :=  p_level_2 * factor + offset;
      l_arguments(4) := (p_rate    * rate_factor + rate_offset) * interval_factor;
      l_result := round(cwms_util.eval_tokenized_expression(expression_tokens, l_arguments), 9); -- may return null
      -----------------------------------
      -- evaluate the first comparison --
      -----------------------------------
      l_comparison_1 := nvl(
         case comparison_operator_1
            when 'LT' then l_result  < comparison_value_1
            when 'LE' then l_result <= comparison_value_1
            when 'EQ' then l_result  = comparison_value_1
            when 'NE' then l_result != comparison_value_1
            when 'GE' then l_result >= comparison_value_1
            when 'GT' then l_result  > comparison_value_1
         end, false);
      -------------------------------------------------
      -- evaluate the second comparison if specified --
      -------------------------------------------------
      if connector is null then
         l_is_set := l_comparison_1;
      else
         l_comparison_2 := nvl(
            case comparison_operator_2
               when 'LT' then l_result  < comparison_value_2
               when 'LE' then l_result <= comparison_value_2
               when 'EQ' then l_result  = comparison_value_2
               when 'NE' then l_result != comparison_value_2
               when 'GE' then l_result >= comparison_value_2
               when 'GT' then l_result  > comparison_value_2
            end, false);
         l_is_set :=
            case connector
               when 'AND' then l_comparison_1 and l_comparison_2
               when 'OR'  then l_comparison_1 or  l_comparison_2
            end;
      end if;
      ---------------------------------------------------
      -- evaluate the rate if a rate expression exists --
      ---------------------------------------------------
      if l_is_set and rate_expression_tokens is not null then
         l_result := round(cwms_util.eval_tokenized_expression(rate_expression_tokens, l_arguments), 9); -- may return null
         ----------------------------------------
         -- evaluate the first rate comparison --
         ----------------------------------------
         l_comparison_1 := nvl(
            case rate_comparison_operator_1
               when 'LT' then l_result  < rate_comparison_value_1
               when 'LE' then l_result <= rate_comparison_value_1
               when 'EQ' then l_result  = rate_comparison_value_1
               when 'NE' then l_result != rate_comparison_value_1
               when 'GE' then l_result >= rate_comparison_value_1
               when 'GT' then l_result  > rate_comparison_value_1
            end, false);
         ------------------------------------------------------
         -- evaluate the second rate comparison if specified --
         ------------------------------------------------------
         if rate_connector is null then
            l_is_set := l_comparison_1;
         else
            l_comparison_2 := nvl(
               case rate_comparison_operator_2
                  when 'LT' then l_result  < rate_comparison_value_2
                  when 'LE' then l_result <= rate_comparison_value_2
                  when 'EQ' then l_result  = rate_comparison_value_2
                  when 'NE' then l_result != rate_comparison_value_2
                  when 'GE' then l_result >= rate_comparison_value_2
                  when 'GT' then l_result  > rate_comparison_value_2
               end, false);
            l_is_set :=
               case rate_connector
                  when 'AND' then l_comparison_1 and l_comparison_2
                  when 'OR'  then l_comparison_1 or  l_comparison_2
               end;
         end if;
      end if;
      return l_is_set;
   end is_set;

end;
/
show errors;
