nixpkgs: let
  lib = nixpkgs.lib or (import <nixpkgs/lib>);
  inherit (lib) asserts attrsets debug filesystem lists strings trivial types;
in
  lib
  // {
    filesystem =
      filesystem
      // {
        inherit (lib.trivial) pathExists;
      };
  }
  // {
    debug =
      debug
      // {
        inherit (builtins) tryEval;
        inherit (asserts) assertMsg;
        inherit (trivial) deepSeq;
      };
  }
  // {
    lists =
      lists
      // (with lists; {
        firstList = findFirst;
        first = head;
        lastDropped = init;
        firstItem = head;
        lastItem = tail;
        itemFirst = head;
        itemLast = tail;
        itemIndexed = elemAt;
      });
  }
  // {
    types =
      types
      // {
        inherit (filesystem) isPath;
        inherit (attrsets) isAttrs isDerivation;
        inherit (trivial) isBool isFloat isFunction;
        inherit
          (strings)
          isConvertibleWithToString
          isInt
          isList
          isStorePath
          isString
          isStringLike
          isValidPosixName
          typeOf
          ;
      };
  }
