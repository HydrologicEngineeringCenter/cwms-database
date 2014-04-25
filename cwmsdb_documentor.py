'''
Program for generating HTML-formatted documentation for the CWMS database API.

This program reads javadoc-like comments about packages, database types, and
views in CWMS schema (currently named CWMS_20).

VERSIONS:
   1.0   12Sep2011   MDP   Original version
   1.1   15Sep2011   MDP   Improved initial page in main frame
   1.2   19Sep2011   MDP   Added links to categories on initial page
   1.3   07Mar2012   MDP   Fixed tokenize(), added documents to initial page
   1.4   12Jul2012   MDP   Added API Usage Note to main page

JAVADOCS:
   Standard javadoc syntax applies as shown below, but the list of tags is a
   little different:
   /**
    * This is a brief description. This is an expanded description becuase the
    * brief description ends at the first period, or, if there is no period, at
    * the end of the description section. The description section is not intro-
    * duced by any tag.<p>
    *
    * Javadoc syntax is pseudo-HTML, so all whitespace (spaces, tabs, newlines)
    * are collapsed into single spaces; HTML tags are used to format text and
    * layout. Tables, lists (ordered, unordered, definition), etc... are all
    * acceptable content.<p>
    *
    * Each section after the description section is introduced by a tag starting
    * with the '@' character, most of which are followed by a single item name.
    * The tags available for this program are listed below.
    *
    * @deprecated This is a deprecation message where you tell what to use
    * instead
    *
    * @author authorname This specifies one or more authors, with each author
    * having his/her own tag
    *
    * @since firstappeared This tag tells when the documented item was first
    * introduced
    *
    * @param paramname This describes a parameter to a function or procedure.
    * Only the brief description (up to the first period) is included in the
    * summary section. The entire description is included in the details
    * section. Do not specify the data type, usage (in/out), or any default
    * values in this section because they will be documented automatically. Each
    * parameter requires its own tag
    *
    * @field fieldname This tag is used to describe a field/member of a database
    * object type, package record type, or column in a view. Each field/member/
    * column requires its own tag in the main javadoc for a type. This differs
    * from documenting Java classes, where each field has its own complete
    * javadoc. Do not specify the data type of the item becuase this will be
    * automatically documented.
    *
    * @member membername This tag is the same as @field
    * 
    * @return This tag describes the item returned from the function (not used
    * for procedures). Like other tags, the brief description only is included
    * in the summary section. Do not specify the data type returned in this
    * section because it will be automatically documented
    * 
    * @exception exceptionname This tag describes an exception that is raised
    * by the function or procedure Like other tags, the brief description only
    * is included in the summary section.
    *
    * @throws exceptionname This tag is the same as @exception
    *
    * @see itemname This tag provides a link to another location in the
    * hypertext.
    * <ul>
    *  <li>To reference a database type, use "@see type typename"</li>
    *  <li>To reference a view use "@see view viewname"</li>
    *  <li>To reference a package in general, use "@see packagename" or
    *      or "@see package packagename"</li>
    *  <li>To reference an package itemitem (type, variable, constant, function,
    *      or procedure) in a package use "@see packagename.itemname"
    *      <ul>
    *       <li>for variables you can also use "@see variable variablename"</li>
    *       <li>for constants you can also use "@see constant constantname"</li>
    *      </ul>
    *  </li>
    * </ul>
    */

PACKAGES:
   A package is documented by inserting a javadoc between the package name and
   the as/is keyword in the package specification.  The package javadoc should
   have only the description section and @deprecated, @authors, @since, and @see
   tags.

   PACKAGE TYPES:
      Any package type definition that is immediately preceded by a javadoc is
      documented. Table type javadocs should have only the description section
      and possibly @deprecated, @authors, @since, and @see tags. Record types
      should have a @field or @member section for each field/member.

   PACKAGE VARIABLES:
      Any package variable definition that is immediately preceded by a javadoc
      is documented. Package variable javadocs should have only the description
      section and possibly @deprecated, @authors, @since, and @see tags.

   PACKAGE CONSTANTS:
      Any package constant definition that is immediately preceded by a javadoc
      is documented. Package variable javadocs should have only the description
      section and possibly @deprecated, @authors, @since, and @see tags.

   PACKAGE ROUTINES:
      Any package function or procedure that is immediately preceded by a
      javadoc is documented. Package procedure javadocs should have only the
      description section and possibly  @deprecated, @authors, @since, @see, and
      @exception or @throws tags. They should also have one @param tag for each
      parameter. Package function javadocs are the same except they should also
      have a @return tag

DATABASE TYPES:
   A database type is documented by inserting a javadoc between the type name
   and the as/is keyword in the type specification. A table type javadoc
   should have only the description section and @deprecated, @authors, @since,
   and @see tags. An object type javadoc should also have one @field or
   @member tag for each field/member.

   OBJECT TYPE METHODS:
      Any object type function or procedure that is immediately preceded by a
      javadoc is documented. Procedure method javadocs should have only the
      description section and possibly @deprecated, @authors, @since, @see,
      and @exception or @throws tags. They should also have one @param tag for
      each parameter. Function method javadocs are the same except they should
      also have a @return tag, except for constructor functions.

VIEWS:
   A view is documented by creating an entry in the AT_CLOB table that contains
   the javadoc for the view and has an identifer of /VIEWDOCS/viewname. A view
   javadoc should have only the description section and @deprecated, @authors,
   @since, and @see tags. It should also have one @field or @member tag for each
   column in the view. Do not specify the column data types or column positions
   because these will be automatically
   documented.

EMBEDDED LINKS:
   Embedded links can be used anywhere in the javadocs by specifying an anchor
   tag with an "href" attribute. To reference one of the javadocs, use the
   following targets.

   PUBLIC SYNONYMS:
      You do not need to use the public synonyms for types and views in embedded
      links within javadocs. The program will convert the links to refer to the
      proper target name.

   PACKAGE TARGETS:
      The file names are pkg_packagename.html.

      The summary section contains anchors with names of package routines.
      Since routines can be overloaded (same routine name with different
      parameters), there can be multiple anchors with the same name, for which
      there is no standard behavior among browsers.

      The details section contains anchors with the names package types,
      variables, and constants, as well as distinct anchors for each package
      routine. The anchor names of the types, variables, and constants are
      simply the name of the item.  The anchor name of a routine has three
      components:
         1. routine type
            The routine type is simply "procedure" or "function"

         2. routine name
            The routine name is, well, the name of the routine, separated by a
            space from the routine type

         3. routine parameters
            If the routine has parameters, there will be an opening parenthesis
            immediately following the routine name (no space), and then each
            parameter will have:
               name:  no space before it, followed by one space

               usage: "in", "out", "in out", "out nocopy", or "in out nocopy",
               even if the usage defaults to "in", followed type one space

               type: the data type (e.g, varchar2, interval day to second,
               binary_double)

            Multiple parameters are separated by commas (without spaces) and the
            parameter list is terminated by a closing parenthesis (no spaces).

      Examples:
         <a href="pkg_cwms_ts.html#delete_insert">
         <a href="pkg_cwms_ts.html#function convert_to_db_units(p_value in binary_double,p_parameter_id in varchar2,p_unit_id in varchar2)">


   DATABASE TYPE TARGETS:
      The file names are type_typename.html, where typename is the public synonym
      of the type. As stated above, you can use the actual type name and the
      program will convert to public synonyms as appropriate.

      TABLE TYPES:
         Named anchors should not be used on table type targets.

      OBJECT TYPES WITHOUT ROUTINES:
         Named anchors should not be used on object type targets that don't have
         routines (functions and procedures)

      OBJECT TYPES WITH ROUTINES:
         The summary section has the same named anchors as package targets.

         The details has the same named anchors as the package targets with the
         following exceptions:

            database object targets do not have the equivalent of package level
            types, variables, and constants

            database object targets have an additional routine type: "constructor"

      Example:
          <a href="type_location_ref_t.html#constructor location_ref_t(p_location_code in number)">

   VIEW TARGETS:
      The file names are view_viewname.html, where viewname is the public synonym
      of the view. As stated above, you can use the actual view name and the
      program will convert to public synonyms as appropriate.

      There are no named anchors in the view html files.

      Example:
          <a href="view_av_tsv_dqu.html">
'''

import getopt, java, oracle, os, shutil, string, StringIO, sys, time, traceback

#---------------------#
# regular expressions #
#---------------------#
re_parentheses      = '([()])'
re_size             = r'\s*(\(\s*((\d+(\s+(byte|char))?))\s*\))'
re_complex_char     = r'((national\s+)?char(acter)?|nchar)\s+varying'
re_complex_time     = r'timestamp(\s+with(\s+local)?\s+time\s+zone)?'
re_complex_intvl    = r'interval\s+(year\s+to\+month|day\s+to\s+second)'
re_complex_raw      = r'long\s+raw'
re_complex_type     = re_complex_char+'|'+re_complex_time+'|'+re_complex_intvl+'|'+re_complex_raw
re_empty_line       = r'(\s*$)'
re_line_comment     = '(--.*$)'
re_multi_comment    = '(/[*](.)*?[*]/)'
re_jdoc_comment     = r'(^\s*/[*]{2}(.+?)[*]/)'; # must begin the text
re_jdoc_comment2    = r'(/[*]{2}(.+?)[*]/)';  # can be embedded in text
re_identifier       = '([a-z0-9_$#]{1,30})'
re_identifier_sized = '('+re_identifier+re_size+'?)'
re_compound_id      = '('+re_identifier+r'(\.' +re_identifier+')*)'
re_package_doc      = '('+re_jdoc_comment+r'\s*[ai]s\s+)'
re_datatype         = '('+re_complex_type+'|'+re_compound_id+')'
re_datatype_sized   = '('+re_datatype+re_size+'?)'
re_param_usage      = r'(in\s+out(\s+nocopy)?|out(\s+nocopy)?|in)'
re_param_dflt       = r'default\s+((.+))'
re_param_decl       = re_identifier+r'(\s+'+re_param_usage+r')?\s+'+re_datatype+r'(\s+'+re_param_dflt+r')?\s*'
re_return_type      = r'(return\s+('+re_datatype+r')(\s+(result_cache|pipelined))?)'
re_procedure        = r'(\s*procedure\s+'+re_identifier+r'((\s*\(.+?\))?\s*;))'
re_function         = r'(\s*function\s+'+re_identifier+r'(\s*\(.+?\))?\s*'+re_return_type+r'\s*;)'
re_routine          = '('+re_procedure+'|'+re_function+')'
re_constant         = re_identifier+r'\s+constant\s+'+re_datatype_sized+r'\s*:=(\s*(.+?)\s*);'
re_variable         = re_identifier+r'\s+'+re_datatype_sized+r'\s*:=(\s*(.+?)\s*);'
re_pkg_type         = r'\s*type\s+'+re_identifier+r'\s+is\s+(record\s*\(([^)]+)\)|table\s+of\s+('+re_datatype_sized+r')(\s+index\s+by\s+'+re_identifier_sized+r')?)\s*;'
re_jdoc_pkg         = r'package\s+'+re_compound_id+r'\s*'+re_package_doc
re_pkg_jdoc_routine = '('+re_jdoc_comment+r'\s*'+re_routine+')'
re_pkg_jdoc_type    = '('+re_jdoc_comment+r'\s*'+re_pkg_type+')'
re_pkg_jdoc_const   = '('+re_jdoc_comment+r'\s*'+re_constant+')'
re_pkg_jdoc_var     = '('+re_jdoc_comment+r'\s*'+re_variable+')'
re_object_id        = r'OID\s+''.+?'''
re_table_type       = r'type\s+('+re_compound_id+r')(\s+'+re_object_id+r')?\s+[ai]s\s+table\s+of\s+('+re_identifier_sized+');'
re_obj_level        = r'(\s+[ai]s\s+object|\s+under\s+(\S+))'
re_obj_field        = re_identifier+r'\s+([^,(]+(\(\d+(\s+(byte|char))?\))?)'
re_obj_type         = r'type\s+'+re_compound_id+'.*'+re_obj_level+r'\s*\((.+)\)(.*)[;/]?'
re_obj_routine_type = r'((constructor|(overriding\s+)?member|static)\s+(function|procedure))'
re_obj_func_return  = r'return\s+[^,)]+'
re_obj_routine      = re_obj_routine_type+r'\s+'+re_identifier+r'(\s*\([^()]+\))?(\s+'+re_obj_func_return+')?'
re_obj_routines     = re_obj_routine+r'(\s*,\s*'+re_obj_routine+')*'
re_obj_jdoc_routine = re_jdoc_comment2+r'\s*('+re_obj_routine+')'
re_jdoc_type        = r'type\s+.*?'+re_jdoc_comment2+r'.*?\s+[ai]s\s+.*'
#-----#
# css #
#-----#
css = '''
   body {
     font-size:.85em;
     font-family:Tahoma, Veranda, Arial, Sans-serif;
   }
   .top-level {
     font-size:2em;
     color:blue;
   }
   .summary {
     width:100%;
     border-collapse:collapse;
   }
   .summary th {
     border:1px solid black;
     color:blue;
     background-color:#F0D0FF;
     text-align:left;
     font-size:1.2em;
     padding:15px;
   }
   .summary td {
     border:1px solid black;
     color:black;
     background-color:white;
     margin:0px;
     padding-top:5px;
     padding-bottom:5px;
     padding-left:15px;
     padding-right:15px;
   }
   .summary p {
      padding-left:5em;
      text-indent:-5em;
   }
   .members {
     border:none;
   }
   .members td {
     border:none;
     margin:0px;
     padding:0px;
     width:0%;
   }
   table.descr {
      border-collapse:collapse;
   }
   th.descr {
     background-color:#DFDFDF;
     border:1px solid black;
     padding:5px;
   }
   td.descr {
     border:1px solid black;
     padding:5px;
   }
   td.descr-center {
     text-align:center;
     border:1px solid black;
     padding:5px;
   }
   .routine-type-col {
     width:1%;
     text-align:right;
   }
   .description-col {
     width:100%;
     text-align:left;
   }
   .keyword {
     color:darkred;
     font-weight:normal;
   }
   .parentheses, .comma {
     color:black;
   }
   .routine-name {
     color:blue;
     font-weight:normal;
   }
   .param-name {
     color:green;
   }
   .param-type {
     color:navy;
   }
   .param-value {
     color:red;
   }
   .comment {
     color:gray;
   }
   .detail-header {
     font-size:.1.5em;
   }
   .details {
   }
   .details th {
     border:1px solid black;
     color:blue;
     background-color:#F0D0FF;
     text-align:left;
     font-size:1.2em;
     padding:15px;
   }
   .details td {
   }
   .inline {
     white-space:nowrap;
   }
'''
compiled_regexs = {}
synonyms = {}
css_filename = 'pljdoc.css'
package_links = {}
type_links = {}
view_links = {}
brief_descriptions = {}
external_files = [
   'CWMS Database Naming.pdf',
   'CWMS LOCATION LEVELS.pdf',
   'CWMS RATINGS.pdf',
   'CWMS Properties Dictionary.pdf',
   'Text and Binary Data in the CWMS Database.pdf'
]

