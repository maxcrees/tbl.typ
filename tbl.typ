// SPDX-License-Identifier: MPL-2.0
// vi: ft=typst et ts=2 sts=2 sw=2 tw=72
//
// Copyright Contributors to the "tbl.typ" project.
// This Source Code Form is subject to the terms of the
// Mozilla Public License, v. 2.0. If a copy of the MPL was
// not distributed with this file, You can obtain one at
// http://mozilla.org/MPL/2.0/.
#import "tablex.typ"

#let special-entries = (
  "_",
  "=",
  "\\_",
  "\\=",
  "\\^",
)

#let units = (
  // Typst units and aliases
  "pt": ("p",),
  "mm": (),
  "cm": ("c",),
  "in": ("i",),
  "em": ("m",),

  // troff-only units
  "en": ("n",),
  "P": (),
  "M": (),
)

#let width-default = (min: 0pt, max: 0pt, num-l: 0pt, num-r: 0pt)

#let options-default = (
  // troff tbl
  box: false,
  decimalpoint: ".",
  doublebox: false,
  font: "Times",
  tab: "\t",

  // tbl.typ
  breakable: false,
  leading: 0.65em,
  macros: (:),
  pad: (
    left: 0.75em,
    right: 0.75em,
    top: 3pt,
    bottom: 3pt,
  ),
  tbl-align: left,

  // tablex.typ
  auto-lines: false,
  header-rows: 1,
  repeat-header: false,
  stroke: 1pt,
)

#let options-alias = (
  allbox: "auto-lines",
  center: (tbl-align: center),
  centre: (tbl-align: center),
  doubleframe: "doublebox",
  frame: "box",
  linesize: "stroke",
  nokeep: "breakable",
)

// "Column descriptors"
#let spec-default(options) = {(
  class: "L",

  bold: false,
  fill: auto,
  font: options.font,
  halign: left,
  ignore: false,
  italic: false,
  leading: options.leading,
  macro: none,
  pad: options.pad,
  size: 1em,
  stagger: false,
  valign: horizon,
)}

#let assert-ctx(cond, message, row: none, col: none) = {
  assert(
    cond,
    message: {
      let ctx = ""
      if row != none {
        ctx += "R" + str(row + 1)
      }
      if col != none {
        ctx += "C" + str(col + 1)
      }
      if ctx != "" {
        ctx = "[tbl " + ctx + "] "
      } else {
        ctx = "[tbl] "
      }

      ctx + message
    },
  )
}

#let coerce-unit(len, default, relative: none) = {
  let given-unit = none

  if relative != none {
    if not (len.starts-with("+") or len.starts-with("-")) {
      relative = none
    }
  }

  for (primary-unit, aliases) in units.pairs() {
    for unit in (primary-unit, ..aliases) {
      if len.ends-with(unit) {
        given-unit = primary-unit
        len = len.trim(unit, at: end, repeat: false)
        break
      }
    }
    if given-unit != none {
      break
    }
  }
  if given-unit == none {
    given-unit = default
  }
  len = float(eval(len))

  if given-unit == "en" {
    given-unit = "em"
    len /= 2
  } else if given-unit == "P" {
    given-unit = "in"
    len /= 6
  } else if given-unit == "M" {
    given-unit = "em"
    len /= 100
  }
  given-unit = eval("1" + given-unit)

  if relative != none {
    relative + len * given-unit
  } else {
    len * given-unit
  }
}

// Convert any mix of em / other (absolute) lengths to pt.
// https://github.com/typst/typst/issues/1231
#let pt-length(len, styles) = {
  measure(line(length: len), styles).width
}

#let regex-raw(..patterns) = {
  regex({for pattern in patterns.pos() {
      pattern.text
  }})
}

#let tbl-cell(spec, it) = {
  if type(it) == "function" {
    tbl-cell(spec, style(styles => it(styles)))

  } else {
    set text(
      baseline:
        if spec.stagger { -1em }
        else { 0em },
      font: spec.font,
      size: spec.size,
      number-width:
        if spec.class == "N" { "tabular" }
        else { auto },
    )
    set par(leading: spec.leading)

    if spec.macro != none {
      it = (spec.macro)(it)
    }
    if spec.bold {
      it = strong(it)
    }
    if spec.italic {
      it = emph(it)
    }

    it
  }
}

