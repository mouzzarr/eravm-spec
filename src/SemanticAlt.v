From RecordUpdate Require Import RecordSet.
Require SemanticCommon FarCalls.

Import Bool ZArith Common CodeStorage Condition FarCalls MemoryBase Memory MemoryOps Instruction State ZMod
  ZBits ABI ABI.FarCall ABI.Ret ABI.NearCall ABI.FatPointer Arg Arg.Coercions RecordSetNotations SemanticCommon.

Inductive step_ins: instruction -> global_state -> global_state -> Prop :=
(**
<<
## Far calls
>>
*)

|step_FarCall: forall gs gs' abi dest handler is_static,
    step_farcall (OpFarCall abi dest handler is_static) gs gs' ->
    step_ins (OpFarCall abi dest handler is_static) gs gs'

(**
<<
## NoOp

Performs no operations.
>>
*)
| step_NoOp:
  forall gs, step_ins OpNoOp gs gs

(**
<<
## ModSP

>>
Performs no operations with memory, but may adjust SP using address modes
[RelSpPop] and [RelSPPush].
*)
| step_ModSP:
  forall codes flags storages mem_pages xstack0 xstack1 new_xstack context_u128 in1 out1 regs,
    resolve_effect__in in1 xstack0 xstack1 ->
    resolve_effect__out out1 xstack1 new_xstack ->
    step_ins (OpModSP in1 out1)
          {|
          gs_callstack    := xstack0;


          gs_flags        := flags;
          gs_regs         := regs;
          gs_mem_pages    := mem_pages;
          gs_storages     := storages;
          gs_context_u128 := context_u128;
          gs_contract_code:= codes;
          |}
          {|
          gs_callstack    := new_xstack;


          gs_flags        := flags;
          gs_regs         := regs;
          gs_mem_pages    := mem_pages;
          gs_storages     := storages;
          gs_context_u128 := context_u128;
          gs_contract_code:= codes;
          |}
(**
<<
## Add
Unsigned addition of two numbers.
>>
*)
  | step_Add:
    forall codes flags new_flags mod_swap mod_sf storages mem_pages new_mem_pages xstack new_xstack context_u128 (in1:in_any) (in2:in_reg) out regs new_regs,

      binop_effect xstack regs mem_pages flags in1 in2 out mod_swap mod_sf
        (fun x y =>
          let (result, NEW_OF) := x + y in
          let NEW_EQ := EQ_of_bool (result == zero256) in
          let NEW_GT := GT_of_bool (negb NEW_EQ && negb NEW_OF) in
          (result, mk_fs (OF_LT_of_bool NEW_OF) NEW_EQ NEW_GT))
        (new_xstack, new_regs, new_mem_pages, new_flags) ->

      step_ins (OpAdd in1 in2 out mod_swap mod_sf)
        {|
          gs_flags        := flags;
          gs_regs         := regs;
          gs_mem_pages    := mem_pages;
          gs_callstack    := xstack;


          gs_storages     := storages;
          gs_context_u128 := context_u128;
          gs_contract_code:= codes;
        |}
        {|
          gs_flags        := new_flags;
          gs_regs         := new_regs;
          gs_mem_pages    := new_mem_pages;
          gs_callstack    := new_xstack;


          gs_storages     := storages;
          gs_context_u128 := context_u128;
          gs_contract_code:= codes;
        |}
(**
<<
## Sub
Unsigned subtraction of two numbers.
>>
*)

| step_Sub:
    forall codes flags new_flags mod_swap mod_sf storages mem_pages new_mem_pages xstack new_xstack context_u128 (in1:in_any) (in2:in_reg) out regs new_regs,

      binop_effect xstack regs mem_pages flags in1 in2 out mod_swap mod_sf
        (fun x y =>
          let (result, NEW_OF) := x - y in
          let NEW_EQ := EQ_of_bool (result == zero256) in
          let NEW_GT := GT_of_bool (negb NEW_EQ && negb NEW_OF) in
          (result, mk_fs (OF_LT_of_bool NEW_OF) NEW_EQ NEW_GT))
        (new_xstack, new_regs, new_mem_pages, new_flags) ->

      step_ins (OpSub in1 in2 out mod_swap mod_sf)
        {|
          gs_flags        := flags;
          gs_regs         := regs;
          gs_mem_pages    := mem_pages;
          gs_callstack    := xstack;


          gs_storages     := storages;
          gs_context_u128 := context_u128;
          gs_contract_code:= codes;
        |}
        {|
          gs_flags        := new_flags;
          gs_regs         := new_regs;
          gs_mem_pages    := new_mem_pages;
          gs_callstack    := new_xstack;


          gs_storages     := storages;
          gs_context_u128 := context_u128;
          gs_contract_code:= codes;
        |}
