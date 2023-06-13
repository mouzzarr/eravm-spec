From RecordUpdate Require Import RecordSet.
Require  sem.SemanticCommon.

Import Addressing Bool ZArith Common Condition Instruction ExecutionStack Memory MemoryOps State ZMod
  ZBits Addressing.Coercions RecordSetNotations SemanticCommon List ListNotations.

Section Def.
  Local Coercion u256_of : Z >-> int_mod.
  Open Scope Z_scope.
  Context (flags: flags_state) (regs: regs_state) (xstack: execution_stack) (pgs: pages).

  Inductive step_div: instruction -> flags_state * regs_state * execution_stack * pages -> Prop :=

  | step_Div_no_overflow:
    forall (arg_op1:in_any) (arg_op2:in_reg) (arg_out1:out_any) (arg_out2:out_reg)
      (any_tag1 any_tag2: bool)
      (mod_swap: mod_swap) (mod_flags: mod_set_flags)
      (x y:Z)
      new_regs new_xstack new_pages new_flags
      (quot rem: Z),
      
      fetch_apply22_swap mod_swap (regs,xstack,pgs)
        arg_op1 arg_op2 arg_out1 arg_out2

        (mk_pv any_tag1 x) (mk_pv any_tag2 y) (IntValue quot, IntValue rem)
        
        (new_regs, new_xstack, new_pages) ->
      y <> 0 ->
      quot = Z.div x y ->
      rem = Z.rem x y ->

      let new_EQ := quot == zero256 in
      let new_GT := rem == zero256 in 
      new_flags = apply_set_flags mod_flags flags (bflags false new_EQ new_GT) ->
      
      step_div (OpDiv arg_op1 arg_op2 arg_out1 arg_out2 mod_swap mod_flags)
        (new_flags, new_regs, new_xstack, new_pages)
        
  | step_Div_overflow:
    forall (arg_op1:in_any) (arg_op2:in_reg) (arg_out1:out_any) (arg_out2:out_reg)
      (any_tag1 any_tag2: bool)
      (mod_swap: mod_swap) (mod_flags: mod_set_flags)
      (x y:Z)
      new_regs new_xstack new_pages new_flags
      (quot rem: Z),
      
      fetch_apply22_swap mod_swap (regs,xstack,pgs)
        arg_op1 arg_op2 arg_out1 arg_out2

        (mk_pv any_tag1 x) (mk_pv any_tag2 0) (IntValue 0, IntValue 0)
        
        (new_regs, new_xstack, new_pages) ->

      new_flags = apply_set_flags mod_flags flags (bflags true false false) ->
      
      step_div (OpDiv arg_op1 arg_op2 arg_out1 arg_out2 mod_swap mod_flags)
        (new_flags, new_regs, new_xstack, new_pages).





End Def. 

Inductive step: instruction -> smallstep :=
| step_Div:
  forall flags regs xstack pages ins new_flags new_regs new_xstack new_pages context_u128 gs,
    step_div flags regs xstack pages ins (new_flags, new_regs, new_xstack, new_pages) ->
    step ins
         {|
           gs_flags        := flags;
           gs_regs         := regs;
           gs_callstack    := xstack;
           gs_pages        := pages;


           gs_context_u128 := context_u128;
           gs_global       := gs;
         |}
         {|
           gs_flags        := new_flags;
           gs_regs         := new_regs;
           gs_callstack    := new_xstack;
           gs_pages        := new_pages;


           gs_context_u128 := context_u128;
           gs_global       := gs;
         |}
.

