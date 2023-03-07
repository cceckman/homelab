{ pkgs, ... }: {
  # Uncommon system packages, that I want when doing particular tasks.
  environment.systemPackages = [
    pkgs.ffmpeg
    pkgs.flac
    pkgs.hugo
  ];
}
