create or replace type body logic_expr_t 
as
   constructor function logic_expr_t(
      p_expr in varchar2)
      return self as result
   is 
      l_tokens str_tab_tab_t;
   begin
      l_tokens := cwms_util.tokenize_logic_expression(p_expr);
      self := new logic_expr_t(l_tokens);
      return;
   end logic_expr_t;      
      
   constructor function logic_expr_t(
      p_table in out nocopy str_tab_tab_t)
      return self as result
   is                                    
      l_op    str_tab_t;
      l_value str_tab_t;
      
      function pop return str_tab_t is
         l_item str_tab_t;
      begin
         if p_table.count = 0 then
            cwms_err.raise('ERROR', 'Logic expression stack underflow');
         end if;
         l_item := p_table(p_table.count);
         p_table.trim;
         return l_item;
      end pop;
      
   begin
      ----------------------
      -- get the operator --
      ----------------------
      l_op := pop;
      if l_op.count = 1 then
         if cwms_util.is_combination_operator(l_op(1)) then
            --------------------------
            -- COMBINATION operator --
            --------------------------
            self.operator := l_op(1);
            if self.operator = 'NOT' then
               --------------------
               -- UNARY operator --
               --------------------
               self.operand_1 := logic_expr_t(p_table);
            else
               ---------------------
               -- BINARY operator --
               ---------------------
               self.operand_2 := logic_expr_t(p_table);
               self.operand_1 := logic_expr_t(p_table);
            end if;
         elsif cwms_util.is_comparison_operator(l_op(1)) then
            -------------------------
            -- COMPARISON operator --
            -------------------------
            l_value := pop;
            self.expression := str_tab_tab_t(pop, l_value, l_op);
         else
            cwms_err.raise('ERROR', 'Invalid logic operator on stack: '||l_op(1));
         end if;
      else
         cwms_err.raise('ERROR', 'Logic expression stack is corrupt.');
      end if;
      return;
   end logic_expr_t;
         
   constructor function logic_expr_t(
      p_xml in xmltype)
      return self as result
   is       
      l_text varchar2(32767); 
      l_op   varchar2(16);
      l_xml  xmltype;  
      l_comparison_elems str_tab_t := str_tab_t(
         'not-equal',
         'equal',
         'greater-than-or-equal-to',
         'greater-than',
         'less-than-or-equal-to',
         'less-than');
      l_comparison_opers str_tab_t := str_tab_t(
         'NE',
         'EQ',
         'GE',
         'GT',
         'LE',
         'LT');   
      ------------------------------
      -- local function shortcuts --
      ------------------------------
      function get_node(pp_xml in xmltype, p_path in varchar2) return xmltype is
      begin
         return cwms_util.get_xml_node(pp_xml, p_path);
      end;
      function get_text(pp_xml in xmltype, p_path in varchar2) return varchar2 is
      begin
         return cwms_util.get_xml_text(pp_xml, p_path);
      end;
      function get_number(pp_xml in xmltype, p_path in varchar2) return number is
      begin
         return cwms_util.get_xml_number(pp_xml, p_path);
      end;
   begin                  
      ----------------------------------------------------------------------          
      -- transform the element text into the correspsonding operator text --
      ----------------------------------------------------------------------          
      l_text := p_xml.getrootelement;
      for i in 1..l_comparison_elems.count loop
         l_text := replace(l_text, l_comparison_elems(i), l_comparison_opers(i));
      end loop;
      l_text := upper(l_text);      
      case
      when cwms_util.is_combination_operator(l_text) then
         --------------------------
         -- combination operator --
         --------------------------
         self.operator := l_text;
         l_xml := get_node(p_xml, '/*/*[@position=''1'']');
         if l_xml is null then cwms_err.raise(
            'ERROR',
            'Element <'
            ||p_xml.getrootelement
            ||'> does not contain required first comparison');
         end if;
         self.operand_1 := logic_expr_t(l_xml);
         if l_text != 'NOT' then
            l_xml := get_node(p_xml, '/*/*[@position=''2'']');
            if l_xml is null then cwms_err.raise(
               'ERROR',
               'Element <'
               ||p_xml.getrootelement
               ||'> does not contain required second comparison');
            end if;
         self.operand_2 := logic_expr_t(l_xml);
         end if;
      when cwms_util.is_comparison_operator(l_text) then
         -------------------------
         -- comparison operator --
         -------------------------
         l_op := l_text;
         l_xml := get_node(p_xml, '/*/arg[@position=''1'']');
         if l_xml is null then cwms_err.raise(
            'ERROR',
            'Element <'
            ||p_xml.getrootelement
            ||'> does not contain required first argument');
         end if;
         l_text := cwms_util.join_text(cwms_util.tokenize_expression(regexp_replace(get_text(l_xml, '/arg'), 'i(\d)', 'arg\1', 1, 0, 'i')), ' ');
         l_xml := get_node(p_xml, '/*/arg[@position=''2'']');
         if l_xml is null then cwms_err.raise(
            'ERROR',
            'Element <'
            ||p_xml.getrootelement
            ||'> does not contain required second argument');
         end if;
         l_text := l_text
            ||' '
            ||cwms_util.join_text(cwms_util.tokenize_expression(regexp_replace(get_text(l_xml, '/arg'), 'i(\d)', 'arg\1', 1, 0, 'i')), ' ')
            ||' '
            ||l_op;
         self := new logic_expr_t(l_text);
      else
         cwms_err.raise(
            'ERROR',
            'Element (<'
            ||p_xml.getrootelement
            ||'> is not a valid logic (combination or comparison) operator');
      end case;
      return;
   end logic_expr_t;      
            
   overriding member function evaluate(
      p_args        in double_tab_t,
      p_args_offset in integer default 0)
      return boolean
   is
      l_result  boolean;
      l_result1 boolean;
      l_result2 boolean;
   begin
      if self.operator is null then
         ---------------------------
         -- comparison expression --
         ---------------------------
         l_result := cwms_util.eval_tokenized_comparison(self.expression, p_args, p_args_offset);
      else
         ----------------------------
         -- combination expression --
         ----------------------------
         case self.operator
         when 'NOT' then 
            ------------------------------
            -- nothing to short circuit --
            ------------------------------
            l_result := not self.operand_1.evaluate(p_args, p_args_offset);
         when 'AND' then
            ------------------------------- 
            -- PL/SQL AND short circuits --
            ------------------------------- 
            l_result := self.operand_1.evaluate(p_args, p_args_offset)
                    and self.operand_2.evaluate(p_args, p_args_offset); 
         when 'XOR' then
            --------------------------------- 
            -- must evaluate both operands --
            --------------------------------- 
            l_result1 := self.operand_1.evaluate(p_args, p_args_offset); 
            l_result2 := self.operand_2.evaluate(p_args, p_args_offset);
            l_result  := (l_result1 or l_result2) and not (l_result1 and l_result2); 
         when 'OR'  then 
            ------------------------------ 
            -- PL/SQL OR short circuits --
            ------------------------------ 
            l_result := self.operand_1.evaluate(p_args, p_args_offset)
                     or self.operand_2.evaluate(p_args, p_args_offset); 
         end case;
      end if;
      return l_result;
   end evaluate;
   
   overriding member procedure print(
      p_level in integer default 0)      
   is
   begin 
      dbms_output.put(trim(to_char(p_level, '09'))||'|');
      for i in 1..p_level loop
         dbms_output.put('..');
      end loop;
      if self.operator is null then
         dbms_output.put_line(
            cwms_util.join_text(self.expression(1), ' ')||' '||
            cwms_util.join_text(self.expression(2), ' ')||' '||
            cwms_util.join_text(self.expression(3), ' '));
      else
         dbms_output.put_line(self.operator);
         self.operand_1.print(p_level+1);
         if self.operand_2 is not null then
            self.operand_2.print(p_level+1);
         end if;
      end if;
   end print;
      
   overriding member function to_algebraic( 
      self in out nocopy logic_expr_t)
      return varchar2
   is
      l_expr varchar2(32767);
   begin
      self.to_algebraic(l_expr);
      return substr(l_expr, 2);
   end to_algebraic;      
   
   overriding member procedure to_algebraic(
      p_expr in out nocopy varchar2)
   is
   begin
      if self.operator is null then
         p_expr := p_expr
                   ||' '
                   ||cwms_util.to_algebraic(self.expression(1))
                   ||' '
                   ||cwms_util.get_comparison_op_symbol(self.expression(3)(1))
                   ||' '
                   ||cwms_util.to_algebraic(self.expression(2));
      else 
         if self.operand_2 is not null then
            self.operand_1.to_algebraic(p_expr);
         end if;
         p_expr := p_expr||' '||self.operator;
         self.operand_2.to_algebraic(p_expr);
      end if;
   end to_algebraic;
   
   overriding member function to_rpn( 
      self in out nocopy logic_expr_t)
      return varchar2
   is
      l_expr varchar2(32767);
   begin
      self.to_rpn(l_expr);
      return substr(l_expr, 2);
   end to_rpn;      
   
   overriding member procedure to_rpn(
      p_expr in out nocopy varchar2)
   is
   begin
      if self.operator is null then
         p_expr := p_expr
                   ||' '
                   ||cwms_util.to_rpn(self.expression(1))
                   ||' '
                   ||cwms_util.to_rpn(self.expression(2))
                   ||' '
                   ||cwms_util.get_comparison_op_symbol(self.expression(3)(1));
      else
         self.operand_1.to_rpn(p_expr);
         if self.operand_2 is not null then
            self.operand_2.to_rpn(p_expr);
         end if;
         p_expr := p_expr||' '||self.operator;
      end if;
   end to_rpn;
   
   overriding member function to_xml_text
      return varchar2
   is
      l_xml varchar2(32767);
      l_comparison_op varchar2(21);
   begin
      if self.operator is not null then
         l_xml := '<'||lower(self.operator)||'>';
         l_xml := l_xml||self.operand_1.to_xml_text;
         l_xml := l_xml||self.operand_2.to_xml_text;
         l_xml := l_xml||'</'||lower(self.operator)||'>';
      else
         l_comparison_op := case
                            when self.expression(3)(1) in ('=' , 'EQ'      ) then 'equal'
                            when self.expression(3)(1) in ('!=', '<>', 'NE') then 'not-equal'
                            when self.expression(3)(1) in ('<' , 'LT'      ) then 'less-than'
                            when self.expression(3)(1) in ('<=', 'LE'      ) then 'less-than-or-equal'
                            when self.expression(3)(1) in ('>' , 'LT'      ) then 'greater-than'
                            when self.expression(3)(1) in ('>=', 'LE'      ) then 'greater-than-or-equal'
                            end;
         l_xml := '<'
                  ||l_comparison_op
                  ||' position="1"><arg position="1">'
                  ||cwms_util.to_algebraic(self.expression(1))
                  ||'</arg><arg position="2">'
                  ||cwms_util.to_algebraic(self.expression(2))
                  ||'</arg></'
                  ||l_comparison_op
                  ||'>';
      end if;
      return l_xml;         
   end to_xml_text;   
end;
/
show errors;
commit;
