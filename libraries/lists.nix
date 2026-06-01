{lib}: let
  exports = {
    internal = {
      inherit nthOr asList;
      atOr = nthOr;
    };
    external = {
      valueInList = nthOr;
      toList' = asList;
    };
  };

  inherit (lib.lists) elemAt isList length optionals toList;
  inherit (lib.attrsets) isAttrs;

  asList = val: optionals (val != null) (toList val);

  nthOr = input: let
    fromArgs = {
      position,
      value,
      default ? null,
    }:
      if isList value
      then
        if length value > position
        then elemAt value position
        else default
      else if position == 0
      then value
      else default;
  in
    if isAttrs input
    then fromArgs input
    else
      position:
        fromArgs {
          value = input;
          inherit position;
        };
in
  exports
