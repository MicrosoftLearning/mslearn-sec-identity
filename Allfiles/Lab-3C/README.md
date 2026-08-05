# SC-500 Lab 3C - Setup Instructions

## Overview

This folder contains the setup resources for **Lab 3C: Configure AI Gateway and Foundry Security Controls**.

## Files in this folder

- **lab-3c-setup.json** - ARM template for deploying the lab infrastructure via "Deploy a custom template" in Azure Portal
- **sc500-lab3c-apim-policy.xml** - API Management token rate limit policy (students apply this during the lab)

- **README.md** - This file

## What the setup deploys

The `lab-3c-setup.json` ARM template provisions the following resources in the **sc500-lab3c-rg** resource group:

### Core Infrastructure
- **Azure OpenAI Service** (`sc500-lab3c-ai-{instanceId}`)
  - gpt-5.4-mini model deployment (GlobalStandard SKU) with 10 TPM capacity
  - Initially configured with default content filter (no custom guardrail)
  
- **Azure AI Foundry Hub** (`sc500-lab3c-hub-{instanceId}`)
  - Hub workspace for the Foundry project
  
- **Azure AI Foundry Project** (`sc500-lab3c-foundry`)
  - Hub project workspace where students configure content safety guardrails in Foundry Classic
  - Preconfigured Azure OpenAI connection: `sc500-lab3c-openai`
  
- **Azure API Management** (`sc500-lab3c-apim-{instanceId}`)
  - Basic v2 APIM instance (required for the `llm-token-limit` policy)
  - Pre-registered API: `sc500-foundry-api`
  - **Intentionally unsecured state:**
    - ❌ No subscription key requirement (students enable this)
    - ❌ No rate limit policy (students apply this)
    - ❌ No content safety guardrail (students create this in Foundry)

### Supporting Resources
- **Log Analytics Workspace** (`sc500-lab3c-logs`)
- **Application Insights** (`sc500-lab3c-insights`)
- **Storage Account** (`sc500lab3c{instanceId}`) - for AI Hub/Project
- **Key Vault** (`sc500-kv-{instanceId}`) - for AI Hub/Project

## Deployment Instructions

### Option 1: Deploy via Azure Portal (Recommended for hosted labs)

