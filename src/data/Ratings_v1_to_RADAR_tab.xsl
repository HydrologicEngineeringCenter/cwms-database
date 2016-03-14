<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <!-- routines -->
  <xsl:template name="left-trim">
    <xsl:param name="p-string"/>
    <xsl:choose>
      <xsl:when test="substring($p-string, 1, 1) = ' '">
        <xsl:call-template name="left-trim">
          <xsl:with-param name="p-string" select="substring($p-string, 2)"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$p-string"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template name="right-trim">
    <xsl:param name="p-string"/>
    <xsl:choose>
      <xsl:when test="substring($p-string, string-length($p-string)) = ' '">
        <xsl:call-template name="right-trim">
          <xsl:with-param name="p-string" select="substring($p-string, 1, string-length($p-string)-1)"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$p-string"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template name="trim">
    <xsl:param name="p-string"/>
    <xsl:variable name="trimmed">
      <xsl:call-template name="left-trim">
        <xsl:with-param name="p-string" select="$p-string"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="trimmed">
      <xsl:call-template name="right-trim">
        <xsl:with-param name="p-string" select="$trimmed"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:value-of select="$trimmed"/>
  </xsl:template>
  
  <xsl:template name="format-date">
    <xsl:param name="p-iso-str"/>
    <xsl:variable name="year" select="substring($p-iso-str, 1, 4)"/>
    <xsl:variable name="month" select="substring($p-iso-str, 6, 2)"/>
    <xsl:variable name="day" select="substring($p-iso-str, 9, 2)"/>
    <xsl:variable name="time" select="substring($p-iso-str, 12, 5)"/>
    <xsl:variable name="offset" select="substring($p-iso-str, 20, 6)"/>
    <xsl:variable name="month-str">
      <xsl:choose>
        <xsl:when test="$month='01'"><xsl:value-of select="'Jan'"/></xsl:when>
        <xsl:when test="$month='02'"><xsl:value-of select="'Feb'"/></xsl:when>
        <xsl:when test="$month='03'"><xsl:value-of select="'Mar'"/></xsl:when>
        <xsl:when test="$month='04'"><xsl:value-of select="'Apr'"/></xsl:when>
        <xsl:when test="$month='05'"><xsl:value-of select="'May'"/></xsl:when>
        <xsl:when test="$month='06'"><xsl:value-of select="'Jun'"/></xsl:when>
        <xsl:when test="$month='07'"><xsl:value-of select="'Jul'"/></xsl:when>
        <xsl:when test="$month='08'"><xsl:value-of select="'Aug'"/></xsl:when>
        <xsl:when test="$month='09'"><xsl:value-of select="'Sep'"/></xsl:when>
        <xsl:when test="$month='10'"><xsl:value-of select="'Oct'"/></xsl:when>
        <xsl:when test="$month='11'"><xsl:value-of select="'Nov'"/></xsl:when>
        <xsl:when test="$month='12'"><xsl:value-of select="'Dec'"/></xsl:when>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="offset-str">
      <xsl:choose>
        <xsl:when test="$offset='Z'"><xsl:value-of select="'UTC'"/></xsl:when>
        <xsl:otherwise><xsl:value-of select="concat('UTC', $offset)"/></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:value-of select="concat($day,'-',$month-str,'-',$year,' ',$time,' ',$offset-str)"/>
  </xsl:template>
  
  <xsl:template name="output-rating-parameters">
    <xsl:param name="p-parameters"/>
    <xsl:param name="p-units"/>
    <xsl:param name="p-datum"/>
    <xsl:param name="p-count"/>
    <xsl:choose>
      <xsl:when test="contains($p-parameters, ';')">
        <xsl:call-template name="output-rating-parameters">
          <xsl:with-param name="p-parameters" select="substring-before($p-parameters, ';')"/>
          <xsl:with-param name="p-units" select="substring-before($p-units, ';')"/>
          <xsl:with-param name="p-datum" select="$p-datum"/>
          <xsl:with-param name="p-count" select="1"/>
        </xsl:call-template>
        <xsl:call-template name="output-rating-parameters">
          <xsl:with-param name="p-parameters" select="substring-after($p-parameters, ';')"/>
          <xsl:with-param name="p-units" select="substring-after($p-units, ';')"/>
          <xsl:with-param name="p-datum" select="$p-datum"/>
          <xsl:with-param name="p-count" select="0"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="contains($p-parameters, ',')">
            <xsl:variable name="first-parameter" select="substring-before($p-parameters, ',')"/>
            <xsl:variable name="other-parameters" select="substring-after($p-parameters, ',')"/>
            <xsl:variable name="first-unit" select="substring-before($p-units, ',')"/>
            <xsl:variable name="other-units" select="substring-after($p-units, ',')"/>
            <xsl:call-template name="output-rating-parameters">
              <xsl:with-param name="p-parameters" select="$first-parameter"/>
              <xsl:with-param name="p-units" select="$first-unit"/>
              <xsl:with-param name="p-datum" select="$p-datum"/>
              <xsl:with-param name="p-count" select="$p-count"/>
            </xsl:call-template>
            <xsl:call-template name="output-rating-parameters">
              <xsl:with-param name="p-parameters" select="$other-parameters"/>
              <xsl:with-param name="p-units" select="$other-units"/>
              <xsl:with-param name="p-datum" select="$p-datum"/>
              <xsl:with-param name="p-count" select="$p-count+1"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <xsl:choose>
              <xsl:when test="$p-count = 0">
                <xsl:text>&#x000a;#    Dep Parameter&#x0009;</xsl:text>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="concat('&#x000a;#    Ind Parameter ', $p-count, '&#x0009;')"/>
              </xsl:otherwise>
            </xsl:choose>
            <xsl:value-of select="$p-parameters"/>
            <xsl:if test="string-length($p-units) > 0">
              <xsl:choose>
                <xsl:when test="substring($p-parameters, 1, 4) = 'Elev'">
                  <xsl:choose>
                    <xsl:when test="string-length($p-datum) > 0">
                      <xsl:value-of select="concat(' (', $p-units, ' ', $p-datum, ')')"/>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select="concat(' (', $p-units, ')')"/>
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="concat(' (', $p-units, ')')"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:if>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template name="output-connections">
    <xsl:param name="p-connections"/>
    <xsl:if test="string-length($p-connections) > 0">
      <xsl:choose>
        <xsl:when test="contains($p-connections, ',')">
          <xsl:variable name="first" select="substring-before($p-connections, ',')"/>
          <xsl:variable name="remainder" select="substring-after($p-connections, ',')"/>
