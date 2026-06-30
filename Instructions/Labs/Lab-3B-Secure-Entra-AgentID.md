---
lab:
    title: 'Secure Microsoft Entra Agent Identities'
    description: 'Locate a pre-provisioned Copilot Studio agent identity in Microsoft Entra ID, create Conditional Access policies scoped to agent identities and agent user accounts, analyze blast radius in Microsoft Defender XDR, manage the agent in the Microsoft 365 admin center, and enable real-time protection in Copilot Studio.'
    level: 300
    duration: 60
    islab: true
    primarytopics:
        - Microsoft Entra Agent ID
        - Conditional Access
        - Microsoft Defender XDR
        - Copilot Studio
---

# Lab Setup

Lab profile - https://labondemand.com/LabProfile/217879

This lab runs on a Cloud Slice. NOTE - this lab is a work in progress as the technology around the Entra Agent ID is evolving almost daily. The steps as written worked on June 30, 2026. However with regular product changes you may find that the setups are not 100% accruate.  We don't have a lab setup for this lab yet, as it keeps changing. We will add a lab setup, once things stablize.

===

# Secure Microsoft Entra Agent Identities

Your organization's development team deployed a Copilot Studio agent that has read access to a SharePoint site containing HR data and can send calendar invitations on behalf of users. No Conditional Access policy governs when the agent can authenticate, and no one has assessed what an attacker could do if the agent identity were compromised.

A security review request asks you to apply governance controls to the agent identity and determine its blast radius before the next risk assessment cycle.

In this lab, you will:

- Locate the agent identity in Microsoft Entra ID and understand how it differs from a user identity and a service principal
- Create a risk-based Conditional Access policy targeting all agent identities
- Create a second Conditional Access policy targeting agent user accounts, and understand why MFA is not an available grant control for this scope
- Analyze the agent's blast radius using Microsoft Defender XDR
- Manage the agent's configured connections in the Microsoft 365 admin center
- Enable real-time protection for the agent in Copilot Studio

This exercise should take approximately **60** minutes to complete.

> **Note**: This lab uses one account — your **Global Administrator** credentials — to access four different portals: the Microsoft Entra admin center, Microsoft Defender XDR, the Microsoft 365 admin center, and Copilot Studio. Credentials are in the **Resources** tab of your lab environment.

---

## Create and Agent in Foundry to populate the Agent ID

1. Open the **Azure Portal** at `https://portal.azure.com`

1. Log in as **User-1** using the provided credentials.

1. Select **Yes** one the **Stay signed in?** dialog.

1. In the **Search resources...** bar search for and open `Microsoft Foundry`.

1. Select **Create a resource**.

1. Use the following values on the **Basics** tab:

   - Subscription -- **Use provided subscription**
   - Resource Group -- **Create new** --> **lab3b-rg**
   - Name -- **sc500-copilot-agent**
   - Region -- **Use the default**
   - Default project name -- **sc500-proj-default**

1. Select **Review + create**.

1. After the validation completes, select **Create**.

   > **Note**: it should take about 30-seconds to create.

1. Select **Go to resource**.

1. Select the **Go to Foundry portal** button.

1. Find the box **Build an agent** and select **Start building**

1. Enter **Agent name** of `sc500-lab-test` into the box.

1. Select **Create**.

1. When the **sc500-lab-test** opens, review the information on the page.

1. In the **Instructions** box type `This is a test agent`.

1. Select **Save** in the upper-right.

---

## Locate the agent identity in Microsoft Entra ID

Every Copilot Studio agent is registered in Microsoft Entra ID as a distinct identity type — separate from users, service principals, and managed identities. Before applying security controls, you need to understand what an agent identity object looks like in the directory.

1. Sign in to the **Microsoft Entra admin center** at `https://entra.microsoft.com` using your **Administrator** credentials.

1. In the left navigation, browse to **Entra ID** > **Agents** > **Agent identities**.

    > **Note**: **Agents** is a dedicated hub in the Entra admin center for managing non-human AI identities. It is separate from **Applications** (which contains App registrations and Enterprise applications). Under **Agents** you will find **Agent identities**, **Agent blueprints**, **Sign-in logs**, and an **Overview**. Agent identities carry additional metadata — including the agent's purpose, its configured connections, and the team that deployed it — that standard service principals do not.

1. Locate **sc500-copilot-agent** in the list and select it to open the identity details.

1. Review the agent identity properties. Note the following:

    | Field | What it tells you |
    |-------|------------------|
    | **Object type** | AgentIdentity — distinct from User, Application, or ServicePrincipal |
    | **Connections** | The data sources and services this agent is authorized to access |
    | **Created date** | When the agent was registered in the tenant |

1. In the left navigation, expand **Users** and select **All users**.

1. Search for **sc500-copilot-agent** in the user list.

    You should find an entry for the agent alongside the standard user accounts. This is the agent's **user account** — a second, separate directory object that Entra ID creates when an agent needs a mailbox, Teams presence, or any resource that requires a user-type object.

    > **Note**: The dual-object model is the most important concept in this lab. Every Entra Agent ID has an **agent identity** service principal (what you found under Agent identities) and, in some cases, an **agent's user account** (what you found in All Users). These are two distinct directory objects that require two different Conditional Access policy targets. More critically: any existing CA policy that targets **All users** — including your organization's baseline MFA policy — will also hit the agent's user account. Since the agent cannot fulfill an MFA challenge, an "All users, require MFA" policy will block the agent entirely. Designing around this is part of the next task.

---

## Create Conditional Access policies for agent identities

