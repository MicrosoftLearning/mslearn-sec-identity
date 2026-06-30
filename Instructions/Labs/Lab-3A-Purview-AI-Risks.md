---
lab:
    title: 'Identify AI Data Risks with Microsoft Purview'
    description: 'Navigate the Microsoft Purview DSPM for AI (classic) dashboard to identify SharePoint oversharing risks, unlabeled sensitive data accessible to Copilot, and Copilot interaction signals for a pre-seeded site.'
    level: 300
    duration: 45
    islab: true
    primarytopics:
        - Microsoft Purview DSPM
        - AI Data Risk
        - SharePoint Oversharing
---

# Optional Lab Only

Lab Profile = Bring Your Own Subscription (BYOS)

Note that this lab is still pending completion. The Purview DSPM tool will finalize in mid-September. At this time, this lab can be finalized and used with an ALH tenant.  The lab as written will function in a BYOS scenario now. So if you are working on this lab in a user owned tenant, feel free to test it.

Please read through to learn the steps that are required. We apologize for the delay in this lab.

===


# Identify AI Data Risks with Microsoft Purview

Your organization deployed Microsoft 365 Copilot six months ago. No one has reviewed what data Copilot can access on behalf of users since deployment. A security review request asks you to identify which SharePoint sites are overexposed and what risk signals Purview is surfacing about Copilot data access — before the next compliance audit.

As a Cloud and AI Security Engineer, you are not an information protection worker. You will not be configuring Purview policy, applying sensitivity labels, or changing SharePoint permissions. Your job is to navigate the Data Security Posture Management dashboard, understand what each finding means as a security risk, and determine which remediation actions to recommend and to whom.

In this lab, you will:

- Navigate the Microsoft Purview DSPM for AI (classic) dashboard
- Identify a SharePoint site with oversharing conditions that make it accessible to Copilot
- Identify unlabeled sensitive data that Copilot can surface without restriction
- Review Copilot interaction signals to understand what data Copilot has already accessed
- Evaluate recommended remediations and identify who owns each action

This exercise should take approximately **45** minutes to complete.

---

## Prerequisites and Setup

> **Important**: This lab requires a pre-configured SharePoint site named **sc500-ai-datastore** with oversharing permissions and sample sensitive documents. 

### Setup Required Before Starting This Lab

**Option 1 - Automated Setup (Recommended)**:
1. Download the setup script from `Allfiles\Lab-3A\lab-3a-setup.ps1`
2. Run in PowerShell 7:
   ```powershell
   .\lab-3a-setup.ps1 -TenantUrl "https://YOUR-TENANT.sharepoint.com"
   ```
3. Wait 2-3 minutes for completion

**Option 2 - Manual Setup**:
- Follow the detailed instructions in `Allfiles\Lab-3A\README.md`

**Option 3 - Skillable Environment**:
- If using Skillable Cloud Slice, the site may be pre-provisioned for you
- Verify by navigating to `https://YOUR-TENANT.sharepoint.com/sites/sc500-ai-datastore`

**Timing Note**: Purview DSPM signals can take 24-48 hours to fully populate after site creation. In a lab environment, you can proceed immediately to explore the dashboard structure, though some risk signals may still be processing.

---

## Open the Purview Data Security Posture Management dashboard

1. Sign in to the **Microsoft Purview compliance portal** `https://purview.microsoft.com` using your **User-1** credentials.

1. Select **Solutions** > **DSPM for AI (classic)**.

    > **Note**: Look for **DSPM for AI (classic)** in the Solutions list — not **DSPM** (the newer version, which requires a first-time configuration wizard) and not **Data Security Posture Management (classic)**. DSPM for AI (classic) provides the focused AI data risk views this lab uses and is available immediately without additional setup.

1. The **Overview** page opens. Review the **Get started** and **Recommendations** sections — you should see risk indicators related to SharePoint oversharing, unlabeled sensitive data, and Copilot interaction signals.

    > **Note**: This is a lab environment with a pre-seeded SharePoint site, so signal counts will be small. In a production tenant these numbers can reach into the thousands. The objective is to understand what each signal type means and how to evaluate it, not to process volume.

---

## Identify the SharePoint oversharing risk

SharePoint oversharing is the most common AI data risk in organizations that have deployed Copilot. When a site is shared with **Everyone** or **Everyone except external users**, Copilot can surface that content for any user who queries it — including documents that user would never think to look for directly. DSPM surfaces these sites so the risk can be identified and escalated.

1. In the **Recommendations** section on the **Overview** page, select **Protect your data from potential oversharing risks**, or in the left navigation select **Data assessments**.

