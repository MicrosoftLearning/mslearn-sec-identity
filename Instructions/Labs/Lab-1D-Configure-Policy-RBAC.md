---
lab:
    title: 'Configure Azure Policy and Role-Based Access Control'
    description: 'Assign a built-in Azure Policy and verify compliance evaluation, deploy a custom tag-enforcement policy via Bicep using Cloud Shell, create a custom Azure role with scoped permissions, evaluate and remediate an overprivileged role assignment using an Entra ID Access Review, and protect a resource against deletion with a resource lock.'
    level: 300
    duration: 60
    islab: true
    primarytopics:
        - Azure Policy
        - Azure Role-Based Access Control
        - Microsoft Entra ID Governance
---

# Lab Setup

This lab runs on a Cloud Slice. Complete these steps before starting the exercise to deploy the resources and seed the role assignment used by the access review scenario:

1. Open the **Azure portal** at `https://portal.azure.com` and sign in with **User1**.

1. Select the **Cloud Shell** icon (>_) in the portal top bar. If prompted, select **Bash**.

1. In the **Resources** tab of the lab environment, copy the username for **User3**. In Cloud Shell, replace `<User3-UPN>` with that username and run:

    ```bash
    az ad user show --id '<User3-UPN>' --query id --output tsv
    ```

1. Copy the returned object ID. You will provide it to the deployment template.

1. In the portal search bar, find and open **Deploy a custom template**.

1. Select **Build your own template in the editor**, then select **Load file**.

1. Select **1D-skillable-env.json** from the **F:\AllFiles\Lab-1D** folder on the lab VM, then select **Save**.

1. On the deployment page, configure the following values:

    | Setting | Value |
    |---------|-------|
    | **Region** | Central US |
    | **User3 Object ID** | Paste the object ID returned by the Cloud Shell command |
    | **Admin password** | Enter a temporary password that meets Azure complexity requirements |

1. Select **Review + create**, then select **Create**.

    > **Note**: Deployment may take several minutes. It creates `sc500-lab1d-rg`, the storage account and virtual machine used for policy evaluation, and an explicit Contributor assignment for **User3** on the resource group.

1. When deployment succeeds, close Cloud Shell and continue to the exercise.

===

# Configure Azure Policy and Role-Based Access Control

A compliance audit of your organization's AI platform environment has identified two governance gaps. First, no policy exists to enforce required resource tagging — resources in the subscription have no consistent `Environment` tag, making cost allocation and security boundary tracking unreliable. Second, a team member who moved off the AI platform team nine months ago still holds a standing Contributor assignment on the platform resource group, giving them full management access to resources they no longer work with.

Your task is to close both gaps. You will assign a built-in tagging policy to surface non-compliant resources, then deploy a custom policy via Infrastructure as Code to extend tag enforcement to resource groups. You will create a scoped custom role for security reviewers — granting read access to Defender for Cloud posture data and role assignments without elevating them to administrators — and then use an Entra ID Access Review to formally evaluate and remove the unnecessary Contributor access. Finally, you will apply a resource lock to protect the platform's storage account from accidental deletion.

In this lab, you will:

- Assign a built-in Azure Policy and review policy compliance results
- Deploy a custom tag-enforcement policy definition via Bicep using Cloud Shell
- Create a custom Azure role and assign it to a designated security reviewer
- Evaluate and remediate an overprivileged role assignment using an Entra ID Access Review
- Apply a CanNotDelete resource lock and verify it prevents deletion

This exercise should take approximately **60** minutes to complete.

> **Note**: This lab uses the Cloud Slice account aliases and baseline subscription permissions: **User1** (`sc500-user1-`, Owner), **User2** (`sc500-user2-`, Contributor), and **User3** (`sc500-user3-`, Reader). The Lab Setup deployment adds a direct Contributor assignment for User3 on `sc500-lab1d-rg`; the access review removes that assignment while preserving User3's inherited Reader access. Credentials for all three accounts are in the **Resources** tab.

---

