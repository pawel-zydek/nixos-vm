# Konfiguracja NixOS – maszyna wirtualna

Konfiguracja maszyny wirtualnej KVM (host `nixos-vm`): NixOS z menedżerem okien **i3** na
szyfrowanym ZFS, Home Manager jako moduł NixOS. Jest to repozytorium do nauki.

## Struktura repozytorium

```
flake.nix                    # wejścia (nixpkgs, disko, home-manager) i lista hostów
flake.lock                   # przypięte wersje wejść
hosts/
  vm/
    default.nix              # tożsamość hosta + lista włączonych funkcji (my.*.enable)
    hardware-configuration.nix
modules/
  nixos/                     # moduły systemowe; default.nix importuje wszystkie
    core/                    # zawsze włączone: nix, boot, locale, użytkownik, pakiety, Home Manager
    storage/                 # disko-zfs (układ dysku), zfs, ntfs
    desktop/                 # i3 + LightDM, audio
    services/                # ssh
    virtualisation/          # qemu-guest (agent QEMU, SPICE)
  home/                      # moduły Home Managera: i3, alacritty, git, vim, bash, firefox, ...
users/
  pawel.nix                  # które moduły z modules/home/ dostaje użytkownik
assets/
  wallpapers/                # tapety (pulpit, ekran logowania)
```

Moduły spoza `core/` nic nie robią, dopóki host ich nie włączy, np. w `hosts/vm/default.nix`:

```nix
my.desktop.i3.enable = true;
```

Nowy moduł: utwórz plik w odpowiednim katalogu `modules/nixos/`, dopisz go do
`modules/nixos/default.nix` i włącz w hoście. Formatowanie całego repo: `nix fmt`.

## Układ dysku

| Partycja / dataset | Punkt montowania | Uwagi |
|---|---|---|
| ESP (1 GB, FAT32) | `/boot` | systemd-boot |
| `rpool` (reszta dysku) | — | ZFS, szyfrowanie aes-256-gcm, hasło przy starcie |
| `rpool/root` | `/` | |
| `rpool/nix` | `/nix` | |
| `rpool/var` | `/var` | |
| `rpool/home` | `/home` | snapshoty sanoid (24 h / 7 dni / 3 mies.) |

Brak partycji swap — używany jest zram.

---

# Instalacja na maszynie wirtualnej (KVM / virt-manager)

> **Uwaga:** krok 7 kasuje **cały** dysk wskazany w `my.disk` – w VM to jej wirtualny dysk.

## 0. Utworzenie maszyny w virt-managerze

1. Pobierz **minimalny** obraz NixOS 26.05 z <https://nixos.org/download/> (*Minimal ISO image*, 64-bit Intel/AMD)
   i skopiuj go do `/var/lib/libvirt/images/`.
2. virt-manager → *Nowa maszyna* → *Lokalny nośnik* → wybierz ISO, system operacyjny: **NixOS** (lub *Generic Linux*).
3. RAM **4–8 GB**, **2–4** procesory, dysk **40 GB lub więcej**.
4. Zaznacz **„Dostosuj konfigurację przed instalacją”** i ustaw:
   - *Przegląd* → Chipset: **Q35**, Firmware: **UEFI** (`OVMF_CODE.fd`, **bez** Secure Boot – systemd-boot nie jest podpisany),
   - *Dysk VirtIO 1* → magistrala **VirtIO**, a w zakładce **XML** dopisz w sekcji `<disk>` numer seryjny:

     ```xml
     <serial>nixosvm</serial>
     ```

     Dzięki temu dysk pojawi się w systemie jako `/dev/disk/by-id/virtio-nixosvm` – tej ścieżki używa `my.disk`.
   - *Karta sieciowa* → źródło **NAT (default)**, model **virtio**,
   - *Ekran* → **Spice**, *Wideo* → **Virtio** (bez akceleracji 3D) lub QXL,
   - powinien być *Kanał* `spice` (schowek, rozdzielczość) oraz `org.qemu.guest_agent.0` (agent QEMU);
     jeśli któregoś brakuje: *Dodaj sprzęt* → *Kanał*.
5. *Rozpocznij instalację*.

