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

> **Note**: This lab uses two accounts: your **Global Administrator** account (your primary lab credentials) and **sc500-user04** (used to complete the Access Review decision as the designated reviewer). Credentials for both accounts are in the **Resources** tab of your lab environment.

---

## Assign a built-in compliance policy

Azure Policy evaluates resources against defined rules and reports compliance without requiring changes to existing resources. A **Deny** effect policy blocks new non-compliant resources from being created; existing resources that already violate the policy appear as **Non-compliant** in the compliance report. You will assign the built-in **Require a tag on resources** policy to `sc500-lab1d-rg`, which will flag `sc500lab1d@lab.LabInstance.Id` (the storage account) and `sc500-lab1d-vm` (the virtual machine) as non-compliant because neither resource has an `Environment` tag. You may see one additional non-compliant resource listed — this is expected.

1. Sign in to the Azure portal `https://portal.azure.com` using your **User-1** credentials.

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

    The command displays an **IN-PROGRESS** indicator while the scan runs and returns your Bash prompt only when the scan is complete. This typically takes **5+ minutes** but can take longer depending on subscription load.

    > **Note**: If the compliance state still shows **Not started** or **0 non-compliant resources** after the command completes, wait 2–3 additional minutes and select **Refresh** in the portal. Compliance state updates are written asynchronously after the scan finishes.

1. In the Azure portal, return to **Policy** and select **Compliance** from the left menu.

1. In the scope filter at the top of the page, select `sc500-lab1d-rg` to narrow results to this resource group.

1. Locate the **sc500-require-env-tag** assignment in the compliance list.

1. Confirm that **`sc500lab1d@lab.LabInstance.Id`** (storage account) and **`sc500-lab1d-vm`** (virtual machine) appear in the non-compliant resources list. You may see one additional resource listed — this is expected and does not affect the lab outcome.

    > **Note**: Both resources were deployed without an `Environment` tag and therefore violate the policy. The policy assignment also prevents any future resource deployments in `sc500-lab1d-rg` from omitting the `Environment` tag. Existing resources remain operational — compliance evaluation is non-destructive.

---

## Deploy a custom policy using Infrastructure as Code

The built-in policy you assigned enforces tag requirements on individual resources. A complementary policy at the resource group level ensures that any new resource groups created in the subscription are also tagged from the start. Rather than configuring this policy in the portal, you will deploy a pre-written Bicep template that defines and assigns the custom policy at the subscription scope. Deploying governance policy through Infrastructure as Code ensures it is version-controlled, repeatable, and auditable.

The `sc500-lab1d-policy.bicep` file has been pre-staged in your Cloud Shell home directory. It defines a custom `Deny` policy that requires an `Environment` tag on all resource groups and creates a subscription-scope assignment.

1. In the Cloud Shell (Bash) session, run the following command to deploy the custom policy to the subscription scope:

    ```bash
    az deployment sub create \
      --name sc500-tag-policy \
      --location eastus \
      --template-file ~/sc500-lab1d-policy.bicep
    ```

    The deployment typically completes in under one minute. A JSON output block appears in the terminal when it succeeds.

    > **Note**: The `--location eastus` flag specifies the region for the deployment metadata record, not where resources are created. Subscription-scope Bicep deployments must specify a location for the ARM metadata even when the resources they create (like policy definitions) are globally scoped.

1. In the Azure portal, navigate to **Policy** and select **Definitions** from the left menu.

1. In the **Type** filter, select **Custom**.

    Confirm that a custom policy definition for requiring an `Environment` tag on resource groups appears in the list. This is the definition deployed by the Bicep template.

    > **Note**: This step demonstrates the Infrastructure as Code approach to policy governance. The same Bicep template can be committed to a repository, reviewed through a pull request, and deployed consistently across multiple environments — ensuring that governance rules are applied uniformly without relying on manual portal configuration.

1. Select **Assignments** from the left menu.

    Confirm that an assignment for the custom tag policy appears in the list, scoped to your subscription. The Bicep template deployed both the policy definition and the assignment in a single operation.

1. Close the Cloud Shell.

---

