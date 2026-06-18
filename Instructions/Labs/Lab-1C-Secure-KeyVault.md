---
lab:
    title: 'Deploy and Secure Azure Key Vault'
    description: 'Deploy an Azure Key Vault using the RBAC authorization model, configure role assignments for an App Service managed identity and a test user, store secrets and cryptographic keys, retrieve a secret using the managed identity via the IMDS token endpoint, apply network firewall rules, and enable the Defender for Key Vault protection plan.'
    level: 300
    duration: 60
    islab: true
    primarytopics:
        - Azure Key Vault
        - Azure Role-Based Access Control
        - Microsoft Defender for Key Vault
---

# Deploy and Secure Azure Key Vault

A recent security review of your organization's AI platform found that application secrets — including the API key your Azure AI Foundry integration uses to authenticate against model endpoints — are stored in plain text inside application configuration files. Anyone with access to the deployment configuration or source repository can read them. Your task is to migrate those secrets into Azure Key Vault, restrict access so only the application's managed identity can retrieve them, and ensure the vault is protected by Defender for Key Vault.

Azure Key Vault provides a centrally managed, hardware-protected store for secrets, cryptographic keys, and certificates. When combined with managed identities, applications authenticate to Key Vault without ever handling a credential — the platform handles token acquisition automatically through the Azure Instance Metadata Service (IMDS), and access is governed by Azure RBAC role assignments. Adding a network firewall creates a second enforcement layer, ensuring that even a valid identity cannot reach the vault from an unauthorized network.

In this lab, you will:

- Deploy an Azure Key Vault using the Azure RBAC authorization model
- Assign role-based access to the application's managed identity and a test user account
- Store an API key and a cryptographic key in the vault
- Confirm that a limited Reader role does not grant access to secret values
- Retrieve the secret using the App Service managed identity via the managed identity token endpoint
- Restrict vault network access to an authorized virtual network
- Enable the Defender for Key Vault protection plan and configure audit log forwarding

This exercise should take approximately **60** minutes to complete.

> **Note**: This lab uses two accounts: your **Global Administrator** account (your primary lab credentials) and **sc500-user03** (used to verify that role-based access boundaries are enforced at the data plane). Credentials for both accounts are in the **Resources** tab of your lab environment.

---

## Deploy the Key Vault

Azure Key Vault supports two permission models: **Vault access policies** (the legacy model) and **Azure role-based access control** (the recommended model). The RBAC model integrates Key Vault access governance into the same role assignment system used across all Azure resources, making it easier to audit permissions and apply the principle of least privilege consistently. You will create the vault with the RBAC model enabled and then verify and configure its deletion protection settings.

> **Note**: The Key Vault name must be globally unique across all Azure subscriptions. The name `sc500-kv-@lab.LabInstance.Id` uses your lab instance ID to ensure uniqueness. This name is referenced throughout the lab — if you use a different name, substitute it wherever `sc500-kv-@lab.LabInstance.Id` appears.

1. Sign in to the **Azure portal** using `https://portal.azure.com` using your **Global Administrator** credentials.

2. In the search bar, search for and select **Key vaults**.

3. Select **+ Create**.

4. On the **Basics** tab, configure the following:

    | Setting | Value |
    |---------|-------|
    | **Subscription** | Your lab subscription |
    | **Resource group** | sc500-lab1c-rg |
    | **Key vault name** | sc500-kv-@lab.LabInstance.Id |
    | **Region** | East US |
    | **Pricing tier** | Standard |

5. Select the **Access configuration** tab.

6. Under **Permission model**, select **Azure role-based access control (RBAC)**.

    > **Note**: The RBAC authorization model is selected at vault creation and cannot be changed without deleting and recreating the vault. If the vault is created with the legacy access policies model, the role assignment steps in this lab will not apply.

7. Select **Review + create**, then select **Create**.

    Wait for the deployment to complete. This typically takes less than one minute.

8. Select **Go to resource** to open the vault.

9. On the Key Vault **Overview** page, locate the **Vault URI** field. Copy this value and save it — it follows the format `https://sc500-kv-<your-lab-id>.vault.azure.net/`. You will use it in a later section.

10. In the left menu, under **Settings**, select **Properties**.

11. Locate **Soft-delete** and confirm it shows **Soft delete is enabled for this vault**.

    > **Note**: Soft delete is enabled by default on all new Key Vault instances and cannot be disabled once set. It retains deleted secrets, keys, and certificates in a recoverable state for a configurable retention period (default: 90 days), protecting against accidental or malicious deletion.

12. Locate **Purge protection** and confirm it shows **Disabled**.

