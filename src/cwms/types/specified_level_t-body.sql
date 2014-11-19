create or replace type body specified_level_t
as
   constructor function specified_level_t(
      p_office_code number,
      p_level_id    varchar2,
      p_description varchar2 default null)
      return self as result
   is
   begin
      init(p_office_code, p_level_id, p_description);
      return;
   end specified_level_t;

   constructor function specified_level_t(
      p_level_code number)
      return self as result
   is
      l_level_id    varchar2(256);
      l_description varchar2(256);
   begin
      select specified_level_id,
             description
        into l_level_id,
             l_description
        from at_specified_level
       where specified_level_code = p_level_code;

      init(p_level_code, l_level_id, l_description);
      return;
   end specified_level_t;

   member procedure init(
      p_office_code number,
      p_level_id    varchar2,
      p_description varchar2)
   is
   begin
      select office_id
        into office_id
        from cwms_office
       where office_code = p_office_code;

      level_id    := p_level_id;
      description := p_description;
   end init;

   member procedure store
   is
   begin
      cwms_level.store_specified_level(level_id, description, 'F', office_id);
   end store;
end;
/
show errors;
