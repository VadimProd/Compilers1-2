%{
#include <stdio.h> 
#include <string.h>
#include <math.h>
#include <ctype.h>
#include <stdbool.h>

#define COUNT_POLINOM 26 //максимальное кол-во переменныых для полиномов
#define MAX_DEG 256      //максимальная возможная степень 

enum error_type {
	DOUBLE_CHARACTER,
	EMPTY_OPERATOR,
	NEGATIVE_DEGREE,
	POLYNOM_DEGREE,
	INCORRECT_ASSIGNMENT,
	EMPTY_OUTPUT,
	DIVISION_BY_ZERO,
	DIVISION_ERR,
	NON_INTEGER_DIVISION,
	NOT_INITIALIZED,
	MAX_DEGREE,
	MULTIPLICATION_VARIABLE,
	ZERO_DEGREE
};

struct polynom_list {
	int coeff_array[COUNT_POLINOM][MAX_DEG];
	char letter;
	int max_degree;
}; 

struct polynom_list polynom_calculate[100] = {0};  //массив для подсчетов полинома
struct polynom_list polynoms[COUNT_POLINOM] = {0}; //массив всех полиномов

int index_last_letter = 0;                         //число (индекс) последней использованной маленькой буквы
int level_calc = 0;                                //уровень подсчетов
int line = 1; 		   				               //номер строки для вывода ошибки
int index_last_big_letter = 0; 			           //индекс буквы для полинома

void print_error(const char* text, int line) {
	printf("%s in line %d\n", text, line);
	exit(0);
}

bool is_empty(struct polynom_list poly){
	for (int i = 0; i < COUNT_POLINOM; i++){
		for (int j = 0; j < MAX_DEG; j++){
			if (i == j == 0) continue;
			if (poly.coeff_array[i][j] > 0){
				return false;
			}
		}
	}

	return true;
}

void error_list(enum error_type error) {

	switch (error) {
	case DOUBLE_CHARACTER:
		print_error("Syntax error: Double character", line);

	case EMPTY_OPERATOR:
		print_error("Syntax error: Operator doesn't exist", line);
	
	case NEGATIVE_DEGREE:
		print_error("Syntax error: A degree can only be expressed by a positive number", line);
	
	case POLYNOM_DEGREE:
		print_error("Syntax error: The degree shouldn't be in the form of a polynomial", line);

	case INCORRECT_ASSIGNMENT:
		print_error("Syntax error: Assigning values to a non-variable polynomial", line);

	case EMPTY_OUTPUT:
		print_error("Syntax error: Missing values for output", line);
	
	case DIVISION_BY_ZERO:
		print_error("Semantic error: Division by 0", line);

	case NON_INTEGER_DIVISION:
		print_error("Semantic error: It's impossible to divide integer", line);
	
	case DIVISION_ERR:
		print_error("Semantic error: The dividible is less than the divisor", line);
	
	case NOT_INITIALIZED:
		print_error("Semantic error: The variable hasn't been initialized", line);
	
	case MAX_DEGREE:
		print_error("Semantic error: Maximum polynomial degree < 256", line);
	
	case MULTIPLICATION_VARIABLE:  
		print_error("Semantic error: multiplicationplication of polynomials from different variables", line);
	case ZERO_DEGREE:
		print_error("Semantic error: uncertainty 0^0", line);
	default:
		break;
	}
}

struct polynom_list unary_minus(struct polynom_list poly) {
	for (int i = 0; i < COUNT_POLINOM; i++)
		for (int j = 0; j <= poly.max_degree; j++)
			poly.coeff_array[i][j] = -poly.coeff_array[i][j];
	return (poly);
}

struct polynom_list addition(const int sign, struct polynom_list poly_1, struct polynom_list poly_2) {
	int result, deg;

	struct polynom_list backup;
	memset(&backup, 0, sizeof(struct polynom_list));

	deg = poly_1.max_degree >= poly_2.max_degree ? poly_1.max_degree : poly_2.max_degree;
	for (int i = 0; i < COUNT_POLINOM; i++) {
		for (int j = 0; j <= deg; j++) {
			result = (sign == 1) ? poly_2.coeff_array[i][j] + 
				poly_1.coeff_array[i][j] : poly_1.coeff_array[i][j] - poly_2.coeff_array[i][j];

			backup.coeff_array[i][j] = (backup.coeff_array[i][j] == 0) ? result : backup.coeff_array[i][j] + result;
		}
	}
	for (int i = 0; i < COUNT_POLINOM; i++) {
		for (int j = 0; j < COUNT_POLINOM; j++) {
			if (backup.coeff_array[i][0] != 0 && backup.coeff_array[j][0] != 0 && i < j) {
				backup.coeff_array[j][0] = backup.coeff_array[i][0] + backup.coeff_array[j][0];
				backup.coeff_array[i][0] = 0;
			}
		}
	}
	backup.max_degree = deg;
	return (backup);
}

struct polynom_list multiplication(struct polynom_list poly_1, struct polynom_list poly_2) {
	int result, deg;
	struct polynom_list backup;
	memset(&backup, 0, sizeof(struct polynom_list));

	if (poly_1.max_degree == 0) {
		int count = 0;
		while (poly_1.coeff_array[count][0] == 0 && count < COUNT_POLINOM) {
			count++;
		}
		for (int i = 0; i < COUNT_POLINOM; i++) {
			for (int j = 0; j <= poly_2.max_degree; j++) {
				result = poly_1.coeff_array[count][0] * poly_2.coeff_array[i][j];
				backup.coeff_array[i][j] = result;
			}
		}

		backup.max_degree = poly_2.max_degree;
		return (backup);
	}

	for (int i = 0; i < COUNT_POLINOM; i++) {
		for (int j = 0; j < COUNT_POLINOM; j++) {
			for (int l = 0; l <= poly_1.max_degree; l++) {
				for (int m = 0; m <= poly_2.max_degree; m++) {
					if ((poly_1.coeff_array[i][l] != 0 && poly_2.coeff_array[j][m] != 0) && i != j) { error_list(MULTIPLICATION_VARIABLE); }
					result = poly_1.coeff_array[i][l] * poly_2.coeff_array[j][m];
					deg = l + m;
					backup.coeff_array[i][deg] = (backup.coeff_array[i][deg] == 0) ? result : backup.coeff_array[i][deg] + result;
				}
			}
		}
	}
	backup.max_degree = deg;

	return backup;
}

struct polynom_list divide(struct polynom_list poly_1, struct polynom_list poly_2) {
    int deg;
	float result;
	struct polynom_list backup;
	memset(&backup, 0, sizeof(struct polynom_list));

	if (poly_2.max_degree == 0) {
		int flag = 0;
		for (int i = 0; i < COUNT_POLINOM; i++) {
			if(poly_2.coeff_array[i][0] != 0) { flag = 1  ; break;}
		}
		if (flag == 0) error_list(DIVISION_BY_ZERO);
	}

    if (poly_1.max_degree < poly_2.max_degree) { error_list(DIVISION_ERR); }

    for (int i = 0; i < COUNT_POLINOM; i++) {
		for (int j = 0; j < COUNT_POLINOM; j++) {
			for (int l = 0; l <= poly_1.max_degree; l++) {
				for (int m = 0; m <= poly_2.max_degree; m++) {
					if ((poly_1.coeff_array[i][l] != 0 && poly_2.coeff_array[j][m] != 0) && i != j) error_list(MULTIPLICATION_VARIABLE);
					if (poly_1.coeff_array[i][l] == 0 || poly_2.coeff_array[j][m] == 0) continue;
					else if (poly_1.coeff_array[i][l] % poly_2.coeff_array[j][m] != 0) error_list(NON_INTEGER_DIVISION);
					else result = poly_1.coeff_array[i][l] / poly_2.coeff_array[j][m];
					deg = l - m;
					backup.coeff_array[i][deg] = (backup.coeff_array[i][deg] == 0) ? (int)result : backup.coeff_array[i][deg] + (int)result;
				}
			}
		}
	}
	backup.max_degree = deg;
	return backup;
}

void print(struct polynom_list poly_1) {
	int null_check = 0;
	int flag = 0;
	int num = 0;
	if (poly_1.letter != 0) { printf("%c = ", poly_1.letter); }

	for (int i = 0; i < COUNT_POLINOM; i++) {
		for (int j = poly_1.max_degree; j >= 0; j--) {
			if (poly_1.coeff_array[i][j] != 0) {

				if ((num != 0) && (flag != i) && (poly_1.coeff_array[i][j] > 0)) { printf("+"); }

				flag = i;
				num = 1;

				if (poly_1.coeff_array[i][j] == -1 && j != 0) { printf("-"); }
				else if (poly_1.coeff_array[i][j] != 1 || j == 0) { printf("%d", poly_1.coeff_array[i][j]); }

				if (j != 0 && j == 1) { printf("%c", i + 'a'); }
				else if (j != 0) { printf("%c", i + 'a'); printf("^%d", j); }

				if (j != 0) {
					while (poly_1.coeff_array[i][j - 1] == 0) {
						j--;
					}
					if ((j <= 0) || (poly_1.coeff_array[i][j - 1] <= 0));
					else { printf("+"); }
				}
				null_check = 1;
			}
		}
	}
	if (null_check == 0) { printf("0"); }
	printf("\n");
}
%}

