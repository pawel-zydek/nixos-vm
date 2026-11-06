{ ... }:
{
  # Terminal (Mod+Enter w i3)
  programs.alacritty = {
    enable = true;
    settings = {
      font.size = 11;
      window.padding = { x = 4; y = 4; };
    };
  };
}
