.PHONY: all clean install uninstall

PREFIX := $(DESTDIR)$(or $(PREFIX),/usr/local)

all:
	nimble build -d=danger

clean:
	$(RM) -r bin

install:
	@{ \
	set -eux; \
	install -pDt$(PREFIX)/bin/ bin/dawgviz; \
	cd share/dawgviz/dawgviz/target/; \
	install -m644 -pDt$(PREFIX)/share/dawgviz/dawgviz/target/ -- *; \
	}

uninstall:
	$(RM) -r $(PREFIX)/bin/dawgviz $(PREFIX)/share/dawgviz/
