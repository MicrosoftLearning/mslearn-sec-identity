# Creating a Foundry Agent with a Microsoft Entra User Identity

This guide walks through creating an agent in Microsoft Foundry, locating its automatically provisioned Entra ID objects, granting the agent identity blueprint permission to create a user account, and then creating that user account. This is a complete end-to-end path — not a lab exercise — intended as a reference for environment setup or independent practice.

**Why this matters:** When Foundry creates an agent, it automatically provisions an *agent identity* (a service principal) in Entra ID. However, it does **not** automatically create the agent's *user account* — the second Entra ID object that appears alongside standard users in All Users. That object must be created explicitly, and the blueprint must be granted permission to do it first.

---

## Prerequisites

| Task | Required role |
|------|--------------|
| Create a Foundry project and agent | **Foundry Account Owner** at subscription scope, or **Contributor/Owner** at subscription level |
| Work with agents in an existing project | **Foundry User** at project scope |
| View agent identities and blueprints in Entra ID | Any Microsoft Entra user account (no admin role required for viewing) |
| Grant permission to blueprint | **Privileged Role Administrator** (for application permissions) |
| Create the agent's user account | **Agent ID Administrator** or **User Administrator** |

You also need two PowerShell modules installed for the permission grant step. Run the following in a **PowerShell 7.x** terminal (Windows PowerShell 5.x is not supported by either module):

```powershell
Install-Module Microsoft.Entra.Authentication -Scope CurrentUser
Install-Module Microsoft.Entra.Applications -Scope CurrentUser
```

- **`Microsoft.Entra.Authentication`** — provides the `Connect-Entra` authentication cmdlet used to establish a session with your Entra tenant.
- **`Microsoft.Entra.Applications`** (v1.3 or later) — provides `Add-EntraPermissionToCreateAgentUsersToAgentIdentityBlueprintPrincipal`, used in Part 3 to grant the blueprint permission.

> **Note:** Install these two targeted sub-modules rather than the `Microsoft.Entra` umbrella package. The umbrella attempts to install all sub-modules (including `Microsoft.Entra.SignIns`) as dependencies, which can fail due to PSGallery availability issues. The two modules above are all that is required for the steps in this guide.

---

## Part 1 — Create an agent in Microsoft Foundry

