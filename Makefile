
all: docs

docs:
	terraform-docs markdown table --header-from header.txt . > README.md