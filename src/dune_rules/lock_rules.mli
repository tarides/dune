open Import

val setup_rules
  :  components:string list
  -> dir:Path.Build.t
  -> ctx:Context_name.t
  -> Build_config.Gen_rules.t Memo.t
