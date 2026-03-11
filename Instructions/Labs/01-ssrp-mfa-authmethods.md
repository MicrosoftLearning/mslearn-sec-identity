---
lab:
    title: 'Exercise Title'
    description: 'Sentence describing the lab'
    level: (100 to 500)
    duration: 00
---
<!--
Edit the metadata above to manage the list of exercises in the home page of the GitHub site that gets generated.
You can delete the module and edit index.md in the root of the repo to customize the display so that only the exercises are listed
To enable GitHub page publishing, edit the Page settings for the repo and publish from the main branch
-->

# Exercise title <!-- match title in metadata above (and Learn Exercise unit and ILT slide)-->

In this exercise you will <!-- provide a description of what they'll do and why it;s important -->

This exercise should take approximately **XX** minutes to complete. <!-- update with estimated duration -->

## Before you start

<!--
Add steps to get the learner to the starting point" for the exercise. This might be cloning the repo and running a script or performing some manual steps.

Only include this section if its necessary to do some pre-exercise setup AND the same setup steps are required for self-paced (on Learn) and managed (in hosted ILT lab profiles) scenarios. Otherwise delete this section.
If self-paced /ILT-specific setup steps are required, include them in the Learn "Exercise" unit from where they open this exercise and in the Skillable lab profile instructions before this markdown file is imported.

Do not include requirements for getting an Azure (or other) subscription (write the exercise on the assumption the learner has a functioning lab environment - this section is only for exercise-specific steps to get to a starting point)

If there are complex setup steps that apply to ALL of the exercises in the repo (for example, installing and configuring client-side tools), create a separate 00-setup.md file with instructions.
 -->

Before you can start this exercise, you will need to...

1. Step 1
1. Step 2
1. etc.

## Task <!-- Change to an appropriate task title with an imperative verb phrase (e.g. "Do something") -->

First, you need to ...

1. Step 1
1. This step includes an example of `inline code formatting`, which is used when the learner needs to type something (anything, not just code) because it creates a [T] link in the hosted Skillable environment.
1. If you need the learner to open a website, include both a link (so they can open by clicking in the HTML GitHub page) AND the URL formatted as code (so they can type it in a hosted VM browser). For example, "Open the [Bing](https://www.bing.com){:target="_blank"} website at `https://www.bing.com`" (the {:target="_blank"} tag forces the link to open in a new browser tab!)
1. If you need the learner to download a file (or a bunch of files in a zip), store the file in Allfiles folder in this repo and use the **raw** URL - like this: "Download [file name](https://raw.githubusercontent.com/MicrosoftLearning/INF99X-SampleCourse/master/Allfiles/read-me.md){:target="_blank"} from `https://raw.githubusercontent.com/MicrosoftLearning/INF99X-SampleCourse/master/Allfiles/read-me.md`.
1. Alternatively, for a developer audience, you can have them clone this repo if that seems more appropriate.
1. If you need to include a multiline code block, indent it to match the bulleted list indent:

    ```python
    # This is an example of an
    # indented code block.
    ```

1. If you need to include a acreenshot, resize it to an appropriate size (so any "normal" formatted text in a partial screenshot is roughly the same size as this text - generally try to make screenshots of full application windows 1200x900px (approx)). Store images in a **Media** subfolder and use markdown to add it to the page (remembering that file and folder names are case-sensitive). If the image is in a list, indent it, like this:

    ![A screenshot of an application.](./Media/edge-copilot.png) 

1. If you need to explain why something is done the way it is, or provide additional context or links to info, use a note like this:

    > **Note**: This is a note.

1. Be flexible when providing instructions that might vary between self-paced and hosted lab environments. For example:
    - "Sign in using your Azure credentials" (assuming there were Learn-specific instructions to use a personal subscription or create a trial in the Learn exercise page, and ILT-specific instructions to use provided cloudslice credentials in the Skillable lab profile)
    - "Select an existing resource group or create a new one" (assuming that if a Skillable CS-R cloudslice is used, you included a note in the lab profile telling the learner which resource group they should use)
    - Try to use consistent phrases for anything that might need to be "overwritten" by the replacement-text feature in thw Skillable profile.
    <!-- The key point is that this markdown file should be environment-agnostic - you need to provide explicit details of things that can vary OUTSIDE of this file (in the Learn exercise page or the Skillable lab profile instructions) -->
1. etc.

## Next task

Now let's, ...

1. Step 1
1. Step 2
1. etc.

## Task with subtasks

Sometimes you might want to break a task down into smaller chunks.

### Subtask 1

1. Step 1
1. Step 2
1. Etc.

### Subtask 2

1. Step 1
1. Step 2
1. etc.

## Clean up

