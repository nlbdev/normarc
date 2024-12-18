<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:dc="http://purl.org/dc/elements/1.1/"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:nlb="http://www.nlb.no/"
                xmlns:nlbbib="http://www.nlb.no/bibliographic"
                xmlns:SRU="http://www.loc.gov/zing/sru/"
                xmlns:normarc="info:lc/xmlns/marcxchange-v1"
                xmlns:schema="http://schema.org/"
                xmlns:marcxchange="info:lc/xmlns/marcxchange-v1"
                xmlns:DIAG="http://www.loc.gov/zing/sru/diagnostics/"
                xmlns:opf="http://www.idpf.org/2007/opf"
                xmlns="http://www.idpf.org/2007/opf"
                exclude-result-prefixes="#all"
                xpath-default-namespace="http://www.idpf.org/2007/opf"
                version="2.0">

    <xsl:output indent="no" exclude-result-prefixes="#all" omit-xml-declaration="yes"/>

    <xsl:param name="nested" select="false()" as="xs:boolean"/>
    <xsl:param name="include-source-reference" select="false()" as="xs:boolean"/>
    <xsl:param name="include-source-reference-as-comments" select="false()" as="xs:boolean"/>
    <xsl:param name="identifier" select="''" as="xs:string"/>
    <xsl:param name="prefix-everything" select="false()" as="xs:boolean"/>
    <xsl:param name="verbose" select="false()" as="xs:boolean"/>
    
    <xsl:template match="@*|node()">
        <xsl:if test="$verbose = true()">
            <xsl:choose>
                <xsl:when test="self::*[@tag]">
                    <xsl:message>
                        <xsl:text>Ingen regel for NORMARC-felt: </xsl:text>
                        <xsl:value-of select="@tag"/>
                        <xsl:text> (boknummer: </xsl:text>
                        <xsl:value-of select="../*[@tag='001']/text()"/>
                        <xsl:text>)</xsl:text>
                    </xsl:message>
                </xsl:when>
                <xsl:when test="self::*[@code]">
                    <xsl:message>
                        <xsl:text>Ingen regel for NORMARC-delfelt: </xsl:text>
                        <xsl:value-of select="parent::*/@tag"/>
                        <xsl:text> $</xsl:text>
                        <xsl:value-of select="@code"/>
                        <xsl:text> (boknummer: </xsl:text>
                        <xsl:value-of select="../../*[@tag='001']/text()"/>
                        <xsl:text>)</xsl:text>
                    </xsl:message>
                </xsl:when>
                <xsl:when test="self::*">
                    <xsl:message
                        select="concat('marcxchange-to-opf.xsl: no match for element &quot;',concat('/',string-join((ancestor-or-self::*)/concat(name(),'[',count(preceding-sibling::*)+1,']'),'/')),'&quot; with attributes: ',string-join(for $attribute in @* return concat($attribute/name(),'=&quot;',$attribute,'&quot;'),' '))"
                    />
                </xsl:when>
            </xsl:choose>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="/*" priority="2">
        <xsl:text>    </xsl:text>
        <xsl:variable name="result" as="element()*">
            <xsl:next-match/>
        </xsl:variable>
        <xsl:sequence select="$result"/>
    </xsl:template>

    <xsl:template match="SRU:*">
        <xsl:apply-templates select="node()"/>
    </xsl:template>

    <xsl:template match="*:record[not(self::SRU:*)]">
        <xsl:variable name="metadata" as="element()">
            <metadata>
                <xsl:namespace name="dc" select="'http://purl.org/dc/elements/1.1/'"/>
                <xsl:namespace name="nlbbib" select="'http://www.nlb.no/bibliographic'"/>
                <xsl:namespace name="schema" select="'http://schema.org/'"/>
                <xsl:if test="$include-source-reference">
                    <xsl:namespace name="nlb" select="'http://www.nlb.no/'"/>
                </xsl:if>
                <xsl:variable name="with-duplicates" as="element()*">
                    <xsl:apply-templates select="node()"/>
                </xsl:variable>
                <xsl:variable name="without-duplicates" as="element()*">
                    <xsl:for-each select="$with-duplicates">
                        <xsl:variable name="position" select="position()"/>
                        <xsl:choose>
                            <xsl:when test="exists(@id | @refines)">
                                <!-- don't remove duplicates if the duplicate has an id or refines attribute -->
                                <xsl:copy exclude-result-prefixes="#all">
                                    <xsl:copy-of select="@*" exclude-result-prefixes="#all"/>
                                    <xsl:copy-of select="node()" exclude-result-prefixes="#all"/>
                                </xsl:copy>
                            </xsl:when>
                            <xsl:when test="self::dc:*">
                                <xsl:if test="not($with-duplicates[position() &lt; $position and name()=current()/name() and text()=current()/text() and string(@refines)=string(current()/@refines)])">
                                    <xsl:copy exclude-result-prefixes="#all">
                                        <xsl:copy-of select="$with-duplicates[self::dc:*[name()=current()/name() and text()=current()/text() and string(@refines)=string(current()/@refines)]]/@*" exclude-result-prefixes="#all"/>
                                        <xsl:copy-of select="node()" exclude-result-prefixes="#all"/>
                                    </xsl:copy>
                                </xsl:if>
                            </xsl:when>
                            <xsl:when test="self::meta">
                                <xsl:variable name="this" select="."/>
                                <xsl:if
                                    test="not($with-duplicates[position() &lt; $position and @property=current()/@property and text()=current()/text() and string(@refines)=string(current()/@refines)])">
                                    <xsl:copy exclude-result-prefixes="#all">
                                        <xsl:copy-of select="$with-duplicates[self::meta[@property=current()/@property and text()=current()/text() and string(@refines)=string(current()/@refines)]]/@*" exclude-result-prefixes="#all"/>
                                        <xsl:copy-of select="node()" exclude-result-prefixes="#all"/>
                                    </xsl:copy>
                                </xsl:if>
                            </xsl:when>
                        </xsl:choose>
                    </xsl:for-each>
                </xsl:variable>
                <xsl:variable name="without-duplicate-role-and-id" as="element()*">
                    <xsl:for-each select="$without-duplicates">
                        <xsl:choose>
                            <xsl:when test="@property = 'bibliofil-id'">
                                <xsl:variable name="position" as="xs:integer" select="position()"/>
                                <xsl:variable name="bibliofil-id" as="xs:string" select="text()"/>
                                <xsl:variable name="target-role" as="xs:string?" select="($without-duplicates[concat('#', @id) = current()/@refines]/string((@property, name())[1]))[1]"/>
                                <xsl:variable name="preceding-bibliofil-id" as="element()*" select="$without-duplicates[position() lt $position and @property = 'bibliofil-id' and text() = $bibliofil-id]"/>
                                <xsl:variable name="preceding-bibliofil-id-target-roles" as="xs:string*" select="$without-duplicates[concat('#', @id) = $preceding-bibliofil-id/@refines]/(string((@property, name())[1]))"/>
                                <xsl:if test="not($target-role = $preceding-bibliofil-id-target-roles)">
                                    <xsl:sequence select="."/>
                                </xsl:if>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:sequence select="."/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each>
                </xsl:variable>

                <xsl:variable name="sorted" as="element()*">
                    <xsl:for-each select="$without-duplicate-role-and-id[self::dc:*[not(@refines)]]">
                        <xsl:sort
                            select="if (not(contains('dc:identifier dc:title dc:creator dc:format',name()))) then 100 else count(tokenize(substring-before('dc:identifier dc:title dc:creator dc:format',name()),' '))"/>
                        <xsl:copy-of select="." exclude-result-prefixes="#all"/>
                        <xsl:if test="@id">
                            <xsl:call-template name="copy-meta-refines">
                                <xsl:with-param name="meta-set" select="$without-duplicate-role-and-id"/>
                                <xsl:with-param name="id" select="string(@id)"/>
                            </xsl:call-template>
                        </xsl:if>
                    </xsl:for-each>
                    <xsl:for-each select="$without-duplicate-role-and-id[self::meta[starts-with(@property,'dc:') and not(@refines)]]">
                        <xsl:sort select="@property"/>
                        <xsl:copy-of select="." exclude-result-prefixes="#all"/>
                        <xsl:if test="@id">
                            <xsl:call-template name="copy-meta-refines">
                                <xsl:with-param name="meta-set" select="$without-duplicate-role-and-id"/>
                                <xsl:with-param name="id" select="string(@id)"/>
                            </xsl:call-template>
                        </xsl:if>
                    </xsl:for-each>
                    <xsl:for-each select="$without-duplicate-role-and-id[self::meta[not(starts-with(@property,'dc:')) and contains(@property,':') and not(@refines)]]">
                        <xsl:sort select="@property"/>
                        <xsl:copy-of select="." exclude-result-prefixes="#all"/>
                        <xsl:if test="@id">
                            <xsl:call-template name="copy-meta-refines">
                                <xsl:with-param name="meta-set" select="$without-duplicate-role-and-id"/>
                                <xsl:with-param name="id" select="string(@id)"/>
                            </xsl:call-template>
                        </xsl:if>
                    </xsl:for-each>
                    <xsl:for-each select="$without-duplicate-role-and-id[self::meta[not(contains(@property,':')) and not(@refines)]]">
                        <xsl:sort select="@property"/>
                        <xsl:copy-of select="." exclude-result-prefixes="#all"/>
                        <xsl:if test="@id">
                            <xsl:call-template name="copy-meta-refines">
                                <xsl:with-param name="meta-set" select="$without-duplicate-role-and-id"/>
                                <xsl:with-param name="id" select="string(@id)"/>
                            </xsl:call-template>
                        </xsl:if>
                    </xsl:for-each>
                </xsl:variable>

                <xsl:for-each select="$sorted">
                    <!-- remove unneccessary id's on non-DC elements -->
                    <xsl:copy exclude-result-prefixes="#all">
                        <xsl:copy-of select="@* except @id" exclude-result-prefixes="#all"/>
                        <xsl:if test="self::dc:* or @id and $sorted[@refines = concat('#',current()/@id)]">
                            <xsl:copy-of select="@id" exclude-result-prefixes="#all"/>
                        </xsl:if>
                        <xsl:copy-of select="node()" exclude-result-prefixes="#all"/>
                    </xsl:copy>
                </xsl:for-each>
            </metadata>
        </xsl:variable>
        
        <xsl:variable name="metadata" as="element()">
            <xsl:choose>
                <xsl:when test="string($nested) = 'true'">
                    <xsl:for-each select="$metadata">
                        <xsl:copy exclude-result-prefixes="#all">
                            <xsl:copy-of select="@* | namespace::*" exclude-result-prefixes="#all"/>
                            <xsl:for-each select="*[not(@refines)] | comment()">
                                <xsl:choose>
                                    <xsl:when test="self::comment()">
                                        <xsl:copy-of select="." exclude-result-prefixes="#all"/>
                                    </xsl:when>
                                    <xsl:when test="self::*">
                                        <xsl:apply-templates select="." mode="nesting"/>
                                    </xsl:when>
                                </xsl:choose>
                            </xsl:for-each>
                        </xsl:copy>
                    </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy-of select="$metadata" exclude-result-prefixes="#all"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:variable name="metadata" as="element()">
            <xsl:choose>
                <xsl:when test="$include-source-reference-as-comments">
                    <xsl:call-template name="add-comments">
                        <xsl:with-param name="context" select="$metadata"/>
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy-of select="$metadata" exclude-result-prefixes="#all"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:call-template name="indent">
            <xsl:with-param name="element" select="$metadata"/>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template name="add-comments">
        <xsl:param name="context" as="element()"/>
        
        <xsl:for-each select="$context">
            <xsl:element name="{name()}" exclude-result-prefixes="#all">
                <xsl:copy-of select="@* except @nlb:metadata-source | namespace::*[not(name() = 'nlb')]" exclude-result-prefixes="#all"/>

                <xsl:if test="$include-source-reference">
                    <xsl:copy-of select="namespace::*[name() = 'nlb']"/>
                    <xsl:copy-of select="@nlb:metadata-source" exclude-result-prefixes="#all"/>
                </xsl:if>
                
                <xsl:for-each select="node()">
                    <xsl:choose>
                        <xsl:when test="self::*">
                            <xsl:call-template name="add-comments">
                                <xsl:with-param name="context" select="."/>
                            </xsl:call-template>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:copy-of select="." exclude-result-prefixes="#all"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
            </xsl:element>
        </xsl:for-each>
        
        <xsl:if test="$include-source-reference-as-comments and @nlb:metadata-source and parent::*">
            <xsl:text> </xsl:text>
            <xsl:comment select="concat(' ', @nlb:metadata-source, ' ')"/>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="indent">
        <xsl:param name="element" as="element()"/>
        
        <xsl:if test="exists($element/parent::*) and $element/parent::*/normalize-space(string-join(text(),'')) = ''">
            <xsl:text>
</xsl:text>
            <xsl:for-each select="0 to count($element/ancestor::*)">
                <xsl:text>    </xsl:text>
            </xsl:for-each>
        </xsl:if>
        
        <xsl:for-each select="$element">
            <xsl:copy exclude-result-prefixes="#all">
                <xsl:copy-of select="@* | namespace::*" exclude-result-prefixes="#all"/>
                <xsl:for-each select="node()">
                    <xsl:choose>
                        <xsl:when test="self::*">
                            <xsl:call-template name="indent">
                                <xsl:with-param name="element" select="."/>
                            </xsl:call-template>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:copy-of select="." exclude-result-prefixes="#all"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
                
                <xsl:if test="exists(*)">
                    <xsl:text>
