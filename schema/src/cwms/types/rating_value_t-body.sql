create or replace type body rating_value_t
as
   
   constructor function rating_value_t
   return self as result
   is
   begin
      -- members are null!
      return;
   end;
   
   constructor function rating_value_t(
      p_rating_ind_param_code in number,
      p_other_ind             in double_tab_t,
      p_other_ind_hash        in varchar2,
      p_ind_value             in binary_double,
      p_is_extension          in varchar2)
   return self as result
   is
      l_rec        at_rating_value%rowtype;
   begin
      if cwms_util.is_true(p_is_extension) then
         select *
           into l_rec
           from at_rating_extension_value
          where rating_ind_param_code = p_rating_ind_param_code
            and other_ind_hash = p_other_ind_hash
            and ind_value = p_ind_value;
      else
         select *
           into l_rec
           from at_rating_value
          where rating_ind_param_code = p_rating_ind_param_code
            and other_ind_hash = p_other_ind_hash
            and ind_value = p_ind_value;
      end if;
      
      self.ind_value := l_rec.ind_value;
      self.dep_value := l_rec.dep_value;
      
      if l_rec.dep_rating_ind_param_code is not null then
         self.dep_rating_ind_param := rating_ind_parameter_t(l_rec.dep_rating_ind_param_code, p_other_ind, self.ind_value);
      end if;
      
      if l_rec.note_code is not null then
         select note_id
           into self.note_id
           from at_rating_value_note
          where note_code = l_rec.note_code;
      end if;
      
      return;              
   end;
   
   member procedure store(
      p_rating_ind_param_code in number,
      p_other_ind             in double_tab_t,
      p_is_extension          in varchar2,
      p_office_id             in varchar2)
   is
      l_rec                  at_rating_value%rowtype;
      l_note_rec             at_rating_value_note%rowtype;
      l_office_code          number(14) := cwms_util.get_office_code(p_office_id);
      l_rating_code          number(14);
      l_rating_ind_parameter rating_ind_parameter_t;
      l_parameter_position   number(1);
      l_other_ind            double_tab_t;
      l_count                simple_integer := 0;
   begin
      ----------------------------------
      -- store the note, if necessary --
      ----------------------------------
      if self.note_id is not null then
         begin
            select *
              into l_note_rec
              from at_rating_value_note
             where office_code in (l_office_code, cwms_util.db_office_code_all)
               and upper(note_id) = upper(self.note_id);
         exception
            when no_data_found then
               l_note_rec.note_code   := cwms_seq.nextval;
               l_note_rec.office_code := l_office_code;
               l_note_rec.note_id     := self.note_id;
               
               insert
                 into at_rating_value_note
               values l_note_rec;
         end;
      end if;
      ---------------------------------------------
      -- store the dependent rating if necessary --
      ---------------------------------------------
      if self.dep_rating_ind_param is not null then
         select rips.parameter_position
           into l_parameter_position
           from at_rating_ind_parameter rip,
                at_rating_ind_param_spec rips
          where rip.rating_ind_param_code = p_rating_ind_param_code
            and rips.ind_param_spec_code = rip.ind_param_spec_code;

         l_other_ind := p_other_ind;
         if l_other_ind is null then
            l_other_ind := double_tab_t();
         end if;
         l_other_ind.extend;
         if l_other_ind.count != l_parameter_position then
            cwms_err.raise(
               'ERROR',
               'Computed parameter position ('
               ||l_other_ind.count
               ||') does not agree with specified parameter position ('
               ||l_parameter_position
               ||')');
         end if;
         l_other_ind(l_parameter_position) := self.ind_value;
          
         select rating_code
           into l_rating_code
           from at_rating_ind_parameter
          where rating_ind_param_code = p_rating_ind_param_code;
           
         self.dep_rating_ind_param.store(
            p_rating_ind_param_code => l_rec.dep_rating_ind_param_code, --- out parameter
            p_rating_code           => l_rating_code,
            p_other_ind             => l_other_ind,
            p_fail_if_exists        => 'F');
      end if;            
      ----------------------------
      -- store the rating value --
      ----------------------------
      l_rec.rating_ind_param_code     := p_rating_ind_param_code;
      l_rec.other_ind_hash            := rating_value_t.hash_other_ind(p_other_ind);
      l_rec.ind_value                 := self.ind_value;
      l_rec.dep_value                 := self.dep_value;
      l_rec.note_code                 := l_note_rec.note_code;               
         
      if cwms_util.is_true(p_is_extension) then
         -- cwms_err.raise('ERROR', 'Unexpected p_is_extension: '||p_is_extension);
         insert
           into at_rating_extension_value
         values l_rec;
      else
         insert
           into at_rating_value
         values l_rec;
      end if;
   end;      
      
   static function hash_other_ind(
      p_other_ind in double_tab_t)
   return varchar2
   is
      l_text varchar2(32767) := '/';
   begin
      if p_other_ind is not null then
         for i in 1..p_other_ind.count loop
            l_text := l_text || to_char(p_other_ind(i)) || '/';
         end loop;
      end if;
      return rawtohex(dbms_crypto.hash(utl_raw.cast_to_raw(l_text), dbms_crypto.hash_sh1));
   end;      
end;
/
show errors;