%start starter

%token DIGIT LETTER BIG_LETTER
%left '+' '-'
%left '*' '/'
%right '^'
%%

starter: begin 
	| begin enter starter
	| enter starter
	| enter 
;

enter: '\n' { line++; }
;

begin: '>' main {
		print(polynom_calculate[0]);
		memset(&polynom_calculate[0], 0, sizeof(struct polynom_list));
		level_calc = 0;
	}
	| '>' { error_list(EMPTY_OUTPUT); }
	| big_letter '=' init 
	| big_letter '=' { error_list(EMPTY_OPERATOR); }
	| big_letter { error_list(EMPTY_OPERATOR); }
	| main '=' { error_list(INCORRECT_ASSIGNMENT); }
	| main { error_list(EMPTY_OPERATOR); }
;

big_letter: BIG_LETTER {
		index_last_big_letter = $1 + 0;
	}
;

init: main {
		index_last_letter = 0; 
		polynoms[index_last_big_letter] = polynom_calculate[0];
		polynoms[index_last_big_letter].letter = index_last_big_letter + 'A';

		memset(&polynom_calculate[0], 0, sizeof(struct polynom_list));
		level_calc = 0;
	}
;

main: '-' '-' main { error_list(DOUBLE_CHARACTER); }
	| main symbol symbol { error_list(DOUBLE_CHARACTER); }
	| main '+' main {
		polynom_calculate[level_calc - 2] = addition(1, polynom_calculate[level_calc - 2], polynom_calculate[level_calc - 1]);
		memset(&polynom_calculate[level_calc - 1], 0, sizeof(struct polynom_list));
		level_calc--;
	}
	| main '-' main {
		printf("main - main\n");
		polynom_calculate[level_calc - 2] = addition(0, polynom_calculate[level_calc - 2], polynom_calculate[level_calc - 1]);
		memset(&polynom_calculate[level_calc - 1], 0, sizeof(struct polynom_list));
		level_calc--;
	}
	| main '*' main {
		polynom_calculate[level_calc - 2] = polynom_calculate[level_calc - 1].max_degree == 0 ? 
			multiplication(polynom_calculate[level_calc - 1], polynom_calculate[level_calc - 2]) : 
			multiplication(polynom_calculate[level_calc - 2], polynom_calculate[level_calc - 1]);
		memset(&polynom_calculate[level_calc - 1], 0, sizeof(struct polynom_list));
		level_calc--;
	}
	| main '*' '(' main ')' {
		polynom_calculate[level_calc - 2] = polynom_calculate[level_calc - 1].max_degree == 0 ? 
			multiplication(polynom_calculate[level_calc - 1], polynom_calculate[level_calc - 2]) : 
			multiplication(polynom_calculate[level_calc - 2], polynom_calculate[level_calc - 1]);
		memset(&polynom_calculate[level_calc - 1], 0, sizeof(struct polynom_list));
		level_calc--;
	}
	| main '(' main ')' {
		polynom_calculate[level_calc - 2] = polynom_calculate[level_calc - 1].max_degree == 0 ? 
			multiplication(polynom_calculate[level_calc - 1], polynom_calculate[level_calc - 2]) : 
			multiplication(polynom_calculate[level_calc - 2], polynom_calculate[level_calc - 1]);

		memset(&polynom_calculate[level_calc - 1], 0, sizeof(struct polynom_list));
		level_calc--;
	}
	| main main {
		polynom_calculate[level_calc - 2] = polynom_calculate[level_calc - 1].max_degree == 0 ? 
			multiplication(polynom_calculate[level_calc - 1], polynom_calculate[level_calc - 2]) : 
			multiplication(polynom_calculate[level_calc - 2], polynom_calculate[level_calc - 1]);

		memset(&polynom_calculate[level_calc - 1], 0, sizeof(struct polynom_list));
		level_calc--;
	}
	| '(' main ')'{}
	| main '/' main {
		polynom_calculate[level_calc - 2] = divide(polynom_calculate[level_calc - 2], polynom_calculate[level_calc - 1]);
		memset(&polynom_calculate[level_calc - 1], 0, sizeof(struct polynom_list));
		level_calc--;
	}
	| '-' main { 
		polynom_calculate[level_calc - 1] = unary_minus(polynom_calculate[level_calc - 1]);
	}
	| main '^' degree {
		printf("main ^ degree\n");
		if ($3 == 0) {
			memset(&polynom_calculate[level_calc - 1], 0, sizeof(struct polynom_list));
			polynom_calculate[level_calc - 1].coeff_array[25][0] = 1;
		}
		else {
			int deg = 1;
			struct polynom_list poly_backup = polynom_calculate[level_calc - 1];

			while (deg != $3) {
				polynom_calculate[level_calc - 1] = multiplication(polynom_calculate[level_calc - 1], poly_backup);
				deg++;
			}
		}
	}
	| kit { level_calc++; }