format_type = 'initcap' # must be 'upper', 'lower' or 'initcap'
use_synonyms = True

def usage(msg=None) :
   '''
   Spews a usage blurb to stderr and exits
   '''
   program_name = os.path.splitext(os.path.split(sys.argv[0])[1])[0]
   blurb = '''
      %s: Program for generating HTML-formatted documentation for the CWMS database API.

      Usage: %s -d database -u db_user -p db_pass -o out_dir -e ext_dir

      Where: database = database connection string as host:port:sid
             db_user  = the database user (this user's schema will be documented)
             db_pass  = the password for the database user
             out_dir  = the directory to output the html files in
             ext_dir  = the directory containing external files to include (pdfs, etc...)

   ''' % (program_name, program_name)
   if msg :
      sys.stderr.write('\n')
      for line in msg.strip().split('\n') :sys.stderr.write("      %s\n" % line)
   sys.stderr.write(blurb)
   sys.exit()

def output(msg, timestamp=False, newline=False) :
   '''
   Outputs log text
   '''
   if timestamp : sys.stdout.write('%s ' % time.ctime())
   sys.stdout.write(msg)
   if newline : sys.stdout.write('\n')
   sys.stdout.flush()

def output1(itemtype, itemname) :
   '''
   Outputs the first part of log messages about checking items for documentation.
   '''
   output('Checking %-7s %s%s' % (itemtype, itemname, '.' * (31-len(itemname))), timestamp=True, newline=False)

def output2(msg) :
   '''
   Outputs text terminating in a newline (without timestamp)
   '''
   output(msg, timestamp=False, newline=True)

def output3(itemtype) :
   '''
   Outputs the first part of log messages about retrieving items
   '''
   output('Retrieving %s%s' % (itemtype, '.' * (15-len(itemtype))), timestamp=True, newline=False)


def alias(item) :
   '''
   Replaces words in text with identified synonyms
   '''
   words = item.split()
   for i in range(len(words)) :
      try    : words[i] = synonyms[words[i].upper()]
      except : pass
   return ' '.join(words)

def initcap(text) :
   '''
   Uppercases the first character of each word and lowercases the rest
   '''
   chars = map(None, text.lower())
   for i in range(len(chars))[::-1] :
      if i == 0 or chars[i-1] not in ('abcdefghijklmnopqrstuvwxyz') :
         chars[i] = chars[i].upper()
   return ''.join(chars)

format_funcs = {
   'upper'   : string.upper,
   'lower'   : string.lower,
   'initcap' : initcap
}

def tokenize(text) :
   '''
   prepares text for safe formatting
   '''
   patterns = [
      get_pattern(re_multi_comment, 'imd'),
      get_pattern(re_line_comment, 'im'),
      get_pattern("'[^']*?'", 'imd')]
   pattern_count = len(patterns)
   replacements = [[] for i in range(pattern_count)]
   tokenized = text
   #------------------------------------------#
   # replace comments and strings with tokens #
   #------------------------------------------#
   for i in range(pattern_count) :
      squiggle = (i + 1) * '~'
      template = '!%s%%d%s!' % (squiggle, squiggle)
      while True :
         matcher = patterns[i].matcher(tokenized)
         if not matcher.find() : break
         replacement = template % len(replacements[i])
         replacements[i].append(matcher.group())
         tokenized = matcher.replaceFirst(replacement)
   #---------------------------------------------#
   # restore comments, leaving strings tokenized #
   #---------------------------------------------#
   tokenized = untokenize(tokenized, replacements[:-1])
   for i in range(pattern_count - 1) : replacements[i] = []
   return tokenized, replacements

def untokenize(text, replacements) :
   '''
   Reverse of tokenize()
   '''
   if text :
      for i in range(len(replacements)) :
         squiggle = (i + 1) * '~'
         template = '!%s%%d%s!' % (squiggle, squiggle)
         for j in range(len(replacements[i])) :
            text = text.replace(template % j, replacements[i][j])
   return text

def format(item, useSynonym=None) :
   '''
   Format text according to the format_type setting, optionally using an alias
   '''
   tokenized, replacements = tokenize(item)
   if useSynonym is None : useSynonym = use_synonyms
   if useSynonym : tokenized = alias(tokenized)
   tokenized = format_funcs[format_type](tokenized)
   return untokenize(tokenized, replacements)

def get_pattern(expr, flags=None) :
   '''
   Returns a compiled version of the regular expression, caching results for reuse
   '''
   global compiled_regexs
   pattern_flags = 0
   if flags is not None :
      for c in flags :
         if   c == 'i' : pattern_flags |= java.util.regex.Pattern.CASE_INSENSITIVE
         elif c == 'm' : pattern_flags |= java.util.regex.Pattern.MULTILINE
         elif c == 'd' : pattern_flags |= java.util.regex.Pattern.DOTALL
   key = (expr, pattern_flags)
   if compiled_regexs.has_key(key) :
      pattern = compiled_regexs[key]
   else :
      pattern = java.util.regex.Pattern.compile(expr, pattern_flags)
      compiled_regexs[key] = pattern
   return pattern

def clean_text(text) :
   '''
   Removes comments (except javadocs) and empty lines from text
   '''
   empty_comment_pattern  = get_pattern(re_empty_line, 'm')
   single_comment_pattern = get_pattern(re_line_comment, 'm')
   multi_comment_pattern  = get_pattern(re_multi_comment, 'imd')
   jdoc_comment2_pattern  = get_pattern(re_jdoc_comment2, 'imd')
   multi_matcher = multi_comment_pattern.matcher(text)
   pos = 0
   comments = []
   while multi_matcher.find(pos) :
      comments.append((multi_matcher.start(), multi_matcher.end()))
      pos = comments[-1][1]
   for start, end in comments[::-1] :
      comment_text = text[start:end]
      if not jdoc_comment2_pattern.matcher(comment_text).matches() :
         text = text[:start] + text[end:]
   single_matcher = single_comment_pattern.matcher(text)
   text = single_matcher.replaceAll('')
   empty_matcher = empty_comment_pattern.matcher(text)
   text = empty_matcher.replaceAll('')
   return text

def brief(text) :
   '''
   Returns text up to the first period.
   '''
   pos = text.find('.')
   if pos != -1 : return text[:pos+1].strip()
   return text

def mark_parentheses(text) :
   '''
   Returns text with any parentheses marked in <span>s
   '''
   return get_pattern(re_parentheses).matcher(text).replaceAll('<span class="parentheses">$1</span>')

def replace_synonyms(text) :
   '''
   Replaces any raw type and view names with their formatted, aliased equivalents
   '''
   for type_name in fmt_type_names.keys() :
      matcher = get_pattern(r'(\W|^)%s(\W|$)' % type_name, 'i').matcher(text)
      if matcher.find() : text = matcher.replaceAll('$1%s$2' % fmt_type_names[type_name])
   for view_name, is_materialized in fmt_view_names.keys() :
      matcher = get_pattern(r'(\W)%s(\W)' % view_name, 'i').matcher(text)
      if matcher.find() : text = matcher.replaceAll('$1%s$2' % fmt_view_names[(view_name, is_materialized)])
   return text

def make_reference_elem(text, local_names=None) :
   '''
   Builds a reference element for the specified text
   '''
   ref_text = text.lower()
   matcher = get_pattern(r'\W%s\.' % username.lower()).matcher(ref_text)
   if matcher.find() : ref_text = matcher.replaceAll('')
   if ref_text.startswith('type ') :
      parts = ref_text[5:].strip().split('.', 1)
      if local_names and len(parts) == 1 and parts[0] in local_names :
         target = '#%s' % parts[0]
      else :
         target = './type_%s.html' % alias(parts[0]).lower()
         if len(parts) > 1 : target += '#%s' % parts[1]
   elif ref_text.startswith('package ') :
      parts = ref_text[5:].strip().split('.', 1)
      target = './pkg_%s.html' % parts[0]
      if len(parts) > 1 : target += '#%s' % parts[1]
   elif ref_text.startswith('dflt ') :
      parts = ref_text[5:].strip().split('.', 1)
      if local_names and len(parts) == 1 and parts[0] in local_names :
         target = '#%s' % parts[0]
      else :
         target = './pkg_%s.html' % parts[0]
         if len(parts) > 1 : target += '#%s' % parts[1]
   elif ref_text.startswith('view ') :
      target = './view_%s.html' % alias(ref_text[5:].strip()).lower()
   elif ref_text.startswith('constant ') or ref_text.startswith('variable ') :
      parts = ref_text[9:].strip().split('.', 1)
      if local_names and len(parts) == 1 and parts[0] in local_names :
         target = '#%s' % parts[0]
      else :
         target = './pkg_%s.html' % parts[0]
         if len(parts) > 1 :target += '#%s' % parts[1]
   else :
      parts = ref_text.strip().split('.', 1)
      if len(parts) > 1 :
         target = './pkg_%s.html#%s' % (parts[0], parts[1])
      else :
         target = '#%s' % parts[0]
   return HtmlElem('a', attrs=[('href', target)])

def parse_params(params_text, jdoc_text) :
   '''
   Creates list of [param_name, param_usage, param_type] elements from
   parameter list, and replaces occurences of param_name in the javadoc
   with formatted version
   '''
   params = []
   if params_text :
      tokenized, replacements = tokenize(params_text)
      params_text = params_text.replace('\n', ' ')
      params_text = params_text[params_text.find('(')+1:params_text.rfind(')')].strip()
      lines = map(string.strip, params_text.split(','))
      for line in lines :
         if not line : continue
         param_matcher = get_pattern(re_param_decl, 'i').matcher(line)
         param_matcher.find()
         param_name  = param_matcher.group(1)
         param_usage = param_matcher.group(2)
         param_type  = param_matcher.group(6)
         param_dflt  = param_matcher.group(18)
         if not param_usage : param_usage = 'in'
         params.append((param_name.strip().lower(), param_usage.strip().lower(), param_type.strip().lower(), param_dflt))
         matcher = get_pattern(r'(\W)%s(\W)' % param_name, 'i').matcher(jdoc_text)
         formatted_name = format(param_name, False)
         if matcher.find() : jdoc_text = matcher.replaceAll('$1%s$2' % formatted_name)
   return params, jdoc_text