## Assign a built-in compliance policy

Azure Policy evaluates resources against defined rules and reports compliance without requiring changes to existing resources. A **Deny** effect policy blocks new non-compliant resources from being created; existing resources that already violate the policy appear as **Non-compliant** in the compliance report. You will assign the built-in **Require a tag on resources** policy to `sc500-lab1d-rg`, which will flag the pre-provisioned storage account (name starts with **`sc500lab1d`**) and `sc500-lab1d-vm` (the virtual machine) as non-compliant because neither resource has an `Environment` tag. You may see one additional non-compliant resource listed — this is expected.

1. Sign in to the Azure portal `https://portal.azure.com` using your **User1** credentials.

1. In the search bar, search for and select **`Policy`**.

1. In the left menu, under **Authoring**, select **Assignments**.

1. Select **Assign policy**.

1. On the **Basics** tab, configure the following:

    | Setting | Value |
    |---------|-------|
    | **Scope** | Select the ellipsis (**...**), then select your subscription and **sc500-lab1d-rg** as the resource group. Select **Select**. |
    | **Exclusions** | Leave blank |
    | **Policy definition** | Select the ellipsis (**...**), search for **`Require a tag on resources`**, select the result, then select **Add**. |
    | **Assignment name** | sc500-require-env-tag |
    | **Policy enforcement** | Enabled |

1. Select the **Parameters** tab.

1. In the **Tag Name** field, enter `Environment`.

1. Select **Review + create**, then select **Create**.

    > **Note**: Policy assignments can take up to 30 minutes to fully propagate before compliance evaluation reflects the new assignment. You will trigger an on-demand scan in the next step rather than waiting.

1. Select the **Cloud Shell** icon (>_) in the Azure portal top bar. If prompted to select a shell type, select **Bash**. If prompted to create a storage account, select your subscription and select **Create**.

1. Run the following command to trigger an on-demand compliance evaluation for the resource group:

    ```bash
    az policy state trigger-scan --resource-group sc500-lab1d-rg
    ```

    The command displays an **IN-PROGRESS** indicator while the scan runs and returns your Bash prompt only when the scan is complete. This typically takes **5+ minutes** but can take longer depending on subscription load.  You don't need to wait for the Scan to finish. Wait a minute or two, then proceed to the next Note and Steps.

    > **Note**: If the compliance state still shows **Not started** or **0 non-compliant resources** after the command completes, wait 2–3 additional minutes and select **Refresh** in the portal. Compliance state updates are written asynchronously after the scan finishes.

1. In the Azure portal, return to **Policy** and select **Compliance** from the left menu.

1. In the scope filter at the top of the page, select `sc500-lab1d-rg` to narrow results to this resource group.

1. Locate the **sc500-require-env-tag** assignment in the compliance list.

1. Confirm that the storage account (name starts with **`sc500lab1d`**) and **`sc500-lab1d-vm`** (virtual machine) appear in the non-compliant resources list. You may see one additional resource listed — this is expected and does not affect the lab outcome.

    > **Note**: Both resources were deployed without an `Environment` tag and therefore violate the policy. The policy assignment also prevents any future resource deployments in `sc500-lab1d-rg` from omitting the `Environment` tag. Existing resources remain operational — compliance evaluation is non-destructive.

---

## Deploy a custom policy using Infrastructure as Code

The built-in policy you assigned enforces tag requirements on individual resources. A complementary policy at the resource group level ensures that any new resource groups created in the subscription are also tagged from the start. Rather than configuring this policy in the portal, you will deploy a pre-written Bicep template that defines and assigns the custom policy at the subscription scope. Deploying governance policy through Infrastructure as Code ensures it is version-controlled, repeatable, and auditable.

The **sc500-lab1d-policy.bicep** file has been pre-staged in your Cloud Shell home directory. It defines a custom **Deny** policy that requires an **Environment** tag on all resource groups and creates a subscription-scope assignment.

1. Open a Cloud Shell (Bash), if it is not already open.

