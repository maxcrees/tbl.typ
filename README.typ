// vi: ft=typst et ts=2 sts=2 sw=2 tw=72
#import "tbl.typ"

#set document(
  title: "tbl.typ: a tbl-like preprocessor for Typst and tablex",
  author: "Max Rees",
)

#let current-heading = state("current-heading", none)
#set page(
  paper: "us-letter",
  margin: (top: 0.75in, rest: 0.5in),
  header: locate(loc => {
    let my-page-num = counter(page).at(loc).first()
    let my-heading = current-heading.at(loc)
    let my-line = none
    if my-heading == none {
      my-heading = []
    } else {
      my-heading = align(center, my-heading)
      my-line = place(bottom, dy: 8pt, line(length: 100%))
    }

    if my-page-num > 1 {
      grid(
        columns: (1fr, 1fr),
        text(size: 1.2em, `tbl.typ`),
        align(right)[#my-page-num],
      )
      my-line
    }
  })
)

#let font = "New Computer Modern"
#set text(
  font: font,
  size: 14pt,
  hyphenate: true,
  overhang: true,
)
#set par(leading: 0.5em, justify: true)

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

#set heading(numbering: "1.1.")
#show heading: it => {
  set text(size: calc.max(1.4em - 0.2em * (it.level - 1), 1em))

  block(
    breakable: false,
    inset:
      if it.level == 1 { (bottom: 10pt) }
      else { 0pt },
    stroke:
      if it.level == 1 { (bottom: 1pt) }
      else { none },
    width: 100%,

    if it.body == [Contents] { it.body }
    else [#counter(heading).display() #it.body],
  )
}

#show terms: it => style(styles => {
  let width = calc.max(..it.children.map(t => measure(t.term, styles).width))

  for item in it.children {
    block(
      breakable: false,
      width: 100%,
      inset: (top: 0em, bottom: 0.5em),
      below: 0.5em,
      stroke: (bottom: 0.5pt + gray),

      stack(
        dir: ltr,
        1em,
        box(width: width, {
          show strong: it => {
            let the-label = none
            if it.body.func() == raw {
              the-label = label(it.body.text)
            } else if it.body.func() == text {
              the-label = repr(it.body)
              the-label = the-label.trim("[", at: start, repeat: false)
              the-label = the-label.trim("]", at: end, repeat: false)
              the-label = label(the-label)
            }
            [#it#the-label]
          }
          item.term
        }),
        1em,
        box(width: 100% - width - 2em, item.description),
      ),
    )
  }
})

#let TK = strong(text(fill: red)[TK])
#let troff = smallcaps[troff]
#let issue(num) = link(
  "https://github.com/sroracle/tbl.typ/issues/" + str(num),
  [GH\##num],
)
#let link-label(target, ..text) = {
  text = text.pos()
  if text.len() == 0 {
    text = none
  } else if text.len() == 1 {
    text = text.first()
  } else {
    panic("Too many texts")
  }
  if type(target) == "content" and target.func() == raw {
    if text == none {
      text = target
    }
    target = target.text
  }
  link(label(target), text)
}

#let example = figure.with(kind: "example", supplement: "Example")
#show figure.where(kind: "example"): it => block(
  breakable: false,

  {
    set par(justify: false)
    set text(hyphenate: auto, overhang: false)
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
    let inset = 0pt
    let width = 50%
    if it.lang.ends-with("-wide") {
      dir = ttb
      inset = (y: 1em)
      width = 100%
    }

    align(center, stack(
      dir: dir,

      {
        set text(size: 0.8em)
        block(
          width: width,
          fill: luma(85%),
          inset: 0.5em,
          stroke: 1pt,
          align(left, "```tbl\n" + it.text + "\n```"),
        )
      },
      align(horizon, block(inset: inset, width: width, raw(lang: "tbl", it.text))),
    ))
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
    Version 0.0.1 \
    Max Rees \
    2023
  ]

  v(1fr)
  pagebreak(weak: true)
  outline(indent: true)
}

