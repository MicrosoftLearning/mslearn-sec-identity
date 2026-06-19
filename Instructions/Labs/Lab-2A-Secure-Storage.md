---
lab:
    title: 'Secure Azure Storage'
    description: 'Restrict network access to a pre-provisioned storage account using VNet firewall rules, create a stored access policy and generate a SAS token, verify that the firewall blocks unauthorized access, enable Defender for Storage, and confirm diagnostic logging to a Log Analytics workspace.'
    level: 300
    duration: 60
    islab: true
    primarytopics:
        - Azure Storage Security
        - Microsoft Defender for Storage
        - Stored Access Policies
---

# Secure Azure Storage

A storage account containing AI training data and model outputs is currently accessible from the public internet with no network restrictions. A recent security scan found that the account has no threat detection enabled and no policies governing how access tokens are issued or revoked. Any actor with the account key or a valid SAS token generated without policy backing can access training data with no audit trail and no revocation path.

Your task is to close these gaps. You will apply a stored access policy to the training data container so that any generated SAS tokens can be revoked centrally, verify that the SAS token works before any network restrictions are in place, restrict network access to an authorized virtual network only, confirm that the restriction blocks unauthorized access from Cloud Shell, and enable Defender for Storage to detect future threats.

In this lab, you will:

- Create a stored access policy on a blob container and generate a SAS token backed by the policy
- Verify data-plane access using the SAS token before and after network restrictions are applied
- Restrict storage account network access to an authorized virtual network
- Confirm the firewall blocks unauthorized access from Cloud Shell and the Azure portal
- Enable Defender for Storage at the resource level
- Confirm diagnostic logging to a Log Analytics workspace

This exercise should take approximately **60** minutes to complete.

---

## Create a stored access policy and generate a SAS token

A **stored access policy** centralizes the permissions and lifetime of one or more SAS tokens on a container. Without a stored access policy, a SAS token cannot be revoked before its expiry — the only remediation for a leaked standalone SAS token is to rotate the storage account key, which invalidates all other tokens simultaneously. A stored access policy solves this: revoking the policy immediately invalidates every SAS token that references it, with no collateral impact on other access paths.

You will create a stored access policy on the `training-data` container that grants read access for 24 hours, then generate a SAS token that references the policy.

1. Sign in to the Azure portal at `https://portal.azure.com` using your **User-1** credentials.

1. In the search bar, search for and select **Storage accounts**.

1. Select **sc500lab2astorage**.

1. In the left menu, under **Data storage**, select **Containers**.

1. Select the **training-data** container.

1. In the menu on the left, select **Settings** then **Access policy**.

    > **Note**: This opens the **Access policy** pane for the container — not the storage account. Stored access policies are defined at the container level.

1. Under **Stored access policies**, select **+ Add policy**.

1. Configure the policy as follows:

    | Setting | Value |
    |---------|-------|
    | **Identifier** | sc500-training-read |
    | **Permissions** | Select **Read** only |
    | **Start time** | Leave at the current date and time |
    | **Expiry time** | Set to 24 hours from now |

1. Select **OK**, then select **Save** to save the policy.

1. Return to the **training-data** container overview.

1. In the menu on the left, select **Shared access token**.

1. On the **Generate SAS** panel, configure the following:

    | Setting | Value |
    |---------|-------|
    | **Signing method** | Account key |
    | **Signing key** | Key 1 (default — either key works) |
    | **Stored access policy** | sc500-training-read |
    | **Permissions** | Automatically populated from the policy |
    | **Start and expiry date/time** | Automatically populated from the policy |
    | **Allowed IP addresses** | Leave blank |
    | **Allowed protocols** | HTTPS only |

1. Select **Generate SAS token and URL**.

1. Copy the **SAS token** value (not the SAS URL) and save it to a text file — you will need it in the next section. The SAS token is the query string only, beginning with `sv=` or `si=`. It does not include the `https://` prefix or the container path.

    > **Note**: This SAS token is backed by the `sc500-training-read` stored access policy. If the policy is deleted or its permissions are revoked, this token becomes immediately invalid — without needing to rotate the storage account key.

---

## Verify access before applying network restrictions

Before restricting the storage account to a virtual network, verify that the SAS token provides data-plane access from Cloud Shell. This establishes the "before" state — open access from any network — so you can observe the contrast after the firewall rule is applied.

1. In the Azure portal top bar, select the **Cloud Shell** icon (**>_**). If prompted, select **Bash**.

