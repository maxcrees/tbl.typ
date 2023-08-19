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
  "https://github.com/maxcrees/tbl.typ/issues/" + str(num),
  [GH-#num],
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

#let example(path, caption: none, wide: false) = {
  figure(
    kind: "example",
    supplement: "Example",
    caption: caption,
    raw(
      block: true,
      lang:
        if wide { "tbl-example-wide" }
        else { "tbl-example" },
      read(path).trim("\n")
    ),
  )
}
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
    #link("https://maxre.es/tbl.typ/")[maxre.es/tbl.typ] \
    Version 0.0.4 \
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

= Usage <usage>
+ Make sure you are using Typst version 0.6.0.
+ Add the following code to the top of your `.typ` file:

  ```
  #import "@preview/tbl:0.0.4"
  #show: tbl.template
  ```

The basic format of a table when using `tbl.typ` is the following:

````
```tbl
Format specifications .
Data
```
````

The two main components of this syntax are:

- #link(<specs>)[_Format specifications_]. This describes the layout of
  the table in terms of the number and style of columns for each row.
  They can be changed later using the #link-label(`.T&`) command.

  The last line of the format specifications must end in a period (`.`).
  This is the separator between the two sections.

- #link(<data>)[_Data_]. This is the content that will fill each cell of
  the table. Generally every input line in this section corresponds to a
  row in the table, though there are exceptions noted later. Cells are
  separated by the #link-label(`tab`) option which defaults to a
  #smallcaps[tab] character.

#pagebreak(weak: true)
= Region options <options>
In addition to the overall #link(<usage>)[table syntax] itself, you may
specify _region options_ that control the parsing and styling of the
table as a whole using a "show-everything" rule prior to the tables you
would like to control. For example:

```
#show: tbl.template.with(
  allbox: true,
  tab: "|",
)
```

You must provide at least one of these rules somewhere in your document
before your first table (even if no options are specified); otherwise
the table(s) will not be rendered.

The following options are recognized:

/ *`align`*: How to align the table as a whole.

  _Default:_ `left`

/ *`auto-lines`*, \ `allbox`: Like #link-label(`box`), but also draw a
  line between every cell if `true`. This is the same option from
  `tablex`.

  _Default:_ `false` \
  #emph[cf. @ex-att, @ex-rocks[], @ex-lines[], @ex-grade[].]

/ *`bg`*: The background color for the table cells. Can be overridden
  later by the #link-label(`k(...)`) column modifier.

  _Default:_ `auto` (transparent)

/ *`box`*, \ `frame`: If `true`, draw a line around the entire table.

  _Default:_ `false` \
  #emph[cf. @ex-spans, @ex-facts[], @ex-software[], @ex-food[],
  @ex-bridges[].]

/ *`breakable`*, \ `nokeep`: If `true`, the table can span multiple
  pages if necessary.

  _Default:_ `false`

/ *`center`*, \ `centre`: Aliases for a #link-label(`align`) value of
  `center`.

/ *`colors`*: An array of colors for shorthand use with the
  #link-label(`k(...)`) column modifier.

  _Default:_ `()` \
  #emph[cf. @ex-grade.]

/ *`decimalpoint`*: The string used to separate the integral part of a
  number from the fractional part. Used in #link-label(`N`)-classified
  columns.

  _Default:_ `"."`

/ *`doublebox`*, \ `doubleframe`: Like #link-label(`box`), but also draw
  a second line around the entire table if `true`.

  _Default:_ `false` \
  #emph[cf. @ex-read.]

/ *`fg`*: The foreground (text) color for the table cells. Can be
  overridden later by the #link-label(`o(...)`) column modifier.

  _Default:_ `auto` (the text color is the same as the surrounding text)

/ *`font`*: The font family for the table. Can be overridden later by
  the #link-label(`f(...)`) column modifier.

  _Default:_ `"Times"` \
  _n.b. all tables in this document are formatted with the #font font._