13. Select **Enable purge protection**, then select **Save**.

    > **Note**: Purge protection prevents permanent deletion of the vault or its objects during the soft-delete retention period, even by users with the Key Vault Contributor role. This is a one-way operation and cannot be reversed after it is enabled. In production environments, purge protection is recommended for any vault storing critical secrets or keys.

---

## Configure access using Azure RBAC

With the vault created, you will assign four RBAC roles following the principle of least privilege. Rather than granting a broad administrator role to your Global Administrator account, you will assign two targeted roles: **Key Vault Secrets Officer** (to create and manage secrets) and **Key Vault Crypto Officer** (to create and manage keys). You will then grant the **Key Vault Secrets User** role to the App Service managed identity (which will retrieve secrets at runtime), and the **Key Vault Reader** role to `sc500-user03` (which you will use to verify that management-plane access does not grant data-plane access to secret values).

> **Note**: When a Key Vault uses the RBAC authorization model, data-plane access is controlled entirely by role assignments — including for the account that created the vault. The subscription Owner role and the Global Administrator role do not grant any data-plane rights to Key Vault. Without an explicit assignment, your admin account cannot create, read, or delete secrets or keys.

The `sc500-lab1c-app` App Service has a system-assigned managed identity that was pre-enabled before the lab started. You do not need to configure the App Service itself — you only need to grant the identity access to this vault.

1. In the left menu of the Key Vault, select **Access control (IAM)**.

1. Select **+ Add**, then select **Add role assignment**.

1. On the **Role** tab, search for and select **Key Vault Secrets Officer**, then select **Next**.

    > **Note**: The **Key Vault Secrets Officer** role grants create, read, update, delete, and purge permissions for secrets only — it does not include access to keys or certificates. Assigning it separately from **Key Vault Crypto Officer** enforces separation: an account with only Secrets Officer cannot manage keys, and vice versa.

1. On the **Members** tab, confirm **Assign access to** is set to **User, group, or service principal**.

1. Select **+ Select members**, search for and select your **Global Administrator** account (the account you are currently signed in with), then select **Select**.

1. Select **Review + assign**, then select **Review + assign** again to save.

1. Select **+ Add**, then select **Add role assignment** to begin a second assignment.

1. On the **Role** tab, search for and select **Key Vault Crypto Officer**, then select **Next**.

    > **Note**: The **Key Vault Crypto Officer** role grants create, read, update, delete, and purge permissions for keys only. Separating key management from secrets management is a Zero Trust design principle — the person or process that manages encryption keys is not automatically the same one that can read application secrets.

1. On the **Members** tab, confirm **Assign access to** is set to **User, group, or service principal**.

1. Select **+ Select members**, search for and select your **Global Administrator** account (the account you are currently signed in with), then select **Select**.

1. Select **Review + assign**, then select **Review + assign** again to save.

1. Select **+ Add**, then select **Add role assignment** to begin a third assignment.

1. On the **Role** tab, search for and select **Key Vault Secrets User**, then select **Next**.

    > **Note**: The **Key Vault Secrets User** role grants read access to secret contents only — just enough for an application to retrieve a secret value at runtime. It does not allow creating, updating, listing, or deleting secrets. This is the minimum permission required for an application's managed identity to read a secret.

1. On the **Members** tab, set **Assign access to** to **Managed identity**.

1. Select **+ Select members**.

1. On the **Select managed identities** pane, set **Managed identity** to **App Service**, then select **sc500-lab1c-app** from the list.

1. Select **Select**, then select **Review + assign**, then select **Review + assign** again to save.

1. Select **+ Add**, then select **Add role assignment** to begin a fourth assignment.

1. On the **Role** tab, search for and select **Key Vault Reader**, then select **Next**.

    > **Note**: The **Key Vault Reader** role grants read access to Key Vault metadata — vault properties, and the names of secrets and keys — but does not grant permission to view secret values or key material. It is a management-plane role only. You will verify this boundary in the next section.

1. On the **Members** tab, set **Assign access to** to **User, group, or service principal**.

1. Select **+ Select members**, search for and select **sc500-user03**, then select **Select**.

1. Select **Review + assign**, then select **Review + assign** again to save.

1. On the **Access control (IAM)** page, select the **Role assignments** tab and confirm the following four assignments are listed:

    | Principal | Role |
    |-----------|------|
    | Your Global Administrator account | Key Vault Secrets Officer |
    | Your Global Administrator account | Key Vault Crypto Officer |
    | sc500-lab1c-app | Key Vault Secrets User |
    | sc500-user03 | Key Vault Reader |

    > **Note**: In a production environment, consider making the **Key Vault Secrets Officer** and **Key Vault Crypto Officer** assignments eligible through Privileged Identity Management (PIM) rather than active. This removes standing data-plane access entirely — administrators activate the role just-in-time when they need to manage vault contents, and access automatically expires.