1. Assign your SAS token to a variable, replacing the placeholder with the SAS token you copied in the previous section:

    ```bash
    SAS_TOKEN="<paste your SAS token here>"
    ```

1. Verify the variable is set by checking the first few characters:

    ```bash
    echo "${SAS_TOKEN:0:30}..."
    ```

    The output should show the beginning of your SAS token (for example, `si=sc500-training-read&spr=...`). If the output is `...` with nothing before it, the variable is empty — paste the SAS token value again and re-run the assignment.

    > **Warning**: If the output is `...` with nothing before it, the variable is empty — paste the SAS token value again and re-run the assignment. Do not proceed with an empty variable.

1. Run the following command to read a blob from the container using the SAS token. This calls the Azure Blob Storage REST API directly — no Azure CLI authentication is involved:

    ```bash
    curl -s -w "\n--- HTTP Status: %{http_code} ---" \
      "https://sc500lab2astorage.blob.core.windows.net/training-data/sample-1.json?${SAS_TOKEN}"
    ```

    Confirm that the response ends with `--- HTTP Status: 200 ---` and the body contains the JSON content of the file. This confirms the SAS token is valid and the storage account currently allows read access from all networks.

    > **Note**: The stored access policy grants **Read** permission — this allows reading individual blob content but not listing the container. Cloud Shell runs outside your virtual network, so a 200 response here confirms the account is open to all networks. After the firewall rule is applied, this same request will return 403.

---

## Restrict network access to the authorized virtual network

You will now change the storage account from **Allow all networks** to **Selected networks**, adding the pre-provisioned `sc500-lab2a-vnet` subnet as the only authorized network. You will then disable the **Allow Azure services** exception, which otherwise creates a bypass for any Azure-hosted service regardless of network membership.

1. In the left menu for `sc500lab2astorage`, under **Security + networking**, select **Networking**.

1. Select the **Public Access** tab, then select **Manage**.

    > **Note**: The **Manage** button opens the **Public Network Access** configuration page. If you don't see a **Manage** button, you may already be on the Public Network Access page.

1. Under **Public Network Access**, confirm the setting is **Enable**.

1. Under **Public Network Access Scope**, select **Enable from selected networks**.

1. Under **Virtual networks**, select **+ Add existing virtual network**.

1. Configure the following:

    | Setting | Value |
    |---------|-------|
    | **Subscription** | Your lab subscription |
    | **Virtual network** | sc500-lab2a-vnet |
    | **Subnet** | default |

1. Select **Add**.

1. Under **Exceptions**, clear the checkbox for **Allow Azure services on the trusted services list to access this storage account**.

    > **Note**: The **Allow Azure services** exception grants implicit data-plane access to a broad set of Microsoft services — including Azure Backup, Azure Site Recovery, and Azure Monitor — regardless of network membership. Disabling it closes a potential bypass that could allow exfiltration via a misconfigured Azure service in the same tenant. In production environments, evaluate whether any Azure services legitimately need this bypass before removing it.

1. Select **Save** to apply the network restriction.

---

## Confirm the firewall blocks unauthorized access

With the VNet-only restriction applied, verify that Cloud Shell — which runs outside the authorized VNet — is now blocked from accessing the storage account.

1. Return to the **Cloud Shell** session (or reopen it if it closed). Check whether the `$SAS_TOKEN` variable is still set:

    ```bash
    echo "${SAS_TOKEN:0:30}..."
    ```

    If the output is `...` with nothing before it, the session timed out and the variable was cleared. Reassign it:

    ```bash
    SAS_TOKEN="<paste your SAS token here>"
    ```

