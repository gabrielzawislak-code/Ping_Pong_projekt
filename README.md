# Ping-Pong na Basys3

Projekt zaliczeniowy MTM UEC2 — gra Ping-Pong (Pong) w SystemVerilog na dwóch
płytkach Digilent Basys3, każda z własnym monitorem VGA i własnym graczem,
połączonych pełnodupleksowym łączem UART.

Autorzy: Mateusz Zybura, Gabriel Zawiślak

## Architektura

Jeden, identyczny bitstream wgrywany na obie płytki. Rolę (HOST / Gracz 1
albo CLIENT / Gracz 2) wybiera fizyczny przełącznik `sw_role` (SW0),
odczytywany w locie:

- **HOST** (`sw_role = 0`) — jedyna płytka licząca fizykę piłki i wynik
  (`rtl/game/ball_pos.sv`). Wysyła do drugiej płytki pełny stan gry.
- **CLIENT** (`sw_role = 1`) — mirroruje piłkę i wynik z ramki otrzymanej
  od HOSTa.

Obie płytki niezależnie od roli mają aktywne wyjście VGA (1024×768),
renderują obraz lokalnie i liczą lokalnie własną paletkę. Szczegółowy opis
wprowadzonych zmian architektonicznych oraz znany, nierozwiązany problem
znajdują się w [`doc/Opis-zmian.txt`](doc/Opis-zmian.txt) — patrz też
[`doc/raport.pdf`](doc/raport.pdf).

Płytki łączy się na krzyż: `JXADC[0]` (TX) jednej do `JC1` (RX) drugiej,
plus wspólna masa (GND).

## Struktura katalogów

```
doc/          - raport, checklist, opis zmian
fpga/         - wrapper top-level, ograniczenia (.xdc), skrypty Vivado
results/      - wygenerowany bitstream (.bit)
rtl/          - źródła SystemVerilog/Verilog, pogrupowane w podkatalogach
  common/     - moduły ogólnego przeznaczenia (debounce, reset_ctrl, ...)
  game/       - logika gry (game_fsm, ball_pos, paddle_mover, ...)
  uart/       - UART i kodery/dekodery ramek
  video/      - potok generowania obrazu VGA
sim/          - testbenche i listy plików (.prj) do symulacji
tools/        - skrypty pomocnicze (budowanie, symulacja, programowanie)
```

## Wymagania

- Xilinx Vivado 2025.2 (dla docelowej płytki `xc7a35tcpg236-1`)
- Bash (do skryptów w `tools/` i `env.sh`)

## Budowanie i symulacja

```sh
source env.sh                    # inicjalizacja środowiska (git init w razie potrzeby, ROOT_DIR, PATH)
tools/run_simulation.sh -l       # lista dostępnych testów symulacyjnych
tools/run_simulation.sh -t top_vga   # uruchomienie pojedynczego testu
tools/run_simulation.sh -a       # uruchomienie wszystkich testów
tools/generate_bitstream.sh      # pełna synteza + implementacja + bitstream (wymaga Vivado w PATH)
```

Bitstream trafia do `fpga/build/` i jest kopiowany do `results/`.
Programowanie płytki: `tools/program_fpga.sh` albo ręcznie przez
Vivado Hardware Manager, wskazując plik `.bit` z `results/`.

## Uruchomienie na sprzęcie

1. Wgraj ten sam bitstream (`results/*.bit`) na obie płytki Basys3.
2. Połącz płytki przewodami: `JXADC[0]` płytki A → `JC1` płytki B, `JXADC[0]`
   płytki B → `JC1` płytki A, plus wspólna masa (GND).
3. Ustaw `SW0` różnie na obu płytkach (jedna HOST, druga CLIENT).
4. `btnL` = reset, `btnC` = start (obaj gracze muszą wcisnąć), `btnU`/`btnD`
   = ruch paletki.
