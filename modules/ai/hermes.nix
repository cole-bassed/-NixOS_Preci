{
  config,
  inputs,
  # alpha,
  ...
}: {
  imports = with inputs; [
    hermes-agent.nixosModules.default
    agenix.nixosModules.default
  ];

  services.hermes-agent = {
    enable = true;
    container.enable = true;

    # ── Model ──────────────────────────────────────────────────────────
    settings = {
      model = {
        base_url = "https://openrouter.ai/api/v1";
        default = "anthropic/claude-opus-4.6";
      };
      toolsets = ["all"];
      max_turns = 100;
      terminal = {
        backend = "local";
        cwd = ".";
        timeout = 180;
      };
      compression = {
        enabled = true;
        threshold = 0.85;
        summary_model = "google/gemini-3-flash-preview";
      };
      memory = {
        memory_enabled = true;
        user_profile_enabled = true;
      };
      display = {
        compact = false;
        personality = "kawaii";
      };
      agent = {
        max_turns = 60;
        verbose = false;
      };
    };

    # ── Secrets ────────────────────────────────────────────────────────
    environmentFiles = with config; [
      # sops.secrets."hermes-env".path
      age.secrets.hermes-env.file
    ];

    # ── Documents ──────────────────────────────────────────────────────
    documents = {
      "USER.md" = ./documents/USER.md;
    };

    # ── MCP Servers ────────────────────────────────────────────────────
    # mcpServers.filesystem = {
    #   command = "npx";
    #   args = [
    #     "-y"
    #     "@modelcontextprotocol/server-filesystem"
    #     "/data/workspace"
    #   ];
    # };

    # ── Container options ──────────────────────────────────────────────
    # container = {
    #   image = "ubuntu:24.04";
    #   backend = "docker";
    #   hostUsers = [ alpha.name ];
    # extraVolumes = [ "${alpha.home}/Projects:/projects:rw" ];
    #   extraOptions = [
    #     "--gpus"
    #     "all"
    #   ];
    # };

    # ── Service tuning ─────────────────────────────────────────────────
    addToSystemPackages = true;
    extraArgs = ["--verbose"];
    restart = "always";
    restartSec = 5;
  };

  age.secrets = {
    hermes-env.file = ./secrets/hermes-env.age;
  };
}