<!-- Good practice - especially as self-paced learners will be using their own subscriptions -->
<!-- Delete this section if it is not needed -->

Now that you've finished the exercise, you should delete the cloud resources you've created to avoid unnecessary resource usage.

1. Step 1
2. etc.


Contoso's IT security team is ready to implement the authentication controls covered in this module. In this exercise, you configure a Conditional Access MFA policy with a named location exclusion, enable passkeys for the IT security group, set up self-service password reset (SSPR) for a pilot group, explore workload identity authentication for an AI agent, and review the sign-in log to observe how your policies apply.

In this exercise, you complete the following tasks:

- **Task 1**: Create a Conditional Access MFA policy for the IT security group
- **Task 2**: Enable passkeys in Microsoft Authenticator for the pilot group
- **Task 3**: Configure SSPR for the SSPR pilot group
- **Task 4**: Explore workload identity authentication for an AI agent
- **Task 5**: Review authentication activity in sign-in logs

## Prerequisites

To complete this exercise, you need:

**Roles**: Assign the following Microsoft Entra ID roles to the account you use for this exercise — no single role covers all tasks, which reflects the Zero Trust principle of least privilege:

| Role | Tasks covered |
| --- | --- |
| **Conditional Access Administrator** | Tasks 1 and 4 — create CA policies and named locations |
| **Authentication Policy Administrator** | Tasks 2 and 3 — configure authentication methods and SSPR |
| **Groups Administrator** | Tasks 1 and 3 — create security groups |
| **Application Administrator** | Task 4 — register the AI agent application |
| **Security Reader** | Task 5 — view sign-in logs |

> [!TIP]
> In production, follow the same pattern: assign each administrator only the roles required for their area of responsibility, and use **Privileged Identity Management (PIM)** to make those assignments eligible rather than permanent. This way, elevated access is activated on demand with MFA and an approval step — a practice you'll implement in Module 3 of this learning path.

**Licensing**:

| Task | License required |
| --- | --- |
| Tasks 1–3, 5 | Microsoft Entra ID P1, P2, or Microsoft 365 Business Premium |
| Task 4 (passkey enforcement + workload identity CA exploration) | Microsoft Entra ID P1 or P2 (Workload ID Premium required to *save* a workload identity CA policy — Task 4 walks through the blade without saving) |

**Access**:

- Access to the **Microsoft Entra admin center** at `https://entra.microsoft.com`
- Your own Microsoft Entra ID tenant with the roles listed above assigned to your account

> [!IMPORTANT]
> Password writeback (Task 3) requires Microsoft Entra Connect or cloud sync deployed against an on-premises Active Directory — Task 3 walks through the setting without saving. Physical passkey registration (Task 2) requires a supported personal device — Task 2 includes guidance for completing registration outside this exercise.

## Task 1: Create a Conditional Access MFA policy for the IT security group

1. Sign in to the **Microsoft Entra admin center** at `https://entra.microsoft.com` using an account with the roles listed in the Prerequisites section.
2. Navigate to **Groups** > **All groups** > **New group**.
3. Set **Group type** to **Security**, enter **Group name** as `sg-Contoso-ITSec`, leave membership type as **Assigned**, and select **Create**.
4. Navigate to **Entra ID** > **Conditional Access** > **Policies** > **New policy**.
5. Name the policy `Contoso-Require-MFA-ITSec`.
6. Under **Users**, select **Select users and groups** > **Users and groups**, search for and add `sg-Contoso-ITSec`, and select **Select**.
7. Under **Target resources**, select **All cloud apps**.
8. Under **Network**, select **Configure** > **Include** > **Any network or location**.
9. Select **Exclude** > **Select excluded locations** > **New location**.
10. Name the location `Contoso-Corporate-HQ`, select **IP ranges (IPv4 and IPv6)**, enter `203.0.113.0/24`, and select **Create**.
11. Back in the exclusion picker, select `Contoso-Corporate-HQ` and select **Select**.
12. Under **Grant**, select **Grant access** > **Require multifactor authentication** > **Select**.
13. Under **Enable policy**, select **Report-only**.
14. Select **Create** to save the policy.

In the Conditional Access policies list, `Contoso-Require-MFA-ITSec` appears with the state **Report-only**. Select the policy and confirm that `sg-Contoso-ITSec` is listed under **Users**, `Contoso-Corporate-HQ` appears under **Network** exclusions, and **Require multifactor authentication** is the selected grant control.

## Task 2: Enable passkeys in Microsoft Authenticator for the pilot group

1. Navigate to **Entra ID** > **Authentication methods** > **Policies**.
2. Select **Passkey (FIDO2)**.
3. Under **Enable**, select **Enabled**.
4. Under **Include**, select **Select groups**, search for `sg-Contoso-ITSec`, and add the group.
5. Select the **Configure** tab. Confirm **Allow self-service set up** is set to **Yes**. Set **Enforce attestation** to **Yes**.
6. Select **Save**.

