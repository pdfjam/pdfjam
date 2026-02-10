![GitHub CI](https://github.com/pdfjam/pdfjam/actions/workflows/ci.yml/badge.svg)

# pdfjam

_Markus Kurtz_ <_anything_ at mgkurtz.de>

- [Overview](#overview)
  - [Major Features](#major-features)
  - [Strengths, Weaknesses and
    Alternatives](#strengths-weaknesses-and-alternatives)
- [Installation](#installation)
- [Comprehensive list of options](#comprehensive-list-of-options)
  - [Change operation mode](#change-operation-mode)
  - [Define where to put files](#define-where-to-put-files)
  - [Configure LaTeX run](#configure-latex-run)
  - [Set PDF metadata](#set-pdf-metadata)
  - [Set paper format](#set-paper-format)
  - [Adjust page](#adjust-page)
  - [Pdfpages settings](#pdfpages-settings)
  - [Graphicx options](#graphicx-options)
- [Usage examples](#usage-examples)
  - [Batch 2-upping of documents](#batch-2-upping-of-documents)
  - [Merging pages from 2 documents](#merging-pages-from-2-documents)
  - [A 4-up document with frames](#a-4-up-document-with-frames)
  - [Convert a 'US letter' document to A4](#convert-a-us-letter-document-to-a4)
  - [Handouts from presentation slides](#handouts-from-presentation-slides)
  - [Trimming pages; and piped output](#trimming-pages-and-piped-output)
  - [Output pages suitable for binding](#output-pages-suitable-for-binding)
  - [Input file with nonstandard name](#input-file-with-nonstandard-name)
  - [Rotate every 2nd page](#rotate-every-2nd-page)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)
- [Reporting bugs](#reporting-bugs)
- [Developing](#developing)
- [The History of *pdfjam*](#the-history-of-pdfjam)

Website: <https://github.com/pdfjam/pdfjam>  
License: [GPL 2](https://www.gnu.org/licenses/old-licenses/gpl-2.0.html)

Pdfjam assembles a list of documents (pdf, ps, eps, jpg or png) into a single
pdf. It allows to [rotate](#angle), [scale](#scale), [n-up](#nup), reorder and
combine pages freely using the power of the
[pdfpages](https://ctan.org/pkg/pdfpages) and
[graphicx](https://ctan.org/pkg/graphicx) [LaTeX](https://latex-project.org)
packages.

## Overview

### Major Features

Pdfjam is for you, if you want to create ready to print pdf files from any
number of source files using a command line interface.

A pretty basic call to `pdfjam` looks like

``` sh
pdfjam --outfile output.pdf input.pdf 2,4-6,9-last input-image.jpg
```

Some options (including example values) include

- `--nup 2x2` for putting 4 input pages on each output page
- `--paper a4` for setting ISO A4 page size
- `--angle 90` for rotating to the left
- `--scale 0.7` for scaling by 70 %
- `--booklet true` to arrange the input as a booklet
- `--signature 24` to arrange as a book consisting of separate signatures, made
  up of 24 pages each
- `--batch` Create one output file for each input file

See the [comprehensive list of options](#comprehensive-list-of-options) for more
and advanced options.

### Strengths, Weaknesses and Alternatives

The many options for dealing with pdfs as graphics plus the support for various
image formats turn *pdfjam* into a powerful tool among pdf manipulating
programs.

The *pdfjam* script builds upon *LaTeX* and needs a Unix shell. This will be
fine for some, but if you do not have both installed, some other tool may suit
your needs better.

The LaTeX backend of *pdfjam* deals with pdf files as vector images only. Thus
all interactive features such as hyperlinks or bookmarks get lost. If you need
to keep them, or want a tool that manipulates any specific pdf properties, best
consider one of the below.

All listed alternatives allow combining various input pdfs, selecting pages and
rotating them.

- [PSUtils](https://pypi.org/project/psutils): Python-based, features a subset
  of pdfjam’s features using a much smaller technology stack
- [PDFtk-Java](https://gitlab.com/pdftk-java/pdftk): Java-based, supports
  encryption and decryption, as well as working with pdf forms and more
  - [PDFtk](https://www.pdflabs.com/tools/pdftk-server): also Java-based, the
    ancestor of the above
  - [pdfchain](https://pdfchain.sourceforge.io): a GUI for PDFtk
- [qpdf](https://qpdf.sourceforge.io): similar features as PDFtk
- [mutool](https://mupdf.com/core): part of *mupdf*, some of PDFtk’s features,
  supports epub files
- [PDFsam](https://pdfsam.org): Java-based GUI program
- [pypdf](https://github.com/py-pdf/pypdf): self-contained Python package
  - [pdfly](https://github.com/py-pdf/pdfly): CLI for a subset of pypdf
- [ghostscript](https://ghostscript.com): Has been around for ages, comes with
  many features, high and low level

Useful tools while working with *pdfjam* contain `pdfinfo` from
[poppler-utils](https://poppler.freedesktop.org) to inspect pdf metadata and
[`pdfcrop`](https://www.ctan.org/pkg/pdfcrop) to trim any whitespace border
around a pdf. You may also want to take a look at
[`inkscape`](https://inkscape.org) for editing pdf files or converting or
cropping them via its command line interface.

## Installation

Currently *pdfjam* works for Unix-like operating systems (Linux, Mac OS X,
FreeBSD, etc.) only. Under Windows, you may try a Linux subsystem, Cygwin or Git
Bash.

Some options to install *pdfjam*

1.  Install via [your operating system’s
    repository](https://repology.org/project/pdfjam).
2.  If you installed a [TeX Live](https://tug.org/texlive) distribution not
    managed by your operating system, use the [TeX Live
    cockpit](https://github.com/TeX-Live/tlcockpit).
3.  Download or clone the [pdfjam sources](https://github.com/pdfjam/pdfjam).
    Then run `l3build install --full` in the pdfjam directory to install
    locally. Also see the [developing](#developing) section for working with,
    rebuilding and testing the code.
4.  Download a [packaged release](https://github.com/pdfjam/pdfjam/releases), it
    contains a file `bin/pdfjam` which you need to make available on your `PATH`
    and `man/pdfjam.1` which you should put in your `MANPATH`.

If you choose one of the later options, make sure your system contains a working
installation of [LaTeX](https://latex-project.org) and the
[pdfpages](https://ctan.org/pkg/pdfpages) LaTeX package.

For the `--keepinfo` option, you need `pdfinfo` available by installing
[poppler-utils](https://poppler.freedesktop.org).

## Comprehensive list of options

Also see the [manual]() which contains the same list with example output added.

### Change operation mode

<span id="help"/>**-h**, **--help**  
Print help message.

<span id="version"/>**-V**, **--version**  
Print the version number.

<span id="configpath"/>**--configpath**  
Print the `configpath` variable.

<span id="quiet"/>**-q**, **--quiet**  
Suppress verbose commentary on progress.

<span id="batch"/>**--batch**  
Run pdfjam sequentially on each input file in turn, and produce a separate
output file for each input.

<span id="checkfiles"/>**--checkfiles** *respectively* **--no-checkfiles**  
Use `file` utility to determine file type.

<span id="vanilla"/>**--vanilla**  
Suppress the reading of any pdfjam configuration files.

<span id="enc"/>**--enc** encoding  
Command-line encoding as understood by `iconv`.

### Define where to put files

<span id="outfile"/>**-o** output, **--outfile** output, **--output** output  
File or directory name for output(s).

<span id="suffix"/>**--suffix** string  
Suffix for output, when file name is not given explicitly.

<span id="tidy"/>**--tidy** *respectively* **--no-tidy**  
Clean temporary build directory. On by default.

<span id="builddir"/>**--builddir** directory  
Set build directory.

### Configure LaTeX run

<span id="latex"/>**--latex** engine  
Absolute path to LaTeX engine to be used.

<span id="latexopts"/>**--latexopts** latex-command-line-options  
Provide arguments to use when calling the LaTeX engine.

<span id="preamble"/>**--preamble** tex  
Append code to the LaTeX preamble.

<span id="runs"/>**--runs** number-of-runs  
Run latex N times, for each output document made.

### Set PDF metadata

<span id="keepinfo"/>**--keepinfo** *respectively* **--no-keepinfo**  
Preserve Title, Author, Subject and Keywords (from the last input PDF) in the
output PDF file.

<span id="pdftitle"/>**--pdftitle** string  
Set Title of the output PDF file.

<span id="pdfauthor"/>**--pdfauthor** string  
Set Author of the output PDF file.

<span id="pdfsubject"/>**--pdfsubject** string  
Set Subject of the output PDF file.

<span id="pdfkeywords"/>**--pdfkeywords** string  
Set Keywords of the output PDF file.

### Set paper format

<span id="paper"/>**--paper** paper-name  
Paper format.

<span id="papersize"/>**--papersize** width,height  
Specify a paper size as width × height.

### Adjust page

<span id="landscape"/>**--landscape** *respectively* **--no-landscape**  
Exchange width and height of paper.

<span id="twoside"/>**--twoside** *respectively* **--no-twoside**  
Specify `twoside` document class option.

<span id="otheredge"/>**--otheredge** *respectively* **--no-otheredge**  
Rotate every odd page by 180 degrees.

<span id="pagecolor"/>**--pagecolor** rgb  
Background color.

### Pdfpages settings

#### N-up pages

<span id="nup"/>**--nup** XxY  
Put multiple logical pages onto each sheet of paper.

<span id="column"/>**--column** bool  
Use column-major layout, where successive pages are arranged in columns down the
paper.

<span id="columnstrict"/>**--columnstrict** bool  
For column-major layout only: Do not balance the columns on the last page.

#### Shift pages

<span id="delta"/>**--delta** 'horizontal-space vertical-space'  
Put some horizontal and vertical space between the logical pages.

<span id="offset"/>**--offset** 'horizontal-displacement vertical-displacement'  
Displace the origin of the inserted pages.

<span id="frame"/>**--frame** bool  
Put a frame around each logical page.

#### Scale pages

<span id="noautoscale"/>**--noautoscale** bool  
Suppress automatic scaling of pages.

<span id="fitpaper"/>**--fitpaper** bool  
Adjust the paper size to the size of the inserted document.

<span id="turn"/>**--turn** bool  
Tell PDF viewer to display landscape pages in landscape orientation. On by
default.

<span id="pagetemplate"/>**--pagetemplate** pagenumber  
Declare page to be used as a template. All other pages are scaled such that they
match within its size.

<span id="templatesize"/>**--templatesize** width,height  
Specify size of page template. All pages are scaled such that they match within
this size.

<span id="rotateoversize"/>**--rotateoversize** bool  
Rotate oversized pages.

#### Mirror pages

<span id="reflect"/>**--reflect** bool  
Reflect output pages.

<span id="reflect*"/>**--reflect\*** bool  
Reflect input pages.

#### Create signatures

<span id="signature"/>**--signature** multiple-of-4  
Create booklets by rearranging pages into signatures of 2 pages each.

<span id="signature*"/>**--signature\*** multiple-of-4  
Similar to signature, but for right-edge binding.

<span id="booklet"/>**--booklet** bool  
Same as signature with signature size chosen such that all pages fit into one
signature.

<span id="booklet*"/>**--booklet\*** bool  
Similar to booklet, but for right-edge binding.

<span id="flip-other-edge"/>**--flip-other-edge** bool  
For signatures/booklets: set duplex binding edge perpendicular (instead of
parallel) to signature binding edge. Has same result as `otheredge`.

#### Add blank pages

<span id="openright"/>**--openright** bool  
Put an empty page before the first logical page.

<span id="openrighteach"/>**--openrighteach** bool  
Put an empty page before the first logical page of each file.

#### Duplicate pages

<span id="doublepages"/>**--doublepages** bool  
Insert every page twice.

<span id="doublepagestwist"/>**--doublepagestwist** bool  
Insert every page twice: once upside down and once normally.

<span id="doublepagestwistodd"/>**--doublepagestwistodd** bool  
Insert every page twice: once normally and once upside down.

<span id="doublepagestwist*"/>**--doublepagestwist\*** bool  
Insert every page twice: for odd pages, the first copy is upside down; for even
pages, the second copy.

<span id="doublepagestwistodd*"/>**--doublepagestwistodd\*** bool  
Insert every page twice: for odd pages, the second copy is upside down; for even
pages, the first copy.

<span id="duplicatepages"/>**--duplicatepages** number  
Insert every page multiple times.

#### Run LaTeX commands

<span id="pagecommand"/>**--pagecommand** tex  
Declare LaTeX commands, which are executed on each sheet of paper.

<span id="pagecommand*"/>**--pagecommand\*** tex  
Declare LaTeX commands, which are executed on the very first page only.

<span id="picturecommand"/>**--picturecommand** tex  
Similar to pagecommand, but executed within a picture environment with base
point at the lower left page corner.

<span id="picturecommand*"/>**--picturecommand\*** tex  
Similar to picturecommand, but for very first page only.

#### Add hyperlinks

<span id="link"/>**--link** bool  
Each inserted page becomes the target of the hyperlink ⟨filename⟩.⟨pagenumber⟩.

<span id="linkname"/>**--linkname** name  
For link option only: Change the link base name from ⟨filname⟩ to name.

<span id="threadname"/>**--threadname** name  
For thread option only: Change the thread name from ⟨filename⟩ to name.

<span id="linkfit"/>**--linkfit** (Fit \| FitH ⟨top⟩ \| FitV ⟨left⟩ \| FitB \| FitBH ⟨top⟩ \| FitBV ⟨left⟩ \| Region)  
For link option only: Specify, how the viewer displays a linked page.

<span id="addtotoc"/>**--addtotoc** pagenumber,section,level,heading,label  
Add an entry to the table of contents.

<span id="addtolist"/>**--addtolist** pagenumber,type,heading,label  
Add an entry to the list of figures, the list of tables, or any other list.

### Graphicx options

<span id="viewport"/>**--viewport** 'left bottom right top'  
Consider image to consist of given rectangle only.

<span id="trim"/>**--trim** 'left bottom right top'  
Similar to viewport, but here the four lengths specify the amount to remove or
add to each side.

<span id="angle"/>**--angle** angle  
Rotation angle (counterclockwise).

<span id="width"/>**--width** width  
Required width. The graphic is scaled to this width.

<span id="height"/>**--height** height  
Required height. The graphic is scaled to this height.

<span id="keepaspectratio"/>**--keepaspectratio** bool  
Do not distort figure if both width and height are given.

<span id="scale"/>**--scale** float  
Scale factor.

<span id="clip"/>**--clip** bool  
Clip the graphic to the viewport.

<span id="pagebox"/>**--pagebox** (mediabox \| cropbox \| bleedbox \| trimbox \| artbox)  
Specify which PDF bounding box specification to read.

<span id="draft"/>**--draft** bool  
Switch to draft mode.

## Usage examples

### Batch 2-upping of documents

Consider converting each of two documents to a side-by-side "2-up" format. Since
we want the two documents to be processed separately, we'll use the `--batch`
option:

``` sh
pdfjam --batch --nup 2x1 --suffix 2up --landscape file1.pdf file2.pdf
```

This will produce new files `file1-2up.pdf` and `file2-2up.pdf` in the current
working directory.

### Merging pages from 2 documents

Suppose we want a single new document which puts together selected pages from
two different files:

``` sh
pdfjam file1.pdf '{},2-' file2.pdf '10,3-6' --outfile ../myNewFile.pdf
```

The new file `myNewFile.pdf`, in the parent directory of the current one,
contains an empty page, followed by all pages of `file1.pdf` except the first,
followed by pages 10, 3, 4, 5 and 6 from `file2.pdf`.

The resulting PDF page size will be whatever is the default paper size for you
at your site. If instead you want to preserve the page size of (the first
included page from) `file1.pdf`, use the option `--fitpaper true`.

**All pages in an output file from `pdfjam` will have the same size and
orientation.** For joining together PDF files while preserving *different* page
sizes and orientations, `pdfjam` is not the tool to use.

### A 4-up document with frames

To make a portrait-oriented 4-up file from the pages of three input files, with
a thin-line frame around the input pages:

``` sh
pdfjam file1.pdf file2.pdf file3.pdf --no-landscape --frame true --nup 2x2 --suffix 4up --outfile ~/Documents
```

Here a *directory* was specified at `--outfile`: the resultant file in this case
will be `~/Documents/file3-4up.pdf`. (Note that **if there's a writeable file
with that name already, it will be overwritten**: no check is made, and no
warning given.)

### Convert a 'US letter' document to A4

Suppose we have a document made up of 'US letter' size pages, and we want to
convert it to A4:

``` sh
pdfjam 'my US letter file.pdf' --a4paper --outfile 'my A4 file.pdf'
```

### Handouts from presentation slides

A useful application of `pdfjam` is for producing a handout from a file of
presentation slides. For slides made with the standard 4:3 aspect ratio a nice
6-up handout on A4 paper can be made by

``` sh
pdfjam --nup 2x3 --frame true --noautoscale false --delta "0.2cm 0.3cm" --scale 0.95 myslides.pdf --outfile myhandout.pdf
```

The `--delta` option here comes from the pdfpages package; the `--scale` option
is passed to LaTeX's `\includegraphics` command.

Slides made by LaTeX's *beamer* package, using the `handout` class option, work
especially nicely with this! The example wrapper scripts `pdfjam-slides3up` and
`pdfjam-slides6up`, in the
[pdfjam-extras](https://github.com/pdfjam/pdfjam-extras) repository, are for
3-up and 6-up handouts, respectively.

### Trimming pages; and piped output

Suppose we want to trim the pages of our input file prior to n-upping. This can
be done by using a pipe:

``` sh
pdfjam myfile.pdf --trim '1cm 2cm 1cm 2cm' --clip true --outfile /dev/stdout | pdfjam --nup 2x1 --frame true --outfile myoutput.pdf
```

The `--trim` option specifies an amount to trim from the left, bottom, right and
top sides respectively; to work as intended here it needs also `--clip true`.
These (i.e., `trim` and `clip`) are in fact options to LaTeX's
`\includegraphics` command (in the standard *graphics* package).

Thanks go to Christophe Lange and Christian Lohmaier for suggesting an example
on this.

### Output pages suitable for binding

To offset the content of double-sided printed pages so that they are suitable
for binding with a [Heftstreifen](https://de.wikipedia.org/wiki/Heftstreifen),
use the `--twoside` option:

``` sh
pdfjam --twoside myfile.pdf --offset '1cm 0cm' --suffix 'offset'
```

### Input file with nonstandard name

To use PDF input files whose names do not end in '`.pdf`', you will need to use
the `--checkfiles` option. This depends on the availability of the `file`
utility, with support for the options `-Lb`; this can be checked by trying

``` sh
file -Lb 'my PDF file'
```

where `'my PDF file'` is the name of a PDF file on your system. The result
should be something like '`PDF document, version 1.4`' (possibly with a
different version number).

With '`file -Lb`' available, we can use PDF files whose names lack the usual
'`.pdf`' extension. For example,

``` sh
pdfjam --nup 2x1 --checkfiles 'my PDF file'
```

will result in a file named '`my PDF file-2x1.pdf`' in the current working
directory.

### Rotate every 2nd page

If you want to print a landscape-oriented PDF document on both sides of the
paper, using a duplex printer that does not have 'tumble' capability, make a new
version with every second page rotated for printing:

``` sh
pdfjam --landscape --doublepagestwistodd true my-landscape-document.pdf
```

## Configuration

You can configure pdfjam to your needs by putting a file called `pdfjam.conf` in
any directory specified by `pdfjam --configpath` or a `.pdfjam.conf` in your
home directory. See the `pdfjam.conf` coming with your installation or
[online](https://github.com/pdfjam/pdfjam/blob/master/doc/pdfjam.conf) for a
list of available configuration variables.

For setting the default paper size, also consider configuring (or installing)
[libpaper](https://github.com/rrthomas/libpaper).

## Troubleshooting

<!-- TODO: Are any of those relevant any more? -->

- The script runs but the output doesn't look the way it should. Why?

  Most likely either your pdfTeX or your pdfpages installation is an old
  version. You could check also that `pdftex.def`, typically to be found in
  `.../texmf/tex/latex/graphics/`, is up to date. If the problem persists even
  with up-to-date versions of pdfTeX, `pdftex.def` and pdfpages, then please do
  report it.

- What can I do to solve a “Too many open files” error?

  This error has been reported to occur sometimes, when dealing with large
  numbers of documents/pages. A [suggested
  solution](https://stackoverflow.com/questions/1715677/error-too-many-open-files-in-pdflatex),
  if this happens, is to include additionally (in the call to `pdfjam`):

  ``` sh
  --preamble '\let\mypdfximage\pdfximage \def\pdfximage{\immediate\mypdfximage}'
  ```

- Minor details of the font got missing in the output. Why?

  Sometimes font information (such as ligatures) is lost from the output of
  `pdfjam`. It seems that a fairly simple fix when this happens is to add the
  option `--preamble '\pdfinclusioncopyfonts=1'` in your call to `pdfjam`.

- My `--preamble '\usepackage[...]{geometry}'` causes failure. What shall I do?

  The `geometry` package gets already loaded by pdfjam, so just use
  `\geometry{}` for any further settings.

- My `--preamble '\usepackage[...]{color}'` does not work. What to do?

  Either do not use in conjunction with `--pagecolor` or use with `--pagecolor`,
  but then do not load the *color* package again.

## Reporting bugs

Please report any bugs found in `pdfjam` [on
GitHub](https://github.com/pdfjam/pdfjam/issues).

## Developing

This project uses [l3build](https://ctan.org/pkg/l3build) for building
(`l3build unpack`), testing (`l3build check`) and installing
(`l3build install`). See the first few lines of `build.lua` for more
information.

## The History of *pdfjam*

The first versions of PDFjam were made by [David
Firth](http://warwick.ac.uk/dfirth) with the first release of the `pdfnup`
script dating back to 2002-04-04 and the name PDFjam debuting with the 1.0
release on 2004-05-07. Several releases followed until version 2.08 on
2010-11-14.

Nine years later — on 2019-11-14 — David Firth published an overhauled version
3.02, now called pdfjam (in lower letters). The next November, maintenance went
over to [Reuben Thomas](https://rrt.sc3d.org) were it remained until November
2024, when [Markus Kurtz](https://mgkurtz.de) took over.

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
> broken out the wrapper scripts into a separate repository, *unsupported* ---
> so that people can still see and use/adapt them if they want. And maybe even
> someone else will want to take on the task of improving and maintaining some
> of them, who knows? The wrapper scripts (**no longer maintained**) can now be
> found at <https://github.com/pdfjam/pdfjam-extras>.

For historic release notes, see the `README.md` as of [pdfjam
v3.04](https://github.com/pdfjam/pdfjam/tree/v3.04).

Releases from version 1.0 up to version 2.08 are still available at
<https://pdfjam.github.io/pdfjam>. For any releases after that, see
<https://github.com/pdfjam/pdfjam/releases>.
