{ pkgs, ... }:
{
  home.packages = with pkgs; [
    pcmanfm                       # Lekki menedżer plików
    vlc                           # Odtwarzacz multimedialny
    obsidian                      # Aplikacja do notatek w MD
    libreoffice                   # Pakiet biurowy
    hunspell                      # Silnik sprawdzania pisowni
    hunspellDicts.pl_PL           # Polski słownik (pl_PL)
    remmina                       # Klient RDP i VNC
    anki-bin                      # Program do fiszek
    lame flac vorbis-tools opus-tools   # kodery MP3, FLAC, Ogg
    spotify                       # Klient Spotify
    keepassxc
    ncdu                          # Zużycie dysku (w terminalu)
    drawio                        # Tworzenie diagramów i schematów
  ];
}
