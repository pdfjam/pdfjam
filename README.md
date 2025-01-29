![GitHub CI](https://github.com/pdfjam/pdfjam/actions/workflows/ci.yml/badge.svg)

pdfjam
===

_Reuben Thomas_ <https://rrt.sc3d.org>, _Markus Kurtz_ <_anything_ at mgkurtz.de>

A snapshot of this page is included as _README.md_
in the distributed package.  The most up-to-date version is maintained online at
<https://github.com/pdfjam/pdfjam>.

1. [Overview](#overview)
    - [What is pdfjam?](#whatis)
    - [Wrapper scripts no longer included here](#wrappers)
2. [Pre-requisites](#prereq)
3. [Documentation](#documentation)
4. [Installation](#install)
5. [Configuration](#config)
6. [Using pdfjam](#using)
7. [FAQ](#faq)
8. [Reporting bugs](#bugs)
9. [Version history](#history)


# <a name="overview"> Overview

## <a name="whatis"> What is pdfjam?

The **pdfjam** package makes available the `pdfjam` shell script that provides a
simple interface to much of the functionality of the excellent
[pdfpages](https://www.ctan.org/tex-archive/macros/latex/contrib/pdfpages)
package (by Andreas Matthias) for _LaTeX_. The `pdfjam` script takes one
or more PDF files (and/or JPG/PNG graphics files) as input, and produces
one or more PDF files as output. It is useful for joining files together,
selecting pages, reducing several source pages onto one output page, etc., etc.

A potential drawback of `pdfjam` and other scripts based upon it is that any
hyperlinks in the source PDF are lost.

`pdfjam` is designed for Unix-like systems, including Linux and Mac OS X.
It seems that it will work also on Windows computers with a suitable
installation of [Cygwin](https://www.cygwin.com) (with TeX Live
installed), but this has not been thoroughly tested.

Alternatives to `pdfjam` which are widely packaged in GNU/Linux distributions and other free software collections include:

* [PDFtk](https://www.pdflabs.com/tools/pdftk-the-pdf-toolkit/) (Java-based)
* [PDFsam](https://pdfsam.org) (Java-based)
* [PSPDFUtils](https://pypi.org/project/pspdfutils/) (Python-based, also supports PostScript files)

Those alternatives do many of the same things as `pdfjam`, and maybe
quite a bit more too.

The **pdfjam** software is made available free, under GPL version 2 (see the
file named `COPYING` that is included with the package).
It comes with **ABSOLUTELY NO WARRANTY** of fitness for any purpose whatever.

## <a name="wrappers"> Wrapper scripts no longer included here

Previous versions of **pdfjam** (before 3.02) included some _other_ scripts too,
in addition to the `pdfjam` script iteslf.
Those other scripts are simple wrappers for calls to `pdfjam`, designed to perform
some common tasks such as joining or n-upping PDF files or to illustrate
other features; they are not very elaborate, and nor are they extensively tested.
They are probably best viewed as simple templates that can be used for
constructing more elaborate wrapper scripts as required.

Those 'wrapper' scripts are **no longer maintained**. I continue to make
them available in a separate repository
<https://github.com/pdfjam/pdfjam-extras>,
in case anyone wants to see them, to use them, or to improve and maintain
them independently as a separate project.

The specific wrapper scripts that were removed from the **pdfjam** package
at version 3.02 are:

- `pdfnup`, `pdfpun`
- `pdfjoin`
- `pdf90`, `pdf180`, `pdf270`
- `pdfflip`
- `pdfbook`
- `pdfjam-pocketmod`
- `pdfjam-slides3up`, `pdfjam-slides6up`

For those scripts and for more information on them, please now see
<https://github.com/pdfjam/pdfjam-extras>.


# <a name="prereq"> Pre-requisites

- A Unix-like operating system (Linux, Mac OS X, FreeBSD, etc.; possibly Cygwin)
- A working, up-to-date installation of LaTeX (including at least one of
  `pdflatex`, `lualatex` or `xelatex`)
- A working installation of the LaTeX package
  [**pdfpages**](https://www.ctan.org/tex-archive/macros/latex/contrib/pdfpages)
  (version 0.4f or later)
  and
[**geometry**](https://www.ctan.org/tex-archive/macros/latex/contrib/geometry).

With [libpaper](https://github.com/rrthomas/libpaper) installed, `pdfjam` will be able to find your default paper size, which you can configure if desired.

For some years now, **pdfjam** has been included in the _TeX Live_ distribution,
which includes all the necessary programs and packages to make `pdfjam` run smoothly.
If you have the necessary bandwidth and disk space for it, I do recommend installing
[_TeX Live_](https://tug.org/texlive/).

# <a name="documentation"></a> Documentation

The primary documentation for `pdfjam` is obtained (after installation of `pdfjam`)
via the command

```
pdfjam --help
```

This gives information on the arguments to `pdfjam`, and the default settings
that apply at your installation.  In addition to the arguments that are explicitly
documented there, `pdfjam` provides access to all of the options of the
**pdfpages** package: that's a large number of options, and it's a set of options
that might change, so users are referred to the current
[pdfpages manual (PDF)](https://www.ctan.org/tex-archive/macros/latex/contrib/pdfpages/pdfpages.pdf) to see what's available.

In case you want to look at the `pdfjam --help` text template online, for example
before you decide whether to install **pdfjam**, the source is available at
<https://github.com/pdfjam/pdfjam/blob/master/doc/pdfjam-help.txt>.

There is also a (very basic) `man` page, accessed in the usual way
(after installation) by

```
man pdfjam
```

# <a name="install"></a> Installation

There are two main ways:

1. Install the [current _TeX Live_ distribution](https://tug.org/texlive/)
(how you do this will depend on details of your operating system).
_TeX Live_ will already contain a recent release of **pdfjam**.
Many thanks to Karl Berry
for setting up and maintaining **pdfjam** as a _CTAN_ package that is part of
_TeX Live_.

2.  Install it yourself (e.g., if you don't want _TeX Live_, or if you want a later
release of **pdfjam** than the one that's currently in _TeX Live_).
Download the latest packaged release of **pdfjam** from
<https://github.com/pdfjam/pdfjam/releases>.
If for some reason you don't want the latest released version, or even a recently released version, you can still get older versions too: see <https://davidfirth.github.io/pdfjam>.

**The first way, via _TeX Live_, is recommended** as the easiest way for most users.

If you go the second way, then you will have a bit more to do:

- The `pdfjam` shell script in the _bin_ sub-directory of the released package
  should be  placed on the `PATH` of anyone who needs to use it.
- The `man` file in the _man1_ sub-directory should be installed on the `MANPATH`
  of all who might need to read it.

# <a name="config"></a> Configuration

On many unix-like systems `pdfjam` should run without any further configuration,
provided that the pre-requisite TeX installation (such as _TeX Live_) is present.
If you want to  check (e.g., prior to installation) that `pdfjam` will work on
your system, then

- unzip the `tests.zip` archive (inside the package)
- `cd` to your newly made `tests` sub-directory and follow the instructions that appear there in `README_tests.md`.

If configuration _is_ needed, this can be done through a site-wide or
user-specific configuration file. This might be necessary if, for example, your
site has a non-standard TeX installation, or a non-standard location for
temporary files, or a specific paper size for output PDFs ---
or some other reason.

The file
[pdfjam.conf](https://github.com/pdfjam/pdfjam/raw/master/doc/pdfjam.conf)
is a sample configuration file which can be edited as needed.  After editing,
either install the file for site-wide use (e.g. at `/etc/pdfjam.conf`) or as a
user-defaults file at `~/.pdfjam.conf` or `~/.config/pdfjam.conf`.  User
settings override corresponding settings made in a site-wide configuration
file.

For example, if you prefer to use `/usr/bin/xelatex` as your default LaTeX engine
(in place of the standard `pdflatex`), and you want your output page size to be
"US letter" size paper by default, you would simply include the lines

```
latex=/usr/bin/xelatex
paper=letterpaper
```

in a plain text file named  '`.pdfjam.conf`' in your home directory.
The path `usr/bin/xelatex` specifies exactly _which_ LaTeX program will be
used: it could be a path to any one of the `pdflatex`, `lualatex` or
`xelatex` executables.  (You can get the full path to an executable
by, for example, the command `which xelatex`.)
The code word `letterpaper` is how LaTeX refers to that particular page size.
For other available paper sizes, and all the many
other options that could be set as defaults if you want, please see the output of

```
pdfjam --help
```

On some systems it might even be necessary to change the list of places
(i.e., `/etc/pdfjam.conf` and others) that is searched for site-wide
configuration files.  This can only be done by editing the `pdfjam` script
itself.  To see which directories on _your_ system are searched for a file
named `pdfjam.conf`, look at the output of

```
pdfjam --configpath
```

# <a name="using"></a> Using pdfjam

For a full overview of what `pdfjam` can do, the importance of the
[pdfpages manual (PDF)](https://www.ctan.org/tex-archive/macros/latex/contrib/pdfpages/pdfpages.pdf)
cannot be stressed enough!
The following examples merely serve as a brief introduction.

### Example 1: Batch 2-upping of documents

Consider converting each of two documents to a side-by-side "2-up" format.
Since we want the two documents to be processed separately, we'll use the
`--batch` option:

```
pdfjam --batch --nup 2x1 --suffix 2up --landscape file1.pdf file2.pdf
```

This will produce new files `file1-2up.pdf` and `file2-2up.pdf` in the current
working directory.

### Example 2: Merging pages from 2 documents

Suppose we want a single new document which puts together selected pages from two different files:

```
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

### Example 3: A 4-up document with frames

To make a portrait-oriented 4-up file from the pages of three input files,
with a thin-line frame around the input pages:

```
pdfjam file1.pdf file2.pdf file3.pdf --no-landscape --frame true --nup 2x2 --suffix 4up --outfile ~/Documents
```

Here a _directory_ was specified at `--outfile`: the resultant file in this
case will be `~/Documents/file3-4up.pdf`.
(Note that **if there's a writeable file with that name already, it will be
overwritten**: no check is made, and no warning given.)

### Example 4: Convert a 'US letter' document to A4

Suppose we have a document made up of 'US letter' size pages,
and we want to convert it to A4:

```
pdfjam 'my US letter file.pdf' --a4paper --outfile 'my A4 file.pdf'
```

### Example 5: Handouts from presentation slides

A useful application of `pdfjam` is for producing a handout from a file of
presentation slides. For slides made with the standard 4:3 aspect ratio a
nice 6-up handout on A4 paper can be made by

```
pdfjam --nup 2x3 --frame true --noautoscale false --delta "0.2cm 0.3cm" --scale 0.95 myslides.pdf --outfile myhandout.pdf
```

The `--delta` option here comes from the pdfpages package; the `--scale`
option is passed to LaTeX's `\includegraphics` command.

Slides made by LaTeX's _beamer_ package, using the `handout` class option,
work especially nicely with this! The example wrapper scripts `pdfjam-slides3up`
and `pdfjam-slides6up`, in the
[pdfjam-extras](https://github.com/pdfjam/pdfjam-extras) repository,
are for 3-up and 6-up handouts, respectively.

### Example 6: Trimming pages; and piped output

Suppose we want to trim the pages of our input file prior to n-upping.
This can be done by using a pipe:

```
pdfjam myfile.pdf --trim '1cm 2cm 1cm 2cm' --clip true --outfile /dev/stdout | pdfjam --nup 2x1 --frame true --outfile myoutput.pdf
```

The `--trim` option specifies an amount to trim from the left, bottom, right and
top sides respectively; to work as intended here it needs also `--clip true`.
These (i.e., `trim` and `clip`) are in fact options to LaTeX's
`\includegraphics` command (in the standard _graphics_ package).

Thanks go to Christophe Lange and Christian Lohmaier for suggesting
an example on this.

### Example 7: Output pages suitable for binding

To offset the content of double-sided printed pages so that they are
suitable for binding with a
[Heftstreifen](https://de.wikipedia.org/wiki/Heftstreifen), use
the `--twoside` option:

```
pdfjam --twoside myfile.pdf --offset '1cm 0cm' --suffix 'offset'
```

### Example 8: Input file with nonstandard name

To use PDF input files whose names do not end in '`.pdf`', you will need to use
the `--checkfiles` option. This depends on the availability of the `file`
utility, with support for the options `-Lb`; this can be checked by trying

```
file -Lb 'my PDF file'
```

where `'my PDF file'` is the name of a PDF file on your system.
The result should be something like '`PDF document, version 1.4`'
(possibly with a different version number).

With '`file -Lb`' available, we can use PDF files whose names lack the usual
'`.pdf`' extension.  For example,

```
pdfjam --nup 2x1 --checkfiles 'my PDF file'
```

will result in a file named '`my PDF file-2x1.pdf`'
in the current working directory.

### Example 9: Rotate every 2nd page

If you want to print a landscape-oriented PDF document on both sides of the paper,
using a duplex printer that does not have 'tumble' capability, make a new version
with every second page rotated for printing:

```
pdfjam --landscape --doublepagestwistodd true my-landscape-document.pdf
```


# <a name="faq"></a> FAQ


**1. The script runs but the output doesn't look the way it should. Why?**

Most likely either your pdfTeX or your pdfpages installation is an old version.
You could check also that `pdftex.def`, typically to be found in
`.../texmf/tex/latex/graphics/`,
is up to date. If the problem persists even with up-to-date versions of pdfTeX,
`pdftex.def` and pdfpages, then please do report it.

**2. What can I do to solve a 'Too many open files' error?**

This error has been reported to occur sometimes, when dealing with large numbers of
documents/pages. A suggested solution, if this happens,
is to include additionally (in the call to `pdfjam`):

```
--preamble '\let\mypdfximage\pdfximage \def\pdfximage{\immediate\mypdfximage}'
```

See for example
<https://stackoverflow.com/questions/1715677/error-too-many-open-files-in-pdflatex>
for this suggestion and links to more information.

# <a name="bugs"></a> Reporting bugs

Please report any bugs found in `pdfjam` by reporting as an issue at GitHub:
<https://github.com/pdfjam/pdfjam/issues>

# Developing

This project uses [l3build](https://ctan.org/pkg/l3build). See the header of
`build.lua` for more information.

### Some known problems:

- Sometimes font information (such as ligatures) is lost from the output of
  `pdfjam`.  It seems that a fairly simple fix when this happens is to add the
  option `--preamble '\pdfinclusioncopyfonts=1'` in your call to `pdfjam`.
- In _Cygwin_, using `pdfjam` in a pipeline does not seem to work.
  The problem seems to be with _Cygwin_'s handling of file descriptors
  within pipelines.
- The `--preamble` option can sometimes clash with other elements of the LaTeX
  preamble.  Some specific things to watch out for:
    + If the preamble needs to set further options to the _geometry_ package, be sure to use the `\geometry{}` command for that.
    + If options to the _color_ package are to be specified in the preamble,
      do not at the same time use the `--pagecolor` option to `pdfjam`.


#  <a name="history"> Version history

### Overview of the history

This all grew originally from a script named `pdfnup`. That was later joined,
in a published package called 'PDFjam', by two further scripts `pdfjoin` and
`pdf90`.

At version 2.00, everything was unified through a single script `pdfjam`, with
many more options. Along with `pdfjam` various 'wrapper' scripts --- i.e.,
other scripts that use `pdfjam` in different ways --- were provided, mainly as
examples.

From version 3.02, the extra 'wrapper' scripts are removed from the package,
mainly because they are hard to maintain: different users want different
things, and `pdfjam` itself provides all the options in any case. So I have
broken out the wrapper scripts into a separate repository, _unsupported_ ---
so that people can still see and use/adapt them if they want.
And maybe even someone else will
want to take on the task of improving and maintaining some of them,
who knows?  The wrapper scripts (**no longer maintained**) can now be found at
<https://github.com/pdfjam/pdfjam-extras>.

_Releases up to version 2.08 are still available at <https://pdfjam.github.io/pdfjam>._
