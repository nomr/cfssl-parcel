TAG:=$(shell git describe --tags | sed -e 's/^v//')
TAG_DIST=$(shell echo $(TAG) | sed -r -e 's/.*-([[:digit:]]+)-g.*/\1/')
TAG_HASH=$(shell echo $(TAG) | sed -r -e 's/^.*(g[0-9a-f]+|$$)/\1/')

PKG=PKI
PKG_VERSION=$(shell echo $(TAG) | sed -r -e 's/\+.*//')
JQ_VERSION=1.5
VERSION=$(subst +,-,$(TAG))
GOPATH=$(PWD)/$(PKG)-$(VERSION)

ifeq ($(TRAVIS), true)
  DISTROS=el7
else
  DISTROS=el7
endif
PARCELS=$(foreach DISTRO,$(DISTROS),$(PKG)-$(VERSION)-$(DISTRO).parcel)

.INTERMEDIATE: %-SHA256
.DELETE_ON_ERROR:
.PHONY: release cfssl

all: info release

info:
	@echo '       Git Tag: $(TAG)'
	@[ ! -z $(TAG) ]
	@echo '      Tag dist: $(TAG_DIST)'
	@echo '      Tag hash: $(TAG_HASH)'
	@echo '   PKG version: $(PKG_VERSION)'
	@echo 'Parcel version: $(VERSION)'
	@echo '       Parcels: $(PARCELS)'

clean:
	rm -rf release $(PKG)-* registry-$(PKG_VERSION)

release: $(foreach PARCEL,$(PARCELS),release/$(PARCEL)) release/manifest.json

%/manifest.json: make_manifest.py
	@mkdir -p $(shell dirname $@)
	python make_manifest.py $(shell dirname $@)

$(PKG)-$(VERSION)-%.parcel: $(PKG)-$(VERSION).parcel
	@mkdir -p $(shell dirname $@)
	ln $< $@
	java -jar validator.jar -f $@

$(PKG)-$(VERSION).parcel: $(PKG)-$(VERSION)/meta
	@mkdir -p $(shell dirname $@)
	tar zcvf $@ --owner root --group=root $(shell dirname $<)

$(PKG)-$(VERSION)/meta: $(PKG)-$(VERSION) meta validator.jar
	@mkdir $@
	cp meta/pki_env.sh $@
	cp meta/alternatives.json $@
	cat meta/parcel.json | jq ".version=\"$(VERSION)\"" > $@/parcel.json
	java -jar validator.jar -p $@/parcel.json || (rm -rf $@ && false)
	java -jar validator.jar -a $@/alternatives.json || (rm -rf $@ && false)

$(PKG)-$(VERSION): jq-$(JQ_VERSION)-linux64
	rm -rf $@
	mkdir -p $@
	go get github.com/GeertJohan/go.rice/rice
	go get -u -d github.com/cloudflare/cfssl/cmd/...
	cd $(GOPATH)/src/github.com/cloudflare/cfssl && $(GOPATH)/bin/rice embed-go -i=./cli/serve
	cd ../../../../..
	go install github.com/cloudflare/cfssl/cmd/...
	rm -rf $(GOPATH)/bin/rice $(GOPATH)/src $(GOPATH)/pkg
	mv jq-$(JQ_VERSION)-linux64 $@/bin/jq


# Remote dependencies
validator.jar:
	cd tools/cm_ext && mvn -q install && cd -
	ln tools/cm_ext/validator/target/validator.jar .

make_manifest.py:
	ln tools/cm_ext/make_manifest/make_manifest.py

jq-$(JQ_VERSION)-linux64: jq-$(JQ_VERSION)-SHA256
	wget 'https://github.com/stedolan/jq/releases/download/jq-$(JQ_VERSION)/jq-linux64' -O $@
	touch $@
	sha256sum -c $<

# Implicit rules
%-SHA256: SHA256SUMS
	grep $(subst -SHA256,,$@) SHA256SUMS > $@

%: %.tar.gz
	tar --no-same-permission --no-same-owner -zxvf $<
	find $@/lib -type f -exec chmod o+r {} \;