#Connection&#x0009;<xsl:copy-of select="$first"/>
          <xsl:call-template name="output-connections">
            <xsl:with-param name="p-connections" select="$remainder"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
#Connection&#x0009;<xsl:copy-of select="$p-connections"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>
  
  <!-- rating-template -->
  <xsl:template match="/ratings/rating-template">

#Rating Template
#  Office&#x0009;<xsl:value-of select="@office-id"/>
#  Name&#x0009;<xsl:value-of select="parameters-id"/>.<xsl:value-of select="version"/>
#  Parameters&#x0009;<xsl:value-of select="parameters-id"/>
#  Version&#x0009;<xsl:value-of select="version"/>
    <xsl:for-each select="ind-parameter-specs/ind-parameter-spec">
#  Ind Parameter <xsl:value-of select="@position"/>
#    Name&#x0009;<xsl:value-of select="parameter"/>
#    Value Lookup In Range&#x0009;<xsl:value-of select="in-range-method"/>
#    Value Lookup Below Range&#x0009;<xsl:value-of select="out-range-low-method"/>
#    Value Lookup Above Range&#x0009;<xsl:value-of select="out-range-high-method"/>
    </xsl:for-each>
#  Dep Parameter&#x0009;<xsl:value-of select="dep-parameter"/>
#  Description&#x0009;<xsl:value-of select="description"/>
  </xsl:template>
  
  <!-- rating-spec -->
  <xsl:template match="/ratings/rating-spec">

#Rating Spec
#  Office&#x0009;<xsl:value-of select="@office-id"/>
#  Name&#x0009;<xsl:value-of select="rating-spec-id"/>
#  Location&#x0009;<xsl:value-of select="location-id"/>
#  Version&#x0009;<xsl:value-of select="version"/>
#  Source Agency&#x0009;<xsl:choose>
      <xsl:when test="string-length(source-agency) > 0">
        <xsl:value-of select="source-agency"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>Not Specified</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
