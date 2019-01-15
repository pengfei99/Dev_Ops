
SUFFIXES= .pod .man

MANARGS= -c 'User Manuals' -r 'Unix'

man1_MANS= $(MAN)

MAN= fqquality.man fqduplicate.man fqextract.man
POD= fqquality.pod fqduplicate.pod fqextract.pod

EXTRA_DIST= $(MAN) $(POD)

.pod.man:
	$(POD2MAN) $(MANARGS) $< >$@ && touch $@

## Maintainer parano checks

lint:
	for f in *.pod; do podchecker --warning --warning $$f; done
	-for f in *.man; do mandoc -Tlint $$f; done
