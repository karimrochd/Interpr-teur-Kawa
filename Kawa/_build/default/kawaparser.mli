
(* The type of tokens. *)

type token = 
  | WHILE
  | VOID
  | VAR
  | THIS
  | SUB
  | SET
  | SEMI
  | RPAR
  | RETURN
  | PRINT
  | POINT
  | OR
  | NOT
  | NEW
  | NEQ
  | NEG
  | MUL
  | MOD
  | METHOD
  | MAIN
  | LT
  | LPAR
  | LE
  | INT of (int)
  | IF
  | IDENT of (string)
  | GT
  | GE
  | FOR
  | EXTENDS
  | EQ
  | EOF
  | END
  | ELSE
  | DIV
  | COMA
  | CLASS
  | BOOL of (bool)
  | BEGIN
  | ATTRIBUTE
  | AND
  | ADD

(* This exception is raised by the monolithic API functions. *)

exception Error

(* The monolithic API. *)

val program: (Lexing.lexbuf -> token) -> Lexing.lexbuf -> (Kawa.program)
