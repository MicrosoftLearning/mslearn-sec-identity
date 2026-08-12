---
lab:
    title: 'Explore Defender for Cloud Security Posture and CSPM'
    description: 'Use a guided review of Defender CSPM posture, compliance, secret scanning, attack paths, and governance workflows, and optionally examine live results when asynchronous posture data is available.'
    level: 300
    duration: 75
    islab: true
    primarytopics:
        - Microsoft Defender for Cloud
        - Defender CSPM
        - Regulatory compliance and governance rules
---

# Lab Setup

> **Note**: Defender CSPM recommendations, Secure Score, secret scanning findings, regulatory compliance results, and attack paths are generated asynchronously and can take **24 hours or longer** to appear after Defender plans are enabled and resources are deployed. To increase the likelihood of seeing live posture data, prepare the environment at least one day before the exercise. If data is not available, continue with the guided-review path and use the descriptions of what each populated view would show.

This lab supports two paths:

- **Live-results path**: If posture data is present, open the available results and record the requested details.
- **Guided-review path**: If a view is empty, review its navigation, filters, purpose, and described populated state, and continue without waiting for data to appear.

Follow these steps to build out your lab scenarios:

1. Open the **Azure Portal** at `https://portal.azure.com`.

1. Log in with the **User1** administrator role.

1. Open Cloud Shell, select **Bash**, and register the Microsoft.Security resource provider:

    ```bash
    az provider register --namespace Microsoft.Security --wait
    az provider show --namespace Microsoft.Security --query registrationState -o tsv
    ```

1. Confirm the provider output is `Registered`, and then close Cloud Shell.

1. In the **Search** bar, find and open **Deploy a custom template**.
   
1. Select **Build your own template in the editor**.

1. In the menu choose **Load file**.

1. Select the file **lab-4d-setup.json** from the Desktop folder.

1. Select **Save**.

1. Select **Review + create**.

    > **Note**: Deployment may take a few minutes to complete.

1. Close the browser.

===

# Explore Defender for Cloud Security Posture and CSPM

Your organization needs a posture update that goes beyond single findings. Leadership wants to know:

- Current Secure Score and top risk drivers.
- Compliance state against a named framework.
- Whether secrets are exposed outside approved secret stores.
- Who owns remediation and by when.

In this lab, you will use Defender for Cloud to evaluate and action security posture using recommendation prioritization, compliance mapping, secret scanning, governance assignment, and attack path review.

In this lab, you will:

- Locate the Defender CSPM views used for posture and risk review.
- Review how Secure Score, recommendations, and compliance controls are presented when data is available.
- Review the secret-scanning and attack-path investigation workflows.
- Compare unsafe secret placement with correct Key Vault usage.
- Review the governance-assignment workflow and expected ownership information.
- Optionally review multicloud connector scope.

This exercise should take approximately **75** minutes to complete.

> **Note**: The generated storage account, Web App, and Key Vault names begin with `sc500lab4dstore`, `sc500-lab4d-webapp-`, and `sc500-lab4d-kv-`. Throughout the lab, `<storage-account-name>`, `<web-app-name>`, and `<key-vault-name>` refer to those resources. Defender posture data may still be processing when the resources are already visible.

---

## Review the Preconfigured State

1. In the Azure portal, open **Resource groups** and select **sc500-lab4d-rg**.

1. Confirm the generated storage account, Web App, Key Vault, and **sc500-lab4d-vm** are present.

1. Open **Microsoft Defender for Cloud**.

1. If the subscription shows active posture data, continue with the live-results path. If posture data is absent, continue with the guided-review path; do not wait for processing to finish during the learner session.
---

## Review Secure Score and Top Recommendations

1. On **Overview**, if Secure Score data is available, record:

    | Field | Value |
    |-------|-------|
    | Secure Score (%) | |
    | Unhealthy resources count | |
    | Active recommendations count | |

1. Open **Recommendations**.

1. If recommendations are present, sort by **Max score impact**, open the highest-impact recommendation, and review affected resources and remediation guidance.

1. If a non-destructive quick fix is available, optionally apply it.

1. If Secure Score or recommendations are absent, review the available filters and columns. In a populated environment, Secure Score summarizes posture as a percentage, and recommendation details identify affected resources, score impact, severity, and remediation guidance.
---

## Assign and Review Regulatory Compliance

1. Open **Regulatory compliance**.

1. Select **Add standards** and assign **NIST SP 800-53 Rev. 5** to the subscription.

1. After the assignment appears, open the NIST view.

1. If compliance results are available, identify two failing controls and capture:

    | Field | Control 1 | Control 2 |
    |-------|-----------|-----------|
    | Control ID and title | | |
    | Backing policy name | | |
    | Quick fix available (Y/N) | | |

1. If results are not yet available, review the standards and controls hierarchy. In a populated environment, each control shows its compliance state, backing policy assessments, affected resources, and available remediation guidance.
---

## Investigate CSPM Secret Scanning Findings

1. Open **Cloud Security Posture Management** and navigate to **Secret scanning**.

1. If a finding is available for **<web-app-name>**, open it and record:

    | Field | Value |
    |-------|-------|
    | Finding type | |
    | Affected resource | <web-app-name> |
    | Detected secret category | |

1. If no finding is present, review the filters and finding fields. In a populated environment, a secret-scanning finding identifies the exposed secret category, affected resource, evidence location, severity, and remediation guidance.

1. Open **<web-app-name>** configuration and identify the synthetic exposed app setting.

1. Open **<key-vault-name>** and confirm the managed secret baseline exists.

1. Explain why secrets in app settings are flagged, why properly stored Key Vault secrets are treated differently, and why this distinction matters for remediation ownership.
---

## Review Attack Path Analysis

1. Open **Attack path analysis**.

1. If attack paths are available, open the highest-severity path and record:

    | Step | Resource or edge |
    |------|-------------------|
    | Initial exposure | |
    | Lateral movement | |
    | Blast radius target | |

1. Record one mitigation action recommended by Defender for Cloud.

1. If no attack path is available, review the filters and graph legend. In a populated environment, an attack path connects an initial exposure through exploitable relationships to a high-value target and includes affected resources and mitigation guidance.
---

## Assign Governance Ownership

1. Return to **Recommendations**.

1. If an open recommendation is available, select it and assign a **Governance rule** with these settings:

    - Owner: **User3**
    - Due date: 14 days from today
    - Notification cadence: weekly

1. Save the governance assignment and confirm the owner and due date appear in recommendation details.

1. If no recommendation is available, review the governance controls without saving. In a populated environment, governance assignment records an owner, due date, notification cadence, and remediation status for selected recommendations.
---

## Optional Task: Review Multicloud Connector Scope

1. Open **Environment settings** and select **AWS** connectors.

1. If a connector exists, review covered resource types and finding contribution.

1. If no connector exists in your environment, mark this step as not configured in your notes.

---

## Summary

In this lab, you followed the Defender for Cloud posture-management workflow. Depending on data availability, you either examined live posture results or used the guided-review path to understand what each populated view would provide:

- How Secure Score and recommendation impact quantify risk.
- How posture maps to a named compliance framework.
- How secret-scanning findings distinguish exposed secrets from managed Key Vault secrets.
- How attack paths provide context for prioritization.
- How governance assignments establish ownership and timelines.

If the environment remains available long enough for Defender processing to finish, you can optionally return to these views and compare live results with the expected workflows described in this lab.

This guided review represents the core operating pattern for cloud security posture management at scale.