create or replace package body cwms_db_chg_log
as
   procedure get_current_ver (p_application   in     varchar2 default 'CWMS',
                              p_version          out varchar2,
                              p_ver_major        out number,
                              p_ver_minor        out number,
                              p_ver_build        out number)
   is
      l_application   cwms_db_change_log.application%type;
   begin
      l_application := nvl (upper (trim (p_application)), 'CWMS');


      select max (ver_major)
        into p_ver_major
        from cwms_db_change_log
       where upper (application) = l_application;

      if p_ver_major is null
      then
         cwms_err.raise (
            'ERROR',
               'A Version entry for Application: '
            || l_application
            || ' was not found.');
      end if;


      select max (ver_minor)
        into p_ver_minor
        from cwms_db_change_log
       where ver_major = p_ver_major and upper (application) = l_application;

      select max (ver_build)
        into p_ver_build
        from cwms_db_change_log
       where     ver_major = p_ver_major
             and ver_minor = p_ver_minor
             and upper (application) = l_application;

      p_version :=
            to_char (p_ver_major)
         || '.'
         || to_char (p_ver_minor)
         || '.'
         || to_char (p_ver_build);
   end;

   procedure get_next_ver_build (
      p_application   in     varchar2 default 'CWMS',
      p_version          out varchar2,
      p_ver_major        out number,
      p_ver_minor        out number,
      p_ver_build        out number)
   is
      l_application   cwms_db_change_log.application%type;
   begin
      l_application := nvl (upper (trim (p_application)), 'CWMS');
      get_current_ver (l_application,
                       p_version,
                       p_ver_major,
                       p_ver_minor,
                       p_ver_build);
      p_ver_build := p_ver_build + 1;
      p_version :=
            to_char (p_ver_major)
         || '.'
         || to_char (p_ver_minor)
         || '.'
         || to_char (p_ver_build);
   end;

   procedure get_next_ver_minor (
      p_application   in     varchar2 default 'CWMS',
      p_version          out varchar2,
      p_ver_major        out number,
      p_ver_minor        out number,
      p_ver_build        out number)
   is
      l_application   cwms_db_change_log.application%type;
   begin
      l_application := nvl (upper (trim (p_application)), 'CWMS');
      get_current_ver (l_application,
                       p_version,
                       p_ver_major,
                       p_ver_minor,
                       p_ver_build);
      p_ver_minor := p_ver_minor + 1;
      p_version :=
         to_char (p_ver_major) || '.' || to_char (p_ver_minor) || '.0';
   end;

   procedure get_next_ver_major (
      p_application   in     varchar2 default 'CWMS',
      p_version          out varchar2,
      p_ver_major        out number,
      p_ver_minor        out number,
      p_ver_build        out number)
   is
      l_application   cwms_db_change_log.application%type;
   begin
      l_application := nvl (upper (trim (p_application)), 'CWMS');
      get_current_ver (l_application,
                       p_version,
                       p_ver_major,
                       p_ver_minor,
                       p_ver_build);
      p_ver_major := p_ver_major + 1;
      p_version := to_char (p_ver_major) || '.0.0';
   end;

   function get_version (p_application in varchar2 default 'CWMS')
      return varchar2
   is
      l_application   cwms_db_change_log.application%type;
      l_ver_major     cwms_db_change_log.ver_major%type;
      l_ver_minor     cwms_db_change_log.ver_minor%type;
      l_ver_build     cwms_db_change_log.ver_build%type;
      l_version       varchar2(32);
   begin
      l_application := nvl (upper (trim (p_application)), 'CWMS');
      get_current_ver (l_application,
                       l_version,
                       l_ver_major,
                       l_ver_minor,
                       l_ver_build);

      return l_version;
   end;
end cwms_db_chg_log;
/
