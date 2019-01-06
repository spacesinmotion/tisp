# tisp - tiny lisp
# See LICENSE file for copyright and license details.

include config.mk

EXE = tisp
SRC = tisp.c main.c util.c extern/linenoise.c
TIB = tib/math.c
OBJ = $(SRC:.c=.o) $(TIB:.c=.o)
LIB = tib/libtibmath.so

all: options $(EXE)

options:
	@echo $(EXE) build options:
	@echo "CFLAGS  = $(CFLAGS)"
	@echo "LDFLAGS = $(LDFLAGS)"

.o:
	@echo $(LD) $@
	@$(LD) -o $@ $< $(LDFLAGS)

.c.o:
	@echo $(CC) $<
	@$(CC) -c -o $@ $< $(CFLAGS)

$(OBJ): config.h config.mk

config.h:
	@echo creating $@ from config.def.h
	@cp config.def.h $@

$(LIB): $(TIB)
	@echo $(CC) -o $@
	@gcc -shared -o $@ $(OBJ)

$(EXE): $(OBJ) $(LIB)
	@echo $(CC) -o $@
	@$(CC) -o $@ $(OBJ) $(LDFLAGS)

clean:
	@echo cleaning
	@rm -f $(OBJ) $(LIB) $(EXE) test test.o test.out

install: all
	@echo installing $(EXE) to $(DESTDIR)$(PREFIX)/bin
	@mkdir -p $(DESTDIR)$(PREFIX)/bin
	@cp -f $(EXE) $(DESTDIR)$(PREFIX)/bin
	@chmod 755 $(DESTDIR)$(PREFIX)/bin/$(EXE)
	@echo installing manual page to $(DESTDIR)$(MANPREFIX)/man1
	@mkdir -p $(DESTDIR)$(MANPREFIX)/man1
	@sed "s/VERSION/$(VERSION)/g" < $(EXE).1 > $(DESTDIR)$(MANPREFIX)/man1/$(EXE).1
	@chmod 644 $(DESTDIR)$(MANPREFIX)/man1/$(EXE).1
	@echo installing libraries to $(DESTDIR)$(PREFIX)/lib/tisp
	@mkdir -p $(DESTDIR)$(PREFIX)/lib/tisp
	@cp -f $(LIB) $(DESTDIR)$(PREFIX)/lib/tisp

uninstall:
	@echo removing $(EXE) from $(DESTDIR)$(PREFIX)/bin
	@rm -f $(DESTDIR)$(PREFIX)/bin/$(EXE)
	@echo removing manual page from $(DESTDIR)$(MANPREFIX)/man1
	@rm -f $(DESTDIR)$(MANPREFIX)/man1/$(EXE).1
	@echo removing libraries from $(DESTDIR)$(PREFIX)/lib/tisp
	@rm -rf $(DESTDIR)$(PREFIX)/lib/tisp/

test: $(OBJ) $(LIB) test.o
	@echo running tests
	@echo $(CC) -o test
	@$(CC) -o test tisp.o tib/math.o util.o test.o $(LDFLAGS)
	@./test

man:
	@echo -n updating man page $(EXE).1 ...
	@(head -1 README.md | sed "s/$(EXE)/$(EXE) 1 \"`date +%B\ %Y`\" \"$(EXE)\ $(VERSION)\"\n\n##NAME\n\n&/"; \
	  echo "\n##SYNOPSIS\n"; \
	  ./$(EXE) -h 2>&1 | sed -E 's/(\<[_A-Z][_A-Z]+\>)/\*\1\*/g' | \
	                     sed -E 's/(-[a-Z]+\>)/\*\*\1\*\*/g' | \
	                     sed -E 's/(\<$(EXE)\>)/\*\*\1\*\*/g' | \
	                     sed 's/_/\\_/g' | sed 's/:/:\ /g'| cut -d' ' -f2-; \
	  echo "\n##DESCRIPTION"; \
	  tail +2 README.md;) | \
	 md2roff - | sed "9s/]/]\ /g" | sed "9s/|/|\ /g" > $(EXE).1
	@echo \ done

.PHONY: all options clean install uninstall test man
