# Enterprise API Security Demo

This repository provisions a repeatable Azure API Management security demo:

- **Velocity:** an OpenAPI inventory API is published through Terraform and can be updated by Azure DevOps CI/CD.
- **Visibility:** API Management sends gateway telemetry to Application Insights.
- **Protection:** an IP-based rate-limit policy allows five requests per 15 seconds and returns `429` after the limit is reached.
- **Safe demo backend:** the API uses an APIM mock response, so no database or application server is required.

## Architecture

```text
Developer commit -> Azure DevOps pipeline -> APIM OpenAPI import
																			\
Client / traffic script -> APIM gateway -> rate limit -> mock inventory response
																							 \
																								-> Application Insights
```

## Repository layout

| Path | Purpose |
| --- | --- |
| `main.tf` | Resource group, APIM, Application Insights, logger, API, and diagnostics |
| `policies/inventory.xml` | Gateway policy with IP rate limiting and a mock response |
| `api-specs/inventory-api.json` | Version-controlled OpenAPI contract |
| `scripts/api_demo_traffic.py` | Reproducible normal-traffic and rate-limit demonstration |
| `azure-pipelines.yml` | Validation and API import pipeline |

## Prerequisites

- Terraform 1.6+
- Azure CLI 2.60+
- An Azure subscription and permission to create resource groups, APIM, and Application Insights
- An Azure DevOps project with this repository and an Azure Resource Manager service connection

APIM Consumption can take several minutes to provision and has Azure region availability constraints. Choose a supported region with `location`.

## Deploy

```bash
az login
az account set --subscription "<subscription-id>"
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars. Use a unique, lowercase APIM name.
terraform init
terraform fmt -check -recursive
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

The API key is never stored in Terraform output. Retrieve the built-in subscription key only when you are ready to run the demo:

```bash
az apim subscription list \
	--resource-group "$(terraform output -raw resource_group_name)" \
	--service-name "$(terraform output -raw apim_name)" \
	--query "[?contains(displayName, 'Built-in')].primaryKey" -o tsv
```

Run the traffic demonstration:

```bash
python3 -m pip install -r requirements.txt
export TARGET_URL="$(terraform output -raw inventory_api_url)"
export VALID_API_KEY="<key-from-previous-command>"
python3 scripts/api_demo_traffic.py
```

The script makes five successful requests, waits for Enter, and then sends a burst that should produce `429 Too Many Requests`. Open the Application Insights resource in Azure Portal and inspect **Failures** or **Logs** for the gateway activity.

## Azure DevOps setup

1. Create an Azure Resource Manager service connection with permission to the resource group or subscription.
2. Create a pipeline from `azure-pipelines.yml`.
3. Set the `azureServiceConnection` variable to the service connection name.
4. Set `resourceGroupName`, `location`, and `apimName` to the same values used by Terraform.

The pipeline validates the OpenAPI document and imports it into the existing APIM service. Terraform remains the owner of infrastructure and policy configuration; the pipeline owns contract publication.

## Security notes

- `terraform.tfvars`, state files, and API keys are ignored by Git. Store state in an authenticated remote backend for shared use.
- Do not commit subscription keys. Prefer Azure Key Vault-backed variable groups for production pipelines.
- The mock response is intentionally local to APIM. Replace it with a private backend and network controls before using this pattern outside a demonstration.

## Cleanup

```bash
terraform destroy
```