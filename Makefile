BMO_BASE   = https://bugzilla.mozilla.org
BMO_CONFIG = $(BMO_BASE)/bzapi/configuration
BMO_MODAL  = $(BMO_BASE)/rest/bug_modal/edit/900

generate_bmo_data.pl: generate_bmo_data_template.pl build_generate_bmo_data.pl modal.json configuration.json local
	carton exec ./build_generate_bmo_data.pl $< > $@

modal.json: pretty.pl Makefile local
	curl -s -L $(BMO_MODAL) | carton exec ./pretty.pl > $@

configuration.json: pretty.pl Makefile local
	curl -s -L $(BMO_CONFIG) | carton exec ./pretty.pl > $@

local: ./cpanm
	./cpanm -l local --installdeps --notest .

cpanm:
	curl -s -L https://cpanmin.us > $@
	chmod 755 $@

