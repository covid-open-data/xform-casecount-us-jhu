.PHONY: run-xform
run-xform:
	cd .github/actions/run-xform; make dc-up; cd -


.PHONY: run-xform-build
run-xform-build:
	cd .github/actions/run-xform; make dc-up-build; cd -


.PHONY: run-xform-build-no-cache
run-xform-build-no-cache:
	cd .github/actions/run-xform; make dc-build-no-cache; cd -

