---
lab:
    title: 'Configure Privileged Identity Management'
    description: 'Configure PIM-eligible role assignments, activation settings, and approval workflows to enforce just-in-time privileged access, then enable managed identity on an Azure resource.'
    level: 300
    duration: 45
    islab: true
    primarytopics:
        - Microsoft Entra Privileged Identity Management
        - Conditional Access
        - Managed Identity
---

# Configure Privileged Identity Management

Privileged Identity Management (PIM) is a Microsoft Entra ID service that enables just-in-time (JIT) privileged access to Azure and Microsoft Entra roles. Instead of granting permanent admin access — which creates a persistent attack surface — PIM requires users to request and activate elevated access for a limited time window, with optional approval and justification requirements.

In this lab, you will configure PIM for the Conditional Access Administrator role, enforce an approval-based activation workflow, validate that elevated access works as expected, and then enable a system-assigned managed identity on an Azure App Service.

In this lab, you will:

- Assign the Conditional Access Administrator role as a PIM-eligible role assignment
- Configure activation settings including a time limit, justification requirement, and approver
- Request and approve a role activation using two separate accounts
- Verify that the activated role grants the expected access
- Enable a system-assigned managed identity on a pre-provisioned App Service
- Deactivate the role to close the just-in-time access window

This exercise should take approximately **45** minutes to complete.

> **Note**: This lab uses three accounts: your **Global Administrator** account (your primary lab credentials), **sc500-user01** (the PIM eligible member), and **sc500-approver** (the approver). Credentials for all three accounts are in the **Resources** tab of your lab environment.

---

## Assign a PIM-eligible role

In this section, you assign the Conditional Access Administrator role to **sc500-user01** as an eligible assignment. An eligible assignment means the user does not hold the role permanently — they must request and activate it each time they need it.

1. Sign in to the Microsoft Entra admin center at `https://entra.microsoft.com` using your **Administrator** credentials.

1. In the left navigation, expand **Identity governance** and select **Privileged Identity Management**.

1. Under **Manage**, select **Microsoft Entra roles**.

1. Select **Assignments**, then select **Add assignments**.

1. On the **Add assignments** page, configure the following:

    | Setting | Value |
    |---------|-------|
    | **Select role** | Conditional Access Administrator |
    | **Select members** | sc500-user01 |
    | **Assignment type** | Eligible |

1. Select **Next**, then select **Assign** to save the assignment.

1. On the **Assignments** page, confirm that **sc500-user01** appears under the **Eligible assignments** tab with the role **Conditional Access Administrator**.

    > **Note**: An eligible assignment does not grant access — it only enables the user to request activation. No access is active at this point.

---

## Configure activation settings

PIM role settings control how the activation process works: how long the activation lasts, whether a justification is required, and whether an approver must approve each request. You will now configure the Conditional Access Administrator role settings.

1. In **Privileged Identity Management > Microsoft Entra roles**, select **Settings**.

1. Find and select **Conditional Access Administrator** from the role list.

1. Select **Edit** to open the role settings.

1. On the **Activation** tab, configure the following settings:

    | Setting | Value |
    |---------|-------|
    | **Activation maximum duration** | 1 hour |
    | **On activation, require** | Justification |
    | **Require approval to activate** | Enabled |

1. Under **Select approvers**, select **+ Select members**.

1. Search for and select **sc500-approver**, then choose **Select**.

1. Select **Update** to save the role settings.

1. Verify the role settings page now shows:
    - Maximum activation duration: **1 hour**
    - Approval required: **Yes**
    - Approver: **sc500-approver**

---

## Request role activation

Now you will sign in as **sc500-user01** and submit a role activation request. This simulates a user who needs temporary elevated access to perform a specific task.

1. Open a new **InPrivate** or **Private** browser window.

