create or replace type body rating_value_note_t
as
   constructor function rating_value_note_t(
      p_note_code in number)
   return self as result
   is
   begin
      ----------------------------------------------------------
      -- use loop for convenience - only 1 at most will match --
      ----------------------------------------------------------
      for rec in
         (  select *
              from at_rating_value_note
             where note_code = p_note_code
         )
      loop
         self.note_id     := rec.note_id;
         self.description := rec.description;

         select office_id
           into self.office_id
           from cwms_office
          where office_code = rec.office_code;
      end loop;
      return;
  end;

   member function get_note_code
   return number
   is
      l_note_code number;
   begin
      select note_code
        into l_note_code
        from at_rating_value_note
       where office_code in (cwms_util.get_office_code(self.office_id), cwms_util.db_office_code_all)
         and note_id = upper(self.note_id);

      return l_note_code;
   end;


   member procedure store(
      p_fail_if_exists in varchar)
   is
      l_rec           at_rating_value_note%rowtype;
      l_cwms_note_ids str_tab_t;
   begin
      if cwms_util.get_office_code(self.office_id) = cwms_util.db_office_code_all then
         cwms_err.raise(
            'ERROR',
            'Cannot store a rating value note for the CWMS office.');
      end if;
      select note_id bulk collect
        into l_cwms_note_ids
        from at_rating_value_note
       where office_code = cwms_util.db_office_code_all;
      for i in 1..l_cwms_note_ids.count loop
         if upper(self.note_id) = l_cwms_note_ids(i) then
            cwms_err.raise(
               'ERROR',
               'NOTE_ID '|| upper(self.note_id) || ' exists for the CWMS office, cannot store.');
         end if;
      end loop;
      l_rec.office_code := cwms_util.get_office_code(self.office_id);
      l_rec.note_id     := upper(self.note_id);
      begin
         select *
           into l_rec
           from at_rating_value_note
          where office_code = l_rec.office_code
            and note_id = l_rec.note_id;
         if cwms_util.is_true(p_fail_if_exists) then
            cwms_err.raise(
               'ITEM_ALREADY_EXISTS',
               'Rating value note',
               self.office_id || '/' || self.note_id);
        end if;
        l_rec.description := self.description;

        update at_rating_value_note
           set row = l_rec
         where note_code = l_rec.note_code;

      exception
         when no_data_found then
            l_rec.description := self.description;

            insert
              into at_rating_value_note
            values l_rec;
      end;
   end;

end;
