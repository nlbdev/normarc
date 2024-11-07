<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:dc="http://purl.org/dc/elements/1.1/"
                xmlns:SRU="http://www.loc.gov/zing/sru/"
                xmlns:normarc="info:lc/xmlns/marcxchange-v1"
                xmlns:DIAG="http://www.loc.gov/zing/sru/diagnostics/"
                xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                xmlns:schema="http://schema.org/"
                xmlns:frbr="http://purl.org/vocab/frbr/core#"
                xmlns:nlbbib="http://www.nlb.no/bibliographic"
                xmlns:nlb="http://www.nlb.no/"
                xmlns:html="http://www.w3.org/1999/xhtml"
                xmlns:f="#"
                exclude-result-prefixes="#all"
                version="2.0">
    
    <!-- note: assumes input XML is generated by run.py in github.com/nlbdev/bibliofil-dump -->
    
    <xsl:output indent="yes" method="xml"/>
    
    <xsl:template match="@* | node()" mode="#all" priority="-2">
        <xsl:copy exclude-result-prefixes="#all">
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="laaner/row | /row">
        <rdf:RDF>
            <xsl:namespace name="nlbbib" select="'http://www.nlb.no/bibliographic'"/>
            <rdf:Description rdf:ID="{@ln_nr}">
                <rdf:type rdf:resource="http://schema.org/Person"/>
                <xsl:for-each select="@*[starts-with(local-name(), 'ln_')]">
                    <xsl:apply-templates select="."/>
                </xsl:for-each>
                <xsl:for-each select="lnel/row/@*[starts-with(local-name(), 'lnel_')]">
                    <xsl:element name="nlbbib:{local-name()}">
                        <xsl:attribute name="rdf:name" select="."/>
                    </xsl:element>
                </xsl:for-each>
                <xsl:apply-templates select="lmarc/record | lmarc/record/*" mode="lmarc"/>
                <xsl:for-each select="res/row">
                    <nlbbib:res>
                        <xsl:for-each select="@*[starts-with(local-name(), 'res_')]">
                            <xsl:element name="nlbbib:{local-name()}">
                                <xsl:attribute name="rdf:name" select="."/>
                            </xsl:element>
                        </xsl:for-each>
                    </nlbbib:res>
                </xsl:for-each>
                <xsl:for-each select="bhist/row">
                    <nlbbib:bhist_tnr rdf:name="{@bhist_tnr}">
                        <nlbbib:bhist_laant rdf:name="{@bhist_laant}"/>
                    </nlbbib:bhist_tnr>
                </xsl:for-each>
            </rdf:Description>
        </rdf:RDF>
    </xsl:template>
    
    <xsl:template match="@*[starts-with(local-name(), 'ln_')]" priority="-1">
        <xsl:element name="nlbbib:{local-name()}">
            <xsl:attribute name="rdf:name" select="."/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="@ln_navn">
        <xsl:choose>
            <xsl:when test="starts-with(lower-case(.), '!!lnr. slettet')">
                <nlbbib:ln_navn rdf:name="Slettet"/>
                <nlbbib:ln_slettet rdf:name="{normalize-space(substring-after(lower-case(.),'!!lnr. slettet'))}"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:next-match/>
                <xsl:variable name="name-parsed" select="f:parse-name(.)" as="xs:string*"/>
                <nlbbib:ln_navn_fornavn rdf:name="{$name-parsed[1]}"/>
                <nlbbib:ln_navn_mellomnavn rdf:name="{$name-parsed[2]}"/>
                <nlbbib:ln_navn_etternavn rdf:name="{$name-parsed[3]}"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="@ln_kat">
        <xsl:element name="nlbbib:{local-name()}">
            <xsl:attribute name="rdf:name" select="f:ln_kat(.)"/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="controlfield | datafield" mode="lmarc">
        <xsl:if test="not((@tag, ../@tag) = ('102','103','200','250','260','271','272','273','300','466','467','500','516','517','518','521','600'))">
            <xsl:message select="concat('Ignored ', local-name(), ': ', @tag)"/>
            <!--<xsl:copy exclude-result-prefixes="#all">
                <xsl:apply-templates select="@* | node()" mode="#default"/>
            </xsl:copy>-->
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="controlfield[@tag='001']" mode="lmarc">
        <xsl:call-template name="lmarc">
            <xsl:with-param name="name" select="'nr'"/>
        </xsl:call-template>
        <xsl:call-template name="institution-and-disability">
            <xsl:with-param name="lmarc402a" select="../datafield[@tag='402']/subfield[@code='a']/text()"/>
            <xsl:with-param name="lmarc465d" select="../datafield[@tag='465']/subfield[@code='d']/text()"/>
            <xsl:with-param name="lmarc466a" select="../datafield[@tag='466']/subfield[@code='a']/text()"/>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template match="record" mode="lmarc">
        <!-- enable_cd_distribution from *465$c -->
        <xsl:choose>
            <xsl:when test="not(exists(datafield[@tag='465']/subfield[@code='c']))">
                <xsl:call-template name="lmarc">
                    <xsl:with-param name="name" select="'enable_cd_distribution'"/>
                    <xsl:with-param name="value" select="'true'"/>
                    <xsl:with-param name="context" select="."/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:for-each select="datafield[@tag='465']/subfield[@code='c']">
                    <xsl:call-template name="lmarc">
                        <xsl:with-param name="name" select="'enable_cd_distribution'"/>
                        <xsl:with-param name="value" select="if (. = '0') then 'false' else 'true'"/>
                        <xsl:with-param name="context" select="."/>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
        
        <!-- enable_cd_distribution_for_periodicals from *465$i -->
        <xsl:choose>
            <xsl:when test="not(exists(datafield[@tag='465']/subfield[@code='i']))">
                <xsl:call-template name="lmarc">
                    <xsl:with-param name="name" select="'enable_cd_distribution_for_periodicals'"/>
                    <xsl:with-param name="value" select="'true'"/>
                    <xsl:with-param name="context" select="."/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:for-each select="datafield[@tag='465']/subfield[@code='i']">
                    <xsl:call-template name="lmarc">
                        <xsl:with-param name="name" select="'enable_cd_distribution_for_periodicals'"/>
                        <xsl:with-param name="value" select="if (. = '0') then 'false' else 'true'"/>
                        <xsl:with-param name="context" select="."/>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="datafield[@tag='140']" mode="lmarc">
        <xsl:for-each select="subfield">
            <xsl:choose>
                <xsl:when test="@code = 'a'">
                    <xsl:call-template name="lmarc">
                        <xsl:with-param name="name" select="'library'"/>
                        <xsl:with-param name="value" select="
                            if (. = ('OL','OS')) then 'NLB' else
                            if (. = 'SPED') then 'Statped' else
                            if (. = 'KABB') then 'Kabb' else .
                            "/>
                        <xsl:with-param name="context" select="."/>
                    </xsl:call-template>
                    <xsl:call-template name="lmarc">
                        <xsl:with-param name="name" select="'student'"/>
                        <xsl:with-param name="value" select="if (. = 'OS') then 'true' else 'false'"/>
                        <xsl:with-param name="context" select="."/>
                    </xsl:call-template>
                </xsl:when>
                <xsl:when test="@code = 'i'">
                    <xsl:variable name="context" select="."/>
                    <xsl:for-each select="tokenize(text(), '\s+')">
                        <xsl:call-template name="lmarc">
                            <xsl:with-param name="name" select="'libraryAccess'"/>
                            <xsl:with-param name="value" select="
                                if (. = 'SPED') then 'Statped' else
                                if (. = 'KABB') then 'Kabb' else .
                                "/>
                            <xsl:with-param name="context" select="$context"/>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:when>
            </xsl:choose>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template match="datafield[@tag='150']" mode="lmarc">
        <xsl:if test="not(preceding-sibling::*[@tag='150'])">
            <xsl:variable name="lines" as="xs:string*">
                <xsl:for-each select="(. | following-sibling::*[@tag='150'])">
                    <xsl:sort select="*[@code='a']/text()"/>
                    <xsl:value-of select="*[@code = 'b']/text()"/>
                </xsl:for-each>
            </xsl:variable>
            <xsl:call-template name="lmarc">
                <xsl:with-param name="name" select="'melding'"/>
                <xsl:with-param name="value" select="string-join($lines, '&#xA;')"/>
                <xsl:with-param name="context" select="."/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="datafield[@tag='240']" mode="lmarc">
        <xsl:for-each select="subfield">
            <xsl:choose>
                <xsl:when test="@code = 'a'">
                    <xsl:variable name="tlf" select="replace(normalize-space(), '(^\s+|\s+$)', '')"/>
                    <xsl:variable name="type" select="((../subfield[@code = 'c'])[1]/normalize-space(), '')[1]"/>
                    <xsl:call-template name="lmarc">
                        <xsl:with-param name="name" select="if ($type = '') then 'tlf' else concat('tlf_', $type)"/>
                        <xsl:with-param name="value" select="$tlf"/>
                    </xsl:call-template>
                </xsl:when>
            </xsl:choose>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template match="datafield[@tag='251']" mode="lmarc">
        <xsl:for-each select="subfield[@code='k']">
            <xsl:call-template name="lmarc">
                <xsl:with-param name="name" select="'kindle_email'"/>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template match="datafield[@tag='261']" mode="lmarc">
        <xsl:for-each select="subfield">
            <xsl:choose>
                <xsl:when test="@code = 'a'">
                    <xsl:call-template name="lmarc">
                        <xsl:with-param name="name" select="'pin'"/>
                    </xsl:call-template>
                </xsl:when>
                <xsl:when test="@code = 'b'">
                    <xsl:call-template name="lmarc">
                        <xsl:with-param name="name" select="'pin_date'"/>
                    </xsl:call-template>
                </xsl:when>
            </xsl:choose>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template match="datafield[@tag='402']" mode="lmarc">
        <!-- NOTE: 402$a checked by the template "institution-and-disability" -->
    </xsl:template>
    
    <xsl:template match="datafield[@tag='465']" mode="lmarc">
        <xsl:for-each select="subfield">
            <xsl:choose>
                <xsl:when test="@code = 'e' and text() = '1'">
                    <xsl:call-template name="lmarc">
                        <xsl:with-param name="name" select="'automated_loans'"/>
                        <xsl:with-param name="value" select="'true'"/>
                    </xsl:call-template>
                </xsl:when>
                
                <xsl:when test="@code = 'h' and text() = 'P'">
                    <xsl:call-template name="lmarc">
                        <xsl:with-param name="name" select="'braille_patron'"/>
                        <xsl:with-param name="value" select="'true'"/>
                    </xsl:call-template>
                </xsl:when>
                
                <!-- NOTE: 465$d handled by the template "institution-and-disability" -->
                <!-- NOTE: 465$c and 465$i handled by template matching 'record' and mode=lmarc -->
            </xsl:choose>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template match="datafield[@tag='466']" mode="lmarc">
        <xsl:for-each select="subfield">
            <xsl:choose>
                <xsl:when test="@code = 'b' and text() = 'PR'">
                    <xsl:call-template name="lmarc">
                        <xsl:with-param name="name" select="'production_right'"/>
                        <xsl:with-param name="value" select="'true'"/>
                    </xsl:call-template>
                </xsl:when>
                
                <!-- NOTE: 466$a handled by the template "institution-and-disability" -->
            </xsl:choose>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template match="datafield[@tag='468']" mode="lmarc">
        <xsl:for-each select="subfield">
            <xsl:choose>
                <xsl:when test="@code = 'a'">
                    <xsl:call-template name="lmarc">
                        <xsl:with-param name="name" select="'preferredPlayer'"/>
                    </xsl:call-template>
                </xsl:when>
            </xsl:choose>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template match="datafield[@tag='469']" mode="lmarc">
        <xsl:variable name="datafield" select="."/>
        
        <xsl:if test="subfield[@code='a']">
            <xsl:variable name="subscription" as="element()">
                <xsl:for-each select="(subfield[@code='a'])[1]">
                    <xsl:call-template name="lmarc">
                        <xsl:with-param name="name" select="'subscription'"/>
                        <xsl:with-param name="value" select="tokenize(text(), '\s+')[1]"/>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:variable>
            
            <xsl:for-each select="$subscription">
                <xsl:copy exclude-result-prefixes="#all">
                    <xsl:copy-of select="@* | node()" exclude-result-prefixes="#all"/>
                    
                    <xsl:for-each select="$datafield/subfield">
                        <xsl:choose>
                            <xsl:when test="@code = 'd'">
                                <xsl:call-template name="lmarc">
                                    <xsl:with-param name="name" select="'subscriptionStarted'"/>
                                </xsl:call-template>
                            </xsl:when>
                        </xsl:choose>
                    </xsl:for-each>
                </xsl:copy>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="institution-and-disability">
        <xsl:param name="lmarc402a" as="xs:string*"/>
        <xsl:param name="lmarc465d" as="xs:string*"/>
        <xsl:param name="lmarc466a" as="xs:string*"/>
        
        <xsl:if test="upper-case($lmarc402a) = 'HER' or $lmarc465d = 'TS'">
            <xsl:call-template name="lmarc">
                <xsl:with-param name="name" select="'test_patron'"/>
                <xsl:with-param name="value" select="'true'"/>
            </xsl:call-template>
        </xsl:if>
        
        <xsl:variable name="disability" as="xs:string" select="
            if ($lmarc466a = 'D') then 'Dysleksi' else
            if ($lmarc466a = 'AL') then 'Andre lesevansker' else
            if ($lmarc466a = 'FF') then 'Fysisk funksjonshemming' else
            if ($lmarc466a = 'ME') then 'ME - utmattelsessyndrom' else
            if ($lmarc466a = 'MH') then 'Multihandikap' else
            if ($lmarc466a = 'PU') then 'Psykisk utviklingshemming' else
            if ($lmarc466a = 'A') then 'Afasi' else
            if ($lmarc466a = 'ADHD') then 'ADHD' else
            if ($lmarc466a = 'KU') then 'Kognitive utfordringer og/eller språkvansker' else
            if ($lmarc466a = 'UH') then 'Utviklingshemming' else

            if ($lmarc465d = 'ME') then 'ME - utmattelsessyndrom' else
            if ($lmarc465d = 'S') then 'Synshemmet' else
            if ($lmarc465d = 'AH') then 'Annet handikap' else
            
            'Ukjent'
        "/>
        
        <xsl:variable name="institution" as="xs:string" select="
            if ($lmarc466a = 'IBIB') then 'Bibliotek' else
            if ($lmarc466a = 'ISHAH') then 'Sykehjem-Aldershjem' else
            if ($lmarc466a = 'IBH') then 'Barnehager' else
            if ($lmarc466a = 'IS') then 'Sykehus' else
            if ($lmarc466a = 'IA') then 'Andre' else
            
            if ($lmarc465d = 'I') then 'Andre' else
            if ($lmarc465d = 'AN') then 'Andre' else
            
            'Ingen'
        "/>
        
        <xsl:call-template name="lmarc">
            <xsl:with-param name="name" select="'institution'"/>
            <xsl:with-param name="value" select="$institution"/>
        </xsl:call-template>
        
        <xsl:call-template name="lmarc">
            <xsl:with-param name="name" select="'disability'"/>
            <xsl:with-param name="value" select="$disability"/>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template name="lmarc">
        <xsl:param name="name" as="xs:string"/>
        <xsl:param name="value" select="()" as="xs:string?"/>
        <xsl:param name="context" select="." as="element()"/>
        <xsl:element name="nlbbib:lmarc_{$name}">
            <xsl:attribute name="rdf:name" select="($value, $context/text())[1]"/>
            <xsl:call-template name="lmarc-source">
                <xsl:with-param name="context" select="$context"/>
            </xsl:call-template>
        </xsl:element>
    </xsl:template>
    
    <xsl:template name="lmarc-source">
        <xsl:param name="context" select="." as="element()"/>
        <!--<nlbbib:source rdf:name="{if ($context/self::subfield) then concat($context/../@tag, '$', $context/@code) else $context/@tag}"/>-->
    </xsl:template>
    
    <xsl:function name="f:ln_kat">
        <xsl:param name="ln_kat" as="xs:string?"/>
        <xsl:choose>
            <xsl:when test="$ln_kat = 'l'">
                <xsl:value-of select="'Institusjon'"/>
            </xsl:when>
            <xsl:when test="$ln_kat = 'b'">
                <xsl:value-of select="'Barn'"/>
            </xsl:when>
            <xsl:when test="$ln_kat = 'ele'">
                <xsl:value-of select="'Elevlåner'"/>
            </xsl:when>
            <xsl:when test="$ln_kat = 'sped_ansatt'">
                <xsl:value-of select="'Statped Ansatt'"/>
            </xsl:when>
            <xsl:when test="$ln_kat = 'sped_elev'">
                <xsl:value-of select="'Statped Elev'"/>
            </xsl:when>
            <xsl:when test="$ln_kat = 'sped_larer'">
                <xsl:value-of select="'Statped Lærer'"/>
            </xsl:when>
            <xsl:when test="$ln_kat = 'sped_skole'">
                <xsl:value-of select="'Statped Skole'"/>
            </xsl:when>
            <xsl:when test="$ln_kat = 'ue'">
                <xsl:value-of select="'Utgått elev'"/>
            </xsl:when>
            <xsl:when test="$ln_kat = 'v'">
                <xsl:value-of select="'Voksen'"/>
            </xsl:when>
            <xsl:when test="$ln_kat = 'u'">
                <xsl:value-of select="'Ukjent'"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="'Ukjent'"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="f:parse-name" as="xs:string*">
        <xsl:param name="name" as="xs:string"/>
        
        <xsl:variable name="valid-letters" select="'\p{L}\. -'"/>
        
        <xsl:choose>
            <!-- valid characters, then a comma, then more valid characters -->
            <xsl:when test="matches($name, concat('^[', $valid-letters, ']+,[', $valid-letters, ']+$'))">
                <xsl:variable name="last" select="normalize-space(tokenize($name, ',')[1])"/>
                
                <xsl:variable name="first" select="normalize-space(tokenize(normalize-space($name), ',')[2])"/>
                
                <xsl:variable name="middle" select="string-join(tokenize($first, ' ')[position() gt 1], ' ')"/>
                
                <xsl:variable name="first" select="tokenize($first, ' ')[1]"/>
                
                <xsl:sequence select="($first, $middle, $last)"/>
                
            </xsl:when>
            <xsl:otherwise>
                <!-- Special characters found, or incorrect number of commas. Put everything as first name. -->
                <xsl:sequence select="(normalize-space($name), '', '')"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
</xsl:stylesheet>