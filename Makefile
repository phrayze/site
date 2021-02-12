.PHONY: apply destroy compliance

apply:
	terraform apply -auto-approve

destroy:
	terraform destroy -auto-approve

compliance:
