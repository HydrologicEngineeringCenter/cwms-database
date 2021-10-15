<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <!-- routines -->
  <xsl:template name="output-connections">
    <xsl:param name="pConnections"/>
    <xsl:if test="string-length($pConnections) > 0">
      <xsl:choose>
        <xsl:when test="contains($pConnections, ',')">
          <xsl:variable name="first" select="substring-before($pConnections, ',')"/>
          <xsl:variable name="remainder" select="substring-after($pConnections, ',')"/>
          <connection><xsl:copy-of select="$first"/></connection>
          <xsl:call-template name="output-connections">
            <xsl:with-param name="pConnections" select="$remainder"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <connection><xsl:copy-of select="$pConnections"/></connection>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>
  
  <xsl:template name="left-trim">
    <xsl:param name="pString"/>
    <xsl:choose>
      <xsl:when test="substring($pString, 1, 1) = ' '">
        <xsl:call-template name="left-trim">
          <xsl:with-param name="pString" select="substring($pString, 2)"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$pString"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template name="right-trim">
    <xsl:param name="pString"/>
    <xsl:choose>
      <xsl:when test="substring($pString, string-length($pString)) = ' '">
        <xsl:call-template name="right-trim">
          <xsl:with-param name="pString" select="substring($pString, 1, string-length($pString)-1)"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$pString"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template name="trim">
    <xsl:param name="pString"/>
    <xsl:variable name="trimmed1">
      <xsl:call-template name="left-trim">
        <xsl:with-param name="pString" select="$pString"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="trimmed2">
      <xsl:call-template name="right-trim">
        <xsl:with-param name="pString" select="$trimmed1"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:value-of select="$trimmed2"/>
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
                <dep-parameter>
                <xsl:if test="string-length($p-units) > 0">
                  <xsl:choose>
                    <xsl:when test="substring($p-parameters, 1, 4) = 'Elev'">
                      <xsl:choose>
                        <xsl:when test="string-length($p-datum) > 0">
                        <xsl:attribute name="units">
                          <xsl:value-of select="concat($p-units, ' ', $p-datum)"/>
                        </xsl:attribute>
                        </xsl:when>
                        <xsl:otherwise>
                      <xsl:attribute name="units">
                        <xsl:copy-of select="$p-units"/>
                      </xsl:attribute>
                        </xsl:otherwise>
                      </xsl:choose>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:attribute name="units">
                        <xsl:copy-of select="$p-units"/>
                      </xsl:attribute>
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:if>
                <xsl:value-of select="$p-parameters"/>
                </dep-parameter>
              </xsl:when>
              <xsl:otherwise>
                <ind-parameter>
                <xsl:attribute name="position">
                  <xsl:copy-of select="$p-count"/>
                </xsl:attribute>
                <xsl:if test="string-length($p-units) > 0">
                  <xsl:choose>
                    <xsl:when test="substring($p-parameters, 1, 4) = 'Elev'">
                      <xsl:choose>
                        <xsl:when test="string-length($p-datum) > 0">
                        <xsl:attribute name="units">
                          <xsl:value-of select="concat($p-units, ' ', $p-datum)"/>
                        </xsl:attribute>
                        </xsl:when>
                        <xsl:otherwise>
                      <xsl:attribute name="units">
                        <xsl:copy-of select="$p-units"/>
                      </xsl:attribute>
                        </xsl:otherwise>
                      </xsl:choose>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:attribute name="units">
                        <xsl:copy-of select="$p-units"/>
                      </xsl:attribute>
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:if>
                <xsl:value-of select="$p-parameters"/>
                </ind-parameter>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- rating-template -->
  <xsl:template match="/ratings/rating-template">
    <xsl:copy>
      <xsl:attribute name="office">
        <xsl:value-of select="@office-id"/>
      </xsl:attribute>
      <name>
        <xsl:value-of select="parameters-id"/>.<xsl:value-of select="version"/>
      </name>
      <parameters>
        <xsl:value-of select="parameters-id"/>
      </parameters>
      <xsl:copy-of select="version"/>
      <xsl:for-each select="ind-parameter-specs/ind-parameter-spec">
        <ind-parameter>
          <xsl:copy-of select="@*"/>
          <name>
            <xsl:value-of select="parameter"/>
          </name>
          <value-lookup-in-range>
            <xsl:value-of select="in-range-method"/>
          </value-lookup-in-range>
          <value-lookup-below-range>
            <xsl:value-of select="out-range-low-method"/>
          </value-lookup-below-range>
          <value-lookup-above-range>
            <xsl:value-of select="out-range-high-method"/>
          </value-lookup-above-range>
        </ind-parameter>
      </xsl:for-each>
      <xsl:copy-of select="dep-parameter"/>
      <xsl:copy-of select="version"/>
    </xsl:copy>
  </xsl:template>
  
  <!-- rating-spec -->
  <xsl:template match="/ratings/rating-spec">
    <xsl:copy>
      <xsl:attribute name="office">
        <xsl:value-of select="@office-id"/>
      </xsl:attribute>
      <name>
        <xsl:value-of select="rating-spec-id"/>
      </name>
      <template>
        <xsl:value-of select="template-id"/>
      </template>
      <location>
        <xsl:value-of select="location-id"/>
      </location>
      <xsl:copy-of select="source-agency"/>
      <time-lookup-in-range>
        <xsl:value-of select="in-range-method"/>
      </time-lookup-in-range>
      <time-lookup-before-first>
        <xsl:value-of select="out-range-low-method"/>
      </time-lookup-before-first>
      <time-lookup-after-last>
        <xsl:value-of select="out-range-high-method"/>
      </time-lookup-after-last>
      <xsl:for-each select="ind-rounding-specs/ind-rounding-spec">
        <xsl:copy-of select="."/>
      </xsl:for-each>
      <xsl:copy-of select="dep-rounding-spec"/>
      <xsl:copy-of select="description"/>
    </xsl:copy>
  </xsl:template>
  
  <!-- simple-rating -->
  <xsl:template match="/ratings/simple-rating">
    <xsl:copy>
      <xsl:attribute name="office">
        <xsl:value-of select="@office-id"/>
      </xsl:attribute>
      <rating-spec>
        <xsl:value-of select="rating-spec-id"/>
      </rating-spec>
      <xsl:variable name="datum" select="units-id/@vertical-datum"/>
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
      <xsl:copy-of select="effective-date"/>
      <xsl:copy-of select="description"/>
      <rating-points>
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
            <xsl:choose>
              <xsl:when test="note">
                <xsl:copy-of select="$others"/>
                <xsl:value-of select="ind"/>
                <xsl:text>&#x0020;</xsl:text>
                <xsl:value-of select="dep"/>
                <xsl:text>&#x0020;"</xsl:text>
                <xsl:value-of select="note"/>
                <xsl:text>"&#x000a;</xsl:text>
              </xsl:when>
              <xsl:otherwise>
                <xsl:copy-of select="$others"/>
                <xsl:value-of select="ind"/>
                <xsl:text>&#x0020;</xsl:text>
                <xsl:value-of select="dep"/>
                <xsl:text>&#x000a;</xsl:text>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:for-each>
        </xsl:for-each>
      </rating-points>
      <xsl:if test="extension-points">
        <extension-points>
          <xsl:for-each select="extension-points/point">
            <xsl:choose>
              <xsl:when test="note">
                <xsl:value-of select="ind"/>
                <xsl:text>&#x0020;</xsl:text>
                <xsl:value-of select="dep"/>
                <xsl:text>&#x0020;"</xsl:text>
                <xsl:value-of select="note"/>
                <xsl:text>"&#x000a;</xsl:text>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="ind"/>
                <xsl:text>&#x0020;</xsl:text>
                <xsl:value-of select="dep"/>
                <xsl:text>&#x000a;</xsl:text>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:for-each>
        </extension-points>
      </xsl:if>
    </xsl:copy>
  </xsl:template>
  
  <!-- usgs-stream-rating -->
  <xsl:template match="/ratings/usgs-stream-rating">
    <xsl:copy>
      <xsl:attribute name="office">
        <xsl:value-of select="@office-id"/>
      </xsl:attribute>
      <rating-spec>
        <xsl:value-of select="rating-spec-id"/>
      </rating-spec>
      <xsl:copy-of select="effective-date"/>
      <xsl:copy-of select="description"/>
      <xsl:for-each select="vertical-datum-info">
        <vertical-datum>
          <xsl:apply-templates select="@*|node()"/>
        </vertical-datum>
      </xsl:for-each>
      <xsl:for-each select="height-shifts">
        <shifts>
          <xsl:attribute name="effective-date">
            <xsl:value-of select="effective-date"/>
          </xsl:attribute>
          <xsl:for-each select="point">
            <xsl:choose>
              <xsl:when test="note">
                <xsl:value-of select="ind"/>
                <xsl:text>&#x0020;</xsl:text>
                <xsl:value-of select="dep"/>
                <xsl:text>&#x0020;"</xsl:text>
                <xsl:value-of select="note"/>
                <xsl:text>"&#x000a;</xsl:text>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="ind"/>
                <xsl:text>&#x0020;</xsl:text>
                <xsl:value-of select="dep"/>
                <xsl:text>&#x000a;</xsl:text>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:for-each>
        </shifts>
      </xsl:for-each>
      <xsl:for-each select="height-offsets">
        <offsets>
          <xsl:for-each select="point">
            <xsl:choose>
              <xsl:when test="note">
                <xsl:value-of select="ind"/>
                <xsl:text>&#x0020;</xsl:text>
                <xsl:value-of select="dep"/>
                <xsl:text>&#x0020;"</xsl:text>
                <xsl:value-of select="note"/>
                <xsl:text>"&#x000a;</xsl:text>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="ind"/>
                <xsl:text>&#x0020;</xsl:text>
                <xsl:value-of select="dep"/>
                <xsl:text>&#x000a;</xsl:text>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:for-each>
        </offsets>
      </xsl:for-each>
      <rating-points>
        <xsl:for-each select="rating-points/point">
          <xsl:choose>
            <xsl:when test="note">
              <xsl:value-of select="ind"/>
              <xsl:text>&#x0020;</xsl:text>
              <xsl:value-of select="dep"/>
              <xsl:text>&#x0020;"</xsl:text>
              <xsl:value-of select="note"/>
              <xsl:text>"&#x000a;</xsl:text>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="ind"/>
              <xsl:text>&#x0020;</xsl:text>
              <xsl:value-of select="dep"/>
              <xsl:text>&#x000a;</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>
      </rating-points>
      <xsl:if test="extension-points">
        <extension-points>
          <xsl:for-each select="extension-points/point">
            <xsl:choose>
              <xsl:when test="note">
                <xsl:value-of select="ind"/>
                <xsl:text>&#x0020;</xsl:text>
                <xsl:value-of select="dep"/>
                <xsl:text>&#x0020;"</xsl:text>
                <xsl:value-of select="note"/>
                <xsl:text>"&#x000a;</xsl:text>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="ind"/>
                <xsl:text>&#x0020;</xsl:text>
                <xsl:value-of select="dep"/>
                <xsl:text>&#x000a;</xsl:text>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:for-each>
        </extension-points>
      </xsl:if>
    </xsl:copy>
  </xsl:template>
  
  <!-- transitional-rating -->
  <xsl:template match="/ratings/transitional-rating">
    <xsl:copy>
      <xsl:attribute name="office">
        <xsl:value-of select="@office-id"/>
      </xsl:attribute>
      <rating-spec>
        <xsl:value-of select="rating-spec-id"/>
      </rating-spec>
      <xsl:variable name="datum" select="units-id/@vertical-datum"/>
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
      <xsl:copy-of select="effective-date"/>
      <xsl:copy-of select="description"/>
      <xsl:copy-of select="select"/>
      <xsl:for-each select="source-ratings">
        <xsl:for-each select="rating-spec-id">
          <reference>
            <xsl:attribute name="position">
              <xsl:value-of select="@position"/>
            </xsl:attribute>
            <xsl:value-of select="."/>
          </reference>
        </xsl:for-each>
      </xsl:for-each>
    </xsl:copy>
  </xsl:template>
  
  <!-- virtual-rating -->
  <xsl:template match="/ratings/virtual-rating">
    <xsl:copy>
      <xsl:attribute name="office">
        <xsl:value-of select="@office-id"/>
      </xsl:attribute>
      <rating-spec>
        <xsl:value-of select="rating-spec-id"/>
      </rating-spec>
      <xsl:variable name="datum" select="units-id/@vertical-datum"/>
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
      <xsl:copy-of select="effective-date"/>
      <xsl:copy-of select="description"/>
      <xsl:variable name="connections">
        <xsl:value-of select="connections"/>
      </xsl:variable>
      <xsl:call-template name="output-connections">
        <xsl:with-param name="pConnections" select="$connections"/>
      </xsl:call-template>
      <xsl:for-each select="source-ratings">
        <xsl:for-each select="source-rating">
          <reference>
            <xsl:attribute name="position">
              <xsl:value-of select="@position"/>
            </xsl:attribute>
            <xsl:choose>
              <xsl:when test="rating-spec-id">
                <xsl:attribute name="units">
                  <xsl:variable name="trimmed">
                    <xsl:call-template name="trim">
                      <xsl:with-param name="pString" select="substring-after(substring-before(rating-spec-id, '}'), '{')"/>
                    </xsl:call-template>
                  </xsl:variable>
                  <xsl:value-of select="$trimmed"/>
                </xsl:attribute>
                <xsl:variable name="trimmed">
                  <xsl:call-template name="trim">
                    <xsl:with-param name="pString" select="substring-before(rating-spec-id, '{')"/>
                  </xsl:call-template>
                </xsl:variable>
                <xsl:value-of select="$trimmed"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:attribute name="units">
                  <xsl:variable name="trimmed">
                    <xsl:call-template name="trim">
                      <xsl:with-param name="pString" select="substring-after(substring-before(rating-expression, '}'), '{')"/>
                    </xsl:call-template>
                  </xsl:variable>
                  <xsl:value-of select="$trimmed"/>
                </xsl:attribute>
                <xsl:variable name="trimmed">
                  <xsl:call-template name="trim">
                    <xsl:with-param name="pString" select="substring-before(rating-expression, '{')"/>
                  </xsl:call-template>
                </xsl:variable>
                <xsl:value-of select="$trimmed"/>
              </xsl:otherwise>
            </xsl:choose>
          </reference>
        </xsl:for-each>
      </xsl:for-each>
    </xsl:copy>
  </xsl:template>
  <!-- default -->
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>