1. Select the **Manage file** button in the menu at the top of your Bash window.

1. Select **Upload**.

1. Browse to the **F:\AllFiles\Lab-1D** folder on the lab VM, then select **sc500-lab1d-policy.bicep** file.

1. Select **Open** to upload the file. Wait for the **Successfully uploaded file** message.

1. In the Cloud Shell (Bash) session, run the following command to deploy the custom policy to the subscription scope:

    ```bash
    az deployment sub create \
      --name sc500-tag-policy \
      --location centralus \
      --template-file ~/sc500-lab1d-policy.bicep
    ```

    The deployment typically completes in under one minute. A JSON output block appears in the terminal when it succeeds.

    > **Note**: The `--location centralus` flag specifies the region for the deployment metadata record, not where resources are created. Subscription-scope Bicep deployments must specify a location for the ARM metadata even when the resources they create (like policy definitions) are globally scoped.

1. In the Azure portal, navigate to **Policy** and select **Definitions** from the left menu.

1. In the **Type** filter, select **Custom**.

    Confirm that a custom policy definition for requiring a **Require Environment tag on resource groups** policy appears in the list. This is the definition deployed by the Bicep template.

    > **Note**: This step demonstrates the Infrastructure as Code approach to policy governance. The same Bicep template can be committed to a repository, reviewed through a pull request, and deployed consistently across multiple environments — ensuring that governance rules are applied uniformly without relying on manual portal configuration.

1. Select **Assignments** from the left menu.

    Confirm that an assignment for the custom tag policy appears in the list, scoped to your subscription. The Bicep template deployed both the policy definition and the assignment in a single operation.

1. Close the Cloud Shell.

---

## Create a custom security reviewer role

Built-in Azure roles such as **Reader** grant broad read access across all resource types in a scope. When a role is needed for a specific governance function — such as reviewing Defender for Cloud security posture data and role assignments — a custom role with the minimum required permissions is a better fit. You will create a role named **sc500-Security-Reviewer** that grants read access to Microsoft Defender for Cloud data and Azure authorization objects only, then assign it to **User2**.

1. In the Azure portal search bar, search for and select **Resource groups**.

1. Select **sc500-lab1d-rg**.

1. In the left menu, select **Access control (IAM)**.

1. Select **+ Add**, then select **Add custom role**.

1. On the **Basics** tab, configure the following:

    | Setting | Value |
    |---------|-------|
    | **Custom role name** | `sc500-Security-Reviewer` |
    | **Description** | `Read-only access to Defender for Cloud security posture data and role assignments. Scoped to the sc500-lab1d-rg resource group.` |
    | **Baseline permissions** | Start from scratch |

1. Select **Next** to proceed to the **Permissions** tab.

    > **Note**: The **Permissions** tab provides a searchable card-based interface for adding individual operations. Adding wildcard permissions — such as `Microsoft.Security/*/read` — requires editing the role's JSON directly, which you will do on the **JSON** tab.

1. Select **Next** to proceed to the **Assignable scopes** tab.

    Confirm that **sc500-lab1d-rg** is listed as an assignable scope. Because you opened the custom role wizard from the resource group's IAM page, the scope is pre-populated. If it is not listed, select **Add assignable scopes**, expand your subscription, select **sc500-lab1d-rg**, then select **Add**.

1. Select **Next** to proceed to the **JSON** tab.

1. Select **Edit** to open the JSON editor.

1. Locate the `"actions": []` line inside the `"permissions"` array. Replace the empty array with the following:

    ```json
    "actions": [
        "Microsoft.Security/*/read",
        "Microsoft.Authorization/*/read"
    ],
    ```

    The completed `"permissions"` block should look like this:

    ```json
    "permissions": [
        {
            "actions": [
                "Microsoft.Security/*/read",
                "Microsoft.Authorization/*/read"
            ],
            "notActions": [],
            "dataActions": [],
            "notDataActions": []
        }
    ]
    ```

    > **Note**: `Microsoft.Security/*/read` grants read access to all Defender for Cloud and Azure Security Center data — security assessments, recommendations, alerts, and secure score. `Microsoft.Authorization/*/read` grants read access to all role assignments, policy assignments, and role definitions, which allows the reviewer to audit who has access to what without having any write or delete permissions.