---

## Store secrets and keys

You will now store two objects in the vault: a secret that represents the AI application's model endpoint API key, and a cryptographic key that represents a data encryption key managed through Key Vault. These objects will be used in the access verification and managed identity retrieval steps that follow.

1. In the left menu of the Key Vault, select **Objects** then **Secrets**.

1. Select **+ Generate/Import**.

1. On the **Create a secret** page, configure the following:

    | Setting | Value |
    |---------|-------|
    | **Upload options** | Manual |
    | **Name** | foundry-api-key |
    | **Secret value** | sk-foundry-demo-00000000000000000000000000000001 |
    | **Enabled** | Yes |

1. Select **Create**.

    The secret appears in the Secrets list with a status of **Enabled**.

1. In the left menu, select **Keys**.

1. Select **+ Generate/Import**.

1. On the **Create a key** page, configure the following:

    | Setting | Value |
    |---------|-------|
    | **Options** | Generate |
    | **Name** | data-encryption-key |
    | **Key type** | RSA |
    | **RSA key size** | 2048 |
    | **Enabled** | Yes |

1. Select **Create**.

    The key appears in the Keys list with a status of **Enabled**.

    > **Note**: Key Vault stores the RSA private key material inside the vault and never exposes it directly. Applications interact with the key by calling Key Vault cryptographic operations — encrypt, decrypt, sign, verify — rather than extracting the raw key. This keeps the private key permanently protected and audited inside the vault.

---

## Verify access control enforcement

The **Key Vault Reader** role grants management-plane access only — a user assigned this role can see that secrets exist and view their names, but cannot read secret values. You will sign in as `sc500-user03` to confirm that the role boundary is enforced at the data plane.

1. Open a new **InPrivate** or **Private** browser window.