#pagebreak(weak: true)
= Introduction <intro>
Typst @Typst is "a new markup-based typesetting system that is powerful
and easy to learn." While Typst provides a built-in `table()` function,
it does not currently support more advanced features such as row spans
and column spans, fine-grain control of borders, or complex cell
alignments. Pg Biel's `tablex` project @tablex.typ provides many of
these features. However, it remains the case that writing a table using
either `table()` or `tablex()` can require rather verbose syntax.

The `tbl.typ` project is an effort to allow the expression of rich
tables in Typst using a more terse syntax. This syntax comes from a
#smallcaps[unix] heritage: the `tbl` preprocessor which designed for use
with the traditional #troff typesetting system @tbl.1 @tbl.7 @Cherry.
Important differences between the syntax of traditional `tbl` and
`tbl.typ` are noted #link(<diff>)[later in this document]. The goal of
this project is to support many traditional `tbl` features in a sensible
manner (i.e. not pixel-for-pixel or bug compatible). Some of these
features are unique to `tbl.typ` and are not easily reproduced in either
`table()` or `tablex()` alone.

After importing the library using `#import "tbl.typ"`, the basic format
of a table when using `tbl.typ` is the following:

````
```tbl
Format specifications .
Data
```
````

The two main components of this syntax are:

- #link(<specs>)[_Format specifications_]. This describes the layout of
  the table in terms of the number and style of columns for each row.

  The last line of the format specifications must end in a period (`.`).
  This is the separator between the two sections.

- #link(<data>)[_Data_]. This is the content that will fill each cell of
  the table. Generally every input line in this section corresponds to a
  row in the table, though there are exceptions noted later. Cells are
  separated by the #link-label(`tab`) option which defaults to a
  #smallcaps[tab] character.

#pagebreak(weak: true)
= Region options <options>
In addition to the overall #link(<intro>)[table syntax] itself, you may
specify _region options_ that control the parsing and styling of the
table as a whole using a "show-everything" rule prior to the tables you
would like to control. For example:

```
#show: tbl.template.with(
  allbox: true,
  tab: "|",
)
```

The following options are recognized:

/ *`align`*: How to align the table as a whole.

  _Default:_ `left`

/ *`auto-lines`*, \ `allbox`: Like #link-label(`box`), but also draw a
  line between every cell if `true`. This is the same option from
  `tablex`.

  _Default:_ `false` \
  #emph[cf. @ex-att, @ex-grade[], @ex-rocks[], @ex-lines[].]

/ *`box`*, \ `frame`: If `true`, draw a line around the entire table.

  _Default:_ `false` \
  #emph[cf. @ex-spans, @ex-facts[], @ex-software[], @ex-food[],
  @ex-bridges[].]

/ *`breakable`*, \ `nokeep`: If `true`, the table can span multiple
  pages if necessary.

  _Default:_ `false`

/ *`center`*, \ `centre`: Aliases for a #link-label(`align`) value of
  `center`.

/ *`decimalpoint`*: The string used to separate the integral part of a
  number from the fractional part. Used in #link-label(`N`)-classified
  columns.

  _Default:_ `"."`

/ *`doublebox`*, \ `doubleframe`: Like #link-label(`box`), but also draw
  a second line around the entire table if `true`.

  _Default:_ `false` \
  #emph[cf. @ex-read.]

/ *`font`*: The font for the table. Can be overridden later by the
  #link-label(`f(...)`) column modifier.

  _Default:_ `"Times"` \
  _n.b. all tables in this document are formatted with the #font font._

/ *`header-rows`*: The number of rows at the beginning of the table to
  consider part of the "header" for the purposes of
  #link-label(`repeat-header`). This option is also controlled by `.TH`
  rows in the table data.

  _Default:_ `1`

/ *`leading`*: The vertical spacing / leading to apply to table cells.
  Can be overridden later by the #link-label(`v(...)`) column modifier.

/ *`macros`*: A dictionary of (name, function) pairs that can be used
  with column modifier #link-label(`m(...)`).

  _Default:_ `(:)`

