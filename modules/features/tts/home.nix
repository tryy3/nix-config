# modules/features/tts/home.nix
#
# Home Manager TTS configuration.
# Downloads Kokoro and Matcha-TTS models and provides the `tts` command.
{ pkgs, ... }:
let
  kokoroModel = pkgs.fetchzip {
    url = "https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/kokoro-en-v0_19.tar.bz2";
    sha256 = "sha256-Kjq29Rtn34qzkR06zG0JHR3P/eQdDUC6NPKn/WKqJs4=";
  };

  matchaModel = pkgs.fetchzip {
    url = "https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/matcha-icefall-en_US-ljspeech.tar.bz2";
    sha256 = "sha256-Q8MtOSEKv0cI8VrmMgxxx9VCc6Jiu2Q/S6+xgn5ZiI4=";
  };

  vocosVocoder = pkgs.fetchurl {
    url = "https://github.com/k2-fsa/sherpa-onnx/releases/download/vocoder-models/vocos-22khz-univ.onnx";
    sha256 = "sha256-BXShNaodst5uGBBQ2y7FKElsrNSkcB/F1/r5+YBMAIE=";
  };

  tts = pkgs.writeShellScriptBin "tts" (
    ''
      KOKORO_MODEL_DIR="${kokoroModel}"
      MATCHA_MODEL_DIR="${matchaModel}"
      VOCOS_VOCODER="${vocosVocoder}"
      TTS_BIN="${pkgs.unstable.sherpa-onnx}/bin/sherpa-onnx-offline-tts"
    ''
    + builtins.readFile ./tts.sh
  );
in
{
  home.packages = [
    tts
    pkgs.pandoc
  ];
}
