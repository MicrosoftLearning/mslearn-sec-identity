---
lab:
    title: 'Secure Azure SQL Database'
    description: 'Harden a pre-provisioned Azure SQL database by replacing SQL authentication with Entra ID group-based authentication, restricting network access via a Private Endpoint, enabling auditing to a Log Analytics workspace, and enabling Defender for Databases.'
    level: 300
    duration: 60
    islab: true
    primarytopics:
        - Azure SQL Security
        - Microsoft Defender for Databases
        - Private Endpoints
        - SQL Auditing
---

# Lab Setup

Follow these steps to build out your lab scenarios:

1. Open the **Azure Portal** at `https://portal.azure.com`.

1. Log in with the **User1** administrator role.

1. Open **Cloud Shell**, select **Bash**, and run the following commands to register the resource provider used by Defender for Databases:

    ```bash
    az provider register --namespace Microsoft.Security --wait
    az provider show --namespace Microsoft.Security --query registrationState -o tsv
    ```

    Confirm that the second command returns `Registered` before continuing.

1. In the **Search** bar find and open **Deploy a custom template**.
   
1. Select **Build your own template in the editor**.

1. In the menu choose **Load file**.

1. Select the file **lab-2b-setup.json** from the **F:\AllFiles\Lab-2B** folder on the lab VM.

1. Select **Save**.

1. On the **Basics** tab, confirm **Location** is set to **East US**. The template supplies this value automatically.

1. Select **Review + create**, and then select **Create**.

    > **Note**: Deployment typically takes **10–15 minutes** while the database initialization script runs. Wait until the deployment shows **Succeeded** before continuing. Do not continue while the top-level or nested deployment is still **Running**.

1. Close the browser.

===

# Secure Azure SQL Database

A penetration test of your organization's AI application database found three critical findings. First, the database server has no Microsoft Entra administrator — there is no identity governance over who holds database credentials, and no Entra ID audit trail for administrative access. Second, the **Allow Azure services and resources to access this server** firewall exception is enabled, creating a bypass that allows any Azure-hosted service — regardless of ownership or location — to reach the database. Third, the server has no auditing configured, so there is no record of who queried what data or when.

Your task is to address all three findings. You will add a security group-backed Entra ID administrator while retaining SQL authentication for a controlled verification step, remove the Azure services firewall bypass, isolate the database to a Private Endpoint, enable auditing to a Log Analytics workspace, and turn on Defender for Databases.

In this lab, you will:

- Create an Entra ID security group and configure it as the SQL server's Entra ID administrator
- Disable the Azure services firewall exception and configure a Private Endpoint
- Enable SQL auditing to a Log Analytics workspace
- Run a query to generate an auditable event and verify it appears in Log Analytics
- Enable Defender for Databases

This exercise should take approximately **60** minutes to complete.

---

## Configure Entra ID authentication

Using a SQL-only administrator account means database access cannot be governed by Entra ID Conditional Access, PIM, or sign-in risk policies — and the credentials exist independently of your identity platform. Replacing the SQL admin with an Entra ID security group addresses this: group membership is managed in Entra ID, access can be audited through Entra sign-in logs, and the group itself can be governed by access reviews.

You will create a security group named `sc500-sql-admins`, add `User3` as a member, and configure the group as the Entra ID administrator for the SQL server deployed in `sc500-lab2b-rg`.

1. Sign in to the **Microsoft Entra admin center** at `https://entra.microsoft.com` using the credentials provided for **User1**. User1 must have the **Global Administrator** role.

1. In the left menu, expand **Groups** and select **All groups**.

1. Select **New group**.

1. Configure the following:

    | Setting | Value |
    |---------|-------|
    | **Group type** | Security |
    | **Group name** | `sc500-sql-admins` |
    | **Group description** | Entra ID administrator group for the Lab 2B SQL server |
    | **Membership type** | Assigned |

1. Under **Members**, select **No members selected**.

1. Search for and select **User3**, then select **Select**.

1. Select **Create**.

    > **Note**: Using a group rather than an individual account as the SQL Entra ID administrator centralizes access management — administrators are added and removed via group membership without requiring a change to the SQL server configuration. It also enables access reviews on the group to periodically certify that all members still need database admin access.

1. Navigate to the **Azure portal** `https://portal.azure.com`.

1. In the search bar, search for and select **SQL servers**.

1. Select the SQL server in **sc500-lab2b-rg** whose name begins with `sc500-lab2b-sql-`.

1. In the left menu, under **Settings**, select **Microsoft Entra ID**.

1. Select **Set admin**.

1. Search for and select **sc500-sql-admins**, then select **Select**.