1. Select **Save** to apply the JSON changes.

1. Select **Review + create**, then select **Create**.

    Wait for the custom role to be created. This typically takes a few seconds.

1. On the **Access control (IAM)** page for `sc500-lab1d-rg`, select **+ Add**, then select **Add role assignment**.

1. On the **Role** tab, select **Custom roles** from the **Type** filter dropdown, then select **sc500-Security-Reviewer**. Select **Next**.

1. On the **Members** tab, confirm **Assign access to** is set to **User, group, or service principal**.

1. Select **+ Select members**, search for and select **User2**, then select **Select**.

1. Select **Review + assign**, then select **Review + assign** again to save.

    > **Note**: The `sc500-Security-Reviewer` role itself grants only the defined read permissions. In this Cloud Slice, **User2** also inherits the **Contributor** role from the subscription, so User2's effective permissions are broader than this custom role. The exercise demonstrates custom-role definition and assignment; in production, assign this role to a principal without a broader inherited role. User2 is also the designated reviewer in the next section.

---

## Evaluate and remediate overprivileged access

**User3** holds an active **Contributor** role assignment directly on `sc500-lab1d-rg`. The Contributor role grants full management access—the ability to create, modify, and delete resources—without permission to manage role assignments. **User3** no longer has a business need for this access.

A Microsoft Entra access review provides a structured, auditable process for deciding whether an existing role assignment remains appropriate. You will verify the seeded assignment, create a review at the resource-group scope, designate **User2** as the reviewer, submit a denial as **User2**, stop the review, and confirm that the Contributor assignment is removed.

1. In the Azure portal, open **Resource groups**, select **sc500-lab1d-rg**, and then select **Access control (IAM)**.

1. On the **Role assignments** tab, search for **User3** and confirm that **User3** has the **Contributor** role with scope **This resource**.

    > **Important**: If the Contributor assignment is missing, stop here. The Lab Setup deployment did not receive the correct **User3 Object ID**, and the access review will have no assignment to evaluate.