/ *`header-rows`*: The number of rows at the beginning of the table to
  consider part of the "header" for the purposes of
  #link-label(`repeat-header`). This option is also controlled by
  #link-label(`.TH`) rows in the table data.

  _Default:_ `1`

/ *`leading`*: The vertical spacing / leading to apply to table cells.
  Can be overridden later by the #link-label(`v(...)`) column modifier.

/ *`mode`*:

  - `"markup"`: all table cells are evaluated as `[content blocks]`.
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

/ *`scope`*: A dictionary of (name, definition) pairs that can be used
  with column modifiers #link-label(`k(...)`), #link-label(`m(...)`),
  #link-label(`o(...)`), and within table data entries.

  _Default:_ `(:)`

/ *`size`*: The font size for the table. Can be overridden later by the
  #link-label(`p(...)`) column modifier.

  _Default:_ `1em`

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
definition with the largest number of columns specified.
<inferred-columns> Any row definitions that have fewer columns than this
maximum are assumed to have however many #link-label(`L`) columns at the
end to complete the row.

The last row definition in the format specifications determines the
layout of that row and all subsequent rows until the next
#link-label(`.T&`) command or the end of the table if there is none.

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

/ *`N`*: #strong[N]umerically align: all cells with this classifier in
  the current column are centered with respect to an _alignment point_,
  which is determined according to the following rules:

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
  @ex-alpha[], @ex-att[], @ex-read[].]

/ *`A`*: #strong[A]lphabetically align: in the current column the widest
  cell with this classifier is centered and the rest with this
  classifier are left-aligned with respect to that widest cell. These
  are sometimes called _subcolumns_ because they appear to be indented
  relative to `L`-classified cells.

  #emph[cf. @ex-alpha.]

/ *`S`*: This cell is column-spanned by the previous cell to the left in
  the current row.

  _The corresponding table data entries should be empty or elided._ \
  #emph[cf. @ex-food, @ex-bridges[], @ex-att[], @ex-rocks[], @ex-read[].]

/ *`^`* (caret): This cell is row-spanned by the corresponding cell in
  the previous row above.

  _The corresponding table data entries should be empty or elided._ \
  #emph[cf. @ex-spans.]

/ *`_`* (underscore), \ `-` (hyphen): This cell contains a
  vertically-centered horizontal rule.

  _The corresponding table data entries should be empty or elided._

/ *`=`* (equals sign): Same as #link-label(`_`), but draw a double
  horizontal rule instead.

  _The corresponding table data entries should be empty or elided._

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

/ *`k(...)`*: Bac#strong[k]ground for the cell is given in parentheses,
  evaluated as Typst code (with a scope determined by the
  #link-label(`scope`) region option). The argument can also be an
  integer representing an index into the #link-label(`colors`) region
  option. In any case, the default color is controlled by the
  #link-label(`bg`) region option.

  #emph[cf. @ex-grade.]

/ *`m(...)`*: #strong[M]acro (function) to apply to each corresponding
  cell. The macros must be scoped using the #link-label(`scope`) region
  option.

  The macro currently only receives a single argument: the content of
  the cell. A future version may also pass the position of the cell in
  terms of row number and column number.

/ *`o(...)`*: F#strong[o]reground color for the cell is given in
  parentheses, evaluated as Typst code (with a scope determined by the
  #link-label(`scope`) region option). The argument can also be an
  integer representing an index into the #link-label(`colors`) region
  option.  In any case, the default color is controlled by the
  #link-label(`fg`) region option.

  #emph[cf. @ex-grade.]

/ *`p(...)`*: #strong[P]oint size of the font is modified according to
  the argument in parentheses.

  If the argument begins with a `+` or `-`, then the argument is added
  or subtracted with respect to the current font size for the column,
  which is initialized with the #link-label(`size`) region option.

  The argument may be suffixed by a unit. If no unit is specified, `pt`
  is assumed. Valid units are:

  #grid(columns: (1fr, 1fr))[
    - `pt`, `p`: points.
    - `mm`: millimeters.
    - `cm`, `c`: centimeters.
    - `in`, `i`: inches.
  ][
    - `em`, `m`: `1em` corresponds to the current font size.
    - `en`, `n`: one _en_ equals half of an em.
    - `P`: six _picas_ equals one inch.
    - `M`: 100 of these equals one em.
  ]

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

== Special input lines <special-line>
Some input lines do not represent table rows at all. Leading and
trailing whitespace will prevent the special interpretation of these
input lines.

- A line consisting of only `_` (underscore) draws a horizontal line at
  that position in the table. This is only useful if
  #link-label(`auto-lines`) is `false`.

  #emph[cf. @ex-software, @ex-food[], @ex-bridges[], @ex-read[],
  @ex-butcher[].]

  Similarly, `=` (equals sign) in #troff would draw a double horizontal
  line, but this is not currently supported.

