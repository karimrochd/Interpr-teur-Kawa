{

  open Lexing
  open Kawaparser

  exception Error of string

  let keyword_or_ident =
  let h = Hashtbl.create 17 in
  List.iter (fun (s, k) -> Hashtbl.add h s k)
    [ "print",    PRINT;
      "main",     MAIN;
      "return", RETURN;
      "class", CLASS;
      "new", NEW;
      "method", METHOD;
      "var", VAR;
      "attribute", ATTRIBUTE;
      "for", FOR;
      "while", WHILE;
      "if", IF;
      "else", ELSE;
      "void", VOID;
      "extends", EXTENDS;
      "this", THIS;
      "false", BOOL(false);
      "true", BOOL(true)
    ] ;
  fun s ->
    try  Hashtbl.find h s
    with Not_found -> IDENT(s)
}

let digit = ['0'-'9']
let number = ['-']? digit+
let alpha = ['a'-'z' 'A'-'Z']
let ident = ['a'-'z' '_'] (alpha | '_' | digit)*
let boolean = "true" | "false"
  
rule token = parse
  | ['\n']            { new_line lexbuf; token lexbuf }
  | [' ' '\t' '\r']+  { token lexbuf }

  | "//" [^ '\n']* "\n"  { new_line lexbuf; token lexbuf }
  | "/*"                 { comment lexbuf; token lexbuf }

  | number as n  { INT(int_of_string n) }
  | ident as id  { keyword_or_ident id }
  | boolean as b {BOOL(bool_of_string b)}
  | "void" {VOID}

  | "("  { LPAR }
  | ")"  { RPAR }
  | "{"  { BEGIN }
  | "}"  { END }
  | ";"  { SEMI }
  | "." {POINT}
  | "," {COMA}

  | number+ [' ']* "-"  { NEG }
  | "+"  { ADD }
  | "-"  { SUB }
  | "*"  { MUL }
  | "/"  { DIV }
  | "%"  { MOD }
  | "==" { EQ }
  | "!=" { NEQ }
  | "<"  { LT  }
  | "<=" { LE  }
  | ">"  { GT  }
  | ">=" { GE  }

  | "&&" { AND }
  | "||" { OR  }
  | "!"  { NOT }

  | "class" {CLASS}
  | "new" {NEW}
  | "attribute" {ATTRIBUTE}
  | "method" {METHOD}
  | "this" {THIS}
  | "extends" {EXTENDS}

  | "print" {PRINT}
  | "main" {MAIN}
  | "for" {FOR}
  | "while" {WHILE}
  | "if" {IF}
  | "else" {ELSE}
  | "return" {RETURN}
  | "var" {VAR}
  | "=" {SET}

  | _    { raise (Error ("unknown character : " ^ lexeme lexbuf)) }
  | eof  { EOF }

and comment = parse
  | "*/" { () }
  | _    { comment lexbuf }
  | eof  { raise (Error "unterminated comment") }