/ *`mode`*:

  - `"content"`: all table cells are evaluated as `[content blocks]`.
  - `"math"`: all table cells are evaluated as `$inline equations$`.

  _Default:_ `"content"` \
  #emph[cf. @ex-butcher.]

/ *`pad`*: This is the padding used for each cell, for use with the
  Typst `pad` element function. The `left` and `right` keys can be
  overridden using a #link-label("Number")[numeric column modifier].

  _Default:_ `(x: 0.75em, y: 3pt)` \
  #emph[cf. @ex-butcher.]

/ *`repeat-header`*: If #link-label(`breakable`) is `true` and this
  option is `true`, then the table header controlled by
  #link-label(`header-rows`) will be re-displayed on each subsequent
  page. This option is also controlled by `.TH` rows in the table data.

  _Default:_ `false`

/ *`stroke`*, \ `linesize`: How to draw all lines in the table.

  _Default:_ `1pt` \
  #emph[cf. @ex-butcher.]

/ *`tab`*: The string delimiter that separates different cells within a
  given row of the table data.

  _Default:_ `"\t"` (a #smallcaps[tab] character) \
  #emph[cf. @ex-read. Most tables in this document use `"|"` (a vertical
  bar) for readability purposes, though this should not be confused with
  #link-label(`|`)[the column classifier of the same name].]

= Format specifications <specs>
The format specifications section controls the layout and style of cells
within rows and columns of the table.

Each comma or new line of format specification begins a new _row
definition_. Within each row definition, encountering a
#link(<classes>)[_column classifier_ character] denotes a new column in
the table. The classifier may be followed by any number of
#link(<mods>)[_column modifiers_], some of which may have required
arguments enclosed in parentheses.

The total number of columns in the table is determined by the row
definition with the largest number of columns specified. Any row
definitions that have fewer columns than this maximum are assumed to
have however many #link-label(`L`) columns at the end to complete the
row.

The last row definition in the format specifications determines the
layout of that row and all rows for the rest of the table.

Spaces and tabs between any column classifiers or column modifiers are
ignored. Column classifier letters and column modifier letters can be
given as either uppercase (preferred for column classifiers) or
lowercase (preferred for column modifiers). For example:

```
L Rb
Cr n I.
```

This specifies:

- Row 1:
  - Column 1 is left-aligned (#link-label(`L`))
  - Column 2 is right-aligned (#link-label(`R`)) and bold
    (#link-label(`b`))
  - Column 3 is not specified, but will be assumed to be left-aligned
- Row 2 (*and all subsequent rows*):
  - Column 1 is centered (#link-label(`C`))
  - Column 2 is right-aligned (#link-label(`R`)[`r`])
  - Column 3 is numerically-aligned (#link-label(`N`)[`n`]) and italic
    (#link-label(`i`)[`I`])

== Column classifiers <classes>
The following column classifiers are recognized:

/ *`L`*: #strong[L]eft align.

/ *`R`*: #strong[R]ight align.

/ *`C`*: #strong[C]enter align.

/ *`N`*: #strong[N]umerically align.

  All cells with this classifier in the current column are centered with
  respect to an _alignment point_, which is determined according to the
  following rules:

  - One position after the leftmost occurrence of the
    #link-label(`\&`)[_non-printing input token_ `\&`], if any is
    present.

  - Otherwise, the rightmost occurrence of the
    #link-label(`decimalpoint`) string that immediately precedes a
    digit.

  - Otherwise, the rightmost digit.

  - Otherwise, the content is instead centered with respect to the
    column as a whole.

  The alignment point is centered horizontally with respect to the
  column as a whole.

  #emph[cf. @ex-software, @ex-food[], @ex-stack[], @ex-numeric[],
  @ex-att[], @ex-read[].]

/ *`S`*: This cell is column-spanned by the previous cell to the left in
  the current row.

  _The corresponding table data entries should be empty._ \
  #emph[cf. @ex-food, @ex-bridges[], @ex-att[], @ex-rocks[], @ex-read[].]

/ *`^`* (caret): This cell is row-spanned by the corresponding cell in
  the previous row above.

  _The corresponding table data entries should be empty._ \
  #emph[cf. @ex-spans.]

/ *`_`* (underscore), \ `-` (hyphen): This cell contains a
  vertically-centered horizontal rule.

  _The corresponding table data entries should be empty._

/ *`=`* (equals sign): Same as #link-label(`_`), but draw a double
  horizontal rule instead.

  _The corresponding table data entries should be empty._

/ *`|`* (vertical bar): This classifier does not actually begin a new
  column, but rather indicates the location of a vertical line.

  If placed at the beginning of a row definition, the line is drawn to
  the left of the first cell in that row. Otherwise, it is drawn to the
  right of the current cell in that row.

  #emph[cf. @ex-spans, @ex-software[], @ex-food[], @ex-bridges[],
  @ex-stack[].]

== Column modifiers <mods>
The following column modifiers are recognized:

/ *`b`*: #strong[B]old text using the Typst `strong` element function.

/ *`d`*: #strong[D]own --- set the vertical alignment to `bottom`.

/ *`e`*: #strong[E]qualize the width of all columns with this modifier
  to the maximum width among those columns.

  This overrides modifier #link-label(`x`).

/ *`f(...)`*: #strong[F]ont name to use is given in parentheses.

  `f(B)` is an alias for the #link-label(`b`) modifier. \
  `f(I)` is an alias for the #link-label(`i`) modifier. \
  `f(BI)` is an alias for providing both of the above modifiers.

  #emph[cf. @ex-rocks.]

/ *`i`*: #strong[I]talicize text using the Typst `emph` element
  function.

/ *`m(...)`*: #strong[M]acro (function) to apply to each corresponding
  cell. The macros must be scoped using the #link-label(`macros`) region
  option.

  The macro currently only receives a single argument: the content of
  the cell. A future version may also pass the position of the cell in
  terms of row number and column number.

/ *`o(...)`*: Fill c#strong[o]lor for the cell is given in parentheses.

  #emph[cf. @ex-grade.]

/ *`p(...)`*: #strong[P]oint size of the font is modified according to
  the argument in parentheses.

  If the argument begins with a `+` or `-`, then the argument is added
  or subtracted respectively with respect to the current size.

  The argument may be suffixed by a unit. If no unit is specified, `pt`
  is assumed. Valid units are:

  - `pt`, `p`: points.
  - `mm`: millimeters.
  - `cm`, `c`: centimeters.
  - `in`, `i`: inches.
  - `em`, `m`: `1em` corresponds to the current font size.
  - `en`, `n`: one _en_ equals half of an em.
  - `P`: six _picas_ equals one inch.
  - `M`: 100 of these equals one em.

  #emph[cf. @ex-stack, @ex-rocks[], @ex-read[].]

/ *`t`*: #strong[T]op --- set the vertical alignment to `top`.

  #emph[cf. @ex-rocks.]

/ *`u`*: "Stagger" the affected cells so that they appear *between* the
  current row and the previous one above.

  #emph[cf. @ex-stagger.]

/ *`v(...)`*: #strong[V]ertical spacing (leading) is modified according
  to the argument in parentheses.

  The length argument provided is in the same format as
  #link-label(`p(...)`), with a default unit of `pt` and `+` / `-`
  relative adjustments supported.

/ *`w(...)`*: #strong[W]idth of the column is guaranteed to be at least
  as big as the argument in parentheses, which acts as a _minimum
  width_.

  The length argument provided supports the same units as
  #link-label(`p(...)`), with a default unit of `en`. However, relative
  adjustments are *not* supported.

  This overrides modifier #link-label(`x`).

  #emph[cf. @ex-rocks, @ex-lines[].]

/ *`x`*: E#strong[x]pand the width of the column to `1fr`, which will
  consume all of the remaining horizontal space on the page or in the
  current container. Applying this modifier to multiple columns will
  divide that remaining space evenly between them.

  This overrides modifiers #link-label(`e`) and #link-label(`w(...)`).

/ *`z`*: The corresponding cell is treated as if it has #strong[z]ero
  width for the purpose of determining the width of its column.

  #emph[cf. @ex-spans.]

/ *Number*: A number given as a column modifier is interpreted as a
  #link-label(`p(...)`)[`en` length] which is used as a _column
  separation_. This is the distance that separates the end of the
  current cell's content from the beginning of the next cell's content.
  If there is a vertical line between the two cells, then it will appear
  centered on this separation distance.

  The default column separation is controlled by the sum of the `left`
  and `right` keys of the #link-label(`pad`) option. When not specified,
  this defaults to `0.75em + 0.75em`, which traditional #troff calls
  `3n`.

  #emph[cf. @ex-lines, @ex-read[].]

= Data <data>
Each input line following the terminating `.` of the
#link(<specs>)[format specifications] creates a new row of data in the
table, with each cell separated by the #link-label(`tab`) string.

If a row provides fewer entries than there are columns in the table at
that point, then the remaining columns are assumed to be empty. It is an
error to provide more entries in a row than there are columns.

== Special input lines
Some input lines do not represent table rows at all:

- A line consisting of only `_` (underscore) draws a horizontal line at
  that position in the table. This is only useful if
  #link-label(`auto-lines`) is `false`.

  #emph[cf. @ex-software, @ex-food[], @ex-bridges[], @ex-read[],
  @ex-butcher[].]

  Similarly, `=` (equals sign) in #troff would draw a double horizontal
  line, but this is not currently supported.

- A line consisting of only `.TH` (period + capital T + capital H) is an
  _end-of-header_ marker. All rows of data that precede it are
  considered part of the table's header for the purposes of the
  #link-label(`header-rows`) option. It also sets
  #link-label(`repeat-header`) to `true`. This is only useful if
  #link-label(`breakable`) is also `true` and the table spans multiple
  pages.

- A line consisting of only `.T&` (period + capital T + ampersand) in
  #troff marks the beginning of a new set of format specifications to be
  terminated by `.` and more table data to follow, but this is not
  currently supported.

- Lines that begin with `.\"` (period + backslash + double quote) are
  treated as comments and completely ignored.

- Other lines that begin with `.` (period) in #troff were used as
  _commands_ (_requests_ or _macro invocations_), but this cannot be
  supported for obvious reasons. Any such line is rejected. To have the
  first cell in a row begin with a period, use a Typst escape like `\.`
  or put a #smallcaps[space] in front of it.

== Table entries
The string representing the cell content is called the _table entry_.
Each table entry is evaluated by the Typst `eval` function. By default,
they will be evaluated as Typst markup, but you can change the
#link-label(`mode`) region option to evaluate them as equations instead.

Any leading or trailing spaces or tabs within a table entry (so long as
#link-label(`tab`) is neither) are ignored. The
#link(<examples>)[Examples] section takes advantage of this in order to
improve legibility, but note that making the input look pretty is *not*
a requirement: see @ex-align.

There are a few important caveats:

- The `eval` function does not have access to anything other than the
  Typst standard library. This means it is not currently possible to
  reference variables or functions within a table entry.

- #link-label(`N`)[Numerically-aligned cells] are split on the alignment
  point and then evaluated as two separate pieces of content. This may
  cause unexpected syntax errors if you have Typst markup that spans the
  alignment point.

- The `tab` string cannot be used *within* a table entry, except by
  using Typst hexadecimal escape sequences (provided that `tab` is not
  any of `\`, `u`, `{`, `}`, a letter, or a digit).

- Any occurrences of the string `\&` #label(`\&`.text)
  (backslash-ampersand; known as the _non-printing input token_) in the
  table entry are removed.

#pagebreak(weak: true)
== Special table entries
If a table entry consists of any of the following strings alone
(ignoring any spaces or tabs), then they gain a special meaning:

  - *`_`* (a single underscore): Draw a horizontal line through the
    middle of this otherwise empty cell. The line touches any adjacent
    vertical lines that are present.

    #emph[cf. @ex-bridges, @ex-stack[], @ex-lines[].]

  - *`\_`* (backslash + underscore): Like `_` above, but the line does
    *not* touch any adjacent vertical lines, subject to the current
    #link-label("Number")[column separation].

    #emph[cf. @ex-lines.]

  - *`=`* (equals sign): Like `_` above, but draw a double horizontal
    line.

    #emph[cf. @ex-lines.]

  - *`\=`* (backslash + equals sign): Like `=` above, but subject to
    column separation like `\_` above.

  - *`\^`* (backslash + caret): This cell is row-spanned by the
    corresponding cell in the previous row above. This is similar to the
    #link-label(`^`) column classifier, but can be used at an arbitrary
    point in the table.

    #emph[cf. @ex-food.]

== Text blocks
A table entry can also span multiple input lines by writing it as a
_text block._ #label("text block") This consists of beginning the entry
with `T{` (capital T \+ open brace), followed immediately by the end of
that input line.  All following input lines are collected as part of the
text block until a input line that begins with `T}` (capital T \+ close
brace) is encountered. The rest of that input line can provide the
remaining entries for that row of the table.

// modifiers on spanned columns??
If the cell is subject to the #link-label(`w(...)`) column modifier,
then the text block is constrained to the specified width.

Otherwise, a constraining width $W$ is calculated according to the
following formula:

$ W = L times C / (N - 1) $

where $L$ is the maximum width of the table based on the container it is
in, or the width of the page minus the margins if there is no container;
$C$ is the number of columns this text block spans horizontally; and $N$
is the total number of columns in the table.

#emph[cf. @ex-rocks, @ex-lines[].]

#pagebreak(weak: true)
= Differences from traditional `tbl` <diff>

- #link(<options>)[Region options] must be specified using a
  "show-everything" rule; they cannot be provided within the `raw` block
  itself.

- The `nospaces` option is always in effect and cannot be disabled.

- The `nowarn` option is not supported. Typst currently does not support
  displaying text to standard output or error, except by the use of the
  `assert` and `panic` functions. As such, `tbl.typ` will halt
  compilation if any issue is detected.

- The #link-label(`stroke`)[`linesize`] option is expected to be a Typst
  color, length, or stroke; a dimensionless number does not work.

- The #link-label(`tab`) option may be a multi-character string.

- The alignment point of #link-label(`N`)[numerically-centered cells]
  that are in the same column as #link-label(`L`)[left-centered] or
  #link-label(`R`)[right-centered] cells is always centered with respect
  to the column as a whole (as if the classifier was #link-label(`C`)),
  rather than with respect to the widest #link-label(`L`) or
  #link-label(`R`) entry.

- All #link(<mods>)[column modifiers] that expect an argument must
  provide that argument in parentheses.

- The #link-label(`o(...)`) column modifier is a `tbl.typ` extension.

- Nothing special needs to be done to use equations within table
  entries, though #link-label(`N`)[numerically-aligned columns] may
  behave unexpectedly until the `delim` option is implemented.

- An empty entry in the table data must be given even if the cell is
  spanned or contains a horizontal line.

- `\Rx` table entries are not handled. Use the Typst `repeat` element
  function instead, though this does not work well at the moment without
  a fully-functioning #link-label(`w(...)`) column modifier (see
  #link(<issues>)[Known issues]).

#pagebreak(weak: true)
= Known issues <issues>

- The following #link(<options>)[region options] are not currently
  supported:

  - `delim` (#issue(1))
  - `expand` (#issue(2))

- The following #link(<classes>)[column classifiers] are not currently
  supported:

  - `A` (#strong[a]lphabetic)

  - `||` (double vertical line)

- The #link-label(`x`) (e#strong[x]pand) column modifier does not
  currently constrain the width of text blocks like it should.
  (#issue(7))

- `.T&` in the #link(<data>)[table data] is not currently supported.
  (#issue(4))

- Within text blocks, `.\"` comments are not removed, and other #troff
  commands are not rejected. (#issue(6))

- A table data row consisting of only `=` (double horizontal line) is
  not currently supported.

#pagebreak(weak: true)
= Examples <examples>

#let template = (..args, it) => {
  block(breakable: false)[
    *The following examples are formatted with these region options:*

    #raw(
      block: true,
      lang: none,
      "#show: tbl.template.with" + repr(args)
    )
  ]
  tbl.template(
    font: font,
    center: true,
    ..args,
    it,
  )
}

#show: template.with(
  box: true,
  tab: "|",
)

#example(
  caption: [adapted from @tbl.7],
  ```tbl-example
  Lz     S   | Rt
  Lt  |  Cb  | ^
  ^   |  Rz    S.
  left|      | r
  l   |center|
      |     right
  ```
) <ex-spans>

#example(
  caption: [adapted from @Cherry[p. 41]],
  ```tbl-example-wide
          C                C                   C
          L                L                   N.
  Fact            |Location            |Statistic
  Largest state   |Alaska              |591,004 sq. mi.
  Smallest state  |Rhode Island        |1,212 sq. mi.
  Longest river   |Mississippi-Missouri|3,710 mi.
  Highest mountain|Mount McKinley, AK  |20,320 ft.
  Lowest point    |Death Valley, CA    |-- 282 ft.
  ```
) <ex-facts>

#example(
  caption: [adapted from @tbl.7],
  ```tbl-example
        R | L
        R   N.
  software|version
  _
       AFL|2.39b
      Mutt|1.8.0
      Ruby|1.8.7.374
  TeX Live|2015
  ```
) <ex-software>

#example(
  caption: [adapted from @Cherry[p. 43]],
  ```tbl-example
  Cf(Courier New)  S       S   S
  C              | C       S   S
  C              | C       S   S
  C              | C     | C | C
  C              | C     | C | C
  L              | N     | N | N.
  Composition of Foods
  _
  Food           |Percent by Weight
  \^             |_
  \^             |Protein|Fat|Carbo-
  \^             |\^     |\^ |hydrate
  _
  Apples         |  .4   | .5|13.0
  Halibut        |18.4   |5.2|...
  Lima beans     | 7.5   | .8|22.0
  Milk           | 3.3   |4.0| 5.0
  Mushrooms      | 3.5   | .4| 6.0
  Rye bread      | 9.0   | .6|52.7
  ```
) <ex-food>