> [!NOTE]
> In a production environment, users complete passkey registration at `mysignins.microsoft.com/security-info`. This sandbox environment doesn't support physical device registration. To test the registration flow, complete the steps on a personal device running iOS 17.1 or later, or Android 14 or later.

In the Authentication methods policies list, **Passkey (FIDO2)** shows **Enabled** and the **Includes** column lists `sg-Contoso-ITSec`.

## Task 3: Configure SSPR for the SSPR pilot group

1. Navigate to **Groups** > **All groups** > **New group**.
2. Set **Group type** to **Security**, enter **Group name** as `sg-Contoso-SSPR-Pilot`, leave membership type as **Assigned**, and select **Create**.
3. Navigate to **Entra ID** > **Password reset** > **Properties**.
4. Under **Self service password reset enabled**, select **Selected**.
5. Select **No groups selected**, search for and select `sg-Contoso-SSPR-Pilot`, and select **Select**.
6. Select **Save**.
7. Navigate to **Authentication methods** under **Password reset**.
8. Set **Number of methods required to reset** to **2**. Select **Save**.

> [!NOTE]
> As of September 30, 2025, authentication method selection for SSPR can no longer be managed in the legacy **Password reset** > **Authentication methods** view. Available methods are now controlled through the unified Authentication methods policy at **Entra ID** > **Authentication methods** > **Policies**.

9. Navigate to **Registration**.
10. Set **Require users to register when signing in** to **Yes**.
11. Set **Number of days before users are asked to re-confirm their authentication information** to **180**.
12. Select **Save**.
13. Navigate to **On-premises integration**. Observe the **Write back passwords to your on-premises directory** toggle but don't enable it.

> [!NOTE]
> Password writeback requires Microsoft Entra Connect or cloud sync configured against an on-premises Active Directory. This sandbox environment doesn't include on-premises infrastructure. In Contoso's hybrid deployment, this toggle is enabled after verifying that Entra Connect is running with the appropriate permissions.

Under **Password reset** > **Properties**, the **Selected** option is active and `sg-Contoso-SSPR-Pilot` appears. Under **Authentication methods**, two methods are required. Under **Registration**, the re-confirmation period is **180 days**.

## Task 4: Explore workload identity authentication for an AI agent

1. Navigate to **Applications** > **App registrations** > **New registration**.
2. Under **Name**, enter `Contoso-AIFoundry-Agent`.
3. Under **Supported account types**, leave **Accounts in this organizational directory only** selected.
4. Leave **Redirect URI** empty and select **Register**.
5. Record the **Application (client) ID** on the app's Overview page. This ID represents the identity Contoso's Azure AI Foundry agent uses to authenticate.
6. Navigate to **Entra ID** > **Conditional Access** > **Policies** > **New policy**.
7. Under **Users or workload identities**, under **What does this policy apply to?**, select **Workload identities**.
8. Under **Include** > **Select service principals**, search for `Contoso-AIFoundry-Agent` and add it.
9. Review the available **Conditions** (service principal risk, filter for service principals) and **Grant** controls.
10. Select **Discard**. Don't save this policy.

> [!TIP]
> Workload identity Conditional Access policies require Microsoft Entra Workload ID Premium licensing. In production, this policy enforces location-based restrictions on the AI agent's service principal — for example, blocking API calls from unexpected regions. For Azure AI Foundry agents, using a **managed identity** instead of a service principal with client secrets is the stronger option because it eliminates stored credentials entirely. Managed identities are covered in Module 5 of this learning path.

The `Contoso-AIFoundry-Agent` app registration appears in **App registrations** > **All applications**.

## Task 5: Review authentication activity in sign-in logs

1. Navigate to **Monitoring & health** > **Sign-in logs**.
2. Select the **User sign-ins (interactive)** tab.
3. Select any sign-in entry in the list.
4. In the details pane, select the **Authentication details** tab.
5. Observe the **Authentication method** and **Result detail** fields.
6. Select the **Conditional Access** tab.
7. Locate the `Contoso-Require-MFA-ITSec` policy in the list. Observe the **Result** value, which reflects the report-only state.

> [!NOTE]
> In a production tenant with active users, the **Report-only** result in the **Conditional Access** tab shows how the `Contoso-Require-MFA-ITSec` policy *would have* applied to each sign-in — without enforcing any access controls. Use this view to validate policy impact before switching the policy to **On**.

With all five tasks complete, you've configured the core authentication controls for Contoso's Microsoft Entra ID tenant. In the next unit, test your understanding of the key concepts covered in this module.
