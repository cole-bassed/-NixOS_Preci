{
  lib,
  lists,
}: let
  exports = {
    internal = {
      inherit
        getOrderedOr
        toOrderedAttrs
        mapOrderedAttrs
        parseOrderedAttrs
        mapParsedOrderedAttrs
        ;
      orderedOf = toOrderedAttrs;
      parsedOf = parseOrderedAttrs;
    };
    external = {
      inherit
        toOrderedAttrs
        mapOrderedAttrs
        parseOrderedAttrs
        mapParsedOrderedAttrs
        ;
    };
  };

  inherit (lib.attrsets) hasAttr getAttr listToAttrs mapAttrs;
  inherit (lib.lists) genList isList length;
  inherit (lists) nthOr;

  getOrderedOr = {
    key,
    attrs,
    default ? null,
  }:
    if hasAttr key attrs
    then getAttr key attrs
    else default;

  toOrderedAttrs = {value}: let
    count =
      if isList value
      then length value
      else 1;
  in
    listToAttrs (
      map (position: {
        name = toString (position + 1);
        value = nthOr {
          inherit position value;
        };
      }) (genList (x: x) count)
    );

  mapOrderedAttrs = {attrs}:
    mapAttrs (_: value: toOrderedAttrs {inherit value;}) attrs;

  parseOrderedAttrs = {value}: let
    ordered = toOrderedAttrs {inherit value;};

    primary = getOrderedOr {
      key = "1";
      attrs = ordered;
    };
    secondary = getOrderedOr {
      key = "2";
      attrs = ordered;
    };
    tertiary = getOrderedOr {
      key = "3";
      attrs = ordered;
    };

    preferred = primary;
    fallback = secondary;
    default =
      if isList value
      then
        nthOr {
          position = (length value) - 1;
          inherit value;
        }
      else value;
  in
    ordered
    // {inherit primary secondary tertiary preferred fallback default;};

  mapParsedOrderedAttrs = {attrs}:
    mapAttrs (_: value: parseOrderedAttrs {inherit value;}) attrs;
in
  exports
