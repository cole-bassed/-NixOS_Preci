{
  attrsets,
  lists,
  modules,
  defaults,
  ...
}: let
  exports = {
    scoped = {inherit getUsers;};
    global = {inherit hosts users;};
  };

  inherit (attrsets) attrNames filterAttrs genAttrs mapAttrs;
  inherit (lists) elemAt filter length;
  # inherit (modules) getUsers;
  inherit (modules) collectNamedSpecs getUsers;
  inherit (defaults) ignore;

  # ── collect specs (spec.name wins over directory-derived key) ──────────────

  # getUsers = declared: let
  #   # ── group constructor ────────────────────────────────────────────────────
  #   mkGroup = attrs: let
  #     names = attrNames attrs;
  #     values = mapAttrs (name: user:
  #       user
  #       // {
  #         inherit name;
  #         home = user.home or "/home/${name}";
  #         description = user.description or name;
  #       })
  #     attrs;
  #     count = length names;
  #   in {inherit names values count;};

  #   # ── filter helpers ───────────────────────────────────────────────────────

  #   filterByStatus = status: attrs:
  #     filterAttrs (_: u: (u.enable or true) == (status == "enabled")) attrs;

  #   filterByRole = wantedRole: attrs:
  #     filterAttrs (
  #       _: u: let
  #         role = u.role or "";
  #         isNormal = role == "" || role == "user" || role == "normal";
  #       in
  #         if wantedRole == "normal"
  #         then isNormal
  #         else role == wantedRole
  #     )
  #     attrs;

  #   # ── cross-cutting group index ────────────────────────────────────────────
  #   # byStatus and byRole are mutually enriched: each slice gets the other
  #   # dimension attached, so callers can do .byStatus.enabled.byRole.admin etc.

  #   mkStatusIndex = attrs:
  #     genAttrs ["enabled" "disabled"] (status: let
  #       subset = filterByStatus status attrs;
  #     in
  #       (mkGroup subset) // {byRole = mkRoleIndex subset;});

  #   mkRoleIndex = attrs:
  #     genAttrs ["normal" "administrator" "service" "guest"] (role: let
  #       subset = filterByRole role attrs;
  #     in
  #       (mkGroup subset) // {byStatus = mkStatusIndex subset;});

  #   # ── assemble ─────────────────────────────────────────────────────────────

  #   users = mapAttrs (_: user:
  #     {
  #       role = "user";
  #       enable = true;
  #     }
  #     // user)
  #   declared;
  # in
  #   (mkGroup users)
  #   // {
  #     byStatus = mkStatusIndex users;
  #     byRole = mkRoleIndex users;
  #   };

  # collectNamedSpecs = {
  #   args,
  #   extraArgs ? {},
  #   base,
  #   ignore ? defaults.ignore,
  #   tags ? defaults.tags,
  #   rekey ? false, # when true, rekey by spec.name instead of dir name
  # }: let
  #   entries = readDirAttrs {inherit base ignore;};
  #   raw =
  #     mapAttrs
  #     (name: _:
  #       importModule {
  #         inherit base name;
  #         args =
  #           args
  #           // {
  #             dom = baseNameOf (toString base);
  #             mod = name;
  #           }
  #           // extraArgs;
  #       })
  #     entries;
  # in
  #   if rekey
  #   then
  #     mapAttrs' (dirName: spec: {
  #       name = spec.name or dirName;
  #       value = spec // {name = spec.name or dirName;};
  #     })
  #     raw
  #   else raw;

  collectSpecs = base:
    collectNamedSpecs {
      inherit ignore;
      args = {
        # inherit lix;
        # inherit (lix) defaults lib;
      };
      inherit base;
      rekey = true;
    };

  specs = {
    hosts = collectSpecs ./hosts;
    users = collectSpecs ./users;
  };

  # ── user resolution ────────────────────────────────────────────────────────

  resolveUsers = host: let
    hostPath = "api/hosts/${host.name}";
    fail = msg: throw "${hostPath}: ${msg}";

    declared = host.users or {};
    isSingleUser = length (attrNames declared) == 1;

    resolveUser = userName: config: let
      spec =
        specs.users.${userName}
        or (fail "user '${userName}' not found in api/users");

      defaults' = {
        role =
          if isSingleUser
          then config.role or "administrator"
          else "user";
        enable =
          if isSingleUser
          then config.enable or true
          else true;
        primary =
          if isSingleUser
          then config.primary or true
          else false;
        autoLogin = false;
      };
    in
      spec // defaults' // config;

    resolved = getUsers (mapAttrs resolveUser declared);

    primary = let
      enabled = resolved.byStatus.enabled;
      candidates =
        filter
        (n: enabled.values.${n}.primary or false)
        enabled.names;
      name =
        if enabled.count == 0
        then null
        else if length candidates == 0 && enabled.count == 1
        then elemAt enabled.names 0
        else if length candidates == 0
        then fail "expected exactly one primary enabled user, found none"
        else if length candidates > 1
        then fail "expected exactly one primary enabled user, found ${toString (length candidates)}"
        else elemAt candidates 0;
    in {
      inherit name;
      value =
        if name == null
        then null
        else enabled.values.${name};
    };
  in
    resolved // {inherit primary;};

  # ── top-level outputs ──────────────────────────────────────────────────────

  hosts =
    mapAttrs
    (_: host: host // {users = resolveUsers host;})
    specs.hosts;

  users = specs.users;
in
  exports
