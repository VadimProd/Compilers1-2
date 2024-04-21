#include <stdio.h>
#include "y.tab.h"

FILE* yyin;

int main() {
	yyin = fopen("test.txt", "r");
	if (yyin == NULL) { return -1; }
	yyparse();
	fclose(yyin);
	return 0;
}
