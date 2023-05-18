// vi: ft=typst et ts=2 sts=2 sw=2
#import "tbl.typ"

#set text(
  font: "New Computer Modern",
  size: 14pt,
)
#show raw.where(block: false, lang: none): it => {
  set text(
    font: "CMU Typewriter Text",
  )
  box(
    fill: luma(85%),
    inset: (x: 0.1em),
    outset: (top: 0.1em, bottom: 0.3em),
    radius: 0.2em,
    it.text,
  )
}
#show raw.where(block: true, lang: "tbl-example"): it => block(
  breakable: false,
  align(center, stack(
    dir: ltr,

    {
      set text(
        font: "CMU Typewriter Text",
      )
      block(
        width: 55%,
        fill: luma(85%),
        inset: 0.5em,
        align(left, "```tbl\n" + it.text + "\n```"),
      )
    },
    1fr,
    align(horizon, raw(lang: "tbl", it.text)),
    1fr,
  ))
)
#let title = ""
#set document(
  title: "tbl.typ: a tbl(1)-like preprocessor for Typst and tablex.typ",
  author: "Max Rees",
)
#set page(
  paper: "us-letter",
  margin: 0.5in,
  header: locate(loc => {
    let page-num = counter(page).at(loc).first()

    if page-num > 1 {
      stack(
        dir: ltr,
        text(size: 1.2em, `tbl.typ`),
        1fr,
        [#page-num],
      )
    }
  })
)
#show heading: it => {
  set text(size: calc.max(1.4em - 0.1em * (it.level - 1), 1em))

  block(
    breakable: false,
    inset: (bottom: 5pt),
    stroke:
      if it.level == 1 { (bottom: 1pt) }
      else { none },
    width: 100%,
    it.body,
  )
}

#[
  #set align(center)
  #v(1fr)

  #strong[
    #set text(size: 2em)
    `tbl.typ`: a `tbl(1)`-like preprocessor \
    for Typst and `tablex.typ`
  ]

  #set text(size: 1.2em)
  Version TK \
  Max Rees \
  2023

  #v(1fr)
  #pagebreak()
]

= Examples

#show: tbl.template.with(
  box: true,
  tab: "|",
)

```tbl-example
lz  s | rt
lt| cb| ^
^ | rz  s.
left||r
l|center|
|right
```

```tbl-example
c c c
l l ne .
Fact|Location|Statistic
Largest state|Alaska|591,004 sq. mi.
Smallest state|Rhode Island|1,212 sq. mi.
Longest river|Mississippi-Missouri|3,710 mi.
Highest mountain|Mount McKinley, AK|20,320 ft.
Lowest point|Death Valley, CA|-- 282 ft.
```

```tbl-example
r| l
r  n.
software|version
_
AFL|2.39b
Mutt|1.8.0
Ruby|1.8.7.374
TeX Live|2015
```

```tbl-example
cf(Courier New) s s s
c | cs s
c | cs s
c |c|c|c
c |c|c|c
l |n |ne |ne.
Composition of Foods
_
Food|Percent by Weight
\^|_
\^|Protein|Fat|Carbo-
\^|\^|\^|hydrate
_
Apples|.4|.5|13.0
Halibut|18.4|5.2|...
Lima beans|7.5|.8|22.0
Milk|3.3|4.0|5.0
Mushrooms|3.5|.4|6.0
Rye bread|9.0|.6|52.7
```

```tbl-example
c s s
c | c | c
l | l | ne .
Major New York Bridges
_
Bridge|Designer|Length
_
Brooklyn|J . A . Roebling|1595
Manhattan|G . Lindenthal|1470
Williamsburg|L . L . Buck|1600
_
Queensborough|Palmer &|1182
|Hornbostel
_
||1380
Triborough|O . H . Ammann|_
||383
_
Bronx Whitestone|O . H . Ammann|2300
Throgs Neck|O . H . Ammann|1800
_
George Washington|O . H . Ammann|3500
```

#show: tbl.template.with(
  tab: "|",
)

```tbl-example
rb c  lb
r  ci l.
r|center|l
ri|ce|le
right|c|left
```

```tbl-example
Cf(BI) Cf(BI) Cf(B), C C Cu.
n|n*#sym.times;*n|difference
1|1
2|4|3
3|9|5
4|16|7
5|25|9
6|36|11
```

```tbl-example
c c
np(-2) | n | .
|Stack
|_
1|46
|_
2|23
|_
3|15
|_
4|6.5
|_
5|2.1
|_
```

```tbl-example
n.
13
4.2
26.4.12
26.4. 12
26.4 .12
abc
abc\&
43\&3.22
749.12
```

#show: tbl.template.with(
  allbox: true,
  tab: "|",
)

```tbl-example
c s s
c c c
n n ne .
AT&T Common Stock
Year|Price|Dividend
1984|15-20|\$1.20
5|19-25|1.20
6|21-28|1.20
7|20-36|1.20
8|24-30|1.20
9|29-37|.30\*
```

```tbl-example
cb cb
c  c.
Grade|Points
A|510
B|450
C|390
D|330
```

```tbl-example
cf(I) s s
c cw(1in) cw(1in)
ltp(9) ltp(9) ltp(9).
New York Area Rocks
Era|Formation|Age (years)
Precambrian|Reading Prong|>1 billion
Paleozoic|Manhattan Prong|400 million
Mesozoic|T{
#set text(hyphenate: true, overhang: true)
Newark Basin, incl.
Stockton, Lockatong, and Brunswick
formations; also Watchungs
and Palisades.
T}|200 million
Cenozoic|Coastal Plain|T{
#set text(hyphenate: true, overhang: true)
#set par(justify: true)
On Long Island 30,000 years;
Cretaceous sediments redeposited
by recent glaciation.
T}
```

```tbl-example
le le7| lw(10).
The fourth line|_|line 1
of this column|=|line 2
determines|\_|line 3
the column width.|T{
#set text(hyphenate: true, overhang: true)
This text is too wide to fit into a column of width 17.
T}|line 4
T{
No break here.
T}||line 5
```

#show: tbl.template.with(
  doublebox: true,
  tab: " : ",
  nokeep: true,
)

```tbl-example
cb s s s s
cp(-2) s s s s
c | c | c | c | c
c | c | c | c | c
r2 | n2 | n2 | n2e | nbe.
Readability of Text
Line Width and Leading for 10-Point Type
_
Line : Set : 1-Point : 2-Point : 4-Point
Width : Solid : Leading : Leading : Leading
_
9 Pica : 93 : --6.0 : --5.3 : --7.1
14 Pica : 450 : --0.6 : --0.3 : --1.7
19 Pica : 5 : --5.1 : 0.0 : --2.0
31 Pica : 3 : --3.8 : --2.4 : --3.6
43 Pica : 5.1 : --90000.000 : --5.9 : --8.8
```
