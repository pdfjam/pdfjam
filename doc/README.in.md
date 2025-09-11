---
title: pdfjam
author: Markus Kurtz <anything at mgkurtz.de>
---

Website: <https://github.com/pdfjam/pdfjam>  
License: [GPL 2](https://www.gnu.org/licenses/old-licenses/gpl-2.0.html)

Pdfjam assembles a list of documents (pdf, ps, eps, jpg or png) into a single pdf.
It allows to [rotate](#angle), [scale](#scale), [n-up](#nup), reorder and combine pages freely
using the power of the [pdfpages](https://ctan.org/pkg/pdfpages) and [graphicx](https://ctan.org/pkg/graphicx) [LaTeX](https://latex-project.org) packages.

# Overview

## Major Features

Pdfjam is for you, if you want to create ready to print pdf files from any number of source files using a command line interface.

A pretty basic call to `pdfjam` looks like

```sh
pdfjam --outfile output.pdf input.pdf 2,4-6,9-last input-image.jpg
```

Some options (including example values) include

* `--nup 2x2` for putting 4 input pages on each output page
* `--paper a4` for setting ISO A4 page size
* `--angle 90` for rotating to the left
* `--scale 0.7` for scaling by 70 %
* `--booklet true` to arrange the input as a booklet
* `--signature 24` to arrange as a book consisting of separate signatures, made up of 24 pages each
* `--batch` Create one output file for each input file

See the [comprehensive list of options] for more and advanced options.

## Strengths, Weaknesses and Alternatives

The many options for dealing with pdfs as graphics plus the support for various image formats
turn _pdfjam_ into a powerful tool among pdf manipulating programs.

The _pdfjam_ script builds upon _LaTeX_ and needs a Unix shell.
This will be fine for some, but if you do not have both installed,
some other tool may suit your needs better.

The LaTeX backend of _pdfjam_ deals with pdf files as vector images only.
Thus all interactive features such as hyperlinks or bookmarks get lost.
If you need to keep them, or want a tool that manipulates any specific pdf properties,
best consider one of the below.

All listed alternatives allow combining various input pdfs, selecting pages and rotating them.

* [PSUtils](https://pypi.org/project/psutils): Python-based, features a subset of pdfjam’s features using a much smaller technology stack
* [PDFtk-Java](https://gitlab.com/pdftk-java/pdftk): Java-based, supports encryption and decryption, as well as working with pdf forms and more
  * [PDFtk](https://www.pdflabs.com/tools/pdftk-server): also Java-based, the ancestor of the above
  * [pdfchain](https://pdfchain.sourceforge.io): a GUI for PDFtk
* [qpdf](https://qpdf.sourceforge.io): similar features as PDFtk
* [mutool](https://mupdf.com/core): part of _mupdf_, some of PDFtk’s features, supports epub files
* [PDFsam](https://pdfsam.org): Java-based GUI program
* [pypdf](https://github.com/py-pdf/pypdf): self-contained Python package
  * [pdfly](https://github.com/py-pdf/pdfly): CLI for a subset of pypdf
* [ghostscript](https://ghostscript.com): Has been around for ages, comes with many features, high and low level

Useful tools while working with _pdfjam_ contain `pdfinfo` from [poppler-utils](https://poppler.freedesktop.org)
to inspect pdf metadata and [`pdfcrop`](https://www.ctan.org/pkg/pdfcrop) to trim
any whitespace border around a pdf.
You may also want to take a look at [`inkscape`](https://inkscape.org)
for editing pdf files or converting or cropping them via its command line interface.

# Installation

Currently _pdfjam_ works for Unix-like operating systems (Linux, Mac OS X, FreeBSD, etc.) only.
Under Windows, you may try a Linux subsystem, Cygwin or Git Bash.

Some options to install _pdfjam_

1. Install via [your operating system’s repository](https://repology.org/project/pdfjam).
2. If you installed a [TeX Live](https://tug.org/texlive) distribution not managed by your operating system,
    use the [TeX Live cockpit](https://github.com/TeX-Live/tlcockpit).
3. Download or clone the [pdfjam sources](https://github.com/pdfjam/pdfjam).
    Then run `l3build install --full` in the pdfjam directory to install locally.
    Also see the [developing] section for working with, rebuilding and testing the code.
4. Download a [packaged release](https://github.com/pdfjam/pdfjam/releases),
    it contains a file `bin/pdfjam` which you need to make available on your `PATH`
    and `man/pdfjam.1` which you should put in your `MANPATH`.

If you choose one of the later options, make sure your system contains
a working installation of [LaTeX](https://latex-project.org) and the
[pdfpages](https://ctan.org/pkg/pdfpages) LaTeX package.

For the `--keepinfo` option, you need `pdfinfo` available by installing [poppler-utils](https://poppler.freedesktop.org).

# Comprehensive list of options

\input{options.tex}

# Usage examples

## Batch 2-upping of documents

Consider converting each of two documents to a side-by-side "2-up" format.
Since we want the two documents to be processed separately, we'll use the
`--batch` option:

```sh
pdfjam --batch --nup 2x1 --suffix 2up --landscape file1.pdf file2.pdf
```

This will produce new files `file1-2up.pdf` and `file2-2up.pdf` in the current
working directory.

## Merging pages from 2 documents

Suppose we want a single new document which puts together selected pages from two different files:

```sh
pdfjam file1.pdf '{},2-' file2.pdf '10,3-6' --outfile ../myNewFile.pdf
```

The new file `myNewFile.pdf`, in the parent directory of the current one,
contains an empty page, followed by all pages of `file1.pdf` except the first,
followed by pages 10, 3, 4, 5 and 6 from `file2.pdf`.

The resulting PDF page size will be whatever is the default paper size for
you at your site. If instead you want to preserve the page size of
(the first included page from) `file1.pdf`, use the option `--fitpaper true`.

**All pages in an output file from `pdfjam` will have the same size and
orientation.**  For joining together PDF files while preserving _different_ page
sizes and orientations, `pdfjam` is not the tool to use.

## A 4-up document with frames

To make a portrait-oriented 4-up file from the pages of three input files,
with a thin-line frame around the input pages:

```sh
pdfjam file1.pdf file2.pdf file3.pdf --no-landscape --frame true --nup 2x2 --suffix 4up --outfile ~/Documents
```

Here a _directory_ was specified at `--outfile`: the resultant file in this
case will be `~/Documents/file3-4up.pdf`.
(Note that **if there's a writeable file with that name already, it will be
overwritten**: no check is made, and no warning given.)

## Convert a 'US letter' document to A4

Suppose we have a document made up of 'US letter' size pages,
and we want to convert it to A4:

```sh
pdfjam 'my US letter file.pdf' --a4paper --outfile 'my A4 file.pdf'
```

## Handouts from presentation slides

A useful application of `pdfjam` is for producing a handout from a file of
presentation slides. For slides made with the standard 4:3 aspect ratio a
nice 6-up handout on A4 paper can be made by

```sh
pdfjam --nup 2x3 --frame true --noautoscale false --delta "0.2cm 0.3cm" --scale 0.95 myslides.pdf --outfile myhandout.pdf
```

The `--delta` option here comes from the pdfpages package; the `--scale`
option is passed to LaTeX's `\includegraphics` command.

Slides made by LaTeX's _beamer_ package, using the `handout` class option,
work especially nicely with this! The example wrapper scripts `pdfjam-slides3up`
and `pdfjam-slides6up`, in the
[pdfjam-extras](https://github.com/pdfjam/pdfjam-extras) repository,
are for 3-up and 6-up handouts, respectively.

## Trimming pages; and piped output

Suppose we want to trim the pages of our input file prior to n-upping.
This can be done by using a pipe:

```sh
pdfjam myfile.pdf --trim '1cm 2cm 1cm 2cm' --clip true --outfile /dev/stdout | pdfjam --nup 2x1 --frame true --outfile myoutput.pdf
```

The `--trim` option specifies an amount to trim from the left, bottom, right and
top sides respectively; to work as intended here it needs also `--clip true`.
These (i.e., `trim` and `clip`) are in fact options to LaTeX's
`\includegraphics` command (in the standard _graphics_ package).

Thanks go to Christophe Lange and Christian Lohmaier for suggesting
an example on this.

## Output pages suitable for binding

To offset the content of double-sided printed pages so that they are
suitable for binding with a
[Heftstreifen](https://de.wikipedia.org/wiki/Heftstreifen), use
the `--twoside` option:

```sh
pdfjam --twoside myfile.pdf --offset '1cm 0cm' --suffix 'offset'
```

## Input file with nonstandard name

To use PDF input files whose names do not end in '`.pdf`', you will need to use
the `--checkfiles` option. This depends on the availability of the `file`
utility, with support for the options `-Lb`; this can be checked by trying

```sh
file -Lb 'my PDF file'
```

where `'my PDF file'` is the name of a PDF file on your system.
The result should be something like '`PDF document, version 1.4`'
(possibly with a different version number).

With '`file -Lb`' available, we can use PDF files whose names lack the usual
'`.pdf`' extension.  For example,

```sh
pdfjam --nup 2x1 --checkfiles 'my PDF file'
```

will result in a file named '`my PDF file-2x1.pdf`'
in the current working directory.

## Rotate every 2nd page

If you want to print a landscape-oriented PDF document on both sides of the paper,
using a duplex printer that does not have 'tumble' capability, make a new version
with every second page rotated for printing:

```sh
pdfjam --landscape --doublepagestwistodd true my-landscape-document.pdf
```

# Configuration

You can configure pdfjam to your needs by putting a file called `pdfjam.conf`
in any directory specified by `pdfjam --configpath` or a `.pdfjam.conf` in
your home directory. See the `pdfjam.conf` coming with your installation
or [online](https://github.com/pdfjam/pdfjam/blob/master/doc/pdfjam.conf)
for a list of available configuration variables.

For setting the default paper size, also consider configuring (or installing) [libpaper](https://github.com/rrthomas/libpaper).

# Troubleshooting

<!-- TODO: Are any of those relevant any more? -->

* The script runs but the output doesn't look the way it should. Why?

  Most likely either your pdfTeX or your pdfpages installation is an old version.
  You could check also that `pdftex.def`, typically to be found in
  `.../texmf/tex/latex/graphics/`,
  is up to date. If the problem persists even with up-to-date versions of pdfTeX,
  `pdftex.def` and pdfpages, then please do report it.
* What can I do to solve a “Too many open files” error?

  This error has been reported to occur sometimes, when dealing with large numbers of
  documents/pages. A [suggested solution](https://stackoverflow.com/questions/1715677/error-too-many-open-files-in-pdflatex),
  if this happens, is to include additionally (in the call to `pdfjam`):
  
  ```sh
  --preamble '\let\mypdfximage\pdfximage \def\pdfximage{\immediate\mypdfximage}'
  ```

* Minor details of the font got missing in the output. Why?

  Sometimes font information (such as ligatures) is lost from the output of
  `pdfjam`.  It seems that a fairly simple fix when this happens is to add the
  option `--preamble '\pdfinclusioncopyfonts=1'` in your call to `pdfjam`.
* My `--preamble '\usepackage[...]{geometry}'` causes failure. What shall I do?

  The `geometry` package gets already loaded by pdfjam, so just use `\geometry{}`
  for any further settings.
* My `--preamble '\usepackage[...]{color}'` does not work. What to do?

  Either do not use in conjunction with `--pagecolor` or use with `--pagecolor`,
  but then do not load the _color_ package again.


# Reporting bugs

Please report any bugs found in `pdfjam` [on GitHub](https://github.com/pdfjam/pdfjam/issues).

# Developing

This project uses [l3build](https://ctan.org/pkg/l3build) for
building (`l3build unpack`), testing (`l3build check`) and installing (`l3build install`).
See the first few lines of `build.lua` for more information.

# The History of _pdfjam_

The first versions of PDFjam were made by [David Firth](http://warwick.ac.uk/dfirth)
with the first release of the `pdfnup` script dating back to 2002-04-04
and the name PDFjam debuting with the 1.0 release on 2004-05-07.
Several releases followed until version 2.08 on 2010-11-14.

Nine years later — on 2019-11-14 — David Firth published an overhauled version 3.02,
now called pdfjam (in lower letters).
The next November, maintenance went over to [Reuben Thomas](https://rrt.sc3d.org)
were it remained until November 2024, when [Markus Kurtz](https://mgkurtz.de) took over.

What follows is David Firth’s account of pdfjam’s history:

> This all grew originally from a script named `pdfnup`. That was later joined,
> in a published package called 'PDFjam', by two further scripts `pdfjoin` and
> `pdf90`.
>
> At version 2.00, everything was unified through a single script `pdfjam`, with
> many more options. Along with `pdfjam` various 'wrapper' scripts --- i.e.,
> other scripts that use `pdfjam` in different ways --- were provided, mainly as
> examples.
>
> From version 3.02, the extra 'wrapper' scripts are removed from the package,
> mainly because they are hard to maintain: different users want different
> things, and `pdfjam` itself provides all the options in any case. So I have
> broken out the wrapper scripts into a separate repository, _unsupported_ ---
> so that people can still see and use/adapt them if they want.
> And maybe even someone else will
> want to take on the task of improving and maintaining some of them,
> who knows?  The wrapper scripts (**no longer maintained**) can now be found at
> <https://github.com/pdfjam/pdfjam-extras>.

For historic release notes, see the `README.md`
as of [pdfjam v3.04](https://github.com/pdfjam/pdfjam/tree/v3.04).

Releases from version 1.0 up to version 2.08 are still available at <https://pdfjam.github.io/pdfjam>.
For any releases after that, see <https://github.com/pdfjam/pdfjam/releases>.