(**
<<
## And
Bitwise AND of two numbers.
>>
*)

| step_And:
    forall codes flags new_flags mod_swap mod_sf storages mem_pages new_mem_pages xstack new_xstack context_u128 (in1:in_any) (in2:in_reg) out regs new_regs,

      binop_effect xstack regs mem_pages flags in1 in2 out mod_swap mod_sf
        (fun x y => let result := bitwise_and _ x y in (result, (mk_fs Clear_OF_LT (EQ_of_bool (result == zero256)) Clear_GT)))
        (new_xstack, new_regs, new_mem_pages, new_flags) ->

      step_ins (OpAnd in1 in2 out mod_swap mod_sf)
        {|
          gs_flags        := flags;
          gs_regs         := regs;
          gs_mem_pages    := mem_pages;
          gs_callstack    := xstack;


          gs_storages     := storages;
          gs_context_u128 := context_u128;
          gs_contract_code:= codes;
        |}
        {|
          gs_flags        := new_flags;
          gs_regs         := new_regs;
          gs_mem_pages    := new_mem_pages;
          gs_callstack    := new_xstack;


          gs_storages     := storages;
          gs_context_u128 := context_u128;
          gs_contract_code:= codes;
        |}
(**
<<
## Or
Bitwise OR of two numbers.
>>
*)
| step_Or:
    forall codes flags new_flags mod_swap mod_sf storages mem_pages new_mem_pages xstack new_xstack context_u128 (in1:in_any) (in2:in_reg) out regs new_regs,

      binop_effect xstack regs mem_pages flags in1 in2 out mod_swap mod_sf
        (fun x y => let result := bitwise_or _ x y in (result, (mk_fs Clear_OF_LT (EQ_of_bool (result == zero256)) Clear_GT)))
        (new_xstack, new_regs, new_mem_pages, new_flags) ->

      step_ins (OpOr in1 in2 out mod_swap mod_sf)
        {|
          gs_flags        := flags;
          gs_regs         := regs;
          gs_mem_pages    := mem_pages;
          gs_callstack    := xstack;


          gs_storages     := storages;
          gs_context_u128 := context_u128;
          gs_contract_code:= codes;
        |}
        {|
          gs_flags        := new_flags;
          gs_regs         := new_regs;
          gs_mem_pages    := new_mem_pages;
          gs_callstack    := new_xstack;


          gs_storages     := storages;
          gs_context_u128 := context_u128;
          gs_contract_code:= codes;
        |}

(**
<<
## Xor
Bitwise XOR of two numbers.
>>
*)
| step_Xor:
    forall codes flags new_flags mod_swap mod_sf storages mem_pages new_mem_pages xstack new_xstack context_u128 (in1:in_any) (in2:in_reg) out regs new_regs,

      binop_effect xstack regs mem_pages flags in1 in2 out mod_swap mod_sf
        (fun x y => let result := bitwise_or _ x y in (result, (mk_fs Clear_OF_LT (EQ_of_bool (result == zero256)) Clear_GT)))
        (new_xstack, new_regs, new_mem_pages, new_flags) ->

      step_ins (OpXor in1 in2 out mod_swap mod_sf)
        {|
          gs_flags        := flags;
          gs_regs         := regs;
          gs_mem_pages    := mem_pages;
          gs_callstack    := xstack;


          gs_storages     := storages;
          gs_context_u128 := context_u128;
          gs_contract_code:= codes;
        |}
        {|
          gs_flags        := new_flags;
          gs_regs         := new_regs;
          gs_mem_pages    := new_mem_pages;
          gs_callstack    := new_xstack;


          gs_storages     := storages;
          gs_context_u128 := context_u128;
          gs_contract_code:= codes;
        |}
