---
lab:
    title: 'Enforce MFA with Conditional Access'
    description: 'Create a Conditional Access policy that enforces MFA for a named user accessing the Azure portal, validate the policy in Report-only mode using the What If tool, test MFA enforcement at sign-in, and register an application in Entra ID with scoped API permissions.'
    level: 300
    duration: 45
    islab: true
    primarytopics:
        - Microsoft Entra Conditional Access
        - Multifactor Authentication
        - App Registration
---

# Lab Setup

Lab profile - https://labondemand.com/LabProfile/217878

This lab runs on a M365 Tenant with no special configuration needed.

===


# Enforce MFA with Conditional Access

A recent security review of your organization's Entra ID tenant found that access controls rely entirely on Microsoft security defaults — a one-size-fits-all baseline with no targeted policies. At the same time, the AI platform team has registered a new application that accesses sensitive APIs, and one user account was recently flagged as a sign-in risk. Your task is to create a Conditional Access policy that explicitly enforces multifactor authentication (MFA) for a targeted user accessing the Azure portal, validate the policy behavior before enabling it, and register the new AI platform application with appropriately scoped API permissions.

Conditional Access policies are the primary enforcement mechanism in Microsoft Entra ID for applying access controls based on identity signals — user, location, device, and risk level. Unlike security defaults, which apply a fixed set of controls across all users, Conditional Access policies give you precise control over who is affected, what conditions trigger the policy, and what access controls are applied.

In this lab, you will:

- Create a Conditional Access policy that requires MFA for a named user accessing the Azure portal
- Validate the policy behavior using the What If simulation tool before enforcing it
- Enable the policy and confirm MFA is enforced at sign-in
- Register a new application in Entra ID and configure scoped API permissions

This exercise should take approximately **45** minutes to complete.

---

## Create a Conditional Access policy

Conditional Access policies are built from two parts: assignments (who and what the policy applies to) and access controls (what happens when the conditions are met). You will create a policy that targets a specific user and requires MFA when that user accesses the Azure portal.

1. Sign in to the **Microsoft Entra admin center** at `https://entra.microsoft.com` using your *Administrator** credentials.

1. In the left navigation, expand **Entra ID** and select **Conditional Access**.

1. Select **Policies** from the menu, then select **+ New policy**.

1. In the **Name** field, enter: `sc500-require-mfa-portal`

1. Under **Assignments**, select **0 users or agents selected**.

1. On the opened page, choose **Select users and groups**, then mark the **Users and groups** checkbox.

1. Select **Select**, search for and select **Adele Vance**, then select **Select** to confirm.

    > **Note**: Limiting the policy to a single named user lets you validate behavior without affecting administrators or other users. In production, you would expand the scope after confirming the policy works as expected.

1. Under **Assignments**, in the **Target resources** select **No target resources selected** item.

1. On the **Target resources** pane, set the target to **All resources (formerly all cloud apps)**, then select **Select resources**.

1. Under **Select specific resources** select the **None** link.

1. Select **Select**, search for **Office 365**, mark the checkbox, then select **Select** to confirm.

1. Find the **Access controls** section.

1. On the **Grant** section, select the **0 controls selected** item.

1. Select **Require multifactor authentication**, then select **Select**.

3. At the bottom of the policy page, set **Enable policy** to **Report-only**.

4. Select **Create** to save the policy.

    Confirm that **sc500-require-mfa-portal** now appears on the **Conditional Access | Policies** page with a state of **Report-only**.

---

## Validate the policy in Report-only mode

Report-only mode records what a policy would do without blocking or requiring anything from users. The **What If** tool simulates a sign-in so you can confirm the policy applies correctly before you turn it on. Use it now to verify the policy targets the right user and resource.

1. On the **Conditional Access | Policies** page, select **What If** from the toolbar.

1. On the **What If** pane, configure the following:

    | Setting | Value |
    |---------|-------|
    | **Select identity type - Users** | use the **Edit user** to select **Adele Vance** |
    | **Select target type - Cloud apps** | Microsoft Forms |
    | **Sign-in conditions - Device Platform** | Windows |
    | **Sign-in conditions - Client App | Browser |
    | All other settings | Leave at defaults |

1. Scroll down to the bottom of the page.

1. Select **What If** to run the simulation. Then **scroll to the bottom of the page**.

1. Under **Policies that will apply**, confirm that **sc500-require-mfa-portal** appears with a **Grant** control of **Require multifactor authentication**.

    This confirms the policy is correctly scoped — it would enforce MFA for sc500-user02 accessing the Azure portal.

    > **Note**: If the policy does not appear in the results, verify that sc500-user02 is listed under **Included users** in the policy assignments and that **Microsoft Azure Management** is the selected cloud app. Correct any issues before proceeding.

