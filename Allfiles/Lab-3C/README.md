# SC-500 Lab 3C - Setup Instructions

## Overview

This folder contains the setup resources for **Lab 3C: Configure AI Gateway and Foundry Security Controls**.

## Files in this folder

- **lab-3c-setup.json** - ARM template for deploying the lab infrastructure via "Deploy a custom template" in Azure Portal
- **sc500-lab3c-apim-policy.xml** - API Management token rate limit policy (students apply this during the lab)
- **generate-adversarial-traffic.ps1** - PowerShell script for testing rate limiting with rapid requests
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
  - Project workspace where students configure content safety guardrails
  
- **Azure API Management** (`sc500-lab3c-apim`)
  - Consumption tier APIM instance
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

### Option 1: Deploy via Azure Portal (Recommended for Skillable labs)

1. Sign in to the [Azure Portal](https://portal.azure.com)
2. Search for **Deploy a custom template**
3. Select **Build your own template in the editor**
4. Click **Load file** and upload `lab-3c-setup.json`
5. Click **Save**
6. Configure parameters:
   - **Subscription**: Select the lab subscription
   - **Location**: Choose a region that supports Azure OpenAI (e.g., East US, West Europe)
   - **Lab Instance Id**: Use the Skillable variable `@lab.LabInstance.Id` or enter a unique 6-8 character identifier
   - **Publisher Email**: Leave default or customize
   - **Publisher Name**: Leave default or customize
7. Click **Review + create**, then **Create**

**Deployment time:** Approximately 10-15 minutes

### Option 2: Deploy via Azure CLI

```bash
# Set variables
LOCATION="eastus"
LAB_INSTANCE_ID="12345678"  # Use a unique 8-digit ID or Skillable @lab.LabInstance.Id

# Deploy the template
az deployment sub create \
  --location $LOCATION \
  --template-file lab-3c-setup.json \
  --parameters location=$LOCATION labInstanceId=$LAB_INSTANCE_ID
```

### Option 3: Deploy via PowerShell

```powershell
# Set variables
$Location = "eastus"
$LabInstanceId = "12345678"  # Use a unique 8-digit ID or Skillable @lab.LabInstance.Id

# Deploy the template
New-AzSubscriptionDeployment `
  -Location $Location `
  -TemplateFile .\lab-3c-setup.json `
  -location $Location `
  -labInstanceId $LabInstanceId
```

## Post-Deployment Configuration

After the ARM template deployment completes, **verify the following before students begin the lab:**

### 1. Verify Azure OpenAI Deployment
1. Navigate to **Resource Groups** > **sc500-lab3c-rg** > **sc500-lab3c-ai-{instanceId}**
2. Select **Model deployments** (or **Deployments**)
3. Confirm **gpt-5.4-mini** is deployed and shows "Succeeded" status

### 2. Configure Azure AI Foundry Project Connection
The ARM template creates the AI Foundry project, but the connection to Azure OpenAI may need to be verified:

1. Navigate to [Azure AI Foundry portal](https://ai.azure.com)
2. Select the **sc500-lab3c-foundry** project
3. In left navigation, select **Settings** or **Connected resources**
4. Verify a connection to the Azure OpenAI service exists
   - If missing, click **+ New connection** → **Azure OpenAI** → select `sc500-lab3c-ai-{instanceId}`
5. Navigate to **Models + endpoints** and confirm **gpt-5.4-mini** is visible
6. Navigate to **Safety + security** > **Content filters** and confirm no custom filter is assigned to gpt-5.4-mini (should use "Default" or "None")

### 3. Verify API Management API Configuration
1. Navigate to **sc500-lab3c-apim** > **APIs**
2. Select **sc500-foundry-api**
3. Verify the **Settings** tab shows:
   - ✅ **Subscription required**: **Not required** (this is intentional - students enable it)
4. Verify the **Design** tab > **All operations** > **Inbound processing** shows:
   - ✅ Only `<base />` tag (no rate limit policy - students apply it)

### 4. Test the Unsecured Endpoint (Optional)
To confirm the environment is in the expected unsecured state before students begin:

1. In APIM, go to **APIs** > **sc500-foundry-api** > **Test**
2. Select the POST operation
3. **Do not add any subscription key header** (verify anonymous access works)
4. In Request body, paste:
   ```json
   {"messages": [{"role": "user", "content": "Hello"}], "max_tokens": 10}
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
**Solution:** Check that the selected region supports API Management Consumption tier. Try East US, West Europe, or North Europe.

### Issue: gpt-5.4-mini deployment fails
**Solution:** Check Azure OpenAI quota for the subscription. The model requires at least 10 TPM capacity. Request quota increase if needed.

### Issue: Students receive 403 when testing APIM API
**Solution:** Verify the backend configuration in APIM includes the Azure OpenAI API key in the `api-key` header. Check `sc500-lab3c-apim` > **Backends** > **openai-backend**.

## Cleanup

The lab environment is typically auto-reset by Skillable. If manual cleanup is needed:

```bash
az group delete --name sc500-lab3c-rg --yes --no-wait
```

## Important Notes

- **Intentionally unsecured:** The API is deployed WITHOUT subscription key requirement, WITHOUT rate limit, and WITHOUT content safety guardrail. This is by design - students apply these controls during the lab.
- **Model version:** The template deploys `gpt-5.4-mini` version `2026-03-17` (GA model, GlobalStandard deployment type, retires March 2027).
- **Quota requirements:** Ensure the subscription has sufficient Azure OpenAI quota. GlobalStandard deployments of gpt-5.4-mini provide 5,000 RPM and 5,000,000 TPM in Tier 1.
- **Region availability:** GlobalStandard deployments route traffic globally. Use East US, West Europe, or other regions that support Azure OpenAI. See [Azure OpenAI region availability](https://learn.microsoft.com/azure/ai-services/openai/concepts/models#model-summary-table-and-region-availability).

## Lab Resources Reference

| Resource Type | Resource Name | Purpose |
|--------------|---------------|---------|
| Resource Group | sc500-lab3c-rg | Contains all lab resources |
| API Management | sc500-lab3c-apim | AI Gateway for rate limiting and auth |
| Azure OpenAI | sc500-lab3c-ai-{instanceId} | Hosts gpt-5.4-mini model |
| AI Hub | sc500-lab3c-hub-{instanceId} | Foundry hub workspace |
| AI Project | sc500-lab3c-foundry | Foundry project for content safety |
| Model Deployment | gpt-5.4-mini | Language model endpoint |
| APIM API | sc500-foundry-api | API routing to Foundry model |

---

**Last Updated:** 2026-06-30  
**Lab Version:** 1.0  
**Target Audience:** SC-500 students and lab environment administrators