(**
<<
## Near calls

Calls the code inside the current contract space.

>>
         *)
 | step_NearCall_pass_some_ergs:
    forall codes flags storages mem_pages xstack0 context_u128 regs (abi_params_op:in_reg) abi_params_value call_addr expt_handler ergs_left passed_ergs,

      resolve_fetch_word regs xstack0 mem_pages abi_params_op abi_params_value ->

      Some passed_ergs = option_map NearCall.nca_get_ergs_passed (NearCall.ABI.(decode) abi_params_value) ->

      passed_ergs <> zero32 ->

      (ergs_left, false) = ergs_remaining xstack0 - passed_ergs  ->

      let new_frame := mk_cf expt_handler (sp_get xstack0) call_addr passed_ergs in
      step_ins (OpNearCall abi_params_op (Imm call_addr) (Imm expt_handler))
        {|
          gs_flags        := flags;
          gs_callstack    := xstack0;


          gs_regs         := regs;
          gs_mem_pages    := mem_pages;
          gs_storages     := storages;
          gs_context_u128 := context_u128;
          gs_contract_code:= codes;
        |}
        {|
          gs_flags        := flags_clear;
          gs_callstack    := InternalCall new_frame (ergs_set ergs_left xstack0);


          gs_regs         := regs;
          gs_mem_pages    := mem_pages;
          gs_storages     := storages;
          gs_context_u128 := context_u128;
          gs_contract_code:= codes;
        |}

 | step_NearCall_underflow_pass_all_ergs:
    forall codes flags storages mem_pages xstack0 context_u128 regs (abi_params_op:in_reg) abi_params_value call_addr expt_handler ergs_underflown passed_ergs,
      resolve_fetch_word regs xstack0 mem_pages abi_params_op abi_params_value ->
      Some passed_ergs = option_map NearCall.nca_get_ergs_passed (NearCall.ABI.(decode) abi_params_value) ->
      passed_ergs <> zero32 ->

      (ergs_underflown, true) = ergs_remaining xstack0 - passed_ergs  ->

      let new_frame := mk_cf expt_handler (sp_get xstack0) call_addr (ergs_remaining xstack0) in
      step_ins (OpNearCall abi_params_op (Imm call_addr) (Imm expt_handler))
        {|
          gs_flags        := flags;
          gs_callstack    := xstack0;


          gs_regs         := regs;
          gs_mem_pages    := mem_pages;
          gs_storages     := storages;
          gs_context_u128 := context_u128;
          gs_contract_code:= codes;
        |}
        {|
          gs_flags        := flags_clear;
          gs_callstack    := InternalCall new_frame (ergs_zero xstack0);


          gs_regs         := regs;
          gs_mem_pages    := mem_pages;
          gs_storages     := storages;
          gs_context_u128 := context_u128;
          gs_contract_code:= codes;
        |}

  | step_NearCall_pass_all_ergs:
    forall codes flags storages mem_pages xstack0 xstack1 context_u128 regs (abi_params_op:in_reg) abi_params_value call_addr expt_handler,
      resolve_fetch_word regs xstack0 mem_pages abi_params_op abi_params_value ->

      option_map NearCall.nca_get_ergs_passed  (NearCall.ABI.(decode) abi_params_value)= Some zero32 ->

      let new_frame := mk_cf expt_handler (sp_get xstack0) call_addr (ergs_remaining xstack0) in
      step_ins (OpNearCall abi_params_op (Imm call_addr) (Imm expt_handler))
        {|
          gs_flags        := flags;
          gs_callstack    := xstack0;


          gs_regs         := regs;
          gs_mem_pages    := mem_pages;
          gs_storages     := storages;
          gs_context_u128 := context_u128;
          gs_contract_code:= codes;
        |}

        {|
          gs_flags        := flags_clear;
          gs_callstack    := InternalCall new_frame (ergs_zero xstack1);


          gs_regs         := regs;
          gs_mem_pages    := mem_pages;
          gs_storages     := storages;
          gs_context_u128 := context_u128;
          gs_contract_code:= codes;
        |}

 (**
<<
## Return (normal return, not panic/revert)

>>
  *)
