open Kawa

type value =
  | VInt  of int
  | VBool of bool
  | VObj  of obj
  | Null
and obj = {
  cls:    string;
  fields: (string, value) Hashtbl.t;
}

exception Error of string
exception Return of value

let exec_prog (p: program): unit =

  (* Création de l'environnement *)
    let env = Hashtbl.create 16 in
    List.iter (fun (x, _) -> Hashtbl.add env x Null) p.globals;

    let find_class cm = List.find(fun cdef -> cdef.class_name=cm) p.classes in
    let find_cdef_par cdef = (match cdef.parent with | Some s -> find_class s | None -> cdef) in

  (* Fonction qui exécute la séquence d'instruction en prenant l'environnement locale lenv *)
  let rec eval_seq s lenv =
    (* Fonctions auxiliaire pour évaluer chaque expressions int/bool/obj/NULL*)
    let rec evalb e = match eval e with
      | VBool b -> b
      | _ -> assert false
    and evalo e = match eval e with
      | VObj o -> o
      | _ -> assert false

    (* Fonction eval qui selon l'expression renvoie un type value avec la valeur correspondante *)
    and eval (e: expr): value = match e with
      | Int n  -> VInt n
      | Bool b -> VBool b
      | Unop(op,e) -> (*unop consécutif ne fonctionne pas*)(match op,eval e with | Neg, VInt n -> VInt(0 - n) | Not, VBool b -> VBool (not b) | _,_ -> failwith "exec Unop wrong")                       
      | Binop(op,e1,e2) ->  (match op, eval e1, eval e2 with
                            | Add, VInt n1, VInt n2 -> VInt (n1 + n2)
                            (*Ne fonctionne pas*)
                            | Sub, VInt n1, VInt n2 -> VInt (n1 - n2)
                            | Mul, VInt n1, VInt n2 -> VInt (n1 * n2)
                            | Div, VInt n1, VInt n2 -> VInt (n1 / n2)
                            | Rem, VInt n1, VInt n2 -> VInt (n1 mod n2)
                            | Le, VInt n1, VInt n2 -> VBool (n1 <= n2)
                            | Lt, VInt n1, VInt n2 -> VBool (n1 < n2)
                            | Ge, VInt n1, VInt n2 -> VBool (n1 >= n2)
                            | Gt, VInt n1, VInt n2 -> VBool (n1 > n2)
                            | Eq, VInt n1, VInt n2 -> VBool (n1 = n2)
                            | Eq, VBool b1, VBool b2 -> VBool (b1 = b2)
                            | Neq, VInt n1, VInt n2 -> VBool (n1 <> n2)
                            | Neq, VBool b1, VBool b2 -> VBool (b1 <> b2)
                            | And, VBool b1, VBool b2 -> VBool (b1 && b2)
                            | Or, VBool b1, VBool b2 -> VBool (b1 || b2)
                            | _,_,_ -> failwith "binop not implemented" 
                            )
      | Get access -> (match access with
                  | Var s -> Hashtbl.find lenv s
                  | Field(o,attribute) -> (match eval o with 
                                          | VObj tmp -> Hashtbl.find (tmp.fields) attribute 
                                          | _ -> failwith "not an object"))
      | This -> Hashtbl.find lenv "this" 
      | New o -> let obj = VObj { cls = o; fields = Hashtbl.create 8 } in Hashtbl.add lenv "this" obj; obj
      | NewCstr (class_name, args) -> 
          let obj = { cls = class_name; fields = Hashtbl.create 16 } in
          Hashtbl.iter (fun s _ -> Hashtbl.replace obj.fields s Null ) obj.fields;
          let _ = eval_call "constructor"  obj args in 
          VObj obj          
      | MethCall(obj,meth_n,meth_args) -> eval_call meth_n (evalo obj) meth_args

    and eval_call f this args = 
      (*On cherche la définition de classe de l'objet*)
      let cdef = List.find (fun c -> c.class_name = this.cls) p.classes in
      (*On cherche la méthode correspondante*)
      let mdef = try List.find (fun m -> (m.method_name = f) && (List.length args = List.length m.params)) cdef.methods 
          with Not_found -> (match cdef.parent with 
                            | Some par -> let cdef_par = List.find (fun c -> c.class_name = par) p.classes in
                                          List.find (fun m -> (m.method_name = f) && (List.length args = List.length m.params)) cdef_par.methods 
                            | None -> failwith "Interpreter: Method not found")
        in
        (* Bout de code pour l'héritage de plus d'une classe, ne fonctionne pas
      let rec check_all_par cd = 
        let cdef_par = find_cdef_par cd in
        if (cdef.class_name <> cdef_par.class_name) then 
          try List.find (fun m -> (m.method_name = f) && (List.length args = List.length m.params)) cdef_par.methods with Not_found -> check_all_par cdef_par
        else failwith "Interpreter: Method not found"
      in
      let mdef = check_all_par cdef in*)
      (*exécution du code de la méthode avec un environnement locale, eval_seq se charge de renvoie la value correspondante*)
      let local_env = Hashtbl.create 16 in
      (*On ajoute dans l'environnement locale les arguments, les champs de l'objets, les var globales*)
      List.iter2 (fun a (s, _) -> Hashtbl.add local_env s (eval a)) args mdef.params;
      Hashtbl.iter (fun s v -> Hashtbl.add local_env s v ) this.fields;
      List.iter (fun (s,_) -> Hashtbl.add local_env s (try (Hashtbl.find lenv s) with Not_found -> Null ) ) p.globals;
      Hashtbl.add local_env "this" (VObj this);
      try eval_seq mdef.code local_env; Null
      with Return v -> v
      | Not_found -> (match cdef.parent with 
                     | Some par -> (* On ajoute les attributs de la classe mère *)
                                    Hashtbl.iter (fun s v -> Hashtbl.add local_env s v ) this.fields;
                                    (try eval_seq mdef.code local_env; Null with Return v -> v)
                     | None -> failwith "Interpreter: not_found"; Null)
      (*On exécute le code de la méthode et on renvoie la valeur s'il y en a*)
          (*
          let rec try_eval_seq cdef = 
            (* Rend void*)
            try eval_seq mdef.code local_env; Null
            (* Rend quelque chose*)
            with | Return v -> v 
            (* Y'a quelque chose qui manque, on va chercher dans les classes mère *)
            | Not_found -> let tmp = find_cdef_par cdef in 
                         if (tmp.class_name <> cdef.class_name) then begin
                          Hashtbl.iter (fun s v -> Hashtbl.add local_env s v ) this.fields;
                          try_eval_seq tmp 
                         end
                         else failwith "Interpreter: not_found"*)
                         (* Fonction évaluation de méthodes *)
                                        
    
    (* Fonction exec qui prends une instruction et l'exécute *)
    and exec (i: instr): unit = match i with
      | Print(e) ->  (match eval e with
                    | VInt n -> Printf.printf "%d\n" n
                    | VBool b -> Printf.printf "%b\n" b
                    | VObj o -> Printf.printf "%s\n" o.cls
                    | _ -> failwith "Invalid print argument")
      | Set(so,e) -> (match so with
                    | Var(svar) -> Hashtbl.replace lenv svar (eval e)    
                    | Field(o,valo) -> match eval o with
                                       | VObj tmp -> Hashtbl.replace (tmp.fields) valo (eval e)
                                       | _ -> failwith "Object doesn't exist")
      | If (cond, s1, s2) -> if evalb cond then exec_seq s1 else exec_seq s2
      | While (cond, s) -> while evalb cond do exec_seq s done
      | Return(expr) -> raise (Return (eval expr))
      | Expr(expr) -> (match expr with 
                      | MethCall(e,f,args) -> let _ = eval_call f (evalo e) args in ()
                      | _ -> failwith "not a methcall") 
      | _ -> failwith "case not implemented in exec"
    
    (* Foncion qui exécute toutes les instructions contenue dans s *)
    and exec_seq s = 
      List.iter exec s
    in

    exec_seq s
  in
  (* On appelle exec_seq sur toutes les instructions dans le main *)
  eval_seq p.main (Hashtbl.create 1)