#  Time Lookup In Range&#x0009;<xsl:value-of select="in-range-method"/>
#  Time Lookup Before First&#x0009;<xsl:value-of select="out-range-low-method"/>
#  Time Lookup After Last&#x0009;<xsl:value-of select="out-range-high-method"/>
#  Rounding<xsl:for-each select="ind-rounding-specs/ind-rounding-spec">
#    Ind Parameter <xsl:value-of select="@position"/><xsl:text>&#x0009;</xsl:text><xsl:value-of select="."/>    
    </xsl:for-each>
#    Dep Parameter&#x0009;<xsl:value-of select="dep-rounding-spec"/>    
#  Description&#x0009;<xsl:value-of select="description"/>    
  </xsl:template>
  
  <!-- simple-rating -->
  <xsl:template match="/ratings/simple-rating">

#Simple Rating
#  Office&#x0009;<xsl:value-of select="@office-id"/>
#  Name&#x0009;<xsl:value-of select="rating-spec-id"/>
#  Parameters<xsl:variable name="datum" select="units-id/@vertical-datum"/>
    <xsl:if test="not(contains($datum, '-'))">
      <xsl:variable name="datum" select="concat(substring($datum, 1, 4), '-', substring($datum, 5))"/>
    </xsl:if>
    <xsl:for-each select="vertical-datum-info/offset[to-datum=$datum]">
      <xsl:if test="@estimate='true'">
        <xsl:variable name="datum" select="concat($datum, ' estimated')"/>
      </xsl:if>
    </xsl:for-each>
    <xsl:call-template name="output-rating-parameters">
      <xsl:with-param name="p-parameters" select="substring-before(substring-after(rating-spec-id, '.'), '.')"/>
      <xsl:with-param name="p-units" select="units-id/text()"/>
      <xsl:with-param name="p-datum" select="$datum"/>
    </xsl:call-template>
#  Effective Date&#x0009;<xsl:call-template name="format-date">
      <xsl:with-param name="p-iso-str" select="effective-date"/>
    </xsl:call-template>
#  Description&#x0009;<xsl:choose>
      <xsl:when test="string-length(description) > 0">
        <xsl:value-of select="description"/>
      </xsl:when>
      <xsl:otherwise>
      <xsl:text>None</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:choose>
      <xsl:when test="formula">
        <xsl:text>&#x000a;#Formula&#x0009;</xsl:text>
        <xsl:value-of select="formula"/>
      </xsl:when>
      <xsl:when test="rating-points">
        <xsl:text>&#x000a;#Values</xsl:text>      
        <xsl:for-each select="rating-points">
          <xsl:variable name="others"/>
          <xsl:for-each select="other-ind">
            <xsl:variable name="others">
              <xsl:copy-of select="$others"/>
              <xsl:value-of select="@value"/>
              <xsl:text>&#x0020;</xsl:text>
            </xsl:variable>
          </xsl:for-each>
          <xsl:for-each select="point">
            <xsl:text>&#x000a;</xsl:text>
            <xsl:choose>
              <xsl:when test="note">
                <xsl:copy-of select="$others"/>
                <xsl:value-of select="ind"/>
                <xsl:text>&#x0020;</xsl:text>
                <xsl:value-of select="dep"/>
                <xsl:text>&#x0020;"</xsl:text>
                <xsl:value-of select="note"/>
                <xsl:text>"</xsl:text>
              </xsl:when>
              <xsl:otherwise>
                <xsl:copy-of select="$others"/>
                <xsl:value-of select="ind"/>
                <xsl:text>&#x0020;</xsl:text>
                <xsl:value-of select="dep"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:for-each>
        </xsl:for-each>
        <xsl:if test="extension-points">
          <xsl:text>&#x000a;#Extension Values</xsl:text>      
          <xsl:for-each select="extension-points/point">
            <xsl:text>&#x000a;</xsl:text>
            <xsl:choose>
              <xsl:when test="note">
                <xsl:value-of select="ind"/>
                <xsl:text>&#x0020;</xsl:text>
                <xsl:value-of select="dep"/>
                <xsl:text>&#x0020;"</xsl:text>
                <xsl:value-of select="note"/>
                <xsl:text>"</xsl:text>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="ind"/>
                <xsl:text>&#x0020;</xsl:text>
                <xsl:value-of select="dep"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:for-each>
        </xsl:if>
      </xsl:when>
    </xsl:choose>
  </xsl:template>
  
  <!-- usgs-stream-rating -->
  <xsl:template match="/ratings/usgs-stream-rating">

