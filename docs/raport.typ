// Raport końcowy — Niezawodność transmisji w scenariuszu awarii obszarowej
// Strona tytułowa zostanie dodana osobno.

#set text(lang: "pl", size: 11pt)
#set page(numbering: "1", margin: 2.5cm)
#set par(justify: true, leading: 0.65em)
#set heading(numbering: "1.")

#show heading.where(level: 1): it => [
  #v(0.6em)
  #block(text(size: 14pt, weight: "bold", it.body))
  #v(0.3em)
]

#show heading.where(level: 2): it => [
  #v(0.3em)
  #block(text(size: 12pt, weight: "bold", it.body))
  #v(0.2em)
]

// Ścieżki do rysunków są względne do katalogu projektu (o jeden poziom wyżej).
#let fig-topology = "../topology.png"
#let fig-results = "../reliability.png"

#heading(numbering: none, outlined: false)[Spis treści]
#outline(title: none, indent: auto)
#pagebreak()

= Charakterystyka zagadnienia i opis problemu

Współczesne sieci telekomunikacyjne należą do infrastruktury krytycznej, dlatego ich
odporność na awarie i katastrofy jest ważnym problemem badawczym. Literatura pokazuje, że
najpoważniejsze zakłócenia nie wynikają z pojedynczych uszkodzeń, lecz z *awarii
obszarowych*, czyli takich, które obejmują jednocześnie wiele elementów sieci położonych w
tym samym obszarze geograficznym. Do zdarzeń takich zalicza się m.in. trzęsienia ziemi,
powodzie, huragany czy inne zjawiska naturalne, jak i celowe ataki, które mogą równocześnie
wyłączyć wiele węzłów i łączy.

W literaturze awarie obszarowe opisuje się jako zdarzenia obejmujące jednocześnie wiele
elementów sieci, wynikające z jednego wspólnego zagrożenia o charakterze geograficznym. W
analizach odporności sieci wykorzystuje się w tym celu m.in. modele SRLG (Shared Risk Link
Group), które grupują łącza i węzły podatne na wspólne źródło uszkodzenia, oraz modele
obszarowych awarii, w których obszar katastrofy reprezentuje się jako obszar oddziaływania,
często w postaci okręgu. Takie podejście dobrze oddaje sytuacje, w których jedno zdarzenie
naturalne może wyłączyć naraz wiele komponentów infrastruktury znajdujących się w jego
zasięgu.

Celem analizy w niniejszym projekcie jest ocena, jak podatne są trasy podstawowe na awarie
obszarowe oraz czy po wystąpieniu uszkodzeń możliwe jest wyznaczenie alternatywnej trasy
zabezpieczającej rozłącznej węzłowo. Tego typu podejście wpisuje się w szerszy nurt badań
nad odpornością sieci, w którym bada się nie tylko samą spójność topologii, ale także
skuteczność rozwiązań routingowych i protekcyjnych w scenariuszu awarii obszarowej.

= Opis proponowanej metody rozwiązania problemu

Rozwiązanie problemu zostało zrealizowane poprzez symulację w języku Python z
wykorzystaniem biblioteki NetworkX. Topologia sieci została zamodelowana jako graf
nieskierowany $G = (V, E)$. Algorytm badawczy składa się z następujących kroków:

+ *Analiza struktury.* Wczytanie grafu topologii i obliczenie średnicy sieci $D$ rozumianej
  jako największa z najkrótszych odległości (liczonych w liczbie przeskoków) pomiędzy
  dowolną parą węzłów.

+ *Wyznaczenie trasy podstawowej.* Dla zadanej pary węzłów krańcowych $(s, t)$ wyznaczana
  jest najkrótsza ścieżka algorytmem Dijkstry.