1. Navigate to [https://portal.azure.com](https://portal.azure.com) and sign in using the **sc500-user03** credentials from the **Resources** tab.

1. In the search bar, search for and select **Key vaults**.

1. Select **sc500-kv-@lab.LabInstance.Id** from the list.

1. In the left menu, select **Secrets**.

    Confirm that **foundry-api-key** appears in the list. The Key Vault Reader role grants `sc500-user03` management-plane access, so the secret name is visible.

1. Select **foundry-api-key** to open the secret, then select the current version.

1. On the secret version page, select **Show Secret Value**.

    Confirm that an error message appears, such as **"The operation is not allowed by RBAC. If role assignments were recently changed, please wait several minutes for role assignments to become effective."** or an access denied notification.

    > **Note**: The Key Vault Reader role includes `Microsoft.KeyVault/vaults/read` (management plane) but does not include `Microsoft.KeyVault/vaults/secrets/getSecret/action` (data plane). This means `sc500-user03` can enumerate secrets but cannot retrieve their values — precisely the boundary that separates the Reader role from the Secrets User role.

1. Close the InPrivate browser window and return to your Global Administrator browser session.

---

## Retrieve a secret using the managed identity

The `sc500-lab1c-app` App Service managed identity has the **Key Vault Secrets User** role, which grants data-plane access to secret values. You will use the App Service's built-in Kudu console to retrieve the `foundry-api-key` secret programmatically — using a bearer token issued to the managed identity. No user credentials are involved at any point in this retrieval.

When managed identity is enabled on an App Service, the runtime injects two environment variables into the application's process: `IDENTITY_ENDPOINT` (a local token service URL) and `IDENTITY_HEADER` (a shared secret that prevents SSRF attacks). Code running inside the App Service uses these to request OAuth tokens scoped to any Azure resource the identity has been granted access to.

> **Note**: Managed identity requires a **Basic (B1) tier** App Service or higher. The Free (F1) tier does not support managed identities and the `IDENTITY_ENDPOINT` environment variable will be empty. If your lab environment uses a Free tier App Service, managed identity is not available and the steps in this section cannot be completed until the App Service plan is upgraded.

1. Confirm you are signed in to the [Azure portal](https://portal.azure.com) as your **Global Administrator** account. If the InPrivate window from the previous section is still active, close it first.

1. In the search bar, search for and select **App Services**.

1. Select **sc500-lab1c-app**.

1. In the left menu, under **Development Tools**, select **Advanced Tools**.

1. Select **Go →** to open the Kudu service console in a new browser tab.

1. In the Kudu top navigation bar, select **Debug console**, then select **PowerShell**.

    A PowerShell terminal opens. This runs inside the App Service's compute environment.

1. In the PowerShell terminal, run the following two commands to verify the managed identity environment variables are present:

    ```powershell
    Write-Output "IDENTITY_ENDPOINT: $env:IDENTITY_ENDPOINT"
    Write-Output "IDENTITY_HEADER is set: $(-not [string]::IsNullOrEmpty($env:IDENTITY_HEADER))"
    ```

    Expected output:
    ```
    IDENTITY_ENDPOINT: http://127.0.0.1:<port>/MSI/token
    IDENTITY_HEADER is set: True
    ```

    > **Important**: If `IDENTITY_ENDPOINT` is blank or `IDENTITY_HEADER is set: False`, stop here. Navigate to **sc500-lab1c-app → Settings → Identity** in the Azure portal and confirm the **System assigned** status is **On**. If the App Service is on the **Free (F1)** pricing tier, managed identity is not supported — the App Service plan must be upgraded to **Basic (B1)** or higher before continuing. Raise this with your instructor.

1. Run the following commands to request a bearer token for the managed identity, scoped to Azure Key Vault:

    ```powershell
    $tokenEndpoint = $env:IDENTITY_ENDPOINT
    $identityHeader = $env:IDENTITY_HEADER
    $response = Invoke-RestMethod `
        -Uri "${tokenEndpoint}?resource=https://vault.azure.net&api-version=2019-08-01" `
        -Method GET `
        -Headers @{"X-IDENTITY-HEADER" = $identityHeader}
    $token = $response.access_token
    Write-Output "Token acquired: $($token.Substring(0, 20))..."
    ```

    If successful, a partial token value is displayed, confirming the managed identity is active and returned a valid token.

    > **Note**: The `$env:` provider variables are captured into local variables first. The Kudu PowerShell console does not expand `$env:` references reliably when they appear inline inside multi-line backtick-continued commands — pre-assigning them is the correct pattern for Kudu scripts.

    > **Note**: App Services use a different token endpoint than virtual machines. Rather than calling the VM-specific IMDS address (`169.254.169.254`), App Services expose two environment variables: `IDENTITY_ENDPOINT` (the local token service URL) and `IDENTITY_HEADER` (a secret value that prevents SSRF attacks). The `X-IDENTITY-HEADER` header serves the same security purpose as the `Metadata: true` header on the VM IMDS endpoint. The token returned is a JWT issued by Microsoft Entra ID for the `sc500-lab1c-app` managed identity.

1. Run the following command to call the Key Vault REST API and retrieve the secret value. Replace `<your-vault-uri>` with the Vault URI you copied from the Key Vault Overview page earlier (for example, `https://sc500-kv-12345678.vault.azure.net`):

    ```powershell
    $kvUri = "<your-vault-uri>"
    $result = Invoke-RestMethod `
        -Uri "$kvUri/secrets/foundry-api-key?api-version=2016-10-01" `
        -Method GET `
        -Headers @{Authorization = "Bearer $token"}
    Write-Output "Secret value: $($result.value)"
    ```

    The output should display the secret value you stored in the previous section:

    ```
    Secret value: sk-foundry-demo-00000000000000000000000000000001
    ```

    > **Note**: The bearer token identifies the managed identity of `sc500-lab1c-app` to Key Vault. Key Vault validates the token against Microsoft Entra ID, confirms that the identity holds the **Key Vault Secrets User** role, and returns the secret value. No username, password, or stored credential was used — authentication was handled entirely by the managed identity and the App Service token endpoint.

1. Close the Kudu browser tab and return to the Azure portal.

---

## Restrict network access

Identity-based access control is the primary enforcement mechanism for Key Vault. A network firewall adds a second layer of defense by limiting which networks can reach the vault's data plane, regardless of role assignments. You will configure the Key Vault firewall to allow access only from the `sc500-lab1c-vnet` virtual network.

> **Note**: The `sc500-lab1c-vnet` virtual network was pre-provisioned with the `Microsoft.KeyVault` service endpoint already enabled on its subnet. This is required before a VNet can be added to a Key Vault firewall allow list — the service endpoint configures the subnet to route Key Vault traffic directly through the Azure backbone rather than through the public internet.

1. Navigate to your Key Vault, **sc500-kv-@lab.LabInstance.Id**.

1. In the left menu, under **Settings**, select **Networking**.

1. Under **Allow access from**, select **Allow public access from specific virtual networks and IP addresses**.

1. Under **Virtual networks**, select **+ Add existing virtual networks**.

1. On the **Add networks** pane, configure the following:

    | Setting | Value |
    |---------|-------|
    | **Subscription** | Your lab subscription |
    | **Virtual networks** | sc500-lab1c-vnet |
    | **Subnets** | Select the available subnet - default |

1. Select **Enable**.

1. Under **Exceptions**, confirm that **Allow trusted Microsoft services to bypass this firewall** is selected.

    > **Note**: The trusted Microsoft services exception allows Azure platform services — such as Azure Monitor, Azure Backup, and Azure Defender — to access the vault for monitoring and protection purposes, even when the firewall restricts all other traffic.

1. Select **Apply** to save the firewall configuration.

    > **Note**: After saving, the vault accepts data-plane traffic only from the `sc500-lab1c-vnet` subnet and from Azure services on the trusted services list. The Azure portal may display a banner warning that your current IP is not in the allow list — this is expected. If you need to access the vault from the portal after this step, you can temporarily add your lab environment's public IP to the **IP addresses** section of the firewall, or use an Azure resource that is VNet-integrated with `sc500-lab1c-vnet`.

---

## Enable Defender for Key Vault

Microsoft Defender for Key Vault detects unusual and potentially harmful access patterns — including access from known malicious IP addresses, suspicious retrieval volumes, and anomalous geographic locations. You will enable the Defender for Key Vault protection plan on the subscription and configure the vault to forward audit logs to the pre-provisioned Log Analytics workspace.

1. In the [Azure portal](https://portal.azure.com) search bar, search for and select **Microsoft Defender for Cloud**.

1. In the left menu, under **Management**, select **Environment settings**.

1. Expand your subscription node and select your subscription.

1. On the **Defender plans** page, locate **Key Vault** in the list of resource types.

1. Set the **Key Vault** plan status to **On**.

1. Select **Save**.

    > **Note**: Enabling Defender for Key Vault activates threat detection across all Key Vaults in the subscription, including the vault you created in this lab. Alerts are generated for anomalies such as access from Tor exit nodes, access from atypical geographic locations, and bulk secret retrieval patterns that may indicate a credential harvesting attempt.

1. Navigate back to your Key Vault, **sc500-kv-@lab.LabInstance.Id**.

1. In the left menu, under **Monitoring**, select **Diagnostic settings**.

1. Select **+ Add diagnostic setting**.

1. Configure the following:

    | Setting | Value |
    |---------|-------|
    | **Diagnostic setting name** | sc500-kv-diag |
    | **Logs — Category groups** | Check **audit** |
    | **Destination details** | Check **Send to Log Analytics workspace** |
    | **Subscription** | Your lab subscription |
    | **Log Analytics workspace** | sc500-lab1c-log |

1. Select **Save**.

1. Confirm that **sc500-kv-diag** now appears in the Diagnostic settings list.

    > **Note**: Diagnostic settings forward all Key Vault audit events — read, write, and delete operations on secrets, keys, and certificates — to the Log Analytics workspace. This telemetry feeds into Defender for Key Vault alert enrichment and supports security investigations and compliance reporting. Allow up to 15 minutes for the first log entries to appear in the workspace after the setting is saved.

---

## Summary

In this lab, you secured an Azure Key Vault from end to end. You deployed the vault using the RBAC authorization model, ensuring access governance integrates with the same role assignment system used across all Azure resources. You granted the App Service managed identity the minimum required permission — **Key Vault Secrets User** — and confirmed that the **Key Vault Reader** role assigned to `sc500-user03` enforces the management-plane and data-plane boundary: the user can see that a secret exists but cannot read its value. You stored a simulated AI application API key and a cryptographic key, then retrieved the secret programmatically from the App Service using a managed identity bearer token acquired from the IMDS endpoint — with no stored credentials involved at any step. Finally, you applied a network firewall to restrict vault access to an authorized virtual network, enabled the Defender for Key Vault protection plan, and configured audit log forwarding to a Log Analytics workspace.

You have successfully completed this exercise.

---

## Clean up

The lab environment is automatically reset at the end of the session. No manual resource deletion is required.

If you want to clean up before the session ends:

1. Navigate to the [Azure portal](https://portal.azure.com).
1. Navigate to **Resource groups** and select **sc500-lab1c-rg**.
1. Select **Delete resource group**, enter the resource group name to confirm, and select **Delete**.
1. In **Microsoft Defender for Cloud** → **Management** → **Environment settings**, select your subscription and set the **Key Vault** plan to **Off**, then select **Save**.
