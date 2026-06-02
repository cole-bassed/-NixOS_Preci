{lib, ...} @ args:
lib.importModules (args
  // {
    base = ./.;
  })