| step_RetLocal_nolabel:
    forall codes flags storages mem_pages cf caller_stack new_caller_stack context_u128 regs _ignored,

      let xstack := InternalCall cf caller_stack in

      ergs_reimburse (ergs_remaining xstack) caller_stack new_caller_stack ->
      step_ins (OpRet _ignored None)
        {|
          gs_flags        := flags;
          gs_callstack    := xstack;


          gs_regs         := regs;
          gs_mem_pages    := mem_pages;
          gs_storages     := storages;
          gs_context_u128 := context_u128;
          gs_contract_code:= codes;
        |}
        {|
          gs_flags        := flags_clear;
          gs_callstack    := new_caller_stack;


          gs_regs         := regs;
          gs_mem_pages    := mem_pages;
          gs_storages     := storages;
          gs_context_u128 := context_u128;
          gs_contract_code:= codes;
        |}

| step_RetLocal_label:
  forall gs gs1 _ignored label,
    step_ins (OpRet _ignored None) gs gs1 ->
    step_ins (OpRet _ignored (Some label)) gs (gs1 <| gs_callstack ::= pc_set label |>)



| step_RetExt_ForwardFatPointer:
  forall codes flags storages mem_pages cf caller_stack new_caller_stack context_u128 regs label_ignored (arg:in_reg) in_ptr_encoded in_ptr shrunk_ptr,
    let xstack0 := ExternalCall cf (Some caller_stack) in
    (* Panic if not a pointer *)
    resolve_fetch_value regs xstack0 mem_pages arg (PtrValue in_ptr_encoded) ->

    Ret.ABI.(decode) in_ptr_encoded = Some (Ret.mk_params in_ptr ForwardFatPointer) ->

    (* Panic if either [page_older] or [validate] do not hold *)
    page_older in_ptr.(fp_mem_page) cf.(ecf_mem_context)  = false ->

    ergs_reimburse_caller xstack0 new_caller_stack ->
    fat_ptr_shrink in_ptr shrunk_ptr ->

    let encoded_shrunk_ptr := FatPointer.ABI.(encode) shrunk_ptr in
    step_ins (OpRet arg label_ignored)
          {|
          gs_flags        := flags;
          gs_callstack    := xstack0;
          gs_regs         := regs;
          gs_context_u128 := context_u128;


          gs_mem_pages    := mem_pages;
          gs_storages    := storages;
          gs_contract_code:= codes;
          |}
          {|
          gs_flags        := flags_clear;
          gs_regs         := regs_state_zero
                             <| gprs_r1 := PtrValue encoded_shrunk_ptr |>
                             <| gprs_r2 := reg_reserved |>
                             <| gprs_r3 := reg_reserved |>
                             <| gprs_r4 := reg_reserved |> ;
          gs_callstack    := new_caller_stack;
          gs_context_u128 := zero128;


          gs_mem_pages    := mem_pages;
          gs_storages     := storages;
          gs_contract_code:= codes;
          |}
(* ------ *)
| step_RetExt_ForwardFatPointer':
  forall codes flags storages mem_pages cf caller_stack new_caller_stack context_u128 regs label_ignored (arg:in_reg) in_ptr_encoded in_ptr shrunk_ptr,
    let xstack0 := ExternalCall cf (Some caller_stack) in
    let gs := {|
          gs_flags        := flags;
          gs_callstack    := xstack0;
          gs_regs         := regs;
          gs_context_u128 := context_u128;


          gs_mem_pages    := mem_pages;
          gs_storages     := storages;
          gs_contract_code:= codes;
          |}  in
    (* Panic if not a pointer *)
    resolve_fetch_value regs xstack0 mem_pages arg (PtrValue in_ptr_encoded) ->

    Ret.ABI.(decode) in_ptr_encoded = Some (Ret.mk_params in_ptr ForwardFatPointer) ->

    (* Panic if either [page_older] or [validate] do not hold *)
    page_older in_ptr.(fp_mem_page) cf.(ecf_mem_context)  = false ->

    ergs_reimburse_caller xstack0 new_caller_stack ->
    fat_ptr_shrink in_ptr shrunk_ptr ->

    let encoded_shrunk_ptr := FatPointer.ABI.(encode) shrunk_ptr in
    step_ins (OpRet arg label_ignored) gs (gs
          <| gs_flags        := flags_clear |>
          <| gs_regs         := regs_state_zero
                             <| gprs_r1 := PtrValue encoded_shrunk_ptr |>
                             <| gprs_r2 := reg_reserved |>
                             <| gprs_r3 := reg_reserved |>
                             <| gprs_r4 := reg_reserved |>  |>
          <| gs_callstack    := new_caller_stack |>
          <| gs_context_u128 := zero128 |>)


