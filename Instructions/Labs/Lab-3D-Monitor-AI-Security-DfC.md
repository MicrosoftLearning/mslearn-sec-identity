---
lab:
    title: 'Monitor AI Security with Defender for Cloud'
    description: 'Use a guided review of the Microsoft Defender for Cloud Data and AI security dashboard to understand AI workload protection, findings, and recommendations, and optionally examine live results when Defender data is available.'
    level: 300
    duration: 15
    islab: true
    primarytopics:
        - Microsoft Defender for Cloud
        - Defender for AI Services
        - AI Security Monitoring
---

# Lab Setup

> **Note**: Defender for Cloud event processing can take **6-24 hours or longer**. To increase the likelihood of seeing live detections, run the setup instructions in `Allfiles\Lab-3D\README.md`, generate the test traffic, and allow the environment to persist for at least one day before the exercise. If findings are not available, continue with the guided-review path and compare the portal workflow with the descriptions of what a populated environment would show.

This lab supports two paths:

- **Live-results path**: If protection data, findings, or recommendations are present, open them and record the requested details.
- **Guided-review path**: If data is absent, follow the same navigation, review the purpose of each view and the described populated state, and continue without waiting for Defender data to appear.

Follow these steps to deploy the resources used in the lab:

1. Open the **Azure portal** at `https://portal.azure.com` and sign in with **User1**.

1. In the portal top bar, select the **Cloud Shell** icon (**>_**). If prompted, select **Bash** and **No storage account required**.

1. Register the Microsoft.Security resource provider:

    ```bash
    az provider register --namespace Microsoft.Security --wait
    az provider show --namespace Microsoft.Security --query registrationState -o tsv
    ```

1. Confirm the provider output is `Registered`, and then close Cloud Shell.

1. In the portal search bar, find and open **Deploy a custom template**.

1. Select **Build your own template in the editor**, and then select **Load file**.

1. Select **lab-3d-setup.json** from the **F:\AllFiles\Lab-3D** folder on the lab VM, and then select **Save**.


1. Select **Review + create**, and then select **Create**.

1. Wait until the deployment shows **Succeeded** before continuing.

===

# Monitor AI Security with Defender for Cloud

Your CISO wants a status report on the AI workload protections deployed this week: which AI resources are protected, what has Defender for Cloud detected, and what needs to be remediated first.

The setup creates an Azure AI workload that can be protected by Defender for AI Services. When the environment has persisted long enough after test traffic is generated, Defender may display protection data, findings, and recommendations. Your job is to learn where those results appear, how to interpret them when present, and what a populated environment would show when live data is not yet available.

In this lab, you will:

- Locate the Data and AI security views used to monitor AI workloads.
- Review how Defender presents AI security findings and severity when detections are available.
- Review the AI security recommendation workflow and expected remediation information.
- Explain how behavioral detections complement preventive guardrails.

This exercise should take approximately **15** minutes to complete.

> **Note**: If synthetic adversarial traffic was run and Defender processing has completed, the environment may show findings such as jailbreak attempts, prompt injection probes, or anomalous volume. Defender can correlate related signals, so the number and grouping of findings can vary. If no findings are present, use the guided-review notes in the following sections.

---

## Open the Data and AI security dashboard

1. Sign in to the [Azure portal](https://portal.azure.com) using your **User1** credentials.

1. Search for and open **Microsoft Defender for Cloud**.

1. In the left menu, select **Data and AI security**.

    > **Note**: If you do not see **Data and AI security**, look under **Cloud security** or use the Defender for Cloud search bar. The menu label can vary by portal version.

1. Review the protection status summary.

1. If AI resources are listed, record how many are protected, unprotected, or partially covered, and look for **sc500-lab3d-foundry**.

1. If no AI workload data is listed, review the available filters and status categories. In a populated environment, this view identifies each AI resource and whether Defender for AI Services reports it as protected, unprotected, or partially covered. Continue without waiting for data to populate.
---

## Review active security findings

1. In **Data and AI security**, select **Findings**, or open **Alerts** and filter to AI workloads.

1. If findings are present, note the total count, severity levels, and affected resources. Select the highest-severity finding and record:

    | Field | Value |
    |-------|-------|
    | **Finding title** | |
    | **Severity** | High / Medium / Low |
    | **Affected resource** | |
    | **Trigger description** | |
    | **Recommended action** | |

1. Return to the findings list and compare any different attack types. Synthetic traffic can include jailbreak attempts, prompt injection probes, and high-volume bursts, but Defender may correlate related signals into fewer finding groups.

1. If no findings are present, review the columns, filters, and severity controls in the empty view. In a populated environment, selecting a finding opens details such as the detection title, severity, affected AI resource, observed behavior, supporting evidence, and recommended action.
---

## Review AI security recommendations

1. Open **Recommendations** and filter for AI-related recommendations, or search for **AI**.

1. If a recommendation applies to **sc500-lab3d-foundry**, select it and review:

    - The security control.
    - The affected resource and severity.
    - The recommendation freshness.
    - The remediation guidance.

1. If no AI recommendation is present, review the recommendation filters and detail fields. In a populated environment, an AI recommendation identifies the affected resource, security control, severity, freshness, and remediation steps. An endpoint without a content filter may produce a recommendation to apply content safety guardrails.

1. Consider why a content-filter recommendation is appropriate even when Defender behavioral detections are enabled: the content filter helps prevent individual unsafe requests, while Defender identifies broader patterns over time.
---

## Consider the findings in context

When findings are available, they represent behavioral analysis of activity against the AI endpoint. Defender for AI can identify patterns across multiple queries rather than relying only on whether an individual request was blocked. This illustrates the distinction between a guardrail, which evaluates a request at the point of interaction, and a behavioral detection system, which can identify a campaign or anomalous sequence over time.

In production, these views can contain findings from Foundry endpoints, Copilot agents, and other AI services. Security engineers review the findings, prioritize them by severity and potential impact, and escalate the highest-risk activity for remediation.

If live findings are available, identify the highest-severity finding and one action that would reduce the most risk for **sc500-lab3d-foundry**. If findings are absent, choose one example category described in this lab and identify an appropriate preventive or remediation action.

You do not need to write a formal answer. The objective is to practice the reasoning process even when asynchronous Defender data is not yet available.
---

## Summary

In this lab, you followed the Microsoft Defender for Cloud Data and AI security monitoring workflow. Depending on data availability, you either examined live protection data, findings, and recommendations or used the guided-review path to understand the information those views provide in a populated environment.

Defender for AI Services is a detection layer that helps identify activity patterns over time. Preventive controls such as content filters, authentication, and rate limiting complement that detection capability by reducing risk at the point of interaction.

If the environment remains available long enough for Defender processing to finish, you can optionally return to these views and compare live results with the expected workflow described in this lab.

## Clean up

No resources are removed as part of the guided review. Follow the environment-owner cleanup guidance when the lab environment is no longer needed.