// Name: Austin Lehman & Andrew Westlund
// Assignment: Program 3
// Class: CSC453 Fall 2022
// File: symbol.c

#include "global.h"

#define STRMAX 999
#define SYMMAX 100

// Allow the lexemes characters combined to go up to STRMAX characters
int charCnt = 0;

// Create an array of Symbol structs
struct Symbol symTable[SYMMAX];
int lastEntry = 0;

// We want to return a reference to the Symbol entry of Symbol
Symbol *lookup(const char *s)
{
    /* TODO: TO BE COMPLETED */
    int p;
	Symbol *rc = NULL;
	for (p = 0; p < lastEntry; p++) {
		if (strcmp(symTable[p].lexptr, s) == 0) {
			rc = &symTable[p];
		}
	}
    return rc;	// Return a pointer to the found Symbol struct
}

Symbol *insert(const char *s, int tok)
{
    /* TODO: TO BE COMPLETED */
	int lexLen = strlen(s) + 1;
	if (lastEntry + 1 == SYMMAX) {
		error("Symbol table full");
	} else if (charCnt + lexLen >= STRMAX) {
		error("Too many ID characters");
	}
	
	symTable[lastEntry].token = tok;
	symTable[lastEntry].lexptr = (char *)malloc(lexLen);
	strcpy((char *)symTable[lastEntry].lexptr, s);	// Copy lexeme over
	charCnt += lexLen;
	symTable[lastEntry].localvar = -1;		// Assume keywords; install_ID overrides it
	lastEntry++;
	return &symTable[lastEntry - 1];		// Return a pointer to the inserted ID
}