#example(
  caption: [adapted from @Cherry[p. 42]],
  ```tbl-example
  C                  S                S
  C                | C              | C
  L                | L              | N.
  Major New York Bridges
  _
  Bridge           |Designer        |Length
  _
  Brooklyn         |J . A . Roebling|1595
  Manhattan        |G . Lindenthal  |1470
  Williamsburg     |L . L . Buck    |1600
  _
  Queensborough    |Palmer &        |1182
                   |Hornbostel
  _
                   |                |1380
  Triborough       |O . H . Ammann  |_
                   |                |383
  _
  Bronx Whitestone |O . H . Ammann  |2300
  Throgs Neck      |O . H . Ammann  |1800
  _
  George Washington|O . H . Ammann  |3500
  ```
) <ex-bridges>

#pagebreak(weak: true)
#show: template.with(
  tab: "|",
)

#example(
  caption: [adapted from @tbl.7],
  ```tbl-example
  rBclB, rcIl.
  r|center|l
  ri|ce|le
  right|c|left
  ```
) <ex-align>

#example(
  caption: [adapted from @tbl.1],
  ```tbl-example
  Cf(BI) Cf(BI)            Cf(B)
  C      C                 Cu.
  n     |n*_#sym.times;_*n|difference
  1     |1
  2     |4                |3
  3     |9                |5
  4     |16               |7
  5     |25               |9
  6     |36               |11
  ```
) <ex-stagger>