def add_routine(summary_table, details_div, routine_name, routine_type, return_type, params, jdoc_text, local_types=[], local_names=[]) :
   '''
   Adds html elements for a specified routine to the summary and details area
   '''
   #-----------------------#
   # build the anchor name #
   #-----------------------#
   anchor = '%s %s' % (routine_type, routine_name)
   if params : anchor += '(%s)' % ','.join([' '.join(p[:3]) for p in params])
   anchor = anchor.lower()
   #-----------------------#
   # build routine summary #
   #-----------------------#
   if return_type :
      return_type_elem = HtmlElem('span', attrs=[('class', 'param-type')], content=format(return_type))
      if fmt_type_names.has_key(return_type.upper()) or return_type.lower() in local_types :
         return_type_elem = make_reference_elem('type %s' % return_type, local_types).add_content([return_type_elem])
      col1 = HtmlElem('td', attrs=[('class', 'routine-type-col')], content=[
         return_type_elem,
         HtmlElem('br'),
         HtmlElem('span', attrs=[('class', 'keyword')], content=format(routine_type, False))])
   else :
      col1 = HtmlElem('td', attrs=[('class', 'routine-type-col')], content=[
         HtmlElem('span', attrs=[('class', 'keyword')], content=format(routine_type, False)),
         HtmlElem('br')])
   col2 = HtmlElem('td', attrs=[('class', 'details-col')], content=[
      HtmlElem('p'),
      HtmlElem('a', attrs=[('name', routine_name)]),
      HtmlElem('a', attrs=[('href', '#%s' % anchor),('title', 'Click for details')], content=[
         HtmlElem('span', attrs=[('class', 'routine-name')], content=format(routine_name, False))])])
   param_count = len(params)
   for i in range(param_count) :
      param_name, param_usage, param_type, param_dflt = params[i]
      param_type_elem = HtmlElem('span', attrs=[('class', 'param-type')], content=format(param_type))
      if fmt_type_names.has_key(param_type.upper()) or param_type.lower() in local_types :
         param_type_elem = make_reference_elem('type %s' % param_type, local_types).add_content([param_type_elem])
      if param_dflt :
         param_dflt_elem = HtmlElem('span', attrs=[('class', 'param-value')], content=format(param_dflt))
         if param_dflt.lower() in local_names :
            param_dflt_elem = make_reference_elem('dflt %s' % param_dflt, local_names).add_content([param_dflt_elem])
      if i == 0 : col2.add_content([HtmlElem('span', attrs=[('class', 'parentheses')], content='(')])
      col2.add_content([
         HtmlElem('span', attrs=[('class', 'param-name')], content=format(param_name, False)),
         HtmlElem('span', attrs=[('class', 'keyword')], content=format(param_usage, False))])
      if param_dflt :
         col2.add_content([
            param_type_elem,
            HtmlElem('span', attrs=[('class', 'keyword')], content=format(' default ', False))])
         span = HtmlElem('span', attrs=[('class', 'inline')], content=[param_dflt_elem])
      else :
         span = HtmlElem('span', attrs=[('class', 'inline')], content=[param_type_elem])
      if i == param_count - 1 :
         span.add_content([HtmlElem('span', attrs=[('class', 'parentheses')], content=')')])
      else :
         span.add_content([HtmlElem('span', attrs=[('class', 'comma')], content=',')])
      col2.add_content([span])
   jdoc = JDoc(replace_synonyms(jdoc_text))
   if jdoc.has_description() : col2.add_brief(jdoc)
   summary_table.add_content([HtmlElem('tr', [col1, col2])])
   #-----------------------#
   # build routine details #
   #-----------------------#
   details_div.add_content([HtmlElem('a', attrs=[('name', anchor)])])
   if return_type :
      return_type_elem = HtmlElem('span', attrs=[('class', 'param-type')], content=format(return_type))
      if fmt_type_names.has_key(return_type.upper()) or return_type.lower() in local_types :
         return_type_elem = make_reference_elem('type %s' % return_type, local_types).add_content([return_type_elem])
      details_div.add_content([
         return_type_elem,
         HtmlElem('br')])
   details_div.add_content([
      HtmlElem('span', attrs=[('class', 'keyword')], content=format(routine_type)),
      HtmlElem('', '&nbsp;')])
   if param_count == 0 :
      routine_table = HtmlElem('table', attrs=[('class', 'members')], content= [
         HtmlElem('tr', [
            HtmlElem('td', [
               HtmlElem('span', attrs=[('class', 'routine-name')], content=format(routine_name, False))])])])
   else :
      for i in range(param_count) :
         param_name, param_usage, param_type, param_dflt = params[i]
         col1 = HtmlElem('td')
         if i == 0 :
            col1.add_content([
               HtmlElem('span', attrs=[('class', 'routine-name')], content=format(routine_name, False)),
               HtmlElem('span', attrs=[('class', 'parentheses')], content='(')])
         col2 = HtmlElem('td', [HtmlElem('span', attrs=[('class', 'param-name')], content=(format(param_name, False)))])
         col3 = HtmlElem('td', [
            HtmlElem('', '&nbsp;'),
            HtmlElem('span', attrs=[('class', 'keyword')], content=format(param_usage, False)),
            HtmlElem('', '&nbsp;')])
         param_type_elem = HtmlElem('span', attrs=[('class', 'param-type')], content=format(param_type))
         if fmt_type_names.has_key(param_type.upper()) or param_type.lower() in local_types :
            param_type_elem = make_reference_elem('type %s' % param_type, local_types).add_content([param_type_elem])
         col4 = HtmlElem('td', [param_type_elem])
         if param_dflt :
            param_dflt_elem = HtmlElem('span', attrs=[('class', 'param-value')], content=format(param_dflt))
            if param_dflt.lower() in local_names :
               param_dflt_elem = make_reference_elem('dflt %s' % param_dflt, local_names).add_content([param_dflt_elem])
            col4.add_content([
               HtmlElem('span', attrs=[('class', 'keyword')], content=format(' default ', False)),
               param_dflt_elem])
         if i == param_count - 1 :
            col4.add_content([HtmlElem('span', attrs=[('class', 'parentheses')], content=')')])
         else :
            col4.add_content([HtmlElem('span', attrs=[('class', 'comma')], content=',')])
         if i == 0 :
            routine_table = HtmlElem('table', attrs=[('class', 'members')], content= [
               HtmlElem('tr', [col1, col2, col3, col4])])
         else :
            routine_table.add_content([HtmlElem('tr', [col1, col2, col3, col4])])
   details_div.add_content([routine_table]).add_content(jdoc, local_names).add_content([HtmlElem('p'), HtmlElem('hr')])

def find_last_match(pattern_text, pattern_flags, search_text) :
   '''
   For some reason I have trouble getting a javadoc+item combination pattern to retrieve
   just the LAST javadoc before the item.  It seems to want to retrieve from the FIRST
   javadoc in the file all the way through to the end of the item when the item is the
   first of its type in the file.
   '''
   last_match = None
   pos = 0
   matcher = get_pattern(pattern_text, pattern_flags).matcher(search_text)
   while matcher.find(pos) :
      last_match = matcher.group()
      pos = matcher.end()
   return last_match

def get_type_text(type_name) :
   '''
   Retrieves the source text for a type
   '''
   lines = []
   stmt = conn.createStatement()
   rs = stmt.executeQuery("select text from user_source where name = '%s' and type = 'TYPE' order by line" % type_name)
   while rs.next() :
      lines.append(rs.getString(1))
   rs.close()
   stmt.close()
   return clean_text(''.join(lines))

def get_base_type_fields(base_type_name) :
   '''
   Retrieve information about a base type
   '''
   fields=[]
   if base_type_name != 'OBJECT' :
      text = get_type_text(base_type_name)
      jdoc_comment2_pattern = get_pattern(re_jdoc_comment2, 'imd')
      obj_type_pattern = get_pattern(re_obj_type, 'imd')
      obj_routines_pattern = get_pattern(re_obj_routines, 'imd')
      obj_field_pattern = get_pattern(re_obj_field, 'imd')
      jdoc_matcher = jdoc_comment2_pattern.matcher(text)
      obj_type_matcher = obj_type_pattern.matcher(text)
      if jdoc_matcher.find() :
         jdoc_text = jdoc_matcher.group(1)
         text = text.replace(jdoc_text, '').strip()
         jdoc_text = replace_synonyms(jdoc_text)
         jdoc = JDoc(jdoc_text)
         jdoc._params_name = 'Fields'
      assert obj_type_matcher.find()
      base_type = obj_type_matcher.group(5).upper().split()[1]
      fields = get_base_type_fields(base_type)
      type_text  = obj_type_matcher.group(7)
      type_text2 = jdoc_comment2_pattern.matcher(type_text).replaceAll('')
      matcher    = obj_routines_pattern.matcher(type_text2)
      if matcher.find() :
         routines_text = matcher.group(0)
         fields_text = type_text2.replace(routines_text, '').strip()
      else :
         routines_text = None
         fields_text = type_text2
      pos = 0
      matcher = obj_field_pattern.matcher(fields_text)
      while matcher.find(pos) :
         fields.append(fields_text[matcher.start():matcher.end()])
         pos = matcher.end()
   return fields

class JDoc :
   '''
   Parses jdoc text and allows access to components
   '''
   def __init__(self, jdoc_text) :
      self._deprecated  = ''
      self._since       = ''
      self._description = ''
      self._return      = ''
      self._params_name = 'Parameters'
      self._see_also    = []
      self._authors     = []
      self._params      = []
      self._exceptions  = []
      self._params_by_name = {}
      self._parse(jdoc_text)

   def _parse(self, text) :
      '''
      Parses the text into components
      '''
      tag_token = '~!~!~'
      ACTUAL, REPLACEMENT = 0, 1
      space   = (' ',  chr(0))
      tab     = ('\t', chr(1))
      newline = ('\n', chr(2))
      lines = text[text.find('/**')+3:text.rfind('*/')+1].split('\n') # split text on newlines
      prefix_pattern = get_pattern('^\s*[*]\s?') # trims at most 1 space after '*'
      at_pattern = get_pattern('^\s*@')          # trims any remaining speces before '@'
      preformatted_level = 0
      for i in range(len(lines)) :
         # handle <pre></pre> blocks
         lines[i] = prefix_pattern.matcher(lines[i]).replaceAll('')
         pos = -1
         while True :
            pos = lines[i].find('<pre>', pos+1)
            if pos == -1 : break
            preformatted_level += 1
         pos = -1
         while True :
            pos = lines[i].find('</pre>', pos+1)
            if pos == -1 : break
            preformatted_level -= 1
         if preformatted_level > 0 :
            lines[i] = lines[i].replace(space[ACTUAL], space[REPLACEMENT]).replace(tab[ACTUAL], tab[REPLACEMENT]) + newline[REPLACEMENT]
         lines[i] = at_pattern.matcher(lines[i].strip()).replaceAll(tag_token+'@')
      # re-split text around javadoc tags
      sections = space[ACTUAL].join(lines).strip().split(tag_token)
      for section in sections :
         # re-constitue any <pre></pre> blocks
         section = section.replace(space[REPLACEMENT], space[ACTUAL]).replace(tab[REPLACEMENT], tab[ACTUAL]).replace(newline[REPLACEMENT], newline[ACTUAL])
         if section[0] == '@' :
            tag = section.split()[0]
            section = section[len(tag):].strip()
            if   tag == '@deprecated' :
               if self._deprecated : raise ValueError('Multiple @deprecated tags encountered');
               self._deprecated = section
            elif tag == '@author' :
               self._authors.append(section)
            elif tag == '@since' :
               if self._since : raise ValueError('Multiple @since tags encountered');
               self._since = section
            elif tag in ('@param', '@member', '@field') :
               self._params.append(section)
               param_name = section.split()[0]
               section = section[len(param_name):].strip()
               self._params_by_name[param_name.lower()] = section
            elif tag == '@return' :
               if self._return : raise ValueError('Multiple @return tags encountered');
               self._return = section
            elif tag in ('@exception', '@throws') :
               self._exceptions.append(section)
            elif tag == '@see' :
               self._see_also.append(section)
            else : raise ValueError('Unexpected tag: %s' % tag)
         else :
            if self._description : raise ValueError('Cannot have multiple descriptions.')
            self._description = section.strip()

   def description(self)      : return self._description
   def has_description(self)  : return bool(self._description)
   def authors(self)          : return self._authors
   def author_count(self)     : return len(self._authors)
   def has_authors(self)      : return self.author_count() > 0
   def params(self)           : return self._params
   def param_count(self)      : return len(self._params)
   def has_params(self)       : return self.param_count() > 0
   def members(self)          : return self._params
   def member_count(self)     : return len(self._params)
   def has_members(self)      : return self.member_count() > 0
   def exceptions(self)       : return self._exceptions
   def exception_count(self)  : return len(self._exceptions)
   def has_exceptions(self)   : return self.exception_count() > 0
   def see_also(self)         : return self._see_also
   def see_also_count(self)   : return len(self._see_also)
   def has_see_also(self)     : return self.see_also_count() > 0
   def returns(self)          : return self._return
   def has_return(self)       : return bool(self._return)
   def deprecated(self)       : return self._deprecated
   def is_deprecated(self)    : return bool(self._deprecated)
   def since(self)            : return self._since
   def has_since(self)        : return bool(self._since)
   def get_param(self, name)  : return self._params_by_name[name.lower()]

