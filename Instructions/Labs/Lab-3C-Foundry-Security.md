---
lab:
    title: 'Configure AI Gateway and Foundry Security Controls'
    description: 'Configure token rate limiting and subscription key authentication in Azure API Management in front of a pre-provisioned Azure AI Foundry model endpoint, create a content safety guardrail with Prompt Shield in Azure AI Foundry, apply it to the deployed model, and enable Defender for AI Services in Microsoft Defender for Cloud.'
    level: 300
    duration: 60
    islab: true
    primarytopics:
        - Azure API Management AI Gateway
        - Azure AI Foundry
        - Microsoft Defender for AI Services
---

# Lab Setup

Follow these steps to build out your lab scenarios:

1. Open the **Azure Portal** at `https://portal.azure.com`.

1. Log in with the **User1** administrator role.

1. In the Azure portal top bar, select the **Cloud Shell** icon (**>_**). If prompted, select **Bash**.

1. Register the Microsoft.Security resource provider so Defender plans are available later in the lab:

    ```bash
    az provider register --namespace Microsoft.Security
    ```

1. Wait until registration completes:

    ```bash
    az provider show --namespace Microsoft.Security --query "registrationState" -o tsv
    ```

    Re-run the command until the output is `Registered`.


1. In the **Search** bar find and open **Deploy a custom template**.

1. Select **Build your own template in the editor**.

1. In the menu choose **Load file**.

1. Select the file **lab-3c-setup.json** from the **F:\AllFiles\Lab-3C** folder on the lab VM.

1. Select **Save**.



1. Select **Review + create**.

    > **Note**: The Basic v2 API Management instance can take 10–15 minutes to provision. Wait for the deployment to show **Succeeded** before continuing.

1. Close the browser.

===


# Configure AI Gateway and Foundry Security Controls

Your organization is exposing a Foundry-hosted language model through an API endpoint that currently has no rate limiting, no content filtering, and no authentication requirement. Any client that knows the endpoint URL can send unlimited requests — including harmful prompts — and the model will respond without restriction.

A security review identified three independent gaps:

- **No access control**: Anonymous callers can reach the model without a subscription key
- **No rate limiting**: Unlimited token consumption with no cost abuse protection
- **No content safety**: No guardrail prevents the model from processing or generating harmful content

Your job is to address all three gaps. You will configure the AI Gateway in API Management to enforce subscription key authentication and token rate limiting, configure a Foundry content safety guardrail with Prompt Shield, apply the guardrail to the deployed model, and enable Defender for AI Services to add a detection layer on top of the prevention controls.

In this lab, you will:

- Review the pre-provisioned Foundry model endpoint and confirm its unsecured state
- Apply a token rate limit policy to the API in Azure API Management
- Require subscription key authentication and remove anonymous access
- Test the configured gateway to verify rate limiting and authentication enforcement
- Create a content safety guardrail with Prompt Shield in Azure AI Foundry and apply it to the model
- Enable Defender for AI Services in Microsoft Defender for Cloud

This exercise should take approximately **60** minutes to complete.

