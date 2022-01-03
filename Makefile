#
#
#

NAME := gpx-tools
INSTALLROOT := installdir
INSTALLBIN := $(INSTALLROOT)/usr/local/bin
INSTALLLIB := $(INSTALLROOT)/usr/local/lib/site_perl

describe := $(shell git describe --always --dirty)
tarfile := $(NAME)-$(describe).tar.gz

all: test

PACKAGES := libxml-twig-perl libtext-csv-perl libdevel-cover-perl
PACKAGES += libio-string-perl
PACKAGES += libdatetime-format-strptime-perl
PACKAGES += liblist-moreutils-perl

build_dep:
	git submodule update --init
	apt-get install -y $(PACKAGES)

install: clean
	mkdir -p $(INSTALLBIN)
	cp -pr gpx_split $(INSTALLBIN)

tar: $(tarfile)

$(tarfile):
	$(MAKE) install
	tar -v -c -z -C $(INSTALLROOT) -f $(tarfile) .

clean:
	rm -rf $(INSTALLROOT)

cover:
	cover -delete
	COVER=true $(MAKE) test
	cover

test:
	./test_harness