</xsl:text>
                    <xsl:for-each select="0 to count($element/ancestor::*)">
                        <xsl:text>    </xsl:text>
                    </xsl:for-each>
                </xsl:if>
            </xsl:copy>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="copy-meta-refines">
        <xsl:param name="meta-set" required="yes" as="element()*"/>
        <xsl:param name="id" required="yes" as="xs:string"/>
        <xsl:variable name="idref" select="concat('#',$id)"/>
        <xsl:for-each select="$meta-set[self::*[@refines=$idref]]">
            <xsl:sort select="string((@property, name())[1])"/>
            <xsl:copy-of select="." exclude-result-prefixes="#all"/>
            <xsl:if test="@id">
                <xsl:call-template name="copy-meta-refines">
                    <xsl:with-param name="meta-set" select="$meta-set"/>
                    <xsl:with-param name="id" select="string(@id)"/>
                </xsl:call-template>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="*" mode="nesting">
        <xsl:copy exclude-result-prefixes="#all">
            <xsl:copy-of select="@* except (@property, @refines)" exclude-result-prefixes="#all"/>
            <xsl:if test="@property">
                <xsl:attribute name="name" select="@property"/>
            </xsl:if>
            <xsl:attribute name="content" select="text()"/>
            <xsl:if test="@id">
                <xsl:apply-templates select="../*[@refines = concat('#',current()/@id)]" mode="nesting"/>
            </xsl:if>
        </xsl:copy>
    </xsl:template>

    <xsl:template name="meta">
        <xsl:param name="context" as="element()?" select="."/>
        <xsl:param name="controlfield_position" as="xs:string?"/>
        <xsl:param name="property" as="xs:string"/>
        <xsl:param name="value" as="xs:string+"/>
        <xsl:param name="id" as="xs:string?" select="()"/>
        <xsl:param name="refines" as="xs:string?" select="()"/>
        
        <xsl:if test="not($property)">
            <xsl:message terminate="yes" select="'No property name was given'"/>
        </xsl:if>
        <xsl:if test="count($value) = 0">
            <xsl:message terminate="yes" select="concat('No value was given (value=', string($value), ')')"/>
        </xsl:if>

        <xsl:variable name="dublin-core" select="$property = ('dc:contributor', 'dc:coverage', 'dc:creator', 'dc:date', 'dc:description', 'dc:format', 'dc:identifier',
                                                              'dc:language', 'dc:publisher', 'dc:relation', 'dc:rights', 'dc:source', 'dc:subject', 'dc:title', 'dc:type')" as="xs:boolean"/>

        <xsl:variable name="identifier001" as="xs:string?" select="($context/(../* | ../../*)[self::*:controlfield[@tag='001']])[1]/replace(text(), '^0+(.)', '$1')"/>
        <xsl:variable name="tag" select="($context/../@tag, $context/@tag, '???')[1]"/>
        <xsl:variable name="metadata-source-text" select="concat('Bibliofil', if ($identifier001) then concat('@',$identifier001) else '', ' *', $tag, if ($context/@code) then concat('$',$context/@code) else '', if ($controlfield_position) then concat('/', $controlfield_position) else '')"/>
        <xsl:variable name="metadata-source-text" select="concat($metadata-source-text, if ($identifier001 != $identifier and $property = ('dc:identifier', 'dc:title') and not($refines)) then ' + dc:identifier' else '')"/>

        <xsl:element name="{if ($dublin-core and not($refines)) then $property else 'meta'}">
            <xsl:if test="$include-source-reference or $include-source-reference-as-comments">
                <xsl:attribute name="nlb:metadata-source" select="$metadata-source-text"/>
            </xsl:if>

            <xsl:if test="not($dublin-core) or $refines">
                <xsl:attribute name="property" select="$property"/>
            </xsl:if>

            <xsl:if test="$id">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>

            <xsl:if test="$refines">
                <xsl:attribute name="refines" select="concat('#',$refines)"/>
            </xsl:if>
            
            <xsl:if test="count($value) gt 1">
                <xsl:message select="concat('WARNING: more than one value at ', $metadata-source-text)"/>
                <xsl:for-each select="$value">
                    <xsl:message select="."/>
                </xsl:for-each>
            </xsl:if>

            <xsl:value-of select="($value)[1]"/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template name="bibliofil-id">
        <xsl:param name="context" as="element()?" select="."/>
        <xsl:param name="property" as="xs:string" select="nlb:prefixed-property('bibliofil-id')"/>
        <xsl:param name="refines" as="xs:string?" select="()"/>
        
        <xsl:variable name="subfield" select="($context/*:subfield[@code='_' and matches(., '^\d+$')],
                                               $context/*:subfield[@code='3' and matches(., '^\d+$')])[1]"/>
        
        <xsl:for-each select="$subfield">
            <xsl:call-template name="meta">
                <xsl:with-param name="context" select="$subfield"/>
                <xsl:with-param name="property" select="$property"/>
                <xsl:with-param name="value" select="$subfield/text()"/>
                <xsl:with-param name="refines" select="$refines"/>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>

    <!-- 00X KONTROLLFELT -->

    <xsl:template match="*:leader"/>

    <xsl:template match="*:controlfield[@tag='001']">
        <xsl:variable name="edition-identifier" select="if ($identifier) then $identifier else replace(text(), '^0+(.)', '$1')"/>

        <xsl:call-template name="meta">
            <xsl:with-param name="property" select="'dc:identifier'"/>
            <xsl:with-param name="value" select="$edition-identifier"/>
            <xsl:with-param name="id" select="'pub-id'"/>
        </xsl:call-template>

        <xsl:call-template name="meta">
            <xsl:with-param name="property" select="'dc:source.urn-nbn'"/>
            <xsl:with-param name="value" select="concat('urn:nbn:no-nb_nlb_', $edition-identifier)"/>
        </xsl:call-template>
        
        <xsl:call-template name="meta">
            <xsl:with-param name="property" select="nlb:prefixed-property('library')"/>
            <xsl:with-param name="value" select="nlb:parseLibrary850a($edition-identifier, .)"/>
            <xsl:with-param name="context" select="(../*:datafield[@tag='850']/*:subfield[@code='a'], .)[1]"/>
        </xsl:call-template>

        <xsl:if test="matches(string($edition-identifier), '^\d{12}$')">
            <xsl:variable name="year" select="substring($edition-identifier,9)"/>
            <xsl:variable name="month" select="substring($edition-identifier,7,2)"/>
            <xsl:if test="not(../*:datafield[@tag='260']/*:subfield[@code='c'])">
                <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:date.issued'"/><xsl:with-param name="value" select="$year"/></xsl:call-template>
            </xsl:if>
            <xsl:if test="not(../*:datafield[@tag='596']/*:subfield[@code='c'])">
                <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:date.issued.original'"/><xsl:with-param name="value" select="$year"/></xsl:call-template>
            </xsl:if>
        </xsl:if>
        
        <!-- checking this here makes sure that the field is always defined. *260$9 is usually not present. -->
        <xsl:choose>
            <xsl:when test="../*:datafield[@tag='260']/*:subfield[@code='9']/text() = 'n'">
                <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('watermark')"/><xsl:with-param name="value" select="'false'"/></xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('watermark')"/><xsl:with-param name="value" select="'true'"/></xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="*:controlfield[@tag='003']">
        <!-- Ignoreres. Dette er noe som ble brukt "i riktig gamle dager". -->
    </xsl:template>

    <xsl:template match="*:controlfield[@tag='007']">
        <!--<xsl:message select="'NORMARC-felt ignorert: 007 FYSISK BESKRIVELSE AV DOKUMENTET'"/>-->
    </xsl:template>

    <xsl:template match="*:controlfield[@tag='008']">
        <xsl:variable name="POS00-05" select="substring(text(),1,6)"/>
        <xsl:variable name="POS21" select="substring(text(),22,1)"/>
        <xsl:variable name="POS22" select="substring(text(),23,1)"/>
        <xsl:variable name="POS33" select="substring(text(),34,1)"/>
        <xsl:variable name="POS34" select="substring(text(),35,1)"/>
        <xsl:variable name="POS35-37" select="substring(text(),36,3)"/>
        
        <xsl:if test="matches($POS00-05,'^\d\d\d\d\d\d$')">
            <xsl:variable name="current-year" select="xs:integer(tokenize(xs:string(current-date()),'-')[1])"/>
            <xsl:variable name="year" select="xs:integer(substring($POS00-05,1,2))"/>
            <xsl:variable name="year" select="xs:string($current-year - $current-year mod 100 + (if ($year gt $current-year mod 100) then $year - 100 else $year))"/>
            <xsl:variable name="month" select="substring($POS00-05,3,2)"/>
            <xsl:variable name="day" select="substring($POS00-05,5,2)"/>
            <xsl:variable name="registered" select="concat($year,'-',$month,'-',$day)"/>

            <xsl:call-template name="meta"><xsl:with-param name="controlfield_position" select="'00-05'"/><xsl:with-param name="property" select="'dc:date.registered'"/><xsl:with-param name="value" select="$registered"/></xsl:call-template>

            <xsl:variable name="available" as="node()*">
                <xsl:apply-templates select="(../*:datafield[@tag=('592')])"/>
            </xsl:variable>
            <xsl:variable name="external" as="node()*">
                <xsl:apply-templates select="(../*:datafield[@tag=('598', '594')])"/>
            </xsl:variable>
            <xsl:choose>
                <xsl:when test="count($available[@property='dc:date.available']) ge 1">
                    <!-- do nothing, dc:date.available is created in template for 592 -->
                </xsl:when>
                <xsl:when test="count($external[@property=nlb:prefixed-property('external-retrieved')]) ge 1">
                    <xsl:variable name="external-retrieved" select="($external[@property=nlb:prefixed-property('external-retrieved')])[1]" as="xs:string"/>
                    <xsl:call-template name="meta">
                        <xsl:with-param name="property" select="'dc:date.available'"/>
                        <xsl:with-param name="value" select="$external-retrieved"/>
                        <xsl:with-param name="context" select="(../*:datafield[@tag=('598', '594')])[1]"/>  <!-- most likely context. calculating the correct context with 100% certainty requires too many lines of code -->
                    </xsl:call-template>
                </xsl:when>
                <xsl:when test="matches($year,'^19..$')">
                    <xsl:call-template name="meta">
                        <xsl:with-param name="property" select="'dc:date.available'"/>
                        <xsl:with-param name="value" select="$registered"/>
                        <xsl:with-param name="controlfield_position" select="'00-05'"/>
                    </xsl:call-template>
                </xsl:when>
            </xsl:choose>
        </xsl:if>
        
        <xsl:choose>
            <xsl:when test="$POS21 = 'a'"><!-- "Årbok": Not in use; ignore for now --></xsl:when>
            <xsl:when test="$POS21 = 'm'"><!-- "Monografiserie": Not in use; ignore for now --></xsl:when>
            <xsl:when test="$POS21 = 'n'">
                <xsl:call-template name="meta"><xsl:with-param name="controlfield_position" select="'21'"/><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Periodika'"/></xsl:call-template>
                <xsl:call-template name="meta"><xsl:with-param name="controlfield_position" select="'21'"/><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Serial'"/></xsl:call-template>
                <xsl:call-template name="meta"><xsl:with-param name="controlfield_position" select="'21'"/><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Avis'"/></xsl:call-template>
                <xsl:call-template name="meta"><xsl:with-param name="controlfield_position" select="'21'"/><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Newspaper'"/></xsl:call-template>
                <xsl:call-template name="meta"><xsl:with-param name="controlfield_position" select="'21'"/><xsl:with-param name="property" select="nlb:prefixed-property('periodical')"/><xsl:with-param name="value" select="'true'"/></xsl:call-template>
                <xsl:call-template name="meta"><xsl:with-param name="controlfield_position" select="'21'"/><xsl:with-param name="property" select="nlb:prefixed-property('newspaper')"/><xsl:with-param name="value" select="'true'"/></xsl:call-template>
            </xsl:when>
            <xsl:when test="$POS21 = 'p'">
                <xsl:call-template name="meta"><xsl:with-param name="controlfield_position" select="'21'"/><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Periodika'"/></xsl:call-template>
                <xsl:call-template name="meta"><xsl:with-param name="controlfield_position" select="'21'"/><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Serial'"/></xsl:call-template>
                <xsl:call-template name="meta"><xsl:with-param name="controlfield_position" select="'21'"/><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Tidsskrift'"/></xsl:call-template>
                <xsl:call-template name="meta"><xsl:with-param name="controlfield_position" select="'21'"/><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Magazine'"/></xsl:call-template>
                <xsl:call-template name="meta"><xsl:with-param name="controlfield_position" select="'21'"/><xsl:with-param name="property" select="nlb:prefixed-property('periodical')"/><xsl:with-param name="value" select="'true'"/></xsl:call-template>
                <xsl:call-template name="meta"><xsl:with-param name="controlfield_position" select="'21'"/><xsl:with-param name="property" select="nlb:prefixed-property('magazine')"/><xsl:with-param name="value" select="'true'"/></xsl:call-template>
            </xsl:when>
            <xsl:when test="$POS21 = 'z'"><!-- "Andre typer periodika": Not in use; ignore for now --></xsl:when>
        </xsl:choose>
        
        <xsl:variable name="tag385sub0_contexts" select="../*:datafield[@tag='385']/*:subfield[@code='0' and replace(text(), '^.*/', '') = ('TG1000', 'TG1001', 'TG1002', 'TG1003', 'TG1004', 'TG1005', 'TG1015', 'TG1016')]" as="element()*"/>
        <xsl:variable name="tag385sub0" select="$tag385sub0_contexts/text()" as="xs:string*"/>
        <xsl:variable name="ageRangesFrom385sub0" as="xs:string*">
            <xsl:for-each select="$tag385sub0">
                <xsl:choose>
                    <xsl:when test=".='https://schema.nb.no/Bibliographic/Values/TG1000'">
                        <xsl:sequence select="'0-2'"/>
                    </xsl:when>
                    <xsl:when test=".='https://schema.nb.no/Bibliographic/Values/TG1001'">
                        <xsl:sequence select="'3-5'"/>
                    </xsl:when>
                    <xsl:when test=".='https://schema.nb.no/Bibliographic/Values/TG1002'">
                        <xsl:sequence select="'6-8'"/>
                    </xsl:when>
                    <xsl:when test=".='https://schema.nb.no/Bibliographic/Values/TG1003'">
                        <xsl:sequence select="'9-10'"/>
                    </xsl:when>
                    <xsl:when test=".='https://schema.nb.no/Bibliographic/Values/TG1004'">
                        <xsl:sequence select="'11-12'"/>
                    </xsl:when>
                    <xsl:when test=".='https://schema.nb.no/Bibliographic/Values/TG1005'">
                        <xsl:sequence select="'13-15'"/>
                    </xsl:when>
                    <xsl:when test=".='https://schema.nb.no/Bibliographic/Values/TG1015'">
                        <xsl:sequence select="'16-17'"/>
                    </xsl:when>
                    <xsl:when test=".='https://schema.nb.no/Bibliographic/Values/TG1016'">
                        <xsl:sequence select="'18-INF'"/>
                    </xsl:when>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="audienceFrom385sub0" as="xs:string*">
            <xsl:for-each select="$tag385sub0">
                <xsl:choose>
                    <xsl:when test=".='https://schema.nb.no/Bibliographic/Values/TG1000'">
                        <xsl:sequence select="'Child'"/>
                    </xsl:when>
                    <xsl:when test=".='https://schema.nb.no/Bibliographic/Values/TG1001'">
                        <xsl:sequence select="'Child'"/>
                    </xsl:when>
                    <xsl:when test=".='https://schema.nb.no/Bibliographic/Values/TG1002'">
                        <xsl:sequence select="'Child'"/>
                    </xsl:when>
                    <xsl:when test=".='https://schema.nb.no/Bibliographic/Values/TG1003'">
                        <xsl:sequence select="'Child'"/>
                    </xsl:when>
                    <xsl:when test=".='https://schema.nb.no/Bibliographic/Values/TG1004'">
                        <xsl:sequence select="'Child'"/>
                    </xsl:when>
                    <xsl:when test=".='https://schema.nb.no/Bibliographic/Values/TG1005'">
                        <xsl:sequence select="'Adolescent'"/>
                    </xsl:when>
                    <xsl:when test=".='https://schema.nb.no/Bibliographic/Values/TG1015'">
                        <xsl:sequence select="'Adolescent'"/>
                    </xsl:when>
                    <xsl:when test=".='https://schema.nb.no/Bibliographic/Values/TG1016'">
                        <xsl:sequence select="'Adult'"/>
                    </xsl:when>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="ageRangesFrom008POS22" as="xs:string*">
            <xsl:for-each select="$POS22">
                <xsl:choose>
                    <xsl:when test=".='a'">
                        <xsl:sequence select="'0-5'"/>
                    </xsl:when>
                    <xsl:when test=".='b'">
                        <xsl:sequence select="'6-8'"/>
                    </xsl:when>
                    <xsl:when test=".='c'">
                        <xsl:sequence select="'9-13'"/>
                    </xsl:when>
                    <xsl:when test=".='d'">
                        <xsl:sequence select="'14-17'"/>
                    </xsl:when>
                    <xsl:when test=".='j'">
                        <xsl:sequence select="'0-15'"/>
                    </xsl:when>
                    <xsl:when test=".='e'">
                        <xsl:sequence select="'18-INF'"/>
                    </xsl:when>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="tag019a_context" select="(../*:datafield[@tag='019']/*:subfield[@code='a'])[1]" as="element()?"/>
        <xsl:variable name="tag019a" select="../*:datafield[@tag='019']/*:subfield[@code='a']/tokenize(replace(replace(text(), '[\[\]\s]', ''), '[/\.-]', ','), '[,\.\-_]')" as="xs:string*"/>
        <xsl:variable name="tag019a" select="for $a in ($tag019a) return if (string-length($a) gt 0) then $a else ()" as="xs:string*"/>
        <xsl:variable name="ageRangesFrom019a" as="xs:string*">
            <!-- *019$a is a remnant from NORMARC. If there's no *385$0, let's fall back to this instead -->
            <xsl:if test="count($tag385sub0) = 0">
                <xsl:for-each select="$tag019a">
                    <xsl:choose>
                        <xsl:when test=".='a'">
                            <xsl:sequence select="'0-5'"/>
                        </xsl:when>
                        <xsl:when test=".='b'">
                            <xsl:sequence select="'6-7'"/>
                        </xsl:when>
                        <xsl:when test=".='bu'">
                            <xsl:sequence select="'8-10'"/>
                        </xsl:when>
                        <xsl:when test=".='u'">
                            <xsl:sequence select="'11-12'"/>
                        </xsl:when>
                        <xsl:when test=".='mu'">
                            <xsl:sequence select="'13-16'"/>
                        </xsl:when>
                    </xsl:choose>
                </xsl:for-each>
            </xsl:if>
        </xsl:variable>
        <xsl:variable name="audienceFrom019a" as="xs:string*">
            <!-- *019$a is a remnant from NORMARC. If there's no *385$0, let's fall back to this instead -->
            <xsl:if test="count($tag385sub0) = 0">
                <xsl:for-each select="$tag019a">
                    <xsl:choose>
                        <xsl:when test=".='a'">
                            <xsl:sequence select="'Child'"/>
                        </xsl:when>
                        <xsl:when test=".='b'">
                            <xsl:sequence select="'Child'"/>
                        </xsl:when>
                        <xsl:when test=".='bu'">
                            <xsl:sequence select="'Child'"/>
                        </xsl:when>
                        <xsl:when test=".='u'">
                            <xsl:sequence select="'Child'"/>
                        </xsl:when>
                        <xsl:when test=".='mu'">
                            <xsl:sequence select="'Adolescent'"/>
                        </xsl:when>
                    </xsl:choose>
                </xsl:for-each>
            </xsl:if>
        </xsl:variable>
        <xsl:variable name="ageRanges" select="if (count($ageRangesFrom385sub0)) then $ageRangesFrom385sub0 else if (count($ageRangesFrom019a)) then $ageRangesFrom019a else $ageRangesFrom008POS22"/>
        <xsl:variable name="ageRangeFrom" select="if (count($ageRanges) = 0) then '' else xs:integer(min(for $range in ($ageRanges) return xs:double(tokenize($range,'-')[1])))"/>
        <xsl:variable name="ageMax" select="if (count($ageRanges) = 0) then '' else max(for $range in ($ageRanges) return xs:double(tokenize($range,'-')[2]))"/>
        <xsl:variable name="ageRangeTo" select="if ($ageMax and $ageMax = xs:double('INF') or $POS22 = 'e') then '' else $ageMax"/>

        <xsl:if test="$ageRangeFrom or $ageRangeTo">
            <xsl:call-template name="meta">
                <xsl:with-param name="property" select="nlb:prefixed-property('typicalAgeRange')"/>
                <xsl:with-param name="value" select="concat($ageRangeFrom,'-',$ageRangeTo)"/>
                <xsl:with-param name="context" select="($tag385sub0_contexts, $tag019a_context, .)[1]"/>
                <xsl:with-param name="controlfield_position" select="if (($tag385sub0_contexts, $tag019a_context, .)[1] = .) then '22' else ()"/>
            </xsl:call-template>
        </xsl:if>

        <!--
            - if *008/22 is 'e', then use "Adult"
            - else if *OO8/22 is 'd', then use "Adolescent"
            - else if *008/22 is 'j' and *385$0 points to adult (https://schema.nb.no/Bibliographic/Values/TG1016), then use "Adolescent"
            - else if *385$0 points to an audience, then use that (vu/mu=Adolescent, u/bu/b/a/aa=Child)
            - else if *019$a points to an audience, then use that (mu=Adolescent, u/bu/b/a=Child)
            - else if *008/22 is 'j', then use "Child"
            - else use "Adult"
        -->
        <xsl:choose>
            <xsl:when test="$POS22='e'">
                <xsl:call-template name="meta">
                    <xsl:with-param name="controlfield_position" select="'22'"/>
                    <xsl:with-param name="property" select="nlb:prefixed-property('audience')"/>
                    <xsl:with-param name="value" select="'Adult'"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$POS22='d'">
                <xsl:call-template name="meta">
                    <xsl:with-param name="controlfield_position" select="'22'"/>
                    <xsl:with-param name="property" select="nlb:prefixed-property('audience')"/>
                    <xsl:with-param name="value" select="'Adolescent'"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$POS22='j' and $audienceFrom385sub0 = 'Adult'">
                <xsl:call-template name="meta">
                    <xsl:with-param name="context" select="$tag385sub0_contexts[1]"/>
                    <xsl:with-param name="property" select="nlb:prefixed-property('audience')"/>
                    <xsl:with-param name="value" select="'Adolescent'"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$audienceFrom385sub0 = 'Adolescent'">
                <xsl:call-template name="meta">
                    <xsl:with-param name="context" select="$tag385sub0_contexts[1]"/>
                    <xsl:with-param name="property" select="nlb:prefixed-property('audience')"/>
                    <xsl:with-param name="value" select="'Adolescent'"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$audienceFrom385sub0 = 'Child'">
                <xsl:call-template name="meta">
                    <xsl:with-param name="context" select="$tag385sub0_contexts[1]"/>
                    <xsl:with-param name="property" select="nlb:prefixed-property('audience')"/>
                    <xsl:with-param name="value" select="'Child'"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$audienceFrom019a = 'Adolescent'">
                <xsl:call-template name="meta">
                    <xsl:with-param name="context" select="$tag019a_context"/>
                    <xsl:with-param name="property" select="nlb:prefixed-property('audience')"/>
                    <xsl:with-param name="value" select="'Adolescent'"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$audienceFrom019a = 'Child'">
                <xsl:call-template name="meta">
                    <xsl:with-param name="context" select="$tag019a_context"/>
                    <xsl:with-param name="property" select="nlb:prefixed-property('audience')"/>
                    <xsl:with-param name="value" select="'Child'"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$POS22='j'">
                <xsl:call-template name="meta">
                    <xsl:with-param name="controlfield_position" select="'22'"/>
                    <xsl:with-param name="property" select="nlb:prefixed-property('audience')"/>
                    <xsl:with-param name="value" select="'Child'"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="meta">
                    <xsl:with-param name="controlfield_position" select="'22'"/>
                    <xsl:with-param name="property" select="nlb:prefixed-property('audience')"/>
                    <xsl:with-param name="value" select="'Adult'"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>

        <xsl:choose>
            <xsl:when test="$POS33='0'">
                <xsl:call-template name="meta"><xsl:with-param name="controlfield_position" select="'33'"/><xsl:with-param name="property" select="'dc:type.fiction'"/><xsl:with-param name="value" select="'false'"/></xsl:call-template>
                <xsl:call-template name="meta"><xsl:with-param name="controlfield_position" select="'33'"/><xsl:with-param name="property" select="'dc:type.genre'"/><xsl:with-param name="value" select="'Non-fiction'"/></xsl:call-template>
            </xsl:when>
            <xsl:when test="$POS33='1'">
                <xsl:call-template name="meta"><xsl:with-param name="controlfield_position" select="'33'"/><xsl:with-param name="property" select="'dc:type.fiction'"/><xsl:with-param name="value" select="'true'"/></xsl:call-template>
                <xsl:call-template name="meta"><xsl:with-param name="controlfield_position" select="'33'"/><xsl:with-param name="property" select="'dc:type.genre'"/><xsl:with-param name="value" select="'Fiction'"/></xsl:call-template>
            </xsl:when>
        </xsl:choose>

        <xsl:choose>
            <xsl:when test="$POS34='a'">
                <xsl:call-template name="meta"><xsl:with-param name="controlfield_position" select="'34'"/><xsl:with-param name="property" select="'dc:type.genre'"/><xsl:with-param name="value" select="'Biography'"/></xsl:call-template>
                <xsl:call-template name="meta"><xsl:with-param name="controlfield_position" select="'34'"/><xsl:with-param name="property" select="'dc:type.genre'"/><xsl:with-param name="value" select="'Autobiography'"/></xsl:call-template>
            </xsl:when>
            <xsl:when test="$POS34='b'">
                <xsl:call-template name="meta"><xsl:with-param name="controlfield_position" select="'34'"/><xsl:with-param name="property" select="'dc:type.genre'"/><xsl:with-param name="value" select="'Biography'"/></xsl:call-template>
                <xsl:call-template name="meta"><xsl:with-param name="controlfield_position" select="'34'"/><xsl:with-param name="property" select="'dc:type.genre'"/><xsl:with-param name="value" select="'Individual biography'"/></xsl:call-template>
            </xsl:when>
            <xsl:when test="$POS34='c'">
                <xsl:call-template name="meta"><xsl:with-param name="controlfield_position" select="'34'"/><xsl:with-param name="property" select="'dc:type.genre'"/><xsl:with-param name="value" select="'Biography'"/></xsl:call-template>
                <xsl:call-template name="meta"><xsl:with-param name="controlfield_position" select="'34'"/><xsl:with-param name="property" select="'dc:type.genre'"/><xsl:with-param name="value" select="'Collective biography'"/></xsl:call-template>
            </xsl:when>
            <xsl:when test="$POS34='d'">
                <xsl:call-template name="meta"><xsl:with-param name="controlfield_position" select="'34'"/><xsl:with-param name="property" select="'dc:type.genre'"/><xsl:with-param name="value" select="'Biography'"/></xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <!-- ('0', ' ') -->
                <xsl:call-template name="meta"><xsl:with-param name="controlfield_position" select="'34'"/><xsl:with-param name="property" select="'dc:type.genre'"/><xsl:with-param name="value" select="'Non-biography'"/></xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
        
        <xsl:if test="$POS34 = ('a', 'b', 'c', 'd')">
            <xsl:variable name="subject-id" select="'subject-008'"/>
            <xsl:variable name="bibliofil-id" select="'19880600'"/>  <!-- unfortunately hardcoded here - if we had a good way to do it  we could look for *655$aBiografisk in data.aut.txt and use $_ from there. -->
            
            <xsl:variable name="context" select="."/>
            <xsl:variable name="mainGenre" select="'Biografisk'"/>
            <xsl:variable name="genre" select="$mainGenre"/>
            
            <xsl:call-template name="meta"><xsl:with-param name="controlfield_position" select="'34'"/><xsl:with-param name="property" select="'dc:type.genre'"/><xsl:with-param name="value" select="$genre"/><xsl:with-param name="id" select="$subject-id"/></xsl:call-template>
            <xsl:call-template name="meta"><xsl:with-param name="controlfield_position" select="'34'"/><xsl:with-param name="property" select="'dc:type.genre.no'"/><xsl:with-param name="value" select="$genre"/><xsl:with-param name="refines" select="$subject-id"/></xsl:call-template>
            <xsl:call-template name="meta"><xsl:with-param name="controlfield_position" select="'34'"/><xsl:with-param name="property" select="'dc:type.mainGenre'"/><xsl:with-param name="value" select="$mainGenre"/><xsl:with-param name="refines" select="$subject-id"/></xsl:call-template>
            <xsl:call-template name="meta"><xsl:with-param name="controlfield_position" select="'34'"/><xsl:with-param name="property" select="nlb:prefixed-property('bibliofil-id')"/><xsl:with-param name="value" select="$bibliofil-id"/><xsl:with-param name="refines" select="$subject-id"/></xsl:call-template>
        </xsl:if>

        <xsl:choose>
            <xsl:when test="normalize-space($POS35-37) and normalize-space($POS35-37) != 'mul'">
                <xsl:call-template name="meta"><xsl:with-param name="controlfield_position" select="'35-37'"/><xsl:with-param name="property" select="'dc:language'"/><xsl:with-param name="value" select="$POS35-37"/></xsl:call-template>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="*:controlfield[@tag='009']">
        <xsl:variable name="POS05" select="substring(text(),6,1)"/>
        <xsl:if test="$POS05 = 'd'">
            <xsl:call-template name="meta"><xsl:with-param name="controlfield_position" select="'05'"/><xsl:with-param name="property" select="nlb:prefixed-property('availability')"/><xsl:with-param name="value" select="'deleted'"/></xsl:call-template>
        </xsl:if>
    </xsl:template>

    <!-- 010 - 04X KONTROLLNUMMER OG KODER -->

    <xsl:template match="*:datafield[@tag='015']">
        <!--<xsl:message select="'NORMARC-felt ignorert: 015 ANDRE BIBLIOGRAFISKE KONTROLLNUMMER'"/>-->
    </xsl:template>

    <xsl:template match="*:datafield[@tag='019']">
        <!-- *019$a handled in template for *008 -->

        <xsl:variable name="b" as="element()*">
            <xsl:for-each select="*:subfield[@code='b']">
                <xsl:variable name="context" select="."/>
                <xsl:for-each select="tokenize(replace(text(),'\s',''),'[,\.\-_]')">
                    <xsl:choose>
                        <xsl:when test=".='a'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Kartografisk materiale'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Cartographic materials'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='ab'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Kartografisk materiale'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Cartographic materials'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Atlas'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Atlas'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='aj'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Kartografisk materiale'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Cartographic materials'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Kart'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Map'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='b'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Manuskripter'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Manuscripts'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='c'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Musikktrykk'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Sheet music'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format'"/><xsl:with-param name="value" select="'Braille'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.no'"/><xsl:with-param name="value" select="'Punktskrift'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='d'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Lydopptak'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Audio recording'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='da'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Lydopptak'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Audio recording'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Grammofonplate'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Gramophone record'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='db'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Lydopptak'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Audio recording'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Kassett'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Cassette'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='dc'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Lydopptak'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Audio recording'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'CD (kompaktplate)'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Compact Disk'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format'"/><xsl:with-param name="value" select="'DAISY 2.02'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:type.audio'"/><xsl:with-param name="value" select="'true'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='dd'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Lydopptak'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Audio recording'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Avspiller med lydfil'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Player with audio file'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='de'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Lydopptak'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Audio recording'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Digikort'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Digikort'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='dg'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Lydopptak'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Audio recording'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Musikk'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Music'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='dh'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Lydopptak'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Audio recording'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Språkkurs'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Language course'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='di'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Lydopptak'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Audio recording'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Lydbok'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Audio book'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='dj'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Lydopptak'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Audio recording'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Annen tale/annet'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Other voice/other'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format'"/><xsl:with-param name="value" select="'DAISY 2.02'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:type.audio'"/><xsl:with-param name="value" select="'true'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='dk'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Lydopptak'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Audio recording'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Kombidokument'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Combined document'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='e'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Film'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Video'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='ec'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Film'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Video'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Filmspole'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Video tape'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='ed'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Film'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Video'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Videokassett (VHS)'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'VHS'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='ee'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Film'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Video'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Videoplate (DVD)'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'DVD'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='ef'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Film'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Video'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Blu-ray-plate'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Blu-ray'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='eg'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Film'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Video'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'3D'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'3D'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='f'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Grafisk materiale'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Graphic materials'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='fd'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Grafisk materiale'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Graphic materials'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Dias'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Slides'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='ff'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Grafisk materiale'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Graphic materials'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Fotografi'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Photography'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='fi'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Grafisk materiale'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Graphic materials'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Kunstreproduksjon'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Art reproduction'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='g'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Elektronisk ressurs'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Electronic resource'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format'"/><xsl:with-param name="value" select="'XHTML'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:type.text'"/><xsl:with-param name="value" select="'true'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='gb'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Elektronisk ressurs'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Electronic resource'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Diskett'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Floppy'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='gc'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Elektronisk ressurs'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Electronic resource'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'DVD-ROM'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'DVD'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='gd'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Elektronisk ressurs'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Electronic resource'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'CD-ROM'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'CD'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='ge'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Elektronisk ressurs'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Electronic resource'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Nettressurs'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Web resource'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format'"/><xsl:with-param name="value" select="'XHTML'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:type.text'"/><xsl:with-param name="value" select="'true'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='gf'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Elektronisk ressurs'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Electronic resource'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Lagringsbrikke'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Storage card'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='gg'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Elektronisk ressurs'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Electronic resource'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Blu-ray ROM'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Blu-ray'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='gh'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Elektronisk ressurs'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Electronic resource'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'UMD'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='gi'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Elektronisk ressurs'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Electronic resource'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Wii-plate'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Wii disk'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='gt'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Elektronisk ressurs'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Electronic resource'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format'"/><xsl:with-param name="value" select="'EPUB'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:type.text'"/><xsl:with-param name="value" select="'true'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('is-for-distribution')"/><xsl:with-param name="value" select="'false'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='h'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Tredimensjonal gjenstand'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Three-dimensional object'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='i'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Mikroform'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Microform'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='ib'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Mikroform'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Microform'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Mikrofilmspole'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Microfilm tape'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='ic'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Mikroform'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Microform'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Mikrofilmkort'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Microfilm card'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='j'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Periodika'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Serial'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('periodical')"/><xsl:with-param name="value" select="'true'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='jn'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Periodika'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Serial'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Avis'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Newspaper'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('periodical')"/><xsl:with-param name="value" select="'true'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('newspaper')"/><xsl:with-param name="value" select="'true'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='jp'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Periodika'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Serial'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Tidsskrift'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Magazine'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('periodical')"/><xsl:with-param name="value" select="'true'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('magazine')"/><xsl:with-param name="value" select="'true'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='k'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Artikler'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Article'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='l'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Fysiske bøker'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Physical book'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format'"/><xsl:with-param name="value" select="'Braille'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.no'"/><xsl:with-param name="value" select="'Punktskrift'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:type.braille'"/><xsl:with-param name="value" select="'true'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='m'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Dataspill'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Video game'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='ma'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Dataspill'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Video game'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'PC'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='mb'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Dataspill'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Video game'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Playstation 2'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='mc'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Dataspill'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Video game'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Playstation 3'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='md'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Dataspill'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Video game'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Playstation Portable'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='mi'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Dataspill'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Video game'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Xbox'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='mj'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Dataspill'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Video game'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Xbox 360'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='mn'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Dataspill'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Video game'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Nintendo DS'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='mo'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Dataspill'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Video game'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Nintendo Wii'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='dl'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'SACD'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'SACD'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='dm'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'DVD-audio'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'DVD-audio'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='dn'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Blu-Ray-audio'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Blu-Ray-audio'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='dz'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'MP3'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'MP3'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='ea'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'E-film'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'E-film'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='ga'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Nedlastbar fil'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Downloadable file'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='je'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'E-tidsskrifter'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'E-periodicals'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='ka'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'E-artikler'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'E-articles'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='la'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'E-bøker'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'E-books'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format'"/><xsl:with-param name="value" select="'XHTML'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:type.text'"/><xsl:with-param name="value" select="'true'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='me'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Playstation 4'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Playstation 4'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='mk'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Xbox One'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Xbox One'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='mp'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Nintendo Wii U'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Nintendo Wii U'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='n'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Filformater'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'File formats'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='na'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'PDF'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'PDF'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='nb'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'EPUB'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'EPUB'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='nc'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'MOBI'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'MOBI'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='nl'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'WMA (Windows Media Audio)'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'WMA (Windows Media Audio)'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='ns'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'WMV (Windows Media Video)'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'WMV (Windows Media Video)'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='o'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Digital rettighetsadministrasjon (DRM)'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Digital rights management (DRM)'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='te'">
                            <!-- non-standard -->
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format'"/><xsl:with-param name="value" select="'Braille'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.no'"/><xsl:with-param name="value" select="'Punktskrift'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:type.braille'"/><xsl:with-param name="value" select="'true'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='za'">
                            <!-- non-standard -->
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format'"/><xsl:with-param name="value" select="'Braille'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.no'"/><xsl:with-param name="value" select="'Punktskrift'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:type.braille'"/><xsl:with-param name="value" select="'true'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                    </xsl:choose>
                </xsl:for-each>
            </xsl:for-each>
        </xsl:variable>
        <xsl:copy-of select="$b" exclude-result-prefixes="#all"/>

        <xsl:if test="not($b[self::dc:format])">
            <xsl:for-each select="*:subfield[@code='e']">
                <xsl:variable name="context" select="."/>
                <xsl:for-each select="tokenize(replace(text(),'\s',''),'[,\.\-_]')">
                    <xsl:choose>
                        <xsl:when test=".='dc'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format'"/><xsl:with-param name="value" select="'DAISY 2.02'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:type.audio'"/><xsl:with-param name="value" select="'true'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='dj'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format'"/><xsl:with-param name="value" select="'DAISY 2.02'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:type.audio'"/><xsl:with-param name="value" select="'true'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='te'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format'"/><xsl:with-param name="value" select="'Braille'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.no'"/><xsl:with-param name="value" select="'Punktskrift'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:type.braille'"/><xsl:with-param name="value" select="'true'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='c'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other.no'"/><xsl:with-param name="value" select="'Musikktrykk'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.other'"/><xsl:with-param name="value" select="'Sheet music'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format'"/><xsl:with-param name="value" select="'Braille'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.no'"/><xsl:with-param name="value" select="'Punktskrift'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:type.braille'"/><xsl:with-param name="value" select="'true'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='l'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format'"/><xsl:with-param name="value" select="'Braille'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.no'"/><xsl:with-param name="value" select="'Punktskrift'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:type.braille'"/><xsl:with-param name="value" select="'true'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='gt'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format'"/><xsl:with-param name="value" select="'EPUB'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:type.text'"/><xsl:with-param name="value" select="'true'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('is-for-distribution')"/><xsl:with-param name="value" select="'false'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='ge'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format'"/><xsl:with-param name="value" select="'XHTML'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:type.text'"/><xsl:with-param name="value" select="'true'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='g'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format'"/><xsl:with-param name="value" select="'XHTML'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:type.text'"/><xsl:with-param name="value" select="'true'"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
                        </xsl:when>
                    </xsl:choose>
                </xsl:for-each>
            </xsl:for-each>
        </xsl:if>

        <xsl:for-each select="*:subfield[@code='d']">
            <xsl:variable name="context" select="."/>
                <xsl:for-each select="for $i in (1 to string-length(text())) return substring(text(),$i,1)">
                    <xsl:variable name="literary-form-id" select="concat('literary-form-019d-', position())"/>
                    <xsl:choose>
                        <xsl:when test=".='R'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:type.literaryForm'"/><xsl:with-param name="value" select="'Roman'"/><xsl:with-param name="context" select="$context"/><xsl:with-param name="id" select="$literary-form-id"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('marc-id')"/><xsl:with-param name="value" select="."/><xsl:with-param name="context" select="$context"/><xsl:with-param name="refines" select="$literary-form-id"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='N'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:type.literaryForm'"/><xsl:with-param name="value" select="'Novelle'"/><xsl:with-param name="context" select="$context"/><xsl:with-param name="id" select="$literary-form-id"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('marc-id')"/><xsl:with-param name="value" select="."/><xsl:with-param name="context" select="$context"/><xsl:with-param name="refines" select="$literary-form-id"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='D'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:type.literaryForm'"/><xsl:with-param name="value" select="'Dikt'"/><xsl:with-param name="context" select="$context"/><xsl:with-param name="id" select="$literary-form-id"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('marc-id')"/><xsl:with-param name="value" select="."/><xsl:with-param name="context" select="$context"/><xsl:with-param name="refines" select="$literary-form-id"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='S'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:type.literaryForm'"/><xsl:with-param name="value" select="'Skuespill'"/><xsl:with-param name="context" select="$context"/><xsl:with-param name="id" select="$literary-form-id"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('marc-id')"/><xsl:with-param name="value" select="."/><xsl:with-param name="context" select="$context"/><xsl:with-param name="refines" select="$literary-form-id"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='T'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:type.literaryForm'"/><xsl:with-param name="value" select="'Tegneserie'"/><xsl:with-param name="context" select="$context"/><xsl:with-param name="id" select="$literary-form-id"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('marc-id')"/><xsl:with-param name="value" select="."/><xsl:with-param name="context" select="$context"/><xsl:with-param name="refines" select="$literary-form-id"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='A'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:type.literaryForm'"/><xsl:with-param name="value" select="'Antologi'"/><xsl:with-param name="context" select="$context"/><xsl:with-param name="id" select="$literary-form-id"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('marc-id')"/><xsl:with-param name="value" select="."/><xsl:with-param name="context" select="$context"/><xsl:with-param name="refines" select="$literary-form-id"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='L'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:type.literaryForm'"/><xsl:with-param name="value" select="'Lærebok'"/><xsl:with-param name="context" select="$context"/><xsl:with-param name="id" select="$literary-form-id"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('marc-id')"/><xsl:with-param name="value" select="."/><xsl:with-param name="context" select="$context"/><xsl:with-param name="refines" select="$literary-form-id"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='P'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:type.literaryForm'"/><xsl:with-param name="value" select="'Pekebok'"/><xsl:with-param name="context" select="$context"/><xsl:with-param name="id" select="$literary-form-id"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('marc-id')"/><xsl:with-param name="value" select="."/><xsl:with-param name="context" select="$context"/><xsl:with-param name="refines" select="$literary-form-id"/></xsl:call-template>
                        </xsl:when>
                        <xsl:when test=".='B'">
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:type.literaryForm'"/><xsl:with-param name="value" select="'Billedbok'"/><xsl:with-param name="context" select="$context"/><xsl:with-param name="id" select="$literary-form-id"/></xsl:call-template>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('marc-id')"/><xsl:with-param name="value" select="."/><xsl:with-param name="context" select="$context"/><xsl:with-param name="refines" select="$literary-form-id"/></xsl:call-template>
                        </xsl:when>
                    </xsl:choose>
                </xsl:for-each>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="*:datafield[@tag='020']">
        <xsl:for-each select="*:subfield[@code='a']">
            <xsl:if test="not(text() = '0')">
                <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('isbn')"/><xsl:with-param name="value" select="text()"/></xsl:call-template>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="*:datafield[@tag='022']">
        <xsl:for-each select="*:subfield[@code='a']">
            <xsl:if test="not(text() = '0')">
                <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('issn')"/><xsl:with-param name="value" select="text()"/></xsl:call-template>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="*:datafield[@tag='041']">
        <xsl:for-each select="*:subfield[@code='a']">
            <xsl:variable name="text" select="replace(text(), '[, ]', '')"/>
            <xsl:variable name="context" select="."/>
            <xsl:for-each select="(1 to xs:integer(floor(string-length($text) div 3)))">
                <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:language'"/><xsl:with-param name="value" select="substring($text,1+(.-1)*3,3)"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
            </xsl:for-each>
        </xsl:for-each>
        <xsl:for-each select="*:subfield[@code='h']">
            <xsl:variable name="has-following-041h" select="exists(following-sibling::*:subfield[@code='h'])"/>
            <xsl:variable name="text" select="replace(text(), '[, ]', '')"/>
            <xsl:variable name="context" select="."/>
            <xsl:for-each select="(1 to xs:integer(floor(string-length($text) div 3)))">
                <xsl:call-template name="meta"><xsl:with-param name="property" select="concat('dc:language.original',if (position() lt last() or $has-following-041h) then '.intermediary' else '','')"/><xsl:with-param name="value" select="substring($text,1+(.-1)*3,3)"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
            </xsl:for-each>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="*:datafield[@tag='048']">
        <xsl:for-each select="*:subfield[@code='a']">
            <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('instrument')"/><xsl:with-param name="value" select="text()"/></xsl:call-template>
        </xsl:for-each>
    </xsl:template>

    <!-- 050 - 099 KLASSIFIKASJONSKODER -->
    
    <xsl:template match="*:datafield[@tag='082']">
        <xsl:if test="not(preceding-sibling::*:datafield[@tag='082'])">
            <xsl:for-each select="../*:datafield[@tag='082' and not(*:subfield[@code='z']/text() = 'b')]/*:subfield[@code='a']">
                <xsl:sort select="text()"/>
                <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:subject.dewey'"/><xsl:with-param name="value" select="text()"/></xsl:call-template>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>

    <xsl:template match="*:datafield[matches(@tag,'09\d')]">
        <!--<xsl:message select="'NORMARC-felt ignorert: 09X LOKALT FELT'"/>-->
    </xsl:template>

    <!-- 1XX HOVEDORDNINGSORD -->

    <xsl:template match="*:datafield[@tag='100']">
        <xsl:variable name="creator-id" select="concat('creator-',1+count(preceding-sibling::*:datafield[@tag='100' or @tag='110' or @tag='111']))"/>
        <xsl:variable name="name" select="(*:subfield[@code='a'], *:subfield[@code='q'], *:subfield[@code='w'])[normalize-space(.)][1]/text()"/>
        <xsl:variable name="sortingKey" select="(*:subfield[@code='w'][normalize-space(.)])[1]"/>
        
        <!-- strip and normalize space -->
        <xsl:variable name="name" select="replace(normalize-space($name), '(^ +| +$)', '')"/>
        <xsl:variable name="sortingKey" select="replace(normalize-space($sortingKey), '(^ +| +$)', '')"/>

        <xsl:if test="$name">
            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:creator'"/><xsl:with-param name="value" select="$name"/><xsl:with-param name="id" select="$creator-id"/></xsl:call-template>

            <xsl:for-each select="*:subfield[@code='b']">
                <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('honorificSuffix')"/><xsl:with-param name="value" select="text()"/><xsl:with-param name="refines" select="$creator-id"/></xsl:call-template>
            </xsl:for-each>

            <xsl:for-each select="*:subfield[@code='c']">
                <xsl:choose>
                    <xsl:when test="matches(text(), $PSEUDONYM)">
                        <xsl:variable name="pseudonym" select="replace(text(), $PSEUDONYM_REPLACE, '$1')"/>
                        <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('pseudonym')"/><xsl:with-param name="value" select="$pseudonym"/><xsl:with-param name="refines" select="$creator-id"/></xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('honorificPrefix')"/><xsl:with-param name="value" select="text()"/><xsl:with-param name="refines" select="$creator-id"/></xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
            
            <xsl:if test="$sortingKey">
                <xsl:for-each select="(*:subfield[@code='w'])[1]">
                    <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('sortingKey')"/><xsl:with-param name="value" select="$sortingKey"/><xsl:with-param name="refines" select="$creator-id"/></xsl:call-template>
                </xsl:for-each>
            </xsl:if>

            <xsl:for-each select="*:subfield[@code='d']">
                <xsl:variable name="birthDeath" select="tokenize(nlb:parseBirthDeath(text()), ',')"/>
                <xsl:if test="$birthDeath[1]">
                    <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('birthDate')"/><xsl:with-param name="value" select="$birthDeath[1]"/><xsl:with-param name="refines" select="$creator-id"/></xsl:call-template>
                </xsl:if>
                <xsl:if test="$birthDeath[2]">
                    <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('deathDate')"/><xsl:with-param name="value" select="$birthDeath[2]"/><xsl:with-param name="refines" select="$creator-id"/></xsl:call-template>
                </xsl:if>
            </xsl:for-each>
            
            <xsl:call-template name="nationality">
                <xsl:with-param name="refines" select="$creator-id"/>
            </xsl:call-template>
            
            <xsl:call-template name="bibliofil-id">
                <xsl:with-param name="context" select="."/>
                <xsl:with-param name="refines" select="$creator-id"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="*:datafield[@tag='110']">
        <xsl:variable name="creator-id" select="concat('creator-',1+count(preceding-sibling::*:datafield[@tag='100' or @tag='110' or @tag='111']))"/>
        <xsl:variable name="sortingKey" select="(*:subfield[@code='w'][normalize-space(.)])[1]"/>
        
        <xsl:choose>
            <xsl:when test="*:subfield[@code='a']">
                <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:creator'"/><xsl:with-param name="value" select="*:subfield[@code='a']/text()"/><xsl:with-param name="id" select="$creator-id"/></xsl:call-template>
                <xsl:if test="*:subfield[@code='b']">
                    <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('department')"/><xsl:with-param name="value" select="*:subfield[@code='b'][1]/text()"/><xsl:with-param name="refines" select="$creator-id"/></xsl:call-template>
                </xsl:if>
            </xsl:when>
            <xsl:when test="*:subfield[@code='b']">
                <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:creator'"/><xsl:with-param name="value" select="*:subfield[@code='b'][1]/text()"/><xsl:with-param name="id" select="$creator-id"/></xsl:call-template>
            </xsl:when>
        </xsl:choose>
        
        <xsl:if test="$sortingKey">
            <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('sortingKey')"/><xsl:with-param name="value" select="$sortingKey"/><xsl:with-param name="refines" select="$creator-id"/></xsl:call-template>                
        </xsl:if>
        
        <xsl:for-each select="*:subfield[@code='c']">
            <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('location')"/><xsl:with-param name="value" select="."/><xsl:with-param name="refines" select="$creator-id"/></xsl:call-template>
        </xsl:for-each>
        
        <xsl:for-each select="*:subfield[@code='d']">
            <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('date')"/><xsl:with-param name="value" select="."/><xsl:with-param name="refines" select="$creator-id"/></xsl:call-template>
        </xsl:for-each>

        <xsl:call-template name="bibliofil-id">
            <xsl:with-param name="context" select="."/>
            <xsl:with-param name="refines" select="$creator-id"/>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template match="*:datafield[@tag='111']">
        <xsl:variable name="creator-id" select="concat('creator-',1+count(preceding-sibling::*:datafield[@tag='100' or @tag='110' or @tag='111']))"/>
        <xsl:variable name="sortingKey" select="(*:subfield[@code='w'][normalize-space(.)])[1]"/>
        
        <xsl:for-each select="*:subfield[@code='a']">
            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:creator'"/><xsl:with-param name="value" select="."/><xsl:with-param name="id" select="$creator-id"/></xsl:call-template>
        </xsl:for-each>
        
        <xsl:if test="$sortingKey">
            <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('sortingKey')"/><xsl:with-param name="value" select="$sortingKey"/><xsl:with-param name="refines" select="$creator-id"/></xsl:call-template>                
        </xsl:if>
        
        <xsl:for-each select="*:subfield[@code='c']">
            <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('location')"/><xsl:with-param name="value" select="."/><xsl:with-param name="refines" select="$creator-id"/></xsl:call-template>
        </xsl:for-each>
        
        <xsl:for-each select="*:subfield[@code='d']">
            <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('date')"/><xsl:with-param name="value" select="."/><xsl:with-param name="refines" select="$creator-id"/></xsl:call-template>
        </xsl:for-each>
        
        <xsl:call-template name="bibliofil-id">
            <xsl:with-param name="context" select="."/>
            <xsl:with-param name="refines" select="$creator-id"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="*:datafield[@tag='130']">
        <xsl:for-each select="*:subfield[@code='a']">
            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:title.alternative'"/><xsl:with-param name="value" select="text()"/></xsl:call-template>
        </xsl:for-each>
    </xsl:template>

    <!-- 2XX TITTEL-, ANSVARS- OG UTGIVELSESOPPLYSNINGER -->

    <xsl:template match="*:datafield[@tag='240']">
        <xsl:for-each select="*:subfield[@code='a']">
            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:title.alternative'"/><xsl:with-param name="value" select="text()"/></xsl:call-template>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="*:datafield[@tag='245']">
        <xsl:variable name="language">
            <xsl:apply-templates select="../*[@tag = ('008', '041')]"/>
        </xsl:variable>
        <xsl:variable name="language" select="string(($language/dc:language[not(@refines)])[1])"/>
        
        <xsl:if test="count(*:subfield[@code='a'])">
            <xsl:variable name="title" select="*:subfield[@code='a'][1]/normalize-space(replace(text(), '[\s&#160;]', ' '))" as="xs:string"/>
            <xsl:variable name="title" select="replace(normalize-space($title), '^\[\s*(.*?)\s*\]$', '$1')"/>
            <xsl:variable name="title" select="replace($title, ' *= *$', '')"/>  <!-- remove trailing parallel title marker if present -->
            <xsl:variable name="parallel-title" select="if (contains($title, '=')) then replace($title, '^.*= *', '') else ''" as="xs:string"/>
            <xsl:variable name="title-without-parallel-title" select="if (contains($title, '=')) then replace($title, ' *=.*$', '') else $title" as="xs:string"/>
            <xsl:variable name="title-without-subtitle" select="replace($title-without-parallel-title, '^([^;:]*[^;: ]).*', '$1')"/>
            <xsl:variable name="title-without-subtitle" select="nlb:identifier-in-title($title-without-subtitle, $language, false())"/>
            <xsl:for-each select="*:subfield[@code='a']">
                <xsl:call-template name="meta">
                    <xsl:with-param name="property" select="'dc:title'"/>
                    <xsl:with-param name="context" select="."/>
                    <xsl:with-param name="value" select="$title-without-subtitle"/>
                </xsl:call-template>
                
                <xsl:if test="string-length($parallel-title) gt 0">
                    <xsl:call-template name="meta">
                        <xsl:with-param name="property" select="'dc:title.parallel'"/>
                        <xsl:with-param name="context" select="."/>
                        <xsl:with-param name="value" select="$parallel-title"/>
                    </xsl:call-template>
                </xsl:if>
            </xsl:for-each>
            
            <xsl:variable name="subtitle" as="element()*">
                <xsl:for-each select="*:subfield[@code='a']">
                    <xsl:variable name="subtitle" select="if (matches($title, '.*[;:].*')) then replace($title, '^[^;:]*[;:] *', '') else ()"/>
                    <xsl:variable name="subtitle" select="replace($subtitle, ';', ':')"/>
                    <xsl:if test="$subtitle">
                        <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:title.subTitle'"/><xsl:with-param name="value" select="$subtitle"/></xsl:call-template>
                    </xsl:if>
                </xsl:for-each>
                <xsl:for-each select="*:subfield[@code='b']">
                    <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:title.subTitle'"/><xsl:with-param name="value" select="replace(text(),'[\[\]]','')"/></xsl:call-template>
                </xsl:for-each>
            </xsl:variable>
            <xsl:choose>
                <xsl:when test="count($subtitle) = 1">
                    <xsl:copy-of select="$subtitle"/>
                </xsl:when>
                <xsl:when test="count($subtitle) gt 1">
                    <xsl:variable name="subtitle_context" select="(*:subfield[@code='b'], *:subfield[@code='a'])[1]"/>
                    <xsl:call-template name="meta">
                        <xsl:with-param name="property" select="'dc:title.subTitle'"/>
                        <xsl:with-param name="value" select="string-join($subtitle, ' : ')"/>
                        <xsl:with-param name="context" select="$subtitle_context"/>
                    </xsl:call-template>
                </xsl:when>
            </xsl:choose>
            
            <xsl:variable name="part740" as="element()*">
                <xsl:apply-templates select="../*:datafield[@tag='740']"/>
            </xsl:variable>
            
            <xsl:for-each select="(*:subfield[@code='p'])[1]">
                <xsl:call-template name="meta">
                    <xsl:with-param name="property" select="'dc:title.part'"/>
                    <xsl:with-param name="value" select="text()"/>
                </xsl:call-template>
            </xsl:for-each>
            
            <xsl:for-each select="(*:subfield[@code='n'])[1]">
                <!--
                    - if there's no part number in *740, then use this as the part number (nlbbib:position)
                    - if there's a part number in *740, then use this as an alternative part number (nlbbib:position.other)
                -->
                <xsl:call-template name="meta">
                    <xsl:with-param name="property" select="nlb:prefixed-property('positionStatement')"/>
                    <xsl:with-param name="value" select="text()"/>
                </xsl:call-template>
                
                <xsl:variable name="position" select="replace(text(),'^.*?(\d+).*$','$1')"/>
                <xsl:if test="matches($position, '^\d+$')">
                    <xsl:call-template name="meta">
                        <xsl:with-param name="property" select="concat(nlb:prefixed-property('position'), if (exists($part740[@property = nlb:prefixed-property('position')])) then '.other' else '')"/>
                        <xsl:with-param name="value" select="$position"/>
                    </xsl:call-template>
                </xsl:if>
            </xsl:for-each>
    
            <xsl:for-each select="(*:subfield[@code='c'])[1]">
                <xsl:call-template name="meta"><xsl:with-param name="property" select="'nlbbib:responsibilityStatement'"/><xsl:with-param name="value" select="text()"/></xsl:call-template>
            </xsl:for-each>
    
            <!-- *245 finnes alltid, men ikke alltid *250. Opprett bookEdition herifra dersom *250 ikke definerer bookEdition. -->
            <xsl:if test="count(../*:datafield[@tag='250']/*:subfield[@code='a']) = 0">
                <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('bookEdition')"/><xsl:with-param name="value" select="'1'"/></xsl:call-template>
            </xsl:if>
            
            <!-- The main sorting key for this record -->
            <xsl:variable name="sortingKey_context" select="(
                ../*:datafield[@tag='100' or @tag='110' or @tag='111' or @tag='130']/*:subfield[@code='w'],
                ../*:datafield[@tag='100' or @tag='110' or @tag='111' or @tag='130']/*:subfield[@code='a'],
                *:subfield[@code='w'],
                *:subfield[@code='a']
            )[1]"/>
            <xsl:variable name="sortingKey" select="if ($sortingKey_context[../@tag = '245' and @code = 'a']) then $title-without-subtitle else replace(nlb:identifier-in-title(replace($sortingKey_context/text(),'[\[\]]',''), $language, true()), '(^ +| +$)', '')"/>
            <xsl:if test="$sortingKey_context">
                <xsl:call-template name="meta">
                    <xsl:with-param name="property" select="nlb:prefixed-property('sortingKey')"/>
                    <xsl:with-param name="value" select="$sortingKey"/>
                    <xsl:with-param name="context" select="$sortingKey_context"/>
                </xsl:call-template>
            </xsl:if>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="*:datafield[@tag='246']">
        <xsl:if test="not(preceding-sibling::*:datafield[@tag='246'])">
            <xsl:for-each select="../*:datafield[@tag='246']">
                <xsl:sort select="*:subfield[@code='a'][1]/text()"/>
                
                <xsl:variable name="type" select="if (*:subfield[@code='i' and text()='Originaltittel']) then 'original' else if (@ind2 = '1') then 'parallel' else 'alternative'" as="xs:string"/>
                
                <xsl:for-each select="*:subfield[@code='a']">
                    <xsl:call-template name="meta"><xsl:with-param name="property" select="concat('dc:title.', $type)"/><xsl:with-param name="value" select="replace(text(), ' *[:.]$', '')"/></xsl:call-template>
                </xsl:for-each>
                
                <xsl:for-each select="*:subfield[@code='b']">
                    <xsl:call-template name="meta"><xsl:with-param name="property" select="concat('dc:title.subTitle.', $type, '.other')"/><xsl:with-param name="value" select="text()"/></xsl:call-template>
                </xsl:for-each>
                
                <xsl:for-each select="*:subfield[@code='n']">
                    <xsl:variable name="position" select="replace(text(),'^.*?(\d+).*$','$1')"/>
                    <xsl:if test="matches($position, '^\d+$')">
                        <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('position')"/><xsl:with-param name="value" select="$position"/></xsl:call-template>
                    </xsl:if>
                </xsl:for-each>
                
                <xsl:for-each select="*:subfield[@code='p']">
                    <xsl:call-template name="meta"><xsl:with-param name="property" select="concat('dc:title.subTitle.', $type)"/><xsl:with-param name="value" select="text()"/></xsl:call-template>
                </xsl:for-each>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>

    <xsl:template match="*:datafield[@tag='250']">
        <xsl:for-each select="*:subfield[@code='a']">
            <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('bookEdition')"/><xsl:with-param name="value" select="text()"/></xsl:call-template>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="*:datafield[@tag='260']">
        <xsl:variable name="publisher-id" select="concat('publisher-260-',1+count(preceding-sibling::*:datafield[@tag='260']))"/>
        <xsl:variable name="issued" select="(*:subfield[@code='c' and nlb:parseYear(text(), false())])[1]/nlb:parseYear(text(), false())" as="xs:string?"/>
        <xsl:variable name="first-issued" select="min(../*:datafield[@tag='260']/*:subfield[@code='c']/nlb:parseYear(text(), false()))" as="xs:string?"/>
        <xsl:variable name="first-publisher" select="if ($first-issued) then (../*:datafield[@tag='260' and *:subfield[@code='c']/nlb:parseYear(text(), false()) = $first-issued])[1] else (../*:datafield[@tag='260'])[1]"/>
        <xsl:variable name="primary" select=". intersect $first-publisher"/>
        
        <xsl:if test="*:subfield[@code='b']">
            <xsl:call-template name="meta">
                <xsl:with-param name="property" select="if ($primary) then 'dc:publisher' else 'dc:publisher.other'"/>
                <xsl:with-param name="value" select="(*:subfield[@code='b'])[1]/text()"/>
                <xsl:with-param name="id" select="$publisher-id"/>
                <xsl:with-param name="context" select="(*:subfield[@code='b'])[1]"/>
            </xsl:call-template>
            
            <xsl:call-template name="bibliofil-id">
                <xsl:with-param name="context" select="."/>
                <xsl:with-param name="refines" select="$publisher-id"/>
            </xsl:call-template>
        </xsl:if>
        
        <xsl:for-each select="*:subfield[@code='a']">
            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:publisher.location'"/><xsl:with-param name="value" select="replace(text(),'[\[\]]','')"/><xsl:with-param name="refines" select="if ($primary) then () else $publisher-id"/></xsl:call-template>
        </xsl:for-each>
        <xsl:if test="$issued">
            <xsl:for-each select="*:subfield[@code='c']">
                <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:date.issued'"/><xsl:with-param name="value" select="string($issued)"/><xsl:with-param name="refines" select="if ($primary) then () else $publisher-id"/></xsl:call-template>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>

    <!-- 3XX FYSISK BESKRIVELSE -->

    <xsl:template match="*:datafield[@tag='300']">
        <xsl:variable name="fields" as="element()*">
            <xsl:apply-templates select="../*:datafield[@tag='245']"/>
        </xsl:variable>
        <xsl:variable name="fields" as="element()*">
            <xsl:choose>
                <xsl:when test="$fields[self::dc:format]">
                    <xsl:copy-of select="$fields" exclude-result-prefixes="#all"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="../*:datafield[@tag='019']"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:for-each select="*:subfield[@code='a']">
            <xsl:variable name="extent" select="lower-case(replace(text(),'[\[\]]',''))"/>
            <xsl:variable name="numberOfPages" select="(if (matches($extent,'^.*?(\d+)\s*s.*$')) then replace($extent,'^.*?(\d+)\s*s.*$','$1') else ())[1]"/>
            <xsl:variable name="numberOfVolumes" select="(if (matches($extent,'^.*?(\d+)\s*(heft|b).*$')) then replace($extent,'^.*?(\d+)\s*(heft|b).*$','$1') else ())[1]"/>
            
            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.extent'"/><xsl:with-param name="value" select="text()"/></xsl:call-template>

            <xsl:choose>
                <xsl:when test="matches(text(),'^.*?\d+ *t+\.? *\d+ *min\.?.*?$')">
                    <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.extent.duration'"/><xsl:with-param name="value" select="replace(text(),'^.*?(\d+) *t+\.? *(\d+) *min\.?.*?$','$1 t. $2 min.')"/></xsl:call-template>
                </xsl:when>
                <xsl:when test="matches(text(),'^.*?\d+ *min\.?.*?$')">
                    <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.extent.duration'"/><xsl:with-param name="value" select="replace(text(),'^.*?(\d+) *min\.?.*?$','0 t. $1 min.')"/></xsl:call-template>
                </xsl:when>
                <xsl:when test="matches(text(),'^.*?\d+ *t\.?.*?$')">
                    <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.extent.duration'"/><xsl:with-param name="value" select="replace(text(),'^.*?(\d+) *t\.?.*?$','$1 t. 0 min.')"/></xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:if test="$numberOfPages">
                        <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.extent.pages'"/><xsl:with-param name="value" select="$numberOfPages"/></xsl:call-template>
                    </xsl:if>
                    <xsl:if test="$numberOfVolumes">
                        <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.extent.volumes'"/><xsl:with-param name="value" select="$numberOfVolumes"/></xsl:call-template>
                    </xsl:if>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
        <xsl:for-each select="*:subfield[@code='b']">
            <xsl:if test="tokenize(replace(text(),'\s',''),'[,\.\-_]') = 'o'">
                <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('drm')"/><xsl:with-param name="value" select="'true'"/></xsl:call-template>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="*:datafield[@tag='310']">
        <xsl:for-each select="*:subfield[@code='a']">
            <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('periodicity')"/><xsl:with-param name="value" select="text()"/></xsl:call-template>
        </xsl:for-each>
    </xsl:template>

    <!-- 4XX SERIEANGIVELSER -->
    
    <xsl:template match="*:datafield[@tag='449']">
        <xsl:for-each select="*:subfield[@code='n']">
            <xsl:if test="matches(text(),'\d')">
                <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.extent.cd'"/><xsl:with-param name="value" select="replace(text(),'^[^\d]*(\d+).*?$','$1')"/></xsl:call-template>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:function name="nlb:serialized-series" as="xs:string">
        <xsl:param name="datafield-490-or-830" as="element()"/>
        <xsl:variable name="a" select="string-join($datafield-490-or-830/*:subfield[@code='a']/replace(upper-case(normalize-space(text())), '\(([^)]*)\)', '/$1'), '.')" as="xs:string"/>
        <xsl:variable name="p" select="string-join($datafield-490-or-830/*:subfield[@code='p']/upper-case(normalize-space(text())),'.')" as="xs:string"/>
        <xsl:variable name="ap">
            <xsl:choose>
                <xsl:when test="$p = ''">
                    <xsl:value-of select="$a"/>
                </xsl:when>
                <xsl:when test="contains($a, '/')">
                    <xsl:value-of select="concat(tokenize($a, '/')[1], '.', $p, '/', string-join(tokenize($a, '/')[position() gt 1], '/'))"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat($a, '.', $p)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="values" select="$datafield-490-or-830/*:subfield[not(@code=('a','n','p','v','_'))]" as="element()*"/>
        <xsl:variable name="values" select="($ap, $values/upper-case(normalize-space(text())))" as="xs:string*"/>
        <xsl:value-of select="string-join($values, '.')"/>
    </xsl:function>

    <xsl:template match="*:datafield[@tag='490'] | *:datafield[@tag='830']">
        <xsl:choose>
            <xsl:when test="exists(preceding-sibling::*:datafield[@tag=('490','830')])">
                <!-- skip this one, we process all series on the first match -->
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="series" select="../*:datafield[@tag=('490','830')]" as="element()*"/>
                <xsl:variable name="series-with-ids" select="$series[exists(*:subfield[@code='_'])]" as="element()*"/>
                <xsl:variable name="series-without-ids" select="$series except $series-with-ids" as="element()*"/>
                
                <!-- sort by number of subfields -->
                <xsl:variable name="series" as="element()*">
                    <xsl:for-each select="$series">
                        <xsl:sort select="count(*)"/>
                        <xsl:sequence select="."/>
                    </xsl:for-each>
                </xsl:variable>
                <xsl:variable name="series" select="reverse($series)" as="element()*"/>
                
                <!-- for duplicate series, prefer the one that has an ID -->
                <xsl:variable name="series-unique" as="element()*">
                    <xsl:for-each select="$series">
                        <!-- if the series exists both with and without an ID, and this instance is one without an ID, then discard it -->
                        <xsl:if test="not(nlb:serialized-series(.) = $series-without-ids/nlb:serialized-series(.) and nlb:serialized-series(.) = $series-with-ids/nlb:serialized-series(.) and not(exists(*:subfield[@code='_'])))">
                            <xsl:sequence select="."/>
                        </xsl:if>
                    </xsl:for-each>
                </xsl:variable>
                
                <!-- ignore duplicate series -->
                <xsl:variable name="series-unique" as="element()*">
                    <xsl:for-each select="$series-unique">
                        <xsl:variable name="position" select="position()"/>
                        <!-- if the series is not a duplicate of one of the preceding series -->
                        <xsl:if test="not(nlb:serialized-series(.) = $series-unique[position() lt $position]/nlb:serialized-series(.))">
                            <xsl:sequence select="."/>
                        </xsl:if>
                    </xsl:for-each>
                </xsl:variable>
                
                <!-- sort by serialized value -->
                <xsl:message select="'sort by serialized value'"/>
                <xsl:variable name="series-unique" as="element()*">
                    <xsl:for-each select="$series-unique">
                        <xsl:sort select="nlb:serialized-series(.)"/>
                        <xsl:sequence select="."/>
                    </xsl:for-each>
                </xsl:variable>
                <xsl:message select="$series-unique"/>
                
                <xsl:for-each select="$series-unique">
                    <xsl:variable name="position" select="position()"/>
                    <xsl:variable name="title-id" select="concat('series-title-', position())"/>
                    
                    <xsl:variable name="series-title" as="element()?">
                        <xsl:for-each select="(*:subfield[@code='a'])[1]">
                            <xsl:call-template name="meta">
                                <xsl:with-param name="property" select="'dc:title.series'"/>
                                <xsl:with-param name="value" select="replace(replace(text(), ' *; *.*', ''), '\((.*)\)', '/$1')"/>
                                <xsl:with-param name="id" select="$title-id"/>
                            </xsl:call-template>
                        </xsl:for-each>
                    </xsl:variable>
                    <xsl:copy-of select="$series-title" exclude-result-prefixes="#all"/>
                    <xsl:variable name="series-id" as="element()?">
                        <xsl:if test="$series-title">
                            <xsl:for-each select="..">
                                <xsl:call-template name="bibliofil-id">
                                    <xsl:with-param name="context" select="."/>
                                    <xsl:with-param name="refines" select="$title-id"/>
                                </xsl:call-template>
                            </xsl:for-each>
                        </xsl:if>
                    </xsl:variable>
                    <xsl:copy-of select="$series-id" exclude-result-prefixes="#all"/>
                    <xsl:if test="$series-title">
                        <xsl:for-each select="*:subfield[@code='p']">
                            <xsl:call-template name="meta">
                                <xsl:with-param name="property" select="'dc:title.subSeries'"/>
                                <xsl:with-param name="value" select="text()"/>
                                <xsl:with-param name="refines" select="$title-id"/>
                            </xsl:call-template>
                        </xsl:for-each>
                        <xsl:for-each select="*:subfield[@code='x']">
                            <xsl:if test="not(text() = '0')">
                                <xsl:call-template name="meta">
                                    <xsl:with-param name="property" select="nlb:prefixed-property('series.issn')"/>
                                    <xsl:with-param name="value" select="text()"/>
                                    <xsl:with-param name="refines" select="$title-id"/>
                                </xsl:call-template>
                            </xsl:if>
                        </xsl:for-each>
                        <xsl:for-each select="*:subfield[@code='v']">
                            <xsl:if test="not(starts-with(text(), '['))">
                                <xsl:call-template name="meta">
                                    <xsl:with-param name="property" select="nlb:prefixed-property('series.position')"/>
                                    <xsl:with-param name="value" select="text()"/>
                                    <xsl:with-param name="refines" select="$title-id"/>
                                </xsl:call-template>
                            </xsl:if>
                        </xsl:for-each>
                        <xsl:for-each select="*:subfield[@code='a']">
                            <xsl:variable name="positions" select="text()/tokenize(., ';')[position() gt 1]"/>
                            <xsl:variable name="positions" select="for $position in ($positions) return normalize-space($position)"/>
                            <xsl:variable name="positions" select="for $position in ($positions) return if (starts-with(text(), '[')) then () else $position"/>
                            <xsl:variable name="context" select="."/>
                            <xsl:for-each select="$positions">
                                <xsl:call-template name="meta">
                                    <xsl:with-param name="property" select="nlb:prefixed-property('series.position')"/>
                                    <xsl:with-param name="value" select="."/>
                                    <xsl:with-param name="refines" select="$title-id"/>
                                    <xsl:with-param name="context" select="$context"/>
                                </xsl:call-template>
                            </xsl:for-each>
                        </xsl:for-each>
                    </xsl:if>
                    
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- 5XX NOTER -->
    
    <xsl:template match="*:datafield[@tag='500']">
        <!--<xsl:message select="'MARC21 field ignored: 500'"/>-->
    </xsl:template>

    <xsl:template match="*:datafield[@tag='501']">
        <!--<xsl:message select="'MARC21 field ignored: 501'"/>-->
    </xsl:template>
    
    <xsl:template match="*:datafield[@tag='503']">
        <!--<xsl:message select="'MARC21 field ignored: 503'"/>-->
    </xsl:template>

    <xsl:template match="*:datafield[@tag='505']">
        <xsl:for-each select="*:subfield[@code='a']">
            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:description.content'"/><xsl:with-param name="value" select="text()"/></xsl:call-template>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="*:datafield[@tag='511']">
        <xsl:variable name="contributor-id" select="concat('contributor-511-',1+count(preceding-sibling::*:datafield[@tag='511']))"/>
        <xsl:for-each select="*:subfield[@code='a']">
            <xsl:variable name="contributor-name" select="text()"/>
            
            <xsl:if test="$contributor-name != ('NLB', 'Tibi')">
                <xsl:call-template name="meta">
                    <xsl:with-param name="property" select="'dc:contributor.narrator'"/>
                    <xsl:with-param name="value" select="$contributor-name"/>
                    <xsl:with-param name="id" select="$contributor-id"/>
                </xsl:call-template>
                
                <xsl:for-each select="..">
                    <xsl:call-template name="bibliofil-id">
                        <xsl:with-param name="context" select="."/>
                        <xsl:with-param name="refines" select="$contributor-id"/>
                    </xsl:call-template>
                </xsl:for-each>
                
                <xsl:call-template name="nationality">
                    <xsl:with-param name="refines" select="$contributor-id"/>
                </xsl:call-template>
                
                <xsl:if test="contains(lower-case($contributor-name), 'talesyntese')">
                    <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:type.audio'"/><xsl:with-param name="value" select="'true'"/></xsl:call-template>
                    <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:type.text'"/><xsl:with-param name="value" select="'true'"/></xsl:call-template>
                    <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:type.tts'"/><xsl:with-param name="value" select="'true'"/></xsl:call-template>
                </xsl:if>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="*:datafield[@tag='520']">
        <xsl:for-each select="*:subfield[@code='a']">
            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:description.abstract'"/><xsl:with-param name="value" select="normalize-space(text())"/></xsl:call-template>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="*:datafield[@tag='522']">
        <!-- Ignoreres. Dette er noe som ble brukt "i riktig gamle dager". -->
    </xsl:template>

    <xsl:template match="*:datafield[@tag='523']">
        <!-- Ignoreres. Dette er noe som ble brukt "i riktig gamle dager". -->
    </xsl:template>

    <xsl:template match="*:datafield[@tag='533']">
        <!--<xsl:message select="'NORMARC-felt ignorert: 533 FYSISK BESKRIVELSE'"/>-->
    </xsl:template>

    <xsl:template match="*:datafield[@tag='537']">
        <!-- Duplikat av 505. Ignoreres. -->
    </xsl:template>

    <xsl:template match="*:datafield[@tag='539']">
        <!--<xsl:message select="'NORMARC-felt ignorert: 539 SERIER'"/>-->
    </xsl:template>

    <xsl:template match="*:datafield[@tag='574']">
        <xsl:variable name="property" select="if (../*:datafield[@tag='246' and *:subfield[@code='i' and text()='Originaltittel']]) then 'dc:title.original.alternative' else 'dc:title.original'"/>
        <xsl:for-each select="*:subfield[@code='a']">
            <xsl:call-template name="meta"><xsl:with-param name="property" select="$property"/><xsl:with-param name="value" select="replace(text(),'^\s*Ori?ginal(ens )?tit\w*\s*:?\s*','')"/></xsl:call-template>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template match="*:datafield[@tag='582']">
        <xsl:if test="not(preceding-sibling::*:datafield[@tag='582'])">
            <xsl:for-each select="../*:datafield[@tag='582' and count(*:subfield[@code='p']) = 1 and *:subfield[@code='p']/matches(text(), '\d+')]">
                <xsl:sort select="*:subfield[@code='p']"/>
                
                <xsl:variable name="deliveryFormat-id" select="concat('deliveryFormat-582-', position())"/>
                <xsl:variable name="identifier" select="string-join((*:subfield[@code='d'][1]/text(), *:subfield[@code='a'][1]/text()), '_')"/>
                
                <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('hasDeliveryMethod')"/><xsl:with-param name="value" select="$identifier"/><xsl:with-param name="id" select="$deliveryFormat-id"/></xsl:call-template>
                
                <xsl:for-each select="*:subfield[@code='d'][1]">
                    <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format'"/><xsl:with-param name="value" select="text()"/><xsl:with-param name="refines" select="$deliveryFormat-id"/></xsl:call-template>
                </xsl:for-each>
                
                <xsl:for-each select="*:subfield[@code='a'][1]">
                    <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('deliveryMethod')"/><xsl:with-param name="value" select="substring(text(), 1, 2)"/><xsl:with-param name="refines" select="$deliveryFormat-id"/></xsl:call-template>
                </xsl:for-each>
                
                <xsl:for-each select="*:subfield[@code='f'][1]">
                    <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('name')"/><xsl:with-param name="value" select="text()"/><xsl:with-param name="refines" select="$deliveryFormat-id"/></xsl:call-template>
                </xsl:for-each>
                
                <xsl:for-each select="*:subfield[@code='p'][1]">
                    <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('position')"/><xsl:with-param name="value" select="text()"/><xsl:with-param name="refines" select="$deliveryFormat-id"/></xsl:call-template>
                </xsl:for-each>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>

    <xsl:template match="*:datafield[@tag='590']">
        <!--<xsl:message select="'NORMARC-felt ignorert: 590 LOKALE NOTER'"/>-->
    </xsl:template>

    <xsl:template match="*:datafield[@tag='591']">
        <xsl:for-each select="*:subfield[@code='a']">
            <xsl:variable name="ordered" select="nlb:parseDate(text())"/>
            <xsl:if test="$ordered">
                <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:date.ordered'"/><xsl:with-param name="value" select="$ordered"/></xsl:call-template>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="*:datafield[@tag='592']">
        <xsl:for-each select="*:subfield[@code='a']">
            <xsl:variable name="available" select="nlb:parseDate(text())"/>
            <xsl:if test="$available">
                <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:date.available'"/><xsl:with-param name="value" select="$available"/></xsl:call-template>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="*:datafield[@tag='593']">
        <!--<xsl:message select="'NORMARC-felt ignorert: 593 LOKALE NOTER'"/>-->
    </xsl:template>

    <xsl:template match="*:datafield[@tag='594']">
        <!-- Karakteristikk -->
        <xsl:for-each select="*:subfield[@code='a']">
            <xsl:choose>
                <xsl:when test="text() = 'Åpen linjeavstand' or text() = 'Dobbel linjeavstand'">
                    <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.linespacing'"/><xsl:with-param name="value" select="'double'"/></xsl:call-template>
                </xsl:when>
                <xsl:when test="text() = 'Enkeltsidig trykk'">
                    <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.printing'"/><xsl:with-param name="value" select="'single-sided'"/></xsl:call-template>
                </xsl:when>
                
                <!-- Handle books coming through the Accessible Books Consortium which is not marked as NEDLASTET or INNKJØPT in *598$a -->
                <xsl:when test="text() = 'Accessible Books Consortium' and not((../../*[@tag='598']/*[@code='a'])[1])">
                    <xsl:call-template name="external-production">
                        <xsl:with-param name="tag598a" select="()"/>
                        <xsl:with-param name="tag594a" select="text()"/>
                        <xsl:with-param name="tag260b" select="(../../*[@tag='260']/*[@code='b']/text())[1]"/>
                    </xsl:call-template>
                </xsl:when>
                <!--<xsl:call-template name="meta"><xsl:with-param name="property" select="'clean-598'"/><xsl:with-param name="value" select="'single-sided'"/></xsl:call-template>-->
            </xsl:choose>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="*:datafield[@tag='595']">
        <!--<xsl:message select="'NORMARC-felt ignorert: 595 LOKALE NOTER'"/>-->
    </xsl:template>

    <xsl:template match="*:datafield[@tag='596']">
        <xsl:variable name="preceding-issued-years" select="(for $year in (preceding-sibling::*:datafield[@tag='596']/*:subfield[@code='c']/number(nlb:parseYear(text(), false()))) return if ($year eq $year) then $year else (), xs:double('INF'))"/>
        <xsl:variable name="following-issued-years" select="(for $year in (following-sibling::*:datafield[@tag='596']/*:subfield[@code='c']/number(nlb:parseYear(text(), false()))) return if ($year eq $year) then $year else (), xs:double('INF'))"/>
        <xsl:variable name="issued-year" select="(*:subfield[@code='c']/number(nlb:parseYear(text(), false())))[1]"/>

        <xsl:if test="$issued-year lt min($preceding-issued-years) and $issued-year le min($following-issued-years)
                      or not($issued-year eq $issued-year) and min(($preceding-issued-years, $following-issued-years)) = xs:double('INF') and not(preceding-sibling::*:datafield[@tag='596'])">
            <xsl:for-each select="*:subfield[@code='b']">
                <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:publisher.original'"/><xsl:with-param name="value" select="replace(text(),'[\[\]]','')"/></xsl:call-template>
            </xsl:for-each>
            <xsl:for-each select="*:subfield[@code='a']">
                <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:publisher.location.original'"/><xsl:with-param name="value" select="replace(text(),'[\[\]]','')"/></xsl:call-template>
            </xsl:for-each>
            <xsl:for-each select="*:subfield[@code='c']">
                <xsl:if test="string(number($issued-year)) != 'NaN'">
                    <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:date.issued.original'"/><xsl:with-param name="value" select="string($issued-year)"/></xsl:call-template>
                </xsl:if>
            </xsl:for-each>
            <xsl:for-each select="*:subfield[@code='d']">
                <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('bookEdition.original')"/><xsl:with-param name="value" select="text()"/></xsl:call-template>
            </xsl:for-each>
            <xsl:for-each select="*:subfield[@code='e']">
                <xsl:if test="matches(text(),'^\s*\d+\s*s?[\.\s]*$') and string-length(replace(text(),'[^\d]','')) lt 10">
                    <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.extent.pages.original'"/><xsl:with-param name="value" select="replace(text(),'[^\d]','')"/></xsl:call-template>
                </xsl:if>
                <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:format.extent.original'"/><xsl:with-param name="value" select="text()"/></xsl:call-template>
            </xsl:for-each>
            <xsl:for-each select="*:subfield[@code='f']">
                <xsl:variable name="isbn-issn" select="replace(upper-case(text()),'[^\dX-]','')" as="xs:string"/>
                <xsl:variable name="length" select="string-length(replace($isbn-issn,'-',''))" as="xs:integer"/>
                <xsl:if test="not($isbn-issn = '0') and $length gt 0">
                    <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property(concat(if ($length lt 9) then 'issn' else 'isbn', '.original'))"/><xsl:with-param name="value" select="text()"/></xsl:call-template>
                </xsl:if>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>

    <xsl:template match="*:datafield[@tag='597']">
        <!--<xsl:message select="'NORMARC-felt ignorert: 597 LOKALE NOTER'"/>-->
    </xsl:template>

    <xsl:template match="*:datafield[@tag='598']">
        <xsl:for-each select="*:subfield[@code='a']">
            <xsl:call-template name="external-production">
                <xsl:with-param name="tag598a" select="text()"/>
                <xsl:with-param name="tag594a" select="(../../*[@tag='594']/*[@code='a']/text())[1]"/>
                <xsl:with-param name="tag260b" select="(../../*[@tag='260']/*[@code='b']/text())[1]"/>
            </xsl:call-template>

            <xsl:if test="lower-case(text()) = 'produksjonsrett'">
                <xsl:call-template name="meta">
                    <xsl:with-param name="property" select="nlb:prefixed-property('is-for-distribution')"/>
                    <xsl:with-param name="value" select="'false'"/>
                    <xsl:with-param name="context" select="."/>
                </xsl:call-template>

                <xsl:call-template name="meta">
                    <xsl:with-param name="property" select="nlb:prefixed-property('isAccessibleVersionCommerciallyAvailable')"/>
                    <xsl:with-param name="value" select="'true'"/>
                    <xsl:with-param name="context" select="."/>
                </xsl:call-template>
            </xsl:if>
            
            <xsl:if test="normalize-space(lower-case(text())) = 'anbefales ikke automatisk'">
                <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('exclude-from-recommendations')"/><xsl:with-param name="value" select="'true'"/></xsl:call-template>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:function name="nlb:clean-598" as="xs:string?">
        <xsl:param name="tag598a" as="text()?"/>
        <xsl:variable name="text" select="$tag598a" as="xs:string?"/>
        <xsl:choose>
            <xsl:when test="not($text) or not(matches($text, '^(INTERN BESKJED:\s*)?(INNKJ.PT?!?|NEDLASTE[DT]?|Ferdig|([\w].*)-([a-zA-Z0-9]+)(:|$)).*', 'i'))">
                <xsl:sequence select="()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="text" select="replace($text, '^INTERN BESKJED:\s*', '', 'i')" as="xs:string"/>
                <xsl:variable name="text" select="replace($text, 'Ferdig', ' ', 'i')" as="xs:string"/>
                <xsl:variable name="text" select="normalize-space($text)" as="xs:string"/>
                <xsl:variable name="text" select="replace($text, '^INNKJ.PT?!?( FRA)?', 'INNKJØPT FRA', 'i')" as="xs:string"/>
                <xsl:variable name="text" select="replace($text, '^NEDLASTE[DT]?( FRA)?', 'NEDLASTET FRA', 'i')" as="xs:string"/>
                <xsl:variable name="text" select="replace($text, '^:', 'FERDIG:')"/>
                <xsl:variable name="text" select="replace($text, '^([\w].*)-([a-zA-Z0-9]+)', 'FERDIG FRA $1-$2')"/>
                
                <!-- clean date part if present -->
                <xsl:variable name="date-cleaning-regex" select="'^.*?(\d\d?)[\./]+(\d\d?)[\./]+(\d\d\d\d|\d\d)([^\d].*?$|$)'" as="xs:string"/>
                <xsl:variable name="retrieved" select="if (matches($text, $date-cleaning-regex, 'i'))
                                                        then replace($text, $date-cleaning-regex, '$3-$2-$1', 'i')
                                                        else ()" as="xs:string?"/>
                <xsl:variable name="retrieved" select="if ($retrieved) then replace(replace(replace($retrieved,
                    '-(\d)$', '-0$1'),
                    '-(\d)-', '-0$1-'),
                    '^(\d\d)-', '20$1-')
                    else $retrieved"  as="xs:string?"/>
                <xsl:variable name="text" select="replace($text, ':.*', '')" as="xs:string"/>
                <xsl:variable name="text" select="if ($retrieved) then concat($text, ': ', $retrieved) else $text" as="xs:string"/>
                
                <xsl:sequence select="$text"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:template name="external-production">
        <xsl:param name="tag260b" as="text()?"/>
        <xsl:param name="tag594a" as="text()?"/>
        <xsl:param name="tag598a" as="text()?"/>
        
        <xsl:variable name="text" select="nlb:clean-598($tag598a)" as="xs:string?"/>
        <!--<xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('dirty-598')"/><xsl:with-param name="value" select="string($tag598a)"/></xsl:call-template>
        <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('clean-598')"/><xsl:with-param name="value" select="string($text)"/></xsl:call-template>-->
        <xsl:variable name="agreement" select="if ($tag594a = ('Accessible Books Consortium', 'TIGAR', 'TIGAR/ABC', 'ABC/TIGAR')) then 'Accessible Books Consortium' else ()" as="xs:string?"/>
        <xsl:variable name="category" select="if (starts-with($text, 'INNKJØPT')) then 'WIPS' else if (starts-with($text, 'NEDLASTET')) then 'NEDLASTET' else ()" as="xs:string?"/>
        <xsl:variable name="category-context" select="if ($category) then $tag598a else $tag594a" as="text()?"/>
        <xsl:variable name="category" select="if (not($category) and $agreement = 'Accessible Books Consortium') then 'NEDLASTET' else $category" as="xs:string?"/>
        <xsl:variable name="source" select="if (matches($text, '^(INNKJØPT|NEDLASTET|FERDIG) FRA ([\w].*?)(:.*)?$')) then normalize-space(replace(replace($text, '^(INNKJØPT|NEDLASTET|FERDIG) FRA ([\w].*?)(:.*)?$', '$2'), ' \d.*', '')) else ()" as="xs:string?"/>
        <xsl:variable name="source-identifier-regex" select="'([\w].*?)-([a-zA-Z0-9-]*\d[a-zA-Z0-9-]*)'" as="xs:string"/>
        <xsl:variable name="source-identifier" select="if (matches($source, $source-identifier-regex)) then replace($source, $source-identifier-regex, '$2') else ()" as="xs:string?"/>
        <xsl:variable name="source" select="if (matches($source, $source-identifier-regex)) then replace($source, $source-identifier-regex, '$1') else $source" as="xs:string?"/>
        <xsl:variable name="source" select="if (matches($source, '^[\d./]+$')) then () else $source" as="xs:string?"/>
        <xsl:variable name="source" select="if ($source) then replace($source, '(^[^\w]+|[^\w]+$)', '') else $source" as="xs:string?"/>
        <xsl:variable name="source-context" select="if ($source) then $tag598a else $tag260b" as="text()?"/>
        <xsl:variable name="source" select="if ($source) then $source else $tag260b" as="xs:string?"/>
        <xsl:variable name="retrieved" select="if (contains($text, ': ')) then substring-after($text, ': ') else ()" as="xs:string?"/>
        <xsl:if test="$category">
            <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('external-production')"/><xsl:with-param name="value" select="$category"/><xsl:with-param name="context" select="$tag598a/parent::*"/></xsl:call-template>
            <xsl:if test="$source">
                <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('external-source')"/><xsl:with-param name="value" select="$source"/><xsl:with-param name="context" select="$source-context/parent::*"/></xsl:call-template>
            </xsl:if>
            <xsl:if test="$source-identifier">
                <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('external-identifier')"/><xsl:with-param name="value" select="$source-identifier"/><xsl:with-param name="context" select="$source-context/parent::*"/></xsl:call-template>
            </xsl:if>
            <xsl:if test="$agreement">
                <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('external-agreement')"/><xsl:with-param name="value" select="$agreement"/><xsl:with-param name="context" select="$tag594a/parent::*"/></xsl:call-template>
            </xsl:if>
            <xsl:if test="$retrieved">
                <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('external-retrieved')"/><xsl:with-param name="value" select="$retrieved"/><xsl:with-param name="context" select="$tag598a/parent::*"/></xsl:call-template>
            </xsl:if>
        </xsl:if>
    </xsl:template>

    <xsl:template match="*:datafield[@tag='599']">
        <xsl:choose>
            <!-- $b must be an integer, and if $a exists, it must be either 'EPUB-nr', 'EPUB' or 'DTB-nr' -->
            <xsl:when test="exists(*:subfield[@code='b']) and matches(*:subfield[@code='b'][1]/text(), '^\d+$')
                            and (
                                *:subfield[@code='a']/lower-case(text()) = ('epub-nr', 'epub', 'dtb-nr')
                                or not(exists(*:subfield[@code='a']))
                            )">
                <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('epub-nr')"/><xsl:with-param name="value" select="(*:subfield[@code='b'])[1]/text()"/></xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <!--<xsl:message select="'NORMARC-felt ignorert: 599 LOKALE NOTER'"/>-->
            </xsl:otherwise>
        </xsl:choose>

        <xsl:if test="exists(*:subfield[@code='a']) and *:subfield[@code='a']/lower-case(text()) = ('ikke til utlån', 'statpedintern')">
            <xsl:call-template name="meta">
                <xsl:with-param name="property" select="nlb:prefixed-property('is-for-distribution')"/>
                <xsl:with-param name="value" select="'false'"/>
                <xsl:with-param name="context" select="."/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>

    <!-- 6XX EMNEINNFØRSLER -->
    
    <xsl:template match="*:datafield[@tag='600']">
        <!-- when we find the first *600 -->
        <xsl:if test="not(preceding-sibling::*:datafield[@tag='600'])">
            <!-- then handle all *600 sorted by $a and $b -->
            <xsl:for-each select="../*:datafield[@tag='600']">
                <xsl:sort select="string-join((*:subfield[@code='a']/text(), *:subfield[@code='b']/text(), *:subfield[@code='c']/text(), *:subfield[@code='d']/text()), ' ')"/>
                <xsl:call-template name="datafield600">
                    <xsl:with-param name="position" select="position()"/>
                </xsl:call-template>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>

    <xsl:template name="datafield600">
        <xsl:param name="position"/>
        
        <xsl:for-each select="*:subfield[@code=('g', '0') and not(starts-with(text(), '(NO-TrBIB)'))]">
            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:subject.keyword'"/><xsl:with-param name="value" select="text()"/></xsl:call-template>
        </xsl:for-each>
        <xsl:for-each select="*:subfield[@code='x']">
            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:subject.keyword'"/><xsl:with-param name="value" select="text()"/></xsl:call-template>
        </xsl:for-each>

        <xsl:variable name="subject-id" select="concat('subject-600-',string($position))"/>
        <xsl:variable name="name" select="(*:subfield[@code='a'], *:subfield[@code='q'], *:subfield[@code='w'])[normalize-space(.)][1]/text()"/>

        <xsl:if test="not($name='')">

            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:subject'"/><xsl:with-param name="value" select="$name"/><xsl:with-param name="id" select="$subject-id"/></xsl:call-template>

            <xsl:for-each select="*:subfield[@code='b']">
                <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('honorificSuffix')"/><xsl:with-param name="value" select="text()"/><xsl:with-param name="refines" select="$subject-id"/></xsl:call-template>
            </xsl:for-each>

            <xsl:for-each select="*:subfield[@code='c']">
                <xsl:choose>
                    <xsl:when test="matches(text(), $PSEUDONYM)">
                        <xsl:variable name="pseudonym" select="replace(text(), $PSEUDONYM_REPLACE, '$1')"/>
                        <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('pseudonym')"/><xsl:with-param name="value" select="$pseudonym"/><xsl:with-param name="refines" select="$subject-id"/></xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('honorificPrefix')"/><xsl:with-param name="value" select="text()"/><xsl:with-param name="refines" select="$subject-id"/></xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>

            <xsl:for-each select="*:subfield[@code='d']">
                <xsl:variable name="birthDeath" select="tokenize(nlb:parseBirthDeath(text()), ',')"/>
                <xsl:if test="$birthDeath[1]">
                    <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('birthDate')"/><xsl:with-param name="value" select="$birthDeath[1]"/><xsl:with-param name="refines" select="$subject-id"/></xsl:call-template>
                </xsl:if>
                <xsl:if test="$birthDeath[2]">
                    <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('deathDate')"/><xsl:with-param name="value" select="$birthDeath[2]"/><xsl:with-param name="refines" select="$subject-id"/></xsl:call-template>
                </xsl:if>
            </xsl:for-each>
            
            <xsl:call-template name="nationality">
                <xsl:with-param name="refines" select="$subject-id"/>
            </xsl:call-template>

            <xsl:call-template name="bibliofil-id">
                <xsl:with-param name="context" select="."/>
                <xsl:with-param name="refines" select="$subject-id"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="*:datafield[@tag='610']">
        <!-- when we find the first *610 -->
        <xsl:if test="not(preceding-sibling::*:datafield[@tag='610'])">
            <!-- then handle all *610 sorted by $a and $b -->
            <xsl:for-each select="../*:datafield[@tag='610']">
                <xsl:sort select="*:subfield[@code='a']/text()"/>
                <xsl:call-template name="datafield610">
                    <xsl:with-param name="position" select="position()"/>
                </xsl:call-template>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>

    <xsl:template name="datafield610">
        <xsl:param name="position"/>
        <xsl:variable name="subject-id" select="concat('subject-610-', $position)"/>

        <xsl:if test="*:subfield[@code='a']">
            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:subject.keyword'"/><xsl:with-param name="value" select="*:subfield[@code='a']/text()"/><xsl:with-param name="id" select="$subject-id"/></xsl:call-template>

            <xsl:for-each select="*:subfield[@code='b']">
                <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:subject.keyword'"/><xsl:with-param name="value" select="text()"/><xsl:with-param name="refines" select="$subject-id"/></xsl:call-template>
            </xsl:for-each>
            <xsl:for-each select="*:subfield[@code='q']">
                <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:subject.keyword'"/><xsl:with-param name="value" select="text()"/><xsl:with-param name="refines" select="$subject-id"/></xsl:call-template>
            </xsl:for-each>

            <xsl:call-template name="bibliofil-id">
                <xsl:with-param name="context" select="."/>
                <xsl:with-param name="refines" select="$subject-id"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>

    <xsl:template match="*:datafield[@tag='611']">
        <xsl:variable name="subject-id" select="concat('subject-611-',1+count(preceding-sibling::*:datafield[@tag='611']))"/>

        <xsl:if test="*:subfield[@code='a']">
            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:subject.keyword'"/><xsl:with-param name="value" select="*:subfield[@code='a']/text()"/><xsl:with-param name="id" select="$subject-id"/></xsl:call-template>

            <xsl:call-template name="bibliofil-id">
                <xsl:with-param name="context" select="."/>
                <xsl:with-param name="refines" select="$subject-id"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>

    <xsl:template match="*:datafield[@tag='650']">
        <!-- when we find the first *650 -->
        <xsl:if test="not(preceding-sibling::*:datafield[@tag='650'])">
            <!-- then handle all *650 sorted by $a and $0 -->
            <xsl:for-each select="../*:datafield[@tag='650']">
                <xsl:sort select="string-join((*:subfield[@code='a']/upper-case(text()), *:subfield[@code=('g', '0')]/text()), ' ')"/>
                <xsl:call-template name="datafield650">
                    <xsl:with-param name="position" select="position()"/>
                </xsl:call-template>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="datafield650">
        <xsl:param name="position"/>
        <xsl:variable name="subject-id" select="concat('subject-650-', string($position))"/>

        <xsl:if test="*:subfield[@code='a']">
            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:subject.keyword'"/><xsl:with-param name="value" select="*:subfield[@code='a'][1]/text()"/><xsl:with-param name="id" select="$subject-id"/></xsl:call-template>

            <xsl:if test="*:subfield[@code='a']/text()=('Tidsskrifter','Avis')">
                <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('periodical')"/><xsl:with-param name="value" select="'true'"/></xsl:call-template>
            </xsl:if>
            <xsl:if test="*:subfield[@code='a']/text()='Tidsskrifter'">
                <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('magazine')"/><xsl:with-param name="value" select="'true'"/></xsl:call-template>
            </xsl:if>
            <xsl:if test="*:subfield[@code='a']/text()='Avis'">
                <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('newspaper')"/><xsl:with-param name="value" select="'true'"/></xsl:call-template>
            </xsl:if>

            <xsl:for-each select="*:subfield[@code=('0','g','x')]">
                <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:subject.keyword'"/><xsl:with-param name="value" select="text()"/><xsl:with-param name="refines" select="$subject-id"/></xsl:call-template>
            </xsl:for-each>
            <xsl:for-each select="*:subfield[@code='c']">
                <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:subject.keyword'"/><xsl:with-param name="value" select="text()"/><xsl:with-param name="refines" select="$subject-id"/></xsl:call-template>
            </xsl:for-each>
            <xsl:for-each select="*:subfield[@code='d']">
                <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:subject.time'"/><xsl:with-param name="value" select="text()"/><xsl:with-param name="refines" select="$subject-id"/></xsl:call-template>
            </xsl:for-each>
            <xsl:for-each select="*:subfield[@code='q']">
                <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:subject.keyword'"/><xsl:with-param name="value" select="text()"/><xsl:with-param name="refines" select="$subject-id"/></xsl:call-template>
            </xsl:for-each>
            <xsl:for-each select="*:subfield[@code='z']">
                <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:subject.location'"/><xsl:with-param name="value" select="replace(text(),'[\[\]]','')"/><xsl:with-param name="refines" select="$subject-id"/></xsl:call-template>
            </xsl:for-each>
            
            <!-- generated by NLB as a replacement for the old dewey field in $1 -->
            <xsl:for-each select="*:subfield[@code='9']">
                <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:subject.dewey'"/><xsl:with-param name="value" select="text()"/><xsl:with-param name="refines" select="$subject-id"/></xsl:call-template>
            </xsl:for-each>
            
            <xsl:call-template name="bibliofil-id">
                <xsl:with-param name="context" select="."/>
                <xsl:with-param name="refines" select="$subject-id"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>

    <xsl:template match="*:datafield[@tag='651']">
        <!-- when we find the first *651 -->
        <xsl:if test="not(preceding-sibling::*:datafield[@tag='651'])">
            <!-- then handle all *650 sorted by $a -->
            <xsl:for-each select="../*:datafield[@tag='651']">
                <xsl:sort select="*:subfield[@code='a'][1]/text()"/>
                <xsl:call-template name="datafield651">
                    <xsl:with-param name="position" select="position()"/>
                </xsl:call-template>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="datafield651">
        <xsl:param name="position"/>
        <xsl:variable name="subject-id" select="concat('subject-651-', $position)"/>

        <xsl:if test="*:subfield[@code='a']">
            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:subject.location'"/><xsl:with-param name="value" select="*:subfield[@code='a']/replace(text(),'[\[\]]','')"/><xsl:with-param name="id" select="$subject-id"/></xsl:call-template>

            <xsl:for-each select="*:subfield[@code='q']">
                <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:subject.location'"/><xsl:with-param name="value" select="replace(text(),'[\[\]]','')"/><xsl:with-param name="refines" select="$subject-id"/></xsl:call-template>
            </xsl:for-each>
            <xsl:for-each select="*:subfield[@code='z']">
                <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:subject.location'"/><xsl:with-param name="value" select="replace(text(),'[\[\]]','')"/><xsl:with-param name="refines" select="$subject-id"/></xsl:call-template>
            </xsl:for-each>

            <xsl:call-template name="bibliofil-id">
                <xsl:with-param name="context" select="."/>
                <xsl:with-param name="refines" select="$subject-id"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>

    <xsl:template match="*:datafield[@tag='653']">
        <xsl:variable name="subject-id" select="concat('subject-653-',1+count(preceding-sibling::*:datafield[@tag='653']))"/>

        <xsl:if test="*:subfield[@code='a']">
            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:subject.keyword'"/><xsl:with-param name="value" select="*:subfield[@code='a']/text()"/><xsl:with-param name="id" select="$subject-id"/></xsl:call-template>

            <xsl:call-template name="bibliofil-id">
                <xsl:with-param name="context" select="."/>
                <xsl:with-param name="refines" select="$subject-id"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>

    <xsl:template match="*:datafield[@tag='655']">
        <xsl:choose>
            <xsl:when test="exists(preceding-sibling::*:datafield[@tag='655'])">
                <!-- ignore, we process everything on the first match -->
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="tag655" as="element()*">
                    <xsl:for-each select="../*:datafield[@tag='655']">
                        <xsl:sort select="string-join(*:subfield[@code='a']/text(), ' ')"/>
                        <xsl:if test="*:subfield[@code='a'] and not(*:subfield[@code='2']/text() = 'norvok')">
                            <xsl:sequence select="."/>
                        </xsl:if>
                    </xsl:for-each>
                </xsl:variable>
                
                <xsl:for-each select="$tag655">
                    <xsl:call-template name="datafield655">
                        <xsl:with-param name="position" select="position()"/>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="datafield655">
        <xsl:param name="position"/>
        <xsl:variable name="subject-id" select="concat('subject-655-', $position)"/>
            
        <xsl:variable name="context" select="."/>
        <xsl:variable name="mainGenre" select="*:subfield[@code='a']/text()"/>
        <xsl:variable name="subGenre" as="xs:string*">
            <xsl:for-each select="*:subfield[@code='x']">
                <xsl:sort/>
                <xsl:sequence select="text()"/>
            </xsl:for-each>
            <xsl:for-each select="*:subfield[@code='9']">
                <xsl:choose>
                    <xsl:when test="normalize-space(.) = ('nno','nob','non','nor','n')">
                        <xsl:sequence select="'Norsk'"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:sequence select="."/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="genre" select="if (count($subGenre)) then concat($mainGenre, ' (', string-join($subGenre,'/'), ')') else $mainGenre"/>

        <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:type.genre'"/><xsl:with-param name="value" select="$genre"/><xsl:with-param name="id" select="$subject-id"/></xsl:call-template>
        <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:type.genre.no'"/><xsl:with-param name="value" select="$genre"/><xsl:with-param name="refines" select="$subject-id"/></xsl:call-template>
        <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:type.mainGenre'"/><xsl:with-param name="value" select="$mainGenre"/><xsl:with-param name="refines" select="$subject-id"/></xsl:call-template>
        <xsl:for-each select="$subGenre">
            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:type.subGenre'"/><xsl:with-param name="value" select="."/><xsl:with-param name="refines" select="$subject-id"/><xsl:with-param name="context" select="$context"/></xsl:call-template>
        </xsl:for-each>

        <xsl:call-template name="bibliofil-id">
            <xsl:with-param name="context" select="."/>
            <xsl:with-param name="refines" select="$subject-id"/>
        </xsl:call-template>
        
    </xsl:template>

    <xsl:template match="*:datafield[@tag='691']">
        <xsl:variable name="subject-id" select="concat('subject-691-',1+count(preceding-sibling::*:datafield[@tag='691']))"/>

        <xsl:if test="*:subfield[@code='a']">
            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:subject.keyword'"/><xsl:with-param name="value" select="*:subfield[@code='a']/text()"/><xsl:with-param name="id" select="$subject-id"/></xsl:call-template>
            
            <xsl:call-template name="bibliofil-id">
                <xsl:with-param name="context" select="."/>
                <xsl:with-param name="refines" select="$subject-id"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>

    <xsl:template match="*:datafield[@tag='692']">
        <xsl:variable name="subject-id" select="concat('subject-692-',1+count(preceding-sibling::*:datafield[@tag='692']))"/>

        <xsl:if test="*:subfield[@code='a']">
            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:subject.keyword'"/><xsl:with-param name="value" select="*:subfield[@code='a']/text()"/><xsl:with-param name="id" select="$subject-id"/></xsl:call-template>

            <xsl:call-template name="bibliofil-id">
                <xsl:with-param name="context" select="."/>
                <xsl:with-param name="refines" select="$subject-id"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>

    <xsl:template match="*:datafield[@tag='693']">
        <xsl:variable name="subject-id" select="concat('subject-693-',1+count(preceding-sibling::*:datafield[@tag='693']))"/>

        <xsl:if test="*:subfield[@code='a']">
            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:subject.keyword'"/><xsl:with-param name="value" select="*:subfield[@code='a']/text()"/><xsl:with-param name="id" select="$subject-id"/></xsl:call-template>

            <xsl:call-template name="bibliofil-id">
                <xsl:with-param name="context" select="."/>
                <xsl:with-param name="refines" select="$subject-id"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>

    <xsl:template match="*:datafield[@tag='694']">
        <!-- På gamle slettede kassetter står det i mange tilfeller teksten "Uten Daisy" i dette feltet. Ignoreres. -->
    </xsl:template>

    <xsl:template match="*:datafield[@tag='695']">
        <xsl:variable name="subject-id" select="concat('subject-695-',1+count(preceding-sibling::*:datafield[@tag='695']))"/>

        <xsl:if test="*:subfield[@code='a']">
            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:subject.keyword'"/><xsl:with-param name="value" select="*:subfield[@code='a']/text()"/><xsl:with-param name="id" select="$subject-id"/></xsl:call-template>

            <xsl:call-template name="bibliofil-id">
                <xsl:with-param name="context" select="."/>
                <xsl:with-param name="refines" select="$subject-id"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>

    <xsl:template match="*:datafield[@tag='696']">
        <xsl:variable name="subject-id" select="concat('subject-696-',1+count(preceding-sibling::*:datafield[@tag='696']))"/>

        <xsl:if test="*:subfield[@code='a']">
            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:subject.keyword'"/><xsl:with-param name="value" select="*:subfield[@code='a']/text()"/><xsl:with-param name="id" select="$subject-id"/></xsl:call-template>

            <xsl:call-template name="bibliofil-id">
                <xsl:with-param name="context" select="."/>
                <xsl:with-param name="refines" select="$subject-id"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>

    <xsl:template match="*:datafield[@tag='697']">
        <xsl:for-each select="*:subfield[@code='a']">
            <xsl:if test="text() = 'Lydbok med tekst'">
                <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:type.audio'"/><xsl:with-param name="value" select="'true'"/></xsl:call-template>
                <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:type.text'"/><xsl:with-param name="value" select="'true'"/></xsl:call-template>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="*:datafield[@tag='699']">
        <xsl:variable name="subject-id" select="concat('subject-699-',1+count(preceding-sibling::*:datafield[@tag='699']))"/>

        <xsl:if test="*:subfield[@code='a']">
            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:subject.keyword'"/><xsl:with-param name="value" select="*:subfield[@code='a']/text()"/><xsl:with-param name="id" select="$subject-id"/></xsl:call-template>

            <xsl:for-each select="*:subfield[@code='c']">
                <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:subject.keyword'"/><xsl:with-param name="value" select="text()"/><xsl:with-param name="refines" select="$subject-id"/></xsl:call-template>
            </xsl:for-each>
            <xsl:for-each select="*:subfield[@code='d']">
                <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:subject.time'"/><xsl:with-param name="value" select="text()"/><xsl:with-param name="refines" select="$subject-id"/></xsl:call-template>
            </xsl:for-each>
            <xsl:for-each select="*:subfield[@code='q']">
                <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:subject.keyword'"/><xsl:with-param name="value" select="text()"/><xsl:with-param name="refines" select="$subject-id"/></xsl:call-template>
            </xsl:for-each>
            <xsl:for-each select="*:subfield[@code='z']">
                <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('location')"/><xsl:with-param name="value" select="replace(text(),'[\[\]]','')"/><xsl:with-param name="refines" select="$subject-id"/></xsl:call-template>
            </xsl:for-each>

            <xsl:call-template name="bibliofil-id">
                <xsl:with-param name="context" select="."/>
                <xsl:with-param name="refines" select="$subject-id"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>

    <!-- 700 - 75X BIINNFØRSLER -->
    
    <xsl:function name="nlb:actorRoleID">
        <!-- this is a function used to filter out duplicate (actor + role) relationships. For instance if an actor comes up with the "narrator" role twice.  -->
        <xsl:param name="actor" as="element()"/>
        <xsl:param name="result-elements" as="element()*"/>
        
        <xsl:variable name="actor-role" select="$actor/concat(name(), @property)" as="xs:string"/>
        <xsl:variable name="actor-name" select="$actor/text()" as="xs:string"/>
        <xsl:variable name="actor-bibliofil-id" select="($result-elements[ends-with(@property, 'bibliofil-id') and @refines = $actor/concat('#', @id)])[1]/text()" as="xs:string?"/>
        
        <xsl:value-of select="concat($actor-role, $actor-name, $actor-bibliofil-id)"/>
    </xsl:function>
    
    <xsl:function name="nlb:sortable-string" as="xs:string">
        <xsl:param name="value" as="xs:string"/>
        <xsl:value-of select="
            replace(replace(replace(replace(
            upper-case($value),
            'Ö', 'OE'),
            'Æ', 'AE'),
            'Ø', 'OE'),
            'Å', 'AA')
            "/>
    </xsl:function>
    
    <xsl:template match="*:datafield[@tag='700']">
        <xsl:variable name="debug-context" select="."/>
        <!-- when we find the first *700 -->
        <xsl:if test="not(preceding-sibling::*:datafield[@tag='700'])">
            <!-- then handle all *700 in sorted order -->
            <xsl:variable name="results" as="element()*">
                <xsl:variable name="role-subfields" as="element()*">
                    <xsl:for-each select="../*:datafield[@tag='700']">
                        <xsl:sequence select="(*:subfield[@code='4' and not(nlb:parseRole(text()) = 'dc:contributor.other')],
                                               *:subfield[@code='e' and not(nlb:parseRole(text()) = 'dc:contributor.other')],
                                               *:subfield[@code='r' and not(nlb:parseRole(text()) = 'dc:contributor.other')],
                                               *:subfield[@code='x' and not(nlb:parseRole(text()) = 'dc:contributor.other')])"/>
                    </xsl:for-each>
                </xsl:variable>
                <xsl:variable name="datafields-without-role-subfield" select="../*:datafield[@tag='700' and not(*:subfield = $role-subfields)]" as="element()*"/>
                <xsl:for-each select="$role-subfields | $datafields-without-role-subfield">
                    <xsl:sort select="string-join(((.|..)/*:subfield[@code='a']/nlb:sortable-string(text()), (.|..)/*:subfield[@code='d']/text(), (.|..)/*:subfield[@code='e']/text()), '')"/>
                    <xsl:call-template name="datafield700">
                        <xsl:with-param name="position" select="position()"/>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:variable>
            
            <!-- remove duplicate roles -->
            <xsl:variable name="main-results" as="element()*">
                <xsl:for-each select="1 to count($results)">
                    <xsl:variable name="position" select="."/>
                    
                    <xsl:variable name="actorRoleID" select="$results[$position]/nlb:actorRoleID(., $results)"/>
                    
                    <xsl:if test="$results[$position]/@id and not($actorRoleID = $results[position() lt $position]/nlb:actorRoleID(., $results))">
                        <xsl:sequence select="$results[$position]"/>
                    </xsl:if>
                </xsl:for-each>
            </xsl:variable>
            <xsl:for-each select="$main-results">
                <xsl:sequence select=". | $results[@refines = concat('#',current()/@id)]"/>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="datafield700">
        <xsl:param name="position"/>
        <xsl:variable name="contributor-id" select="concat('contributor-700-', $position)"/>

        <!-- either the context is a role element, or for datafields without a role element, we use the datafield itself -->
        <xsl:variable name="role-element" select="if (self::*:subfield) then . else ()" as="element()?"/>
        <xsl:variable name="datafield" select="if (self::*:subfield) then parent::* else ." as="element()"/>
        
        <xsl:for-each select="$datafield"> <!-- set the datafield as the context for xpath expressions -->
            <xsl:variable name="name" select="(*:subfield[@code='a'], *:subfield[@code='q'], *:subfield[@code='w'])[normalize-space(.)][1]/text()"/>
            <xsl:if test="$name">
                <xsl:variable name="role" select="nlb:parseRole(concat('',$role-element/text()))"/>
    
                <xsl:call-template name="meta">
                    <xsl:with-param name="property" select="$role"/>
                    <xsl:with-param name="value" select="$name"/>
                    <xsl:with-param name="id" select="$contributor-id"/>
                </xsl:call-template>
    
                <xsl:for-each select="*:subfield[@code='b']">
                    <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('honorificSuffix')"/><xsl:with-param name="value" select="text()"/><xsl:with-param name="refines" select="$contributor-id"/></xsl:call-template>
                </xsl:for-each>
    
                <xsl:for-each select="*:subfield[@code='c']">
                    <xsl:choose>
                        <xsl:when test="matches(text(), $PSEUDONYM)">
                            <xsl:variable name="pseudonym" select="replace(text(), $PSEUDONYM_REPLACE, '$1')"/>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('pseudonym')"/><xsl:with-param name="value" select="$pseudonym"/><xsl:with-param name="refines" select="$contributor-id"/></xsl:call-template>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('honorificPrefix')"/><xsl:with-param name="value" select="text()"/><xsl:with-param name="refines" select="$contributor-id"/></xsl:call-template>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
    
                <xsl:for-each select="*:subfield[@code='d']">
                    <xsl:variable name="birthDeath" select="tokenize(nlb:parseBirthDeath(text()), ',')"/>
                    <xsl:if test="$birthDeath[1]">
                        <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('birthDate')"/><xsl:with-param name="value" select="$birthDeath[1]"/><xsl:with-param name="refines" select="$contributor-id"/></xsl:call-template>
                    </xsl:if>
                    <xsl:if test="$birthDeath[2]">
                        <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('deathDate')"/><xsl:with-param name="value" select="$birthDeath[2]"/><xsl:with-param name="refines" select="$contributor-id"/></xsl:call-template>
                    </xsl:if>
                </xsl:for-each>
    
                <xsl:call-template name="nationality">
                    <xsl:with-param name="refines" select="$contributor-id"/>
                </xsl:call-template>
    
                <xsl:call-template name="bibliofil-id">
                    <xsl:with-param name="context" select="."/>
                    <xsl:with-param name="refines" select="$contributor-id"/>
                </xsl:call-template>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="*:datafield[@tag='710']">
        <xsl:choose>
            <xsl:when test="exists(preceding-sibling::*:datafield[@tag='710'])">
                <!-- ignore everything but the first one; everything is processed in xsl:otherwise -->
            </xsl:when>
            <xsl:otherwise>
                <xsl:for-each select="../*:datafield[@tag='710' and exists(*:subfield[@code='a'])]">
                    <xsl:sort select="*:subfield[@code='a'][1]/text()"/>
                    <xsl:call-template name="datafield710">
                        <xsl:with-param name="position" select="string(position())"/>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="datafield710">
        <xsl:param name="position"/>
        <xsl:variable name="creator-id" select="concat('creator-710-', $position)"/>
        
        <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:creator'"/><xsl:with-param name="value" select="*:subfield[@code='a'][1]/text()"/><xsl:with-param name="id" select="$creator-id"/></xsl:call-template>
        
        <xsl:call-template name="bibliofil-id">
            <xsl:with-param name="context" select="."/>
            <xsl:with-param name="refines" select="$creator-id"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="*:datafield[@tag='730']">
        <xsl:for-each select="*:subfield[@code='a']">
            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:title.alternative'"/><xsl:with-param name="value" select="text()"/></xsl:call-template>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="*:datafield[@tag='740']">
        <xsl:if test="exists(*:subfield[@code='a']) and starts-with((*:subfield[@code='e']/text())[1], 'delt')
                      and not(preceding-sibling::*:datafield[@tag='740' and exists(*:subfield[@code='a']) and starts-with((*:subfield[@code='e']/text())[1], 'delt')])">
            <xsl:variable name="title-id" select="concat('title-740-',1+count(preceding-sibling::*:datafield[@tag='740']))"/>
            <xsl:for-each select="*:subfield[@code='a']">
                <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:title.part.other'"/><xsl:with-param name="value" select="text()"/><xsl:with-param name="id" select="$title-id"/></xsl:call-template>
            </xsl:for-each>
            <xsl:for-each select="*:subfield[@code='b']">
                <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:title.part.subTitle.other'"/><xsl:with-param name="value" select="text()"/></xsl:call-template>
            </xsl:for-each>
            <xsl:for-each select="*:subfield[@code='n']">
                <xsl:variable name="position" select="replace(text(),'^.*?(\d+).*$','$1')"/>
                <xsl:if test="matches($position, '^\d+$')">
                    <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('position')"/><xsl:with-param name="value" select="$position"/></xsl:call-template>
                </xsl:if>
            </xsl:for-each>
            <xsl:for-each select="*:subfield[@code='p']">
                <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:title.part.subTitle'"/><xsl:with-param name="value" select="text()"/></xsl:call-template>
            </xsl:for-each>
            <xsl:for-each select="*:subfield[@code='w']">
                <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('sortingKey')"/><xsl:with-param name="value" select="text()"/><xsl:with-param name="refines" select="$title-id"/></xsl:call-template>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>

    <!-- 760 - 79X LENKER / RELASJONER -->
    
    <xsl:template match="*:datafield[@tag='780']">
        <xsl:choose>
            <xsl:when test="exists(preceding-sibling::*:datafield[@tag='780'])">
                <!-- ignore everything but the first one; everything is processed in xsl:otherwise -->
            </xsl:when>
            <xsl:otherwise>
                <xsl:for-each select="../*:datafield[@tag='780']">
                    <xsl:sort select="*:subfield[@code='w'][1]/text()"/>
                    <xsl:call-template name="tag780">
                        <xsl:with-param name="position" select="string(position())"/>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="tag780">
        <xsl:param name="position" as="xs:string"/>
        
        <xsl:variable name="series-preceding-id" select="concat('series-preceding-', $position)"/>

        <xsl:if test="*:subfield[@code='t']">
            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:title.series.preceding'"/><xsl:with-param name="value" select="*:subfield[@code='t']/text()"/><xsl:with-param name="id" select="$series-preceding-id"/></xsl:call-template>
        </xsl:if>
        <xsl:for-each select="*:subfield[@code='w']">
            <xsl:variable name="identifier" select="replace(replace(text(), '\([^)]*\)', ''), '\s', '')"/>
            <xsl:if test="matches($identifier, '^\d+$')">
                <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:identifier.series.preceding.uri'"/><xsl:with-param name="value" select="concat('urn:NBN:no-nb_nlb_',$identifier)"/><xsl:with-param name="refines" select="$series-preceding-id"/></xsl:call-template>
                <xsl:call-template name="meta">
                    <xsl:with-param name="property" select="'dc:identifier.series.preceding'"/>
                    <xsl:with-param name="value" select="$identifier"/>
                    <xsl:with-param name="id" select="if (not(count(parent::*/*:subfield[@code='t']))) then $series-preceding-id else ()"/>
                    <xsl:with-param name="refines" select="if (count(parent::*/*:subfield[@code='t'])) then $series-preceding-id else ()"/>
                </xsl:call-template>
            </xsl:if>
        </xsl:for-each>
        <xsl:for-each select="*:subfield[@code='a']">
            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:title.series.preceding.alternative'"/><xsl:with-param name="value" select="text()"/><xsl:with-param name="refines" select="$series-preceding-id"/></xsl:call-template>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="*:datafield[@tag='785']">
        <xsl:choose>
            <xsl:when test="exists(preceding-sibling::*:datafield[@tag='785'])">
                <!-- ignore everything but the first one; everything is processed in xsl:otherwise -->
            </xsl:when>
            <xsl:otherwise>
                <xsl:for-each select="../*:datafield[@tag='785']">
                    <xsl:sort select="*:subfield[@code='w'][1]/text()"/>
                    <xsl:call-template name="tag785">
                        <xsl:with-param name="position" select="string(position())"/>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="tag785">
        <xsl:param name="position" as="xs:string"/>
        
        <xsl:variable name="series-sequel-id" select="concat('series-sequel-', $position)"/>

        <xsl:for-each select="*:subfield[@code='t']">
            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:title.series.sequel'"/><xsl:with-param name="value" select="text()"/><xsl:with-param name="id" select="$series-sequel-id"/></xsl:call-template>
        </xsl:for-each>
        <xsl:for-each select="*:subfield[@code='w']">
            <xsl:variable name="identifier" select="replace(replace(text(), '\([^)]*\)', ''), '\s', '')"/>
            <xsl:if test="matches($identifier, '^\d+$')">
                <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:identifier.series.sequel.uri'"/><xsl:with-param name="value" select="concat('urn:NBN:no-nb_nlb_',$identifier)"/><xsl:with-param name="refines" select="$series-sequel-id"/></xsl:call-template>
                <xsl:call-template name="meta">
                    <xsl:with-param name="property" select="'dc:identifier.series.sequel'"/>
                    <xsl:with-param name="value" select="$identifier"/>
                    <xsl:with-param name="id" select="if (not(count(parent::*/*:subfield[@code='t']))) then $series-sequel-id else ()"/>
                    <xsl:with-param name="refines" select="if (count(parent::*/*:subfield[@code='t'])) then $series-sequel-id else ()"/>
                </xsl:call-template>
            </xsl:if>
        </xsl:for-each>
        <xsl:for-each select="*:subfield[@code='a']">
            <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:title.series.sequel.alternative'"/><xsl:with-param name="value" select="text()"/><xsl:with-param name="refines" select="$series-sequel-id"/></xsl:call-template>
        </xsl:for-each>
    </xsl:template>

    <!-- 800 - 830 SERIEINNFØRSLER - ANNEN FORM ENN SERIEFELTET -->

    <xsl:template match="*:datafield[@tag='800']">
        <xsl:variable name="creator-id" select="concat('series-creator-',1+count(preceding-sibling::*:datafield[@tag='800']))"/>
        <xsl:variable name="name" select="(*:subfield[@code='a'], *:subfield[@code='q'], *:subfield[@code='w'])[normalize-space(.)][1]/text()"/>

        <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:creator.series'"/><xsl:with-param name="value" select="$name"/><xsl:with-param name="id" select="$creator-id"/></xsl:call-template>

        <xsl:for-each select="*:subfield[@code='t']">
            <xsl:variable name="alternate-title" select="string((../../*:datafield[@tag='490']/*:subfield[@code='a'])[1]/text()) != (text(),'')"/>
            <xsl:call-template name="meta"><xsl:with-param name="property" select="concat('dc:title.series',if ($alternate-title or preceding-sibling::*[@code='t']) then '.alternate' else '','')"/><xsl:with-param name="value" select="text()"/></xsl:call-template>
        </xsl:for-each>

        <xsl:for-each select="*:subfield[@code='b']">
            <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('honorificSuffix')"/><xsl:with-param name="value" select="text()"/><xsl:with-param name="refines" select="$creator-id"/></xsl:call-template>
        </xsl:for-each>

        <xsl:for-each select="*:subfield[@code='c']">
            <xsl:choose>
                <xsl:when test="matches(text(), $PSEUDONYM)">
                    <xsl:variable name="pseudonym" select="replace(text(), $PSEUDONYM_REPLACE, '$1')"/>
                    <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('pseudonym')"/><xsl:with-param name="value" select="$pseudonym"/><xsl:with-param name="refines" select="$creator-id"/></xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('honorificPrefix')"/><xsl:with-param name="value" select="text()"/><xsl:with-param name="refines" select="$creator-id"/></xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:for-each select="*:subfield[@code='d']">
            <xsl:variable name="birthDeath" select="tokenize(nlb:parseBirthDeath(text()), ',')"/>
            <xsl:if test="$birthDeath[1]">
                <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('birthDate')"/><xsl:with-param name="value" select="$birthDeath[1]"/><xsl:with-param name="refines" select="$creator-id"/></xsl:call-template>
            </xsl:if>
            <xsl:if test="$birthDeath[2]">
                <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('deathDate')"/><xsl:with-param name="value" select="$birthDeath[2]"/><xsl:with-param name="refines" select="$creator-id"/></xsl:call-template>
            </xsl:if>
        </xsl:for-each>

        <xsl:call-template name="nationality">
            <xsl:with-param name="refines" select="$creator-id"/>
        </xsl:call-template>

        <xsl:call-template name="bibliofil-id">
            <xsl:with-param name="context" select="."/>
            <xsl:with-param name="refines" select="$creator-id"/>
        </xsl:call-template>
    </xsl:template>

    <!-- 85X LOKALISERINGSDATA -->

    <xsl:template match="*:datafield[@tag='850']">
        <xsl:for-each select="*:subfield[@code='a']">
            <xsl:if test="text()=('NLB/S', 'Tibi/S')">
                <xsl:call-template name="meta"><xsl:with-param name="property" select="'dc:type.genre'"/><xsl:with-param name="value" select="'Textbook'"/></xsl:call-template>
                <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('educationalUse')"/><xsl:with-param name="value" select="'true'"/></xsl:call-template>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="*:datafield[@tag='856']">
        <xsl:if test="*:subfield[@code='s' and matches(text(), '\d+')]">
            <xsl:for-each select="*:subfield[@code='s' and matches(text(), '^\d+$')]">
                <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('fileSize')"/><xsl:with-param name="value" select="text()"/></xsl:call-template>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>

    <!-- 9XX HENVISNINGER -->
    <xsl:template match="*:datafield[@tag=('900','950')]">
        <xsl:variable name="preceding-datafield" select="(preceding-sibling::* except preceding-sibling::*:datafield[starts-with(@tag,'9')])[last()]"/>
        <xsl:variable name="preceding-datafield-refines" as="element()*">
            <xsl:apply-templates select="$preceding-datafield"/>
        </xsl:variable>
        <xsl:variable name="preceding-datafield-refines" as="xs:string" select="string(($preceding-datafield-refines[@property='bibliofil-id']/@refines)[1])"/>
        <xsl:if test="$preceding-datafield-refines">
            <xsl:for-each select="*:subfield[@code='~']">
                <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('bibliofil-id.reference')"/><xsl:with-param name="value" select="text()"/><xsl:with-param name="refines" select="$preceding-datafield-refines"/></xsl:call-template>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>

    <!-- TODO: 911c and 911d (TIGAR project) -->

    <xsl:template match="*:datafield[@tag='996']">
        <xsl:variable name="websok-id" select="concat('websok-',1+count(preceding-sibling::*:datafield[@tag='996']))"/>

        <xsl:if test="*:subfield[@code='u']">
            <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('websok.url')"/><xsl:with-param name="value" select="*:subfield[@code='u']/text()"/><xsl:with-param name="id" select="$websok-id"/></xsl:call-template>

            <xsl:for-each select="*:subfield[@code='t']">
                <xsl:call-template name="meta"><xsl:with-param name="property" select="nlb:prefixed-property('websok.type')"/><xsl:with-param name="value" select="text()"/><xsl:with-param name="refines" select="$websok-id"/></xsl:call-template>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="nationality">
        <xsl:param name="refines" as="xs:string"/>
        <xsl:variable name="context" select="." as="element()"/>
        
        <!-- find all referenced *386 datafields -->
        <xsl:variable name="nationalities" as="element()*">
            <xsl:for-each select="*:subfield[@code = ('0', '6', 'g')]">
                <xsl:variable name="identifier" select="text()"/>
                <xsl:sequence select="../../*:datafield[@tag='386' and *:subfield[@code='m']/text() = 'Nasjonalitet/regional gruppe' and *:subfield[@code='0']/text() = $identifier]"/>
            </xsl:for-each>
        </xsl:variable>
        
        <!-- parse all nationalities -->
        <!-- note that we also support the Normarc syntax for nationalities which uses $j. This is a workaround needed to be able to import from the authority registry in our datawarehouse. -->
        <xsl:variable name="nationalities" as="element()*">
            <xsl:for-each select="$nationalities/*:subfield[@code='b'] | $context/*:subfield[@code='j']">
                <xsl:variable name="context" select="."/>
                <xsl:for-each select="tokenize(replace(text(),'[\.,? ]',''), '-')">
                    <xsl:variable name="nationality" select="nlb:parseNationality(.)"/>
                    <xsl:if test="$nationality != ''">
                        <xsl:call-template name="meta">
                            <xsl:with-param name="property" select="nlb:prefixed-property('nationality')"/>
                            <xsl:with-param name="value" select="$nationality"/>
                            <xsl:with-param name="refines" select="$refines"/>
                            <xsl:with-param name="context" select="$context"/>
                        </xsl:call-template>
                    </xsl:if>
                </xsl:for-each>
            </xsl:for-each>
        </xsl:variable>
        
        <!-- avoid duplicate nationalities -->
        <xsl:for-each select="1 to count($nationalities)">
            <xsl:variable name="position" select="."/>
            <xsl:if test="not($nationalities[$position]/text() = $nationalities[position() lt $position]/text())">
                <xsl:sequence select="$nationalities[$position]"/>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>

    <xsl:variable name="DAY_MONTH_YEAR" select="'\d+-\d+-\d+'"/>
    <xsl:variable name="FORMAT_245H_DAISY2_1" select="'(?i).*da[i\ss][si]y[\.\s]*.*'"/>
    <xsl:variable name="FORMAT_245H_DAISY2_2" select="'.*2[.\s]*0?2.*'"/>
    <xsl:variable name="FORMAT_245H_DTBOOK" select="'(?i).*dtbook.*'"/>
    <xsl:variable name="PSEUDONYM" select="'pse[uv]d.*'"/>
    <xsl:variable name="PSEUDONYM_REPLACE" select="'pse[uv]d.*?f.*?\s+(.*)$'"/>
    <xsl:variable name="FIRST_LAST_NAME" select="'^(.*\S.*)\s+(\S+)\s*$'"/>
    <xsl:variable name="YEAR" select="'.*[^\d-].*'"/>
    <xsl:variable name="YEAR_NEGATIVE" select="'.*f.*(Kr.*)?'"/>
    <xsl:variable name="YEAR_VALUE" select="'[^\d]'"/>
    <xsl:variable name="AVAILABLE" select="'^.*?(\d+)[\./]+(\d+)[\./]+(\d+).*?$'"/>
    <xsl:variable name="ISO_DATE" select="'^\d\d\d\d-\d\d-\d\d$'"/>

    <xsl:function name="nlb:parseNationality">
        <xsl:param name="nationality"/>
        <xsl:choose>
            <xsl:when test="$nationality='somal'">
                <xsl:sequence select="'so'"/>
            </xsl:when>
            <xsl:when test="$nationality='ned'">
                <xsl:sequence select="'nl'"/>
            </xsl:when>
            <xsl:when test="$nationality='am'">
                <xsl:sequence select="'us'"/>
            </xsl:when>
            <xsl:when test="$nationality='liban'">
                <xsl:sequence select="'lb'"/>
            </xsl:when>
            <xsl:when test="$nationality='skzimb'">
                <xsl:sequence select="'sw'"/>
            </xsl:when>
            <xsl:when test="$nationality='pal'">
                <xsl:sequence select="'ps'"/>
            </xsl:when>
            <xsl:when test="$nationality='kongol'">
                <xsl:sequence select="'cd'"/>
            </xsl:when>
            <xsl:when test="$nationality='som'">
                <xsl:sequence select="'so'"/>
            </xsl:when>
            <xsl:when test="$nationality='n'">
                <xsl:sequence select="'no'"/>
            </xsl:when>
            <xsl:when test="$nationality='bulg'">
                <xsl:sequence select="'bg'"/>
            </xsl:when>
            <xsl:when test="$nationality='kan'">
                <xsl:sequence select="'ca'"/>
            </xsl:when>
            <xsl:when test="$nationality='eng'">
                <xsl:sequence select="'gb'"/>
            </xsl:when>
            <xsl:when test="$nationality='ind'">
                <xsl:sequence select="'in'"/>
            </xsl:when>
            <xsl:when test="$nationality='sv'">
                <xsl:sequence select="'se'"/>
            </xsl:when>
            <xsl:when test="$nationality='newzeal'">
                <xsl:sequence select="'nz'"/>
            </xsl:when>
            <xsl:when test="$nationality='pol'">
                <xsl:sequence select="'pl'"/>
            </xsl:when>
            <xsl:when test="$nationality='gr'">
                <xsl:sequence select="'gr'"/>
            </xsl:when>
            <xsl:when test="$nationality='fr'">
                <xsl:sequence select="'fr'"/>
            </xsl:when>
            <xsl:when test="$nationality='belg'">
                <xsl:sequence select="'be'"/>
            </xsl:when>
            <xsl:when test="$nationality='ir'">
                <xsl:sequence select="'ie'"/>
            </xsl:when>
            <xsl:when test="$nationality='columb'">
                <xsl:sequence select="'co'"/>
            </xsl:when>
            <xsl:when test="$nationality='r'">
                <xsl:sequence select="'ru'"/>
            </xsl:when>
            <xsl:when test="$nationality='øst'">
                <xsl:sequence select="'at'"/>
            </xsl:when>
            <xsl:when test="$nationality='sveit'">
                <xsl:sequence select="'ch'"/>
            </xsl:when>
            <xsl:when test="$nationality='tyrk'">
                <xsl:sequence select="'tr'"/>
            </xsl:when>
            <xsl:when test="$nationality='aserb'">
                <xsl:sequence select="'az'"/>
            </xsl:when>
            <xsl:when test="$nationality='t'">
                <xsl:sequence select="'de'"/>
            </xsl:when>
            <xsl:when test="$nationality='pak'">
                <xsl:sequence select="'pk'"/>
            </xsl:when>
            <xsl:when test="$nationality='iran'">
                <xsl:sequence select="'ir'"/>
            </xsl:when>
            <xsl:when test="$nationality='rwand'">
                <xsl:sequence select="'rw'"/>
            </xsl:when>
            <xsl:when test="$nationality='sudan'">
                <xsl:sequence select="'sd'"/>
            </xsl:when>
            <xsl:when test="$nationality='zimb'">
                <xsl:sequence select="'zw'"/>
            </xsl:when>
            <xsl:when test="$nationality='liby'">
                <xsl:sequence select="'ly'"/>
            </xsl:when>
            <xsl:when test="$nationality='rus'">
                <xsl:sequence select="'ru'"/>
            </xsl:when>
            <xsl:when test="$nationality='russ'">
                <xsl:sequence select="'ru'"/>
            </xsl:when>
            <xsl:when test="$nationality='ukr'">
                <xsl:sequence select="'ua'"/>
            </xsl:when>
            <xsl:when test="$nationality='br'">
                <xsl:sequence select="'br'"/>
            </xsl:when>
            <xsl:when test="$nationality='burm'">
                <xsl:sequence select="'mm'"/>
            </xsl:when>
            <xsl:when test="$nationality='d'">
                <xsl:sequence select="'dk'"/>
            </xsl:when>
            <xsl:when test="$nationality='bosn'">
                <xsl:sequence select="'ba'"/>
            </xsl:when>
            <xsl:when test="$nationality='kin'">
                <xsl:sequence select="'cn'"/>
            </xsl:when>
            <xsl:when test="$nationality='togo'">
                <xsl:sequence select="'tg'"/>
            </xsl:when>
            <xsl:when test="$nationality='bangl'">
                <xsl:sequence select="'bd'"/>
            </xsl:when>
            <xsl:when test="$nationality='indon'">
                <xsl:sequence select="'id'"/>
            </xsl:when>
            <xsl:when test="$nationality='fi'">
                <xsl:sequence select="'fi'"/>
            </xsl:when>
            <xsl:when test="$nationality='isl'">
                <xsl:sequence select="'is'"/>
            </xsl:when>
            <xsl:when test="$nationality='ugand'">
                <xsl:sequence select="'ug'"/>
            </xsl:when>
            <xsl:when test="$nationality='malay'">
                <xsl:sequence select="'my'"/>
            </xsl:when>
            <xsl:when test="$nationality='tanz'">
                <xsl:sequence select="'tz'"/>
            </xsl:when>
            <xsl:when test="$nationality='hait'">
                <xsl:sequence select="'ht'"/>
            </xsl:when>
            <xsl:when test="$nationality='irak'">
                <xsl:sequence select="'iq'"/>
            </xsl:when>
            <xsl:when test="$nationality='am'">
                <xsl:sequence select="'us'"/>
            </xsl:when>
            <xsl:when test="$nationality='viet'">
                <xsl:sequence select="'vn'"/>
            </xsl:when>
            <xsl:when test="$nationality='eng'">
                <xsl:sequence select="'gb'"/>
            </xsl:when>
            <xsl:when test="$nationality='portug'">
                <xsl:sequence select="'pt'"/>
            </xsl:when>
            <xsl:when test="$nationality='dominik'">
                <xsl:sequence select="'do'"/>
            </xsl:when>
            <xsl:when test="$nationality='marok'">
                <xsl:sequence select="'ma'"/>
            </xsl:when>
            <xsl:when test="$nationality='indian'">
                <xsl:sequence select="'in'"/>
            </xsl:when>
            <xsl:when test="$nationality='alb'">
                <xsl:sequence select="'al'"/>
            </xsl:when>
            <xsl:when test="$nationality='syr'">
                <xsl:sequence select="'sy'"/>
            </xsl:when>
            <xsl:when test="$nationality='afg'">
                <xsl:sequence select="'af'"/>
            </xsl:when>
            <xsl:when test="$nationality='trinid'">
                <xsl:sequence select="'tt'"/>
            </xsl:when>
            <xsl:when test="$nationality='est'">
                <xsl:sequence select="'ee'"/>
            </xsl:when>
            <xsl:when test="$nationality='guadel'">
                <xsl:sequence select="'gp'"/>
            </xsl:when>
            <xsl:when test="$nationality='mex'">
                <xsl:sequence select="'mx'"/>
            </xsl:when>
            <xsl:when test="$nationality='egypt'">
                <xsl:sequence select="'eg'"/>
            </xsl:when>
            <xsl:when test="$nationality='chil'">
                <xsl:sequence select="'cl'"/>
            </xsl:when>
            <xsl:when test="$nationality='colomb'">
                <xsl:sequence select="'co'"/>
            </xsl:when>
            <xsl:when test="$nationality='lit'">
                <xsl:sequence select="'lt'"/>
            </xsl:when>
            <xsl:when test="$nationality='sam'">
                <xsl:sequence select="'ws'"/>
            </xsl:when>
            <xsl:when test="$nationality='guatem'">
                <xsl:sequence select="'gt'"/>
            </xsl:when>
            <xsl:when test="$nationality='kor'">
                <xsl:sequence select="'kr'"/>
            </xsl:when>
            <xsl:when test="$nationality='ung'">
                <xsl:sequence select="'hu'"/>
            </xsl:when>
            <xsl:when test="$nationality='rum'">
                <xsl:sequence select="'ro'"/>
            </xsl:when>
            <xsl:when test="$nationality='niger'">
                <xsl:sequence select="'ne'"/>
            </xsl:when>
            <xsl:when test="$nationality='tsj'">
                <xsl:sequence select="'cz'"/>
            </xsl:when>
            <xsl:when test="$nationality='fær'">
                <xsl:sequence select="'fo'"/>
            </xsl:when>
            <xsl:when test="$nationality='jug'">
                <xsl:sequence select="'mk'"/>
            </xsl:when>
            <xsl:when test="$nationality='urug'">
                <xsl:sequence select="'uy'"/>
            </xsl:when>
            <xsl:when test="$nationality='cub'">
                <xsl:sequence select="'cu'"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="$nationality"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="nlb:parseRole">
        <xsl:param name="role"/>
        <!--
            Note: based on MARC relators
		    (http://lcweb2.loc.gov/diglib/loc.terms/relators/dc-contributor.html)
        -->
        <xsl:variable name="role" select="lower-case($role)"/>

        <xsl:choose>
            <!-- handle all MARC relators from https://www.loc.gov/marc/relators/relaterm.html -->
            <xsl:when test="$role = 'exp'"><xsl:value-of select="'dc:contributor.expert'"/></xsl:when>
            <xsl:when test="$role = 'abr'"><xsl:value-of select="'dc:contributor.abridger'"/></xsl:when>
            <xsl:when test="$role = 'act'"><xsl:value-of select="'dc:contributor.actor'"/></xsl:when>
            <xsl:when test="$role = 'adp'"><xsl:value-of select="'dc:contributor.adapter'"/></xsl:when>
            <xsl:when test="$role = 'rcp'"><xsl:value-of select="'dc:contributor.addressee'"/></xsl:when>
            <xsl:when test="$role = 'anl'"><xsl:value-of select="'dc:contributor.analyst'"/></xsl:when>
            <xsl:when test="$role = 'anm'"><xsl:value-of select="'dc:contributor.animator'"/></xsl:when>
            <xsl:when test="$role = 'ann'"><xsl:value-of select="'dc:contributor.annotator'"/></xsl:when>
            <xsl:when test="$role = 'apl'"><xsl:value-of select="'dc:contributor.appellant'"/></xsl:when>
            <xsl:when test="$role = 'ape'"><xsl:value-of select="'dc:contributor.appellee'"/></xsl:when>
            <xsl:when test="$role = 'app'"><xsl:value-of select="'dc:contributor.applicant'"/></xsl:when>
            <xsl:when test="$role = 'arc'"><xsl:value-of select="'dc:contributor.architect'"/></xsl:when>
            <xsl:when test="$role = 'arr'"><xsl:value-of select="'dc:contributor.arranger'"/></xsl:when>
            <xsl:when test="$role = 'acp'"><xsl:value-of select="'dc:contributor.art-copyist'"/></xsl:when>
            <xsl:when test="$role = 'adi'"><xsl:value-of select="'dc:contributor.art-director'"/></xsl:when>
            <xsl:when test="$role = 'art'"><xsl:value-of select="'dc:contributor.artist'"/></xsl:when>
            <xsl:when test="$role = 'ard'"><xsl:value-of select="'dc:contributor.artistic-director'"/></xsl:when>
            <xsl:when test="$role = 'asg'"><xsl:value-of select="'dc:contributor.assignee'"/></xsl:when>
            <xsl:when test="$role = 'asn'"><xsl:value-of select="'dc:contributor.associated-name'"/></xsl:when>
            <xsl:when test="$role = 'att'"><xsl:value-of select="'dc:contributor.attributed-name'"/></xsl:when>
            <xsl:when test="$role = 'auc'"><xsl:value-of select="'dc:contributor.auctioneer'"/></xsl:when>
            <xsl:when test="$role = 'aut'"><xsl:value-of select="'dc:creator'"/></xsl:when>
            <xsl:when test="$role = 'aqt'"><xsl:value-of select="'dc:contributor.quotations-or-text-abstracts'"/></xsl:when>
            <xsl:when test="$role = 'aft'"><xsl:value-of select="'dc:contributor.afterword'"/></xsl:when>
            <xsl:when test="$role = 'aud'"><xsl:value-of select="'dc:contributor.dialog'"/></xsl:when>
            <xsl:when test="$role = 'aui'"><xsl:value-of select="'dc:contributor.foreword'"/></xsl:when>
            <xsl:when test="$role = 'ato'"><xsl:value-of select="'dc:contributor.autographer'"/></xsl:when>
            <xsl:when test="$role = 'ant'"><xsl:value-of select="'dc:contributor.bibliographic-antecedent'"/></xsl:when>
            <xsl:when test="$role = 'bnd'"><xsl:value-of select="'dc:contributor.binder'"/></xsl:when>
            <xsl:when test="$role = 'bdd'"><xsl:value-of select="'dc:contributor.binding-designer'"/></xsl:when>
            <xsl:when test="$role = 'blw'"><xsl:value-of select="'dc:contributor.blurb-writer'"/></xsl:when>
            <xsl:when test="$role = 'bkd'"><xsl:value-of select="'dc:contributor.book-designer'"/></xsl:when>
            <xsl:when test="$role = 'bkp'"><xsl:value-of select="'dc:contributor.book-producer'"/></xsl:when>
            <xsl:when test="$role = 'bjd'"><xsl:value-of select="'dc:contributor.bookjacket-designer'"/></xsl:when>
            <xsl:when test="$role = 'bpd'"><xsl:value-of select="'dc:contributor.bookplate-designer'"/></xsl:when>
            <xsl:when test="$role = 'bsl'"><xsl:value-of select="'dc:contributor.bookseller'"/></xsl:when>
            <xsl:when test="$role = 'brl'"><xsl:value-of select="'dc:contributor.braille-embosser'"/></xsl:when>
            <xsl:when test="$role = 'brd'"><xsl:value-of select="'dc:contributor.broadcaster'"/></xsl:when>
            <xsl:when test="$role = 'cll'"><xsl:value-of select="'dc:contributor.calligrapher'"/></xsl:when>
            <xsl:when test="$role = 'ctg'"><xsl:value-of select="'dc:contributor.cartographer'"/></xsl:when>
            <xsl:when test="$role = 'cas'"><xsl:value-of select="'dc:contributor.caster'"/></xsl:when>
            <xsl:when test="$role = 'cns'"><xsl:value-of select="'dc:contributor.censor'"/></xsl:when>
            <xsl:when test="$role = 'chr'"><xsl:value-of select="'dc:contributor.choreographer'"/></xsl:when>
            <xsl:when test="$role = 'cng'"><xsl:value-of select="'dc:contributor.cinematographer'"/></xsl:when>
            <xsl:when test="$role = 'cli'"><xsl:value-of select="'dc:contributor.client'"/></xsl:when>
            <xsl:when test="$role = 'cor'"><xsl:value-of select="'dc:contributor.collection-registrar'"/></xsl:when>
            <xsl:when test="$role = 'col'"><xsl:value-of select="'dc:contributor.collector'"/></xsl:when>
            <xsl:when test="$role = 'clt'"><xsl:value-of select="'dc:contributor.collotyper'"/></xsl:when>
            <xsl:when test="$role = 'clr'"><xsl:value-of select="'dc:contributor.colorist'"/></xsl:when>
            <xsl:when test="$role = 'cmm'"><xsl:value-of select="'dc:contributor.commentator'"/></xsl:when>
            <xsl:when test="$role = 'cwt'"><xsl:value-of select="'dc:contributor.commentator-for-written-text'"/></xsl:when>
            <xsl:when test="$role = 'com'"><xsl:value-of select="'dc:contributor.compiler'"/></xsl:when>
            <xsl:when test="$role = 'cpl'"><xsl:value-of select="'dc:contributor.complainant'"/></xsl:when>
            <xsl:when test="$role = 'cpt'"><xsl:value-of select="'dc:contributor.complainant-appellant'"/></xsl:when>
            <xsl:when test="$role = 'cpe'"><xsl:value-of select="'dc:contributor.complainant-appellee'"/></xsl:when>
            <xsl:when test="$role = 'cmp'"><xsl:value-of select="'dc:contributor.composer'"/></xsl:when>
            <xsl:when test="$role = 'cmt'"><xsl:value-of select="'dc:contributor.compositor'"/></xsl:when>
            <xsl:when test="$role = 'ccp'"><xsl:value-of select="'dc:contributor.conceptor'"/></xsl:when>
            <xsl:when test="$role = 'cnd'"><xsl:value-of select="'dc:contributor.conductor'"/></xsl:when>
            <xsl:when test="$role = 'con'"><xsl:value-of select="'dc:contributor.conservator'"/></xsl:when>
            <xsl:when test="$role = 'csl'"><xsl:value-of select="'dc:contributor.consultant'"/></xsl:when>
            <xsl:when test="$role = 'csp'"><xsl:value-of select="'dc:contributor.consultant-to-a-project'"/></xsl:when>
            <xsl:when test="$role = 'cos'"><xsl:value-of select="'dc:contributor.contestant'"/></xsl:when>
            <xsl:when test="$role = 'cot'"><xsl:value-of select="'dc:contributor.contestant-appellant'"/></xsl:when>
            <xsl:when test="$role = 'coe'"><xsl:value-of select="'dc:contributor.contestant-appellee'"/></xsl:when>
            <xsl:when test="$role = 'cts'"><xsl:value-of select="'dc:contributor.contestee'"/></xsl:when>
            <xsl:when test="$role = 'ctt'"><xsl:value-of select="'dc:contributor.contestee-appellant'"/></xsl:when>
            <xsl:when test="$role = 'cte'"><xsl:value-of select="'dc:contributor.contestee-appellee'"/></xsl:when>
            <xsl:when test="$role = 'ctr'"><xsl:value-of select="'dc:contributor.contractor'"/></xsl:when>
            <xsl:when test="$role = 'ctb'"><xsl:value-of select="'dc:contributor.contributor'"/></xsl:when>
            <xsl:when test="$role = 'cpc'"><xsl:value-of select="'dc:contributor.copyright-claimant'"/></xsl:when>
            <xsl:when test="$role = 'cph'"><xsl:value-of select="'dc:contributor.copyright-holder'"/></xsl:when>
            <xsl:when test="$role = 'crr'"><xsl:value-of select="'dc:contributor.corrector'"/></xsl:when>
            <xsl:when test="$role = 'crp'"><xsl:value-of select="'dc:contributor.correspondent'"/></xsl:when>
            <xsl:when test="$role = 'cst'"><xsl:value-of select="'dc:contributor.costume-designer'"/></xsl:when>
            <xsl:when test="$role = 'cou'"><xsl:value-of select="'dc:contributor.court-governed'"/></xsl:when>
            <xsl:when test="$role = 'crt'"><xsl:value-of select="'dc:contributor.court-reporter'"/></xsl:when>
            <xsl:when test="$role = 'cov'"><xsl:value-of select="'dc:contributor.cover-designer'"/></xsl:when>
            <xsl:when test="$role = 'cre'"><xsl:value-of select="'dc:contributor.creator'"/></xsl:when>
            <xsl:when test="$role = 'cur'"><xsl:value-of select="'dc:contributor.curator'"/></xsl:when>
            <xsl:when test="$role = 'dnc'"><xsl:value-of select="'dc:contributor.dancer'"/></xsl:when>
            <xsl:when test="$role = 'dtc'"><xsl:value-of select="'dc:contributor.data-contributor'"/></xsl:when>
            <xsl:when test="$role = 'dtm'"><xsl:value-of select="'dc:contributor.data-manager'"/></xsl:when>
            <xsl:when test="$role = 'dte'"><xsl:value-of select="'dc:contributor.dedicatee'"/></xsl:when>
            <xsl:when test="$role = 'dto'"><xsl:value-of select="'dc:contributor.dedicator'"/></xsl:when>
            <xsl:when test="$role = 'dfd'"><xsl:value-of select="'dc:contributor.defendant'"/></xsl:when>
            <xsl:when test="$role = 'dft'"><xsl:value-of select="'dc:contributor.defendant-appellant'"/></xsl:when>
            <xsl:when test="$role = 'dfe'"><xsl:value-of select="'dc:contributor.defendant-appellee'"/></xsl:when>
            <xsl:when test="$role = 'dgc'"><xsl:value-of select="'dc:contributor.degree-committee-member'"/></xsl:when>
            <xsl:when test="$role = 'dgg'"><xsl:value-of select="'dc:contributor.degree-granting-institution'"/></xsl:when>
            <xsl:when test="$role = 'dgs'"><xsl:value-of select="'dc:contributor.degree-supervisor'"/></xsl:when>
            <xsl:when test="$role = 'dln'"><xsl:value-of select="'dc:contributor.delineator'"/></xsl:when>
            <xsl:when test="$role = 'dpc'"><xsl:value-of select="'dc:contributor.depicted'"/></xsl:when>
            <xsl:when test="$role = 'dpt'"><xsl:value-of select="'dc:contributor.depositor'"/></xsl:when>
            <xsl:when test="$role = 'dsr'"><xsl:value-of select="'dc:contributor.designer'"/></xsl:when>
            <xsl:when test="$role = 'drt'"><xsl:value-of select="'dc:contributor.director'"/></xsl:when>
            <xsl:when test="$role = 'dis'"><xsl:value-of select="'dc:contributor.dissertant'"/></xsl:when>
            <xsl:when test="$role = 'dbp'"><xsl:value-of select="'dc:contributor.distribution-place'"/></xsl:when>
            <xsl:when test="$role = 'dst'"><xsl:value-of select="'dc:contributor.distributor'"/></xsl:when>
            <xsl:when test="$role = 'dnr'"><xsl:value-of select="'dc:contributor.donor'"/></xsl:when>
            <xsl:when test="$role = 'drm'"><xsl:value-of select="'dc:contributor.draftsman'"/></xsl:when>
            <xsl:when test="$role = 'dub'"><xsl:value-of select="'dc:contributor.dubious-author'"/></xsl:when>
            <xsl:when test="$role = 'edt'"><xsl:value-of select="'dc:contributor.editor'"/></xsl:when>
            <xsl:when test="$role = 'edc'"><xsl:value-of select="'dc:contributor.editor-of-compilation'"/></xsl:when>
            <xsl:when test="$role = 'edm'"><xsl:value-of select="'dc:contributor.editor-of-moving-image-work'"/></xsl:when>
            <xsl:when test="$role = 'elg'"><xsl:value-of select="'dc:contributor.electrician'"/></xsl:when>
            <xsl:when test="$role = 'elt'"><xsl:value-of select="'dc:contributor.electrotyper'"/></xsl:when>
            <xsl:when test="$role = 'enj'"><xsl:value-of select="'dc:contributor.enacting-jurisdiction'"/></xsl:when>
            <xsl:when test="$role = 'eng'"><xsl:value-of select="'dc:contributor.engineer'"/></xsl:when>
            <xsl:when test="$role = 'egr'"><xsl:value-of select="'dc:contributor.engraver'"/></xsl:when>
            <xsl:when test="$role = 'etr'"><xsl:value-of select="'dc:contributor.etcher'"/></xsl:when>
            <xsl:when test="$role = 'evp'"><xsl:value-of select="'dc:contributor.event-place'"/></xsl:when>
            <xsl:when test="$role = 'exp'"><xsl:value-of select="'dc:contributor.expert'"/></xsl:when>
            <xsl:when test="$role = 'fac'"><xsl:value-of select="'dc:contributor.facsimilist'"/></xsl:when>
            <xsl:when test="$role = 'fld'"><xsl:value-of select="'dc:contributor.field-director'"/></xsl:when>
            <xsl:when test="$role = 'fmd'"><xsl:value-of select="'dc:contributor.film-director'"/></xsl:when>
            <xsl:when test="$role = 'fds'"><xsl:value-of select="'dc:contributor.film-distributor'"/></xsl:when>
            <xsl:when test="$role = 'flm'"><xsl:value-of select="'dc:contributor.film-editor'"/></xsl:when>
            <xsl:when test="$role = 'fmp'"><xsl:value-of select="'dc:contributor.film-producer'"/></xsl:when>
            <xsl:when test="$role = 'fmk'"><xsl:value-of select="'dc:contributor.filmmaker'"/></xsl:when>
            <xsl:when test="$role = 'fpy'"><xsl:value-of select="'dc:contributor.first-party'"/></xsl:when>
            <xsl:when test="$role = 'frg'"><xsl:value-of select="'dc:contributor.forger'"/></xsl:when>
            <xsl:when test="$role = 'fmo'"><xsl:value-of select="'dc:contributor.former-owner'"/></xsl:when>
            <xsl:when test="$role = 'fnd'"><xsl:value-of select="'dc:contributor.funder'"/></xsl:when>
            <xsl:when test="$role = 'gis'"><xsl:value-of select="'dc:contributor.geographic-information-specialist'"/></xsl:when>
            <xsl:when test="$role = 'hnr'"><xsl:value-of select="'dc:contributor.honoree'"/></xsl:when>
            <xsl:when test="$role = 'hst'"><xsl:value-of select="'dc:contributor.host'"/></xsl:when>
            <xsl:when test="$role = 'his'"><xsl:value-of select="'dc:contributor.host-institution'"/></xsl:when>
            <xsl:when test="$role = 'ilu'"><xsl:value-of select="'dc:contributor.illuminator'"/></xsl:when>
            <xsl:when test="$role = 'ill'"><xsl:value-of select="'dc:contributor.illustrator'"/></xsl:when>
            <xsl:when test="$role = 'ins'"><xsl:value-of select="'dc:contributor.inscriber'"/></xsl:when>
            <xsl:when test="$role = 'itr'"><xsl:value-of select="'dc:contributor.instrumentalist'"/></xsl:when>
            <xsl:when test="$role = 'ive'"><xsl:value-of select="'dc:contributor.interviewee'"/></xsl:when>
            <xsl:when test="$role = 'ivr'"><xsl:value-of select="'dc:contributor.interviewer'"/></xsl:when>
            <xsl:when test="$role = 'inv'"><xsl:value-of select="'dc:contributor.inventor'"/></xsl:when>
            <xsl:when test="$role = 'isb'"><xsl:value-of select="'dc:contributor.issuing-body'"/></xsl:when>
            <xsl:when test="$role = 'jud'"><xsl:value-of select="'dc:contributor.judge'"/></xsl:when>
            <xsl:when test="$role = 'jug'"><xsl:value-of select="'dc:contributor.jurisdiction-governed'"/></xsl:when>
            <xsl:when test="$role = 'lbr'"><xsl:value-of select="'dc:contributor.laboratory'"/></xsl:when>
            <xsl:when test="$role = 'ldr'"><xsl:value-of select="'dc:contributor.laboratory-director'"/></xsl:when>
            <xsl:when test="$role = 'lsa'"><xsl:value-of select="'dc:contributor.landscape-architect'"/></xsl:when>
            <xsl:when test="$role = 'led'"><xsl:value-of select="'dc:contributor.lead'"/></xsl:when>
            <xsl:when test="$role = 'len'"><xsl:value-of select="'dc:contributor.lender'"/></xsl:when>
            <xsl:when test="$role = 'lil'"><xsl:value-of select="'dc:contributor.libelant'"/></xsl:when>
            <xsl:when test="$role = 'lit'"><xsl:value-of select="'dc:contributor.libelant-appellant'"/></xsl:when>
            <xsl:when test="$role = 'lie'"><xsl:value-of select="'dc:contributor.libelant-appellee'"/></xsl:when>
            <xsl:when test="$role = 'lel'"><xsl:value-of select="'dc:contributor.libelee'"/></xsl:when>
            <xsl:when test="$role = 'let'"><xsl:value-of select="'dc:contributor.libelee-appellant'"/></xsl:when>
            <xsl:when test="$role = 'lee'"><xsl:value-of select="'dc:contributor.libelee-appellee'"/></xsl:when>
            <xsl:when test="$role = 'lbt'"><xsl:value-of select="'dc:contributor.librettist'"/></xsl:when>
            <xsl:when test="$role = 'lse'"><xsl:value-of select="'dc:contributor.licensee'"/></xsl:when>
            <xsl:when test="$role = 'lso'"><xsl:value-of select="'dc:contributor.licensor'"/></xsl:when>
            <xsl:when test="$role = 'lgd'"><xsl:value-of select="'dc:contributor.lighting-designer'"/></xsl:when>
            <xsl:when test="$role = 'ltg'"><xsl:value-of select="'dc:contributor.lithographer'"/></xsl:when>
            <xsl:when test="$role = 'lyr'"><xsl:value-of select="'dc:contributor.lyricist'"/></xsl:when>
            <xsl:when test="$role = 'mfp'"><xsl:value-of select="'dc:contributor.manufacture-place'"/></xsl:when>
            <xsl:when test="$role = 'mfr'"><xsl:value-of select="'dc:contributor.manufacturer'"/></xsl:when>
            <xsl:when test="$role = 'mrb'"><xsl:value-of select="'dc:contributor.marbler'"/></xsl:when>
            <xsl:when test="$role = 'mrk'"><xsl:value-of select="'dc:contributor.markup-editor'"/></xsl:when>
            <xsl:when test="$role = 'med'"><xsl:value-of select="'dc:contributor.medium'"/></xsl:when>
            <xsl:when test="$role = 'mdc'"><xsl:value-of select="'dc:contributor.metadata-contact'"/></xsl:when>
            <xsl:when test="$role = 'mte'"><xsl:value-of select="'dc:contributor.metal-engraver'"/></xsl:when>
            <xsl:when test="$role = 'mtk'"><xsl:value-of select="'dc:contributor.minute-taker'"/></xsl:when>
            <xsl:when test="$role = 'mod'"><xsl:value-of select="'dc:contributor.moderator'"/></xsl:when>
            <xsl:when test="$role = 'mon'"><xsl:value-of select="'dc:contributor.monitor'"/></xsl:when>
            <xsl:when test="$role = 'mcp'"><xsl:value-of select="'dc:contributor.music-copyist'"/></xsl:when>
            <xsl:when test="$role = 'msd'"><xsl:value-of select="'dc:contributor.musical-director'"/></xsl:when>
            <xsl:when test="$role = 'mus'"><xsl:value-of select="'dc:contributor.musician'"/></xsl:when>
            <xsl:when test="$role = 'nrt'"><xsl:value-of select="'dc:contributor.narrator'"/></xsl:when>
            <xsl:when test="$role = 'osp'"><xsl:value-of select="'dc:contributor.onscreen-presenter'"/></xsl:when>
            <xsl:when test="$role = 'opn'"><xsl:value-of select="'dc:contributor.opponent'"/></xsl:when>
            <xsl:when test="$role = 'orm'"><xsl:value-of select="'dc:contributor.organizer'"/></xsl:when>
            <xsl:when test="$role = 'org'"><xsl:value-of select="'dc:contributor.originator'"/></xsl:when>
            <xsl:when test="$role = 'oth'"><xsl:value-of select="'dc:contributor.other'"/></xsl:when>
            <xsl:when test="$role = 'own'"><xsl:value-of select="'dc:contributor.owner'"/></xsl:when>
            <xsl:when test="$role = 'pan'"><xsl:value-of select="'dc:contributor.panelist'"/></xsl:when>
            <xsl:when test="$role = 'ppm'"><xsl:value-of select="'dc:contributor.papermaker'"/></xsl:when>
            <xsl:when test="$role = 'pta'"><xsl:value-of select="'dc:contributor.patent-applicant'"/></xsl:when>
            <xsl:when test="$role = 'pth'"><xsl:value-of select="'dc:contributor.patent-holder'"/></xsl:when>
            <xsl:when test="$role = 'pat'"><xsl:value-of select="'dc:contributor.patron'"/></xsl:when>
            <xsl:when test="$role = 'prf'"><xsl:value-of select="'dc:contributor.performer'"/></xsl:when>
            <xsl:when test="$role = 'pma'"><xsl:value-of select="'dc:contributor.permitting-agency'"/></xsl:when>
            <xsl:when test="$role = 'pht'"><xsl:value-of select="'dc:contributor.photographer'"/></xsl:when>
            <xsl:when test="$role = 'pad'"><xsl:value-of select="'dc:contributor.place-of-address'"/></xsl:when>
            <xsl:when test="$role = 'ptf'"><xsl:value-of select="'dc:contributor.plaintiff'"/></xsl:when>
            <xsl:when test="$role = 'ptt'"><xsl:value-of select="'dc:contributor.plaintiff-appellant'"/></xsl:when>
            <xsl:when test="$role = 'pte'"><xsl:value-of select="'dc:contributor.plaintiff-appellee'"/></xsl:when>
            <xsl:when test="$role = 'plt'"><xsl:value-of select="'dc:contributor.platemaker'"/></xsl:when>
            <xsl:when test="$role = 'pra'"><xsl:value-of select="'dc:contributor.praeses'"/></xsl:when>
            <xsl:when test="$role = 'pre'"><xsl:value-of select="'dc:contributor.presenter'"/></xsl:when>
            <xsl:when test="$role = 'prt'"><xsl:value-of select="'dc:contributor.printer'"/></xsl:when>
            <xsl:when test="$role = 'pop'"><xsl:value-of select="'dc:contributor.printer-of-plates'"/></xsl:when>
            <xsl:when test="$role = 'prm'"><xsl:value-of select="'dc:contributor.printmaker'"/></xsl:when>
            <xsl:when test="$role = 'prc'"><xsl:value-of select="'dc:contributor.process-contact'"/></xsl:when>
            <xsl:when test="$role = 'pro'"><xsl:value-of select="'dc:contributor.producer'"/></xsl:when>
            <xsl:when test="$role = 'prn'"><xsl:value-of select="'dc:contributor.production-company'"/></xsl:when>
            <xsl:when test="$role = 'prs'"><xsl:value-of select="'dc:contributor.production-designer'"/></xsl:when>
            <xsl:when test="$role = 'pmn'"><xsl:value-of select="'dc:contributor.production-manager'"/></xsl:when>
            <xsl:when test="$role = 'prd'"><xsl:value-of select="'dc:contributor.production-personnel'"/></xsl:when>
            <xsl:when test="$role = 'prp'"><xsl:value-of select="'dc:contributor.production-place'"/></xsl:when>
            <xsl:when test="$role = 'prg'"><xsl:value-of select="'dc:contributor.programmer'"/></xsl:when>
            <xsl:when test="$role = 'pdr'"><xsl:value-of select="'dc:contributor.project-director'"/></xsl:when>
            <xsl:when test="$role = 'pfr'"><xsl:value-of select="'dc:contributor.proofreader'"/></xsl:when>
            <xsl:when test="$role = 'prv'"><xsl:value-of select="'dc:contributor.provider'"/></xsl:when>
            <xsl:when test="$role = 'pup'"><xsl:value-of select="'dc:contributor.publication-place'"/></xsl:when>
            <xsl:when test="$role = 'pbl'"><xsl:value-of select="'dc:contributor.publisher'"/></xsl:when>
            <xsl:when test="$role = 'pbd'"><xsl:value-of select="'dc:contributor.publishing-director'"/></xsl:when>
            <xsl:when test="$role = 'ppt'"><xsl:value-of select="'dc:contributor.puppeteer'"/></xsl:when>
            <xsl:when test="$role = 'rdd'"><xsl:value-of select="'dc:contributor.radio-director'"/></xsl:when>
            <xsl:when test="$role = 'rpc'"><xsl:value-of select="'dc:contributor.radio-producer'"/></xsl:when>
            <xsl:when test="$role = 'rce'"><xsl:value-of select="'dc:contributor.recording-engineer'"/></xsl:when>
            <xsl:when test="$role = 'rcd'"><xsl:value-of select="'dc:contributor.recordist'"/></xsl:when>
            <xsl:when test="$role = 'red'"><xsl:value-of select="'dc:contributor.redaktor'"/></xsl:when>
            <xsl:when test="$role = 'ren'"><xsl:value-of select="'dc:contributor.renderer'"/></xsl:when>
            <xsl:when test="$role = 'rpt'"><xsl:value-of select="'dc:contributor.reporter'"/></xsl:when>
            <xsl:when test="$role = 'rps'"><xsl:value-of select="'dc:contributor.repository'"/></xsl:when>
            <xsl:when test="$role = 'rth'"><xsl:value-of select="'dc:contributor.research-team-head'"/></xsl:when>
            <xsl:when test="$role = 'rtm'"><xsl:value-of select="'dc:contributor.research-team-member'"/></xsl:when>
            <xsl:when test="$role = 'res'"><xsl:value-of select="'dc:contributor.researcher'"/></xsl:when>
            <xsl:when test="$role = 'rsp'"><xsl:value-of select="'dc:contributor.respondent'"/></xsl:when>
            <xsl:when test="$role = 'rst'"><xsl:value-of select="'dc:contributor.respondent-appellant'"/></xsl:when>
            <xsl:when test="$role = 'rse'"><xsl:value-of select="'dc:contributor.respondent-appellee'"/></xsl:when>
            <xsl:when test="$role = 'rpy'"><xsl:value-of select="'dc:contributor.responsible-party'"/></xsl:when>
            <xsl:when test="$role = 'rsg'"><xsl:value-of select="'dc:contributor.restager'"/></xsl:when>
            <xsl:when test="$role = 'rsr'"><xsl:value-of select="'dc:contributor.restorationist'"/></xsl:when>
            <xsl:when test="$role = 'rev'"><xsl:value-of select="'dc:contributor.reviewer'"/></xsl:when>
            <xsl:when test="$role = 'rbr'"><xsl:value-of select="'dc:contributor.rubricator'"/></xsl:when>
            <xsl:when test="$role = 'sce'"><xsl:value-of select="'dc:contributor.scenarist'"/></xsl:when>
            <xsl:when test="$role = 'sad'"><xsl:value-of select="'dc:contributor.scientific-advisor'"/></xsl:when>
            <xsl:when test="$role = 'aus'"><xsl:value-of select="'dc:contributor.screenwriter'"/></xsl:when>
            <xsl:when test="$role = 'scr'"><xsl:value-of select="'dc:contributor.scribe'"/></xsl:when>
            <xsl:when test="$role = 'scl'"><xsl:value-of select="'dc:contributor.sculptor'"/></xsl:when>
            <xsl:when test="$role = 'spy'"><xsl:value-of select="'dc:contributor.second-party'"/></xsl:when>
            <xsl:when test="$role = 'sec'"><xsl:value-of select="'dc:contributor.secretary'"/></xsl:when>
            <xsl:when test="$role = 'sll'"><xsl:value-of select="'dc:contributor.seller'"/></xsl:when>
            <xsl:when test="$role = 'std'"><xsl:value-of select="'dc:contributor.set-designer'"/></xsl:when>
            <xsl:when test="$role = 'stg'"><xsl:value-of select="'dc:contributor.setting'"/></xsl:when>
            <xsl:when test="$role = 'sgn'"><xsl:value-of select="'dc:contributor.signer'"/></xsl:when>
            <xsl:when test="$role = 'sng'"><xsl:value-of select="'dc:contributor.singer'"/></xsl:when>
            <xsl:when test="$role = 'sds'"><xsl:value-of select="'dc:contributor.sound-designer'"/></xsl:when>
            <xsl:when test="$role = 'spk'"><xsl:value-of select="'dc:contributor.speaker'"/></xsl:when>
            <xsl:when test="$role = 'spn'"><xsl:value-of select="'dc:contributor.sponsor'"/></xsl:when>
            <xsl:when test="$role = 'sgd'"><xsl:value-of select="'dc:contributor.stage-director'"/></xsl:when>
            <xsl:when test="$role = 'stm'"><xsl:value-of select="'dc:contributor.stage-manager'"/></xsl:when>
            <xsl:when test="$role = 'stn'"><xsl:value-of select="'dc:contributor.standards-body'"/></xsl:when>
            <xsl:when test="$role = 'str'"><xsl:value-of select="'dc:contributor.stereotyper'"/></xsl:when>
            <xsl:when test="$role = 'stl'"><xsl:value-of select="'dc:contributor.storyteller'"/></xsl:when>
            <xsl:when test="$role = 'sht'"><xsl:value-of select="'dc:contributor.supporting-host'"/></xsl:when>
            <xsl:when test="$role = 'srv'"><xsl:value-of select="'dc:contributor.surveyor'"/></xsl:when>
            <xsl:when test="$role = 'tch'"><xsl:value-of select="'dc:contributor.teacher'"/></xsl:when>
            <xsl:when test="$role = 'tcd'"><xsl:value-of select="'dc:contributor.technical-director'"/></xsl:when>
            <xsl:when test="$role = 'tld'"><xsl:value-of select="'dc:contributor.television-director'"/></xsl:when>
            <xsl:when test="$role = 'tlp'"><xsl:value-of select="'dc:contributor.television-producer'"/></xsl:when>
            <xsl:when test="$role = 'ths'"><xsl:value-of select="'dc:contributor.thesis-advisor'"/></xsl:when>
            <xsl:when test="$role = 'trc'"><xsl:value-of select="'dc:contributor.transcriber'"/></xsl:when>
            <xsl:when test="$role = 'trl'"><xsl:value-of select="'dc:contributor.translator'"/></xsl:when>
            <xsl:when test="$role = 'tyd'"><xsl:value-of select="'dc:contributor.type-designer'"/></xsl:when>
            <xsl:when test="$role = 'tyg'"><xsl:value-of select="'dc:contributor.typographer'"/></xsl:when>
            <xsl:when test="$role = 'uvp'"><xsl:value-of select="'dc:contributor.university-place'"/></xsl:when>
            <xsl:when test="$role = 'vdg'"><xsl:value-of select="'dc:contributor.videographer'"/></xsl:when>
            <xsl:when test="$role = 'vac'"><xsl:value-of select="'dc:contributor.voice-actor'"/></xsl:when>
            <xsl:when test="$role = 'wit'"><xsl:value-of select="'dc:contributor.witness'"/></xsl:when>
            <xsl:when test="$role = 'wde'"><xsl:value-of select="'dc:contributor.wood-engraver'"/></xsl:when>
            <xsl:when test="$role = 'wdc'"><xsl:value-of select="'dc:contributor.woodcutter'"/></xsl:when>
            <xsl:when test="$role = 'wam'"><xsl:value-of select="'dc:contributor.accompanying-material'"/></xsl:when>
            <xsl:when test="$role = 'wac'"><xsl:value-of select="'dc:contributor.added-commentary'"/></xsl:when>
            <xsl:when test="$role = 'wal'"><xsl:value-of select="'dc:contributor.added-lyrics'"/></xsl:when>
            <xsl:when test="$role = 'wat'"><xsl:value-of select="'dc:contributor.added-text'"/></xsl:when>
            <xsl:when test="$role = 'win'"><xsl:value-of select="'dc:contributor.introduction'"/></xsl:when>
            <xsl:when test="$role = 'wpr'"><xsl:value-of select="'dc:contributor.preface'"/></xsl:when>
            <xsl:when test="$role = 'wst'"><xsl:value-of select="'dc:contributor.supplementary-textual-content'"/></xsl:when>
            
            <!-- parse the role from the free text subfield (as we did in NORMARC) -->
            <xsl:when test="matches($role,'.*(utøv).*')">
                <!-- Performer -->
                <xsl:value-of select="'dc:contributor.performer'"/>
            </xsl:when>
            <xsl:when test="matches($role,'.*(skuesp).*')">
                <!-- Actor -->
                <xsl:value-of select="'dc:contributor.actor'"/>
            </xsl:when>
            <xsl:when test="matches($role,'.*(arr).*')">
                <!-- Arranger -->
                <xsl:value-of select="'dc:contributor.arranger'"/>
            </xsl:when>
            <xsl:when test="matches($role,'.*(manusforf).*')">
                <!-- Sceenwriter -->
                <xsl:value-of select="'dc:contributor.screenwriter'"/>
            </xsl:when>
            <xsl:when test="matches($role,'^fr.\s.*') or matches($role,'^til\s.*') or matches($role,'^p.\s.*') or matches($role,'^[^(]*(overs|.versett|overatt|omsett).*')">
                <xsl:value-of select="'dc:contributor.translator'"/>
            </xsl:when>
            <xsl:when test="matches($role,'.*(foto|billed).*')">
                <xsl:value-of select="'dc:contributor.photographer'"/>
            </xsl:when>
            <xsl:when test="matches($role,'.*(illu|tegning|teikni|tegnet).*')">
                <xsl:value-of select="'dc:contributor.illustrator'"/>
            </xsl:when>
            <xsl:when test="matches($role,'.*(konsulent|faglig|r.dgiver|research).*')">
                <xsl:value-of select="'dc:contributor.consultant'"/>
            </xsl:when>
            <xsl:when test="matches($role,'.*(red[ia\.]|tilrett|edit|eds|instrukt|instruert|revid).*') or $role='ed' or $role='red' or $role='hovedred'">
                <xsl:value-of select="'dc:contributor.editor'"/>
            </xsl:when>
            <xsl:when test="matches($role,'.*bearb.*')">
                <xsl:value-of select="'dc:contributor.adapter'"/>
            </xsl:when>
            <xsl:when test="matches($role,'.*(innl).*')">
                <xsl:value-of select="'dc:contributor.narrator'"/>
            </xsl:when>
            <xsl:when test="matches($role,'.*(forord|intro).*')">
                <xsl:value-of select="'dc:creator.foreword'"/>
            </xsl:when>
            <xsl:when test="matches($role,'.*etterord.*')">
                <!-- Author of afterword, colophon, etc. -->
                <xsl:value-of select="'dc:creator.afterword'"/>
            </xsl:when>
            <xsl:when test="matches($role,'.*noter.*')">
                <!-- Other -->
                <xsl:value-of select="'dc:contributor.other'"/>
            </xsl:when>
            <xsl:when test="matches($role,'.*kommentar.*')">
                <!-- Commentator for written text -->
                <xsl:value-of select="'dc:contributor.commentator'"/>
            </xsl:when>
            <xsl:when test="matches($role,'.*oppr.*forf.*')">
                <xsl:value-of select="'dc:contributor.bibliographic-antecedent'"/>
            </xsl:when>
            <xsl:when test="matches($role,'.*(forf|bidrag|ansvarl|utgave|medvirk|et\.? al|medf).*')">
                <xsl:value-of select="'dc:creator'"/>
            </xsl:when>
            <xsl:when test="matches($role,'.*utg.*')">
                <xsl:value-of select="'dc:contributor.publisher'"/>
            </xsl:when>
            <xsl:when test="matches($role,'.*(medarb).*')">
                <!-- Contributor -->
                <xsl:value-of select="'dc:contributor.contributor'"/>
            </xsl:when>
            <xsl:when test="matches($role,'.*(lest|fort|presentert).*')">
                <!-- Narrator -->
                <xsl:value-of select="'dc:contributor.narrator'"/>
            </xsl:when>
            <xsl:when test="matches($role,'.*regi.*')">
                <!-- Director -->
                <xsl:value-of select="'dc:contributor.director'"/>
            </xsl:when>
            <xsl:when test="matches($role,'.*musikk.*')">
                <!-- Musician -->
                <xsl:value-of select="'dc:contributor.musician'"/>
            </xsl:when>
            <xsl:when test="matches($role,'.*komp.*')">
                <!-- Composer -->
                <xsl:value-of select="'dc:contributor.composer'"/>
            </xsl:when>
            <xsl:when test="matches($role,'.*(samlet|utvalg).*')">
                <!-- Compiler -->
                <xsl:value-of select="'dc:contributor.compiler'"/>
            </xsl:when>
            
            <!-- default to dc:contributor.other when unable to determine the role -->
            <xsl:otherwise>
                <xsl:value-of select="'dc:contributor.other'"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="nlb:parseDate">
        <xsl:param name="date"/>
        <xsl:choose>
            <xsl:when test="matches($date, $ISO_DATE)">
                <xsl:sequence select="$date"/>
            </xsl:when>
            <xsl:when test="matches($date, $AVAILABLE)">
                <xsl:sequence select="replace($date, $AVAILABLE, '$3-$2-$1')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="nlb:parseBirthDeath">
        <xsl:param name="value"/>

        <xsl:variable name="split" select="tokenize($value,'-')"/>

        <xsl:choose>
            <xsl:when test="count($split) gt 2">
                <xsl:value-of select="','"/>

            </xsl:when>
            <xsl:when test="count($split) = 2">
                <xsl:variable name="year_death" select="nlb:parseYear($split[2], false())"/>
                <xsl:variable name="year_birth" select="nlb:parseYear($split[1], number($year_death) lt 0)"/>
                <xsl:value-of select="concat($year_birth,',',$year_death)"/>

            </xsl:when>
            <xsl:when test="count($split) = 1">
                <xsl:value-of select="concat(nlb:parseYear($split[1], false()),',')"/>
            </xsl:when>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="nlb:parseYear" as="xs:string?">
        <xsl:param name="value"/>
        <xsl:param name="assume-negative"/>

        <xsl:variable name="sign" select="if (matches($value,$YEAR_NEGATIVE) or $assume-negative) then '-' else ''"/>
        <xsl:variable name="year" select="replace($value, '^[^\d]*(\d+)([^\d].*)?$', '$1')"/>
        <xsl:variable name="year" select="if (matches($year,'^\d+$')) then $year else ''"/>

        <xsl:choose>
            <xsl:when test="$year">
                <xsl:sequence select="concat($sign, $year)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="nlb:prefixed-property">
        <xsl:param name="property"/>
        
        <xsl:choose>
            <xsl:when test="not($prefix-everything)">
                <xsl:value-of select="$property"/>
            </xsl:when>
            <xsl:when test="$property = ('series.issn','series.position','periodical','periodicity','magazine','newspaper','watermark','external-production','websok.url','websok.type','bibliofil-id','bibliofil-id.reference','marc-id','pseudonym','epub-nr','sortingKey','exclude-from-recommendations')">
                <xsl:value-of select="concat('nlbbib:', $property)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="concat('schema:', $property)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="nlb:identifier-in-title">
        <xsl:param name="title" as="xs:string"/>
        <xsl:param name="language" as="xs:string"/>
        <xsl:param name="sortable" as="xs:boolean"/>
        
        <xsl:choose>
            <xsl:when test="string-length($identifier) = 12 and xs:integer(substring($identifier, 9, 2)) le 12">
                <!-- YY MM DD -->
                <xsl:variable name="year" select="concat('20', substring($identifier, 7, 2))"/>
                <xsl:variable name="month" select="substring($identifier, 9, 2)"/>
                <xsl:variable name="day" select="substring($identifier, 11, 2)"/>
                
                <xsl:choose>
                    <xsl:when test="$sortable">
                        <xsl:value-of select="concat($title, ', ', $year, '-', $month, '-', string(xs:integer($day)))"/>
                    </xsl:when>
                    
                    <xsl:when test="$language = ('no', 'nor', 'nb', 'nob', 'nn', 'nnn')">
                        <xsl:variable name="month-name" select="if ($month = '01') then 'januar'
                                                                else if ($month = '02') then 'februar'
                                                                else if ($month = '03') then 'mars'
                                                                else if ($month = '04') then 'april'
                                                                else if ($month = '05') then 'mai'
                                                                else if ($month = '06') then 'juni'
                                                                else if ($month = '07') then 'juli'
                                                                else if ($month = '08') then 'august'
                                                                else if ($month = '09') then 'september'
                                                                else if ($month = '10') then 'oktober'
                                                                else if ($month = '11') then 'november'
                                                                else if ($month = '12') then 'desember'
                                                                else string($month)"/>
                        
                        <xsl:value-of select="concat($title, ', ', string(xs:integer($day)), '.', $month-name, ' ', $year)"/>
                    </xsl:when>
                    
                    <xsl:when test="$language = ('en', 'eng')">
                        <xsl:variable name="month-name" select="if ($month = '01') then 'January'
                                                                else if ($month = '02') then 'February'
                                                                else if ($month = '03') then 'March'
                                                                else if ($month = '04') then 'April'
                                                                else if ($month = '05') then 'May'
                                                                else if ($month = '06') then 'June'
                                                                else if ($month = '07') then 'July'
                                                                else if ($month = '08') then 'August'
                                                                else if ($month = '09') then 'September'
                                                                else if ($month = '10') then 'October'
                                                                else if ($month = '11') then 'November'
                                                                else if ($month = '12') then 'December'
                                                                else string($month)"/>
                        
                        <xsl:value-of select="concat($title, ', ', $month-name, ' ', string(xs:integer($day)), if ($day = '01') then 'st'
                                                                                                               else if ($day = '02') then 'nd'
                                                                                                               else if ($day = '03') then 'rd'
                                                                                                               else 'th', ' ', $year)"/>
                    </xsl:when>
                    
                    <xsl:otherwise>
                        <xsl:value-of select="concat($title, ', ', $year, '-', $month, '-', $day)"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            
            <xsl:when test="string-length($identifier) = 12">
                <!-- NR YYYY -->
                <xsl:variable name="number" select="substring($identifier, 7, 2)"/>
                <xsl:variable name="year" select="substring($identifier, 9, 4)"/>
                
                <xsl:choose>
                    <xsl:when test="$sortable">
                        <xsl:value-of select="concat($title, ', ', $year, '-', string(xs:integer($number)))"/>
                    </xsl:when>
                    
                    <xsl:otherwise>
                        <xsl:value-of select="concat($title, ', ', string(xs:integer($number)), '/', $year)"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            
            <xsl:otherwise>
                <xsl:value-of select="$title"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="nlb:parseLibrary850a" as="xs:string">
        <xsl:param name="identifier" as="xs:string"/>
        <xsl:param name="tag001" as="element()"/>
        
        <xsl:variable name="library" select="string(($tag001/../*:datafield[@tag='850']/*:subfield[@code='a'])[1])" as="xs:string"/>
        <xsl:variable name="library" select="replace($library, 'Tibi', 'NLB')" as="xs:string"/>
        <xsl:choose>
            <xsl:when test="contains(upper-case($library), 'NLB')">
                <xsl:value-of select="'NLB'"/>
            </xsl:when>
            <xsl:when test="contains(upper-case($library), 'KABB')">
                <xsl:value-of select="'KABB'"/>
            </xsl:when>
            <xsl:when test="contains(upper-case($library), 'STATPED')">
                <xsl:value-of select="'StatPed'"/>
            </xsl:when>
            <xsl:when test="string-length($identifier) lt 6">
                <xsl:value-of select="'NLB'"/>
            </xsl:when>
            <xsl:when test="substring($identifier, 1, 2) = ('80', '81', '82', '83', '84')">
                <xsl:value-of select="'KABB'"/>
            </xsl:when>
            <xsl:when test="substring($identifier, 1, 2) = ('85', '86', '87', '88')">
                <xsl:value-of select="'StatPed'"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="'NLB'"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

</xsl:stylesheet>
