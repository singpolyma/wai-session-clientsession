GHCFLAGS=-Wall -XNoCPP -fno-warn-name-shadowing -XHaskell98 -O2
HLINTFLAGS=-XHaskell98 -XNoCPP -i 'Use camelCase' -i 'Use String' -i 'Use head' -i 'Use string literal' -i 'Use list comprehension' --utf8
VERSION=0.1

.PHONY: all shell clean doc install

all: report.html doc dist/build/libHSwai-session-clientsession-$(VERSION).a dist/wai-session-clientsession-$(VERSION).tar.gz

install: dist/build/libHSwai-session-clientsession-$(VERSION).a
	cabal install

shell:
	ghci $(GHCFLAGS)

report.html: Network/Wai/Session/ClientSession.hs
	-hlint $(HLINTFLAGS) --report $^

doc: dist/doc/html/wai-session-clientsession/index.html README

README: wai-session-clientsession.cabal
	tail -n+$$(( `grep -n ^description: $^ | head -n1 | cut -d: -f1` + 1 )) $^ > .$@
	head -n+$$(( `grep -n ^$$ .$@ | head -n1 | cut -d: -f1` - 1 )) .$@ > $@
	-printf ',s/        //g\n,s/^.$$//g\n,s/\\\\\\//\\//g\nw\nq\n' | ed $@
	$(RM) .$@

dist/doc/html/wai-session-clientsession/index.html: dist/setup-config Network/Wai/Session/ClientSession.hs
	cabal haddock --hyperlink-source

dist/setup-config: wai-session-clientsession.cabal
	cabal configure

clean:
	find -name '*.o' -o -name '*.hi' | xargs $(RM)
	$(RM) -r dist

dist/build/libHSwai-session-clientsession-$(VERSION).a: dist/setup-config Network/Wai/Session/ClientSession.hs
	cabal build --ghc-options="$(GHCFLAGS)"

dist/wai-session-clientsession-$(VERSION).tar.gz: README dist/setup-config Network/Wai/Session/ClientSession.hs
	cabal check
	cabal sdist
