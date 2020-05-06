.PHONY: dc-up
dc-up:
	sudo docker-compose up


.PHONY: dc-up-build
dc-up-build:
	sudo docker-compose up --build
