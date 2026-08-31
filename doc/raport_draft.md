# Tytuł: Ping-Pong Multiplayer na Basys3 (DONE)
*(zaproponuj własny tytuł, jeśli macie lepszy pomysł)*

**Autorzy:** Mateusz Zybura (MZ), Gabriel Zawiślak (GZ)

**Ostatnia modyfikacja:** [DO UZUPEŁNIENIA - data]

---

## 1. Repozytorium git

Adres repozytorium GITa:

**[DO UZUPEŁNIENIA]** — repozytorium jeszcze nie zostało utworzone. Trzeba zainicjalizować `git init`, dodać pliki źródłowe (z pominięciem katalogów generowanych przez Vivado — patrz `.gitignore`), założyć repozytorium na GitHub/Bitbucket i wkleić tu link. Jeśli repozytorium będzie prywatne, zaprosić `kaczmarczyk@agh.edu.pl`.

---

## 2. Wstęp (DONE)

Projekt jest cyfrową implementacją klasycznej gry Ping-Pong (Pong) w trybie multiplayer na dwóch płytkach Basys3. Pomysł wziął się z chęci zrealizowania prostej, ale w pełni interaktywnej gry czasu rzeczywistego, wymagającej jednoczesnej obsługi grafiki VGA, fizyki ruchu (odbicia, przyspieszanie piłki, losowość) oraz komunikacji między dwiema niezależnymi płytkami FPGA.

Każdy z graczy steruje swoją paletką za pomocą przycisków własnej płytki Basys3. Cała logika gry (pozycje obu paletek, pozycja piłki, wynik, przebieg rozgrywki) jest liczona na jednej płytce (MASTER), która jednocześnie wyświetla obraz na monitorze VGA. Druga płytka (player_2) nieprzerwanie odczytuje stan swoich przycisków i przesyła go do MASTERA przez UART, dzięki czemu gracz przy drugiej płytce może sterować swoją paletką w czasie rzeczywistym.

**Uwaga do sekcji "co było trudne":** Największym wyzwaniem okazała się komunikacja UART między płytkami. Powracający błąd transmisji zmusił nas do zmodyfikowania koncepcji gry na model, który działa obecnie: Master-Slave. Cała logika rozgrywki — fizyka piłki, pozycje obu paletek i wynik — liczona jest wyłącznie na jednej płytce (MASTER), która jako jedyna wyświetla obraz, natomiast druga płytka (player_2/Slave) pełni rolę czystego urządzenia wejściowego, nieprzerwanie przesyłając do MASTERA stan swoich przycisków. To podejście okazało się prostsze i znacznie stabilniejsze niż pierwotnie zakładana dwustronna synchronizacja pełnego stanu gry między dwiema niezależnie liczącymi płytkami.

---

## 3. Specyfikacja

### 3.1. Opis ogólny algorytmu (BRAKUJE SCHEMATU BLOKOWEGO)

1. **Start układu** — reset (asynchroniczne wejście, synchroniczne wyjście z resetu przez dedykowany moduł `reset_ctrl`) ustawia obie płytki w stanie początkowym.
2. **Ekran startowy** — MASTER wyświetla napis "PRESS THE MIDDLE BUTTON TO START". Gra czeka na naciśnięcie środkowego przycisku (BTNC) na MASTERZE.
3. **Start rozgrywki** — po naciśnięciu BTNC automat stanu gry (`game_fsm`) przechodzi w stan `PLAYING`. Piłka odczekuje ok. 1 sekundę na środku ekranu, po czym rusza w losowym kierunku i pod losowym kątem (generowane przez wolnostojący 8-bitowy LFSR, próbkowany w chwili startu — niezależnie od zegara gry, więc wynik jest w praktyce nieprzewidywalny).
4. **Rozgrywka** — obie paletki poruszają się góra/dół (BTNU/BTND): paletka gracza 1 sterowana lokalnymi przyciskami MASTERA, paletka gracza 2 sterowana przyciskami player_2, przesyłanymi ciągle przez UART. Piłka:
   - odbija się od widocznej, wsuniętej 12 pikseli od krawędzi ekranu górnej/dolnej granicy boiska,
   - odbija się od paletek pod kątem zależnym od miejsca trafienia (trafienie bliżej krawędzi paletki = ostrzejszy kąt),
   - przyspiesza o jeden "krok" prędkości po każdym odbiciu od paletki (do limitu), i wraca do wolnego tempa na starcie każdego kolejnego punktu,
   - po dotknięciu lewej lub prawej krawędzi ekranu kończy punkt i przyznaje go przeciwnikowi.
