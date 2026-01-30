%option noyywrap

%x ESC
%x ATTRN ATTRE ATTRC

%{
#include "nocomment.hpp"
#include <string>
#include <cstdio>
#include <cstdlib>

int removed_count = 0;
extern "C" int fileno(FILE *stream);

static std::string attr_buf;
%}

%%

<INITIAL>\\ { yylval.character='\\'; BEGIN(ESC); return Other; }

<INITIAL>"//"[^\n]*\n { removed_count++; }

<INITIAL>"(*" { attr_buf.clear(); BEGIN(ATTRN); }

<INITIAL>\n { yylval.character='\n'; return Other; }
<INITIAL>.  { yylval.character=yytext[0]; return Other; }
<INITIAL><<EOF>> { return Eof; }

<ESC>[^ \n] { yylval.character=yytext[0]; return Other; }
<ESC>[ \n]  { yylval.character=yytext[0]; BEGIN(INITIAL); return Other; }
<ESC><<EOF>> { return Eof; }

<ATTRN>"*)" { removed_count++; BEGIN(INITIAL); }

<ATTRN>"//" { attr_buf.append("//"); BEGIN(ATTRC); }

<ATTRN>\\   { attr_buf.push_back('\\'); BEGIN(ATTRE); }

<ATTRN>\n   { attr_buf.push_back('\n'); }

<ATTRN>.    { attr_buf.push_back(yytext[0]); }

<ATTRN><<EOF>> {
  for (auto it = attr_buf.rbegin(); it != attr_buf.rend(); ++it) unput(*it);
  unput('*');
  BEGIN(INITIAL);
  yylval.character='(';
  return Other;
}

<ATTRE>[^ \n] { attr_buf.push_back(yytext[0]); }

<ATTRE>[ \n]  { attr_buf.push_back(yytext[0]); BEGIN(ATTRN); }

<ATTRE><<EOF>> {
  for (auto it = attr_buf.rbegin(); it != attr_buf.rend(); ++it) unput(*it);
  unput('*');
  BEGIN(INITIAL);
  yylval.character='(';
  return Other;
}

<ATTRC>[^\n]*\n { attr_buf.append(yytext, yyleng); BEGIN(ATTRN); }

<ATTRC><<EOF>> {
  for (auto it = attr_buf.rbegin(); it != attr_buf.rend(); ++it) unput(*it);
  unput('*');
  BEGIN(INITIAL);
  yylval.character='(';
  return Other;
}

%%

void yyerror (char const *s)
{
  fprintf(stderr, "Flex Error: %s\n", s);
  exit(1);
}