#USGS Stream Rating
#  Office&#x0009;<xsl:value-of select="@office-id"/>
#  Name&#x0009;<xsl:value-of select="rating-spec-id"/>
#  Parameters<xsl:variable name="datum" select="units-id/@vertical-datum"/>
    <xsl:if test="not(contains($datum, '-'))">
      <xsl:variable name="datum" select="concat(substring($datum, 1, 4), '-', substring($datum, 5))"/>
    </xsl:if>
    <xsl:for-each select="vertical-datum-info/offset[to-datum=$datum]">
      <xsl:if test="@estimate='true'">
        <xsl:variable name="datum" select="concat($datum, ' estimated')"/>
      </xsl:if>
    </xsl:for-each>
    <xsl:variable name="parameters" select="substring-before(substring-after(rating-spec-id, '.'), '.')"/>
    <xsl:variable name="ind-parameter" select="substring-before($parameters, ';')"/>
    <xsl:variable name="dep-parameter" select="substring-after($parameters, ';')"/>
    <xsl:variable name="units" select="units-id/text()"/>
    <xsl:variable name="ind-unit" select="substring-before($units, ';')"/>
    <xsl:variable name="dep-unit" select="substring-after($units, ';')"/>
    <xsl:choose>
      <xsl:when test="substring($ind-parameter, 1, 4) = 'Elev'">
        <xsl:choose>
          <xsl:when test="string-length($datum) > 0">
            <xsl:text>&#x000a;#  Ind Parameter&#x0009;</xsl:text>
            <xsl:copy-of select="$ind-parameter"/>
            <xsl:text> (</xsl:text>
            <xsl:copy-of select="$ind-unit"/>
            <xsl:text> </xsl:text>
            <xsl:copy-of select="$datum"/>
            <xsl:text>)&#x000a;#  Dep Parameter&#x0009;</xsl:text>
            <xsl:copy-of select="$dep-parameter"/>
            <xsl:text> (</xsl:text>
            <xsl:copy-of select="$dep-unit"/>
            <xsl:text>)</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>&#x000a;#  Ind Parameter&#x0009;</xsl:text>
            <xsl:copy-of select="$ind-parameter"/>
            <xsl:text> (</xsl:text>
            <xsl:copy-of select="$ind-unit"/>
            <xsl:text>)&#x000a;#  Dep Parameter&#x0009;</xsl:text>
            <xsl:copy-of select="$dep-parameter"/>
            <xsl:text> (</xsl:text>
            <xsl:copy-of select="$dep-unit"/>
            <xsl:text>)</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>&#x000a;#  Ind Parameter&#x0009;</xsl:text>
        <xsl:copy-of select="$ind-parameter"/>
        <xsl:text> (</xsl:text>
        <xsl:copy-of select="$ind-unit"/>
        <xsl:text>)&#x000a;#  Dep Parameter&#x0009;</xsl:text>
        <xsl:copy-of select="$dep-parameter"/>
        <xsl:text> (</xsl:text>
        <xsl:copy-of select="$dep-unit"/>
        <xsl:text>)</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
#  Effective Date&#x0009;<xsl:call-template name="format-date">
      <xsl:with-param name="p-iso-str" select="effective-date"/>
    </xsl:call-template>