+ *Generowanie scenariuszy awarii.* Dla każdego węzła $v$ pełniącego rolę epicentrum oraz
  dla każdej wartości promienia $r$ wyznaczany jest zbiór węzłów uszkodzonych — strefa
  awarii. Zgodnie z literaturą strefę modelujemy jako okrąg (dysk) o promieniu $r$ w
  przestrzeni geograficznej: węzeł $u$ ulega uszkodzeniu, gdy jego odległość euklidesowa od
  epicentrum spełnia warunek $d(v, u) <= r$, gdzie $d$ wyznaczane jest na podstawie
  współrzędnych węzłów.

+ *Weryfikacja i protekcja.* Dla każdego scenariusza:
  - sprawdzana jest kolizja trasy podstawowej ze strefą awarii (czy któryś z węzłów trasy
    znalazł się w strefie),
  - generowany jest graf rezydualny poprzez usunięcie węzłów objętych awarią oraz węzłów
    pośrednich (tranzytowych) trasy podstawowej; usunięcie tych ostatnich gwarantuje, że
    znaleziona trasa zabezpieczająca będzie rozłączna węzłowo z trasą podstawową,
  - podejmowana jest próba wyznaczenia trasy zabezpieczającej rozłącznej węzłowo w grafie
    rezydualnym.

= Wykaz funkcji biblioteki NetworkX użytych do rozwiązania problemu

Do implementacji symulacji wykorzystano bibliotekę NetworkX (wersja 3.6.1). Główne
wykorzystane funkcje zestawiono w tabeli @tab-funkcje.

#figure(
  table(
    columns: (auto, 1fr),
    align: (left, left),
    stroke: 0.5pt,
    table.header([*Funkcja*], [*Przeznaczenie*]),
    [`nx.Graph()`], [Inicjalizacja i przechowywanie nieskierowanej topologii sieci.],
    [`nx.diameter(G)`], [Wyznaczenie topologicznej średnicy sieci (krok 1).],
    [`nx.shortest_path(G, source, target, weight)`],
      [Wyznaczanie najkrótszej ścieżki algorytmem Dijkstry — trasa podstawowa i zabezpieczająca.],
    [`G.copy()`], [Utworzenie kopii grafu na potrzeby symulacji uszkodzeń.],
    [`G.remove_nodes_from(nodes)`],
      [Usuwanie węzłów z grafu — generowanie grafu rezydualnego.],
    [`nx.has_path(G, source, target)`],
      [Weryfikacja istnienia połączenia (spójności) po awarii.],
  ),
  caption: [Wykaz funkcji biblioteki NetworkX wykorzystanych w implementacji.],
) <tab-funkcje>

= Opis założeń eksperymentów symulacyjnych

*Topologia.* Analizę przeprowadzono dla przydzielonej struktury sieci przedstawionej na
rysunku @fig-topo. Sieć liczy 17 węzłów i 33 łącza nieskierowane. Średni stopień węzła
wynosi 3,88 (minimalny 3, maksymalny 6), a spójność węzłowa i krawędziowa są równe 3, co
oznacza, że w warunkach bezawaryjnych dla dowolnej pary węzłów istnieją co najmniej trzy
rozłączne węzłowo trasy.

#figure(
  image(fig-topology, width: 70%),
  caption: [Analizowana topologia sieci (17 węzłów, 33 łącza).],
) <fig-topo>

*Średnica sieci.* Topologiczna średnica grafu (w liczbie przeskoków) wynosi 4. Ponieważ
strefy awarii modelowane są jako okręgi w przestrzeni geograficznej, do skalowania promieni
przyjęto *średnicę geograficzną* sieci $D$ — największą odległość euklidesową pomiędzy
dowolną parą węzłów. Dla analizowanej topologii wynosi ona 9,65 (para węzłów 3 i 16).
Współrzędne węzłów odczytano z rysunku topologii, a odległości euklidesowe wyznaczono z
zależności $d(a, b) = sqrt((x_a - x_b)^2 + (y_a - y_b)^2)$.

