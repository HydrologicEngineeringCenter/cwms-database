create or replace package body cwms_mail
as

   procedure send_mail (
      p_to         in varchar2,
      p_subject    in varchar2,
      p_message    in varchar2,
      p_is_html    in varchar2      default 'F',
      p_from       in varchar2      default null,
      p_cc         in varchar2      default null,
      p_bcc        in varchar2      default null,
      p_atts       in anydata_tab_t default null,
      p_att_fnames in str_tab_t     default null,
      p_att_types  in str_tab_t     default null)
   is
      /*
      $ nslookup
      > set type=MX
      > usace.army.mil
      Server:         155.88.30.100
      Address:        155.88.30.100#53
   
      Non-authoritative answer:
      usace.army.mil  mail exchanger = 5 gw4.usace.army.mil.
      usace.army.mil  mail exchanger = 5 gw1.usace.army.mil.
      usace.army.mil  mail exchanger = 5 gw3.usace.army.mil.
      usace.army.mil  mail exchanger = 5 gw2.usace.army.mil.
   
      Authoritative answers can be found from:
      gw4.usace.army.mil      internet address = 140.194.100.160
      gw3.usace.army.mil      internet address = 140.194.153.3
      gw2.usace.army.mil      internet address = 140.194.100.150
      > 
      */
      no_such_table exception;
      pragma exception_init(no_such_table, -942);
      crlf          constant varchar2(2):= chr(13)||chr(10);
      l_mxch        constant varchar2(30) := cwms_properties.get_property('CWMSDB', 'email.mail-exchanger', 'gw2.usace.army.mil', 'CWMS');
      l_boundary    constant varchar2(24) := '~~this~is~the~boundary~~';
      l_conn        utl_smtp.connection;
      l_to          str_tab_t;
      l_cc          str_tab_t;
      l_bcc         str_tab_t;
      l_from        varchar2(32767);
      l_to_str      varchar2(32767);
      l_cc_str      varchar2(32767);
      l_msg         varchar2(32767);
      l_time        varchar2(20);    
      l_db_name     varchar2(30); 
      l_db_host     varchar2(64);
      l_count       pls_integer;
      l_name        varchar2(30);
      l_client_user varchar2(30);
      l_client_host varchar2(64);  
      l_client_pgm  varchar2(48);
      l_is_html     boolean; 
      l_html_tag    boolean;
      l_body_tag    boolean;
      l_att_types   str_tab_t;
   begin
      l_time := to_char(systimestamp at time zone 'UTC', 'dd Mon yyyy hh24:mi:ss');
      ---------------------------------   
      -- sanity check on attachments --
      ---------------------------------   
      if p_atts is null then
         null;
      else
         if p_att_fnames is null or p_att_fnames.count != p_atts.count then
            cwms_err.raise('ERROR', 'Must specify file name for each attachment');
         end if;
         l_att_types := str_tab_t();
         l_att_types.extend(p_atts.count);
         for i in 1..p_atts.count loop
            if p_att_types is not null and p_att_types.count >= i and p_att_types(i) is not null then
               l_att_types(i) := p_att_types(i);
            else
               l_att_types(i) := substr(p_att_fnames(i), instr(p_att_fnames(i), '.', -1) + 1);
            end if;
         end loop;
      end if;
      -----------------------------------      
      -- process info for message body --
      -----------------------------------      
      l_to  := cwms_util.split_text(replace(p_to, ',', ' '));
      l_cc  := cwms_util.split_text(replace(p_cc, ',', ' '));
      l_bcc := cwms_util.split_text(replace(p_bcc, ',', ' ')); 
      
      l_to_str := cwms_util.join_text(l_to, ', ');
      l_cc_str := cwms_util.join_text(l_cc, ', ');
      
      select nvl(primary_db_unique_name, db_unique_name)
        into l_db_name
        from v$database;

      select count(*) into l_count from all_objects where object_name = 'CDB_PDBS';
      if l_count > 0 then
         begin
            execute immediate 'select pdb_name from cdb_pdbs' into l_name;
         exception
            when no_such_table or no_data_found then null;
         end;
         if l_name is not null then
            l_db_name := l_db_name||'-'||l_name;
         end if;
      end if;
                      
      l_db_host := utl_inaddr.get_host_name;
           
      select osuser,
             machine,
             program
        into l_client_user,
             l_client_host,
             l_client_pgm     
        from v$session
       where sid = sys_context('USERENV', 'SID');           
   
      l_from := nvl(p_from , l_db_name||'@'||l_db_host||'.usace.army.mil');
      l_is_html := cwms_util.return_true_or_false(p_is_html);                  
      l_msg := cwms_util.join_text(cwms_util.split_text(p_message, chr(10)), crlf);
      if l_is_html then
         l_html_tag := instr(l_msg, '<html>') > 0;
         l_body_tag := instr(l_msg, '<body>') > 0;
         l_msg := regexp_replace(l_msg, '</(html|body)>', null)||'<hr/><pre>';
      end if;
      l_msg := l_msg 
         ||crlf
         ||'This message was sent by CWMS:'||crlf
         ||'  Database : '||l_db_name    ||'@' ||l_db_host    ||'.usace.army.mil'||crlf
         ||'  Client   : '||l_client_user||'@' ||l_client_host||crlf
         ||'  Program  : '||l_client_pgm ||crlf;
      if l_is_html then
         l_msg := l_msg||'</pre><hr/>';
         if l_body_tag then
            l_msg := l_msg||'</body>';
         end if;
         if l_html_tag then
            l_msg := l_msg||'</html>';
         end if;
      end if;      
      ------------------------------------------------        
      -- email conversation with the mail exchanger --
      ------------------------------------------------        
      begin                        
         l_conn := utl_smtp.open_connection(l_mxch, 25); 
         utl_smtp.helo(l_conn, l_mxch);
         utl_smtp.mail(l_conn, l_from);
         for rec in (select column_value as recipient from table(l_to)  -- "to" recipients
                     union
                     select column_value as recipient from table(l_cc)  -- "cc" recipients  
                     union
                     select column_value as recipient from table(l_bcc) -- "bcc" recipients  
                    )
        loop 
            utl_smtp.rcpt(l_conn, rec.recipient);
         end loop;
         ----------------------   
         -- send the headers --
         ----------------------   
         utl_smtp.open_data(l_conn);   
         utl_smtp.write_data(l_conn,
               'Date: '   ||l_time   ||crlf
             ||'From: '   ||l_from   ||crlf
             ||'Subject: '||p_subject||crlf
             ||'To: '     ||l_to_str ||crlf
             ||case
               when l_cc_str is null then null
               else 'Cc: '||l_cc_str||crlf
               end
             ||'MIME-Version: 1.0'||crlf
             ||'Content-Type: multipart/mixed; boundary='||l_boundary||crlf||crlf);
         ---------------------------          
         -- send the message body --
         ---------------------------          
         utl_smtp.write_data(l_conn, '--'||l_boundary||crlf);
         case l_is_html
         when true  then utl_smtp.write_data(l_conn, 'Content-Type: text/html;'||crlf);
         when false then utl_smtp.write_data(l_conn, 'Content-Type: text/plain;'||crlf);
         end case;
         utl_smtp.write_data(l_conn, 'Content-Disposition: inline;'||crlf||crlf);      
         utl_smtp.write_data(l_conn, l_msg||crlf);
         --------------------------
         -- send the attachments --
         --------------------------
         if p_atts is not null then
            declare
               c sys_refcursor;
               l_office_id varchar2(16);
               l_file_ext  varchar2(16);
               l_mime_type varchar2(84);
               l_blob      blob;
               l_clob      clob;
               l_text      varchar2(32767);
               l_chunk     pls_integer := 2000 - mod(2000, 3); -- largest raw size that is multiple of 3 (for base64 encoding);  
            begin
               for i in 1..p_atts.count loop 
                  utl_smtp.write_data(l_conn, '--'||l_boundary||crlf);
                  -------------------------
                  -- determine MIME type --
                  -------------------------
                  c := cwms_text.cat_file_extensions_f('*', cwms_util.user_office_id);
                  loop
                     fetch c into l_office_id, l_file_ext, l_mime_type;
                     if c%notfound then
                        utl_smtp.close_connection(l_conn);
                        cwms_err.raise('INVALID_ITEM', p_att_types(i), 'file extension or media type');
                     end if;                                                                           
                     if l_att_types(i) in (l_file_ext, l_mime_type) then
                        utl_smtp.write_data(l_conn, 'Content-Type: '||l_mime_type||crlf);
                        utl_smtp.write_data(l_conn, 'Content-Disposition: attachment; filename='||p_att_fnames(i)||crlf);      
                        exit;
                     end if;
                  end loop;
                  --------------------------------------------
                  -- handle different attachment data types --
                  --------------------------------------------
                  case p_atts(i).gettypename
                  when 'SYS.BLOB' then
                     ----------
                     -- blob --
                     ----------
                     if p_atts(i).getblob(l_blob) != dbms_types.success then
                        utl_smtp.close_connection(l_conn);
                        cwms_err.raise('ERROR', 'Could not access data for attachment '||p_att_fnames(i));
                     end if;                  
                     utl_smtp.write_data(l_conn, 'Content-Transfer-Encoding: base64'||crlf||crlf);
                     for j in 0..trunc((dbms_lob.getlength(l_blob) - 1 )/l_chunk) loop   
                        utl_smtp.write_data(l_conn, utl_raw.cast_to_varchar2(utl_encode.base64_encode(dbms_lob.substr(l_blob, l_chunk, j * l_chunk + 1))));
                     end loop;
                     utl_smtp.write_data(l_conn, crlf);
                  when 'SYS.CLOB' then
                     ----------
                     -- clob --
                     ----------
                     if p_atts(i).getclob(l_clob) != dbms_types.success then
                        utl_smtp.close_connection(l_conn);
                        cwms_err.raise('ERROR', 'Could not access data for attachment '||p_att_fnames(i));
                     end if;                  
                     utl_smtp.write_data(l_conn, crlf);
                     for j in 0..trunc((dbms_lob.getlength(l_clob) - 1 )/l_chunk) loop
                        utl_smtp.write_data(l_conn, dbms_lob.substr(l_clob, l_chunk, j * l_chunk + 1));
                     end loop;
                     utl_smtp.write_data(l_conn, crlf);
                  when 'SYS.VARCHAR2' then
                     --------------
                     -- varchar2 --
                     --------------
                     if p_atts(i).getvarchar2(l_text) != dbms_types.success then
                        utl_smtp.close_connection(l_conn);
                        cwms_err.raise('ERROR', 'Could not access data for attachment '||p_att_fnames(i));
                     end if;                  
                     utl_smtp.write_data(l_conn, crlf);
                     utl_smtp.write_data(l_conn, l_text);
                     utl_smtp.write_data(l_conn, crlf);
                  else
                     utl_smtp.close_connection(l_conn);
                     cwms_err.raise(
                        'ERROR', 
                        'Expected SYS.BLOB, SYS.CLOB, or SYS.VARCHAR2, got '
                        ||p_atts(i).gettypename
                        ||' for attachment');
                  end case;
               end loop;
            end;
         end if;  
         --------------------------------------       
         -- send ending boundary and wrap up --
         --------------------------------------       
         utl_smtp.write_data(l_conn, '--'||l_boundary||'--'||crlf);
         utl_smtp.close_data(l_conn); 
         utl_smtp.quit(l_conn);  
      exception
         when others then
            begin
               utl_smtp.quit(l_conn);
            exception
               when others then null;
            end;
            cwms_err.raise('ERROR', sqlerrm);
      end;   
   end send_mail;

end cwms_mail;
/
show errors;