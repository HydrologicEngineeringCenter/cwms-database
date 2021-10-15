<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <!-- 
       NOTE this transform does not distinguish between first and later elements of
       objects or arrays, but puts commas before all elements. This is becuase it is
       quicker to remove the initial commas via text replacement than it is to make
       the distinction here 
  -->
  
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
  
  <xsl:template name="replace">
    <xsl:param name="p-string"/>
    <xsl:param name="p-to-replace"/>
    <xsl:param name="p-replacement"/>
    <xsl:choose>
      <xsl:when test="contains($p-string, $p-to-replace)">
        <xsl:variable name="remainder">
          <xsl:call-template name="replace">
            <xsl:with-param name="p-string" select="substring-after($p-string, $p-to-replace)"/>
            <xsl:with-param name="p-to-replace" select="$p-to-replace"/>
            <xsl:with-param name="p-replacement" select="$p-replacement"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:value-of select="concat(substring-before($p-string, $p-to-replace), $p-replacement, $remainder)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy-of select="$p-string"/>
      </xsl:otherwise>
    </xsl:choose>
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
                <xsl:text>],"dep-parameter":"</xsl:text>
              </xsl:when>
              <xsl:otherwise>
                <xsl:choose>
                  <xsl:when test="$p-count = 1">
                    <xsl:text>,"ind-parameters":["</xsl:text>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:text>,"</xsl:text>
                  </xsl:otherwise>
                </xsl:choose>
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
            <xsl:text>"</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- rating-templates -->
  <xsl:template match="/ratings/rating-template">
    <xsl:choose>
      <xsl:when test="not(preceding-sibling::rating-template)">
        <xsl:text>{"ratings":{"rating-templates":[</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>,</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text>{"office":"</xsl:text>
    <xsl:value-of select="@office-id"/>
    <xsl:text>","name":"</xsl:text>
    <xsl:value-of select="parameters-id"/>.<xsl:value-of select="version"/>
    <xsl:text>","parameters-string":"</xsl:text>
    <xsl:value-of select="parameters-id"/>
    <xsl:text>","version":"</xsl:text>
    <xsl:value-of select="version"/>
    <xsl:text>","ind-parameters":[</xsl:text>
    <xsl:for-each select="ind-parameter-specs/ind-parameter-spec">
      <xsl:text>,{"name":"</xsl:text>
      <xsl:value-of select="parameter"/>
      <xsl:text>","value-lookup-in-range":"</xsl:text>
      <xsl:value-of select="in-range-method"/>
      <xsl:text>","value-lookup-below-range":"</xsl:text>
      <xsl:value-of select="out-range-low-method"/>
      <xsl:text>","value-lookup-above-range":"</xsl:text>
      <xsl:value-of select="out-range-high-method"/>
      <xsl:text>"}</xsl:text>
    </xsl:for-each>
    <xsl:text>],"dep-parameter":"</xsl:text>
    <xsl:value-of select="dep-parameter"/>
    <xsl:text>","description":"</xsl:text>
    <xsl:value-of select="description"/>
    <xsl:text>"}</xsl:text>
    <xsl:if test="not(following-sibling::rating-template)">
      <xsl:text>]</xsl:text>
    </xsl:if>
  </xsl:template>
  
  <!-- rating-specs -->
  <xsl:template match="/ratings/rating-spec">
    <xsl:if test="not(preceding-sibling::rating-template)">
      <xsl:text>{"ratings":{</xsl:text>
    </xsl:if>
    <xsl:choose>
      <xsl:when test="not(preceding-sibling::rating-spec)">
        <xsl:text>,"rating-specs":[</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>,</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text>{"office":"</xsl:text>
    <xsl:value-of select="@office-id"/>
    <xsl:text>","name":"</xsl:text>
    <xsl:value-of select="rating-spec-id"/>
    <xsl:text>","location":"</xsl:text>
    <xsl:value-of select="location-id"/>
    <xsl:text>","version":"</xsl:text>
    <xsl:value-of select="version"/>
    <xsl:text>","source-agency":"</xsl:text>
    <xsl:value-of select="source-agency"/>
    <xsl:text>","time-lookup-in-range":"</xsl:text>
    <xsl:value-of select="in-range-method"/>
    <xsl:text>","time-lookup-before-first":"</xsl:text>
    <xsl:value-of select="out-range-low-method"/>
    <xsl:text>","time-lookup-after-last":"</xsl:text>
    <xsl:value-of select="out-range-high-method"/>
    <xsl:text>","rounding":{"ind-parameters":[</xsl:text>
    <xsl:for-each select="ind-rounding-specs/ind-rounding-spec">
      <xsl:text>,"</xsl:text>
      <xsl:call-template name="trim">
        <xsl:with-param name="p-string" select="."/>
      </xsl:call-template>
      <xsl:text>"</xsl:text>    
    </xsl:for-each>
    <xsl:text>],"dep-parameter":"</xsl:text>
    <xsl:value-of select="dep-rounding-spec"/>    
    <xsl:text>"},"description":"</xsl:text>
    <xsl:value-of select="description"/>
    <xsl:text>"}</xsl:text>
    <xsl:if test="not(following-sibling::rating-spec)">
      <xsl:text>]</xsl:text>
    </xsl:if>
  </xsl:template>
  
  <!-- simple-ratings -->
  <xsl:template match="/ratings/simple-rating">
    <xsl:if test="not(preceding-sibling::rating-template) and not(preceding-sibling::rating-spec)">
      <xsl:text>{"ratings":{</xsl:text>
    </xsl:if>
    <xsl:if test="not(preceding-sibling::*[contains(name(), '-rating')])">
      <xsl:text>,"ratings":[</xsl:text>
    </xsl:if>
    <xsl:text>,{"simple-rating":{"office":"</xsl:text>
    <xsl:value-of select="@office-id"/>
    <xsl:text>","name":"</xsl:text>
    <xsl:value-of select="rating-spec-id"/>
    <xsl:text>"</xsl:text>
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
    <xsl:text>,"effective-date":"</xsl:text>
    <xsl:value-of select="effective-date"/>
    <xsl:text>","description":"</xsl:text>
    <xsl:value-of select="description"/>
    <xsl:choose>
      <xsl:when test="formula">
        <xsl:text>","formula":"</xsl:text>
        <xsl:call-template name="replace">
          <xsl:with-param name="p-string" select="formula/text()"/>
          <xsl:with-param name="p-to-replace" select="'/'"/>
          <xsl:with-param name="p-replacement" select="'\/'"/>
        </xsl:call-template>
        <xsl:text>"</xsl:text>
      </xsl:when>
      <xsl:when test="rating-points">
        <xsl:text>","values":[</xsl:text>      
        <xsl:for-each select="rating-points">
          <xsl:variable name="others"/>
          <xsl:for-each select="other-ind">
            <xsl:variable name="others">
              <xsl:copy-of select="$others"/>
              <xsl:value-of select="format-number(@value, '0.#######')"/>
              <xsl:text>,</xsl:text>
            </xsl:variable>
          </xsl:for-each>
          <xsl:for-each select="point">
            <xsl:text>,[</xsl:text>
            <xsl:copy-of select="$others"/>
            <xsl:value-of select="format-number(ind, '0.#######')"/>
            <xsl:text>,</xsl:text>
            <xsl:value-of select="format-number(dep, '0.#######')"/>
            <xsl:if test="note">
              <xsl:text>,"</xsl:text>
              <xsl:value-of select="note"/>
              <xsl:text>"</xsl:text>
            </xsl:if>
            <xsl:text>]</xsl:text>
          </xsl:for-each>
        </xsl:for-each>
        <xsl:text>]</xsl:text>
      </xsl:when>
    </xsl:choose>
    <xsl:if test="extension-points">
      <xsl:text>,"extension-values"</xsl:text>      
      <xsl:for-each select="extension-points/point">
        <xsl:text>,[</xsl:text>
        <xsl:copy-of select="$others"/>
        <xsl:value-of select="format-number(ind, '0.#######')"/>
        <xsl:text>,</xsl:text>
        <xsl:value-of select="format-number(dep, '0.#######')"/>
        <xsl:if test="note">
          <xsl:text>,"</xsl:text>
          <xsl:value-of select="note"/>
          <xsl:text>"</xsl:text>
        </xsl:if>
        <xsl:text>]</xsl:text>
      </xsl:for-each>
      <xsl:text>]</xsl:text>
    </xsl:if>
    <xsl:text>}}</xsl:text>
    <xsl:if test="not(following-sibling::*[contains(name(), '-rating')])">
      <xsl:text>]}}</xsl:text>
    </xsl:if>
  </xsl:template>
  
  <!-- usgs-stream-rating -->
  <xsl:template match="/ratings/usgs-stream-rating">
    <xsl:if test="not(preceding-sibling::rating-template) and not(preceding-sibling::rating-spec)">
      <xsl:text>{"ratings":{</xsl:text>
    </xsl:if>
    <xsl:if test="not(preceding-sibling::*[contains(name(), '-rating')])">
      <xsl:text>,"ratings":[</xsl:text>
    </xsl:if>
    <xsl:text>,{"usgs-stream-rating":{"office":"</xsl:text>
    <xsl:value-of select="@office-id"/>
    <xsl:text>","name":"</xsl:text>
    <xsl:value-of select="rating-spec-id"/>
    <xsl:variable name="datum" select="units-id/@vertical-datum"/>
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
            <xsl:text>","ind-parameter":"</xsl:text>
            <xsl:copy-of select="$ind-parameter"/>
            <xsl:text> (</xsl:text>
            <xsl:copy-of select="$ind-unit"/>
            <xsl:text> </xsl:text>
            <xsl:copy-of select="$datum"/>
            <xsl:text>)","dep-parameter":"</xsl:text>
            <xsl:copy-of select="$dep-parameter"/>
            <xsl:text> (</xsl:text>
            <xsl:copy-of select="$dep-unit"/>
            <xsl:text> </xsl:text>
            <xsl:copy-of select="$datum"/>
            <xsl:text>)"</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>","ind-parameter":"</xsl:text>
            <xsl:copy-of select="$ind-parameter"/>
            <xsl:text> (</xsl:text>
            <xsl:copy-of select="$ind-unit"/>
            <xsl:text>)","dep-parameter":"</xsl:text>
            <xsl:copy-of select="$dep-parameter"/>
            <xsl:text> (</xsl:text>
            <xsl:copy-of select="$dep-unit"/>
            <xsl:text>)"</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>","ind-parameter":"</xsl:text>
        <xsl:copy-of select="$ind-parameter"/>
        <xsl:text> (</xsl:text>
        <xsl:copy-of select="$ind-unit"/>
        <xsl:text>)","dep-parameter":"</xsl:text>
        <xsl:copy-of select="$dep-parameter"/>
        <xsl:text> (</xsl:text>
        <xsl:copy-of select="$dep-unit"/>
        <xsl:text>)"</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text>,"effective-date":"</xsl:text>
    <xsl:value-of select="effective-date"/>
    <xsl:text>","description":"</xsl:text>
    <xsl:value-of select="description"/>
    <xsl:text>"</xsl:text>
    <xsl:text>,"shifts":[</xsl:text>
    <xsl:if test="height-shifts">
      <xsl:for-each select="height-shifts">
        <xsl:text>,{"effective-date":"</xsl:text>
        <xsl:value-of select="effective-date"/>
        <xsl:text>","values":[</xsl:text>
        <xsl:for-each select="point">
          <xsl:text>,[</xsl:text>
          <xsl:value-of select="format-number(ind, '0.#######')"/>
          <xsl:text>,</xsl:text>
          <xsl:value-of select="format-number(dep, '0.#######')"/>
          <xsl:if test="note">
            <xsl:text>,"</xsl:text>
            <xsl:value-of select="note"/>
            <xsl:text>"</xsl:text>
          </xsl:if>
          <xsl:text>]</xsl:text>
        </xsl:for-each>
        <xsl:text>]}</xsl:text>
      </xsl:for-each>
    </xsl:if>
    <xsl:text>],"offsets":[</xsl:text>      
    <xsl:for-each select="height-offsets">
      <xsl:for-each select="point">
        <xsl:text>,[</xsl:text>
        <xsl:value-of select="format-number(ind, '0.#######')"/>
        <xsl:text>,</xsl:text>
        <xsl:value-of select="format-number(dep, '0.#######')"/>
        <xsl:if test="note">
          <xsl:text>,"</xsl:text>
          <xsl:value-of select="note"/>
          <xsl:text>"</xsl:text>
        </xsl:if>
        <xsl:text>]</xsl:text>
      </xsl:for-each>
    </xsl:for-each>
    <xsl:text>],"values":[</xsl:text>
    <xsl:for-each select="rating-points/point">
        <xsl:text>,[</xsl:text>
        <xsl:value-of select="format-number(ind, '0.#######')"/>
        <xsl:text>,</xsl:text>
        <xsl:value-of select="format-number(dep, '0.#######')"/>
        <xsl:if test="note">
          <xsl:text>,"</xsl:text>
          <xsl:value-of select="note"/>
          <xsl:text>"</xsl:text>
        </xsl:if>
        <xsl:text>]</xsl:text>
    </xsl:for-each>
    <xsl:text>]</xsl:text>
    <xsl:if test="extension-points">
      <xsl:text>,"extension-values"</xsl:text>      
      <xsl:for-each select="extension-points/point">
        <xsl:text>,[</xsl:text>
        <xsl:value-of select="format-number(ind, '0.#######')"/>
        <xsl:text>,</xsl:text>
        <xsl:value-of select="format-number(dep, '0.#######')"/>
        <xsl:if test="note">
          <xsl:text>,"</xsl:text>
          <xsl:value-of select="note"/>
          <xsl:text>"</xsl:text>
        </xsl:if>
        <xsl:text>]</xsl:text>
      </xsl:for-each>
      <xsl:text>]</xsl:text>
    </xsl:if>
    <xsl:text>}}</xsl:text>
    <xsl:if test="not(following-sibling::*[contains(name(), '-rating')])">
      <xsl:text>]}}</xsl:text>
    </xsl:if>
  </xsl:template>
  
  <!-- transitional-rating -->
  <xsl:template match="/ratings/transitional-rating">
    <xsl:if test="not(preceding-sibling::rating-template) and not(preceding-sibling::rating-spec)">
      <xsl:text>{"ratings":{</xsl:text>
    </xsl:if>
    <xsl:if test="not(preceding-sibling::*[contains(name(), '-rating')])">
      <xsl:text>,"ratings":[</xsl:text>
    </xsl:if>
    <xsl:text>,{"transitional-rating":{"office":"</xsl:text>
    <xsl:value-of select="@office-id"/>
    <xsl:text>","name":"</xsl:text>
    <xsl:value-of select="rating-spec-id"/>
    <xsl:text>"</xsl:text>
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
    <xsl:text>,"effective-date":"</xsl:text>
    <xsl:value-of select="effective-date"/>
    <xsl:text>","description":"</xsl:text>
    <xsl:value-of select="description"/>
    <xsl:text>","cases":[</xsl:text>
    <xsl:for-each select="select/case">
      <xsl:text>,{"when":"</xsl:text>
      <xsl:value-of select="when"/>    
      <xsl:text>","then":"</xsl:text>
      <xsl:value-of select="then"/>
      <xsl:text>"}</xsl:text>
    </xsl:for-each>
    <xsl:text>],"default":"</xsl:text>
    <xsl:value-of select="select/default"/>    
    <xsl:text>","references":[</xsl:text>
      <xsl:for-each select="source-ratings/rating-spec-id">
        <xsl:text>,{"R</xsl:text>
        <xsl:value-of select="@position"/>
        <xsl:text>":"</xsl:text>
        <xsl:value-of select="."/>
        <xsl:text>"}</xsl:text>
      </xsl:for-each>
      <xsl:text>]}}</xsl:text>
    <xsl:if test="not(following-sibling::*[contains(name(), '-rating')])">
      <xsl:text>]}}</xsl:text>
    </xsl:if>
  </xsl:template>
  
  <!-- virtual-rating -->
  <xsl:template match="/ratings/virtual-rating">
    <xsl:if test="not(preceding-sibling::rating-template) and not(preceding-sibling::rating-spec)">
      <xsl:text>{"ratings":{</xsl:text>
    </xsl:if>
    <xsl:if test="not(preceding-sibling::*[contains(name(), '-rating')])">
      <xsl:text>,"ratings":[</xsl:text>
    </xsl:if>
    <xsl:text>,{"virtual-rating":{"office":"</xsl:text>
    <xsl:value-of select="@office-id"/>
    <xsl:text>","name":"</xsl:text>
    <xsl:value-of select="rating-spec-id"/>
    <xsl:text>"</xsl:text>
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
    <xsl:text>,"effective-date":"</xsl:text>
    <xsl:value-of select="effective-date"/>
    <xsl:text>","description":"</xsl:text>
    <xsl:value-of select="description"/>
    <xsl:text>","connections":["</xsl:text>
    <xsl:call-template name="replace">
      <xsl:with-param name="p-string" select="connections/text()"/>
      <xsl:with-param name="p-to-replace" select="','"/>
      <xsl:with-param name="p-replacement" select="'&quot;,&quot;'"/>
    </xsl:call-template>
    <xsl:text>"],"references":[</xsl:text>
    <xsl:for-each select="source-ratings/source-rating">
      <xsl:text>,{"name":"R</xsl:text>
      <xsl:value-of select="@position"/>
      <xsl:text>","reference":"</xsl:text>
      <xsl:choose>
        <xsl:when test="rating-spec-id">
          <xsl:call-template name="trim">
            <xsl:with-param name="p-string" select="substring-before(rating-spec-id, '{')"/>
          </xsl:call-template>
          <xsl:text>","units":"</xsl:text>
          <xsl:call-template name="trim">
            <xsl:with-param name="p-string" select="substring-after(substring-before(rating-spec-id, '}'), '{')"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="trim">
            <xsl:with-param name="p-string" select="substring-before(rating-expression, '{')"/>
          </xsl:call-template>
          <xsl:text>","units":"</xsl:text>
          <xsl:call-template name="trim">
            <xsl:with-param name="p-string" select="substring-after(substring-before(rating-expression, '}'), '{')"/>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:text>"}</xsl:text>
    </xsl:for-each>
    <xsl:text>]}}</xsl:text>
    <xsl:if test="not(following-sibling::*[contains(name(), '-rating')])">
      <xsl:text>]}}</xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template match="/ratings/query-info"/>

  <xsl:template match="node()|@*">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>
  
</xsl:stylesheet>