1. Close the **What If** pane.

---

## Enable the policy and verify MFA enforcement

The simulation confirmed the policy is correctly configured. You will now switch the policy to **On** and sign in as sc500-user02 to confirm the MFA prompt is triggered.

1. On the **Conditional Access | Policies** page, select **sc500-require-mfa-portal** to open it.

1. Set **Enable policy** to **On**.

1. Select **Save**.

    The policy state in the policies list should now show **On**.

1. Open a new **InPrivate** or **Private** browser window.

1. Navigate to Microsoft Forms at `https://forms.microsoft.com`.

1. Sign in using the **Adele Vance** credentials from the **Resources** tab.

1. After entering the password, confirm that an MFA prompt appears. This confirms the Conditional Access policy is active and enforcing step-up authentication for this user.

    > **Note**: If you do not see an MFA prompt, verify that the policy state is **On** (not Report-only), that sc500-user02 is listed in the included users scope, and that no exclusions are applied.

1. Complete the MFA challenge using the method registered for sc500-user02. The TOTP code or authenticator details are in the **Resources** tab.

1. Confirm that you are now signed in to the Azure portal. The Conditional Access policy required step-up authentication and granted access after the MFA challenge was completed successfully.

1. Close the InPrivate browser window.

---

## Register an application in Entra ID

The AI platform team needs a registered application identity in Entra ID so their application can authenticate and call APIs on behalf of users. An app registration provides a client ID and a place to define which permissions the application requires. You will register the application and add a scoped delegated permission following the principle of least privilege.

1. Return to your **Global Administrator** browser window at the [Microsoft Entra admin center](https://entra.microsoft.com).

1. In the left navigation, expand **Applications** and select **App registrations**.

1. Select **+ New registration**.

1. On the **Register an application** page, configure the following:

    | Setting | Value |
    |---------|-------|
    | Name | **`sc500-ai-platform-app`** |
    | Supported account types | **Single tenant only - Contoso** |
    | Redirect URI | Leave blank |

1. Select **Register**.

    Entra ID creates the registration and opens the **Overview** page for **sc500-ai-platform-app**.

1. On the **Overview** page, locate the **Application (client) ID** field and copy the value. This value is what you would use when granting access to the application.

    > **Note**: The Application (client) ID is the unique identifier for this registration in Entra ID. Applications use it alongside a client secret or certificate when authenticating against Entra ID during OAuth flows.

1. In the left menu of the app registration, select **API permissions**.

1. Select **+ Add a permission**.

1. On the **Request API permissions** pane, select **Microsoft Graph**.

1. Select **Delegated permissions**.

1. In the search box, search for **`User.Read`**.

1. Expand **User**, select **User.ReadBasic.All**, then select **Add permissions**.

    > **Note**: **User.Read** is a delegated permission that allows the application to read the signed-in user's basic profile on their behalf. It is the minimum permission for applications that need to identify who is signed in. Delegated permissions operate in the context of the signed-in user and do not require admin consent for User.Read under standard tenant settings.

1. On the **API permissions** page, confirm that **User.ReadBasic.All** appears under **Configured permissions** with a type of **Delegated**.

    > **Note**: If a **Grant admin consent** button is visible and the status shows **Not granted**, your tenant requires admin consent for all permissions. Select **Grant admin consent for [your tenant]** and confirm. Your instructor will explain this tenant-wide setting if it applies.

1. Return to the **Overview** page and confirm the **Application (client) ID** is recorded.

---

## Summary

In this lab, you replaced a security-defaults baseline with an explicit Conditional Access policy that enforces MFA for a named user accessing the Azure portal. You validated the policy in Report-only mode using the What If simulation tool before enabling enforcement, confirmed the MFA prompt triggered at sign-in, and completed the MFA challenge to verify access was granted. You then registered the AI platform application in Entra ID and configured a scoped delegated API permission using the principle of least privilege.

You have successfully completed this exercise.

## Clean up

The lab environment is automatically reset at the end of the session. No manual resource deletion is required.

If you want to clean up before the session ends:

1. Sign in to the Entra admin center as your Global Administrator.
1. Navigate to **Protection** → **Conditional Access** → **Policies**.
1. Select **sc500-require-mfa-portal**, select **Delete**, and confirm.
1. Navigate to **Applications** → **App registrations**.
1. Select **sc500-ai-platform-app**, select **Delete**, and confirm.