class HtmlElem :
   '''
   Simple class to construct and output HTML
   '''
   def __init__(self, tagName, content=None, attrs=None) :
      self._tag = tagName
      self._text = ''
      self._attrs = {}
      self._children = []
      if content :
         self.add_content(content)
      if attrs :
         if type(attrs) not in (type(()), type([])) : raise TypeError('Unexpected attrs type: %s' % type(attrs))
         for key, value in attrs : self._attrs[key] = value

   def set_attr(self, key, value) :
      self._attrs[key] = value
      return self

   def add_content(self, content, local_names=[]) :
      if   type(content) in (type(''), type(u'')) :
         if self._children : raise ValueError('Cannot add text to element that contains child elements');
         self._text += content
      elif type(content) in (type(()), type([])) :
         if self._text : raise ValueError('Cannot add child elements to element that contains text');
         self._children.extend(content)
      elif type(content) == type(self) :
         type_name = content.__class__.__name__
         if type_name == 'JDoc' :
            self.add_deprecated(content)
            self.add_description(content)
            self.add_authors(content)
            self.add_since(content)
            self.add_params(content)
            self.add_return(content)
            self.add_exceptions(content)
            self.add_see_also(content, local_names)
         else :
            raise TypeError('Unexpected content type: %s' % type_name)
      else : raise TypeError('Unexpected content type: %s' % type(content))
      return self

   def add_deprecated(self, jdoc) :
      if jdoc.is_deprecated() :
         self.add_content([
            HtmlElem('p'),
            HtmlElem('dl', [
               HtmlElem('dt', [
                  HtmlElem('b', 'Deprecated'),
                  HtmlElem('dl', [HtmlElem('dt', jdoc.deprecated())])])])])
      return self

   def add_brief(self, jdoc) :
      if jdoc.has_description() :
         self.add_content([
            HtmlElem('p'),
            HtmlElem('', brief(jdoc.description()))])
      return self

   def add_description(self, jdoc) :
      if jdoc.has_description() :
         self.add_content([
            HtmlElem('p'),
            HtmlElem('', jdoc.description())])
      return self

   def add_authors(self, jdoc) :
      if jdoc.has_authors() :
         self.add_content([
            HtmlElem('p'),
            HtmlElem('dl', [
               HtmlElem('dt', \
                  [HtmlElem('b', 'Authors')] + \
                  [HtmlElem('dl', [HtmlElem('dt', author) for author in jdoc.authors()])])])])
      return self

   def add_since(self, jdoc) :
      if jdoc.has_since() :
         self.add_content([
            HtmlElem('p'),
            HtmlElem('dl', [
               HtmlElem('dt', [
                  HtmlElem('b', 'Since'),
                  HtmlElem('dl', [HtmlElem('dt', jdoc.since())])])])])
      return self

   def add_params(self, jdoc) :
      if jdoc.has_params() :
         definitions = []
         for param in jdoc.params() :
            param_name = param.split()[0]
            param_def = param[len(param_name):].strip()
            definitions.append(HtmlElem('dt', [HtmlElem('span', attrs=[('class', 'param-name')], content=format(param_name, False))]))
            definitions.append(HtmlElem('dd', param_def))
            definitions.append(HtmlElem('br'))
         self.add_content([
            HtmlElem('p'),
            HtmlElem('dl', [
               HtmlElem('dt', \
                  [HtmlElem('b', jdoc._params_name)] + \
                  [HtmlElem('dl', definitions)])])])
      return self

   def add_return(self, jdoc) :
      if jdoc.has_return() :
         self.add_content([
            HtmlElem('p'),
            HtmlElem('dl', [
               HtmlElem('dt', [
                  HtmlElem('b', 'Returns'),
                  HtmlElem('dl', [HtmlElem('dt', jdoc.returns())])])])])
      return self

   def add_exceptions(self, jdoc) :
      if jdoc.has_exceptions() :
         definitions = []
         for exc in jdoc.exceptions() :
            exc_name = exc.split()[0]
            exc_def = exc[len(exc_name):].strip()
            definitions.append(HtmlElem('dt', [HtmlElem('span', attrs=[('class', 'param-type')], content=format(exc_name, False))]))
            definitions.append(HtmlElem('dd', exc_def))
            definitions.append(HtmlElem('br'))
         self.add_content([
            HtmlElem('p'),
            HtmlElem('dl', [
               HtmlElem('dt', \
                  [HtmlElem('b', 'Exceptions')] + \
                  [HtmlElem('dl', definitions)])])])
      return self

   def add_see_also(self, jdoc, local_names=[]) :
      if jdoc.has_see_also() :
         self.add_content([
            HtmlElem('p'),
            HtmlElem('dl', [
               HtmlElem('dt', \
                  [HtmlElem('b', 'See Also')] + \
                  [HtmlElem('dl', [make_reference_elem(ref_text, local_names).add_content([HtmlElem('dt', format(ref_text))]) for ref_text in jdoc.see_also()])])])])
      return self

   def add_summary(self, jdoc, local_names=[]) :
      self.add_deprecated(jdoc).add_description(jdoc).add_authors(jdoc).add_since(jdoc).add_see_also(jdoc, local_names)

   def get_content(self, pretty=True, indent='  ', level=0, buffer=None) :
      prefix = ''
      top_level = buffer == None
      if top_level : buffer = StringIO.StringIO()
      if pretty : prefix = level * indent
      if self._tag or self._text :
         buffer.write(prefix)
      else :
         level -= 1
      if self._tag == 'html' :
         buffer.write('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">');
         if pretty : buffer.write('\n')
      if self._tag : buffer.write('<' + self._tag)
      for key in self._attrs.keys() : buffer.write(' %s="%s"' % (key, self._attrs[key]))
      if self._children :
         if self._tag :
            buffer.write('>')
            if pretty : buffer.write('\n')
         for child in self._children : child.get_content(pretty, indent, level+1, buffer)
         if self._tag :
            buffer.write(prefix + '</' + self._tag + '>')
            if pretty : buffer.write('\n')
      elif self._text :
         if self._tag : buffer.write('>')
         buffer.write(self._text)
         if self._tag : buffer.write('</' + self._tag + '>');
         if  pretty : buffer.write('\n')
      else :
         if self._tag :
            if self._tag not in ('p', 'br', 'hr') : buffer.write('/')
            buffer.write('>')
            if pretty : buffer.write('\n')
      if top_level :
         text = buffer.getvalue()
         buffer.close()
         return text

def build_main_page() :
   '''
   Builds the HTML for the main documentation page.
   '''
   def build_item_list(item_type, items) :
      '''
      Builds elements lists
      '''
      content = []
      for i in range(len(items)) :
         try    : formatted = format(items[i])
         except : formatted = items[i]
         if item_type == 'package' :
            title = 'Package '
            links = package_links
         elif item_type == 'view' :
            title = 'View '
            links = view_links
         else :
            raise ValueError('Item type must be "package" or "view"')
         try :
            dt = HtmlElem('dt', content = [
               HtmlElem('', content=title),
               HtmlElem('a', attrs=[('href', links[formatted])], content=formatted)])
         except KeyError :
            dt = HtmlElem('dt', content='%s%s' % (title, formatted))
         dl = HtmlElem('dl', content=[dt])
         try    :
            dl.add_content([HtmlElem('dd', content=brief_descriptions[items[i].upper()])])
         except :
            pass
         content.append(dl)
      return content

   def build_item_lists(packages, views) :
      '''
      Builds packages and element lists
      '''
      content = []
      packages_content = build_item_list('package', packages)
      views_content = build_item_list('view', views)
      if packages_content : content.extend(packages_content)
      if views_content : content.extend(views_content)
      return content

   head = HtmlElem('head', content=[HtmlElem('title', content='CWMS Database API Documentation')])
   category_list = [
      HtmlElem('h3', content='API Categories'),
      HtmlElem('a', attrs=[('href', '#Locations and Time Series')], content='Locations and Time Series'),
      HtmlElem('br'),
      HtmlElem('a', attrs=[('href', '#Basins and Streams')], content='Basins and Streams'),
      HtmlElem('br'),
      HtmlElem('a', attrs=[('href', '#Projects, Structures, and Project Usage')], content='Projects, Structures, and Project Usage'),
      HtmlElem('br'),
      HtmlElem('a', attrs=[('href', '#Levels, Rule Curves, and Ratings')], content='Levels, Rule Curves, and Ratings'),
      HtmlElem('br'),
      HtmlElem('a', attrs=[('href', '#Forecasts and Model Runs')], content='Forecasts and Model Runs'),
      HtmlElem('br'),
      HtmlElem('a', attrs=[('href', '#Gages, Sensors, GOES, SHEF, Decoding, and Screening')], content='Gages, Sensors, GOES, SHEF, Decoding, and Screening'),
      HtmlElem('br'),
      HtmlElem('a', attrs=[('href', '#Oracle/HEC-DSS Data Exchange')], content='Oracle/HEC-DSS Data Exchange'),
      HtmlElem('br'),
      HtmlElem('a', attrs=[('href', '#Display Units and Scales')], content='Display Units and Scales'),
      HtmlElem('br'),
      HtmlElem('a', attrs=[('href', '#Miscellaneous and Support')], content='Miscellaneous and Support')
   ]
   api_usage_note = [
      HtmlElem('h3', content='API Usage Note - Please Read!'),
      HtmlElem('', 'Make sure to take the following steps when using the CWMS Database API to ensure your applications work correctly both now and after the database is modified:'),
      HtmlElem('dl', content = [
         HtmlElem('dt', content=[HtmlElem('strong', content="<em>Don't</em> Specify the Schema")]),
         HtmlElem('dd', content="All packages, types, and views have public synonyms (e.g., 'CWMS_TS' for the 'CWMS_20.CWMS_TS' package). If you specify the schema your application <em>will break</em> when a different schema name is used in the future."),
         HtmlElem('p'),
         HtmlElem('dt', content=[HtmlElem('strong', content="<em>Do</em> Use Public Synonyms")]),
         HtmlElem('dd', content="Always use the 'CWMS_V_...' view synonyms and the 'CWMS_T_...' type synonyms. These will not change in the futue even if the names of the underlying objects do."),
         HtmlElem('p'),
         HtmlElem('dt', content=[HtmlElem('strong', content="<em>Don't</em> Use the \"CWMS\" Schema Account")]),
         HtmlElem('dd', content="The \"CWMS\" schema account (currently 'CWMS_20') is designed to be used for administration purposes <em>only</em>. Its password is <em>not</em> guaranteed to remain constant, nor is it assigned an office identifier.  Do <em>not</em> use this account for local applications.")
      ])
   ]
   documents_list = [
      HtmlElem('h3', content='General Documents'),
      HtmlElem('a', attrs=[('href', 'CWMS Database Naming.pdf')], content='CWMS Database Naming'),
      HtmlElem('br'),
      HtmlElem('a', attrs=[('href', 'CWMS RATINGS.pdf')], content='CWMS Ratings'),
      HtmlElem('br'),
      HtmlElem('a', attrs=[('href', 'CWMS LOCATION LEVELS.pdf')], content='CWMS Location Levels'),
      HtmlElem('br'),
      HtmlElem('a', attrs=[('href', 'CWMS Properties Dictionary.pdf')], content='CWMS User Properties'),
      HtmlElem('br'),
      HtmlElem('a', attrs=[('href', 'Text and Binary Data in the CWMS Database.pdf')], content='CWMS Text and Binary Data (Standalone and Time Series)')
   ]
   example_list = [
      HtmlElem('h3', content='API Usage Examples'),
      HtmlElem('', content= 'Examples of accessing the CWMS database and using the API from various programming languages are available on the '),
      HtmlElem('a', attrs=[('href', 'https://cwms.usace.army.mil/dokuwiki/')], content='CWMS Wiki'),
      HtmlElem('', content=' at '),
      HtmlElem('a', attrs=[('href', 'https://cwms.usace.army.mil/dokuwiki/doku.php?id=database_api:sample_programs')], content='this location'),
      HtmlElem('', content='.'),
   ]
   items_list = HtmlElem('dl', content=[
      HtmlElem('a', attrs=[('name', 'Locations and Time Series')]),
      HtmlElem('dt', content=[HtmlElem('h3', content='Locations and Time Series')]),
      HtmlElem('dd', content=build_item_lists(
         packages = ['cwms_loc', 'cwms_ts'],
         views    = ['av_loc', 'av_loc_alias', 'av_loc_cat_grp', 'av_loc_grp_assgn', 'av_tsv',
                     'av_tsv_dqu', 'av_ts_alias', 'av_ts_cat_grp', 'av_ts_grp_assgn', 'av_ts_association']))])
   items_list.add_content([
      HtmlElem('a', attrs=[('name', 'Basins and Streams')]),
      HtmlElem('dt', content=[HtmlElem('h3', content='Basins and Streams')]),
      HtmlElem('dd', content=build_item_lists(
         packages = ['cwms_basin', 'cwms_stream'],
         views    = ['av_stream_types']))])
   items_list.add_content([
      HtmlElem('a', attrs=[('name', 'Projects, Structures, and Project Usage')]),
      HtmlElem('dt', content=[HtmlElem('h3', content='Projects, Structures, and Project Usage')]),
      HtmlElem('dd', content=build_item_lists(
         packages = ['cwms_project', 'cwms_embank', 'cwms_outlet', 'cwms_turbine', 'cwms_lock', 'cwms_water_supply'],
         views    = ['av_gate_change', 'av_gate_setting', 'av_outlet', 'av_project', 'av_turbine', 'av_turbine_change', 'av_turbine_setting']))])
   items_list.add_content([
      HtmlElem('a', attrs=[('name', 'Levels, Rule Curves, and Ratings')]),
      HtmlElem('dt', content=[HtmlElem('h3', content='Levels, Rule Curves, and Ratings')]),
      HtmlElem('dd', content=build_item_lists(
         packages = ['cwms_level', 'cwms_rating'],
         views    = ['av_loc_lvl_cur_max_ind', 'av_loc_lvl_indicator', 'av_loc_lvl_indicator_2', 'av_loc_lvl_ts_map', 'av_location_level',
                     'av_rating', 'av_rating_local', 'av_rating_spec','av_rating_template', 'av_rating_values', 'av_rating_values_native']))])
   items_list.add_content([
      HtmlElem('a', attrs=[('name', 'Forecasts and Model Runs')]),
      HtmlElem('dt', content=[HtmlElem('h3', content='Forecasts and Model Runs')]),
      HtmlElem('dd', content=build_item_lists(
         packages = ['cwms_forecast'],
         views    = []))])
   items_list.add_content([
      HtmlElem('a', attrs=[('name', 'Gages, Sensors, GOES, SHEF, Decoding, and Screening')]),
      HtmlElem('dt', content=[HtmlElem('h3', content='Gages, Sensors, GOES, SHEF, Decoding, and Screening')]),
      HtmlElem('dd', content=build_item_lists(
         packages = ['cwms_gage', 'cwms_shef', 'cwms_vt'],
         views    = ['av_active_flag', 'av_data_streams', 'av_data_streams_current', 'av_screened_ts_ids', 'av_screening_assignments',
                     'av_screening_criteria', 'av_screening_dur_mag', 'av_screening_id', 'av_shef_decode_spec', 'av_shef_pe_codes']))])
   items_list.add_content([
      HtmlElem('a', attrs=[('name', 'Oracle/HEC-DSS Data Exchange')]),
      HtmlElem('dt', content=[HtmlElem('h3', content='Oracle/HEC-DSS Data Exchange')]),
      HtmlElem('dd', content=build_item_lists(
         packages = ['cwms_xchg'],
         views    = ['av_dataexchange_job']))])
   items_list.add_content([
      HtmlElem('a', attrs=[('name', 'Display Units and Scales')]),
      HtmlElem('dt', content=[HtmlElem('h3', content='Display Units and Scales')]),
      HtmlElem('dd', content=build_item_lists(
         packages = ['cwms_display'],
         views    = ['av_display_units']))])
   items_list.add_content([
      HtmlElem('a', attrs=[('name', 'Miscellaneous and Support')]),
      HtmlElem('dt', content=[HtmlElem('h3', content='Miscellaneous and Support')]),
      HtmlElem('dd', content=build_item_lists(
         packages = ['cwms_cat', 'cwms_lookup', 'cwms_msg', 'cwms_properties', 'cwms_rounding', 'cwms_text', 'cwms_util'],
         views    = ['av_data_q_changed', 'av_data_q_protection', 'av_data_q_range', 'av_data_q_repl_cause', 'av_data_q_repl_method',
                     'av_data_q_screened', 'av_data_q_test_failed', 'av_data_q_validity', 'av_data_quality', 'av_log_message',
                     'mv_time_zone', 'av_parameter', 'av_state', 'av_storage_unit', 'av_unit']))])
   body = HtmlElem('body', content= \
      [HtmlElem('h2', attrs=[('style', 'text-align:center;')], content='CWMS Database API Documentation')] +\
      category_list + \
      [HtmlElem('p'), HtmlElem('hr')] + \
      api_usage_note + \
      [HtmlElem('p'), HtmlElem('hr')] + \
      example_list + \
      [HtmlElem('p'), HtmlElem('hr')] + \
      documents_list + \
      [HtmlElem('p'), HtmlElem('hr'), items_list])
   page = HtmlElem('html', content=[head, body])
   return page.get_content()