;  

kit: number {
		if (0 >= polynom_calculate[level_calc].max_degree) 
			polynom_calculate[level_calc].max_degree = 0;
		polynom_calculate[level_calc].coeff_array[index_last_letter][0] = $1;
	}	

	| BIG_LETTER {
		int i = $1 + 0;
		if (polynoms[i].letter == 0){
			error_list(NOT_INITIALIZED);
		}
		polynom_calculate[level_calc] = polynoms[i];
	}
	| BIG_LETTER '^' degree {
		printf("BIG_LETTER ^ degree %d %d\n", $1, $3);
		if ($3 == 0) {
			memset(&polynom_calculate[level_calc], 0, sizeof(struct polynom_list));
			polynom_calculate[level_calc].coeff_array[25][0] = 1;
		}
		else {
			int i = $1 + 0;
			if (polynoms[i].letter == 0){
				error_list(NOT_INITIALIZED);
			}
			polynom_calculate[level_calc] = polynoms[i];
			int degree_pol = 1;
			struct polynom_list poly_backup = polynom_calculate[level_calc];
			while (degree_pol != $3) {
				polynom_calculate[level_calc] = multiplication(polynom_calculate[level_calc], poly_backup);
				degree_pol++;
			}
		}
	}
	| number BIG_LETTER {
		int i = $2 + 0;
		if (polynoms[i].letter == 0){
			error_list(NOT_INITIALIZED);
		}
		polynom_calculate[level_calc] = polynoms[i];
		struct polynom_list poly_backup = polynom_calculate[level_calc];
		for (int j = 0; j < COUNT_POLINOM; j++) {				
			for (int i = 0; i <= polynom_calculate[level_calc].max_degree; i++) {
				polynom_calculate[level_calc].coeff_array[j][i] = poly_backup.coeff_array[j][i] * $1;
			}
		}
	}
	| number BIG_LETTER '^' degree {
		if ($4 == 0) {
			memset(&polynom_calculate[level_calc], 0, sizeof(struct polynom_list));
			polynom_calculate[level_calc].coeff_array[25][0] = $1;
		}
		else {
			int i = $2 + 0;
			if (polynoms[i].letter == 0){
				error_list(NOT_INITIALIZED);
			}
			polynom_calculate[level_calc] = polynoms[i];
			int degree_pol = 1;
			struct polynom_list poly_backup = polynom_calculate[level_calc];
			while (degree_pol != $4) {
				polynom_calculate[level_calc] = multiplication(polynom_calculate[level_calc], poly_backup);
				degree_pol++;
			}
			for (int j = 0; j < COUNT_POLINOM; j++) {				
				for (int i = 0; i <= polynom_calculate[level_calc].max_degree; i++)
					polynom_calculate[level_calc].coeff_array[j][i] = polynom_calculate[level_calc].coeff_array[j][i] * $1;
			}
		}
	}
	| LETTER {
		if (1 > polynom_calculate[level_calc].max_degree) 
			polynom_calculate[level_calc].max_degree = 1;

		index_last_letter = $1 + 0;
		polynom_calculate[level_calc].coeff_array[index_last_letter][1] = 1;
	}
	| number LETTER {
		if (1 > polynom_calculate[level_calc].max_degree)
			polynom_calculate[level_calc].max_degree = 1;

		index_last_letter = $2 + 0;
		polynom_calculate[level_calc].coeff_array[index_last_letter][1] = $1;
	}
	| LETTER '^' degree {
		if ($3 > polynom_calculate[level_calc].max_degree)
			polynom_calculate[level_calc].max_degree = $3;

		index_last_letter = $1 + 0;
		polynom_calculate[level_calc].coeff_array[index_last_letter][$3 ] = 1;
	}
	| number LETTER '^' degree {
		if ($4 > polynom_calculate[level_calc].max_degree)
			polynom_calculate[level_calc].max_degree = $4;

		index_last_letter = $2 + 0;
		polynom_calculate[level_calc].coeff_array[index_last_letter][$4] = $1;
	}
	| number '^' degree {
		printf("number ^ degree %d %d\n", $1, $3);
		if ($1 == 0 && $3 == 0 ){
			error_list(ZERO_DEGREE);
		}
		$$ = pow($1, $3);
		if (0 >= polynom_calculate[level_calc].max_degree)
			polynom_calculate[level_calc].max_degree = 0;

		polynom_calculate[level_calc].coeff_array[index_last_letter][0] = $$;
	}
