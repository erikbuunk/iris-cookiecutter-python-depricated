#################################################################################
# GLOBALS                                                                       #
#################################################################################
ROOT = $(shell pwd)
PROJECT_NAME = iris_cookiecutter
PYTHON_INTERPRETER = python3

# STATA3 or MacOS
PDFLATEX = /Library/TeX/texbin/pdflatex
STATA = /usr/local/stata/stata-mp -b do
R = /usr/local/bin/Rscript

#################################################################################
# PROJECT RULES                                                                 #
#################################################################################

## Install Python Dependencies
requirements: test_environment
	$(PYTHON_INTERPRETER) -m pip install -U pip setuptools wheel
	$(PYTHON_INTERPRETER) -m pip install -r requirements.txt

## Make Dataset
data:
	$(PYTHON_INTERPRETER) src/data/make_dataset.py data/external data/orig data/intermediate

## Make Features
features:
	$(PYTHON_INTERPRETER) src/features/build_features.py data/intermediate data/final

## Build Models and Predict
model:
	$(PYTHON_INTERPRETER) src/models/train_model.py data/final data/final
	$(PYTHON_INTERPRETER) src/models/predict_model.py data/final data/final

## Make Data Visualizations and tables
visualizations:
	$(PYTHON_INTERPRETER) src/visualization/visualize.py  data/orig results/figures results/tables

## Generate PDF from LateX sources
report:
	cd $(ROOT)/publication; $(PDFLATEX) LateX-template.tex

## Sample for running stata script
stata:
	$(STATA) src/stata/main.do

## Sample for running R script
r:
	$(R) src/r/main.r "$(ROOT)"


## Build everything from scratch
build: clean requirements data features model visualizations r report

## Delete compiled Python and other temporary files
clean:
	find . -type f -name "*.py[co]" -delete
	find . -type d -name "__pycache__" -delete
	find . -name "*.pkl" -delete
	find . -name "*.csv" -delete
	find . -name "*.data" -delete
	find . -name "*.names" -delete
	find . -name "*.log" -delete
	find . -name "*.aux" -delete
	find . -name "*.bbl" -delete
	find . -name "*.bcf" -delete
	find . -name "*.blg" -delete
	find . -name "*.nav" -delete
	find . -name "*.out" -delete
	find . -name "*.run.xml" -delete
	find . -name "*.snm" -delete
	find . -name "*.synctex.gz" -delete
	find . -name "*.toc" -delete

## Lint using Flake8 for code checking
lint:
	flake8 src


## Set up python interpreter environment
create_environment:
ifeq (True,$(HAS_CONDA))
		@echo ">>> Detected conda, creating conda environment."
ifeq (3,$(findstring 3,$(PYTHON_INTERPRETER)))
	conda create --name $(PROJECT_NAME) python=3
else
	conda create --name $(PROJECT_NAME) python=2.7
endif
		@echo ">>> New conda env created. Activate with:\nsource activate $(PROJECT_NAME)"
else
	$(PYTHON_INTERPRETER) -m pip install -q virtualenv virtualenvwrapper
	@echo ">>> Installing virtualenvwrapper if not already installed.\nMake sure the following lines are in shell startup file\n\
	export WORKON_HOME=$$HOME/.virtualenvs\nexport PROJECT_HOME=$$HOME/Devel\nsource /usr/local/bin/virtualenvwrapper.sh\n"
	@bash -c "source `which virtualenvwrapper.sh`;mkvirtualenv $(PROJECT_NAME) --python=$(PYTHON_INTERPRETER)"
	@echo ">>> New virtualenv created. Activate with:\nworkon $(PROJECT_NAME)"
endif

## Test if (Python) environment is setup correctly
test_environment:
	$(PYTHON_INTERPRETER) test_environment.py
# TODO: add R and Stata checks
# TODO: Add specific data download/upload scripts


#################################################################################
# Self Documenting Commands                                                     #
#################################################################################

.DEFAULT_GOAL := help

# Inspired by <http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html>
# sed script explained:
# /^##/:
# 	* save line in hold space
# 	* purge line
# 	* Loop:
# 		* append newline + line to hold space
# 		* go to next line
# 		* if line starts with doc comment, strip comment character off and loop
# 	* remove target prerequisites
# 	* append hold space (+ newline) to line
# 	* replace newline plus comments by `---`
# 	* print line
# Separate expressions are necessary because labels cannot be delimited by
# semicolon; see <http://stackoverflow.com/a/11799865/1968>
.PHONY: help
help:
	@echo "$$(tput bold)Available rules:$$(tput sgr0)"
	@echo
	@sed -n -e "/^## / { \
		h; \
		s/.*//; \
		:doc" \
		-e "H; \
		n; \
		s/^## //; \
		t doc" \
		-e "s/:.*//; \
		G; \
		s/\\n## /---/; \
		s/\\n/ /g; \
		p; \
	}" ${MAKEFILE_LIST} \
	| LC_ALL='C' sort --ignore-case \
	| awk -F '---' \
		-v ncol=$$(tput cols) \
		-v indent=19 \
		-v col_on="$$(tput setaf 6)" \
		-v col_off="$$(tput sgr0)" \
	'{ \
		printf "%s%*s%s ", col_on, -indent, $$1, col_off; \
		n = split($$2, words, " "); \
		line_length = ncol - indent; \
		for (i = 1; i <= n; i++) { \
			line_length -= length(words[i]) + 1; \
			if (line_length <= 0) { \
				line_length = ncol - indent - length(words[i]) - 1; \
				printf "\n%*s ", -indent, " "; \
			} \
			printf "%s ", words[i]; \
		} \
		printf "\n"; \
	}' \
	| more $(shell test $(shell uname) = Darwin && echo '--no-init --raw-control-chars')