1. Locate **sc500-ai-datastore** in the assessment results.

1. Select **sc500-ai-datastore** to open the site-level exposure details.

1. Review the **Access configuration** section. Confirm the site is shared with **Everyone except external users** at the site level — this is the oversharing condition DSPM flagged.

1. Review the **Sensitive content** section. Note the document types listed — look for any documents flagged as containing personal information, financial data, or other sensitive categories.

1. Review the **Recommended actions** for this site. You should see actions similar to the following:

    | Recommended action | Who owns it |
    |-------------------|-------------|
    | Restrict site permissions to specific groups | SharePoint administrator or site owner |
    | Apply sensitivity labels to flagged documents | Information protection team |
    | Initiate an access review for the site | Security engineer escalates — site owner executes |

    > **Note**: As a security engineer, you identify the finding and produce a clear recommendation. You do not change SharePoint permissions directly — that requires site owner involvement and organizational authority. Your deliverable is the finding and the remediation recommendation.

---

## Review unlabeled sensitive data

Sensitivity labels tell Copilot how to treat a document — whether it can summarize, reference, or share its contents. Unlabeled documents give Copilot no guidance, and it can use them freely. DSPM flags unlabeled sensitive content so the organization knows where labeling gaps create AI risk.

1. Return to the **Overview** page and locate the **Unlabeled sensitive data** section, or select the equivalent item in the left navigation.

1. Locate files associated with **sc500-ai-datastore** that are flagged as unlabeled sensitive content.

1. Review the detected content type for each flagged file — note whether the content is classified as HR data, financial data, personally identifiable information, or another category.

1. Confirm that none of the documents in **sc500-ai-datastore** have sensitivity labels applied. In a remediated state, each of these documents would carry a label that controls what Copilot can do with the content.

    > **Note**: Applying sensitivity labels is not a task for this lab. Label policy configuration is a compliance engineering role, not a security engineering role. Your finding here is: unlabeled sensitive data exists in a Copilot-accessible location and is not governed by any label-based access restriction.

---

## Review Copilot interaction signals

The Copilot interactions section shows what data Copilot has recently accessed on behalf of users. This is the evidence that over-permission translates into actual exposure — Copilot does not need a security misconfiguration to access data; it only needs the invoking user to have access.

1. Return to the **Overview** page and locate the **Copilot interactions** section, or select the equivalent item in the left navigation.

1. Review the recent Copilot interaction entries. Look for any interactions that reference content from **sc500-ai-datastore**.

1. Note the type of data accessed in those interactions — for example, a document summarization query that pulled from the pre-seeded HR data in the site.

1. Consider the attack path this creates: if an attacker compromises a user account that has access to **sc500-ai-datastore**, they can use Copilot to rapidly extract and summarize sensitive content from the site without ever browsing to the files. Copilot makes existing over-permission faster and more powerful — DSPM's job is to make that risk visible before it is exploited.

---

## Evaluate the findings

1. Based on your review, confirm that **sc500-ai-datastore** presents three distinct risk signals:

    | Risk signal | Root cause | Security implication |
    |-------------|-----------|---------------------|
    | **Oversharing** | Site shared with Everyone | All users — and Copilot acting on their behalf — can access HR and financial content |
    | **Unlabeled data** | No sensitivity labels applied | Copilot can reference and surface document content with no policy restriction |
    | **Copilot interaction exposure** | Copilot has already accessed content on behalf of users | The theoretical risk has already become an actual access event |

1. For each risk signal, confirm you can identify the recommended remediation and the role that owns the action. A security engineer's output from this review is an escalation to the site owner (for permissions) and a referral to the information protection team (for labeling). The security engineer does not directly execute either action.

1. Select **Overview** in the left navigation to return to the DSPM for AI (classic) main view and confirm no other high-priority signals require immediate escalation in this environment.

---

## Summary

In this lab, you navigated the Microsoft Purview DSPM for AI (classic) dashboard and identified three AI data risk signals associated with a pre-seeded SharePoint site: a site-level oversharing condition that makes its content accessible to Copilot for all users, unlabeled sensitive documents that carry no policy-based access restriction, and evidence of actual Copilot interactions that accessed that content.

You reviewed the recommended remediations for each finding and identified that the remediation actions belong to the SharePoint administrator, the information protection team, and the site owner — not to the security engineer. As a Cloud and AI Security Engineer, your contribution is the posture visibility review: finding the risk, understanding what it means, and producing a clear recommendation for the people who own the fix.

You have successfully completed this exercise.

## Clean up

No resources were created in this lab. No cleanup is required.