1. Sign in to the [Azure Portal](https://portal.azure.com)
2. In Cloud Shell, register `Microsoft.Security`, then generate `LAB_INSTANCE_ID=$(az account show --query id -o tsv | tr -d '-' | cut -c1-8)`
3. Search for **Deploy a custom template**
4. Select **Build your own template in the editor**
5. Click **Load file** and upload `lab-3c-setup.json`
6. Click **Save**
7. Configure parameters:
   - **Subscription**: Select the lab subscription
   - **Location**: Choose a region that supports Azure OpenAI (e.g., East US, West Europe)
   - **Lab Instance Id**: Paste the eight-character `LAB_INSTANCE_ID` value generated in Cloud Shell.
   - **Publisher Email**: Leave default or customize
   - **Publisher Name**: Leave default or customize
8. Click **Review + create**, then **Create**

**Deployment time:** Approximately 10-15 minutes

### Option 2: Deploy via Azure CLI

```bash
# Set variables
LOCATION="eastus"

# Deploy the template (labInstanceId defaults to a hash of the subscription ID)
az deployment sub create \
  --location $LOCATION \
  --template-file lab-3c-setup.json \
  --parameters location=$LOCATION
```

### Option 3: Deploy via PowerShell

```powershell
# Set variables
$Location = "eastus"

# Deploy the template (labInstanceId defaults to a hash of the subscription ID)
New-AzSubscriptionDeployment `
  -Location $Location `
  -TemplateFile .\lab-3c-setup.json `
  -location $Location
```

## Post-Deployment Configuration

After the ARM template deployment completes, **verify the following before students begin the lab:**

### 1. Verify Azure OpenAI Deployment
1. Navigate to **Resource Groups** > **sc500-lab3c-rg** > **sc500-lab3c-ai-{instanceId}**
2. Select **Model deployments** (or **Deployments**)
3. Confirm **gpt-5.4-mini** is deployed and shows "Succeeded" status

### 2. Verify Azure AI Foundry Project Connection
The ARM template creates the AI Foundry project and its Azure OpenAI connection:

1. Navigate to [Azure AI Foundry portal](https://ai.azure.com)
2. Open the project switcher and select **View all resources**
3. Select **sc500-lab3c-foundry**, then select **Open in Foundry Classic**
4. In **Management center**, verify `sc500-lab3c-openai` is listed under connected resources
5. Navigate to **Models + endpoints** and confirm **gpt-5.4-mini** is visible
6. Navigate to **Guardrails + controls** > **Content filters** and confirm no custom filter is assigned to gpt-5.4-mini (should use "Default" or "None")

### 3. Verify API Management API Configuration
1. Navigate to **sc500-lab3c-apim-{instanceId}** > **APIs**
2. Select **sc500-foundry-api**
3. Verify the **Settings** tab shows:
   - ✅ **Subscription required**: **Not required** (this is intentional - students enable it)
4. Verify the **Design** tab > **All operations** > **Inbound processing** shows:
   - ✅ `<base />` and `<set-backend-service backend-id="openai-backend" />` (credentialed routing only; students add the rate limit)

### 4. Test the Unsecured Endpoint (Optional)
To confirm the environment is in the expected unsecured state before students begin:

1. In APIM, go to **APIs** > **sc500-foundry-api** > **Test**
2. Select the POST operation
3. **Do not add any subscription key header** (verify anonymous access works)
4. In Request body, paste:
   ```json
   {"messages": [{"role": "user", "content": "Hello"}], "max_completion_tokens": 10}
   ```
5. Click **Send**
6. Expected result: **HTTP 200** with a model response (confirms anonymous access is allowed)

## Lab Flow

Once deployment and verification are complete, students will:

1. **Review the unsecured state** - Confirm no rate limit, no auth, no content filter
2. **Apply token rate limit policy** - Use `sc500-lab3c-apim-policy.xml`
3. **Require subscription key** - Enable subscription requirement in APIM API settings
4. **Test the configured gateway** - Verify 429 responses and 401 for missing keys
5. **Create content safety guardrail** - Configure Prompt Shield in Foundry
7. **Apply guardrail to deployment** - Assign custom filter to gpt-5.4-mini
7. **Enable Defender for AI** - Turn on Defender for AI Services in Microsoft Defender for Cloud

## Troubleshooting

### Issue: Azure OpenAI deployment not visible in AI Foundry
**Solution:** Verify the connection in AI Foundry project settings. Add a new Azure OpenAI connection pointing to `sc500-lab3c-ai-{instanceId}`.

### Issue: API Management deployment fails
**Solution:** Confirm the service uses Basic v2 or another tier supported by `llm-token-limit`. Consumption does not support this policy.

### Issue: gpt-5.4-mini deployment fails
**Solution:** Check Azure OpenAI quota for the subscription. The model requires at least 10 TPM capacity. Request quota increase if needed.

### Issue: Students receive 401 when testing APIM API
**Solution:** Verify the API policy contains `<set-backend-service backend-id="openai-backend" />` and that the backend includes the Azure OpenAI API key in the `api-key` header.

## Cleanup

Your lab host may reset the environment automatically. If manual cleanup is needed:

```bash
az group delete --name sc500-lab3c-rg --yes --no-wait
```

## Important Notes

- **Intentionally unsecured to callers:** The API routes through a credentialed backend so inference works, but it is deployed WITHOUT a caller subscription-key requirement, WITHOUT a rate limit, and WITHOUT a custom content safety guardrail. Students apply those controls during the lab.
- **Model version:** The template deploys `gpt-5.4-mini` version `2026-03-17` (GA model, GlobalStandard deployment type, retires March 2027).
- **Quota requirements:** Ensure the subscription has sufficient Azure OpenAI quota. GlobalStandard deployments of gpt-5.4-mini provide 5,000 RPM and 5,000,000 TPM in Tier 1.
- **Region availability:** GlobalStandard deployments route traffic globally. Use East US, West Europe, or other regions that support Azure OpenAI. See [Azure OpenAI region availability](https://learn.microsoft.com/azure/ai-services/openai/concepts/models#model-summary-table-and-region-availability).

## Lab Resources Reference

| Resource Type | Resource Name | Purpose |
|--------------|---------------|---------|
| Resource Group | sc500-lab3c-rg | Contains all lab resources |
| API Management | sc500-lab3c-apim-{instanceId} | AI Gateway for rate limiting and auth |
| Azure OpenAI | sc500-lab3c-ai-{instanceId} | Hosts gpt-5.4-mini model |
| AI Hub | sc500-lab3c-hub-{instanceId} | Foundry hub workspace |
| AI Project | sc500-lab3c-foundry | Foundry project for content safety |
| Model Deployment | gpt-5.4-mini | Language model endpoint |
| APIM API | sc500-foundry-api | API routing to Foundry model |

---

**Last Updated:** 2026-06-30  
**Lab Version:** 1.0  
**Target Audience:** SC-500 students and lab environment administrators