1. Select **Save**.

    Confirm that the **Microsoft Entra admin** field now shows `sc500-sql-admins` and that **Microsoft Entra authentication only** is available as an option.

    > **Note**: Enabling **Microsoft Entra authentication only** disables SQL authentication entirely — no SQL login credentials can be used. This is the most secure configuration but requires verifying that all applications and services connecting to the database support Entra ID authentication before enabling it. For this lab, leave mixed authentication in place to allow the portal query editor to connect in a later step.

---

## Restrict network access and configure a Private Endpoint

The **Allow Azure services and resources to access this server** exception grants data-plane access to any Azure service in any subscription or tenant — not just your own. This is a broad bypass that was likely enabled as a convenience setting during initial deployment. You will remove it, then create a Private Endpoint to provide controlled, VNet-scoped access to the database.

> **Important**: Complete the auditing task in the next section — specifically the step that runs a query using the portal query editor — **before** you disable the public endpoint in step 9 of this section. The portal query editor uses the public endpoint, and it will be unavailable after the public endpoint is disabled.

1. In the left menu for the SQL server, under **Security**, select **Networking**.

1. At the bottom of the **Networking** page, under **Exceptions**, clear the checkbox for **Allow Azure services and resources to access this server**.

1. Select **Save**.

1. Select the **Private access** tab.

1. Select **+ Create a private endpoint**.

1. On the **Basics** tab, configure the following:

    | Setting | Value |
    |---------|-------|
    | **Resource group** | sc500-lab2b-rg |
    | **Name** | `sc500-sql-pe` |
    | **Region** | Use the same region as `sc500-lab2b-sql` (the region selected during Lab Setup) |

1. Select **Next: Resource**.

1. On the **Resource** tab, confirm the following are pre-populated:

    | Setting | Value |
    |---------|-------|
    | **Resource type** | Microsoft.Sql/servers |
    | **Resource** | The SQL server whose name begins with `sc500-lab2b-sql-` |
    | **Target sub-resource** | sqlServer |

1. Select **Next: Virtual Network**.

1. On the **Virtual Network** tab, configure the following:

    | Setting | Value |
    |---------|-------|
    | **Virtual network** | `sc500-lab2b-vnet` |
    | **Subnet** | default |
    | **Private IP configuration** | Dynamically allocate IP address |

1. Select **Next: DNS**.

1. On the **DNS** tab, confirm **Integrate with private DNS zone** is set to **Yes** and that the DNS zone shown is **privatelink.database.windows.net**.

    > **Note**: The `privatelink.database.windows.net` private DNS zone was pre-provisioned and linked to `sc500-lab2b-vnet`. When the private endpoint is created, it automatically registers an A record in this zone that maps the SQL server's fully qualified domain name to the private IP address — ensuring that resources in the VNet resolve to the private endpoint rather than the public IP.

1. Use the **Next** button to get to the **Review + create** tab.

1. Select **Review + create**, then select **Create**.

    Wait for the private endpoint to finish deploying — this typically takes 1–2 minutes.

    > **Note**: Do not disable the public endpoint yet. You must first complete the SQL auditing task and run a query through the portal query editor, which uses the public endpoint. Return to this step after you have completed the section below.

---

## Enable SQL auditing and generate an auditable event

SQL auditing records all database-level events — queries, logins, schema changes, and errors — to a durable destination. Without auditing, there is no record of data access: you cannot answer "who ran a SELECT against the model metadata table at 2am on Tuesday?" Auditing to Log Analytics enables querying that history with KQL and building alerts on anomalous patterns.

> **Note**: Complete this entire section — including the step that runs a SELECT query in the portal query editor — **before** returning to disable the public SQL endpoint. Once the public endpoint is disabled, the portal query editor can no longer connect.

1. In the left menu for the SQL server, under **Security**, select **Auditing**.

1. Set **Enable Azure SQL Auditing** to **On**.

1. Under **Audit log destination**, select **Log Analytics**.

1. Select your lab subscription and **sc500-lab2b-log** as the Log Analytics workspace.

1. Select **Save**.

    > **Note**: Server-level auditing applies to all databases on the server, including `ai-workload-db`. You do not need to configure auditing separately at the database level.

1. In the left menu for the SQL server, under **Settings**, select **SQL databases**.

1. Select **ai-workload-db** to open the database.

1. In the left menu for `ai-workload-db`, select **Query editor (preview)**.

1. In the authentication panel, select **SQL authentication**. Enter the following credentials:

    | Field | Value |
    |-------|-------|
    | **Login** | sc500sqladmin |
    | **Password** | SC500Lab2b! |

    If the query editor reports that your IP address isn't allowed, select **Allowlist IP `<current-ip-address>`**. Wait up to 5 minutes for the firewall rule to take effect, and then select **Connect** again with the same credentials.

    > **Note**: The User1 account does not have database access — only members of the `sc500-sql-admins` Entra ID admin group do. SQL authentication uses the built-in SQL admin account created when the server was provisioned, which has access regardless of Entra ID group membership.

