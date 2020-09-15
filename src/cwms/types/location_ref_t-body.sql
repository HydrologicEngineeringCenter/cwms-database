create or replace type body location_ref_t
as
   constructor function location_ref_t (
      p_location_id in varchar2,
      p_office_id   in varchar2)
   return self as result
   is
   begin
      base_location_id := cwms_util.get_base_id(p_location_id);
      sub_location_id  := cwms_util.get_sub_id(p_location_id);
      office_id        := cwms_util.get_db_office_id(p_office_id);
      return;
   end location_ref_t;

   constructor function location_ref_t (
      p_office_and_location_id in varchar2)
   return self as result
   is
      l_parts str_tab_t;
   begin
      l_parts := cwms_util.split_text(p_office_and_location_id, '/', 1);
      if l_parts.count = 2 then
         base_location_id := cwms_util.get_base_id(trim(l_parts(2)));
         sub_location_id  := cwms_util.get_sub_id(trim(l_parts(2)));
         office_id        := cwms_util.get_db_office_id(l_parts(1));
      else
         base_location_id := cwms_util.get_base_id(trim(l_parts(1)));
         sub_location_id  := cwms_util.get_sub_id(trim(l_parts(1)));
         office_id        := cwms_util.user_office_id;
      end if;
      return;
   end location_ref_t;

   constructor function location_ref_t (
      p_location_code in number)
   return self as result
   is
   begin
      select bl.base_location_id,
             pl.sub_location_id,
             o.office_id
        into self.base_location_id,
             self.sub_location_id,
             self.office_id
        from at_physical_location pl,
             at_base_location bl,
             cwms_office o
       where pl.location_code = p_location_code
         and bl.base_location_code = pl.base_location_code
         and o.office_code = bl.db_office_code;
      return;
   end location_ref_t;

   member function get_location_code(
      p_create_if_necessary in varchar2 default 'F')
   return number
   is
      l_location_code number(14);
   begin
      if cwms_util.is_true(p_create_if_necessary) then
         declare
            LOCATION_ID_ALREADY_EXISTS exception; pragma exception_init (LOCATION_ID_ALREADY_EXISTS, -20026);
         begin
            cwms_loc.create_location2(
               p_location_id => base_location_id
                  || substr('-', 1, length(sub_location_id))
                  || sub_location_id,
               p_db_office_id => office_id);
         exception
            when LOCATION_ID_ALREADY_EXISTS then
               null;
         end;
      end if;
      select pl.location_code
        into l_location_code
        from at_physical_location pl,
             at_base_location bl,
             cwms_office o
       where o.office_id = self.get_office_id
         and bl.db_office_code = o.office_code
         and bl.base_location_id = self.base_location_id
         and pl.base_location_code = bl.base_location_code
         and nvl(pl.sub_location_id, '.') = nvl(self.sub_location_id, '.');
      return l_location_code;
   end get_location_code;

   member function get_location_id
   return varchar2
   is
      l_location_id varchar2(57);
   begin
      l_location_id := self.base_location_id
        || SUBSTR ('-', 1, LENGTH (self.sub_location_id))
        || self.sub_location_id;
      return l_location_id;
   end get_location_id;

   member function get_office_code
   return number
   is
      l_office_code number(14);
   begin
      select office_code
        into l_office_code
        from cwms_office
       where office_id = self.get_office_id;
      return l_office_code;
   end get_office_code;

   member function get_office_id
   return varchar2
   is
   begin
      return office_id;
   end;

   member procedure get_codes(
      p_location_code       out number,
      p_office_code         out number,
      p_create_if_necessary in  varchar2 default 'F')
   is
   begin
      if cwms_util.is_true(p_create_if_necessary) then
         create_location(p_fail_if_exists => 'F');
      end if;
      select pl.location_code,
             o.office_code
        into p_location_code,
             p_office_code
        from at_physical_location pl,
             at_base_location bl,
             cwms_office o
       where o.office_id = self.get_office_id
         and bl.db_office_code = o.office_code
         and bl.base_location_id = self.base_location_id
         and pl.base_location_code = bl.base_location_code
         and nvl(pl.sub_location_id, '.') = nvl(self.sub_location_id, '.');
      return;
   end get_codes;

   member procedure create_location(
      p_fail_if_exists in varchar2)
   is
      LOCATION_ID_ALREADY_EXISTS exception; pragma exception_init (LOCATION_ID_ALREADY_EXISTS, -20026);
   begin
      cwms_loc.create_location2(
         p_location_id => base_location_id
            || substr('-', 1, length(sub_location_id))
            || sub_location_id,
         p_db_office_id => office_id);
   exception
      when LOCATION_ID_ALREADY_EXISTS then
         if cwms_util.is_true(p_fail_if_exists) then
            raise;
         else
            null;
         end if;
   end create_location;

end;
/
show errors