1. Run the same blob read request. If you reopened Cloud Shell, reassign `$SAS_TOKEN` first:

    ```bash
    curl -s -w "\n--- HTTP Status: %{http_code} ---" \
      "https://sc500lab2astorage.blob.core.windows.net/training-data/sample-1.json?${SAS_TOKEN}"
    ```

    Confirm that the response body contains `<Code>AuthorizationFailure</Code>` and the response ends with `--- HTTP Status: 403 ---`. `AuthorizationFailure` is the error code Azure Storage returns when a request is blocked by the network firewall — the SAS token is valid, but the request origin (Cloud Shell's IP) is not in the authorized network list. This confirms the firewall is active.

1. Close the Cloud Shell.

1. In the left menu for `sc500lab2astorage`, select **Storage browser**.

1. Select **Blob containers**, then select **training-data**.

    Confirm that an error appears stating the request is not authorized. The Storage browser calls the storage data plane directly — because your browser session originates from an IP address outside the authorized VNet, access is blocked here as well.

    > **Note**: Resources deployed *within* the `sc500-lab2a-vnet` subnet — such as a virtual machine running in that network — can still access the storage account. The restriction blocks the public internet and all other networks not in the authorized VNet. This is the intended security posture for a storage account that serves only VNet-resident workloads.

---

## Enable Defender for Storage

Defender for Storage provides threat detection for your storage account — detecting anomalous access patterns, malware uploads, and data exfiltration attempts. You will enable it at the resource level on `sc500lab2astorage`.

Defender for Storage's malware scanning feature uses Azure Event Grid to route scan results. The Event Grid resource provider must be registered in your subscription before enabling Defender for Storage, or the enablement will partially fail.

1. In the Azure portal top bar, select the **Cloud Shell** icon (**>_**). If prompted, select **Bash**.

1. Register the Event Grid resource provider:

    ```bash
    az provider register --namespace Microsoft.EventGrid
    ```

1. Verify the registration is complete before proceeding:

    ```bash
    az provider show --namespace Microsoft.EventGrid --query "registrationState" -o tsv
    ```

    Wait until the output shows `Registered`. This typically takes 1–2 minutes. Re-run the command if it still shows `Registering`.

1. Close the Cloud Shell.

1. In the left menu for `sc500lab2astorage`, under **Security + networking**, select **Microsoft Defender for Cloud**.

1. Select **Enable Microsoft Defender for Storage on this storage account**.

    > **Note**: Defender for Storage can also be enabled at the subscription level from **Microsoft Defender for Cloud** → **Environment settings** → your subscription → **Storage**. Subscription-level enablement automatically protects all current and future storage accounts in the subscription without requiring per-resource configuration — the recommended approach for production environments. Resource-level enablement, used here, limits protection to a single account and is useful when cost control or selective coverage is required. After enabling at the resource level, the subscription-level **Environment settings** page will still show Defender for Storage as **Off** — this is expected. The subscription plan and resource-level overrides are independent. Confirm protection status on the storage account's own **Microsoft Defender for Cloud** blade, not at the subscription level.

1. Confirm the protection status shows **On** after enabling.

---

## Confirm diagnostic logging

Diagnostic logs capture management-plane operations on the storage account — including configuration changes, access policy modifications, and Defender for Storage alerts — and forward them to a Log Analytics workspace for retention and querying.

1. In the left menu for `sc500lab2astorage`, under **Monitoring**, select **Diagnostic settings**.

    The page shows diagnostic settings for the storage account and its sub-services. `StorageRead`, `StorageWrite`, and `StorageDelete` are blob-level log categories, so you need to configure settings at the blob sub-service level.

1. Under the resource list, select **blob**.

1. Select **+ Add diagnostic setting**.

1. Configure the following:

    | Setting | Value |
    |---------|-------|
    | **Diagnostic setting name** | sc500-storage-diag |
    | **Logs** | Select **StorageRead**, **StorageWrite**, and **StorageDelete** |
    | **Destination** | Select **Send to Log Analytics workspace** |
    | **Subscription** | Your lab subscription |
    | **Log Analytics workspace** | sc500-lab2a-log |

    > **Note**: The page may also show a **Diagnostic settings (classic)** row with a status of **Not enabled**. Ignore this row — it is the legacy configuration model. The **+ Add diagnostic setting** button above it uses the correct Azure Monitor version.

1. Select **Save**.

    > **Note**: Log ingestion to Log Analytics typically takes 2–5 minutes after the diagnostic setting is saved. In a production environment, you would query this workspace using KQL to review access patterns, detect configuration drift, and correlate storage activity with Defender for Storage alerts.

---

## Summary

In this lab, you secured an Azure storage account that was previously open to all networks with no threat detection.

You created a **stored access policy** on the `training-data` container and generated a SAS token that references it. Unlike standalone SAS tokens — which cannot be revoked without rotating the account key — a policy-backed token can be invalidated instantly by modifying or deleting the policy. You verified the token worked before any network restrictions were in place.

You then changed the storage account from **Allow all networks** to a VNet-only configuration, restricting data-plane access to the `sc500-lab2a-vnet` subnet and removing the **Allow Azure services** exception. You confirmed the restriction is active by running the same blob list command from Cloud Shell and observing the 403 error — and by observing that the Azure portal's Storage browser was also blocked from your current IP.

Finally, you enabled **Defender for Storage** at the resource level to detect anomalous access patterns and data exfiltration attempts, and configured diagnostic log forwarding to a Log Analytics workspace for audit retention.