> **Note**: This lab uses two portals: the [Azure portal](https://portal.azure.com) for API Management and Defender for Cloud, and the [Azure AI Foundry portal](https://ai.azure.com) for content safety guardrail configuration. Both portals are used in sequence — the sections below indicate which portal each task requires.

---

## Review the unsecured state

Before applying any controls, confirm the current state of the pre-provisioned environment. Understanding the "before" state makes the security changes visible and measurable.

### Review the API Management configuration

> **Note**: The pre-provisioned API Management instance name begins with **`sc500-lab3c-apim-`** followed by an 8-character suffix that is unique to your lab subscription. Throughout this lab, `<apim-name>` refers to that instance. The `sc500-lab3c-rg` resource group contains exactly one API Management instance — select it whenever the lab asks for `<apim-name>`.

1. Sign in to the [Azure portal](https://portal.azure.com) using your **User1** credentials.

1. In the search bar, search for and select **API Management services**.

1. Select the API Management instance whose name starts with **`sc500-lab3c-apim-`** to open it.

1. In the left menu, under **APIs**, select **APIs**.

1. Select the pre-registered Foundry API (named **sc500-foundry-api** or similar).

1. Select the **Design** tab and select **All operations** in the left panel.

1. In the **Inbound processing** section, select the **</>Policy** icon to open the policy editor.

    Confirm that the policy contains `<base />` and `<set-backend-service backend-id="openai-backend" />`. The backend policy supplies the Azure OpenAI credential required for routing, but no token rate limit or caller authentication is applied. This is the unsecured state.

1. Select **Discard** or close the policy editor without making changes.

1. Select the **Settings** tab for the API. Review the **Subscription** section and confirm that **Subscription required** is currently set to **Not required** — anonymous callers can reach the API with no key.

### Review the Foundry model endpoint

1. Open a new browser tab and navigate to the [Microsoft Foundry portal](https://ai.azure.com).

1. If a New Foundry project opens, select the project name in the upper-left corner, and then select **View all resources**.

1. Select the **sc500-lab3c-foundry** Hub project.

1. On the resource details pane, select **Open in Foundry Classic**.

    > **Note**: This lab uses a Hub project. Hub projects are managed in Foundry Classic and are not supported in the New Foundry project experience.

1. In the left navigation, under **My assets**, select **Models + endpoints**.

1. Locate the **sc500-lab3c-openai** deployment row, confirm its **Model name** is **gpt-5.4-mini** and its **State** is **Succeeded**, and then review the endpoint details.

1. In the left navigation, under **Protect and govern**, select **Guardrails + controls**, and then select the **Content filters** tab.

    Confirm that **no custom content filter** is assigned to the gpt-5.4-mini deployment. The model uses the default filter until you create and assign a custom guardrail later in the lab.

1. Return to the Azure portal tab for the next section.

---

## Apply the AI Gateway token rate limit policy

Azure API Management provides AI Gateway policies that are purpose-built for language model endpoints. The token rate limit policy counts the tokens consumed per caller per minute and returns HTTP 429 when the limit is exceeded, protecting the endpoint against cost abuse.

The policy XML for this lab is provided in the **F:\AllFiles\Lab-3C** folder. You will paste it directly into the APIM policy editor — you do not need to author policy XML from memory.

1. In the Azure portal, navigate back to **`<apim-name>` > APIs > sc500-foundry-api**.

1. Select the **Design** tab and select **All operations**.

1. In the **Inbound processing** section, select the **</>Policy** icon to open the policy editor.

1. Open **F:\AllFiles\Lab-3C\sc500-lab3c-apim-policy.xml** on the lab VM.

1. Select and copy the complete contents of the file.

1. In the APIM policy editor, replace the existing policy content with the copied XML.

1. Review the key elements of the policy before saving:

    | Policy element | What it enforces |
    |----------------|-----------------|
    | `set-backend-service` | Preserves routing through the credentialed `openai-backend` |
    | `llm-token-limit` | 500 tokens per minute per subscription key; returns HTTP 429 when exceeded |
    | `counter-key` | Each subscription key gets its own independent token budget |
    | `estimate-prompt-tokens` | Token counting starts before the model responds — prompt tokens count against the limit |
    | `remaining-tokens-header-name` | The `x-ratelimit-remaining-tokens` response header shows remaining budget to callers |

1. Select **Save** to apply the policy.

    > **Note**: The content safety layer for this environment is applied at the Foundry guardrail level (configured in a later section of this lab), not at the APIM policy level. APIM enforces *who can call* and *how often*; Foundry enforces *what content is allowed* at the model inference layer. Both layers are required for a complete security posture.

---

## Require subscription key authentication

Anonymous access to the Foundry API endpoint is the highest-priority gap — rate limiting has no effect if callers can create unlimited API sessions without any identity. You will now configure the API to require a subscription key, which APIM validates before forwarding requests to the Foundry backend.

1. With the Foundry API still selected in the API Management portal, select the **Settings** tab.

1. Under **Subscription**, change **Subscription required** to **Required**.

1. In the **Subscription key header name** field, confirm the default value is `Ocp-Apim-Subscription-Key` — this is the standard APIM subscription key header name.

1. Select **Save**.

1. In the left menu, select **Subscriptions**.

1. Select **+ Add subscription** to create a test subscription key for the next task.

1. Configure the subscription:

    | Setting | Value |
    |---------|-------|
    | **Name** | sc500-test-subscription |
    | **Display name** | SC-500 Lab Test Key |
    | **Scope** | API |
    | **API** | sc500-foundry-api |

1. Select **Create**.

1. On the subscriptions list, find **sc500-test-subscription** and select **Show/hide keys** to reveal the primary key. Copy the primary key value — you will use it in the next section.

---

## Test the configured gateway

With the token rate limit policy and subscription key authentication in place, verify that the gateway enforces both controls as expected.

1. In the APIM portal, navigate to **APIs > sc500-foundry-api**.

1. Select the **Test** tab.

1. Select the chat completions operation (the POST endpoint).

1. In the **Headers** section, add a header:

    | Header name | Header value |
    |-------------|-------------|
    | `Ocp-Apim-Subscription-Key` | (paste the key you copied in the previous section) |

1. In the **Request body** section, paste the following test prompt:

    ```input
    {"messages": [{"role": "user", "content": "What is the capital of France?"}], "max_completion_tokens": 50}
    ```

1. Select **Send** and confirm you receive **HTTP 200** with a model response — the request succeeded with a valid subscription key.

1. Remove the `Ocp-Apim-Subscription-Key` header from the test panel (or clear the value).

1. Select **Send** again and confirm you receive **HTTP 401 Unauthorized** — the request is rejected without a subscription key.

1. To verify rate limiting behavior, use the Azure Cloud Shell to send rapid sequential requests with your subscription key:

    1. Open **Cloud Shell** from the Azure portal toolbar (the `>_` icon).

    1. In the Cloud Shell prompt, run the following command, replacing `<your-key>` with your subscription key and `<your-apim-gateway-url>` with your APIM gateway URL (visible on the `<apim-name>` overview page under **Gateway URL**):

        ```bash
        for i in {1..10}; do curl -s -o /dev/null -w "%{http_code}\n" -X POST "https://<your-apim-gateway-url>/sc500-foundry-api/deployments/gpt-5.4-mini/chat/completions?api-version=2024-10-21" -H "Ocp-Apim-Subscription-Key: <your-key>" -H "Content-Type: application/json" -d '{"messages":[{"role":"user","content":"Summarize the security risks of unprotected AI endpoints in 100 words."}],"max_completion_tokens":100}'; done
        ```

    1. Observe the HTTP status codes returned. The first few requests return **200**. After the 500 token-per-minute limit is reached, subsequent requests return **429 Too Many Requests** — the rate limit policy is enforcing the token budget.

    > **Note**: The exact request at which the 429 response appears depends on the token count of each response. With `max_completion_tokens` set to 100 and 500 TPM configured, the limit typically fires within 5–6 requests. The rate limit counter resets after one minute.

---

## Create a content safety guardrail in Azure AI Foundry

Content safety guardrails are applied at the Foundry layer — they inspect both the prompt sent to the model and the model's response, and block content that exceeds configured harm thresholds. You will create a guardrail with Prompt Shield enabled and apply it to the gpt-5.4-mini deployment.

1. Return to the **Azure AI Foundry portal** tab (or navigate to [https://ai.azure.com](https://ai.azure.com)).

1. Select the **sc500-lab3c-foundry** project.

1. In the left navigation, under **Guardrails + controls**, select **Content filters**.

1. Select **+ Create content filter**.

1. On the **Basic information** step, configure:

    | Setting | Value |
    |---------|-------|
    | **Name** | sc500-safety-filter |
    | **Connection** | sc500-lab3c-openai |

1. Select **Next**.

1. On the **Input filter** step, confirm all four harm categories use **Annotate and block** with **Medium blocking**:

    | Category | Action | Blocking threshold |
    |----------|--------|--------------------|
    | **Violence** | Annotate and block | Medium blocking |
    | **Hate** | Annotate and block | Medium blocking |
    | **Sexual** | Annotate and block | Medium blocking |
    | **Self-harm** | Annotate and block | Medium blocking |

1. Configure Prompt Shields on the same **Input filter** step:

    | Setting | Value |
    |---------|-------|
    | **Prompt shields for jailbreak attacks** | Annotate and block |
    | **Prompt shields for indirect attacks** | Annotate and block |

1. Leave **Blocklist** off and **Spotlighting** disabled, and then select **Next**.

1. On the **Output filter** step, confirm **Violence**, **Hate**, **Sexual**, and **Self-harm** use **Annotate and block** with **Medium blocking**. Leave the remaining output controls at their defaults, and then select **Next**.

1. On the **Connection** step, confirm **sc500-lab3c-openai** is selected.

1. In the deployments table, select the row for **gpt-5.4-mini**, and then select **Next**.

1. On the **Review** step, confirm the filter name, connection, Prompt Shield settings, and deployment assignment, and then select **Create filter**.

1. When creation completes, confirm **sc500-safety-filter** lists **gpt-5.4-mini** under **Applied deployment**.
---

## Enable Defender for AI Services

The APIM gateway and Foundry guardrail are **preventive** controls — they block harmful requests. Defender for AI Services is a **detective** control — it monitors the behavioral patterns of AI workloads over time and alerts when attack sequences are detected, even when individual requests are blocked.

1. Return to the **Azure portal** tab.

1. In the search bar, search for and select **Microsoft Defender for Cloud**.

1. In the left menu, select **Environment settings**.

1. Select your subscription from the list.

1. On the **Defender plans** page, scroll to find **AI Services** (or **Defender for AI**).

1. Set the **AI Services** plan to **On**.

1. Select **Save** at the top of the page.

1. Confirm the **AI Services** plan shows **On** before leaving the Defender plans page.

    > **Note**: Plan status can take several minutes to propagate after the resource provider is registered. Refresh the page if the status does not update immediately.

---

## Review the security architecture

The three controls you configured today address different dimensions of AI endpoint security:

| Control layer | Type | What it addresses |
|---------------|------|------------------|
| **APIM subscription key** | Preventive — access control | Blocks anonymous callers; every request must present a valid key |
| **APIM token rate limit** | Preventive — volume control | Limits consumption per key per minute; protects against cost abuse |
| **Foundry content safety + Prompt Shield** | Preventive — content control | Blocks harmful prompts and jailbreak attempts before model processing |
| **Defender for AI Services** | Detective — behavioral monitoring | Identifies attack campaigns across multiple requests; generates security alerts for SOC investigation |

A single preventive layer is not sufficient. An attacker who obtains a subscription key can still attempt jailbreaks. An attacker blocked by the guardrail on individual requests can still run a jailbreak campaign across many sessions. Defender for AI detects that campaign pattern and alerts your SOC — even when each individual request was blocked. All four controls are required for a complete security posture.

---

## Summary

In this lab, you remediated three independent security gaps in a Foundry-hosted AI endpoint. In Azure API Management, you applied a token rate limit policy to enforce a 500-tokens-per-minute consumption limit and required subscription key authentication, removing anonymous access. You tested both controls using the APIM test console and Cloud Shell.

In Azure AI Foundry, you created a content safety guardrail named **sc500-safety-filter** with Medium harm thresholds across all four harm categories and Prompt Shield enabled for both jailbreak and indirect attack detection. You applied the guardrail to the gpt-5.4-mini deployment.

In Microsoft Defender for Cloud, you enabled Defender for AI Services on the subscription, adding a behavioral detection layer on top of the prevention controls.

You have successfully completed this exercise.

## Clean up

The lab environment is automatically reset at the end of the session. No manual resource deletion is required.

If you want to remove the content safety guardrail from the model deployment before the session ends:

1. Navigate to the Azure AI Foundry portal > **sc500-lab3c-foundry** > **Models + endpoints**.
1. Select the **gpt-5.4-mini** deployment and edit the deployment settings.
1. Set **Content filter** back to the default filter or to none, then save.
