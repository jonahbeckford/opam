TAG = master
VERSION = $(shell git describe $(TAG))
OPAM_VERSION = $(subst -,~,$(VERSION))
GIT_URL = ..

FULL_ARCHIVE_URL = https://github.com/ocaml/opam/releases/download/$(VERSION)/opam-full-$(VERSION).tar.gz

TARGETS = x86_64-linux i686-linux armhf-linux arm64-linux

OCAMLV = 4.13.1
# currently hardcoded in Dockerfile.in
OCAML_URL = https://caml.inria.fr/pub/distrib/ocaml-$(basename $(OCAMLV))/ocaml-$(OCAMLV).tar.gz

HOST_OS = $(shell uname -s | tr A-Z a-z | sed 's/darwin/macos/')
HOST = $(shell uname -m | sed 's/amd64/x86_64/')-$(HOST_OS)
OUTDIR = out/$(TAG)

all: $(patsubst %,$(OUTDIR)/opam-$(VERSION)-%,$(TARGETS))

$(OUTDIR)/opam-full-$(VERSION).tar.gz:
	mkdir -p "$(OUTDIR)"
	cd "$(OUTDIR)" && curl -OfL $(FULL_ARCHIVE_URL) || { \
	  git clone $(GIT_URL) -b $(TAG) --depth 1 opam-full-$(VERSION); \
	  sed 's/^AC_INIT(opam,.*)/AC_INIT(opam,$(OPAM_VERSION))/' opam-full-$(VERSION)/configure.ac > \
	    opam-full-$(VERSION)/configure.ac.tmp; \
	  mv opam-full-$(VERSION)/configure.ac.tmp \
	    opam-full-$(VERSION)/configure.ac; \
	  $(MAKE) -C opam-full-$(VERSION) configure download-ext; \
	  tar cz --exclude-vcs opam-full-$(VERSION) -f $(notdir $@); \
	  rm -rf opam-full-$(VERSION); \
	}

build/Dockerfile.x86_64-linux: Dockerfile.in
	mkdir -p build && sed 's/%TARGET_TAG%/x86_64-v3.13/g' $^ | sed 's/%CONF%//g' >$@
build/Dockerfile.i686-linux: Dockerfile.in
	mkdir -p build && sed 's/%TARGET_TAG%/x86-v3.13/g' $^ | sed 's/%CONF%/-build i586-alpine-linux-musl/g' >$@

# Need to lie about gnueabihf instead of musleabihf, because of a ./configure bug
build/Dockerfile.armhf-linux: Dockerfile.in
	mkdir -p build && sed 's/%TARGET_TAG%/armv7-v3.13/g' $^ | sed 's/%CONF%//g' >$@
build/Dockerfile.arm64-linux: Dockerfile.in
	mkdir -p build && sed 's/%TARGET_TAG%/arm64-v3.13/g' $^ | sed 's/%CONF%//g' >$@


build/%.image: build/Dockerfile.%
	docker build -t opam-build-$* -f $^ build
	touch $@

# Actually, this is for alpine 3.13, and varies
CLINKING_linux = \
-Wl,-Bstatic \
-lunix -lmccs_stubs -lmccs_glpk_stubs -lsha_stubs \
-lstdc++ \
-static-libgcc \
-static
# -Wl,-Bdynamic 

CLINKING_macos = \
-lunix -lmccs_stubs -lmccs_glpk_stubs -lsha_stubs \
-lstdc++

CLINKING_openbsd = $(CLINKING_macos)

LINKING = (-noautolink $(patsubst %,-cclib %,$(CLINKING_$(1))))

EXPORTS_openbsd = \
CPATH=/usr/local/include: \
LIBRARY_PATH=/usr/local/lib: \


%: opam-$(VERSION)-%

opam-$(VERSION)-%: $(OUTDIR)/opam-$(VERSION)-%
	ln -sf $^ $@

# host: opam-$(VERSION)-$(HOST)

# Build for the local host. Containerised builds, below, are preferred, but not always available
build/$(HOST).env:
	mkdir -p build/$(HOST)
	cd build/$(HOST) && curl -OL $(OCAML_URL)
	cd build/$(HOST) && tar xzf ocaml-$(OCAMLV).tar.gz
	cd build/$(HOST)/ocaml-$(OCAMLV) && \
	  ./configure -prefix $(shell pwd)/build/$(HOST) && \
	  $(MAKE) world opt.opt && \
	  $(MAKE) install
	rm -rf build/$(HOST)/ocaml-$(OCAMLV) build/$(HOST)/ocaml-$(OCAMLV).tar.gz
	touch $@

# Actually builds $(OUTDIR)/opam-$(VERSION)-$(HOST), but we don't want to override the
# rule that goes through a container
host: $(OUTDIR)/opam-full-$(VERSION).tar.gz build/$(HOST).env
	rm -rf build/opam-full-$(VERSION)
	cd build && tar xzf ../$<
	( export \
	    PATH=$(shell pwd)/build/$(HOST)/bin:$$PATH \
	    MAKE=$(MAKE) \
	    $(EXPORTS_$(HOST_OS)); \
	  cd build/opam-full-$(VERSION) && \
	  ./configure && \
	  { $(MAKE) lib-ext || ./configure --with-vendored-deps; } && \
	  echo "$(call LINKING,$(HOST_OS))" >src/client/linking.sexp && \
	  $(MAKE) opam; \
	)
	cp build/opam-full-$(VERSION)/opam $(OUTDIR)/opam-$(VERSION)-$(HOST)
	strip $(OUTDIR)/opam-$(VERSION)-$(HOST)
	rm -rf build/opam-full-$(VERSION)

# Containerised builds
$(OUTDIR)/opam-$(VERSION)-%-linux: $(OUTDIR)/opam-full-$(VERSION).tar.gz build/%-linux.image
	docker run --rm -i \
	  -e "VERSION=$(VERSION)" \
	  -e "TARGET=$*-linux" \
	  -e "LINKING=$(call LINKING,$(HOST_OS))" \
	  opam-build-$*-linux \
	  <$< >$@

clean:
	rm -rf build

distclean: clean
	rm -rf out

REMOTE_DIR = /tmp/opam-release
REMOTE_MAKE = make
remote: $(OUTDIR)/opam-full-$(VERSION).tar.gz
	ssh "$(REMOTE)" "mkdir -p $(REMOTE_DIR)/${OUTDIR}"
	scp Makefile "$(REMOTE):$(REMOTE_DIR)/"
	scp "$^" "$(REMOTE):$(REMOTE_DIR)/$^"
	ssh "$(REMOTE)" 'sh -c "cd $(REMOTE_DIR) && ulimit -s 8192 && $(REMOTE_MAKE) host TAG=$(TAG) VERSION=$(VERSION) OCAMLV=$(OCAMLV)"'
	scp "$(REMOTE):$(REMOTE_DIR)/$(OUTDIR)/opam-$(VERSION)*" "$(OUTDIR)/"