Conditional Access policies for non-human identities work differently from policies for users. Agent identities cannot fulfill interactive challenges (MFA, device compliance prompts), so the available grant controls are limited to **Block** or **Allow**. The relevant conditions are risk signals, not location or authentication method.

You will create two policies: one for agent identities (the service principal object) and one for agent user accounts (the user-type object in All Users). These two scopes require separate policies because they target different directory object types.

### Policy 1 — Block high-risk agent identity sign-ins

1. In the Entra admin center, expand **Protection** and select **Conditional Access**.

1. Select **+ Create new policy**.

1. In the **Name** field, enter:

    ```input
    sc500-agent-risk-block
    ```

1. Under **Assignments**, select **Users or agents (Preview)**.

1. In the **What does this policy apply to?** dropdown, select **Agents (Preview)**.

1. Under **Include**, select **Select agents**.

1. From the list, mark the **sc500-copilot-agent**, and then choose **Select**.

1. Under **Access controls**, select **Grant**.

    - Select **Block access**
    - Select **Select**

1. Under **Enable policy**, select **On**.

    > **Note**: This policy is set to **Report-only** because triggering a medium- or high-risk agent sign-in event to verify enforcement is not practical in a lab environment. In a production tenant, switch to **On** after reviewing the What If tool output to confirm no legitimate agent operations would be blocked.

1. Select **Create**.

### Policy 2 — Govern agent user account access

1. Select **+ Create new policy**.

1. In the **Name** field, enter:

    ```input
    sc500-agent-user-block
    ```

1. Under **Assignments**, select **Users or workload identities**.

1. In the **What does this policy apply to?** dropdown, select **Users and groups**.

1. Under **Include**, select **Select users and groups**, then check **All agent users**.

    > **Note**: **All agent users** is a dedicated scope that targets agent user accounts without including standard user accounts. If you targeted **All users** instead, your policy would also cover human users — and the Block grant you are about to apply would lock out every user in the tenant.

1. Under **Access controls**, select **Grant**.

    - Select **Block access**
    - Select **Select**

    > **Note**: Notice that **Require multifactor authentication** is not available as a grant option for this scope. This is by design — the agent's user account is a non-human identity that cannot respond to an MFA prompt. Block is the only meaningful enforcement option. This is also the answer to the CA trap described earlier: if your baseline "All users, require MFA" policy catches the agent's user account, the agent is silently blocked — not prompted. The correct design is to scope agent user account enforcement separately, as you are doing here.

1. Under **Enable policy**, select **On**.

1. Select **Create**.

1. Return to the **Conditional Access** policies list and confirm both **sc500-agent-risk-block** and **sc500-agent-user-block** are listed.

---

## Enable real-time protection in Copilot Studio

Real-time protection monitors agent behavior during execution and can block or flag actions that fall outside defined policies. This is a runtime behavioral control — it operates when the agent is running, not at sign-in time, complementing the Conditional Access controls you configured earlier.

1. Open a new browser tab and navigate to [Copilot Studio](https://copilotstudio.microsoft.com).

1. From the environment selector at the top of the page, confirm you are in the correct tenant environment.

1. In the left navigation, select **Agents**, then locate and select **sc500-copilot-agent**.

1. In the agent settings, select the **Security** tab.

    > **Note**: Depending on the Copilot Studio version in your environment, this may appear as **Advanced settings** or within a **Security and compliance** section. Look for **Real-time protection** as the target setting.

1. Locate the **Real-time protection** setting and set it to **Enabled**.

1. Review the protection options and confirm the following are active:

    | Protection option | What it does |
    |------------------|-------------|
    | **Content moderation** | Blocks agent responses that violate configured content policies at runtime |
    | **Data loss prevention** | Prevents the agent from sharing sensitive content outside approved channels |
    | **Anomaly detection** | Flags unusual agent behavior patterns for security team review |

1. Select **Save** to apply the real-time protection settings.

    > **Note**: Real-time protection builds a behavioral baseline for the agent over time. Early alerts may require review to distinguish legitimate agent behavior from anomalies. Review flagged events in Microsoft Defender XDR, where agent security alerts from Copilot Studio real-time protection appear alongside other identity alerts.

---

## Summary

In this lab, you worked with a Copilot Studio agent identity across four portals to apply a layered set of governance controls.

In Microsoft Entra ID, you located the agent's dual-object model — the agent identity service principal and the agent's user account in All Users — and understood the CA policy design implications of that two-object structure. You created two Conditional Access policies: one risk-based blocking policy targeting all agent identities, and one block-only policy targeting agent user accounts, with a note on why MFA is not available as a grant control for non-human identities.

In Microsoft Defender XDR, you analyzed the blast radius for **sc500-copilot-agent** and identified two attack paths — SharePoint access to sensitive HR data and delegated calendar access — that represent the agent's attack surface if compromised.

In the Microsoft 365 admin center, you disabled the agent's SharePoint connection to **sc500-ai-datastore**, removing the higher-risk attack path identified in the blast radius analysis.

In Copilot Studio, you enabled real-time protection to add a runtime behavioral monitoring layer on top of the identity governance controls.

You have successfully completed this exercise.

## Clean up

The lab environment is automatically reset at the end of the session. No manual resource deletion is required.

If you want to remove the Conditional Access policies before the session ends:

1. Navigate to the Entra admin center > **Protection** > **Conditional Access**.
1. Select **sc500-agent-risk-block**, select **Delete**, and confirm.
1. Select **sc500-agent-user-block**, select **Delete**, and confirm.