;

degree: number {
		$$ = $1;
		if ($$ > 255) {	error_list(MAX_DEGREE); }
	}
	| number '^' degree {
		if ($1 == 0 && $3 == 0 ){
			error_list(ZERO_DEGREE);
		}

		$$ = pow($1, $3);
		if ($$ > 255) { error_list(MAX_DEGREE); }
	}
	| '(' main ')' {
		printf("( main ) %d %d\n", polynom_calculate[level_calc].coeff_array[0][0], level_calc);
		$$ = polynom_calculate[level_calc - 1].coeff_array[0][0];
	}//{ error_list(NEGATIVE_DEGREE); }
	| LETTER { error_list(POLYNOM_DEGREE); }
	| BIG_LETTER '^' degree{
		//printf("$1 = %d, $3 = %d\n", polynoms[$1 + 0].coeff_array[0][0], polynoms[$3 + 0].coeff_array[0][0]);
		$$ = pow(polynoms[$1 + 0].coeff_array[0][0], $3);
		//printf("res: %d\n", $$);
	}
	| BIG_LETTER { 
		if (is_empty(polynoms[$1 + 0])) error_list(POLYNOM_DEGREE);
		$$ = polynoms[$1 + 0].coeff_array[0][0];
	}
;

number: DIGIT { $$ = $1; }
	| number DIGIT { $$ = $1 * 10 + $2; }
;

symbol: '+'
	| '-'
	| '*'
	| '/'
	| '^'
%%