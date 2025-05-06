# Version 4.2
* Expand some character ranges for compatibility with BSD sed (#94).
# Version 4.1
* Man page now contains actual information.
* Add zsh completion file with completions for all relevant options.
* Improve support for non-pdf input files (eps, jpg, png).
* Keep original filenames if they consist of [A-Za-z0-9.-] only and are unique.

# Version 4.0
* Major version bumped to 4.00 to reflect major refactoring, and some minor
  backwards-incompatible changes.
* New co-maintainer.
* Several minor bug fixes.
* New option `--builddir path` to build in `path` instead of a temporary
  directory. Overwrites files in `path` without further notice.
* In the constructed tex file, included files are now referenced as
  `source-1.pdf` etc. instead of `/tmp/pdfjam-XXXXXX/source-1.pdf`.
  This improves reproducibility and allows referencing with hyperref.
* Put every `--preamble` argument on distinct line in tex file.
* Automatically add braces around values where necessary. Thus, one can now
  write `--papersize 7cm,3cm` and `--picturecommand '\put(20,20){Text}'`.
* Support libpaper1 in addition to libpaper2 to obtain system default paper.
* Support `--paper a4` etc. as alternative to `--paper a4paper`.
* Support `--papersize 595,842` as alternative to `--papersize 595bp,842bp`.
  Prevents people adding unit `pt` where they actually mean `bp`.
* Mirror page when `--papersize` and `--landscape` given.
* Renames duplex edge flipping options `--longedge` to `--otheredge` and
  `--shortedge` to `--no-otheredge` to reflect their actual behaviour.
* Support `--keepinfo --pdfauthor ''` to discard only the corresponding field
  while keeping the remaining pdfinfo.
* Adds lots of regression and integration tests.