*Trasy podstawowe.* Jako pary węzłów krańcowych transmisji rozpatrzono wszystkie
$binom(17, 2) = 136$ par węzłów. Dla każdej pary wyznaczono trasę podstawową algorytmem
Dijkstry, przyjmując jednostkowe wagi łączy (trasa najkrótsza w sensie liczby przeskoków).

*Promienie stref awarii.* Zgodnie z treścią zadania promień $r$ strefy awarii przyjmuje
wartości ${5%, 10%, 15%, 25%, 30%}$ średnicy geograficznej $D$, co daje promienie $r$ równe
w przybliżeniu 0,48; 0,97; 1,45; 2,41 oraz 2,90 jednostki odległości. Węzeł zostaje
uszkodzony, gdy jego odległość euklidesowa od epicentrum nie przekracza $r$.

*Lokalizacja epicentrów.* Epicentrum awarii umieszczano kolejno w każdym z 17 węzłów sieci.

*Liczba scenariuszy.* Dla każdej wartości promienia rozpatrzono
$17 "epicentrów" times 136 "par" = 2312$ scenariuszy.

*Definicje miar.* Dla każdej wartości promienia $r$ wyznaczono:
- *odsetek tras wymagających protekcji* — udział scenariuszy, w których strefa awarii koliduje
  z trasą podstawową (trasa wymaga wyznaczenia trasy zabezpieczającej),
- *odsetek tras zabezpieczalnych* — udział tras spośród wymagających protekcji, dla których
  możliwe jest wyznaczenie trasy zabezpieczającej rozłącznej węzłowo w grafie rezydualnym.

= Wyniki eksperymentów wraz z ich analizą

Uśrednione wyniki w podziale na wartości promienia $r$ przedstawiono w tabeli @tab-wyniki
oraz na rysunku @fig-wyniki.

#figure(
  table(
    columns: 6,
    align: (center, center, center, center, center, center),
    stroke: 0.5pt,
    table.header(
      [*$r$ [% $D$]*], [*$r$ [jedn.]*], [*Scenariuszy*],
      [*Wymaga protekcji*], [*Zabezpieczalnych*], [*Zabezpieczalnych [%]*],
    ),
    [5 %],  [0,48], [2312], [441 (19,1 %)],   [169], [38,3 %],
    [10 %], [0,97], [2312], [441 (19,1 %)],   [169], [38,3 %],
    [15 %], [1,45], [2312], [441 (19,1 %)],   [169], [38,3 %],
    [25 %], [2,41], [2312], [825 (35,7 %)],   [235], [28,5 %],
    [30 %], [2,90], [2312], [1185 (51,3 %)],  [238], [20,1 %],
  ),
  caption: [Uśrednione wyniki analizy w podziale na promień strefy awarii $r$.],
) <tab-wyniki>

#figure(
  image(fig-results, width: 80%),
  caption: [Odsetek tras wymagających protekcji oraz odsetek tras zabezpieczalnych w
    funkcji promienia strefy awarii.],
) <fig-wyniki>

*Analiza wyników.* Wraz ze wzrostem promienia strefy awarii rośnie odsetek tras
podstawowych kolidujących ze strefą — od 19,1 % dla najmniejszych promieni, poprzez 35,7 %
dla $r = 25 %D$, aż do 51,3 % dla $r = 30 %D$. Jednocześnie maleje skuteczność protekcji:
odsetek tras zabezpieczalnych spada z 38,3 % do 28,5 % i dalej do 20,1 %. Wynik ten jest
zgodny z intuicją — większy obszar katastrofy nie tylko uszkadza więcej tras podstawowych,
ale również usuwa z grafu więcej węzłów, co ogranicza dostępność tras alternatywnych
rozłącznych węzłowo.