1. Select **+ New Query** to open a new query pane before typing.

1. In the query editor, run the following query:

    ```sql
    SELECT * FROM AiModelMetadata;
    ```

    Confirm that 3 rows are returned. This query generates an auditable event that will appear in the Log Analytics workspace.

    > **Note**: Now that you have generated the auditable query, you can proceed to disable the public endpoint. After completing that step, the portal query editor will no longer be accessible, which is the expected secure configuration.

1. Return to the Lab 2B SQL server in the portal.

1. In the left menu, under **Security**, select **Networking**.

1. Select the **Public access** tab.

1. Set **Public network access** to **Disable**.

1. Select **Save**.

    > **Note**: With the public endpoint disabled and the private endpoint in place, the SQL server is now reachable only from resources within `sc500-lab2b-vnet`. The portal query editor will no longer connect — this is expected and confirms the network isolation is working correctly.

### Verify audit logs in Log Analytics

A security engineer doesn't just enable auditing — they confirm it's capturing activity. In this task you'll query Log Analytics to verify that the `SELECT * FROM AiModelMetadata` statement you ran earlier was recorded. A result confirms the full audit pipeline is working: the SQL server captured the event, forwarded it to Log Analytics, and the data is queryable.

Log Analytics ingestion typically takes 2–5 minutes after an event is generated.

1. Select **Home** to return to the Azure Overview page.

1. In the Azure portal search bar, search for and select **Log Analytics workspaces**.

1. Select **sc500-lab2b-log**.

1. In the left menu, select **Logs**.

1. Close the **Queries** dialog if it appears.

1. In the upper-right corner of the page, select the mode dropdown and switch from **Simple mode** to **KQL mode**. This opens the KQL query editor.

1. Click in the blank query area, then paste the following KQL query:

    ```kusto
    AzureDiagnostics
    | where Category == "SQLSecurityAuditEvents"
    | where statement_s contains "AiModelMetadata"
    | project TimeGenerated, server_instance_name_s, database_name_s, statement_s, client_ip_s
    | order by TimeGenerated desc
    ```

1. Select **Run** (above the query area).

    Confirm that an entry appears showing the `SELECT * FROM AiModelMetadata` statement. If no results appear, wait 2–3 minutes and select **Run** again.

    > **Note**: If results do not appear after 5 minutes, verify that the auditing setting on `sc500-lab2b-sql` shows **On** and that the Log Analytics workspace matches `sc500-lab2b-log`. Ingestion delay of up to 10 minutes is possible under high subscription load.

---

## Enable Defender for Databases

Defender for Databases provides continuous threat detection for your SQL server — identifying SQL injection attempts, brute-force login attacks, anomalous access patterns, and data exfiltration indicators. Unlike auditing, which records what happened, Defender generates real-time alerts when suspicious activity is detected.

1. In the Azure portal search bar, search for and select `Microsoft Defender for Cloud`.

1. In the left menu, under **Management**, select **Environment settings**.

1. Expand your subscription and select it.

1. On the **Defender plans** page, locate **Databases** and set it to **On**.

1. Confirm that **Azure SQL Databases** is included in the protected resource types.

1. Select **Save**.

    > **Note**: After enabling Defender for Databases, the Lab 2B SQL server may take **5–15 minutes** to appear as a protected resource in the Defender for Cloud database security view. This is expected — Defender for Cloud discovers and classifies PaaS resources asynchronously after the plan is enabled. You do not need to wait for discovery to complete before ending the lab; the plan is active even before the resource appears in the portal view.

1. Return to the Lab 2B SQL server in the Azure portal.

1. In the left menu, under **Security**, select **Microsoft Defender for Cloud**.

    Confirm that the Defender for Cloud status for this server shows **On** or **Protected**. If it still shows **Not protected**, wait 5 minutes and refresh.

---

## Summary

In this lab, you hardened an Azure SQL database that had three critical security findings from a penetration test.

You added a group-backed **Entra ID administrator** (`sc500-sql-admins`), enabling Entra ID governance — including Conditional Access, sign-in risk policies, and access reviews — to apply to database admin access.

You removed the **Allow Azure services** firewall exception that created a broad bypass for any Azure-hosted service, and deployed a **Private Endpoint** to restrict connectivity to the `sc500-lab2b-vnet` subnet. With the public endpoint subsequently disabled, the database is no longer reachable from the public internet or from Azure services outside the authorized VNet.

You enabled **SQL auditing** to a Log Analytics workspace, generating a test query to confirm that the audit pipeline captures database activity. You then verified the audit event appeared in Log Analytics using a KQL query. Finally, you enabled **Defender for Databases** to provide real-time threat detection for SQL injection, brute-force attacks, and anomalous access patterns.
