{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
  nativeBuildInputs = with pkgs.buildPackages; [
    elixir
    elixir-ls
    cmake
    file # libmagic
    ffmpeg
  ];
}
