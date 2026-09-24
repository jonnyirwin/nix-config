{ lib, config, ... }:

let
  cfg = config.jonny.services.ollama;
in
{
  options.jonny.services.ollama = {
    enable = lib.mkEnableOption "the Ollama server for local LLMs (CPU inference, localhost only)";

    modelsDir = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/mnt/data/ollama";
      description = ''
        Where model weights live. Null keeps the upstream default,
        /var/lib/ollama/models, on the root filesystem.

        Set it when the root volume is the wrong home for tens of gigabytes
        of weights — a separate data volume, or a faster disk. The directory
        is created and owned by a static `ollama` user, because the upstream
        module's DynamicUser can only own paths under /var/lib.
      '';
    };

    models = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "qwen3:4b" "hf.co/unsloth/Qwen3.6-35B-A3B-GGUF:UD-Q3_K_S" ];
      description = ''
        Models pulled in the background after boot. Accepts Ollama library
        tags and `hf.co/<repo>:<quant>` GGUF references alike. Declarative in
        one direction only: removing a model here does not delete it from
        disk — `ollama rm` does that.
      '';
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      services.ollama = {
        enable = true;
        loadModels = cfg.models;

        # The default package already resolves to the CPU build on a machine
        # without cudaSupport/rocmSupport. `ollama-vulkan` would reach Intel
        # iGPUs, but the ones in this fleet are too small to beat the CPU —
        # token generation is bound by RAM bandwidth, which the iGPU shares.

        environmentVariables = {
          # Two large models resident at once is the fastest route into swap.
          # A second model evicts the first instead.
          OLLAMA_MAX_LOADED_MODELS = "1";

          # Ollama's own default is small enough that pasting a file silently
          # truncates it. 16k is room for a conversation plus a source file.
          OLLAMA_CONTEXT_LENGTH = "16384";

          # Store the KV cache (the per-conversation working memory) at 8-bit
          # rather than 16. Halves its footprint at a negligible quality cost;
          # flash attention is a prerequisite for a quantised cache.
          OLLAMA_FLASH_ATTENTION = "1";
          OLLAMA_KV_CACHE_TYPE = "q8_0";
        };
      };

      # Inference saturates every core, and the work happens here rather than
      # in whatever client asked for it — so niceness on a calling script
      # changes nothing. A low weight hands the desktop priority whenever it
      # wants the CPU, while leaving all of it to Ollama when idle. It is a
      # share, not a cap: nothing slows down unless something else is busy.
      systemd.services.ollama.serviceConfig.CPUWeight = 20;
    }

    (lib.mkIf (cfg.modelsDir != null) {
      services.ollama = {
        inherit (cfg) modelsDir;
        user = "ollama";
      };

      # The service lists modelsDir in ReadWritePaths, which systemd refuses
      # to start with if the path is missing — so it must exist first.
      systemd.tmpfiles.rules = [ "d ${cfg.modelsDir} 0750 ollama ollama -" ];

      # Wait for the volume rather than writing weights into the empty
      # mountpoint underneath it.
      systemd.services.ollama.unitConfig.RequiresMountsFor = [ cfg.modelsDir ];
    })
  ]);
}
