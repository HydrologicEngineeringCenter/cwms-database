create or replace package cwms_mail
/**
 * Routines for sending email from CWMS
 *
 * @author Mike Perryman
 * @since CWMS 3.0
 */
as                                                                                 
   /**
    * Sends email marked as being delivered from a CWMS database
    *
    * @param p_to         "To" recipients of the email.  If more than one, the list of email addresses must be comma-separated.
    * @param p_subject    Subject line of the email
    * @param p_message    Message text. May be in plain text or HTML format
    * @param p_is_html    Flag ('T'/'F') specifying whether to treat the message as HTML. If not specified, the message will be treated as plain text.
    * @param p_from       The email address of the sender. Replies to the email will be delivered to this address.  If not specified or NULL, the sending address will be composed from the database name and host id.
    * @param p_cc         "Cc" recipients of the email.  If more than one, the list of email addresses must be comma-separated. If not specified or NULL, no "cc" recipients will be used.
    * @param p_bcc        "Bcc" recipients of the email.  If more than one, the list of email addresses must be comma-separated. If not specified or NULL, no "bcc" recipients will be used.
    * @param p_atts       A table of attachments to the email.  Each attachment (if any) must be a BLOB, CLOB, or VARCHAR2 object encoded as an ANYDATA object.
    * @param p_att_fnames A table of filenames for the attachments. This table must have an entry for each attachment. The extension of each filename determines the MIME content type specifier for the attachment (but see next parameter).
    * @param p_att_types  A table of MIME content types for each attachment. If specified and not NULL, the table must have one (possibly NULL) entry for each attachment. Any non-NULL entry in this table overrides the filename extension
    *                     for the corresponding attachment for determining the MIME content type.  Each non-NULL entry may be a known MIME content type (e.g. application/pdf) or a file extension that is associated with that content
    *                     type, without the '.' character (e.g. pdf)
    */
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
      p_att_types  in str_tab_t     default null);
      
end cwms_mail;
/
show errors;