## 1. Start instalatora i klawiatura

```bash
sudo -i                 # dalej wszystko jako root
loadkeys pl2            # polska klawiatura w konsoli
export NIX_CONFIG="experimental-features = nix-command flakes"
ping -c 3 nixos.org     # sieć NAT działa od razu (DHCP)
```

`NIX_CONFIG` włącza flakes na czas tej sesji – bez tego polecenia `nix` nie zadziałają z repozytorium.

## 2. (Opcjonalnie) Praca przez SSH z hosta

Konsola virt-managera nie obsługuje wklejania, więc wygodniej jest połączyć się z hosta.

```bash
passwd nixos            # tymczasowe hasło dla użytkownika instalatora
ip -br addr             # adres IP maszyny (zwykle 192.168.122.x)
```

Na hoście: `ssh nixos@ADRES_IP`, potem znowu `sudo -i` oraz `export NIX_CONFIG=...` z kroku 1.

## 3. Pobranie repozytorium

```bash
git clone https://github.com/pawel-zydek/nixos-vm /tmp/nixos-vm
cd /tmp/nixos-vm
```

## 4. Sprawdzenie dysku

```bash
ls -l /dev/disk/by-id/ | grep virtio
```

Musi być wpis `virtio-nixosvm -> ../../vda`. Jeśli go nie ma, wyłącz VM i sprawdź `<serial>` z kroku 0
(albo wpisz w `hosts/vm/default.nix` ścieżkę, którą widzisz).

## 5. Plik hardware-configuration.nix

`--no-filesystems`, bo systemy plików opisuje disko.

```bash
nixos-generate-config --no-filesystems --show-hardware-config > hosts/vm/hardware-configuration.nix
```

Flake widzi **tylko pliki śledzone przez gita** – dodaj zmiany:

```bash
git add -A
git status
```

## 6. Szybki test konfiguracji

```bash
nix eval .#nixosConfigurations.nixos-vm.config.system.build.toplevel.drvPath
```

Jeśli wypisze ścieżkę `/nix/store/...drv`, konfiguracja jest poprawna. Błąd pokaże plik i linię.

## 7. Partycjonowanie i formatowanie (disko)

```bash
nix run github:nix-community/disko/latest -- --mode destroy,format,mount --flake .#nixos-vm
```

- disko poprosi o potwierdzenie usunięcia danych,
- potem **dwa razy o hasło szyfrowania ZFS** – będzie wpisywane przy każdym starcie VM.

Sprawdzenie:

```bash
zpool status rpool
zfs list
findmnt -R /mnt         # /mnt, /mnt/boot, /mnt/nix, /mnt/var, /mnt/home
```

## 8. Instalacja

```bash
nixos-install --flake .#nixos-vm --no-root-passwd
```

`--no-root-passwd` – root bez hasła logowania, administrujemy przez `sudo` (grupa `wheel`).

## 9. Czynności po instalacji (jeszcze w instalatorze)

```bash
# hasło użytkownika pawel
nixos-enter --root /mnt -c 'passwd pawel'

# kopia repozytorium (z nowym hardware-configuration.nix) do katalogu domowego
cp -r /tmp/nixos-vm /mnt/home/pawel/
chown -R 1000:100 /mnt/home/pawel      # 1000 = pawel, 100 = grupa users
```

## 10. Odmontowanie i restart

```bash
umount -Rl /mnt
zpool export -a        # ważne: bez eksportu pula może nie zaimportować się przy starcie
poweroff
```

W virt-managerze odłącz ISO od napędu CD (*Szczegóły* → *SATA CDROM* → *Odłącz*) albo w
*Opcjach rozruchu* przesuń dysk przed CD-ROM. Potem uruchom VM.

> Jeśli start zatrzyma się z komunikatem, że pula była używana przez inny system,
> w konsoli awaryjnej wykonaj jednorazowo `zpool import -f rpool` i uruchom ponownie.

## 11. Pierwsze uruchomienie

1. Wpisz hasło ZFS (w konsoli virt-managera).
2. Zaloguj się w LightDM jako `pawel` – startuje i3.
3. Rozdzielczość powinna dopasowywać się do okna. Jeśli nie: w virt-managerze
   *Widok → Skaluj ekran → Automatycznie zmieniaj rozmiar VM wraz z oknem*.
