# api/default.nix
{
  lib,
  lix,
  inputs,
  defaults,
}: let
  inherit (lib.attrsets) mapAttrs attrValues;
  inherit (lib.lists) length filter findFirst;
  inherit (lix) collectNamedSpecs;

  # ── collect raw specs ──────────────────────────────────────────────────────

  rawHosts = collectNamedSpecs {
    args = {inherit lib lix inputs defaults;};
    base = ./hosts;
    ignore = defaults.ignore;
  };

  rawUsers = collectNamedSpecs {
    args = {inherit lib lix inputs defaults;};
    base = ./users;
    ignore = defaults.ignore;
  };

  # ── name defaulting: spec.name > attrName ─────────────────────────────────

  withDefaultName = attrName: spec:
    if spec ? name && spec.name != null && spec.name != ""
    then spec
    else spec // {name = attrName;};

  # ── validate a host's users block ─────────────────────────────────────────

  validateUsers = hostName: users: let
    primaries = filter (u: u.primary or false) (attrValues users);
    count = length primaries;
  in
    if count == 0
    then throw "api/hosts/${hostName}: no user has primary = true; exactly one is required"
    else if count > 1
    then throw "api/hosts/${hostName}: ${toString count} users have primary = true; exactly one is required"
    else users;

  # ── resolve host users: merge host decl (role/primary/autoLogin) with user spec ──

  resolveUsers = hostName: hostUserDecls:
    mapAttrs (
      userName: decl: let
        spec = rawUsers.${userName}
        or (throw "api/hosts/${hostName}: user '${userName}' declared but not found in api/users");
      in
        # apply name defaulting to user spec, then host decl wins for its own fields
        (withDefaultName userName spec) // decl
    )
    hostUserDecls;

  # ── assemble hosts ─────────────────────────────────────────────────────────

  hosts =
    mapAttrs (
      attrName: raw: let
        namedRaw = withDefaultName attrName raw;
        resolvedUsers = resolveUsers namedRaw.name (namedRaw.users or {});
        validatedUsers = validateUsers namedRaw.name resolvedUsers;
        primaryUser =
          findFirst
          (u: u.primary or false)
          (throw "api/hosts/${namedRaw.name}: primary user missing after validation")
          (attrValues validatedUsers);
      in
        namedRaw
        // {
          users = validatedUsers;
          primary = primaryUser;
        }
    )
    rawHosts;

  # ── users exposed with name defaulting applied ─────────────────────────────

  users = mapAttrs withDefaultName rawUsers;
in {
  inherit hosts users;
}
