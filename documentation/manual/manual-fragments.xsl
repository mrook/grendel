<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:template match="para[@userlevel]">
		<p>
		<xsl:text>Required level: </xsl:text>
		<xsl:value-of select="@userlevel"/>
		</p>
	</xsl:template>
	
	<xsl:param name="html.stylesheet" select="'manual.css'"/>
</xsl:stylesheet>
