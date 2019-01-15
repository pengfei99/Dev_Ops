
SUFFIXES= .pl

bin_PROGRAMS = fqquality fqextract
bin_SCRIPTS = fqduplicate
pkglibexec_PROGRAMS = fqduplicate2

fqquality_SOURCES = fqquality.c $(SRC)
fqextract_SOURCES = fqextract.c seqlist.c

fqduplicate2_SOURCES = fqduplicate2.c $(SRC)
fqduplicate2_LDADD = @MD5LIB@

SRC = fastq.c
HDR = fastq.h

CLEANFILES = $(bin_SCRIPTS)
EXTRA_DIST = $(HDR) fqduplicate.pl seqlist.h compat/err.h

.pl:
	sed -e 's,@XPERLX@,$(PERL),' \
	    -e 's,@pkglibexecdir@,$(pkglibexecdir),' $< >$@.tmp
	mv $@.tmp $@ && chmod +x $@

## Maintainer parano checks

LINTDEFS = $(DEFS) $(DEFAULT_INCLUDES) $(INCLUDES) $(AM_CPPFLAGS) $(CPPFLAGS)

lint:
	for f in *.c; do $(LINT) $(LINTFLAGS) $(LINTDEFS) $$f; done
	for f in *.pl; do $(PERL) -cw $$f; done