- A line consisting of only `.TH` #label(`.TH`.text) (period +
  capital T + capital H) is an _end-of-header_ marker. All rows of data
  that precede it are considered part of the table's header for the
  purposes of the #link-label(`header-rows`) option. It also sets
  #link-label(`repeat-header`) to `true`. This is only useful if
  #link-label(`breakable`) is also `true` and the table spans multiple
  pages.

- A line consisting of only `.T&` #label(`.T&`.text) (period + capital T
  \+ ampersand) begins a new section of #link(<specs>)[format
  specifications] that is terminated by a trailing period.

  The last row definition in the new format specifications determines
  the layout of that row and all subsequent rows until the next `.T&` or
  the end of the table.

  #emph[cf. @ex-alpha.]

- Lines that begin with `.\"` (period + backslash + double quote) are
  treated as comments and completely ignored.

- Other lines that begin with `.` (period) in #troff were used as
  _commands_ (_requests_ or _macro invocations_), but this cannot be
  supported for obvious reasons. Any such line is rejected. To have the
  first cell in a row begin with a period, use a Typst escape (e.g.
  `\.`).

- Lines that end with `\` <line-continue> (backslash) indicate that the
  table entry for the current cell continues on the next input line.

  #emph[cf. @ex-facts.]

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

  - *`\Rx`* #label(`\Rx`.text) (backslash + capital R + any character
    `x`): the single character `x` is repeated enough to fill the cell
    but does *not* touch any adjacent vertical lines, subject to the
    current column separation.

    #emph[cf. @ex-lines.]

== Text blocks
A table entry can also span multiple input lines by writing it as a
_text block._ #label("text block") This consists of beginning the entry
with `T{` (capital T \+ open brace), followed immediately by the end of
that input line.  All following input lines are collected as part of the
text block until a input line that begins with `T}` (capital T \+ close
brace) is encountered. The rest of that input line can provide the
remaining entries for that row of the table.

// modifiers on spanned columns??
If the cell is subject to the #link-label(`w(...)`) or
#link-label(`x`) column modifiers, then the text block is constrained
to the specified width.

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

- The following features are unique to `tbl.typ`:
  - *#link(<options>)[Region options]:* #link-label(`align`),
    #link-label(`bg`), #link-label(`colors`), #link-label(`fg`),
    #link-label(`font`), #link-label(`header-rows`),
    #link-label(`leading`), #link-label(`mode`),
    #link-label(`pad`), #link-label(`scope`), #link-label(`size`),
    #link-label(`repeat-header`)
  - *#link(<mods>)[Column modifiers]:* #link-label(`k(...)`),
    #link-label(`o(...)`)

- Region options must be specified using a "show-everything" rule; they
  cannot be provided within the `raw` block itself.

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

- All column modifiers that expect an argument must provide that
  argument in parentheses.

- The #link-label(`d`) and #link-label(`t`) column modifiers adjust the
  vertical alignment for all table cells, not just those that are
  vertically spanned. As a result, the default is more consistently
  middle alignment (or `horizon` in Typst parlance).

- Nothing special needs to be done to use equations within table
  entries, though #link-label(`N`)[numerically-aligned columns] may
  behave unexpectedly until the `delim` option is implemented.

- The #link-label(`.T&`) command may increase the total number of
  columns in the table arbitrarily. The parts of the table that did
  not specify these new columns will have the columns added as empty
  left-aligned cells on the right-hand side of the table. This ensures
  that the shape of the overall table is always rectangular and is
  consistent with #link(<inferred-columns>)[inferred column
  specifications] within a given set of format specifications.

#pagebreak(weak: true)
= Known issues <issues>

- The following #link(<options>)[region options] are not currently
  supported:

  - `delim` (#issue(1))
  - `expand` (#issue(2))

- The following #link(<classes>)[column classifiers] are not currently
  supported:

  - `||` (double vertical line)

- The #link-label(`e`) (#strong[e]qualize) column modifier does not
  currently constrain the width of text blocks like it should.
  (#issue(7))

- Within text blocks, `.\"` comments are not removed, and other #troff
  commands are not rejected. (#issue(6))

- A table data row consisting of only `=` (double horizontal line) is
  not currently supported.

= Version history
- *Version 0.0.4:* Saturday 19 August 2023
  - _Breaking changes_
    - The `"content"` value for the #link-label(`mode`) region option
      has been renamed to `"markup"` to align with the `eval` element
      function in Typst 0.7.0. The former is now an undocumented alias
      for the latter which *will be removed in the next release*.
    - The `macros` region option has been renamed to
      #link-label(`scope`) to reflect the expansion in its use. The
      former is now an undocumented alias for the latter which *will be
      removed in the next release*.
  - _Bugs fixed_
    - A division-by-zero crash is now fixed.
    - The #link-label(`x`) column modifier now overrides the width
      calculation for text blocks. (#issue(7))
  - _Improvements_
    - As mentioned above, it is now possible to scope arbitrary Typst
      objects for use within table data entries using the
      #link-label(`scope`) region option (#issue(9)).
    - For cells that are spanned or contain horizontal lines, an empty
      table data entry is no longer required (but may still be
      provided).
    - The dependency on `tablex` has been updated to 0.0.5.

#pagebreak(weak: true)
- *Version 0.0.3:* Saturday 29 July 2023
  - _Breaking changes_
    - The #link-label(`o(...)`) column modifier is now the cell
      f#strong[o]reground color. Use #link-label(`k(...)`) to change the
      bac#strong[k]ground color.
    - The `tbl-align` alias for the #link-label(`align`) region option,
      deprecated since version 0.0.2, has been removed.
  - _New features_
    - The #link-label(`.T&`) command is now supported which allows
      changing the table format specifications in the middle of the
      table data. (#issue(4))
    - New region options: #link-label(`bg`), #link-label(`colors`),
      #link-label(`fg`), and #link-label(`size`).
  - _Bugs fixed_
    - Test cases that fail to compile or are missing now cause `make` to
      return with a non-zero exit status.
    - The test suite now operates correctly with Typst 0.6.0.
  - _Improvements_
    - `tbl.typ` has been submitted to the Typst package repository.
    - `tablex` is now imported as a Typst 0.6.0 package.
  - _Documentation_
    - The behavior of whitespace with respect to
      #link(<special-line>)[special input lines] has been clarified.

- *Version 0.0.2:* Saturday 10 June 2023
  - _Breaking changes_
    - Region option `tbl-align` has been renamed to
      #link-label(`align`). The former is now an undocumented
      alias for the latter. *This alias will be removed in the next
      release*.
    - `tablex.typ` is now pulled from `TYPST_ROOT` rather than
      relative to the current working directory.
  - _New features_
    - New region option: #link-label(`mode`).
    - New column classifier: #link-label(`A`).
    - New special table entry: #link-label(`\Rx`).
    - #link(<line-continue>)[Line continuations] in the table data are
      now supported.
  - _Bugs fixed_
    - Fix order of operations for column width measurement, especially
      for class #link-label(`N`) columns. It is no longer
      necessary to include spurious #link-label(`e`) modifiers.
    - #link-label(`w(...)`) column modifier now places a definitive
      lower bound on the width of the column. (#issue(5))
    - #link-label(`pad`) region option now accepts underspecified input.
      (#issue(3))
    - Fix width of horizontally-spanned cells.
  - _Improvements_
    - Clarify error message for malformed text block close.
    - Clean up and refactor implementation.
    - Add test suite based on existing examples from `README`.
  - _Documentation_
    - Fix `README` compilation with Typst version 0.4.0.
    - Align columns in code for example tables to improve legibility.
    - Annotate a short example table format specification.
    - Document behavior when fewer table entries are provided than
      expected columns for a particular row.
    - Fix width of renderings for example tables.
    - Clarify lack of `nospaces` and `nowarn` region options.
    - Expand usage instructions.
    - Document more differences and extensions.

- *Version 0.0.1:* Friday 19 May 2023
  - _Initial release_

#pagebreak(weak: true)
= Examples <examples>

#let template = (path, it) => {
  import path: options

  block(breakable: false)[
    *The following examples are formatted with these region options:*

    #raw(
      block: true,
      lang: none,
      "#show: tbl.template.with" + repr(options)
    )
  ]
  tbl.template(
    font: font,
    align: center,
    ..options,
    it,
  )
}

#show: template.with("test/00/options.typ")

#example(
  "test/00/00_spans.tbl",
  caption: [adapted from @tbl.7],
) <ex-spans>

#example(
  "test/00/01_facts.tbl",
  caption: [adapted from @Cherry[p. 41]],
) <ex-facts>

#example(
  "test/00/02_software.tbl",
  caption: [adapted from @tbl.7],
) <ex-software>