4. Zapisz zmiany w repozytorium (głównie `hardware-configuration.nix`):

```bash
cd ~/nixos-vm
git status
git add -A
git commit -m "VM: hardware-configuration"
git push
```

Przy pierwszym `git push` podaj login GitHub i **token** (Personal Access Token) zamiast hasła –
zostanie zapamiętany w GNOME Keyring (odblokowuje się przy logowaniu; podgląd: program *Hasła i klucze* / `seahorse`).

## Podstawowe skróty i3

Klawisz `Mod` to **Alt** (Super często przechwytuje system hosta).

| Skrót | Działanie |
|---|---|
| `Alt+Enter` | terminal (Alacritty) |
| `Alt+d` | uruchamianie programów (dmenu) |
| `Alt+Shift+q` | zamknięcie okna |
| `Alt+1` … `Alt+0` | przełączenie obszaru roboczego |
| `Alt+Shift+1` … | przeniesienie okna na obszar roboczy |
| `Alt+strzałki` | zmiana aktywnego okna |
| `Alt+h` / `Alt+v` | następne okno obok / pod spodem |
| `Alt+f` | pełny ekran |
| `Alt+Shift+Spacja` | okno pływające / kafelkowe |
| `Alt+Shift+x` | blokada ekranu |
| `Alt+Shift+c` / `Alt+Shift+r` | przeładowanie / restart i3 |
| `Alt+Shift+e` | wylogowanie |

Konfiguracja: `modules/home/i3.nix`. Pełna lista: <https://i3wm.org/docs/refcard.html>.

---

# Codzienna praca

```bash
cd ~/nixos-vm

# po zmianie plików konfiguracji
git add -A
sudo nixos-rebuild switch --flake .#nixos-vm     # albo alias: rebuild

# aktualizacja systemu
nix flake update
sudo nixos-rebuild switch --flake .#nixos-vm
nvd diff /run/booted-system /run/current-system    # co się zmieniło
git commit -am "Aktualizacja flake.lock" && git push

# test bez zapisywania jako domyślna generacja
sudo nixos-rebuild test --flake .#nixos-vm
```

Stara generacja zawsze jest dostępna w menu systemd-boot przy starcie.

## Dostęp i wdrażanie przez SSH

Logowanie tylko kluczem; dozwolone klucze są w `hosts/vm/default.nix`.

```bash
ssh pawel@ADRES_IP_VM

# wdrożenie konfiguracji z innego komputera (z katalogu z tym repo)
nixos-rebuild switch --flake .#nixos-vm --target-host pawel@ADRES_IP_VM --sudo
```

## Snapshoty ZFS

```bash
zfs list -t snapshot                       # lista snapshotów (sanoid robi je dla /home)
sudo zfs snapshot rpool/root@przed-zmiana  # ręczny snapshot
ls /home/.zfs/snapshot/                    # podgląd plików ze snapshotów
```

---

# Rozwiązywanie problemów

| Objaw | Rozwiązanie |
|---|---|
| Brak `/dev/disk/by-id/virtio-nixosvm` | brak `<serial>nixosvm</serial>` w XML dysku – krok 0 |
| VM nie startuje po instalacji (UEFI shell) | firmware musi być UEFI bez Secure Boot; sprawdź kolejność rozruchu |
| Rozdzielczość nie zmienia się z oknem | `systemctl --user status spice-vdagent`; w VM musi być kanał `spice` |
| Schowek host ↔ VM nie działa | jak wyżej – agent `spice-vdagent` i kanał `spice` |
| `nix` nie zna `flake` / `run` | `export NIX_CONFIG="experimental-features = nix-command flakes"` |
| Zmiany w plikach są ignorowane | `git add -A` – flake widzi tylko pliki w gicie |
| Start zatrzymuje się na imporcie `rpool` | w konsoli awaryjnej `zpool import -f rpool`, potem `reboot` |
| System nie startuje po zmianie | wybierz poprzednią generację w menu systemd-boot |
