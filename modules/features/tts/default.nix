# modules/features/tts/default.nix
#
# Text-to-Speech feature: local TTS using sherpa-onnx + Kokoro models.
# Provides the `tts` command for reading text/stdin/URLs aloud.
{ config, pkgs, ... }:
let
  username = config.hostSpec.username;
in
{
  environment.systemPackages = [
    pkgs.unstable.sherpa-onnx
  ];

  home-manager.users.${username}.imports = [ ./home.nix ];
}