> **Source:** [Microsoft Foundry quickstart](https://learn.microsoft.com/azure/foundry/quickstarts/get-started-code), [Create an agent in Foundry portal](https://learn.microsoft.com/azure/app-service/tutorial-ai-integrate-azure-ai-agent-node#create-an-agent-in-microsoft-foundry)

1. Sign in to the [Microsoft Foundry portal](https://ai.azure.com).

1. Confirm the **New Foundry** toggle is active in the top-right area of the portal. These steps use the current (non-classic) Foundry experience.

1. If you do not have an existing project, create one:
   - Select **New Foundry** from the top-right menu.
   - Select **Create new project**, enter a project name, and select **Create**.

1. From your project home page, select **Start building**, then select **Create agent**.

1. Enter a name for the agent and select **Create**. When provisioning completes, the agent playground opens.

    > **Note:** When your first agent is created in the project, Foundry automatically provisions two objects in Microsoft Entra ID: an **agent identity blueprint** and a **shared project agent identity**. These objects appear immediately in the Entra admin center. No additional configuration is required for this provisioning to happen.

1. Optionally add instructions to the agent (for example, *"You are a helpful assistant."*) and test it in the playground. This step is not required for identity provisioning.

1. Select **Save**.

---

## Part 2 — Locate the blueprint and agent identity in Entra ID

> **Source:** [View and filter agent identities](https://learn.microsoft.com/entra/agent-id/agent-lists), [Agent identity concepts in Foundry](https://learn.microsoft.com/azure/foundry/agents/concepts/agent-identity#foundry-integration)

### Find the blueprint Application ID (needed for PowerShell)

You can retrieve the blueprint Application ID from either the Entra admin center or the Azure portal.

**Option A — Entra admin center:**

1. Sign in to the [Microsoft Entra admin center](https://entra.microsoft.com).

1. Browse to **Entra ID** > **Agents** > **Agent blueprints**.

1. The list contains both a **project blueprint** (named after your Foundry project, for example *myproject*) and one or more **agent blueprints** (named after each individual agent, for example *myagent*). Select the **agent blueprint** — the one named after the specific agent you created in Part 1.

   > **Note:** The permission you grant in Part 3 applies to the agent blueprint, not the project blueprint. Granting it to the project blueprint has no effect on user account creation for the agent.

1. On the blueprint detail page, copy the **Blueprint Application ID**. Save this value — you need it in Part 3.

**Option B — Azure portal JSON view:**

1. Sign in to the [Azure portal](https://portal.azure.com) and navigate to your Foundry project resource.

1. On the **Overview** pane, select **JSON View** and choose the latest API version.

1. Locate and copy the `agentIdentityBlueprintId` value from the JSON output.

### Verify the agent identity

1. In the Entra admin center, browse to **Entra ID** > **Agents** > **Agent identities**.

1. Locate the agent identity for your Foundry project. Select it and review the details pane.

1. Note the **Object ID** of the agent identity. This is the parent identity that the user account will be linked to.

---

## Part 3 — Grant the blueprint permission to create user accounts

> **Source:** [Add-EntraPermissionToCreateAgentUsersToAgentIdentityBlueprintPrincipal](https://learn.microsoft.com/powershell/module/microsoft.entra.applications/add-entrapermissiontocreateagentuserstoagentidentityblueprintprincipal?view=entra-powershell)

By default, an agent identity blueprint does **not** have permission to create agent user accounts. The specific permission that must be granted is `AgentIdUser.ReadWrite.IdentityParentedBy` (app role ID: `4aa6e624-eee0-40ab-bdd8-f9639038a614`).

This step uses PowerShell to assign that permission to the blueprint's service principal.

1. Open a PowerShell session and connect to your tenant with the required scopes. Replace `<your-tenant-id>` with your tenant ID:

    ```powershell
    Connect-Entra -TenantId "<your-tenant-id>" `
        -Scopes 'Application.Read.All', `
                'AppRoleAssignment.ReadWrite.All', `
                'AgentIdentityBlueprint.UpdateAuthProperties.All', `
                'AgentIdUser.ReadWrite.IdentityParentedBy'
    ```

    > **Note:** All four scopes are required. `Application.Read.All` allows the cmdlet to look up the blueprint's service principal. `AppRoleAssignment.ReadWrite.All` allows the POST to `/appRoleAssignments` that performs the actual grant — delegated auth requires this scope explicitly in the token even when the signed-in account holds Privileged Role Administrator. The two `AgentIdentityBlueprint` and `AgentIdUser` scopes are the agent-specific permissions being assigned.

1. Grant the permission to the blueprint using the Application ID you copied in Part 2:

    ```powershell
    Add-EntraPermissionToCreateAgentUsersToAgentIdentityBlueprintPrincipal `
        -AgentBlueprintId "<blueprint-application-id>"
    ```

1. Confirm the output includes the following values:

    | Output field | Expected value |
    |-------------|----------------|
    | `PermissionName` | `AgentIdUser.ReadWrite.IdentityParentedBy` |
    | `appRoleId` | `4aa6e624-eee0-40ab-bdd8-f9639038a614` |
    | `AgentBlueprintId` | The blueprint Application ID you provided |

    > **Note:** The cmdlet requires that the blueprint's service principal already exists in the tenant (which Foundry creates automatically). If the cmdlet fails with a not-found error, confirm the blueprint appears in **Entra ID** > **Agents** > **Agent blueprints** before retrying.

---

## Part 4 — Create the agent's user account

> **Source:** [The agent's user account in Microsoft Entra Agent ID](https://learn.microsoft.com/entra/agent-id/agent-users), [How are agent identities created?](https://learn.microsoft.com/entra/agent-id/agent-id-creation-channels)

The agent's user account is the object that appears in **All Users** and enables the agent to act as a user identity — accessing mailboxes, Teams, calendar, and other resources that require a user-type token (`idtyp=user`).

Creating this object requires **Agent ID Administrator** or **User Administrator** role.

### Create via Microsoft Graph API

The agent identity detail page in the Entra admin center (**Entra ID** > **Agents** > **Agent identities** > select the agent) shows only Overview, Custom Security Attributes, Owners and Sponsors, Granted Permissions, Audit logs, and Sign-in logs. There is currently no **Create user account** option in the portal UI. Use the [Graph Explorer](https://developer.microsoft.com/graph/graph-explorer) or PowerShell instead.

1. Open [Graph Explorer](https://developer.microsoft.com/graph/graph-explorer) and sign in with the account that holds **Agent ID Administrator** or **User Administrator**.

1. Grant Graph Explorer the required delegated permissions before running the query. Select **Modify permissions** at the top of the query window, search for each of the following, and select **Consent** for each:
   - `AgentIdUser.ReadWrite.IdentityParentedBy`
   - `AgentIdUser.ReadWrite.All` *(consent as a fallback if the first is insufficient)*

   > **Note:** Graph Explorer maintains its own consented permission set independently of your Entra role assignments. Even a Global Administrator with Agent ID Administrator role active will receive a 403 error if Graph Explorer has not been explicitly consented to the `AgentIdUser` scopes. The **Modify permissions** button is located at the top of the query window, not in the left navigation.

1. In the Entra admin center, open the agent identity (**Entra ID** > **Agents** > **Agent identities** > select the agent) and copy the **Object ID** from the Overview pane.

1. In Graph Explorer, set the method to **POST** and the URL to:

    ```
    https://graph.microsoft.com/v1.0/users/microsoft.graph.agentUser
    ```

1. On the **Request body** tab, enter the following. Replace the placeholder values with your agent's details and your verified domain:

    ```json
    {
      "accountEnabled": true,
      "displayName": "<your-agent-display-name>",
      "mailNickname": "<mailnickname-no-spaces>",
      "userPrincipalName": "<mailnickname>@<yourdomain>.com",
      "identityParentId": "<agent-identity-object-id>"
    }
    ```

    | Field | Notes |
    |-------|-------|
    | `accountEnabled` | Set to `true` |
    | `displayName` | Human-readable name shown in All Users |
    | `mailNickname` | Alias — no spaces or special characters |
    | `userPrincipalName` | Must use a **verified** domain in your tenant — check **Entra ID** > **Custom domain names** for the exact domain string |
    | `identityParentId` | **Object ID** of the agent identity from Part 2 (not the Application ID) |

    > **Note:** All five fields are required. The `identityParentId` takes the agent identity **Object ID** — not the blueprint Application ID used in Part 3.

1. Select **Run query**. A successful response returns HTTP **201 Created** with the new agent user object in the response body. Confirm the following fields in the response:

    | Response field | Expected value |
    |---------------|----------------|
    | `identityParentId` | The Object ID of the agent identity from Part 2 |
    | `agentIdentityBlueprintId` | The blueprint Application ID from Part 3 |
    | `passwordProfile` | `null` — no password credential exists |
    | `userType` | `Member` |

    The presence of both `identityParentId` and `agentIdentityBlueprintId` in the response confirms the full blueprint → agent identity → user account hierarchy is linked.

---

## Part 5 — Verify the user account in Entra ID

> **Source:** [Manage agent identities in your organization](https://learn.microsoft.com/entra/agent-id/manage-agent-identities-admin)

1. In the Entra admin center, browse to **Entra ID** > **Users** > **All users**.

1. Search for the agent's display name. You should find the agent user account listed alongside standard user accounts.

1. Select the user account entry and confirm:

    - The account type is listed as an agent user (not a standard user or guest)
    - The account has no password or passkey credentials — it authenticates only through its parent agent identity
    - The account cannot be assigned privileged administrator roles

1. Return to **Entra ID** > **Agents** > **Agent identities**, select the agent identity, and look for a grey banner near the top of the detail page that reads **"This agent identity has an associated agent user"**. Select **View** to confirm it links to the user account you created in Part 4.

    > **Note:** The linkage confirmation is a banner, not a dedicated property or section in the Overview pane. If the banner is not visible, scroll to the top of the agent identity detail page.

---

## Object model summary

After completing all parts, three distinct Entra ID objects exist for your agent:

| Object | Type | Location in Entra admin center |
|--------|------|-------------------------------|
| Agent identity blueprint | Application registration (typed) | Agents > Agent blueprints |
| Agent identity | Service principal (typed) | Agents > Agent identities |
| Agent's user account | User (typed, no password) | Users > All users |

These three objects have a fixed hierarchy: blueprint → agent identity → user account. Each relationship is 1:1 and immutable after creation. The user account can only authenticate by presenting a token issued to its parent agent identity — it has no independent credentials.

---

## Reference documentation

- [Agent identity concepts in Microsoft Foundry](https://learn.microsoft.com/azure/foundry/agents/concepts/agent-identity)
- [Create an agent identity blueprint](https://learn.microsoft.com/entra/agent-id/create-blueprint)
- [Create agent identities](https://learn.microsoft.com/entra/agent-id/create-delete-agent-identities)
- [The agent's user account](https://learn.microsoft.com/entra/agent-id/agent-users)
- [Manage agent identities in your organization](https://learn.microsoft.com/entra/agent-id/manage-agent-identities-admin)
- [Add-EntraPermissionToCreateAgentUsersToAgentIdentityBlueprintPrincipal](https://learn.microsoft.com/powershell/module/microsoft.entra.applications/add-entrapermissiontocreateagentuserstoagentidentityblueprintprincipal?view=entra-powershell)
