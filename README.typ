// vi: ft=typst et ts=2 sts=2 sw=2 tw=72

#set document(
  title: "tbl.typ: a tbl-like preprocessor for Typst and tablex",
  author: "Max Rees",
)

#set page(
  paper: "us-letter",
  margin: (top: 1in, rest: 0.5in),
  header-ascent: 0.5in,
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

#let font = "New Computer Modern"
#set text(
  font: font,
  size: 14pt,
)

#show link: set text(fill: blue)

#show raw.where(block: false): it => {
  box(
    fill: luma(85%),
    inset: (x: 0.1em),
    outset: (y: 0.3em),
    radius: 0.3em,
    it.text,
  )
}

#show heading: it => {
  set text(size: calc.max(1.4em - 0.1em * (it.level - 1), 1em))

  block(
    breakable: false,
    inset: (bottom: 10pt),
    stroke:
      if it.level == 1 { (bottom: 1pt) }
      else { none },
    width: 100%,
    it.body,
  )
}

#let prose = it => {
  set par(leading: 0.5em, justify: true)
  set text(hyphenate: true, overhang: true)
  it
}

#let TK = strong(text(fill: red)[TK])
#let option(name) = {
  link(label("options." + name), raw(block: false, name))
}

#show figure.where(kind: "example"): it => block(
  breakable: false,

  {
    {
      set text(font: font)
      if it.caption in (none, [], "") {
        strong[#it.supplement #it.counter.display()]
      } else [
        #strong[#it.supplement #it.counter.display():] #it.caption
      ]
    }
    box(
      stroke: 1pt,
      it.body
    )
  },
)

#show raw.where(block: true): it => {
  if it.lang == none or not it.lang.starts-with("tbl") {
    block(
      width: 100%,
      fill: luma(85%),
      inset: 0.5em,
      stroke: 1pt,
      it.text,
    )
  } else if it.lang.starts-with("tbl-example") {
    let dir = ltr
    let sep = (1fr, 1fr)
    let width = 50%
    if it.lang.ends-with("-wide") {
      dir = ttb
      sep = (1em, 1em)
      width = 100%
    }
    let caption = none
    let src = it.text
    let caption = src.match(regex(`(?m)\A\.\\"[ \t]*Caption:[ \t]*(.*?)$`.text))
    if caption != none {
      src = src.slice(caption.end + 1)
      caption = eval("[" + caption.captures.first() + "]")
    }

    figure(
      kind: "example",
      supplement: "Example",
      caption: caption,

      align(center, stack(
        dir: dir,

        {
          set text(size: 0.8em)
          block(
            width: width,
            fill: luma(85%),
            inset: 0.5em,
            stroke: 1pt,
            align(left, "```tbl\n" + src + "\n```"),
          )
        },
        sep.first(),
        align(horizon, raw(lang: "tbl", src)),
        sep.last(),
      ))
    )
  } else {
    it
  }
}

#{
  v(1fr)

  strong[
    #set align(center)
    #set text(size: 2em)
    `tbl.typ`: a `tbl`-like preprocessor \
    for Typst and `tablex`
  ]

  [
    #set align(center)
    #set text(size: 1.2em)
    Version #TK \
    Max Rees \
    2023
  ]

  v(1fr)
  outline()
  pagebreak()
}

= Introduction <intro>
#prose[
  Typst @Typst is "a new markup-based typesetting system that is
  powerful and easy to learn." While Typst provides a built-in `table()`
  function, it does not currently support more advanced features such as
  row spans and column spans, fine-grain control of borders, or complex
  cell alignments. Pg Biel's `tablex` project @tablex.typ provides many
  of these features. However, it remains the case that writing a table
  using either `table()` or `tablex()` can require rather verbose
  syntax.

  The `tbl.typ` project is an effort to allow the expression of rich
  tables in Typst using a more terse syntax. This syntax comes from a
  #smallcaps[unix] heritage: the `tbl` preprocessor which designed for
  use with the traditional #smallcaps[troff] typesetting system @tbl.1
  @tbl.7 @Cherry.  Important differences between the syntax of
  traditional `tbl` and `tbl.typ` are noted in Section #TK.

  After importing the library using `#import "tbl.typ"`, the basic
  format of a table when using `tbl.typ` is the following:

````
```tbl
Format specifications .
Data
```
````

  The two main components of this syntax are:

  - #link(<specs>)[_Format specifications_]. This describes the layout
    of the table in terms of the number and style of columns for each
    row.

    The last line of the format specifications must end in a period
    (`.`). This is the separator between the two sections.

  - #link(<data>)[_Data_]. This is the content that will fill each cell
    of the table.  Generally every line of input in this section
    corresponds to a row in the table, though there are exceptions noted
    later. Cells are separated by the #option("tab") option which
    defaults to a #smallcaps[tab] character.
]

