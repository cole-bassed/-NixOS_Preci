{lix, ...} @ base: let
  inherit (lix.config) assemble;
  inherit (lix.modules) importModules;

  collected = importModules (base // {base = ./.;});
in
  assemble.configurations base {
    modules = {
      core = collected.imports;
      home = collected.home-manager.sharedModules;
    };
  }