5. **Koniec gry** — pierwszy gracz, który zdobędzie 9 punktów, wygrywa; ekran pokazuje napis "GAMEOVER". Powrót do gry wymaga pełnego resetu (BTNL).

*(Tu wstawcie uproszczony schemat blokowy / diagram stanów: IDLE → PLAYING → END, oraz ewentualnie zrzut ekranu z gry.)*

### 3.2. Tabela zdarzeń (DONE)

| Zdarzenie | Kategoria | Reakcja systemu |
|---|---|---|
| Naciśnięcie BTNC | Ekran startowy | Start rozgrywki (przejście `IDLE` → `PLAYING`) |
| Naciśnięcie BTNU / BTND (lokalnie lub zdalnie, przez player_2) | Gra | Ruch odpowiedniej paletki w górę/w dół |
| Piłka dotyka górnej/dolnej granicy boiska | Gra | Odbicie piłki (zmiana kierunku ruchu pionowego) |
| Piłka dotyka paletki | Gra | Odbicie piłki pod kątem zależnym od miejsca trafienia, przyspieszenie |
| Piłka dotyka lewej lub prawej krawędzi ekranu | Gra | Punkt dla przeciwnika, piłka wraca na środek, prędkość resetuje się |
| Wynik jednego z graczy osiąga 9 | Gra | Koniec gry, ekran "GAMEOVER" |
| Naciśnięcie BTNL | Dowolny stan | Pełny reset układu, powrót do ekranu startowego |

---

## 4. Architektura

### 4.1. Moduł: top (`top_vga` na MASTERZE)

Osoba odpowiedzialna: **[DO UZUPEŁNIENIA - MZ/GZ]**

#### 4.1.1. Schemat blokowy

*(Miejsce na właściwy diagram — poniżej opis strukturalny do wykorzystania jako podstawa rysunku.)*

`top_vga` (MASTER) łączy ze sobą następujące moduły funkcjonalne, komunikujące się głównie przez interfejs `vga_if` (potok rysowania) oraz proste sygnały danych:

```
vga_timing -> draw_bg -> draw_char -> draw_score -> draw_paddle_ball -> (r,g,b,hs,vs)
                 ^            ^            ^               ^
              (tło+granica) (tekst)     (wynik)      (paletki+piłka)

game_fsm --(flag_char)--> steruje draw_char / ball_pos / paddle_pos / counter_refresh_time
paddle_pos --(paddle1_y, paddle2_y)--> ball_pos, draw_paddle_ball
ball_pos --(ball_x, ball_y, score_1, score_2)--> draw_paddle_ball, draw_score, game_fsm
receive_bytes <--(UART)-- player_2 (stan przycisków BTNU/BTND gracza 2)
```

#### 4.1.2. Porty

a) **btn** – przyciski, input

| nazwa portu | opis |
|---|---|
| btn_C | środkowy przycisk — start gry |
| btn_up | przycisk góra — ruch paletki gracza 1 |
| btn_down | przycisk dół — ruch paletki gracza 1 |

b) **uart** – łącze do player_2

| nazwa portu | opis |
|---|---|
| rx_pin | wejście UART — odbiór stanu przycisków gracza 2 |

c) **vga** – wyjście obrazu, output

| nazwa portu | opis |
|---|---|
| vs | sygnał synchronizacji pionowej VGA |
| hs | sygnał synchronizacji poziomej VGA |
| r[3:0], g[3:0], b[3:0] | składowe koloru piksela |

#### 4.1.3. Interfejsy

a) **vga_if** – potok przetwarzania obrazu między kolejnymi etapami rysowania (`vga_timing` → `draw_bg` → `draw_char` → `draw_score` → `draw_paddle_ball`)

| nazwa sygnału | opis |
|---|---|
| vga_hcount[10:0] | bieżąca pozycja pozioma skanowania |
| vga_vcount[10:0] | bieżąca pozycja pionowa skanowania |
| vga_hsync, vga_vsync | sygnały synchronizacji |
| vga_hblnk, vga_vblnk | sygnały wygaszania |
| vga_rgb[11:0] | kolor bieżącego piksela, modyfikowany przez kolejne etapy potoku |

### 4.2. Rozprowadzenie sygnału zegara

Osoba odpowiedzialna: **[DO UZUPEŁNIENIA - MZ/GZ]**

Płytka Basys3 dostarcza zegar wejściowy 100 MHz (`clk`). Jedyny generowany zegar pochodny to 65 MHz (`clk_65Mhz`, oznaczany w kodzie jako `pclk`), wytwarzany przez IP core `clk_wiz_0` (MMCM). Ten pojedynczy zegar 65 MHz jest jedynym zegarem używanym w całym projekcie — zarówno do generowania sygnałów VGA (timing 1024×768@60Hz), jak i do całej logiki gry oraz komunikacji UART. Dzięki jednej domenie zegarowej nie występują problemy z synchronizacją między blokami funkcjonalnymi.

Wyjście `locked` z `clk_wiz_0` jest wykorzystywane przez dedykowany moduł `reset_ctrl` (jedyne miejsce w projekcie z resetem w pełni asynchronicznym) — układ nie wychodzi z resetu, dopóki PLL się nie ustabilizuje, a wyjście z resetu jest dodatkowo zsynchronizowane do zegara (2-stopniowy synchronizator), tak aby wszystkie rejestry w projekcie wychodziły z resetu na tym samym zboczu zegara.

---

## 5. Implementacja

### 5.1. Lista zignorowanych ostrzeżeń Vivado

**[DO UZUPEŁNIENIA]** — po uruchomieniu syntezy/implementacji w Vivado przejrzyjcie zakładkę "Messages" i wypełnijcie tabelę:

| Identyfikator ostrzeżenia | Liczba wystąpień | Uzasadnienie |
|---|---|---|
| | | |
| | | |

### 5.2. Wykorzystanie zasobów

**[DO UZUPEŁNIENIA]** — tabela z Vivado: Reports → Report Utilization (po implementacji). Wklejcie tabelę LUT/FF/BRAM/DSP z procentowym wykorzystaniem względem dostępnych zasobów XC7A35T.

### 5.3. Marginesy czasowe

**[DO UZUPEŁNIENIA]** — Reports → Report Timing Summary (po implementacji). Podajcie WNS (Worst Negative Slack) dla setup i hold.

---

## 6. Konfiguracja sprzętu

**Architektura:** obraz jest wyświetlany wyłącznie z płytki MASTER na jednym monitorze VGA — obaj gracze siedzą obok siebie i patrzą na ten sam ekran, każdy sterując swoją paletką z własnej płytki. **Uwaga:** to odstępstwo od dosłownego zapisu wymagań (każdy użytkownik ma mieć własny ekran) — [DO UZUPEŁNIENIA: potwierdźcie tu, że macie wyraźną zgodę prowadzącego na tę architekturę, zgodnie z pkt. 2.4 wymagań projektu].

**Połączenie między płytkami** (goldpiny, jeden kierunek transmisji UART — player_2 → MASTER):

| Sygnał | MASTER | player_2 |
|---|---|---|
| TX (player_2) → RX (MASTER) | Pmod JC, pin 1 (JC1, RX) | Pmod JXADC, pin 1 (TX) |
| Wspólna masa | GND | GND |

Master dodatkowo wyprowadza kopię zegara pikseli na pin JA1 (Pmod JA) — wyłącznie do celów diagnostycznych (podgląd na oscyloskopie/analizatorze stanów logicznych), niewykorzystywana funkcjonalnie w rozgrywce.

Nie są używane żadne dodatkowe urządzenia peryferyjne (mysz, klawiatura) — interfejsem użytkownika są wbudowane przyciski Basys3 (BTNU, BTND, BTNC, BTNL). Nie zmieniano konfiguracji przełączników ani zworek względem ustawień domyślnych płytki.

*(Tu warto wstawić zdjęcie rzeczywistego połączenia obu płytek.)*

---

## 7. Film

Link do ściągnięcia filmu:

**[DO UZUPEŁNIENIA]**
