---
lab:
    title: 'Configure Privileged Identity Management'
    description: 'Configure PIM-eligible role assignments, activation settings, and approval workflows to enforce just-in-time privileged access to Microsoft Entra roles.'
    level: 300
    duration: 45
    islab: true
    primarytopics:
        - Microsoft Entra Privileged Identity Management
        - Conditional Access
---

# Lab Setup

This lab runs on a M365 Tenant with no special configuration needed.

===

# Configure Privileged Identity Management

Privileged Identity Management (PIM) is a Microsoft Entra ID service that enables just-in-time (JIT) privileged access to Azure and Microsoft Entra roles. Instead of granting permanent admin access — which creates a persistent attack surface — PIM requires users to request and activate elevated access for a limited time window, with optional approval and justification requirements.

In this lab, you will configure PIM for the Conditional Access Administrator role, enforce an approval-based activation workflow, and validate that elevated access works as expected.

In this lab, you will:

- Assign the Conditional Access Administrator role as a PIM-eligible role assignment
- Configure activation settings including a time limit, justification requirement, and approver
- Request and approve a role activation using two separate accounts
- Verify that the activated role grants the expected access
- Deactivate the role to close the just-in-time access window

This exercise should take approximately **45** minutes to complete.

---

## Assign a PIM-eligible role

In this section, you assign the Conditional Access Administrator role to **Adele Vance** as an eligible assignment. An eligible assignment means the user does not hold the role permanently — they must request and activate it each time they need it.

1. Sign in to the Microsoft Entra admin center at `https://entra.microsoft.com` as **MOD Administrator** — sign-in name `admin@<your-tenant>.onmicrosoft.com` and the **User Password** from the Resources tab.

1. In the left navigation, expand **ID Governance** and select **Privileged Identity Management**.

1. Under **Manage**, select **Microsoft Entra roles**.

1. Select **Assignments**, then select **Add assignments**.

1. On the **+ Add assignments** page, configure the following:

    | Setting | Value |
    |---------|-------|
    | **Select role** | Conditional Access Administrator |
    | **Select members** | Adele Vance |
    | **Assignment type** | Eligible (after using the Next button) |

1. Select **Next**, then select **Assign** to save the assignment.

1. On the **Assignments** page, confirm that **Adele Vance** appears under the **Eligible assignments** tab with the role **Conditional Access Administrator**.

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
    | **Other settings** | Leave at default value |

1. Under **Select approvers**, select **+ Select members**.

1. Search for and select **MOD Administrator**, then choose **Select**.

1. Select **Update** to save the role settings.

1. Verify the role settings page now shows:
    - Maximum activation duration: **1 hour**
    - Approval required: **Yes**
    - Approver: **MOD Administrator**

---

## Request role activation

Now you will sign in as **Adele Vance** and submit a role activation request. This simulates a user who needs temporary elevated access to perform a specific task.

1. Open a new **InPrivate** or **Private** browser window.

1. Navigate to the Entra admin center using `https://entra.microsoft.com`. Sign in as **Adele Vance** — sign-in name `AdeleV@<your-tenant>.OnMicrosoft.com` and the **User Password** from the Resources tab.

1. In the left navigation, expand **ID Governance** and select **Privileged Identity Management**.

1. Under **Tasks**, select **My roles**.

1. Select the **Microsoft Entra roles** tab.

1. Under **Eligible assignments**, find **Conditional Access Administrator** and select **Activate**.

1. On the **Activate** pane, configure the following:

    | Setting | Value |
    |---------|-------|
    | **Duration** | 1 hour |
    | **Justification** | `Reviewing and updating Conditional Access policies as part of a scheduled security review.` |

1. Select **Activate**.

    You will see a confirmation that the request is pending approval. The role is not yet active — it requires approval from **MOD Administrator** before access is granted.

1. Leave this browser window open — you will return to it after approving the request.

---

## Approve the activation request

You will now switch back to the **MOD Administrator** browser window and approve the pending activation request.

1. Return to your primary browser window (**MOD Administrator** is currently signed in).

1. Navigate to the Microsoft Entra admin center.

1. In the left navigation, expand **ID Governance** and select **Privileged Identity Management**.

1. Under **Tasks**, select **Approve requests**.

1. Select the **Microsoft Entra roles** menu item.

1. Find the pending request from **Adele Vance** for the **Conditional Access Administrator** role.

1. Add a mark in the box next to the request, then select **Approve**.

1. In the **Justification** field, enter: `Approved for scheduled security review task.`

1. Select **Submit**.

    You should see an approval message pop-up.

1. You can now minimize this browser window.

---

## Verify the activated role

Return to the **Adele Vance** browser window and verify that the role activation succeeded and grants the expected access.

1. In the **Adele Vance** browser window, refresh the page.

1. In **Privileged Identity Management > My roles > Microsoft Entra roles**, select the **Active assignments** tab.

1. Confirm that **Conditional Access Administrator** appears with a status of **Active** and an expiration time approximately 1 hour from now.

## Test the activation in Conditional Access

1. Look at the menu on the left.

1. In the left navigation, find the **Entra ID** section and select **Conditional Access**.

1. Select **+ Create New policy** to open the policy creation pane.

    > **Note**: If you can open the new policy pane, the role is active and granting the expected permissions. A user without this role would see an error or the option would be unavailable.

1. Select **X** to close the policy pane without saving — creating a policy is not required for this verification step.

---

## Deactivate the role

Just-in-time access means access should be released as soon as the task is complete — not held until the time window expires. You will now manually deactivate the Conditional Access Administrator role for **Adele Vance**.

1. Return to the **Adele Vance** browser window (My roles shows the currently signed-in user's assignments, so deactivation must be done from Adele's window — not the MOD Administrator window).

1. Navigate to **Privileged Identity Management > My roles > Microsoft Entra roles > Active assignments**.

1. Find the **Conditional Access Administrator** assignment and select **Deactivate**.

1. In the confirmation dialog, select **Deactivate** again.

1. Confirm the role no longer appears under **Active assignments** and has returned to **Eligible assignments** only.

    The access window is now closed. If Adele needs to perform CA Admin tasks again, she must submit a new activation request.

---

## Summary

In this lab, you configured Privileged Identity Management to enforce just-in-time access to the Conditional Access Administrator role. You assigned an eligible role to **Adele Vance**, configured activation settings with a time limit, justification requirement, and named approver, then walked through the full activation and approval workflow. You verified that the activated role granted the expected access, and manually deactivated the role to close the access window.

You have successfully completed this exercise.

## Clean up

The lab environment is automatically reset at the end of the session. No manual resource deletion is required.

If you want to clean up the PIM assignment before the session ends:

1. Sign in to the Entra admin center as your Global Administrator.
1. Navigate to **Privileged Identity Management > Microsoft Entra roles > Assignments**.
1. Find the **Conditional Access Administrator** eligible assignment for **Adele Vance**.
1. Select **Remove** and confirm.
