(**
This is an attempt at partially formalizing one of the systems in Hein's
book.

Questions:
 - How widely applicable is this style of proof?
 - What other styles of proof does he use, and are they worth formalizing?
    - One is equational reasoning
 - Is another proof tool more appropriate?
    - Isabelle (which can be customized to a specific logic)
    - Alfa, which might be customizable, but regardless is really cool
      because it's a syntax-tree editor so syntax errors are (nearly)
      impossible

With this draft there are some issues.  The only reason these are issues
is because I'm making the assumption that we don't want to burdon the 
students with learning anything about the tool, and instead we want
something whose look and feel correspond to the text as close as possible.
  - Some tactics are slightly ambiguous: eg Simpl has to be made into
    Simpl_left and Simpl_right
  - Some tactics are highly ambiguous: eg T will need to have an
    explicit reference to the previous result
  - In order to reuse a previous result (for instance with Hein's
    "T") we need to generalize and then instantiate that previous
    result.  The simplest way is to explicitly list all props in 
    the declaration of the theorem.

Other things:
  - The tactic language Ltac allows us to give very good diagnostic
    messages when a student tries something inappropriate. (see DS).
  - We'd have to categorize the tactics as forward reasoning (eg Cong),
    backward reasoning (bwd_Add), and mixed (P_with_CP).  Might be
    initially confusing, but it's a good thing for students to
    understand

Related work.
 - we used a vastly simplified version of Mizar (http://mizar.uwb.edu.pl/)
   for an intro course at the U of Alberta.  It sucked, but only because
   students were challenged by their syntax errors, not by their logic
   errors.  
*)


(** The use of [H0] as an axiom name, together with the use of [fresh "H0"]
  in the tactics allows us to name intermediate results consistently with
  those in Hein's book.

  A proof a la Hein appears in one pane of the Coq browser (sadly,
  when you finish the proof, it disappears a bit too early).
*)

Require Import Classical.

Notation "A -> B" := (A->B) (at level 84, no associativity).

Axiom excluded_middle: forall P:Prop, P \/ ~P.
Axiom H0 : Prop.

Ltac Universal_Intros :=
   (* Todo: insert a call to this macro into every tactic accessible by the student *)
   match goal with
   | [ |- forall _:Prop, _ ] => intro; Universal_Intros
   | _ => idtac
   end.

Ltac IP := assumption.

Ltac Solve_With H :=
  (* I'm not sure this is a tactic that should be pushed up *)
  apply H || fail "The hypothesis entered does not exist".


Ltac P_with_CP :=
   Universal_Intros;
   let H := fresh "H0" in
   let tmp := fresh "tmp" in
   match goal with
   | [ |- ?a /\ ?b -> ?c ] => intros [H tmp]; generalize tmp; clear tmp
   | [ |- ?a       -> ?c ] => intro H
   | [ |- ~?a -> _ ] => intro H
   | _ => idtac "[appropriate error message]"
   end.

Ltac Conj L R :=
   Universal_Intros;
   let TL := type of L in
   let TR := type of R in
   let H := fresh "H0" in
   assert (H: TL /\ TR)
   ; [ apply conj; assumption | try assumption ]
   .


Example or_swaps P Q :(P \/ Q) <-> (Q \/ P). 
  split; intro; destruct H; [right | left | right | left]; assumption. Qed.

Ltac Split_Eq :=
  split || fail "This statement cannot be split into cases".

Ltac DS D N :=
   let H := fresh "H0" in
     match type of N with
       | ~ ?A' =>
         match type of D with
           | ?A \/ ?B =>
             match A with
               | A'  => idtac "Using ~"A' "to prove" B; assert(H:B); [tauto | try assumption]
             end ||
             match B with 
               | A' => idtac "Using ~"A' "to prove" A; assert (H:A); [tauto | try assumption]
             end ||
             idtac "1: This failed"
           | ?T => idtac "The justification" T "is expected to be a disjunction: _ \/ _"
         end
       | ?A' =>
         match type of D with
           | ?A \/ ?B =>
             match A with
               | ~A'  => idtac "Using" A' "to prove" B; assert(H:B); [tauto | try assumption]
             end ||
             match B with 
               | ~A' => idtac "Using" A' "to prove" A; assert (H:A); [tauto | try assumption]
             end ||
             idtac "2: This failed"
           | ?T => idtac "The justification" T "is expected to be a disjunction: _ \/ _"
         end
     end.

Example ds_unit_1 P Q:  (P\/Q) -> (~P->Q). 
P_with_CP. P_with_CP. DS H1 H2. Qed.

Example ds_unit_2 P Q:  (~P\/Q) -> (P->Q). 
P_with_CP. P_with_CP. DS H1 H2. Qed.

Example ds_unit_3 P Q:  (P\/Q) -> (~Q -> P). 
P_with_CP. P_with_CP. DS H1 H2. Qed.

Example ds_unit_4 P Q:  (P\/~Q) -> (Q -> P). 
P_with_CP. P_with_CP. DS H1 H2. Qed.


Ltac Pose D For N :=
  let H := fresh "H0" in 
    let H' := fresh "H0" in 
      match D with
        | ~N =>
          destruct(excluded_middle N) as [H | H'] ; [try right; try assumption |]
            | ~D => idtac "You cannot pose that" D
            | _ => idtac "Not matching" D N
      end.

Ltac Contr A B:= 
  try apply A in B; contradiction || apply B in A; contradiction ||
    idtac "No such contradiction found in the current proof".


Ltac DN H :=
  Universal_Intros;
  let H1 := fresh "H0" in
  match type of H with
    | ?A' => 
      match A' with
        | ~~_ => apply NNPP in H; try assumption
      end
    (* | H => intros H1; apply H1; try assumption *)
    | _ => idtac "Double Negation can not solve this problem" H
end.


Ltac bwd_Add := left.
Ltac fwd_Add := right.

Ltac add1 H B :=
   let H' := fresh "H0" in
   let A := type of H in
   assert (H' : A \/ B); [ left; try assumption | ].

Ltac add2 H B :=
   let H' := fresh "H0" in
   let A := type of H in
   assert (H' : B \/ A); [ right; try assumption | ].


Ltac MP f x :=
   let H := fresh "H0" in
   let T := type of (f x) in
   assert (H : T); [ apply  (f x) | ].

Ltac Simp_right C :=
   let H := fresh "H0" in
   let P := type of C in
   match P with
   | ?l /\ ?r => assert (H:r); [ destruct C; assumption | try assumption ]
   | _ => idtac "[insert appropriate error message]"
   end.

Ltac MT H N := 
  let C := fresh "H0" in
    let P := type of H in  
      match P with
        | ?p -> ?q => 
          match type of N with
            | ~q => assert (C: ~q -> ~p); intros; [tauto |] ; apply C in N; clear C
            | ?T => idtac T "is not a negation of " q
          end
        | ?T => idtac T "was expected to be an implication" 
      end.


Lemma ex_6_19 P : (~~P) <-> P. 
P_with_CP.
Split_Eq.
  P_with_CP.
  Pose (~P) For P.
  Contr H1 H.
  P_with_CP.
  Pose (~~P) For (~P).
  Contr H1 H.
  IP.
Qed.

Lemma ex_6_20 A B: (A \/ B) -> (~B -> A).
P_with_CP.
P_with_CP.
Pose (~A) For A.
DS H1 H4.
Contr H2 H3.
Qed.

Lemma ex_6_21 (A B: Prop): A -> (B\/A).
P_with_CP.
add1 H1 B.
Pose (~A) For (A). 
DS H2 H4.
add1 H3 A.
IP.
Qed.

Lemma ex_6_22 (A B:Prop): (A -> B) -> (~B -> ~A).  
  Universal_Intros.
  P_with_CP.
  P_with_CP.
  Pose(~~A) For (~A). 
  DN H4.
  MP H1 H4.
  Contr H2 H3.
Qed.

Lemma ex_6_23 (A B C:Prop): (A\/B) -> ((A -> C) -> ((B -> C) -> C)).
Universal_Intros. 
P_with_CP.
P_with_CP.
P_with_CP.
Pose (~C) For (C).
MT H2 H5.
DS H1 H5. 
MP H3 H4. 
IP.
Qed.

Lemma ex_6_24 (A B C: Prop) : (A -> B) -> ((B -> C) -> (A -> C)).
Universal_Intros.
P_with_CP.
P_with_CP.
P_with_CP.
MP H1 H3. 
MP H2 H4.
IP.
Qed.

Lemma ex_6_25 (A B D C: Prop) : (A\/B) -> ((A -> C) -> ((B -> D) -> (C\/D))).
  Universal_Intros.
  P_with_CP.
  P_with_CP.
  P_with_CP.
  (* We'll need a tactic to allow the reasoning by cases here *)
  (* Pose A For (A-> (C\/D)). *)
  destruct H1. MP H2 H. add1 H1 D. IP.
               MP H3 H. add2 H1 C. IP.
Qed.  
  
Lemma p374_6_8 A B C: (A \/ B) /\ (A \/ C) /\ ~A -> B /\ C.
P_with_CP.
P_with_CP.
P_with_CP.
DS H1 H3.
DS H2 H3.
Conj H4 H5.
Qed.


Lemma p375_6_9 A B C D: ((A \/ B) -> (B /\ C)) -> ((B -> C) \/ D).
P_with_CP.
bwd_Add.
P_with_CP.
add2 H2 A.
MP H1 H3.
Simp_right H4. (* Simp alone is too vague *)
Qed.


Lemma ex_6_28 P Q: (~P\/Q) <-> (P -> Q).
Universal_Intros.
Split_Eq.
  (* Case -> *)
  P_with_CP.
  P_with_CP.
  DS H1 H2.
  (* Case <- *)
  P_with_CP.
  (* Here is where the book starts to get it wrong, I have patched below*)
  (* Pose(~(~P\/Q)) For (~P\/Q). *)
  (* Pose (~P) For P. *)
  (* DS H H2. *)
  Pose (~P) For P.
  MP H1 H.
  IP.
  bwd_Add.
  IP.
Qed.