%{

  open Lexing
  open Kawa

%}

%token <int> INT
%token <string> IDENT
%token <bool> BOOL
%token VOID
%token LPAR RPAR BEGIN END SEMI POINT COMA SET
%token NEG ADD SUB MUL DIV MOD EQ NEQ LT LE GT GE 
%token AND OR NOT
%token CLASS NEW ATTRIBUTE METHOD THIS EXTENDS
%token PRINT MAIN FOR WHILE IF ELSE RETURN VAR
%token EOF

%left MUL DIV
%left ADD SUB
%left EQ
%left AND OR

%start program
%type <Kawa.program> program

%%

program:
| glob=list(var_decl) cl=list(class_def) MAIN BEGIN main=list(instruction) END EOF
    { {classes=cl; globals=glob; main} }
;

typ:
|INT {TInt}
|BOOL {TBool}
|s=IDENT {TClass(s)}
|VOID {TVoid}
;

mem:
| s=IDENT {Var(s)}
| e=expression POINT s=IDENT {Field(e,s)}
;

var_decl:
| VAR t=typ s=IDENT SEMI; {(s,t)}

expression:
| n=INT { Int(n) }
| n=INT COMA { Int(n) }
| b=BOOL { Bool(b)}
| b=BOOL COMA { Bool(b)}
| op=unop e=expression { Unop(op,e)}
| e=expression op=binop ee=expression {Binop(op,e,ee)}
| m=mem {Get(m)}
| LPAR e=expression RPAR {e}
| THIS {This}
| NEW s=IDENT {New(s)}
| NEW s=IDENT LPAR elist=list(expression) RPAR {NewCstr(s,elist)}
| e=expression POINT s=IDENT LPAR elist=list(expression) RPAR {MethCall(e,s,elist)}
;

class_def:
| CLASS s=IDENT BEGIN att_list = list(attr_decl) meth_list = list(method_def) END { {class_name = s; attributes = att_list; methods = meth_list; parent = None} }
| CLASS s=IDENT EXTENDS ss=IDENT BEGIN att_list = list(attr_decl) meth_list = list(method_def) END { {class_name = s; attributes = att_list; methods = meth_list; parent = Some(ss)} }
;

attr_decl:
|ATTRIBUTE t=typ s=IDENT SEMI { (s,t) }
;

method_def:
|METHOD ret=typ s=IDENT LPAR params_meth=list(arg_def) RPAR BEGIN var_loc=list(var_decl) bloc=list(instruction) END { {method_name = s; code = bloc; params=params_meth; locals=var_loc; return = ret}}
;

arg_def:
| t=typ s=IDENT { (s,t)}
| t=typ s=IDENT COMA { (s,t)}
;

unop: 
| NEG {Neg}
| NOT {Not}
;

binop:
|ADD {Add}
|SUB {Sub}
|MUL {Mul}
|DIV {Div}
|MOD {Rem}
|EQ {Eq}
|NEQ {Neq}
|LT {Lt}
|LE {Le}
|GT {Gt}
|GE {Ge}
|AND {And}
|OR {Or}
;

instruction:
| PRINT LPAR e=expression RPAR SEMI { Print(e) }
| m=mem SET e=expression SEMI {Set(m,e)}
| IF e=expression BEGIN bloc1=list(instruction) END ELSE BEGIN bloc2=list(instruction) END {If(e,bloc1,bloc2)}
| WHILE LPAR e=expression RPAR BEGIN bloc=list(instruction) END {While(e,bloc)}
| FOR LPAR elist=list(expression) RPAR BEGIN bloc=list(instruction) END {For(elist,bloc)}
| RETURN e=expression SEMI {Return(e)}
| e=expression SEMI {Expr(e)}
;
