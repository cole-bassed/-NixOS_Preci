{
  attrsets,
  debug,
  lists,
  strings,
  types,
  ...
}: let
  exports = {
    scoped = {
      inherit
        getOrderedOr
        toOrdered
        mapOrdered
        parseOrdered
        mapParsedOrdered
        mergeUnique
        orNull
        orDefault
        orEmpty
        getBySpec
        findFirst
        resolveBySpecs
        ;
      orderedOf = toOrdered;
      parsedOf = parseOrdered;
      merge = mergeUnique;

      isEmpty = isEmpty';
      isNotEmpty = isNotEmpty';
    };
    global = {
      orNullAttr = orNull;
      orDefaultAttr = orDefault;
      orEmptyAttr = orEmpty;
      toOrderedAttrs = toOrdered;
      mapOrderedAttrs = mapOrdered;
      parseOrderedAttrs = parseOrdered;
      mapParsedOrderedAttrs = mapParsedOrdered;
      mergeUniqueAttrs = mergeUnique;
      getAttrBySpec = getBySpec;
      findFirstAttrs = findFirst;
      resolveAttrsBySpecs = resolveBySpecs;
      isEmptyAttr = isEmpty';
      isNotEmptyAttr = isNotEmpty';
    };
  };

  inherit
    (attrsets)
    attrNames
    hasAttr
    # hasAttrByPath
    attrByPath
    getAttr
    listToAttrs
    mapAttrs
    optionalAttrs
    ;
  inherit
    (lists)
    concatMap
    filter
    findFirstList
    foldl'
    genList
    isList
    length
    map
    nthOr
    ;
  inherit (strings) concatStringsSep;
  inherit (debug) withContext;
  inherit (types) isAttrs isEmpty typeOf isString;

  isEmpty' = input: input == {};
  isNotEmpty' = input: !isEmpty' input;

  orNull = input:
    assert withContext {
      name = "attrsets.orNull";
      assertion = isEmpty input || isAttrs input;
      message = "expected an attrset, got ${typeOf input}";
      context = "evaluating attrsets.orNull";
    };
      if isEmpty input || !(isAttrs input)
      then null
      else input;

  orDefault = default: input:
    assert withContext {
      name = "attrsets.orDefault";
      assertion = isAttrs default && isAttrs input;
      message = "expected attrsets, got default=${typeOf default} input=${typeOf input}";
      context = "evaluating attrsets.orDefault";
    };
      if isNotEmpty' input
      then input
      else default;

  orEmpty = input:
    assert withContext {
      name = "attrsets.orEmpty";
      assertion = isNull input || isAttrs input;
      message = "expected an attrset or null, got ${typeOf input}";
      context = "evaluating attrsets.orEmpty";
    };
      optionalAttrs (input != null && isNotEmpty' input) input;

  getBySpec = input: spec:
    assert withContext {
      name = "attrsets.getBySpec";
      assertion = isNull input || isAttrs input;
      message = "expected input to be an attrset or null, got ${typeOf input}";
      context = "evaluating attrsets.getBySpec";
    };
      if input == null
      then null
      else if isList spec
      then attrByPath spec null input
      else if isString spec && hasAttr spec input
      then getAttr spec input
      else null;

  findFirst = {
    sets,
    specs,
    default ? null,
  }:
    assert withContext {
      name = "attrsets.findFirst'";
      assertion = isList sets && isList specs;
      message = "expected sets and specs to be lists";
      context = "evaluating attrsets.findFirst";
    };
      findFirstList (x: x != null) default
      (concatMap (input: map (spec: getBySpec input spec) specs) sets);

  resolveBySpecs = {
    input,
    specs,
    default ? null,
  }:
    assert withContext {
      name = "attrsets.resolveBySpecs";
      assertion = (input == null || isAttrs input) && isList specs;
      message = "expected input to be an attrset or null, and specs to be a list";
      context = "evaluating attrsets.resolveBySpecs";
    };
      findFirst {
        sets = [input];
        inherit specs default;
      };

  mergeUnique = {
    items,
    getAttrs,
    what ? "attributes",
    owner ? (name: name),
  }:
    foldl'
    (
      acc: name: let
        incoming = getAttrs name;
        collisions = filter (k: hasAttr k acc) (attrNames incoming);
      in
        if collisions == []
        then acc // incoming
        else
          throw ''
            ${what}: collision(s) detected in '${owner name}':
              ${concatStringsSep ", " collisions}
            Each merged attribute name must be unique.
          ''
    )
    {}
    (attrNames items);

  getOrderedOr = {
    key,
    attrs,
    default ? null,
  }:
    if hasAttr key attrs
    then getAttr key attrs
    else default;

  toOrdered = {value}: let
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

  mapOrdered = {attrs}:
    mapAttrs (_: value: toOrdered {inherit value;}) attrs;

  parseOrdered = {value}: let
    ordered = toOrdered {inherit value;};

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

  mapParsedOrdered = {attrs}:
    mapAttrs (_: value: parseOrdered {inherit value;}) attrs;
in
  exports