#  Description&#x0009;<xsl:choose>
      <xsl:when test="string-length(description) > 0">
        <xsl:value-of select="description"/>
      </xsl:when>
      <xsl:otherwise>
      <xsl:text>None</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
      <xsl:for-each select="height-shifts">
        <xsl:text>&#x000a;#Shifts&#x0009;Effective Date = </xsl:text>      
        <xsl:call-template name="format-date">
          <xsl:with-param name="p-iso-str" select="effective-date"/>
        </xsl:call-template>
        <xsl:for-each select="point">
          <xsl:text>&#x000a;</xsl:text>
          <xsl:choose>
            <xsl:when test="note">
              <xsl:value-of select="ind"/>
              <xsl:text>&#x0020;</xsl:text>
              <xsl:value-of select="dep"/>
              <xsl:text>&#x0020;"</xsl:text>
              <xsl:value-of select="note"/>
              <xsl:text>"</xsl:text>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="ind"/>
              <xsl:text>&#x0020;</xsl:text>
              <xsl:value-of select="dep"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>
      </xsl:for-each>
      <xsl:for-each select="height-offsets">
        <xsl:text>&#x000a;#Offsets</xsl:text>      
        <xsl:for-each select="point">
          <xsl:text>&#x000a;</xsl:text>
          <xsl:choose>
            <xsl:when test="note">
              <xsl:value-of select="ind"/>
              <xsl:text>&#x0020;</xsl:text>
              <xsl:value-of select="dep"/>
              <xsl:text>&#x0020;"</xsl:text>
              <xsl:value-of select="note"/>
              <xsl:text>"</xsl:text>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="ind"/>
              <xsl:text>&#x0020;</xsl:text>
              <xsl:value-of select="dep"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>
      </xsl:for-each>
    <xsl:text>&#x000a;#Values</xsl:text>      
    <xsl:for-each select="rating-points">
      <xsl:for-each select="point">
        <xsl:text>&#x000a;</xsl:text>
        <xsl:choose>
          <xsl:when test="note">
            <xsl:value-of select="ind"/>
            <xsl:text>&#x0020;</xsl:text>
            <xsl:value-of select="dep"/>
            <xsl:text>&#x0020;"</xsl:text>
            <xsl:value-of select="note"/>
            <xsl:text>"</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="ind"/>
            <xsl:text>&#x0020;</xsl:text>
            <xsl:value-of select="dep"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </xsl:for-each>
    <xsl:if test="extension-points">
      <xsl:text>&#x000a;#Extension Values;</xsl:text>      
      <xsl:for-each select="extension-points/point">
        <xsl:text>&#x000a;</xsl:text>
        <xsl:choose>
          <xsl:when test="note">
            <xsl:value-of select="ind"/>
            <xsl:text>&#x0020;</xsl:text>
            <xsl:value-of select="dep"/>
            <xsl:text>&#x0020;"</xsl:text>
            <xsl:value-of select="note"/>
            <xsl:text>"</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="ind"/>
            <xsl:text>&#x0020;</xsl:text>
            <xsl:value-of select="dep"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </xsl:if>
  </xsl:template>
  
  <!-- transitional-rating -->
  <xsl:template match="/ratings/transitional-rating">

#Transitional Rating
#  Office&#x0009;<xsl:value-of select="@office-id"/>
#  Name&#x0009;<xsl:value-of select="rating-spec-id"/>
#  Parameters<xsl:variable name="datum" select="units-id/@vertical-datum"/>
    <xsl:if test="not(contains($datum, '-'))">
      <xsl:variable name="datum" select="concat(substring($datum, 1, 4), '-', substring($datum, 5))"/>
    </xsl:if>
    <xsl:for-each select="vertical-datum-info/offset[to-datum=$datum]">
      <xsl:if test="@estimate='true'">
        <xsl:variable name="datum" select="concat($datum, ' estimated')"/>
      </xsl:if>
    </xsl:for-each>
    <xsl:call-template name="output-rating-parameters">
      <xsl:with-param name="p-parameters" select="substring-before(substring-after(rating-spec-id, '.'), '.')"/>
      <xsl:with-param name="p-units" select="units-id/text()"/>
      <xsl:with-param name="p-datum" select="$datum"/>
    </xsl:call-template>
#  Effective Date&#x0009;<xsl:call-template name="format-date">
      <xsl:with-param name="p-iso-str" select="effective-date"/>
    </xsl:call-template>
#  Description&#x0009;<xsl:choose>
      <xsl:when test="string-length(description) > 0">
        <xsl:value-of select="description"/>
      </xsl:when>
      <xsl:otherwise>
      <xsl:text>None</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:for-each select="select/case">
    <xsl:choose>
      <xsl:when test="@position='1'">
