Require Common ABI lib.Decidability Log MemoryOps VersionedHash.

Import Coder Log VersionedHash Common Decidability Ergs Memory MemoryBase ZArith ZMod ABI.


Section Decommitter.
  Open Scope Z.
  Open Scope ZMod_scope.
  (** # Decommitter


Decommitter is a module external to EraVM, a key-value storage where:

- key is [%versioned_hash]
- value is the contract code

**Decommitting** refers to querying contract code from the decommitter and
filling new [%code_page] and [%const_page] with it. The rest of the code page is
filled with invalid instructions; the rest of const page is filled with zeros.

The mapping [%code_hash_location] between contract addresses and the hashes of
their codes is implemented by the storage of the contract
[%DEPLOYER_SYSTEM_CONTRACT_ADDRESS].

Note: storage with the same contract address may differ between shards.
   *)

  Definition DEPLOYER_SYSTEM_CONTRACT_ADDRESS : contract_address := int_mod_of _ ((2^15) + 2).

  Definition code_hash_location (for_contract: contract_address) (sid:shard_id): fqa_key :=
    mk_fqa_key (mk_fqa_storage sid DEPLOYER_SYSTEM_CONTRACT_ADDRESS) (resize _ 256 for_contract).

  Context {ins_type: Type} (invalid_ins: ins_type) (code_page := code_page invalid_ins).

  Definition code_storage_params := {|
                                     addressable_block := code_page * const_page;
                                     address_bits := 256;
                                     default_value := (empty _, empty _);
                                     writable := false;
                                   |}.

  Definition code_storage: Type := mem_parameterized code_storage_params.

  Record decommitter :=
    mk_code_mgr {
        cm_storage: code_storage;
        cm_accessed: @log versioned_hash;
      }.

  (** The versioned hash is called **cold** if it was not accessed during
  construction of the current block. Otherwise, it is **warm**. See
  [%is_first_access]. *)
  Definition is_first_access cm vh := negb (contains _ VersionedHash.eq_dec (cm_accessed cm) vh).

  (** Decommitting code by a cold versioned hash costs ([%ERGS_PER_CODE_WORD_DECOMMITTMENT] * (block size in words)) ergs.
Decommitting warm code is free. *)
  Inductive decommitment_cost (cm:decommitter) vhash (code_length_in_words: code_length): ergs -> Prop :=
  |dc_fresh: forall cost,
      is_first_access cm vhash = true->
      (cost, false) = ergs_of Ergs.ERGS_PER_CODE_WORD_DECOMMITTMENT * (resize _ _ code_length_in_words) ->
      decommitment_cost cm vhash code_length_in_words cost
  |dc_not_fresh:
    is_first_access cm vhash = false ->
    decommitment_cost cm vhash code_length_in_words zero32.

  Inductive code_fetch_hash (d:depot) (cs: code_storage) (sid: shard_id) (contract_addr: contract_address) :
    option (versioned_hash * code_length) -> Prop :=
  |cfh_found: forall hash_enc code_length_in_words extra_marker partial_hash,
      storage_read d (code_hash_location contract_addr sid) hash_enc ->
      hash_enc <> zero256 ->
      marker_valid extra_marker = true ->
      hash_coder.(decode) hash_enc = Some (mk_vhash code_length_in_words extra_marker partial_hash) ->
      code_fetch_hash d cs sid contract_addr (Some (mk_vhash code_length_in_words extra_marker partial_hash, code_length_in_words))

  | cfh_not_found:
    storage_read d (code_hash_location contract_addr sid) zero256 ->
    code_fetch_hash d cs sid contract_addr None.


  (** When decommitter does not have code for the requested hash, VM may allow
  masking, and request the code with default versioned hash [%DEFAULT_AA_VHASH]
  instead. It is expected that:

- [%DEFAULT_AA_VHASH] is well-formed (see [%marker_valid]), and
- decommitter has code matching [%DEFAULT_AA_VHASH].

VM does not mask the code for system contracts; see [%sem.FarCall.step].

[%DEFAULT_AA_CODE] is the decommitter's answer to the query [%DEFAULT_AA_VHASH]. *)

  Parameter DEFAULT_AA_CODE: (Memory.code_page invalid_ins * const_page).

  Inductive code_fetch  (d:depot) (cs: code_storage) (sid: shard_id) (contract_addr: contract_address) :
    bool -> (versioned_hash * (code_page * const_page) * code_length) -> Prop :=
  | cfnm_no_masking: forall vhash (code_storage:code_storage) code_length_in_words pages0 masking,
      code_fetch_hash d cs sid contract_addr (Some (vhash, code_length_in_words)) ->
      load_result code_storage_params (resize _ 256 (partial_hash vhash)) code_storage pages0 ->

      code_fetch d cs sid contract_addr masking (vhash, pages0, code_length_in_words)


  | cfnm_masking: forall (code_storage:code_storage) code_length_in_words,
      code_fetch_hash d cs sid contract_addr None ->
      code_fetch d cs sid contract_addr true (DEFAULT_AA_VHASH, DEFAULT_AA_CODE,code_length_in_words).


End Decommitter.
