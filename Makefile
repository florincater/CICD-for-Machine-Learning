
install:
	@echo "Installing Python dependencies..."
	python -m pip install --upgrade pip setuptools
	@if [ -f requirements.txt ]; then python -m pip install -r requirements.txt; fi

format:	
	black *.py 

train:
	python train.py

eval:
	echo "## Model Metrics" > report.md
	cat ./Results/metrics.txt >> report.md
	
	echo '\n## Confusion Matrix Plot' >> report.md
	echo '![Confusion Matrix](./Results/model_results.png)' >> report.md
	
	cml comment create report.md
		
update-branch:
	git config --global user.name $(USER_NAME)
	git config --global user.email $(USER_EMAIL)
	git commit -am "Update with new results"
	git push --force origin HEAD:update

hf-login:
	python -m pip install -U "huggingface_hub[cli]"
	# fetch and switch to update branch safely
	git fetch origin update
	git switch update || git switch -c update origin/update
	# perform an explicit pull strategy (fast-forward only here)
	git pull --ff-only origin update
	# invoke the HF CLI via Python module to avoid PATH issues
	python -m huggingface_hub.cli login --token $(HF) --add-to-git-credential

push-hub: 
	huggingface-cli upload kingabzpro/Drug-Classification ./App --repo-type=space --commit-message="Sync App files"
	huggingface-cli upload kingabzpro/Drug-Classification ./Model /Model --repo-type=space --commit-message="Sync Model"
	huggingface-cli upload kingabzpro/Drug-Classification ./Results /Metrics --repo-type=space --commit-message="Sync Model"

deploy: hf-login push-hub


all: install format train eval update-branch deploy