#example(
  caption: [adapted from @Cherry[p. 42]],
  ```tbl-example
  C         C
  N p(-2) | N   |.
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
) <ex-stack>

#example(
  caption: [adapted from @Cherry[p. 37]],
  ```tbl-example
  N.
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
) <ex-numeric>

#show: template.with(
  allbox: true,
  tab: "|",
)

#example(
  caption: [adapted from @Cherry[p. 41]],
  ```tbl-example
  C    S      S
  C    C      C
  N    N      N.
  AT&T Common Stock
  Year|Price |Dividend
  1984|15-20 |\$1.20
     5|19-25 |1.20
     6|21-28 |1.20
     7|20-36 |1.20
     8|24-30 |1.20
     9|29-37 |.30\*
  ```
) <ex-att>

#example(
  ```tbl-example
  C b o(luma(85%))
  C   o(luma(95%)) C.
  Grade           |Points
  A               |$ >= 510$
  B               |$ >= 450$
  C               |$ >= 390$
  D               |$ >= 330$
  ```
) <ex-grade>

#example(
  caption: [adapted from @Cherry[p. 44]],
  ```tbl-example
  Cf(I)       S               S
  C           Cw(1in)         Cw(1in)
  Ltp(9)      Ltp(9)          Ltp(9).
  New York Area Rocks
  Era        |Formation      |Age (years)
  Precambrian|Reading Prong  |>1 billion
  Paleozoic  |Manhattan Prong|400 million
  Mesozoic   |T{
    #set text(hyphenate: true, overhang: true)
    
    Newark Basin, incl.
    Stockton, Lockatong, and Brunswick
    formations; also Watchungs
    and Palisades.
  T}                         |200 million
  Cenozoic   |Coastal Plain  |T{
    #set text(hyphenate: true, overhang: true)
    #set par(justify: true)
    
    On Long Island 30,000 years;
    Cretaceous sediments redeposited
    by recent glaciation.
  T}
  ```
) <ex-rocks>

