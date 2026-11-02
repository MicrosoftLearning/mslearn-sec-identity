---
lab:
    title: 'Secure Microsoft Entra Agent Identities'
    description: 'Create an agent in Microsoft Foundry, locate its agent identity in Microsoft Entra ID, create Conditional Access policies scoped to agent identities and agent user accounts, and enable real-time protection in Microsoft Defender.'
    level: 300
    duration: 60
    islab: true
    primarytopics:
        - Microsoft Entra Agent ID
        - Conditional Access
        - Microsoft Foundry
        - Microsoft Defender XDR
---

# Lab Setup

Follow these steps to complete the lab. **Note**: This lab is a work in progress as the technology around the Entra Agent ID is evolving almost daily. The steps as written worked on June 30, 2026. However with regular product changes you may find that the setups are not 100% accurate. We don't have a lab setup for this lab yet, as it keeps changing. We will add a lab setup, once things stabilize.

> **Note**: The steps refer to a hosted lab environment (**User1**, "the provided subscription", automatic reset). If you use your own tenant, you need a Global Administrator account, a **Microsoft Agent 365** licence together with Microsoft Entra ID P1 (or Microsoft 365 E7) to target agents in Conditional Access, Microsoft Entra ID P2 for the agent risk condition in Policy 1, an Azure subscription where you can create a Microsoft Foundry resource, and access to Security for AI in the Microsoft Defender portal for the last section.

===

# Secure Microsoft Entra Agent Identities

Your organization's development team deployed an AI agent that has read access to a SharePoint site containing HR data and can send calendar invitations on behalf of users. No Conditional Access policy governs when the agent can authenticate, and no one has assessed what an attacker could do if the agent identity were compromised.

A security review request asks you to apply governance controls to the agent identity and determine its blast radius before the next risk assessment cycle.

In this lab, you will:

- Locate the agent identity in Microsoft Entra ID and understand how it differs from a user identity and a service principal
- Create a risk-based Conditional Access policy targeting all agent identities
- Create a second Conditional Access policy targeting agent user accounts, and understand why MFA is not an available grant control for this scope
- Enable real-time protection for the agent in Microsoft Defender

This exercise should take approximately **60** minutes to complete.

> **Note**: This lab uses one account — **User1** (`sc500-user1-`), which is the seeded Global Administrator — to access three portals: the Azure portal and Microsoft Foundry, the Microsoft Entra admin center, and the Microsoft Defender portal. Use the credentials provided for this account.

---

## Create an agent in Foundry to populate the Agent ID

1. Open the **Azure Portal** at `https://portal.azure.com`

1. Log in as **User1** using the provided credentials.

1. Select **Yes** on the **Stay signed in?** dialog.

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

1. On the Foundry portal resources page, select the **sc500-proj-default** project.

1. Find the box **Build an agent** and select **Start building**

1. Enter **Agent name** of `sc500-lab-test` into the box.

1. Select **Create**.

1. When the **sc500-lab-test** opens, review the information on the page.

1. In the **Instructions** box type `This is a test agent`.

1. Select **Save** in the upper-right.

---

## Locate the agent identity in Microsoft Entra ID

Agents created in Microsoft Foundry and Copilot Studio are registered in Microsoft Entra ID as a distinct identity type — separate from users, service principals, and managed identities. Before applying security controls, you need to understand what an agent identity object looks like in the directory.

1. Sign in to the **Microsoft Entra admin center** at `https://entra.microsoft.com` using your **Administrator** credentials.

1. In the left navigation, browse to **Entra ID** > **Agents** > **Agent identities**.

    > **Note**: **Agents** is a dedicated hub in the Entra admin center for managing non-human AI identities. It is separate from **Applications** (which contains App registrations and Enterprise applications). Under **Agents** you will find **Agent identities**, **Agent blueprints**, **Sign-in logs**, and an **Overview**. Agent identities carry additional metadata that standard service principals do not, such as the **agent blueprint** they were created from and the **sponsors** who are accountable for them.

1. Locate **sc500-copilot-agent** in the list and select it to open the identity details.

1. On the **Overview** page, review the agent identity properties. Note the following:

    | Field | What it tells you |
    |-------|------------------|
    | **Agent identity** badge | The object is an agent identity, distinct from a user, an app registration, or an ordinary service principal |
    | **Sponsors** and **Owners** | The people accountable for the agent and the people who can manage it |
    | **Agent blueprint** and **Blueprint App ID** | The blueprint (template) this agent identity was created from |
    | **Object ID** and **Application ID** | The identifiers you use when scoping policies or searching logs |
    | **Created on** | When the agent was registered in the tenant |

1. In the **Agent identity's access** card, note the number of **Permissions** and **Entra roles** granted to the agent. Select **Granted permissions** in the left navigation to see the details.

1. In the left navigation, expand **Users** and select **All users**.

1. Search for **sc500-copilot-agent** in the user list.

    You should find an entry for the agent alongside the standard user accounts. This is the agent's **user account** — a second, separate directory object that Entra ID creates when an agent needs a mailbox, Teams presence, or any resource that requires a user-type object.

    > **Note**: The dual-object model is the most important concept in this lab. Every Entra Agent ID has an **agent identity** service principal (what you found under Agent identities) and, in some cases, an **agent's user account** (what you found in All Users). These are two distinct directory objects that require two different Conditional Access policy targets. More critically: any existing CA policy that targets **All users** — including your organization's baseline MFA policy — will also hit the agent's user account. Since the agent cannot fulfill an MFA challenge, an "All users, require MFA" policy will block the agent entirely. Designing around this is part of the next task.