(* ------ *)

| step_RetExt_UseHeapOrAuxHeap:
    forall codes flags storages mem_pages cf xstack1 caller_stack new_caller_stack context_u128 regs label_ignored (arg:in_reg) in_ptr_encoded in_ptr page_id mode current_bound diff,

      let xstack0 := ExternalCall cf (Some caller_stack) in

      (* Panic if not a pointer*)
      resolve_fetch_value regs xstack0 mem_pages arg (IntValue in_ptr_encoded) \/ resolve_fetch_value regs xstack0 mem_pages arg (PtrValue in_ptr_encoded) ->

      Ret.ABI.(decode) in_ptr_encoded = Some (Ret.mk_params in_ptr mode) ->
      (mode = UseHeap \/ mode = UseAuxHeap) ->

      (* Panic if either [page_older] or [validate] does not hold *)
      page_older in_ptr.(fp_mem_page) cf.(ecf_mem_context)  = false ->
      select_page_bound xstack0 mode (page_id, current_bound) ->
      fat_ptr_induced_growth in_ptr current_bound diff ->
      pay (Ergs.growth_cost diff) xstack0 xstack1 ->

      ergs_reimburse_caller xstack1 new_caller_stack ->

      let out_ptr := in_ptr <| fp_mem_page := page_id |> in
      let out_ptr_encoded := FatPointer.ABI.(encode) out_ptr in
      step_ins (OpRet arg label_ignored)
        {|
          gs_flags        := flags;
          gs_regs         := regs;
          gs_callstack    := xstack0;
          gs_context_u128 := context_u128;


          gs_mem_pages    := mem_pages;
          gs_storages     := storages;
          gs_contract_code:= codes;
        |}
        {|
          gs_flags        := flags_clear;
          gs_regs         := regs_state_zero
          <| gprs_r1 := PtrValue  out_ptr_encoded |>
          <| gprs_r2 := reg_reserved |>
          <| gprs_r3 := reg_reserved |>
          <| gprs_r4 := reg_reserved |>;
          gs_callstack    := new_caller_stack;
          gs_context_u128 := zero128;


          gs_mem_pages    := mem_pages;
          gs_storages     := storages;
          gs_contract_code:= codes;
        |}

(**
<<
## Revert (not return/panic)

>>
  *)

| step_RevertLocal:
  forall gs gs1 _ignored opt_label,
    step_ins (OpRet _ignored opt_label) gs gs1 ->
    let dest := match opt_label with
          | None => active_exception_handler gs.(gs_callstack)
          | Some label => label
          end in
    step_ins (OpRevert _ignored None) gs (gs1 <| gs_callstack ::= pc_set dest |> )