#If&#x0009;<xsl:value-of select="when"/>    
      </xsl:when>
      <xsl:otherwise>
#Else If&#x0009;<xsl:value-of select="when"/>    
      </xsl:otherwise>
    </xsl:choose>
#  Then&#x0009;<xsl:value-of select="then"/>
    </xsl:for-each>
    <xsl:choose>
      <xsl:when test="select/case">
#Else&#x0009;<xsl:value-of select="select/default"/>    
      </xsl:when>
      <xsl:otherwise>
#Always&#x0009;<xsl:value-of select="select/default"/>    
      </xsl:otherwise>
    </xsl:choose>
    <xsl:if test="source-ratings/rating-spec-id">
      <xsl:text>&#x000a;#Reference&#x0009;Rating Spec</xsl:text>    
      <xsl:for-each select="source-ratings/rating-spec-id">
      <xsl:text>&#x000a;R</xsl:text>
      <xsl:value-of select="@position"/>
        <xsl:text>&#x0009;</xsl:text>
        <xsl:value-of select="."/>
        <xsl:text>&#x000a;</xsl:text>
      </xsl:for-each>
    </xsl:if>
  </xsl:template>
  
  <!-- virtual-rating -->
  <xsl:template match="/ratings/virtual-rating">

#Virtual Rating
#  Office&#x0009;<xsl:value-of select="@office-id"/>
#  Name&#x0009;<xsl:value-of select="rating-spec-id"/>
#  Parameters<xsl:variable name="datum" select="units-id/@vertical-datum"/>
    <xsl:if test="not(contains($datum, '-'))">
      <xsl:variable name="datum" select="concat(substring($datum, 1, 4), '-', substring($datum, 5))"/>
    </xsl:if>
    <xsl:for-each select="vertical-datum-info/offset[to-datum=$datum]">
      <xsl:if test="@estimate='true'">
        <xsl:variable name="datum" select="concat($datum, ' estimated')"/>
      </xsl:if>
    </xsl:for-each>
    <xsl:call-template name="output-rating-parameters">
      <xsl:with-param name="p-parameters" select="substring-before(substring-after(rating-spec-id, '.'), '.')"/>
      <xsl:with-param name="p-units" select="units-id/text()"/>
      <xsl:with-param name="p-datum" select="$datum"/>
    </xsl:call-template>
#  Effective Date&#x0009;<xsl:call-template name="format-date">
      <xsl:with-param name="p-iso-str" select="effective-date"/>
    </xsl:call-template>
#  Description&#x0009;<xsl:choose>
      <xsl:when test="string-length(description) > 0">
        <xsl:value-of select="description"/>
      </xsl:when>
      <xsl:otherwise>
      <xsl:text>None</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:variable name="connections">
      <xsl:value-of select="connections"/>
    </xsl:variable>
    <xsl:call-template name="output-connections">
      <xsl:with-param name="p-connections" select="$connections"/>
    </xsl:call-template>
    <xsl:text>&#x000a;#Reference&#x0009;Units&#x0009;Rating Spec or Formula</xsl:text>    
    <xsl:for-each select="source-ratings/source-rating">
R<xsl:value-of select="@position"/>
      <xsl:text>&#x0009;</xsl:text>
      <xsl:choose>
        <xsl:when test="rating-spec-id">
          <xsl:call-template name="trim">
            <xsl:with-param name="p-string" select="substring-after(substring-before(rating-spec-id, '}'), '{')"/>
          </xsl:call-template>
          <xsl:text>&#x0009;</xsl:text>
          <xsl:call-template name="trim">
            <xsl:with-param name="p-string" select="substring-before(rating-spec-id, '{')"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="trim">
            <xsl:with-param name="p-string" select="substring-after(substring-before(rating-expression, '}'), '{')"/>
          </xsl:call-template>
          <xsl:text>&#x0009;</xsl:text>
          <xsl:call-template name="trim">
            <xsl:with-param name="p-string" select="substring-before(rating-expression, '{')"/>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="/ratings/query-info"/>
  
  <xsl:template match="node()|@*">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>