#--------------------------#
# process the command line #
#--------------------------#
VALUE, IS_SET = 0, 1
option_info = {
   'd' : [None, False, 'Database'],
   'u' : [None, False, 'User name'],
   'p' : [None, False, 'Password'],
   'o' : [None, False, 'Output directory'],
   'e' : [None, False, 'External file directory']
}
option_chars = option_info.keys()
opts, args = getopt.gnu_getopt(sys.argv[1:], ':'.join(option_chars))
for opt, val in opts :
   opt_char = opt[1]
   if opt_char == 'd' and val == '' and args:
      val = args[0]
      args = args[1:]
   if opt_char in option_chars :
      opt_val, is_set, item_name = option_info[opt_char]
      if is_set : usage("%s already set" % item_name)
      option_info[opt_char][VALUE] = val
      option_info[opt_char][IS_SET] = True
   else :
      usage('Unexpected option specified: %s' % opt)
error_message = ''
for opt in option_chars :
   if not option_info[opt][1] : error_message += "%s not specified\n" % option_info[opt][2]
if error_message : usage(error_message)
if args : usage('Unexpected argument specified: %s' % args[0])
conn_str = option_info['d'][VALUE]
username = option_info['u'][VALUE]
password = option_info['p'][VALUE]
output_dir = option_info['o'][VALUE]
external_docs_dir = option_info['e'][VALUE]

