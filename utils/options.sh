#!/bin/sh
echo PDFPAGES
sed -n 's/^\\define@key{pdfpages}{\([^}]*\)}.*$/\1/p' "$(kpsewhich pdfpages.sty)"
echo GRAPHICX
sed -n 's/^\\define@key{Gin}{\([^}]*\)}.*$/\1/p' "$(kpsewhich graphicx.sty)"
