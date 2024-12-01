open Kawa

exception Error of string
let error s = raise (Error s)
let type_error ty_actual ty_expected =
  error (Printf.sprintf "expected %s, got %s"
           (typ_to_string ty_expected) (typ_to_string ty_actual))

module Env = Map.Make(String)
type tenv = typ Env.t

let add_env l tenv =
  List.fold_left (fun env (x, t) -> Env.add x t env) tenv l

let typecheck_prog p = 
  let find_class cm = List.find(fun cdef -> cdef.class_name=cm) p.classes in
  let tenv = add_env p.globals Env.empty in

  let rec check e typ tenv =
    let typ_e = type_expr e tenv in
    if (typ_to_string typ_e) <> (typ_to_string typ) then type_error typ_e typ 

  and type_expr e tenv = match e with
  | Int _  -> TInt
  | Bool _ -> TBool
  | Unop (op, e) -> (match op with | Neg -> check e TInt tenv; TInt | Not -> check e TBool tenv; TBool)
  | Binop (op, e1, e2) -> (match op with
                          | Add | Sub | Mul | Div | Rem -> check e1 TInt tenv; check e2 TInt tenv; TInt
                          | Lt | Le | Gt | Ge -> check e1 TInt tenv; check e2 TInt tenv; TBool
                          | Eq | Neq -> let t1 = type_expr e1 tenv in check e2 t1 tenv; TBool
                          | And | Or -> check e1 TBool tenv; check e2 TBool tenv; TBool)
  (*soit une variable (verifier qu'elle existe) soit un attribut (verifier que la classe existe et que l'attribut existe)*) 
  | Get (m) -> type_mem_access m tenv
  | This ->  Env.find "this" tenv
  (*trouver classe_n recuperer la methode constructeur et verifier si les argument sont les bon si c'est le cas on retourne la classe*)
  | New (classe_n) -> let _ = find_class classe_n  in TClass classe_n
  | NewCstr (classe_n, args) -> let cdef = find_class classe_n in
                            let constr = List.find (fun mdef -> (mdef.method_name = "constructor") && (List.length mdef.params = List.length args)) cdef.methods in
                            (*verifier que les arguments sont les bons*)
                            List.iter2 (fun a (_, t) -> check a t tenv) args constr.params;
                            TClass classe_n
  | MethCall (e, f, args) -> (*pareil mais on renvoie le type de retour de la methode*)begin
    let typ_e = type_expr e tenv in
    match typ_e with
      | TClass cn ->
        let cdef = find_class cn in
        let mdef = List.find (fun mdef -> (mdef.method_name = f) && (List.length args = List.length mdef.params)) cdef.methods in
        List.iter2 (fun a (_, t) -> check a t tenv) args mdef.params; 
        mdef.return
      | _ -> error "Method call on non-class type"
      end

  and type_mem_access m tenv = match m with
  | Var x -> Env.find x tenv
  | Field (objet, attribut) -> 
    (*verifie si type de objet est une class qui existe puis trouver les attribut de la classe et verifier si le type de attribut est le type d'un attribut de la classe de objet*)
      let typ_e = type_expr objet tenv in
      (match typ_e with
      | TClass cn -> let rec find_all_par cd = 
                      try List.find (fun (name, _) -> name = attribut) cd.attributes 
                      with Not_found -> (match cd.parent with
                                      | Some par -> find_all_par (find_class par)
                                      | None -> failwith "Typechecker: attribute not found in class and all parents")
                      in
                    let _, attrib_type = find_all_par (find_class cn)
                    in
                    attrib_type
      | _ -> error "Accessing field of a non-class type")
  in

  let subclass t1 t2 = 
    let cdef1 = find_class t1 in 
    let cdef2 = find_class t2 in

    let rec aux cn1 cn2 = 
      if (cn1 = cn2.class_name ) then true 
      else begin
        (match cn2.parent with
        | Some s -> aux cn1 (find_class s)
        | None -> false
        )
      end
    in
    (match cdef1.parent with 
    |Some s -> aux s cdef2
    |None -> false)
  in

  let rec check_instr i ret tenv = match i with
    | Print e -> let typ = type_expr e tenv in if ((typ_to_string typ) = "void") then failwith "print void type expression"
    | If(e, s1, s2) -> check e TBool tenv; check_seq s1 ret tenv; check_seq s2 ret tenv 
    | While (e, s) -> check e TBool tenv; check_seq s ret tenv
    (*A vérifier*)
    | For(elist,inlist) -> check_exprlist elist ret tenv; check_seq inlist ret tenv;
    | Set(m,e) -> let t1 = type_mem_access m tenv in 
                  let s1 = typ_to_string t1 in
                  if (s1 <> "int") && (s1 <> "void") && (s1 <> "bool") then begin 
                  match (type_expr e tenv) with 
                    | TClass s -> if (s1 <> s) then assert (subclass s s1)
                    | _ -> failwith "Set a non object value"
                  end
                  else check e t1 tenv  
    | Return(e) -> if ret != TVoid then check e ret tenv else failwith "return type void"
    | Expr(e) -> check e TVoid tenv
    
  and check_seq s ret tenv = List.iter (fun i -> check_instr i ret tenv) s
  and check_exprlist s ret tenv = List.iter (fun i -> check i ret tenv) s in
  
  let check_mdef mdef tenv =
    (*On crée un environnement locale à la méthode contenant ses variables locales*)
    let local_env = add_env mdef.locals tenv in
    (*On vérifie le code  de la méthode avec son environnement dans lequel on ajoute les paramètres*)
    check_seq mdef.code mdef.return (add_env mdef.params local_env)
  in
  

  let rec check_class cdef tenv =
    match cdef.parent with
    | None -> (*On crée un environnement contenant les noms et types de retours de chaque méthode*)
    let method_env = List.fold_left (fun env mdef -> Env.add mdef.method_name mdef.return env) tenv cdef.methods in
    (*On vérifie que le code de chaque méthode est cohérent*)
    List.iter (fun mdef -> check_mdef mdef method_env) cdef.methods;
    | Some par -> (*Cas où la classe cdef a un parent*)
        (* On cherche la classe parent *)
        let par_cdef = (try find_class par with Not_found -> failwith "Typechecker : classe parent introuvable ")in

        (* On crée une fonction qui va ajouter toutes les variables et méthodes de tous les parents à l'environnement tenv*)
        let rec add_env_par cdef tenv =
          let var_par_env = List.fold_left (fun fenv (att_n,att_typ) -> Env.add att_n att_typ fenv ) tenv par_cdef.attributes in
          let meth_par_env = List.fold_left (fun fenv mdef -> Env.add mdef.method_name mdef.return fenv) var_par_env par_cdef.methods in
          (match cdef.parent with
          | None -> meth_par_env
          | Some s -> add_env_par (find_class s) meth_par_env
          )
        in 
        let par_env = add_env_par par_cdef tenv in
        (* On peut désormais ajouter ce qu'il y a dans la classe, si il a conflit, on priorise la classe fille *)
        let var_env = List.fold_left (fun fenv (att_n,att_typ) -> Env.add att_n att_typ fenv ) par_env cdef.attributes in
        let meth_env = List.fold_left (fun fenv mdef -> Env.add mdef.method_name mdef.return fenv) var_env cdef.methods in
        (* On vérifie que chaque méthode est bien typée*)
        List.iter (fun mdef -> check_mdef mdef meth_env ) cdef.methods
        
  and check_class_seq seq_c tenv = 
    List.iter (fun c -> let tenv = Env.add "this" (TClass c.class_name) tenv in check_class c tenv) seq_c 
  in

  check_class_seq p.classes tenv;
  check_seq p.main TVoid tenv