1. Navigate to [https://entra.microsoft.com](https://entra.microsoft.com) and sign in as **sc500-user01** using the credentials from the **Resources** tab.

1. In the left navigation, expand **Identity governance** and select **Privileged Identity Management**.

1. Under **Tasks**, select **My roles**.

1. Select the **Microsoft Entra roles** tab.

1. Under **Eligible assignments**, find **Conditional Access Administrator** and select **Activate**.

1. On the **Activate** pane, configure the following:

    | Setting | Value |
    |---------|-------|
    | **Duration** | 1 hour |
    | **Justification** | Reviewing and updating Conditional Access policies as part of a scheduled security review. |

1. Select **Activate**.

    You will see a confirmation that the request is pending approval. The role is not yet active — it requires approval from **sc500-approver** before access is granted.

1. Leave this browser window open — you will return to it after approving the request.

---

## Approve the activation request

You will now switch to the **sc500-approver** account and approve the pending activation request.

1. Open a second **InPrivate** or **Private** browser window (separate from the sc500-user01 window).

1. Navigate to [https://entra.microsoft.com](https://entra.microsoft.com) and sign in as **sc500-approver** using the credentials from the **Resources** tab.

1. In the left navigation, expand **Identity governance** and select **Privileged Identity Management**.

1. Under **Tasks**, select **Approve requests**.

1. Select the **Microsoft Entra roles** tab.

1. Find the pending request from **sc500-user01** for the **Conditional Access Administrator** role.

1. Select the request to open it, then select **Approve**.

1. In the **Justification** field, enter:

    ```input
    Approved for scheduled security review task.
    ```

1. Select **Confirm**.

    You should see the request status change to **Approved**.

1. You can now close this browser window.

---

## Verify the activated role

Return to the **sc500-user01** browser window and verify that the role activation succeeded and grants the expected access.

1. In the **sc500-user01** browser window, refresh the page.

1. In **Privileged Identity Management > My roles > Microsoft Entra roles**, select the **Active assignments** tab.

1. Confirm that **Conditional Access Administrator** appears with a status of **Active** and an expiration time approximately 1 hour from now.

1. In the left navigation, expand **Protection** and select **Conditional Access**.

1. Select **+ Create New policy** to open the policy creation pane.

    > **Note**: If you can open the new policy pane, the role is active and granting the expected permissions. A user without this role would see an error or the option would be unavailable.

1. Select **X** to close the policy pane without saving — creating a policy is not required for this verification step.

---

## Enable system-assigned managed identity

A managed identity is an identity automatically managed by Microsoft Entra ID, used by applications and services to authenticate to other Azure resources without storing credentials. In this task, you will enable a system-assigned managed identity on a pre-provisioned App Service.

1. Switch back to your **Global Administrator** browser window (or open a new browser and sign in with your Global Administrator credentials).

1. Navigate to the [Azure portal](https://portal.azure.com).

1. In the search bar, search for and select **App Services**.

1. Select **sc500-lab1a-app** from the list.

1. In the left menu, under **Settings**, select **Identity**.

1. On the **System assigned** tab, set **Status** to **On**.

1. Select **Save**, then select **Yes** to confirm.

    After a few seconds, the page refreshes and displays an **Object (principal) ID** — this is the unique identity assigned to the App Service in Microsoft Entra ID.

1. Note the **Object (principal) ID** value. In a real deployment, you would use this ID to grant the App Service access to other Azure resources such as Key Vault secrets or storage accounts.

    > **Note**: A system-assigned managed identity is tied to the resource — if the App Service is deleted, the identity is automatically removed. This makes it a lower-maintenance option compared to a user-assigned managed identity, which persists independently of the resource.

---

## Deactivate the role

Just-in-time access means access should be released as soon as the task is complete — not held until the time window expires. You will now manually deactivate the Conditional Access Administrator role for **sc500-user01**.

1. Return to the **sc500-user01** browser window.

1. Navigate to **Privileged Identity Management > My roles > Microsoft Entra roles > Active assignments**.

1. Find the **Conditional Access Administrator** assignment and select **Deactivate**.

1. In the confirmation dialog, select **Deactivate** again.

1. Confirm the role no longer appears under **Active assignments** and has returned to **Eligible assignments** only.

    The access window is now closed. If sc500-user01 needs to perform CA Admin tasks again, they must submit a new activation request.

---

## Summary

In this lab, you configured Privileged Identity Management to enforce just-in-time access to the Conditional Access Administrator role. You assigned an eligible role, configured activation settings with a time limit, justification requirement, and named approver, then walked through the full activation and approval workflow. You verified that the activated role granted the expected access, and manually deactivated the role to close the access window. You also enabled a system-assigned managed identity on an Azure App Service, establishing the pattern for workload identity that you will apply to Key Vault access in a later lab.

You have successfully completed this exercise.

## Clean up

The lab environment is automatically reset at the end of the session. No manual resource deletion is required.

If you want to clean up the PIM assignment before the session ends:

1. Sign in to the Entra admin center as your Global Administrator.
1. Navigate to **Privileged Identity Management > Microsoft Entra roles > Assignments**.
1. Find the **Conditional Access Administrator** eligible assignment for **sc500-user01**.
1. Select **Remove** and confirm.