## Create a custom security reviewer role

Built-in Azure roles such as **Reader** grant broad read access across all resource types in a scope. When a role is needed for a specific governance function — such as reviewing Defender for Cloud security posture data and role assignments — a custom role with the minimum required permissions is a better fit. You will create a role named `sc500-Security-Reviewer` that grants read access to Microsoft Defender for Cloud data and Azure authorization objects only, then assign it to `sc500-user04`.

1. In the Azure portal search bar, search for and select **Resource groups**.

1. Select **sc500-lab1d-rg**.

1. In the left menu, select **Access control (IAM)**.

1. Select **+ Add**, then select **Add custom role**.

1. On the **Basics** tab, configure the following:

    | Setting | Value |
    |---------|-------|
    | **Custom role name** | sc500-Security-Reviewer |
    | **Description** | Read-only access to Defender for Cloud security posture data and role assignments. Scoped to the sc500-lab1d-rg resource group. |
    | **Baseline permissions** | Start from scratch |

1. Select **Next** to proceed to the **Permissions** tab.

    > **Note**: The **Permissions** tab provides a searchable card-based interface for adding individual operations. Adding wildcard permissions — such as `Microsoft.Security/*/read` — requires editing the role's JSON directly, which you will do on the **JSON** tab.

1. Select **Next** to proceed to the **Assignable scopes** tab.

    Confirm that `sc500-lab1d-rg` is listed as an assignable scope. Because you opened the custom role wizard from the resource group's IAM page, the scope is pre-populated. If it is not listed, select **Add assignable scopes**, expand your subscription, select `sc500-lab1d-rg`, then select **Add**.

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

1. Select **+ Select members**, search for and select **sc500-user04**, then select **Select**.

1. Select **Review + assign**, then select **Review + assign** again to save.

    > **Note**: `sc500-user04` now holds the `sc500-Security-Reviewer` role on `sc500-lab1d-rg`. They have read access to Defender for Cloud data and role assignments within this resource group — without any management or write permissions. This role will also be used in the next section: `sc500-user04` is the designated reviewer for the Access Review you are about to create.

---

## Evaluate and remediate overprivileged access

`sc500-user05` holds an active **Contributor** role assignment on `sc500-lab1d-rg`. The Contributor role grants full management access — the ability to create, modify, and delete resources — without the ability to manage role assignments. This level of access is appropriate while someone is actively working on a platform, but `sc500-user05` no longer has a business need for it.

An **Entra ID Access Review** provides a structured, auditable process for evaluating whether existing role assignments remain appropriate. You will create a review that targets the Contributor role on `sc500-lab1d-rg`, designate `sc500-user04` as the reviewer, then sign in as `sc500-user04` to submit the denial decision. The review will automatically remove the assignment when stopped.

