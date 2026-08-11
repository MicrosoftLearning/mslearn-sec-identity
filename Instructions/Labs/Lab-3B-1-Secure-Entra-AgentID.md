---
lab:
    title: 'Secure Microsoft Entra agent identities with Conditional Access'
    description: 'Examine the dual-object model for a pre-provisioned Microsoft Entra agent and create Report-only Conditional Access policies for its agent identity and agent user account.'
    level: 300
    duration: 45
    islab: true
    primarytopics:
        - Microsoft Entra Agent ID
        - Conditional Access
---

# Lab setup

This lab uses a Microsoft 365 tenant with the following items already configured:

- A Microsoft Entra ID P2 license
- A pre-provisioned agent identity named **sc500-copilot-agent**
- An agent user account named **sc500-copilot-agent**
- An administrator account named **MOD Administrator** with permission to manage Conditional Access

Sign in using the credentials provided for **MOD Administrator**. If either agent object is unavailable, you cannot complete this lab.

===

# Secure Microsoft Entra agent identities with Conditional Access

AI agents can have more than one Microsoft Entra object. The agent identity represents the non-human workload. An agent can also have an associated user account when it needs access to services that require a user identity. These objects have different security characteristics and must be governed separately.

In this lab, you will:

- Locate a pre-provisioned agent identity and review its properties
- Locate the associated agent user account
- Compare the two identity objects
- Create a Report-only Conditional Access policy for the agent identity
- Create a separate Report-only policy for the agent user account

This exercise should take approximately **45** minutes to complete.

---

## Verify the agent identity

1. Sign in to the Microsoft Entra admin center at `https://entra.microsoft.com` as **MOD Administrator** using the credentials provided.

1. In the left navigation, expand **Entra ID**, and then select **Agents**.

1. Select **Agent identities**.

1. Search for `sc500-copilot-agent`.

1. Confirm that **sc500-copilot-agent** appears in the results, and then select it.

    > **Important**: If the agent identity does not appear, stop. The required environment prerequisite has not been provisioned.

1. Review the available properties, including:

    - Display name
    - Object ID
    - Agent identity blueprint or parent blueprint
    - Created date
    - Owners, sponsors, or related identities, when available

1. Record the object ID in a temporary text file. You will use it only to distinguish this object from the agent user account.

1. Return to **Agents**, and then select **Agent blueprints**.

1. Confirm that the blueprint associated with **sc500-copilot-agent** appears.

    The blueprint is the reusable definition from which the agent identity was created. The agent identity is the individual non-human identity produced from that definition.

---

## Verify the agent user account

1. In the left navigation, expand **Entra ID**, and then select **Users**.

1. Select **All users**.

1. Search for `sc500-copilot-agent`.

1. Select the agent user account.

    > **Important**: If an agent user account does not appear, stop. The second required environment prerequisite has not been provisioned.

1. Review the available properties, including:

    - Display name
    - User principal name
    - Object ID
    - User type
    - Account status

1. Compare this object ID with the agent identity object ID you recorded earlier. Confirm that they are different.

    The two objects serve different purposes:

    | Object | Purpose | Conditional Access target |
    |---|---|---|
    | Agent identity | Represents the non-human agent workload | **Agents** |
    | Agent user account | Provides user-type access when a service requires it | **Users** |

1. Delete the temporary text file containing the object ID.

---

## Create a Report-only policy for the agent identity

You will create a policy that targets the non-human agent identity. Report-only mode allows administrators to evaluate the policy without disrupting the agent.

1. In the left navigation, select **Conditional Access**.

1. Select **+ Create new policy**.

1. In **Name**, enter:

    ```input
    sc500-agent-identity-report-only
    ```

1. Under **Assignments**, select **Users or agents**.

1. For **What does this policy apply to?**, select **Agents**.

1. Under **Include**, choose **Select agents**.

1. Search for and select **sc500-copilot-agent**, and then select **Select**.

1. Under **Target resources**, select **Resources (formerly cloud apps)**.

1. Under **Include**, select **All resources (formerly All cloud apps)**.

1. Under **Access controls**, select **Grant**.

1. Select **Block access**, and then select **Select**.

1. Under **Enable policy**, select **Report-only**.

1. Review the policy configuration and select **Create**.

    > **Note**: Do not set this policy to **On** in the lab. Report-only mode avoids disrupting a pre-provisioned agent while still demonstrating the correct identity scope.

---

## Create a Report-only policy for the agent user account

The agent user account is a separate user object, so it requires a separate policy with a user target.

1. On the **Conditional Access | Policies** page, select **+ Create new policy**.

1. In **Name**, enter:

    ```input
    sc500-agent-user-report-only
    ```

1. Under **Assignments**, select **Users or agents**.

1. For **What does this policy apply to?**, select **Users**.

1. Under **Include**, choose **Select users and groups**.

1. Search for and select the **sc500-copilot-agent** user account, and then select **Select**.

1. Under **Target resources**, select **Resources (formerly cloud apps)**.

1. Under **Include**, select **All resources (formerly All cloud apps)**.

1. Under **Access controls**, select **Grant**.

1. Select **Block access**, and then select **Select**.

1. Under **Enable policy**, select **Report-only**.

1. Review the policy configuration and select **Create**.

    > **Note**: Do not add an MFA grant requirement. An agent cannot respond to an interactive MFA challenge. Report-only block policies let administrators evaluate the potential effect before enforcement.

---

## Verify the Conditional Access policies

1. Return to **Conditional Access | Policies**.

1. Confirm that both policies appear:

    - **sc500-agent-identity-report-only**
    - **sc500-agent-user-report-only**

1. Confirm that the state of both policies is **Report-only**.

1. Open **sc500-agent-identity-report-only** and confirm that its identity scope targets **Agents** and includes **sc500-copilot-agent**.

1. Return to the policy list, open **sc500-agent-user-report-only**, and confirm that its identity scope targets **Users** and includes the agent user account.

1. Close the policy without making changes.

---

## Summary

In this lab, you examined the two Microsoft Entra objects used by a pre-provisioned agent. You confirmed that the agent identity and agent user account have different object IDs and serve different purposes. You then created separate Report-only Conditional Access policies so each identity type can be evaluated without disrupting the agent.

You have successfully completed this exercise.

## Clean up

The lab environment is automatically reset at the end of the session. No manual cleanup is required.

If you want to remove the policies before the session ends:

1. In the Microsoft Entra admin center, navigate to **Conditional Access**.
1. Select **sc500-agent-identity-report-only**, select **Delete**, and confirm.
1. Select **sc500-agent-user-report-only**, select **Delete**, and confirm.