Wyniki dla promieni 5 %, 10 % i 15 % są identyczne. Wynika to z faktu, że dla analizowanej
topologii najmniejsza odległość euklidesowa pomiędzy sąsiednimi węzłami przekracza 15 %
średnicy geograficznej (czyli $r$ ≈ 1,45). W konsekwencji okręgi awarii o tych promieniach
obejmują wyłącznie samo epicentrum, odwzorowując w praktyce awarię pojedynczego węzła.
Wyraźne zróżnicowanie wyników pojawia się dopiero dla promieni 25 % i 30 %, gdy strefa
zaczyna obejmować również węzły sąsiednie — i te przypadki dają już odmienne rezultaty
(odpowiednio 2,29 i 3,94 uszkodzonego węzła średnio na scenariusz).

Stosunkowo niska zabezpieczalność (maksymalnie 38,3 %) wynika z przyjętej, rygorystycznej
definicji protekcji: trasa zabezpieczająca musi być rozłączna węzłowo z trasą podstawową
*oraz* w całości omijać strefę awarii. W gęściej oczkowanej części sieci (węzły o wysokim
stopniu, np. 6 i 11) protekcja jest częściej możliwa niż dla par korzystających z węzłów
o stopniu 3, leżących na obrzeżach topologii.

= Wnioski końcowe

- Zaimplementowana symulacja realizuje pełny tok badawczy: wyznaczenie średnicy sieci,
  wyznaczanie tras podstawowych algorytmem Dijkstry, generowanie scenariuszy awarii
  obszarowej oraz weryfikację możliwości protekcji rozłącznej węzłowo.

- Odporność tras podstawowych silnie zależy od rozmiaru obszaru awarii: zwiększenie promienia
  z 15 % do 30 % średnicy geograficznej powoduje wzrost odsetka tras dotkniętych awarią z
  19 % do 51 % przy jednoczesnym spadku zabezpieczalności z 38 % do 20 %.

- Kluczowym czynnikiem ograniczającym skuteczność protekcji jest usuwanie ze struktury sieci
  węzłów o wysokim stopniu, przez które przebiega wiele tras podstawowych; ich utrata
  jednocześnie unieważnia trasy podstawowe i zubaża zbiór tras alternatywnych.

- Geometryczny model strefy awarii (okrąg o promieniu liczonym w jednostkach odległości
  geograficznej) wiernie odwzorowuje obszarowy charakter katastrof i pozwala rozróżnić
  scenariusze o różnych promieniach. Dla najmniejszych promieni (5–15 % średnicy) strefa
  obejmuje jednak wyłącznie epicentrum, ponieważ minimalna odległość między sąsiednimi
  węzłami przekracza 15 % średnicy; pełne zróżnicowanie wyników dla wszystkich pięciu
  promieni wymagałoby topologii o gęstszym rozmieszczeniu węzłów lub dokładniejszych
  współrzędnych odczytanych z oryginalnego rysunku.

= Wykaz literatury

+ J. Rak i in., „Fundamentals of communication networks resilience to disasters and massive
  disruptions”, w: _Guide to Disaster-Resilient Communication Networks_, Springer, 2020.

+ J. Rak, _Resilient Routing in Communication Networks_, Springer, 2015.

+ Y. Liu, F. Zhou, T. Shang, „Disaster protection for service function chain provisioning in
  EO-DCNs”.

+ S. Neumayer, G. Zussman, R. Cohen, E. Modiano, „Assessing the vulnerability of the fiber
  infrastructure to disasters”, _IEEE/ACM Transactions on Networking_, t. 19, nr 6, 2011.

+ A. A. Hagberg, D. A. Schult, P. J. Swart, „Exploring network structure, dynamics, and
  function using NetworkX”, w: _Proc. 7th Python in Science Conference (SciPy)_, 2008.

+ E. W. Dijkstra, „A note on two problems in connexion with graphs”, _Numerische
  Mathematik_, t. 1, 1959.

+ J. W. Suurballe, „Disjoint paths in a network”, _Networks_, t. 4, nr 2, 1974.

+ Dokumentacja biblioteki NetworkX: #link("https://networkx.org/documentation/stable/").