#example(
  caption: [adapted from @tbl.7],
  ```tbl-example-wide
  Le                Le7 Lw(10).
  The fourth line  |_  |line 1
  of this column   |=  |line 2
  determines       |\_ |line 3
  the column width.|T{
    This text is too wide to fit into a column of width 17.
  T}                   |line 4
  T{
    No break here.
  T}               |   |line 5
  ```
) <ex-lines>

#pagebreak(weak: true)
#show: template.with(
  doublebox: true,
  tab: " : ",
)

#example(
  caption: [adapted from @Cherry[p. 45]],
  ```tbl-example
  C b       S       S         S         S
  C p(-2)   S       S         S         S
  C       | C     | C       | C       | C
  C       | C     | C       | C       | C
  R 2     | N 2   | N 2     | N 2     | N b.
  Readability of Text
  Line Width and Leading for 10-Point Type
  _
  Line    : Set   : 1-Point : 2-Point : 4-Point
  Width   : Solid : Leading : Leading : Leading
  _
  9 Pica  : 93    : --6.0   : --5.3   : --7.1
  14 Pica : 450   : --0.6   : --0.3   : --1.7
  19 Pica : 5     : --5.1   : 0.0     : --2.0
  31 Pica : 3     : --3.8   : --2.4   : --3.6
  43 Pica : 5.1   : --90.00 : --5.9   : --8.8
  ```
) <ex-read>

#show: template.with(
  tab: "|",
  pad: (bottom: 4pt),
  mode: "math",
  stroke: 0.1pt,
)

#example(
  caption: [adapted from
  #link("https://discord.com/channels/1054443721975922748/1088371919725793360/1110118908616249435")[Discord]],
  ```tbl-example
  c      | c         c         c           c.
  c_1    | a_(11)  | a_(12)  | dots.h    | a_(1 s)
  c_2    | a_(21)  | a_(22)  | dots.h    | a_(2 s)
  dots.v | dots.v  | dots.v  | dots.down | dots.v
  c_s    | a_(s 1) | a_(s 2) | dots.h    | a_(s s)
  _
         | b_1     | b_2     | dots.h    | b_s
  ```
) <ex-butcher>

#pagebreak(weak: true)
= References
#bibliography(
  "README.yml",
  title: none,
  style: "ieee",
)
