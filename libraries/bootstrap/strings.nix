let
  exports = {
    scoped = {
      inherit
        trim
        cat
        orEmpty
        ;
    };

    global = {
      inherit cat;
      trimString = trim;
      orEmptyString = orEmpty;
    };
  };

  inherit
    (builtins)
    attrNames
    concatLists
    concatStringsSep
    head
    isString
    lessThan
    match
    readDir
    readFile
    readFileType
    sort
    stringLength
    ;

  /**
  Read a file, or recursively concatenate all regular files in a directory.

  When given a path to a regular file, returns its contents as a string.
  When given a path to a directory, collects all regular files beneath it
  recursively — sorted lexicographically at each level — and joins them
  with a single newline between each file's content.

  Symlinks and unknown filesystem entries are silently skipped.

  # Type
  ```nix
  cat :: Path -> String
  ```

  # Dependencies
  None

  # Arguments
  path
  : A path to a file or directory to read.

  # Examples
  ```nix
  cat ./config.nix
  # => "{ foo = 1; }\n"

  cat ./parts
  # => "<contents of parts/a.nix>\n<contents of parts/b.nix>\n<contents of parts/sub/c.nix>"
  ```
  */
  cat = path: let
    collectFiles = dir: let
      entries = readDir dir;
      names = sort lessThan (attrNames entries);
    in
      concatLists (map (
          name: let
            child = dir + "/${name}";
          in
            if entries.${name} == "regular"
            then [(readFile child)]
            else if entries.${name} == "directory"
            then collectFiles child
            else []
        )
        names);
  in
    if readFileType path == "directory"
    then concatStringsSep "\n" (collectFiles path)
    else readFile path;

  /**
  Trim leading and trailing whitespace from a string.

  Non-string values are treated as the empty string.

  # Type
  ```nix
  trim :: a -> String
  ```

  # Dependencies
  None

  # Arguments
  value
  : The value to trim. Non-string values produce `""`.

  # Examples
  ```nix
  trim "  hello  "
  # => "hello"

  trim "\n  hi there\t"
  # => "hi there"

  trim null
  # => ""
  ```
  */
  trim = value: let
    string =
      if isString value
      then value
      else "";

    matches = match "[[:space:]]*(.*[^[:space:]])?[[:space:]]*" string;
  in
    if matches != null
    then head matches
    else "";

  /**
  Return a non-empty string as-is, otherwise return `""`.

  Strings containing only whitespace are treated as empty.

  # Type
  ```nix
  orEmpty :: a -> String
  ```

  # Dependencies
  ```nix
  - strings.trim
  ```
  # Arguments

  value
  : The value to normalize.

  # Examples
  ```nix
  orEmpty "hello"
  # => "hello"

  orEmpty "   "
  # => ""

  orEmpty null
  # => ""
  ```
  */
  orEmpty = value:
    if isString value && stringLength (trim value) > 0
    then value
    else "";
in
  exports