1. Navigate to the [Microsoft Entra admin center](https://entra.microsoft.com).

1. Browse to **ID Governance > Privileged Identity Management**.

1. Select **Azure resources**, then select **sc500-lab1d-rg**.

    > **Note**: If the resource group is not listed, select **Discover resources**, locate `sc500-lab1d-rg`, select it, and then select **Manage resource**.

1. Under **Manage**, select **Access reviews**, then select **New**.

1. On the **Create an access review** page, configure the review details:

    | Setting | Value |
    |---------|-------|
    | **Review name** | `sc500-contributor-review` |
    | **Description** | `Review of Contributor access on the AI platform resource group` |
    | **Start date** | Today's date |
    | **Frequency** | One time |
    | **Duration (in days)** | 3 |

1. Under **Users scope**, leave the review scoped to all users and groups.

1. Under **Review role membership**, select **Contributor**.

1. For **Assignment type**, select **Active assignments only**.

1. Under **Reviewers**, select **Selected users**, then select **User2**.

1. Expand **Upon completion settings** and configure:

    | Setting | Value |
    |---------|-------|
    | **Auto apply results to resource** | Enable |
    | **If reviewers don't respond** | No change |

1. Select **Start** to create and activate the access review.

1. Open a new **InPrivate** or **Private** browser window and sign in to `https://entra.microsoft.com` with the **User2** credentials from the lab **Resources** tab.

1. Browse to **ID Governance > Privileged Identity Management > Review access**.

1. Select **sc500-contributor-review**. Select the entry for **User3**, choose **Deny**, enter `No current business need for Contributor access` as the reason, and submit the decision.

1. Close the InPrivate window and return to the **User1** session.

1. Return to **ID Governance > Privileged Identity Management > Azure resources > sc500-lab1d-rg > Access reviews**.

1. Select **sc500-contributor-review**, then select **Stop** and confirm the action.

    > **Note**: Because **Auto apply results to resource** is enabled, stopping the review completes it and applies the denial automatically. Application can take several minutes.

1. Return to **sc500-lab1d-rg > Access control (IAM) > Role assignments** in the Azure portal. Refresh the page and search for **User3**.

1. Confirm that **User3** no longer has the **Contributor** role scoped to `sc500-lab1d-rg`. **User3** might still appear with a Reader role inherited from the subscription; that inherited assignment is outside this review and is expected.

    > **Note**: The completed review preserves an auditable, timestamped record of the reviewer, decision, justification, and resulting access change.

---

## Apply a resource lock

Resource locks prevent accidental or unauthorized deletion of critical resources. A **CanNotDelete** lock allows all read and write operations on a resource but blocks delete operations — even for users with the Owner role. You will apply a lock to the pre-provisioned storage account in `sc500-lab1d-rg` and verify that the lock prevents deletion.

> **Note**: The `sc500-lab1d-rg` resource group contains exactly one storage account, and its name begins with **`sc500lab1d`** followed by an 8-character suffix unique to your lab subscription. Select it whenever the lab refers to it.

1. In the Azure portal search bar, search for and select **Storage accounts**.

1. Select the storage account whose name starts with **`sc500lab1d`** (there is only one in `sc500-lab1d-rg`).

1. In the left menu, under **Settings**, select **Locks**.

1. Select **+ Add**.

1. Configure the following:

    | Setting | Value |
    |---------|-------|
    | **Lock name** | `sc500-storage-lock` |
    | **Lock type** | Delete |
    | **Notes** | `Prevents accidental deletion of the AI platform storage account.` |

1. Select **OK**.

1. In the left menu, select **Overview**.

1. Select **Delete**.

1. In the confirmation dialog, type the storage account name to confirm, then select **Delete**.

    Confirm that an error message appears indicating the resource is locked and cannot be deleted:

    > **Note**: The `CanNotDelete` lock is enforced by Azure Resource Manager regardless of the requestor's role. An Owner or subscription administrator cannot delete this resource while the lock is in place — you must explicitly remove the lock first. This creates deliberate friction that prevents automated scripts or misconfigured pipelines from destroying critical resources. `ReadOnly` locks are stricter: they block all write and delete operations, but can interfere with platform operations that legitimately need to update resource metadata. `CanNotDelete` is the recommended choice for most production resource protection scenarios.

1. Close the delete confirmation dialog.

---

## Summary

In this lab, you applied governance controls across four dimensions: policy compliance, Infrastructure as Code policy deployment, custom role creation, and access certification.

You assigned the built-in **Require a tag on resources** policy to surface existing non-compliant resources missing an `Environment` tag, and triggered an on-demand compliance scan to observe results immediately rather than waiting for the standard evaluation cycle. You then deployed a complementary custom policy at the subscription scope using a pre-written Bicep template — demonstrating that governance rules, like application code, can be version-controlled and deployed repeatably through Infrastructure as Code.

You created a custom Azure role — `sc500-Security-Reviewer` — whose definition contains only the read permissions needed for a security auditor function. You assigned it to **User2** and distinguished the permissions granted by the custom role from User2's broader Contributor access inherited from the Cloud Slice subscription.

You used an Entra ID Access Review to formally evaluate **User3**'s standing Contributor assignment. Rather than removing access directly, the review process created an auditable record of the decision — who reviewed, the justification, and the resulting action. This audit trail satisfies compliance requirements for periodic access certification. Finally, you applied a CanNotDelete resource lock to the platform storage account, demonstrating that identity-based access control and resource locks serve complementary functions: access control governs who can act, while locks create an explicit barrier that even highly privileged identities cannot bypass without a deliberate removal step.

You have successfully completed this exercise.

---

## Clean up

The lab environment is automatically reset at the end of the session. No manual resource deletion is required.
