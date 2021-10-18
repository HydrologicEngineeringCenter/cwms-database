-----------------------------
-- AT_CLOB table
--
CREATE TABLE at_clob
(
  CLOB_CODE    NUMBER(14) NOT NULL,
  OFFICE_CODE  NUMBER(14) NOT NULL,
  ID           VARCHAR2(256 BYTE) NOT NULL,
  description  VARCHAR2(256 BYTE),
  VALUE        CLOB,
  CONSTRAINT AT_CLOB_PK  PRIMARY KEY (clob_code) USING INDEX
)
TABLESPACE CWMS_20AT_DATA
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE
(
  INITIAL          64 k
  MINEXTENTS       1
  MAXEXTENTS       2147483645
  PCTINCREASE      0
  BUFFER_POOL      DEFAULT
)
LOGGING
NOCOMPRESS
LOB (VALUE) STORE AS
(
  TABLESPACE  CWMS_20AT_DATA
  ENABLE      STORAGE IN ROW
  CHUNK       8192
  PCTVERSION  0
  NOCACHE
  STORAGE
  (
    INITIAL          64 k
    MINEXTENTS       1
    MAXEXTENTS       2147483645
    PCTINCREASE      0
    BUFFER_POOL      DEFAULT
  )
)
NOCACHE
NOPARALLEL
MONITORING
/

-----------------------------
-- AT_CLOB comments
--
COMMENT ON TABLE  at_clob             IS 'Character Large OBject Storage for CWMS';
COMMENT ON COLUMN at_clob.CLOB_CODE   IS 'Unique reference code for this CLOB';
COMMENT ON COLUMN at_clob.OFFICE_CODE IS 'Reference to CWMS office';
COMMENT ON COLUMN at_clob.ID          IS 'Unique record identifier, using hierarchical /dir/subdir/.../file syntax';
COMMENT ON COLUMN at_clob.description IS 'Description of this CLOB';
COMMENT ON COLUMN at_clob.VALUE       IS 'The CLOB data';

-----------------------------
-- AT_CLOB indices
--
create unique index at_clob_idx1 on at_clob (office_code, upper(id)) tablespace cwms_20at_data;

-----------------------------
-- AT_CLOB constraints
--
ALTER TABLE AT_CLOB ADD CONSTRAINT AT_CLOB_FK1 FOREIGN KEY (OFFICE_CODE) REFERENCES CWMS_OFFICE (OFFICE_CODE);

SET define off
-----------------------------
-- AT_CLOB default data
--
INSERT INTO at_clob
     VALUES (1,
             (SELECT OFFICE_CODE FROM CWMS_OFFICE WHERE OFFICE_ID = 'CWMS'),
             '/XSLT/IDENTITY',
             'Transforms the input to an identical copy of itself',
             '<!-- The Identity Transformation -->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <!-- Whenevery you match any node or any attribute -->
  <xsl:template match="node()|@*">
    <!-- Copy the current node -->
    <xsl:copy>
      <!-- Including and attributes it has and any child nodes -->
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>
'           );

INSERT INTO at_clob
     VALUES (2,
             (SELECT OFFICE_CODE FROM CWMS_OFFICE WHERE OFFICE_ID = 'CWMS'),
             '/XSLT/CAT_TS_XML/TABBED_TEXT',
             'Transforms cat_ts_xml output to tab-separated text',
             '<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:template match="/tsid_catalog[1]">
    <xsl:text>Time Series IDs for Office "</xsl:text>
    <xsl:value-of select="/tsid_catalog[1]/@office"/>
    <xsl:text>" Matching "</xsl:text>
    <xsl:value-of select="/tsid_catalog[1]/@pattern"/>
    <xsl:text>"&#xA;&#xA;Time Series ID&#x9;TS CODE&#x9;UTC OFFSET"&#xA;</xsl:text>
    <xsl:for-each select="/tsid_catalog/tsid">
      <xsl:value-of select="."/>
      <xsl:text>&#x9;</xsl:text>
      <xsl:value-of select="@ts_code"/>
      <xsl:text>&#x9;</xsl:text>
      <xsl:value-of select="@offset"/>
      <xsl:text>&#xA;</xsl:text>
    </xsl:for-each>
  </xsl:template>
</xsl:stylesheet>
'           );

INSERT INTO at_clob
     VALUES (3,
             (SELECT OFFICE_CODE FROM CWMS_OFFICE WHERE OFFICE_ID = 'CWMS'),
             '/XSLT/CAT_TS_XML/HTML',
             'Transforms cat_ts_xml output to html',
             '<html xsl:version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<head>
  <title>Time Series IDs for Office "<xsl:value-of select="/tsid_catalog[1]/@office"/>"
         Matching "<xsl:value-of select="/tsid_catalog[1]/@pattern"/>"
  </title>
</head>
<body>
  <center>
    <h2>
      Time series IDs matching pattern
       "<xsl:value-of select="/tsid_catalog[1]/@pattern"/>" for Office
       "<xsl:value-of select="/tsid_catalog[1]/@office"/>".
    </h2>
    <hr/>
    <table border="1">
      <tr>
        <th>Time Series Identifier</th>
        <th>TS Code</th>
        <th>UTC Interval Offset</th>
      </tr>
      <xsl:for-each select="/tsid_catalog/tsid">
      <tr>
        <td><xsl:value-of select="."/></td>
        <td><xsl:value-of select="@ts_code"/></td>
        <td><xsl:value-of select="@offset"/></td>
      </tr>
      </xsl:for-each>
    </table>
  </center>
</body>
</html>
'           );

COMMIT ;