#pagebreak()

= Region options <options>
#let options = (
  (`auto-lines`, (`allbox`,), `false`, [Like #option("box"), but also
   draw a line between every cell if `true`. This is the same option from
   `tablex`.]),
  (`box`, (`frame`,), `false`, [If `true`, draw a line around the entire
   table.]),
  (`breakable`, (`nokeep`,), `false`, [If `true`, the table can span
   multiple pages if necessary.]),
  (`decimalpoint`, (), `"."`, [The string used to separate the integral
   part of a number from the fractional part.]),
  (`doublebox`, (`doubleframe`,), `false`, [Like #option("box"), but
   also draw a second line around the entire table if `true`.]),
  (`font`, (), `"Times"`, [The font for the table. Can be overridden
   later by the format specifications.]),
  (`header-rows`, (), `1`, [The number of rows at the beginning of the
   table to consider part of the "header" for the purposes of
   #option("repeat-header"). This option is also controlled by `.TH`
   rows in the table data.]),
  // leading
  (`macros`, (), `(:)`, [A dictionary of (name, function) pairs that can
   be used with column modifier `m`.]),
  // pad
  (`repeat-header`, (), `false`, [If #option("breakable") is `true` and
   this option is `true`, then the table header controlled by
   #option("header-rows") will be re-displayed on each subsequent page.
   This option is also controlled by `.TH` rows in the table data.]),
  (`stroke`, (`linesize`,), `1pt`, [How to draw all lines in the
   table.]),
  (`tab`, (), [`"\t"` (a #smallcaps[tab] character)], [The string
   delimiter that separates different cells within a given row of the
   table data.]),
  (`tbl-align`, (), `left`, [How to align the table as a whole.]),
)
#prose[

  In addition to the overall #link(<intro>)[table syntax] itself, you
  may specify _region options_ that control the parsing and styling of
  the table as a whole using a "show-everything" rule prior to the
  tables you would like to control. For example:

```
#show: tbl.template.with(
  allbox: true,
  tab: "|",
)
```

  The following options are recognized:

  #style(styles => {
    set par(justify: false)
    set text(hyphenate: false)
    let width = calc.max(..options.map(o => measure(o.first(), styles).width))
    let first = true
    for (name, aliases, default, desc) in options {
      aliases = aliases.join([, ])
      if aliases != none { aliases = [_Aliases:_ #aliases \ ] }
      block(
        breakable: false,
        width: 100%,
        inset: (top: 0em, bottom: 0.5em),
        below: 0.5em,
        stroke: (bottom: 0.5pt + gray),

        terms(
          indent: 1em,
          hanging-indent: width + 1em,
          separator: h(1em),
          tight: true,
          spacing: 0em,

          (
            box(width: width, [#name #label("options." + name.text)]),
            [#desc \ \ #aliases _Default:_ #default]
          ),
        )
      )
    }
  })
]

= Format specifications <specs>

= Data <data>

= Examples

#import "tbl.typ"
#let template = tbl.template.with(
  font: font,
)

#show: template.with(
  box: true,
  tab: "|",
)

```tbl-example
.\" Caption: adapted from @tbl.7
lz  s | rt
lt| cb| ^
^ | rz  s.
left||r
l|center|
|right
```

```tbl-example
.\" Caption: adapted from @Cherry[p. 41]
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
.\" Caption: adapted from @tbl.7
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
.\" Caption: adapted from @Cherry[p. 43]
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
.\" Caption: adapted from @Cherry[p. 42]
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

#show: template.with(
  tab: "|",
)

```tbl-example
.\" Caption: adapted from @tbl.7
rb c  lb
r  ci l.
r|center|l
ri|ce|le
right|c|left
```

```tbl-example
.\" Caption: adapted from @tbl.1
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
.\" Caption: adapted from @Cherry[p. 42]
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
.\" Caption: adapted from @Cherry[p. 37]
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

#show: template.with(
  allbox: true,
  tab: "|",
)

```tbl-example
.\" Caption: adapted from @Cherry[p. 41]
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
.\" Caption: adapted from @Cherry[p. 44]
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

```tbl-example-wide
.\" Caption: adapted from @tbl.7
le le7| lw(10).
The fourth line|_|line 1
of this column|=|line 2
determines|\_|line 3
the column width.|T{
This text is too wide to fit into a column of width 17.
T}|line 4
T{
No break here.
T}||line 5
```

#show: template.with(
  doublebox: true,
  tab: " : ",
  nokeep: true,
)

```tbl-example
.\" Caption: adapted from @Cherry[p. 45]
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

#bibliography(
  "README.yml",
  title: [References],
  style: "ieee",
)
