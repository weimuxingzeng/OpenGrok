/*
 * CDDL HEADER START
 *
 * The contents of this file are subject to the terms of the
 * Common Development and Distribution License (the "License").
 * You may not use this file except in compliance with the License.
 *
 * See LICENSE.txt included in this distribution for the specific
 * language governing permissions and limitations under the License.
 *
 * When distributing Covered Code, include this CDDL HEADER in each
 * file and include the License file at LICENSE.txt.
 * If applicable, add the following below this CDDL HEADER, with the
 * fields enclosed by brackets "[]" replaced with your own identifying
 * information: Portions Copyright [yyyy] [name of copyright owner]
 *
 * CDDL HEADER END
 */

/*
 * Copyright (c) 2015, 2016, Oracle and/or its affiliates. All rights reserved.
 * Portions Copyright (c) 2017, Chris Fraire <cfraire@me.com>.
 */

/*
 * Cross reference a Haskell file
 */

package org.opensolaris.opengrok.analysis.haskell;
import org.opensolaris.opengrok.analysis.JFlexXref;
import org.opensolaris.opengrok.web.Util;

/**
 * @author Harry Pan
 */

%%
%public
%class HaskellXref
%extends JFlexXref
%unicode
%ignorecase
%int
%include CommonXref.lexh
%{
  // TODO move this into an include file when bug #16053 is fixed
  @Override
  protected int getLineNumber() { return yyline; }
  @Override
  protected void setLineNumber(int x) { yyline = x; }
%}

Identifier = [a-zA-Z_] [a-zA-Z0-9_']*
Number = (0[xX][0-9a-fA-F]+|[0-9]+\.[0-9]+|[0-9][0-9_]*)([eE][+-]?[0-9]+)?

%state STRING CHAR COMMENT BCOMMENT

%include Common.lexh
%include CommonURI.lexh
%include CommonPath.lexh
%%
<YYINITIAL> {
    {Identifier} {
        String id = yytext();
        writeSymbol(id, Consts.kwd, yyline);
    }
    {Number}     { out.write("<span class=\"n\">"); out.write(yytext()); out.write("</span>"); }
    \"           { yybegin(STRING); out.write("<span class=\"s\">\"");                         }
    \'           { yybegin(CHAR); out.write("<span class=\"s\">\'");                           }
    "--"         { yybegin(COMMENT); out.write("<span class=\"c\">--");                        }
    "{-"         { yybegin(BCOMMENT); out.write("<span class=\"c\">{-");                       }
}

<STRING> {
    \"                 { yybegin(YYINITIAL); out.write("\"</span>");               }
    \\\\               { out.write("\\\\");                                        }
    \\\"               { out.write("\\\"");                                        }
    {WhspChar}*{EOL} { yybegin(YYINITIAL); out.write("</span>"); startNewLine(); }
}

<CHAR> {    // we don't need to consider the case where prime is part of an identifier since it is handled above
    ( .\' | \\.\' )    { yybegin(YYINITIAL); out.write(yytext()); out.write("</span>"); }
    {WhspChar}*{EOL} { yybegin(YYINITIAL); out.write("</span>"); startNewLine();      }
}

<COMMENT> {
    {WhspChar}*{EOL} { yybegin(YYINITIAL); out.write("</span>"); startNewLine(); }
}

<BCOMMENT> {
    "-}" { yybegin(YYINITIAL); out.write("-}</span>"); }
}

"&"                { out.write( "&amp;");           }
"<"                { out.write( "&lt;");            }
">"                { out.write( "&gt;");            }
{WhspChar}*{EOL} { startNewLine();                }
{WhiteSpace}       { out.write(yytext());           }
[^\n]              { writeUnicodeChar(yycharat(0)); }

<STRING, COMMENT, BCOMMENT> {
    {FPath} { out.write(Util.breadcrumbPath(urlPrefix + "path=", yytext(), '/')); }
    {BrowseableURI}    {
        appendLink(yytext(), true);
    }
    {FNameChar}+ "@" {FNameChar}+ "." {FNameChar}+ { writeEMailAddress(yytext()); }
}