#let template(body, ..options-given) = {
  show raw.where(lang: "tbl"): it => layout(size => {
    let raw-text = it.text.replace("\r", "")

    // A single period separates the "table data" from the "table format
    // specifications".
    let period = raw-text.position(regex-raw(`[.][ \t]*\n`))
    assert-ctx(
      period != none,
      "Missing table format specification: expected '.'",
    )

    ////////////////////// TABLE OPTION PARSING //////////////////////
    let options = options-given.named()
    for (name, value) in options-default.pairs() {
      if name not in options {
        options.insert(name, value)
      }
    }
    for (name, value) in options.pairs() {
      if name in options-alias {
        let mapping = options-alias.at(name)
        if type(mapping) == "dictionary" {
          options += mapping
          let _ = options.remove(name)
        } else if type(mapping) == "string" {
          options.insert(mapping, value)
          let _ = options.remove(name)
        } else {
          panic("Invalid options-alias type", type(mapping))
        }
      } else if name not in options-default {
        panic("Unknown region option '" + name + "'")
      }
    }
    if options.doublebox { options.box = true }

    // "Table format specifications"
    let specstring = raw-text.slice(0, period).trim()
    // Array of rows, each containing dictionaries ("column class" and
    // "column modifiers")
    let specs = ()

    // "Table data"
    let datastring = raw-text.slice(period + 1).trim(" ").trim("\n")
    // Array of rows, each containing an array of content cells
    let rows = ()

    // Named parameter "columns:" for tablex. Mostly used to track how
    // many columns are in the table, and which have modifier "e"
    // ("equalize") or "x" (1fr). The rest are auto, but will be
    // replaced by real lengths before tablex is called; see
    // "final-widths" below.
    let cols = ()

    // Manually specified vertical and horizontal lines. These are
    // arrays of tablex.vlinex and tablex.hlinex. The latter also keeps
    // track of how many lines of input in the datastring have been
    // ignored so that we can still properly map each table row into the
    // correct entry in "specs" above.
    let vlines = ()
    let hlines = ()

    // Largest width of any cell in any column that has been modified "e".
    let equalize-width = state("tbl-equalize-width")
    equalize-width.update(0pt)
    // Dictionary of column # -> dictionary:
    //   min:   as specified by modifier "w", EXCLUDING padding
    //   max:   maximum from all cells in this column, INCLUDING padding
    //   num-l: maximum from all left halves of class "N" cells in this
    //          column, EXCLUDING padding
    //   num-r: same as above, but right halves
    let final-widths = state("tbl-final-widths")
    final-widths.update((:))
    // Maximum possible width of the current table, based on the
    // container we're in - or the width of the page minus the margins
    // if there is no container.
    let tbl-max-width = size.width

    ////////////////// TABLE FORMAT / LAYOUT PARSING //////////////////
    // Strip out any column modifier arguments first, since they may
    // contain spaces, tabs, commas, or any of the classifier
    // characters.
    let args = (:)
    let arg = specstring.match(regex-raw(`(?s)[ \t]*\((.*?)\)`))
    while arg != none {
      let modifier = lower(specstring.slice(arg.start - 1, count: 1))
      if modifier not in args {
        args.insert(modifier, ())
      }
      let argstring = arg.captures.first()

      let num-open-parens = argstring.matches("(").len()
      let close-parens = specstring.slice(arg.end).matches(")")
      assert-ctx(
        num-open-parens <= close-parens.len(),
        "Expected ')' for column modifier argument",
      )
      if num-open-parens > 0 {
        let old-end = arg.end
        arg.end += close-parens.at(num-open-parens - 1).end
        argstring += specstring.slice(old-end, arg.end)
      }

      args.at(modifier).push(argstring)
      specstring = specstring.slice(0, arg.start) + specstring.slice(arg.end)
      arg = specstring.match(regex-raw(`(?s)[ \t]*\((.*?)\)`))
    }

    specstring = specstring.replace(" ", "")
    specstring = specstring.replace("\t", "")

    // Strip out column separations next.
    let seps = ()
    let sep = specstring.match(regex-raw(`([0-9]+)`))
    while sep != none {
      seps.push(sep.captures.first())
      // Leave a single space as a placeholder for parsing below.
      specstring = specstring.slice(0, sep.start) + " " + specstring.slice(sep.end)
      sep = specstring.match(regex-raw(`([0-9]+)`))
    }

    // "Newlines and commas are special; they apply the descriptors
    // following them to a subsequent row of the table."
    specstring = specstring.split(regex-raw(`[,\n]+`)).enumerate()
    for (i, row) in specstring {
      let vline-end = if i == specstring.len() - 1 {
        none
      } else {
        i + 1
      }

      // Column descriptors are optionally separated by spaces or tabs.
      // Commas and newlines start a new "row definition" of column
      // descriptors (see outer loop).
      row = row.matches(regex-raw(
        `(?i)`,
        `([ACLNRS=^_-]|[|]+)`,
        `([^ACLNRS=|^_-]+)?`,
      ))
      let new-vlines = ()
      let new-rowdef = ()

      let column-sep-given = none
      for (j, col) in row.enumerate() {
        let (class, modstring) = col.captures

        let spec = spec-default(options)
        spec.class = upper(class)
        if modstring == none { modstring = "" }
        modstring = lower(modstring)

        assert-ctx(
          spec.class != "A",
          "Column class 'A' is not supported",
          row: i,
          col: j,
        )

        j -= new-vlines.len()
        if spec.class == "|" {
          assert-ctx(
            modstring == "",
            "Column modifiers should precede vertical lines",
            row: i,
            col: if j == 0 { 0 } else { j - 1 },
          )
          new-vlines.push(tablex.vlinex(
            start: i,
            end: vline-end,
            x: j,
            stroke: options.stroke,
          ))
          continue
        } else if spec.class == "||" {
          assert-ctx(
            false,
            "Double vertical lines are not supported",
            row: i,
            col: if j == 0 { 0 } else { j - 1 },
          )
        } else if spec.class.starts-with("|") {
          assert-ctx(
            false,
            "Invalid column class: '" + spec.class + "'",
            row: i,
            col: if j == 0 { 0 } else { j - 1 },
          )
        }

        if j >= cols.len() {
          cols.push(auto)
        }

        if column-sep-given != none {
          spec.pad.left = column-sep-given
          column-sep-given = none
        }

        spec.halign = {
          if spec.class in ("C", "N") {
            center
          } else if spec.class == "R" {
            right
          } else {
            left
          }
        }

        let my-min-width = none

        for mod in modstring.clusters() {
          assert-ctx(
            mod in " bdefimoptuvwxz".clusters(),
            "Column modifier '" + mod + "' is not supported",
            row: i,
            col: j,
          )

          if mod in "fmopvw".clusters() {
            assert-ctx(
              mod in args,
              "Missing argument for column modifier '" + mod + "'",
              row: i,
              col: j,
            )
          }

          if mod == " " {
            // Not a real modifier, but rather a placeholder for where a
            // column separation was given.

            // The following assertion should never fire, unless there
            // is a bug.
            assert(seps.len() > 0)

            spec.pad.right = coerce-unit(seps.remove(0), "en") / 2
            column-sep-given = spec.pad.right
          }

          else if mod == "b" {
            spec.bold = true

          } else if mod == "d" {
            spec.valign = bottom

          } else if mod == "e" {
            cols.at(j) = "equalize"

          } else if mod == "f" {
            arg = args.f.remove(0)
            if arg == "B" {
              spec.bold = true
            } else if arg == "I" {
              spec.italic = true
            } else if arg == "BI" {
              spec.bold = true
              spec.italic = true
            } else {
              spec.font = arg
            }

          } else if mod == "i" {
            spec.italic = true

          } else if mod == "m" {
            arg = args.m.remove(0)
            assert-ctx(
              arg in options.macros,
              "Macro '" + arg + "' not given in region options",
              row: i,
              col: j,
            )
            spec.macro = options.macros.at(arg)

          } else if mod == "o" {
            spec.fill = eval(args.o.remove(0))

          } else if mod == "p" {
            spec.size = coerce-unit(
              args.p.remove(0),
              "pt",
              relative: spec.size,
            )

          } else if mod == "t" {
            spec.valign = top

          } else if mod == "u" {
            spec.stagger = true

          } else if mod == "v" {
            spec.leading = coerce-unit(
              args.v.remove(0),
              "pt",
              relative: spec.leading,
            )

          } else if mod == "w" {
            my-min-width = coerce-unit(args.w.remove(0), "en")

          } else if mod == "x" {
            cols.at(j) = 1fr

          } else if mod == "z" {
            spec.ignore = true

          }
        }

        if my-min-width != none {
          tbl-cell(spec, styles => {
            final-widths.update(d => {
              let e = d.at(str(j), default: width-default)
              let w = pt-length(my-min-width, styles)
              let v = w + pt-length(spec.pad.left + spec.pad.right, styles)
              e.min = calc.max(e.min, w)
              e.max = calc.max(e.max, v)
              d.insert(str(j), e)
              d
            })
          })
        }

        new-rowdef.push(spec)
      }

      vlines += new-vlines
      specs.push(new-rowdef)
    }

    specs = specs.map(rowdef => {
      let missing = cols.len() - rowdef.len()
      if missing > 0 {
        rowdef += (spec-default(options),) * missing
      }
      rowdef
    })

    /////////////////////// TABLE DATA PARSING ///////////////////////

    // Strip out text blocks first.
    let text-blocks = ()
    let text-block = datastring.match(regex-raw(`(?s)T\{\n(.*?)\nT\}`))

    while text-block != none {
      text-blocks.push(text-block.captures.first())
      datastring = (
        datastring.slice(0, text-block.start)
        + "#tbl.text-block"
        + datastring.slice(text-block.end)
      )
      text-block = datastring.match(regex-raw(`(?s)T\{\n(.*?)\nT\}`))
    }

    for (i, row) in datastring.split("\n").enumerate() {
      i = i - hlines.len()

      // Skippable data entries:
      if row == "_" {
        // Horizontal rule
        hlines.push(tablex.hlinex(
          y: i,
          stroke: options.stroke,
        ))
        continue

      } else if row == "=" {
        // Double horizontal rule
        panic("Double horizontal lines are not supported")

      } else if row == ".TH" {
        // End-of-header
        options.repeat-header = true
        options.header-rows = i
        hlines.push(()) // A bit of a hack, but this keeps row numbering
                        // correct later.
        continue

      } else if row == ".T&" {
        panic("'.T&' is not supported")

      } else if row.starts-with(".\\\"") {
        // Comment
        hlines.push(())
        continue
      } else if row.starts-with(".") {
        panic("Unsupported command: `" + row + "'")
      }

      let rowdef = specs.at(calc.min(i, specs.len() - 1))
      row = row.split(options.tab)

      let missing = rowdef.len() - row.len()
      if missing > 0 {
        // Add empty columns if fewer than expected are provided
        row += ("",) * missing
      } else if missing < 0 {
        panic("Too many columns")
      }

      // This will hold each parsed cell
      let new-row = ()

      for (j, col) in row.enumerate() {
        let text-block = false
        if col.trim() == "#tbl.text-block" {
          text-block = true
          col = text-blocks.remove(0)
        } else if col.trim().starts-with("#tbl.text-block") {
          assert-ctx(
            false,
            "Nothing should follow text block close `T}` in same cell",
            row: i,
            col: j,
          )
        }

        col = col.trim()
        let colstring = col
        if colstring in special-entries { col = "" }
        let empty = col == ""
        col = col.replace("\\&", "")

        let spec = rowdef.at(j)
        let tbl-n = none

        col = tbl-cell(spec, {
          let align-pos = none
          let sep = []
          let n = 0

          if (spec.class == "N"
              and col != "" // Do nothing if special entry
              and not text-block
          ) {
            // one position AFTER \&
            align-pos = colstring.position("\\&")
            n = "\\&".len()

            if align-pos == none {
              // OR rightmost decimalpoint "ADJACENT TO DIGIT"
              //    (so "26.4. 12" aligns on "26.4", but
              //     "26.4 .12" aligns on ".12")
              let all-pos = colstring.matches(options.decimalpoint)

              if all-pos != () {
                sep = options.decimalpoint
                n = sep.len()

                for prev-pos in all-pos.rev() {
                  if prev-pos.start + n >= colstring.len() {
                    continue
                  }
                  let next-char = colstring.slice(prev-pos.start + n, count: 1)
                  if next-char.match(regex-raw(`[0-9]`)) != none {
                    align-pos = prev-pos.start
                    break
                  }
                }
              }

              if align-pos == none {
                align-pos = colstring.matches(regex-raw(`[0-9]`))
                if align-pos != () {
                  // OR rightmost digit
                  align-pos = align-pos.last().end
                  sep = []
                  n = 0
                } else {
                  // OR centered (no digits)
                  align-pos = none
                  sep = []
                  n = 0
                }
              }
            }
          }

          if align-pos != none {
            let txt-left = colstring.slice(0, align-pos)
            let txt-right = colstring.slice(align-pos + n)

            // Hacky as it gets... but necessary to preserve some
            // spacing across the decimalpoint.
            let sp = style(styles => {
              let w = measure("x  .", styles).width
              w -= measure("x.", styles).width
              h(w)
            })

            let cell-left = eval("[" + txt-left.trim() + "]")
            let cell-right = eval("[" + txt-right.trim() + "]")

            // Spacing adjustments
            if txt-left.ends-with(regex-raw(`[^ \t][ \t]`)) {
              cell-left = cell-left + sp
            }
            if txt-right.trim() == "" {
              sep = hide(options.decimalpoint)
            } else if txt-right.starts-with(regex-raw(`[ \t][^ \t]`)) {
              cell-right = sp + cell-right
            }

            tbl-n = (cell-left, sep, cell-right)
            stack(dir: ltr, ..tbl-n)

          } else {
            eval("[" + col + "]")
          }
        })

        if text-block {
          col = locate(loc => {
            let w = final-widths.at(loc).at(str(j), default: width-default)
            if w.min != 0pt {
              box(width: w.min, col)
            } else {
              let spanned-cols = 1
              for next-spec in rowdef.slice(j + 1) {
                if next-spec.class == "S" {
                  spanned-cols += 1
                } else {
                  break
                }
              }

              let width = tbl-max-width
              width *= spanned-cols
              width /= cols.len() + 1

              box(width: width, col)
            }
          })
        }

        let next-spec = rowdef.at(j + 1, default: (class: none))
        if spec.ignore {
          // Preserve height, but ignore width.
          col = tbl-cell(spec, styles => {
            box(
              width: 0pt,
              height: measure(col, styles).height,
              place(spec.halign + spec.valign, col)
            )
          })
        } else if next-spec.class != "S" {
          tbl-cell(spec, styles => {
            let v = measure(col, styles).width
            v += pt-length(spec.pad.left, styles)
            v += pt-length(spec.pad.right, styles)
            if cols.at(j) == "equalize" {
              equalize-width.update(w => calc.max(w, v))
            }
            final-widths.update(d => {
              let e = d.at(str(j), default: width-default)
              e.max = calc.max(e.max, v)

              if tbl-n != none {
                let (cell-left, _, cell-right) = tbl-n
                cell-left = measure(cell-left, styles).width
                cell-right = measure(cell-right, styles).width

                e.num-l = calc.max(e.num-l, cell-left)
                e.num-r = calc.max(e.num-r, cell-right)
              }

              d.insert(str(j), e)
              d
            })
          })
        }

        if spec.class == "S" {
          assert-ctx(
            empty,
            "Non-empty cell when class is spanned column",
            row: i,
            col: j,
          )

          // Find origin cell for this spanned one in current row
          let prev-col = -1
          while new-row.at(prev-col) == () {
            prev-col -= 1
          }
          new-row.at(prev-col).colspan += 1
          col = ()

        } else if spec.class == "^" or colstring == "\\^" {
          assert-ctx(
            colstring == "\\^" or empty,
            "Non-empty cell when class is spanned row",
            row: i,
            col: j,
          )

          // Find origin cell for this spanned one in current column
          let prev-row = -1
          while rows.at(prev-row).at(j) == () {
            prev-row -= 1
          }
          rows.at(prev-row).at(j).rowspan += 1
          col = ()

        } else if (spec.class in ("_", "-", "=")
              or colstring in ("_", "=", "\\_", "\\=")
        ) {
          assert-ctx(
            empty,
            "Non-empty cell when class is horizontal rule",
            row: i,
            col: j,
          )

          let line-start-x = 0%
          let line-length = 100%
          if colstring in ("\\_", "\\=") {
            line-start-x += spec.pad.left
            line-length -= spec.pad.left + spec.pad.right
          }

          col = tablex.cellx(
            align: center + horizon,
            fill: spec.fill,

            {
              if spec.class in ("_", "-") or colstring in ("_", "\\_") {
                // Horizontal rule
                line(
                  start: (line-start-x, 50%),
                  length: line-length,
                  stroke: options.stroke,
                )
              } else {
                // Double horizontal rule
                line(
                  start: (line-start-x, 50% - 1pt),
                  length: line-length,
                  stroke: options.stroke,
                )
                line(
                  start: (line-start-x, 50% + 1pt),
                  length: line-length,
                  stroke: options.stroke,
                )
              }
            }
          )

        } else if spec.class in ("L", "C", "R", "N") {
          col = tablex.cellx(
            align: spec.halign + spec.valign,
            fill: spec.fill,
            pad(..spec.pad, col),
          )

          if tbl-n != none {
            col.tbl-n = tbl-n
          }
        }

        new-row.push(col)
      }
      rows.push(new-row)
    }

    ///////////////////////// LINE REALIZATION /////////////////////////
    if options.box and not options.auto-lines {
      hlines += (
        tablex.hlinex(y: 0),
        tablex.hlinex(y: rows.len()),
      )

      vlines += (
        tablex.vlinex(x: 0),
        tablex.vlinex(x: cols.len()),
      )
    }

    //////////////////////// TABLE REALIZATION ////////////////////////
    align(
      options.tbl-align,

      block(
        breakable: options.breakable,
        inset:
          if options.doublebox { 2pt }
          else { 0pt },
        stroke:
          if options.doublebox { options.stroke }
          else { none },

        /********************* WIDTH REALIZATION *********************/
        locate(loc => {
          let adjusted-rows = rows.enumerate().map(row => {
            let (i, row) = row
            let rowdef = specs.at(calc.min(i, specs.len() - 1))

            row.enumerate().map(col => {
              let (j, col) = col
              let spec = rowdef.at(j)

              if type(col) == "dictionary" and "tbl-n" in col {
                col.content = tbl-cell(spec, {
                  let (cell-left, sep, cell-right) = col.tbl-n
                  let w = final-widths.at(loc).at(str(j), default: width-default)

                  pad(
                    ..spec.pad,
                    stack(
                      dir: ltr,
                      box(width: w.num-l, align(right, cell-left)),
                      sep,
                      box(width: w.num-r, align(left, cell-right)),
                    )
                  )
                })
              }

              col
            })
          })

          tablex.tablex(
            columns: cols.enumerate().map(c => {
              let (j, c) = c
              if c == "equalize" {
                equalize-width.at(loc)
              } else if c == auto {
                final-widths.at(loc).at(str(j), default: (max: auto)).max
              } else {
                c
              }
            }),

            auto-lines: options.auto-lines,
            header-rows: options.header-rows,
            inset: 0pt,
            repeat-header: options.repeat-header,
            stroke: options.stroke,

            ..vlines,
            ..hlines,
            ..adjusted-rows.flatten(),
          )
        })
      )
    )
  })

  body
}
