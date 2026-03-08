```skill
---
name: preflight-check
description: Validates that the journal-starter capstone project is submission-ready by checking required files, validating Docker, Terraform, and Kubernetes configs, and fixing issues automatically.
---

# Preflight Check Skill Instructions

When requested to run the preflight check, you must perform the following tasks sequentially to ensure the `journal-starter` project is submission-ready:

1. **Required Files Check**
   Run bash commands to verify the existence of all essential capstone files, including:
   - `Dockerfile`
   - `deployment.yaml`
   - `README.md`
   - `pyproject.toml`
   - Source code directories like `api/` and `tests/`

2. **Docker Build Verification**
   Run the command `docker build -t journal-test .` in a terminal to verify that the Docker image builds successfully.

3. **Terraform Validation**
   Check for `.tf` files in the repository. If Terraform configuration files are present, run `terraform init -backend=false` and then `terraform validate` to ensure configuration correctness.

4. **Kubernetes Manifest Validation**
   Check that all Kubernetes manifests (e.g., `deployment.yaml`) are valid. Use terminal commands to parse or validate them (e.g., validating YAML structure or using `kubectl apply --dry-run=client -f deployment.yaml` if available).

5. **Auto-Remediation**
   If any of the above checks fail, you must thoroughly analyze the error output and **autonomously fix** the underlying issues. Open and edit the necessary files using your available tools, then re-run the failed checks to confirm the problem is resolved. Repeat this loop until all checks pass.

6. **Final Report**
   Once all checks execute successfully, provide a brief summary reporting that the project has been fully validated and is submission-ready.
```