---

## Create Conditional Access policies for agent identities

Conditional Access policies for non-human identities work differently from policies for users. Agent identities cannot fulfill interactive challenges (MFA, device compliance prompts), so the available grant controls are limited to **Block** or **Allow**. The relevant conditions are risk signals, not location or authentication method.

You will create two policies: one for agent identities (the service principal object) and one for agent user accounts (the user-type object in All Users). These two scopes require separate policies because they target different directory object types.

### Policy 1 — Block high-risk agent identity sign-ins

1. In the Entra admin center, browse to **Entra ID** > **Conditional Access** > **Policies**.

1. Select **+ Create new policy**.

1. In the **Name** field, enter:

    ```input
    sc500-agent-risk-block
    ```

1. Under **Assignments**, select **Users, agents or workload identities**.

1. In the **What does this policy apply to?** dropdown, select **Agents**.

1. Under **Include**, select **Select individual agent identities**.

1. In the object picker, select the **Agent identities** tab, select the agent identity you found earlier, and then choose **Select**.

1. Under **Target resources** > **Include**, select **All resources (formerly 'All cloud apps')**.

1. Under **Conditions** > **Agent risk (Preview)**, set **Configure** to **Yes**, select **High**, and then select **Done**.

    > **Note**: Without this condition the policy blocks the agent on every sign-in, not only high-risk ones. Agent risk comes from Microsoft Entra ID Protection and needs Microsoft Entra ID P2 (or Microsoft 365 E5) in addition to the Agent 365 licence.

1. Under **Access controls**, select **Grant**.

    - Select **Block access**
    - Select **Select**

1. Under **Enable policy**, select **Report-only**.

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

## Enable real-time protection in Microsoft Defender

Real-time protection inspects agent activity while the agent runs and can block risky actions, such as secret exfiltration or passing along malicious content, before they execute. This is a runtime behavioral control. It operates when the agent is running, not at sign-in time, and complements the Conditional Access controls you configured earlier.

Real-time protection is configured in the Microsoft Defender portal, not in the agent's own settings. It covers Foundry agents and Copilot Studio agents (both in preview).

> **Note**: The Foundry agent you created in the setup doesn't appear in Copilot Studio. Foundry and Copilot Studio are separate agent platforms, and Copilot Studio only lists agents built in a Power Platform environment.

1. Open a new browser tab and sign in to the [Microsoft Defender portal](https://security.microsoft.com).

1. Go to **Settings** > **Security for AI** > **Policies & rules** > **Real-time protection**.

    > **Note**: If **Security for AI** isn't available, it must be enabled first. See [Enable security for AI agents using Microsoft Defender](https://learn.microsoft.com/defender-xdr/security-for-ai/get-started-defender-security-for-ai).

1. Review the built-in **Default** rule. It audits all agents and records matching activity as a behavior without blocking it.

1. Select **Create rule**.

1. On the **Rule details** step, set **Status** to on, enter the **Rule name** `sc500-agent-runtime-block` and a description, and then select **Next**.

1. Configure the rule:

    - **Scope**: select specific agents, and then select the agent identity you created in the setup. Only agents with a Microsoft Entra agent ID appear in the list.
    - **Detection types**: select the threat scenarios to block, and then select **Apply**.

    | Detection type | What it blocks |
    |----------------|----------------|
    | **Secret exfiltration** | Interactions that expose or try to transfer secrets such as API keys, credentials or access tokens |
    | **Malicious content propagation** | Interactions where the agent receives, generates or passes along content identified as malicious |
    | **Evasion techniques** | Interactions that hide malicious instructions, for example by encoding them |
    | **Unsafe email domain** | Tool calls that would send email to an unsafe or untrusted domain |

1. Select **Next**, review the summary, and then select **Create**.

    > **Note**: When Defender audits or blocks an action, it records the event as a behavior in the `BehaviorInfo` table, including which agent, user and tool were involved. Security teams can use these records for custom detections and hunting.

---

## Summary

In this lab, you created an agent in Microsoft Foundry and worked with its agent identity to apply a layered set of governance controls.

In Microsoft Entra ID, you located the agent's dual-object model — the agent identity service principal and the agent's user account in All Users — and understood the CA policy design implications of that two-object structure. You created two Conditional Access policies: one risk-based blocking policy targeting all agent identities, and one block-only policy targeting agent user accounts, with a note on why MFA is not available as a grant control for non-human identities.

In Microsoft Defender, you created a real-time protection rule that blocks risky agent actions at runtime, adding a behavioral layer on top of the identity governance controls.

You have successfully completed this exercise.

## Clean up

The lab environment is automatically reset at the end of the session. No manual resource deletion is required.

If you want to remove the Conditional Access policies before the session ends:

1. Navigate to the Entra admin center > **Entra ID** > **Conditional Access** > **Policies**.
1. Select **sc500-agent-risk-block**, select **Delete**, and confirm.
1. Select **sc500-agent-user-block**, select **Delete**, and confirm.