| step_RevertExt_ForwardFatPointer:
  forall codes flags storages mem_pages cf caller_stack new_caller_stack context_u128 regs label_ignored (arg:in_reg) in_ptr_encoded in_ptr shrunk_ptr,
    let xstack0 := ExternalCall cf (Some caller_stack) in
    (* Panic if not ptr *)
    resolve_fetch_value regs xstack0 mem_pages arg (PtrValue in_ptr_encoded) ->

    Ret.ABI.(decode) in_ptr_encoded = Some( Ret.mk_params in_ptr ForwardFatPointer) ->

    (* Panic if either [page_older] or [validate] do not hold *)
    page_older in_ptr.(fp_mem_page) cf.(ecf_mem_context)  = false ->

    fat_ptr_shrink in_ptr shrunk_ptr ->
    ergs_reimburse (ergs_remaining xstack0) caller_stack new_caller_stack ->

    let exception_handler := active_exception_handler xstack0 in
    let encoded_shrunk_ptr := FatPointer.ABI.(encode) shrunk_ptr in
    let new_regs := regs_state_zero
          <| gprs_r1 := PtrValue encoded_shrunk_ptr |>
          <| gprs_r2 := reg_reserved |>
          <| gprs_r3 := reg_reserved |>
          <| gprs_r4 := reg_reserved |> in
    step_ins (OpRevert arg label_ignored)
         {|
          gs_flags        := flags;
          gs_callstack    := xstack0;
          gs_regs         := regs;
          gs_context_u128 := context_u128;


          gs_mem_pages    := mem_pages;
          gs_storages     := storages;
          gs_contract_code:= codes;
         |}
         {|
          gs_flags        := flags_clear;
          gs_callstack    := pc_set exception_handler new_caller_stack;
          gs_regs         := new_regs;
          gs_context_u128 := zero128;


          gs_mem_pages    := mem_pages;
          gs_storages     := storages;
          gs_contract_code:= codes;
         |}
(**
<<
## Panic (not return/revert)

>>
  *)
| step_PanicLocal:
  forall gs gs1 _ignored opt_label,
    step_ins (OpRevert _ignored opt_label) gs gs1 ->
    step_ins (OpPanic opt_label) gs (gs1 <| gs_flags ::= set_overflow |>)


 | step_PanicExt:
   forall codes flags storages mem_pages cf caller_stack context_u128 regs label_ignored,

     let xstack0 := ExternalCall cf (Some caller_stack) in

     let encoded_res_ptr := FatPointer.ABI.(encode) fat_ptr_empty in
     let new_regs := regs_state_zero
          <| gprs_r1 := PtrValue encoded_res_ptr |>
          <| gprs_r2 := reg_reserved |>
          <| gprs_r3 := reg_reserved |>
          <| gprs_r4 := reg_reserved |> in
     let exception_handler := active_exception_handler xstack0 in
     step_ins (OpPanic label_ignored)
          {|
          gs_flags        := flags;
          gs_regs         := regs;
          gs_callstack    := xstack0;
          gs_context_u128 := context_u128;

          gs_mem_pages    := mem_pages;
          gs_storages     := storages;
          gs_contract_code:= codes;
          |}
          {|
          gs_flags        := set_overflow flags_clear;
          gs_regs         := new_regs;
          gs_callstack    := pc_set exception_handler caller_stack;
          gs_context_u128 := zero128;


          gs_mem_pages    := mem_pages;
          gs_storages     := storages;
          gs_contract_code:= codes;
          |}
.

Inductive step: global_state -> global_state -> Prop :=
   | step_correct:
    forall codes flags storages mem_pages xstack0 xstack1 new_xstack ins context_u128 regs cond new_gs,
      let gs0 := {|
          gs_callstack    := xstack0;

          gs_flags        := flags;
          gs_regs         := regs;
          gs_mem_pages    := mem_pages;
          gs_storages    := storages;
          gs_context_u128 := context_u128;
          gs_contract_code:= codes;
          |} in
      let gs1 := {|
          gs_callstack    := new_xstack;

          gs_flags        := flags;
          gs_regs         := regs;
          gs_mem_pages    := mem_pages;
          gs_storages     := storages;
          gs_context_u128 := context_u128;
          gs_contract_code:= codes;
          |} in
      cond_holds cond flags = true ->

      check_requires_kernel ins (is_kernel xstack0) = true ->
      check_allowed_static_ctx ins (topmost_extframe xstack0).(ecf_is_static) = true ->
      fetch_instr regs xstack0 mem_pages (Ins ins cond) ->

      update_pc_regular xstack0 xstack1 ->
      pay (base_cost ins) xstack1 new_xstack ->
      step_ins ins gs1 new_gs ->
      step gs0 new_gs.