if not os.path.exists(output_dir) : os.makedirs(output_dir)
#---------------------#
# connect to database #
#---------------------#
db_url     = 'jdbc:oracle:thin:@%s' % conn_str
stmt   = None
rs     = None
driver = java.sql.DriverManager.registerDriver(oracle.jdbc.driver.OracleDriver());
conn   = java.sql.DriverManager.getConnection(db_url, username, password);
conn.setAutoCommit(False)
try :
   if use_synonyms :
      #-------------------------#
      # get the public synonyms #
      #-------------------------#
      output3('synonyms')
      stmt = conn.prepareStatement('''
         select synonym_name,
                table_name
           from dba_synonyms
          where owner = 'PUBLIC'
            and table_owner = 'CWMS_20'
            and synonym_name not like '/%' '''.strip())
      rs = stmt.executeQuery()
      while rs.next() :
         synonym = rs.getString(1)
         realName = rs.getString(2)
         synonyms[realName] = synonym
      rs.close()
      stmt.close()
      output2('%d' % len(synonyms))
   #----------------------------#
   # get the user defined types #
   #----------------------------#
   output3('types')
   fmt_type_names = {}
   raw_type_names = {}
   stmt = conn.prepareStatement('''
      select type_name
        from user_types
       where type_name not like 'SYS\_%' escape '\\' '''.strip())
   rs = stmt.executeQuery()
   while rs.next() :
      type_name = rs.getString(1)
      formatted = format(type_name)
      fmt_type_names[type_name] = formatted
      raw_type_names[formatted] = type_name
   rs.close()
   stmt.close()
   output2('%d' % len(raw_type_names))
   #---------------#
   # get the views #
   #---------------#
   output3('views')
   fmt_view_names = {}
   raw_view_names = {}
   stmt = conn.prepareStatement('''
      select view_name
        from user_views
       where view_name not like 'AQ%' '''.strip())
   rs = stmt.executeQuery()
   while rs.next() :
      viewName = rs.getString(1)
      formatted = format(viewName)
      fmt_view_names[(viewName, False)] = formatted
      raw_view_names[formatted] = (viewName, False)
   rs.close()
   stmt.close()
   stmt = conn.prepareStatement('''
      select table_name
        from user_snapshots
       where table_name not like '%_SEC_%' '''.strip())
   rs = stmt.executeQuery()
   while rs.next() :
      view_name = rs.getString(1)
      formatted = format(view_name)
      fmt_view_names[(view_name, True)] = formatted
      raw_view_names[formatted] = (view_name, True)
   rs.close()
   output2('%d' % len(raw_view_names))
   #------------------#
   # get the packages #
   #------------------#
   output3('packages')
   package_names = []
   stmt = conn.prepareStatement('''
      select object_name
        from user_objects
       where object_type = 'PACKAGE'
         and object_name not like '%_SEC_%' '''.strip())
   rs = stmt.executeQuery()
   while rs.next() :
      package_names.append(rs.getString(1))
   rs.close()
   stmt.close()
   output2('%d' % len(package_names))
   #----------------------#
   # process the packages #
   #----------------------#
   stmt = conn.prepareStatement('''
      select text
        from user_source
       where name = :1
         and type = 'PACKAGE'
    order by line'''.strip())
   jdoc_pkg_pattern     = get_pattern(re_jdoc_pkg, 'imd')
   jdoc_type_pattern    = get_pattern(re_pkg_jdoc_type, 'imd')
   jdoc_const_pattern   = get_pattern(re_pkg_jdoc_const, 'imd')
   jdoc_var_pattern     = get_pattern(re_pkg_jdoc_var, 'imd')
   jdoc_routine_pattern = get_pattern(re_pkg_jdoc_routine, 'imd')
   for package_name in sorted(package_names) :
      output1('package', package_name)
      lines = []
      stmt.setString(1, package_name)
      rs = stmt.executeQuery()
      while rs.next() :
         lines.append(rs.getString(1))
      rs.close()
      text = clean_text(''.join(lines))
      pkg_matcher = jdoc_pkg_pattern.matcher(text)
      if not pkg_matcher.find() :
         output2('not documented.')
         continue
      jdoc_text   = pkg_matcher.group(6)
      jdoc        = JDoc(jdoc_text)
      pkg_text    = text.replace(jdoc_text, '').strip()
      top_div     = HtmlElem('div')
      summary_div = HtmlElem('div')
      details_div = HtmlElem('div')
      brief_descriptions[package_name] = brief(jdoc.description())
      page = HtmlElem(
         'html', [
            HtmlElem(
               'head', [
                  HtmlElem('title', 'Package %s' % format(package_name)),
                  HtmlElem('link', attrs = [('rel','stylesheet'),('type','text/css'),('href',css_filename)])]),
            HtmlElem(
               'body', [
                  HtmlElem('span', attrs = [('class','top-level')], content='%s %s' % (format('Package', False), format(package_name))),
                  top_div,
                  HtmlElem('p'),
                  summary_div,
                  HtmlElem('p'),
                  details_div])])
      top_div.add_summary(jdoc)
      tokenized, replacements = tokenize(pkg_text)
      #-----------------------#
      # collect package types #
      #-----------------------#
      pos = 0
      types = []
      type_matcher = jdoc_type_pattern.matcher(tokenized)
      field_pattern = get_pattern(re_obj_field, 'imd')
      while type_matcher.find(pos) :
         jdoc_text        = untokenize(find_last_match(re_jdoc_comment, 'imd', type_matcher.group()), replacements)
         type_name        = untokenize(type_matcher.group(4).lower(), replacements)
         type_fields_text = type_matcher.group(6)              # for record types
         type_elem_type   = untokenize(type_matcher.group(9), replacements)  # for table and assoc array types
         type_elem_size   = untokenize(type_matcher.group(21), replacements) # for table and assoc array  types
         type_indx_type   = untokenize(type_matcher.group(25), replacements) # for assoc array types
         type_indx_size   = untokenize(type_matcher.group(27), replacements) # for assoc array types
         type_fields = []
         if type_fields_text :
            pos = 0
            matcher = field_pattern.matcher(type_fields_text)
            while matcher.find(pos) :
               untokenize(type_fields.append(type_fields_text[matcher.start():matcher.end()]), replacements)
               pos = matcher.end()
         types.append((type_name, type_fields, type_elem_type, type_elem_size, type_indx_type, type_indx_size, jdoc_text))
         pos = type_matcher.end()
      local_type_names = [t[0].lower() for t in types]
      #---------------------------#
      # collect package constants #
      #---------------------------#
      pos = 0
      consts = []
      const_matcher = jdoc_const_pattern.matcher(tokenized)
      while const_matcher.find(pos) :
         jdoc_text  = untokenize(find_last_match(re_jdoc_comment, 'imd', const_matcher.group()), replacements)
         const_name = untokenize(const_matcher.group(4).lower(), replacements)
         const_type = untokenize(const_matcher.group(6), replacements)
         const_size = untokenize(const_matcher.group(18), replacements) # for table and assoc array types
         const_val  = untokenize(const_matcher.group(22), replacements)
         consts.append((const_name, const_type, const_size, const_val, jdoc_text))
         pos = const_matcher.end()
      local_const_names = [c[0].lower() for c in consts]
      #---------------------------#
      # collect package variables #
      #---------------------------#
      pos = 0
      vars = []
      var_matcher = jdoc_var_pattern.matcher(tokenized)
      while var_matcher.find(pos) :
         jdoc_text = untokenize(find_last_match(re_jdoc_comment, 'imd', var_matcher.group()), replacements)
         var_name  = untokenize(var_matcher.group(4).lower(), replacements)
         if var_name not in ('procedure', 'function') :
            var_type = untokenize(var_matcher.group(6), replacements)
            var_size = untokenize(var_matcher.group(18), replacements) # for table and assoc array types
            var_val  = untokenize(var_matcher.group(22), replacements)
            vars.append((var_name, var_type, var_size, var_val, jdoc_text))
         pos = var_matcher.end()
      local_var_names = [v[0].lower() for v in vars]
      #--------------------------#
      # collect package routines #
      #--------------------------#
      pos = 0
      routines = []
      routine_matcher = jdoc_routine_pattern.matcher(pkg_text)
      while routine_matcher.find(pos) :
         jdoc_text     = find_last_match(re_jdoc_comment, 'imd', routine_matcher.group())
         routine_text = routine_matcher.group(4).strip()
         routine_type = routine_text.split()[0].lower()
         if routine_type == 'function' :
            matcher = get_pattern(re_function, 'imd').matcher(routine_text)
            matcher.find()
            routine_name = matcher.group(2).lower()
            params_text  = matcher.group(3)
            return_type  = matcher.group(5)
         else :
            matcher = get_pattern(re_procedure, 'imd').matcher(routine_text)
            matcher.find()
            routine_name = matcher.group(2).lower()
            params_text  = matcher.group(3)
            return_type  = None
         params, jdoc_text = parse_params(params_text, jdoc_text)
         routines.append((routine_name, routine_type, return_type, params, jdoc_text))
         pos = routine_matcher.end()
      #-----------------------#
      # process package types #
      #-----------------------#
      if types :
         summary_table = \
            HtmlElem('table', attrs=[('class', 'summary')], content=[
               HtmlElem('tr', [
                  HtmlElem('th', attrs=[('colspan', '2')], content='Data Types Summary')])])
         summary_div.add_content([summary_table, HtmlElem('p')])
         details_div.add_content([
            HtmlElem('table', attrs=[('class', 'summary')], content=[
               HtmlElem('tr', [HtmlElem('th', attrs=[('colspan', '2')], content='Data Types Details')])])])
         for type_name, type_fields, type_elem_type, type_elem_size, type_indx_type, type_indx_size, jdoc_text in sorted(types) :
            jdoc = JDoc(jdoc_text)
            jdoc._params_name = 'Fields'
            anchor = type_name
            if type_fields :
               #-------------#
               # record type #
               #-------------#
               #
               # summary
               #
               field_count = len(type_fields)
               field_elems = []
               for i in range(field_count) :
                  parts = type_fields[i].split()
                  field_name, field_type = parts[0], ' '.join(parts[1:])
                  field_elems.extend([
                     HtmlElem('span', attrs=[('class', 'param-name')], content=format(field_name, False)),
                     HtmlElem('', '&nbsp;'),
                     HtmlElem('span', attrs=[('class', 'param-type')], content=mark_parentheses(format(field_type)))])
                  if i == field_count - 1 :
                     field_elems.append(HtmlElem('span', attrs=[('class', 'parentheses')], content=')'))
                  else :
                     field_elems.extend([
                        HtmlElem('span', attrs=[('class', 'comma')], content=','),
                        HtmlElem('br')])
               summary_table.add_content([
                  HtmlElem('tr', [
                     HtmlElem('td', attrs=[('class', 'routine-type-col')], content=[
                        HtmlElem('a', attrs=[('href', '#%s' % anchor),('title', 'Click for details')], content=[
                           HtmlElem('span', attrs=[('class', 'param-type')], content=format(type_name))])]),
                     HtmlElem('td', attrs=[('class', 'description-col')], content=[
                        HtmlElem('table', attrs=[('class', 'members')], content = [
                           HtmlElem('tr', [
                              HtmlElem('td', attrs=[('style','vertical-align:top')], content=[
                                 HtmlElem('span', attrs=[('class', 'keyword')], content=format('record', False)),
                                 HtmlElem('span', attrs=[('class', 'parentheses')], content=format('(', False))]),
                              HtmlElem('td', field_elems)])]),
                        HtmlElem('p', attrs=[('style','padding-bottom:0px; margin-bottom:0px;')]),
                        HtmlElem('',  brief(jdoc.description()))])])])
               #
               # details
               #
               field_elems = HtmlElem('table', attrs=[('class', 'members')], content = [])
               for i in range(field_count) :
                  parts = type_fields[i].split()
                  field_name, field_type = parts[0], ' '.join(parts[1:])
                  if i == 0 :
                     col1 = HtmlElem('td', [
                        HtmlElem('span', attrs=[('class', 'keyword')], content=format('is record', False)),
                        HtmlElem('span', attrs=[('class', 'parentheses')], content=format('(', False))])
                  else :
                     col1 = HtmlElem('td')
                  col2 = HtmlElem('td', [
                     HtmlElem('span', attrs=[('class', 'param-name')], content=format(field_name, False))])
                  if i == field_count - 1 :
                     col3 = HtmlElem('td', attrs=[('class', 'description-col')], content=[
                        HtmlElem('', '&nbsp;'),
                        HtmlElem('span', attrs=[('class', 'param-type')], content=mark_parentheses(format(field_type))),
                        HtmlElem('span', attrs=[('class', 'parentheses')], content=')')])
                  else :
                     col3 = HtmlElem('td', attrs=[('class', 'description-col')], content=[
                        HtmlElem('', '&nbsp;'),
                        HtmlElem('span', attrs=[('class', 'param-type')], content=mark_parentheses(format(field_type))),
                        HtmlElem('span', attrs=[('class', 'comma')], content=',')])
                  row = HtmlElem('tr', [col1, col2, col3])
                  field_elems.add_content([row])
               details_div.add_content([
                  HtmlElem('', [
                     HtmlElem('br'),
                     HtmlElem('span', attrs=[('class', 'keyword')], content=format('type', False)),
                     HtmlElem('', '&nbsp;'),
                     HtmlElem('span', attrs=[('class', 'param-type')], content=[
                        HtmlElem('a', attrs=[('name', anchor)], content=format(type_name))]),
                     HtmlElem('br')] + \
                     [field_elems] + [\
                     HtmlElem('', jdoc),
                     HtmlElem('p'),
                     HtmlElem('hr')])])
            else :
               #---------------------------------#
               # associative array or table type #
               #---------------------------------#
               if type_elem_size :
                  type_name_elem = HtmlElem('span', attrs=[('class', 'param-type')], content=[
                     HtmlElem('', mark_parentheses('%s(%s)' % (format(type_elem_type, False), type_elem_size)))])
               else :
                  type_name_elem = HtmlElem('span', attrs=[('class', 'param-type')], content=[
                     HtmlElem('', format(type_elem_type, False))])
               if fmt_type_names.has_key(type_elem_type.upper()) or type_elem_type.lower() in local_type_names :
                  type_name_elem = make_reference_elem('type %s' % type_elem_type, local_type_names).add_content([type_name_elem])
               if type_indx_type :
                  #------------------------#
                  # associative array type #
                  #------------------------#
                  type_name_elem.add_content([
                     HtmlElem('span', attrs=[('class', 'keyword')], content=format('index by ', False)),
                     HtmlElem('span', attrs=[('class', 'param-type')], content=format(type_indx_type, False))])
                  if type_indx_size :
                     type_name_elem.add_content([
                        HtmlElem('span', attrs=[('class', 'param-type')], content=mark_parentheses('(%s)' % type_indx_size))])
               #
               # summary
               #
               summary_table.add_content([
                  HtmlElem('tr', [
                     HtmlElem('td', attrs=[('class', 'routine-type-col')], content=[
                        HtmlElem('a', attrs=[('href', '#%s' % anchor),('title', 'Click for details')], content=[
                           HtmlElem('span', attrs=[('class', 'param-type')], content=format(type_name))])]),
                     HtmlElem('td', attrs=[('class', 'description-col')], content=[
                        HtmlElem('span', attrs=[('class', 'keyword')], content=format('table of ', False)),
                        type_name_elem,
                        HtmlElem('p', attrs=[('style','padding-bottom:0px; margin-bottom:0px;')]),
                        HtmlElem('',  brief(jdoc.description()))])])])
               #
               # details
               #
               details_div.add_content([
                  HtmlElem('', [
                     HtmlElem('br'),
                     HtmlElem('span', attrs=[('class', 'keyword')], content=format('type', False)),
                     HtmlElem('', '&nbsp;'),
                     HtmlElem('span', attrs=[('class', 'param-type')], content=[
                        HtmlElem('a', attrs=[('name', anchor)], content=format(type_name))]),
                     HtmlElem('span', attrs=[('class', 'keyword')], content=format('is table of')),
                     type_name_elem,
                     HtmlElem('', jdoc),
                     HtmlElem('p'),
                     HtmlElem('hr')])])
      #---------------------------#
      # process package constants #
      #---------------------------#
      if consts :
         summary_table = \
            HtmlElem('table', attrs=[('class', 'summary')], content=[
               HtmlElem('tr', [
                  HtmlElem('th', attrs=[('colspan', '2')], content='Constants Summary')])])
         summary_div.add_content([summary_table, HtmlElem('p')])
         details_div.add_content([
            HtmlElem('table', attrs=[('class', 'summary')], content=[
               HtmlElem('tr', [HtmlElem('th', attrs=[('colspan', '2')], content='Constants Details')])])])
         for const_name, const_type, const_size, const_val, jdoc_text in sorted(consts) :
            anchor = const_name
            jdoc = JDoc(jdoc_text);
            if const_size :
               const_elem = HtmlElem('', [
                  HtmlElem('span', attrs=[('class', 'keyword')], content=format('constant ', False)),
                  HtmlElem('span', attrs=[('class', 'param-type')], content=[
                     HtmlElem('', mark_parentheses('%s(%s)' % (format(const_type, False), const_size)))])])
            else :
               const_elem = HtmlElem('', [
                  HtmlElem('span', attrs=[('class', 'keyword')], content=format('constant ', False)),
                  HtmlElem('span', attrs=[('class', 'param-type')], content=[
                     HtmlElem('', format(const_type, False))])])
            if fmt_type_names.has_key(const_type.upper()) or const_type.lower() in local_type_names :
               const_elem = make_reference_elem('type %s' % const_type, local_type_names).add_content([const_elem])
            summary_table.add_content([
               HtmlElem('tr', [
                  HtmlElem('td', attrs=[('class', 'routine-type-col')], content=[
                     HtmlElem('a', attrs=[('href', '#%s' % anchor),('title', 'Click for details')], content=[
                        HtmlElem('span', attrs=[('class', 'param-name')], content=format(const_name))])]),
                  HtmlElem('td', attrs=[('class', 'description-col')], content=[
                     const_elem,
                     HtmlElem('p', attrs=[('style','padding-bottom:0px; margin-bottom:0px;')]),
                     HtmlElem('',  brief(jdoc.description()))])])])
            details_div.add_content([
               HtmlElem('', [
                  HtmlElem('br'),
                  HtmlElem('span', attrs=[('class', 'param-name')], content=[
                     HtmlElem('a', attrs=[('name', anchor)], content=format(const_name))]),
                  const_elem,
                  HtmlElem('span', attrs=[('class', 'keyword')], content=' := '),
                  HtmlElem('span', attrs=[('class', 'param-value')], content=mark_parentheses(format(const_val, False))),
                  HtmlElem('', jdoc),
                  HtmlElem('p'),
                  HtmlElem('hr')])])
      #-------------------------------#
      # process the package variables #
      #-------------------------------#
      if vars :
         summary_table = \
            HtmlElem('table', attrs=[('class', 'summary')], content=[
               HtmlElem('tr', [
                  HtmlElem('th', attrs=[('colspan', '2')], content='Variables Summary')])])
         summary_div.add_content([summary_table, HtmlElem('p')])
         details_div.add_content([
            HtmlElem('table', attrs=[('class', 'summary')], content=[
               HtmlElem('tr', [HtmlElem('th', attrs=[('colspan', '2')], content='Variables Details')])])])
         for var_name, var_type, var_size, var_val, jdoc_text in vars :
            anchor = var_name
            jdoc = JDoc(jdoc_text);
            if var_size :
               var_elem = HtmlElem('', [
                  HtmlElem('span', attrs=[('class', 'param-type')], content=[
                     HtmlElem('', mark_parentheses('%s(%s)' % (format(var_type, False), var_size)))])])
            else :
               var_elem = HtmlElem('', [
                  HtmlElem('span', attrs=[('class', 'param-type')], content=[
                     HtmlElem('', format(var_type, False))])])
            if fmt_type_names.has_key(var_type.upper()) or var_type.lower() in local_type_names :
               var_elem = make_reference_elem('type %s' % var_type, local_type_names).add_content([var_elem])
            summary_table.add_content([
               HtmlElem('tr', [
                  HtmlElem('td', attrs=[('class', 'routine-type-col')], content=[
                     HtmlElem('a', attrs=[('href', '#%s' % anchor),('title', 'Click for details')], content=[
                        HtmlElem('span', attrs=[('class', 'param-name')], content=format(var_name))])]),
                  HtmlElem('td', attrs=[('class', 'description-col')], content=[
                     var_elem,
                     HtmlElem('p', attrs=[('style','padding-bottom:0px; margin-bottom:0px;')]),
                     HtmlElem('',  brief(jdoc.description()))])])])
            if var_val :
               val_elems = [
                  HtmlElem('span', attrs=[('class', 'keyword')], content=' := '),
                  HtmlElem('span', attrs=[('class', 'param-value')], content=mark_parentheses(format(var_val, False)))]
            else :
               val_elems = []
            details_div.add_content([
               HtmlElem('', [
                  HtmlElem('br'),
                  HtmlElem('span', attrs=[('class', 'param-name')], content=[
                     HtmlElem('a', attrs=[('name', anchor)], content=format(var_name))]),
                  var_elem] + val_elems + [
                  HtmlElem('', jdoc),
                  HtmlElem('p'),
                  HtmlElem('hr')])])
      #------------------------------#
      # process the package routines #
      #------------------------------#
      if routines :
         summary_table = \
            HtmlElem('table', attrs=[('class', 'summary')], content=[
               HtmlElem('tr', [
                  HtmlElem('th', attrs=[('colspan', '2')], content='Routines Summary')])])
         summary_div.add_content([summary_table, HtmlElem('p')])
         details_div.add_content([
            HtmlElem('table', attrs=[('class', 'summary')], content=[
               HtmlElem('tr', [HtmlElem('th', attrs=[('colspan', '2')], content='Routines Details')])])])
         for routine_name, routine_type, return_type, params, jdoc_text in sorted(routines) :
            add_routine(summary_table, details_div, routine_name, routine_type, return_type, params, jdoc_text, local_type_names, local_const_names+local_var_names)
      #---------------------------#
      # output the html to a file #
      #---------------------------#
      htmlfilename = 'pkg_%s.html' % package_name.lower()
      package_links[format(package_name)] = htmlfilename
      htmlfilename = os.path.join(output_dir, htmlfilename)
      output2('writing %s' % os.path.abspath(htmlfilename))
      htmlfile = open(htmlfilename, 'w')
      htmlfile.write(page.get_content())
      htmlfile.close()
   stmt.close()

   #-------------------#
   # process the types #
   #-------------------#
   stmt = conn.prepareStatement('''
      select text
        from user_source
       where name = :1
         and type = 'TYPE'
    order by line'''.strip())
   jdoc_type_pattern = get_pattern(re_jdoc_type, 'imd')
   jdoc_comment2_pattern = get_pattern(re_jdoc_comment2, 'imd')
   table_type_pattern = get_pattern(re_table_type, 'imd')
   obj_type_pattern = get_pattern(re_obj_type, 'imd')
   for type_name in sorted(fmt_type_names.keys()) :
      output1('type', type_name)
      lines = []
      stmt.setString(1, type_name)
      rs = stmt.executeQuery()
      while rs.next() :
         lines.append(rs.getString(1))
      rs.close()
      text = clean_text(''.join(lines))
      type_matcher = jdoc_type_pattern.matcher(text)
      if not type_matcher.matches() :
         output2('not documented')
         continue
      #---------------------------------#
      # strip and process the type jdoc #
      #---------------------------------#
      jdoc_matcher = jdoc_comment2_pattern.matcher(text)
      jdoc_matcher.find()
      jdoc_text = jdoc_matcher.group(1)
      text = text.replace(jdoc_text, '').strip()
      jdoc_text = replace_synonyms(jdoc_text)
      jdoc = JDoc(jdoc_text)
      jdoc._params_name = 'Fields'
      #------------------------------------------------------------------------#
      # build as much HTML as we can without knowing what kind of type we have #
      #------------------------------------------------------------------------#
      type_name = text.split()[1].upper()
      top_div     = HtmlElem('div')
      summary_div = HtmlElem('div')
      details_div = HtmlElem('div')
      page = HtmlElem(
         'html', [
            HtmlElem(
               'head', [
                  HtmlElem('title', 'Data Type %s' % fmt_type_names[type_name]),
                  HtmlElem('link', attrs = [('rel','stylesheet'),('type','text/css'),('href',css_filename)])]),
            HtmlElem(
               'body', [
                  HtmlElem('span', attrs = [('class','top-level')], content='%s %s' % (format('type', False), fmt_type_names[type_name])),
                  top_div,
                  HtmlElem('p'),
                  summary_div,
                  HtmlElem('p'),
                  details_div])])
      table_type_matcher = table_type_pattern.matcher(text)
      obj_type_matcher = obj_type_pattern.matcher(text)
      if table_type_matcher.find() :
         #------------#
         # table type #
         #------------#
         top_div.add_summary(jdoc)
         element_type_name = table_type_matcher.group(7).upper()
         element_type_elem = HtmlElem('span', attrs=[('class', 'param-type')], content=mark_parentheses(format(element_type_name)))
         if fmt_type_names.has_key(element_type_name.upper()) or element_type_name.lower() :
            element_type_elem = make_reference_elem('type %s' % element_type_name).add_content([element_type_elem])
         summary_div.add_content([
            HtmlElem('table', attrs=[('class', 'summary')], content=[
               HtmlElem('tr', [
                  HtmlElem('th', attrs=[('colspan', '2')], content='Data Type Summary')]),
               HtmlElem('tr', [
                  HtmlElem('td', attrs=[('class', 'routine-type-col')], content=[
                     HtmlElem('span', attrs=[('class', 'param-type')], content=format(type_name))]),
                  HtmlElem('td', attrs=[('class', 'description-col')], content=[
                     HtmlElem('span', attrs=[('class', 'keyword')], content=format('table of', False)),
                     HtmlElem('', '&nbsp;'),
                     element_type_elem])])])])
         details_div.add_content([
            HtmlElem('table', attrs=[('class', 'summary')], content=[
               HtmlElem('tr', [HtmlElem('th', attrs=[('colspan', '2')], content='Data Type Details')])]),
            HtmlElem('p'),
            HtmlElem('span', attrs=[('class', 'keyword')], content=format('type', False)),
            HtmlElem('span', attrs=[('class', 'param-type')], content=fmt_type_names[type_name]),
            HtmlElem('span', attrs=[('class', 'keyword')], content=format('is table of', False)),
            element_type_elem,
            HtmlElem('p'),
            HtmlElem('', jdoc),
            HtmlElem('p'),
            HtmlElem('hr')])
      elif obj_type_matcher.find() :
         obj_routines_pattern = get_pattern(re_obj_routines, 'imd')
         obj_field_pattern = get_pattern(re_obj_field, 'imd')
         #-------------#
         # object type #
         #-------------#
         base_type  = obj_type_matcher.group(5).upper().split()[1]
         base_fields = get_base_type_fields(base_type)
         if base_type != 'OBJECT' :
            if 'TYPE %s' % format(base_type).upper() not in map(str, map(string.upper, jdoc._see_also)) :
               jdoc._see_also.append('type %s' % base_type)
         top_div.add_summary(jdoc)
         type_text  = obj_type_matcher.group(7)
         type_text2 = jdoc_comment2_pattern.matcher(type_text).replaceAll('')
         matcher    = obj_routines_pattern.matcher(type_text2)
         if matcher.find() :
            routines_text = matcher.group(0)
            fields_text = type_text2.replace(routines_text, '').strip()
         else :
            routines_text = None
            fields_text = type_text2
         fields = []
         pos = 0
         matcher = obj_field_pattern.matcher(fields_text)
         while matcher.find(pos) :
            fields.append(fields_text[matcher.start():matcher.end()])
            pos = matcher.end()
         field_count = len(fields)
         field_elems = []
         #---------------------#
         # build field summary #
         #---------------------#
         for i in range(len(base_fields)) :
            parts = base_fields[i].split()
            field_name, field_type = parts[0], ' '.join(parts[1:])
            field_type_elem = HtmlElem('span', attrs=[('class', 'comment')], content = format(field_type))
            if fmt_type_names.has_key(field_type.upper()) :
               field_type_elem = make_reference_elem('type %s' % field_type).add_content([field_type_elem])
            field_elems.extend([
               HtmlElem('span', attrs=[('class', 'comment')], content=format(field_name, False)),
               HtmlElem('', '&nbsp;'),
               field_type_elem,
               HtmlElem('br')])
         for i in range(field_count) :
            parts = fields[i].split()
            field_name, field_type = parts[0], ' '.join(parts[1:])
            field_type_elem = HtmlElem('span', attrs=[('class', 'param-type')], content = mark_parentheses(format(field_type)))
            if fmt_type_names.has_key(field_type.upper()) :
               field_type_elem = make_reference_elem('type %s' % field_type).add_content([field_type_elem])
            field_elems.extend([
               HtmlElem('span', attrs=[('class', 'param-name')], content=format(field_name, False)),
               HtmlElem('', '&nbsp;'),
               field_type_elem])
            if i == field_count - 1 :
               field_elems.append(HtmlElem('span', attrs=[('class', 'parentheses')], content=')'))
            else :
               field_elems.extend([
                  HtmlElem('span', attrs=[('class', 'comma')], content=','),
                  HtmlElem('br')])
         default_constructor_table = \
            HtmlElem('table', attrs=[('class', 'members')], content = [
               HtmlElem('tr', [
                  HtmlElem('td', attrs=[('style','vertical-align:top')], content=[
                     HtmlElem('span', attrs=[('class', 'keyword')], content=format('object', False)),
                     HtmlElem('span', attrs=[('class', 'parentheses')], content=format('(', False))]),
                  HtmlElem('td', field_elems)])])
         if base_fields :
            default_constructor_table.add_content([
               HtmlElem('tr', content=[
                  HtmlElem('td', content='&nbsp')]),
               HtmlElem('tr', content=[
                  HtmlElem('td', attrs=[('colspan', '2')], content=[
                     HtmlElem('span', attrs=[('class', 'comment')], content='* Inherited Fields')])])])
         summary_table = \
            HtmlElem('table', attrs=[('class', 'summary')], content=[
               HtmlElem('tr', [
                  HtmlElem('th', attrs=[('colspan', '2')], content='Data Type Summary')]),
               HtmlElem('tr', [
                  HtmlElem('td', attrs=[('class', 'routine-type-col')], content=[
                     HtmlElem('a', attrs=[('href', '#default constructor'),('title', 'Click for details')], content=[
                        HtmlElem('span', attrs=[('class', 'param-type')], content=format(type_name))])]),
                  HtmlElem('td', attrs=[('class', 'description-col')], content=[default_constructor_table])])])
         summary_div.add_content([summary_table])
         #---------------------#
         # build field details #
         #---------------------#
         field_elems = HtmlElem('table', attrs=[('class', 'members')], content = [])
         for i in range(len(base_fields)) :
            parts = base_fields[i].split()
            field_name, field_type = parts[0], ' '.join(parts[1:])
            field_type_elem = HtmlElem('span', attrs=[('class', 'comment')], content = format(field_type))
            if fmt_type_names.has_key(field_type.upper()) :
               field_type_elem = make_reference_elem('type %s' % field_type).add_content([field_type_elem])
            if i == 0 :
               col1 = HtmlElem('td', [
                  HtmlElem('span', attrs=[('class', 'keyword')], content=format('object', False)),
                  HtmlElem('span', attrs=[('class', 'parentheses')], content=format('(', False))])
            else :
               col1 = HtmlElem('td')
            col2 = HtmlElem('td', [
               HtmlElem('span', attrs=[('class', 'comment')], content=format(field_name, False))])
            col3 = HtmlElem('td', attrs=[('class', 'description-col')], content=[
               HtmlElem('', '&nbsp;'),
               field_type_elem])
            row = HtmlElem('tr', [col1, col2, col3])
            field_elems.add_content([row])
         for i in range(field_count) :
            parts = fields[i].split()
            field_name, field_type = parts[0], ' '.join(parts[1:])
            field_type_elem = HtmlElem('span', attrs=[('class', 'param-type')], content = format(field_type))
            if fmt_type_names.has_key(field_type.upper()) :
               field_type_elem = make_reference_elem('type %s' % field_type).add_content([field_type_elem])
            if i + len(base_fields) == 0 :
               col1 = HtmlElem('td', [
                  HtmlElem('span', attrs=[('class', 'keyword')], content=format('object', False)),
                  HtmlElem('span', attrs=[('class', 'parentheses')], content=format('(', False))])
            else :
               col1 = HtmlElem('td')
            col2 = HtmlElem('td', [
               HtmlElem('span', attrs=[('class', 'param-name')], content=format(field_name, False))])
            if i == field_count - 1 :
               col3 = HtmlElem('td', attrs=[('class', 'description-col')], content=[
                  HtmlElem('', '&nbsp;'),
                  field_type_elem,
                  HtmlElem('span', attrs=[('class', 'parentheses')], content=')')])
            else :
               col3 = HtmlElem('td', attrs=[('class', 'description-col')], content=[
                  HtmlElem('', '&nbsp;'),
                  field_type_elem,
                  HtmlElem('span', attrs=[('class', 'comma')], content=',')])
            row = HtmlElem('tr', [col1, col2, col3])
            field_elems.add_content([row])
         if base_fields :
            base_elems = [
               HtmlElem('p'),
               HtmlElem('span', attrs=[('class', 'comment')], content='* Inherited fields')]
         else :
            base_elems = []
         details_div.add_content([
            HtmlElem('table', attrs=[('class', 'summary')], content=[
               HtmlElem('tr', [HtmlElem('th', attrs=[('colspan', '2')], content='Data Type Details')])]),
            HtmlElem('', [
               HtmlElem('br'),
               HtmlElem('span', attrs=[('class', 'keyword')], content=format('type', False)),
               HtmlElem('', '&nbsp;'),
               HtmlElem('span', attrs=[('class', 'param-type')], content=[
                  HtmlElem('a', attrs=[('name', 'default constructor')], content=fmt_type_names[type_name])]),
               HtmlElem('br')] + \
               [field_elems] + base_elems + [\
               HtmlElem('', jdoc),
               HtmlElem('p'),
               HtmlElem('hr')])])
         if routines_text :
            #---------------#
            # parse methods #
            #---------------#
            jdoc_routine_pattern = get_pattern(re_obj_jdoc_routine, 'imd')
            routines = []
            pos = 0
            routine_matcher = jdoc_routine_pattern.matcher(type_text)
            while routine_matcher.find(pos) :
               routine_text = type_text[routine_matcher.start():routine_matcher.end()]
               jdoc_text     = routine_matcher.group(1)
               routine_class = routine_matcher.group(5).lower()
               routine_type  = routine_matcher.group(7).lower()
               routine_name  = routine_matcher.group(8).lower()
               params_text   = routine_matcher.group(9)
               return_type   = routine_matcher.group(10)
               params, jdoc_text = parse_params(params_text, jdoc_text)
               #----------------------------------------------------------------------#
               # make sure routines sort in alpabetical order with constructors first #
               #----------------------------------------------------------------------#
               if routine_class.lower().find('constructor') >= 0 :
                  tag = "__%s" % routine_name.lower()
               else :
                  tag = routine_name.lower()
               routines.append((tag, routine_name, params, jdoc_text, routine_class, routine_type, return_type))
               pos = routine_matcher.end()
            for tag, routine_name, params, jdoc_text, routine_class, routine_type, return_type in sorted(routines) :
               routine_class = routine_class.lower().replace('overriding', '').strip()
               if return_type : return_type = return_type.lower().replace('return ', '').replace('self as result', '').strip()
               if routine_class == 'constructor' :
                  routine_type = 'constructor'
                  routine_name = alias(routine_name)
               else :
                  if routine_class == 'static' :
                     routine_type = 'static %s' % routine_type
               add_routine(summary_table, details_div, routine_name, routine_type, return_type, params, jdoc_text)
      else :
         print text
         raise ValueError('Type %s is unexpected type' % type_name)
      #---------------------------#
      # output the html to a file #
      #---------------------------#
      htmlfilename = 'type_%s.html' % alias(type_name).lower()
      type_links[format(type_name)] = htmlfilename
      htmlfilename = os.path.join(output_dir, htmlfilename)
      output2('writing %s' % os.path.abspath(htmlfilename))
      htmlfile = open(htmlfilename, 'w')
      htmlfile.write(page.get_content())
      htmlfile.close()
   stmt.close()
   #-------------------#
   # process the views #
   #-------------------#
   col_stmt = conn.prepareStatement('''
      select column_name,
             nullable,
             decode(
                c.data_type,
                'VARCHAR2',
                c.data_type
                ||'('
                || c.data_length
                ||')',
                'NUMBER',
                decode(
                   c.data_precision,
                   null,
                   c.data_type,
                   0,
                   c.data_type,
                   c.data_type
                   || '('
                   ||c.data_precision
                   ||decode(
                        c.data_scale,
                        null,
                        ')',
                        0,
                        ')' ,
                        ', '
                        ||c.data_scale
                        ||')')),
                    c.data_type) data_type
        from cols c,
             obj o
       where c.table_name = o.object_name
        and o.object_type = :1
        and c.table_name = :2
   order by c.column_id'''.strip())
   clob_stmt = conn.prepareStatement('select value from at_clob where office_code = 53 and id = :1')
   for view_name, is_materialized in sorted(fmt_view_names.keys()) :
      #----------------------------------------#
      # get the javadoc from the AT_CLOB table #
      #----------------------------------------#
      output1('view', view_name)
      clob_stmt.setString(1, '/VIEWDOCS/%s' % view_name.upper())
      rs = clob_stmt.executeQuery()
      jdoc_text = ''
      if rs.next() :
         clob = rs.getObject(1)
         clob_len = clob.length()
         jdoc_text = clob.getSubString(1, clob_len)
      rs.close()
      if not jdoc_text :
         output2('not documented.')
         continue
      matcher = get_pattern(re_jdoc_comment2, 'imd').matcher(jdoc_text)
      if not matcher.find() :
         output2('not documented.')
         continue
      jdoc = JDoc(jdoc_text)
      brief_descriptions[view_name] = brief(jdoc.description())
      #-----------------------------------------#
      # get the column info from the datatabase #
      #-----------------------------------------#
      col_stmt.setString(1, ('VIEW', 'MATERIALIZED VIEW')[is_materialized])
      col_stmt.setString(2, view_name.upper())
      cols = []
      rs = col_stmt.executeQuery()
      while rs.next() :
         col_name = rs.getString(1)
         nullable = rs.getString(2)
         datatype = rs.getString(3)
         cols.append((col_name, nullable, datatype))
      rs.close()
      top_div     = HtmlElem('div')
      summary_div = HtmlElem('div')
      page = HtmlElem(
         'html', [
            HtmlElem(
               'head', [
                  HtmlElem('title', 'VIEW %s' % format(view_name)),
                  HtmlElem('link', attrs = [('rel','stylesheet'),('type','text/css'),('href',css_filename)])]),
            HtmlElem(
               'body', [
                  HtmlElem('span', attrs = [('class','top-level')], content='%s %s' % (format('View', False), format(view_name))),
                  top_div,
                  HtmlElem('p'),
                  summary_div,
                  HtmlElem('p')])])
      top_div.add_summary(jdoc)
      summary_table = \
         HtmlElem('table', attrs=[('class', 'summary')], content=[
            HtmlElem('tr', [
               HtmlElem('th', attrs=[('colspan', '3')], content='Columns Summary')])])
      summary_div.add_content([summary_table])
      for i in range(len(cols)) :
         col_name, nullable, datatype = cols[i]
         try : doc_text = jdoc.get_param(col_name)
         except : doc_text = '???'
         nullable_text = format(('not nullable', 'nullable')[nullable == 'Y'], False)
         summary_table.add_content([
            HtmlElem('tr', [
               HtmlElem('td', attrs=[('class', 'routine-type-col')], content=[
                  HtmlElem('span', attrs=[('class', 'param-name')], content='%d' % (i+1))]),
               HtmlElem('td', attrs=[('class', 'routine-type-col')], content=[
                  HtmlElem('span', attrs=[('class', 'param-name')], content=format(col_name, False))]),
               HtmlElem('td', attrs=[('class', 'description-col')], content=[
                  HtmlElem('span', attrs=[('class', 'param-type')], content=mark_parentheses(format(datatype, False))),
                  HtmlElem('', '&nbsp;'),
                  HtmlElem('span', attrs=[('class', 'keyword')], content=nullable_text),
                  HtmlElem('p', attrs=[('style','padding-bottom:0px; margin-bottom:0px;')]),
                  HtmlElem('', doc_text)])])])
      #---------------------------#
      # output the html to a file #
      #---------------------------#
      htmlfilename = 'view_%s.html' % alias(view_name).lower()
      view_links[format(view_name)] = htmlfilename
      htmlfilename = os.path.join(output_dir, htmlfilename)
      output2('writing %s' % os.path.abspath(htmlfilename))
      htmlfile = open(htmlfilename, 'w')
      htmlfile.write(page.get_content())
      htmlfile.close()
   col_stmt.close
   clob_stmt.close()
   #---------------#
   # write the css #
   #---------------#
   css_file = open(os.path.join(output_dir, css_filename), 'w')
   css_file.write(css)
   css_file.close()
   #----------------------------#
   # write the navigation files #
   #----------------------------#
   head = HtmlElem('head', content=[
      HtmlElem('title', content='CWMS Database API Documentation'),
      HtmlElem('style', attrs=[('type','text/css')], content='a:link, a:visited {text-decoration:none;}')])
   #
   # types
   #
   body = HtmlElem('body', content=[HtmlElem('b', 'Types'), HtmlElem('p')])
   for type_name in sorted(type_links.keys()) :
      body.add_content([
         HtmlElem('a', attrs=[('href', type_links[type_name]),('target','details_frame')], content=type_name),
         HtmlElem('br')])
   page = HtmlElem('html').add_content([head, body])
   htmlfilename = os.path.join(output_dir, 'types.html')
   htmlfile = open(htmlfilename, 'w')
   htmlfile.write(page.get_content())
   htmlfile.close()
   #
   # packages
   #
   body = HtmlElem('body', content=[HtmlElem('b', 'Packages'), HtmlElem('p')])
   for package_name in sorted(package_links.keys()) :
      body.add_content([
         HtmlElem('a', attrs=[('href', package_links[package_name]),('target','details_frame')], content=package_name),
         HtmlElem('br')])
   page = HtmlElem('html').add_content([head, body])
   htmlfilename = os.path.join(output_dir, 'packages.html')
   htmlfile = open(htmlfilename, 'w')
   htmlfile.write(page.get_content())
   htmlfile.close()
   #
   # views
   #
   body = HtmlElem('body', content=[HtmlElem('b', 'Views'), HtmlElem('p')])
   for view_name in sorted(view_links.keys()) :
      body.add_content([
         HtmlElem('a', attrs=[('href', view_links[view_name]),('target','details_frame')], content=view_name),
         HtmlElem('br')])
   page = HtmlElem('html').add_content([head, body])
   htmlfilename = os.path.join(output_dir, 'views.html')
   htmlfile = open(htmlfilename, 'w')
   htmlfile.write(page.get_content())
   htmlfile.close()
   #
   # combination
   #
   all_links = {}
   all_links.update(type_links)
   all_links.update(package_links)
   all_links.update(view_links)
   body = HtmlElem('body', content=[HtmlElem('b', 'All Items'), HtmlElem('p')])
   for all_name in sorted(all_links.keys()) :
      body.add_content([
         HtmlElem('a', attrs=[('href', all_links[all_name]),('target','details_frame')], content=all_name),
         HtmlElem('br')])
   page = HtmlElem('html').add_content([head, body])
   htmlfilename = os.path.join(output_dir, 'all.html')
   htmlfile = open(htmlfilename, 'w')
   htmlfile.write(page.get_content())
   htmlfile.close()
   #
   # top nav frame
   #
   body = HtmlElem('body', content=[HtmlElem('b', 'Item Types'), HtmlElem('p')])
   for item in ('All Items', 'Packages', 'Types', 'Views') :
      link = '%s.html' % item.split()[0].lower()
      body.add_content([
         HtmlElem('a', attrs=[('href', link),('target','chooser_frame')], content=item),
         HtmlElem('br')])
   page = HtmlElem('html').add_content([head, body])
   htmlfilename = os.path.join(output_dir, 'chooser.html')
   htmlfile = open(htmlfilename, 'w')
   htmlfile.write(page.get_content())
   htmlfile.close()
   #
   # main page
   #
   htmlfilename = os.path.join(output_dir, 'main.html')
   htmlfile = open(htmlfilename, 'w')
   htmlfile.write(build_main_page())
   htmlfile.close()
   #
   # frameset
   #
   page = HtmlElem('hmtl', [
      HtmlElem('head', content=[HtmlElem('title', content='CWMS Database API')]),
      HtmlElem('frameset', attrs=[('cols','20%,80%')], content=[
         HtmlElem('frameset', attrs=[('rows','20%,80%')], content=[
            HtmlElem('frame', attrs=[('src','chooser.html')]),
            HtmlElem('frame', attrs=[('src','all.html'),('name','chooser_frame')])]),
         HtmlElem('frame', attrs=[('src','main.html'),('name','details_frame')])])])
   htmlfilename = os.path.join(output_dir, 'index.html')
   htmlfile = open(htmlfilename, 'w')
   htmlfile.write(page.get_content())
   htmlfile.close()
   #---------------------#
   # copy external files #
   #---------------------#
   for external_file in external_files :
      external_file = os.path.join(external_docs_dir, external_file)
      output('Copying %s to %s' % (external_file, output_dir), True, True)
      try    : shutil.copy(external_file, output_dir)
      except : pass
finally :
   if traceback.extract_stack() : traceback.format_exc()
   for resource in (rs, stmt, conn) :
      try    : resource.close()
      except : pass
