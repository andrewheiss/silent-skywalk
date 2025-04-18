// Nicer numbers
#set text(number-type: "old-style")

// Links
#show link: set text(fill: rgb("e17c05"))

// Inline code
#show raw.where(
  block: false
): it => box(fill: rgb("#f5f5f5"), radius: 2pt, outset: 2pt)[
  #set text(fill: rgb("#994E95"), weight: "bold")
  #it
]

// H1
#show heading.where(
  level: 1
): it => block(width: 100%, above: 2em, below: 1em)[
  #set align(center)
  #set text(0.9em, font: "Libre Franklin", weight: "semibold", hyphenate: false)
  #it.body
]

// H2
#show heading.where(
  level: 2
): it => block(width: 100%, above: 2em, below: 1em)[
  #set align(center)
  #set text(0.8em, font: "Libre Franklin", weight: "bold", hyphenate: false)
  #it.body
]

#let article(
  title: none,
  subtitle: none,
  authors: none,
  date: none,
  abstract: none,
  abstract-title: none,
  cols: 1,
  margin: (x: 1.25in, y: 1.25in),
  paper: "us-letter",
  lang: "en",
  region: "US",
  font: "libertinus serif",
  fontsize: 11pt,
  title-size: 1.5em,
  subtitle-size: 1.25em,
  heading-family: "Libre Franklin",
  heading-weight: "bold",
  heading-style: "normal",
  heading-color: black,
  heading-line-height: 0.65em,
  sectionnumbering: none,
  pagenumbering: "1",
  toc: false,
  toc_title: none,
  toc_depth: none,
  toc_indent: 1.5em,
  doc,
) = {
  set page(
    paper: paper,
    margin: margin,
    numbering: pagenumbering,
  )
  set par(justify: true)
  set text(lang: lang,
           region: region,
           font: font,
           size: fontsize)
  set heading(numbering: sectionnumbering)
  if title != none {
    align(center)[#block(inset: 2em)[
      #set par(leading: heading-line-height, justify: false)
      #if (heading-family != none or heading-weight != "bold" or heading-style != "normal"
           or heading-color != black or heading-decoration == "underline"
           or heading-background-color != none) {
        set text(font: heading-family, weight: heading-weight, style: heading-style, fill: heading-color, hyphenate: false)
        text(size: title-size)[#title]
        if subtitle != none {
          parbreak()
          text(size: subtitle-size, hyphenate: false)[#subtitle]
        }
      } else {
        text(weight: "bold", size: title-size, hyphenate: false)[#title]
        if subtitle != none {
          parbreak()
          text(weight: "bold", size: subtitle-size, hyphenate: false)[#subtitle]
        }
      }
    ]]
  }

  if authors != none {
    let count = authors.len()
    let ncols = calc.min(count, 3)
    grid(
      columns: (1fr,) * ncols,
      row-gutter: 1.5em,
      ..authors.map(author =>
          align(center)[
            #text(weight: "bold")[#author.name] \
            #author.affiliation \
            #author.email
          ]
      )
    )
  }

  if date != none {
    align(center)[#block(inset: 1em)[
      #date
    ]]
  }

  if abstract != none {
    block(inset: 2em)[
    #text(weight: "semibold")[#abstract-title] #h(1em) #abstract
    ]
  }

  if toc {
    let title = if toc_title == none {
      auto
    } else {
      toc_title
    }
    block(above: 3em, below: 2em)[
    #outline(
      title: toc_title,
      depth: toc_depth,
      indent: toc_indent
    );
    ]
  }

  if cols == 1 {
    doc
  } else {
    columns(cols, doc)
  }
}