1. Navigate to the [Microsoft Entra admin center](https://entra.microsoft.com).

1. In the left menu, expand **ID Governance** and select **Privileged Identity Management**.

1. Select **Azure resources**.

    > **Note**: If prompted to discover resources, select **Discover resources**, find your lab subscription in the list, select it, and select **Manage resource**. Return to **Azure resources** and select your subscription.

1. From the list of Azure resources, select your lab subscription.

1. In the left menu, under **Manage**, select **Access reviews**.

1. Select **New** to create a new access review.

1. On the **Create an access review** screen, configure the review **details** as follows:

    | Setting | Value |
    |---------|-------|
    | **Review name** | sc500-contributor-review |
    | **Description** | Review of Contributor access on the AI platform resource group |
    | **Start date** | Today's date |
    | **Frequency** | One time |
    | **Duration (in days)** | 3 |

1. Under **Review scope**, configure the following:

    | Setting | Value |
    |---------|-------|
    | **Scope** | All users and groups |
    | **Role** | Contributor |
    | **Assignment type** | Active assignments only |

1. Under **Reviewers**, configure the following:

    | Setting | Value |
    |---------|-------|
    | **Reviewers** | Selected users |
    | **Select reviewers** | Search for and select `sc500-user04` |

1. Under **Upon completion settings**, configure the following:

    | Setting | Value |
    |---------|-------|
    | **Auto apply results to resource** | Enable |
    | **If reviewer doesn't respond** | No change |

1. Select **Start** to create and activate the access review.

    > **Note**: With **Auto apply results to resource** enabled, review decisions are applied automatically when the review is stopped or reaches its end date. You do not need to click a separate Apply button.

1. Open a new **InPrivate** or **Private** browser window.

1. Navigate to the [Microsoft Entra admin center](https://entra.microsoft.com) and sign in using the **sc500-user04** credentials from the **Resources** tab.

1. In the left menu, expand **ID Governance** and select **Privileged Identity Management**.

1. Select **Review access**.

    The pending review **sc500-contributor-review** appears in the access reviews list.

1. Select **sc500-contributor-review** to open it.

1. For the entry showing **sc500-user05**, select **Deny**.

1. In the **Reason** field, enter a justification such as:

    `sc500-user05 is no longer assigned to the AI platform team and does not require Contributor access.`

1. Select **Submit**.

    > **Note**: The review decision is recorded immediately. `sc500-user04` has completed their role as the designated reviewer. PIM-based Azure resource role reviews are completed through the Entra admin center — not myaccess.microsoft.com, which handles group and application access reviews only.

1. Close the InPrivate browser window and return to your Global Administrator browser session.

1. Navigate back to the **sc500-contributor-review** access review in the Microsoft Entra admin center. You can find it under **ID Governance** → **Privileged Identity Management** → **Azure resources** → your subscription → **Access reviews**.

1. Select **Stop** to end the review before its scheduled end date.

    With auto-apply enabled, stopping the review immediately triggers the application of results. The review status progresses through **Stopping** → **Applying** → **Applied**.

    > **Note**: Allow 1–2 minutes for the status to reach **Applied**. Select **Refresh** if the status does not update.

1. In the Azure portal, navigate to **sc500-lab1d-rg**.

1. Select **Access control (IAM)**, then select the **Role assignments** tab.

1. Search or scroll to find `sc500-user05` in the role assignments list.

    Confirm that `sc500-user05` no longer appears as a **Contributor**. The Access Review has removed the assignment.

    > **Note**: Access Reviews create an auditable, timestamped record of the reviewer's decision and the resulting access change. In a production environment, this record provides evidence of due diligence for compliance frameworks that require periodic access certification — including SOC 2, ISO 27001, and NIST 800-53 AC-6.

---

## Apply a resource lock

Resource locks prevent accidental or unauthorized deletion of critical resources. A **CanNotDelete** lock allows all read and write operations on a resource but blocks delete operations — even for users with the Owner role. You will apply a lock to `sc500lab1d@lab.LabInstance.Id` and verify that the lock prevents deletion.

1. In the Azure portal search bar, search for and select **Storage accounts**.

1. Select **sc500lab1d@lab.LabInstance.Id**.

1. In the left menu, under **Settings**, select **Locks**.

1. Select **+ Add**.

1. Configure the following:

    | Setting | Value |
    |---------|-------|
    | **Lock name** | sc500-storage-lock |
    | **Lock type** | Delete |
    | **Notes** | Prevents accidental deletion of the AI platform storage account. |

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

You created a custom Azure role — `sc500-Security-Reviewer` — with exactly the permissions needed for a security auditor function: read access to Defender for Cloud posture data and role assignments, and nothing else. You assigned this role to `sc500-user04` following the principle of least privilege, ensuring the reviewer can observe the security state without any management authority over resources.

You used an Entra ID Access Review to formally evaluate `sc500-user05`'s standing Contributor assignment. Rather than removing access directly, the review process created an auditable record of the decision — who reviewed, the justification, and the resulting action. This audit trail satisfies compliance requirements for periodic access certification. Finally, you applied a CanNotDelete resource lock to the platform storage account, demonstrating that identity-based access control and resource locks serve complementary functions: access control governs who can act, while locks create an explicit barrier that even highly privileged identities cannot bypass without a deliberate removal step.

You have successfully completed this exercise.

---

## Clean up

The lab environment is automatically reset at the end of the session. No manual resource deletion is required.
