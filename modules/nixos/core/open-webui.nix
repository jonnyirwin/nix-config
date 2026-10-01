{ lib, config, pkgs, ... }:

let
  cfg = config.jonny.services.open-webui;
  searxPort = 8888;
in
{
  options.jonny.services.open-webui = {
    enable = lib.mkEnableOption ''
      Open WebUI, a chat front end for the local Ollama that answers from web
      search results rather than memory, backed by a private SearXNG
      (localhost only)
    '';

    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "Port the web interface listens on, on 127.0.0.1.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.jonny.services.ollama.enable;
        message = "jonny.services.open-webui needs jonny.services.ollama for its models.";
      }
    ];

    # torchcodec (open-webui → sentence-transformers → torchaudio) fails its
    # mp3 encoder tests against the ffmpeg CLI at 8 kHz. Encoding is unused
    # here; skip that test until nixpkgs fixes it.
    nixpkgs.overlays = [
      (_final: prev: {
        pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
          (_pyfinal: pyprev: {
            torchcodec = pyprev.torchcodec.overridePythonAttrs (old: {
              disabledTests = (old.disabledTests or [ ]) ++ [ "test_audio_against_cli" ];
            });
          })
        ];
      })
    ];

    services.open-webui = {
      enable = true;
      host = "127.0.0.1";
      inherit (cfg) port;

      # Merged over the module's defaults, which switch off its telemetry.
      environment = {
        OLLAMA_BASE_URL = "http://127.0.0.1:11434";
        ENABLE_OPENAI_API = "False";

        # One user on one machine, reachable from localhost only — a login
        # screen protects nothing.
        WEBUI_AUTH = "False";

        # Settings come from here on every start, not from whatever the admin
        # panel last saved to the database. Changes made in the UI last until
        # the service restarts.
        ENABLE_PERSISTENT_CONFIG = "False";

        ENABLE_WEB_SEARCH = "True";
        WEB_SEARCH_ENGINE = "searxng";
        SEARXNG_QUERY_URL = "http://127.0.0.1:${toString searxPort}/search?q=<query>";
        WEB_SEARCH_RESULT_COUNT = "5";

        # Hand the model the search snippets as they are. The defaults fetch
        # every result page and embed it for retrieval, which on this CPU adds
        # minutes per question and thousands of prompt tokens — and a
        # snippet already names the author, the date, the figure.
        BYPASS_WEB_SEARCH_WEB_LOADER = "True";
        BYPASS_WEB_SEARCH_EMBEDDING_AND_RETRIEVAL = "True";
      };
    };

    services.searx = {
      enable = true;
      environmentFile = "/var/lib/searx-secret/env";
      settings = {
        use_default_settings = true;
        server = {
          bind_address = "127.0.0.1";
          port = searxPort;
          secret_key = "$SEARX_SECRET_KEY";
        };
        # Open WebUI reads results as JSON, which SearXNG ships disabled.
        search.formats = [ "html" "json" ];
      };
    };

    # SearXNG signs its image-proxy URLs with the secret key. Nothing off this
    # machine can reach it, so the key needs no backup or sops entry — only to
    # stay out of the world-readable Nix store. Generated once, then kept.
    systemd.services.searx-secret = {
      description = "Generate the SearXNG secret key";
      wantedBy = [ "searx-init.service" ];
      before = [ "searx-init.service" ];
      unitConfig.ConditionPathExists = "!/var/lib/searx-secret/env";
      serviceConfig = {
        Type = "oneshot";
        StateDirectory = "searx-secret";
        StateDirectoryMode = "0700";
        UMask = "0077";
      };
      script = ''
        echo "SEARX_SECRET_KEY=$(${lib.getExe pkgs.openssl} rand -hex 32)" \
          > /var/lib/searx-secret/env
      '';
    };
  };
}