#example(
  "test/00/03_food.tbl",
  caption: [adapted from @Cherry[p. 43]],
) <ex-food>

#example(
  "test/00/04_bridges.tbl",
  caption: [adapted from @Cherry[p. 42]],
) <ex-bridges>

#pagebreak(weak: true)
#show: template.with("test/01/options.typ")

#example(
  "test/01/00_align.tbl",
  caption: [adapted from @tbl.7],
) <ex-align>

#example(
  "test/01/01_stagger.tbl",
  caption: [adapted from @tbl.1],
) <ex-stagger>

#example(
  "test/01/02_stack.tbl",
  caption: [adapted from @Cherry[p. 42]],
) <ex-stack>

#example(
  "test/01/03_numeric.tbl",
  caption: [adapted from @Cherry[p. 37]],
) <ex-numeric>

#example(
  "test/01/04_alpha.tbl",
  caption: [adapted from @tbl.1],
) <ex-alpha>

#show: template.with("test/02/options.typ")

#example(
  "test/02/00_att.tbl",
  caption: [adapted from @Cherry[p. 41]],
) <ex-att>

#example(
  "test/02/02_rocks.tbl",
  caption: [adapted from @Cherry[p. 44]],
) <ex-rocks>

#example(
  "test/02/03_lines.tbl",
  wide: true,
  caption: [adapted from @tbl.7],
) <ex-lines>

#pagebreak(weak: true)
#show: template.with("test/05/options.typ")

#example(
  "test/05/00_grade.tbl",
) <ex-grade>

#show: template.with("test/03/options.typ")

#example(
  "test/03/00_read.tbl",
  caption: [adapted from @Cherry[p. 45]],
) <ex-read>

#pagebreak(weak: true)
#show: template.with("test/04/options.typ")

#example(
  "test/04/00_butcher.tbl",
  caption: [adapted from
  #link("https://discord.com/channels/1054443721975922748/1088371919725793360/1110118908616249435")[Discord]],
) <ex-butcher>

#pagebreak(weak: true)
= References
#bibliography(
  "README.yml",
  title: none,
  style: "ieee",
)
