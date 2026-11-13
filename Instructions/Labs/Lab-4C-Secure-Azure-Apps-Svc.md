---
lab:
    title: 'Secure Azure App Services and API Management'
    description: 'Use WAF detection and prevention controls, configure Microsoft Entra authentication and network restrictions for app services, and enforce API subscription key protection in API Management.'
    level: 300
    duration: 60
    islab: true
    primarytopics:
        - Web Application Firewall (WAF)
        - Azure App Service and Function App security
        - Azure API Management
---

# Lab Setup

Follow these steps to deploy the resources used in the lab:

1. Open the **Azure portal** at `https://portal.azure.com` and sign in with **User1**.


1. In the portal search bar, find and open **Deploy a custom template**.

1. Select **Build your own template in the editor**, and then select **Load file**.

1. Select **lab-4c-setup.json** from the **F:\AllFiles\Lab-4C** folder on the lab VM, and then select **Save**.

1. On the **Basics** page, confirm **Location** is set to `centralus`.


1. Select **Review + create**, and then select **Create**.

1. Wait until the deployment shows **Succeeded** before continuing.

===

# Secure Azure App Services and API Management

A security assessment identified multiple web application platform gaps in your environment:

- No blocking WAF policy is enforced for inbound web traffic.
- App Service and Function App endpoints allow broad access.
- API calls are accepted without subscription key enforcement.

In this lab, you will validate WAF behavior in detection mode, switch to prevention mode, enforce Microsoft Entra authentication, apply network restrictions, and require subscription key protection in APIM.

In this lab, you will:

- Validate WAF detection mode logging.
- Switch WAF from detection to prevention and confirm request blocking.
- Enable Entra authentication (Easy Auth) for an App Service.
- Restrict network access to App Service and Function App.
- Configure subscription-required access in API Management.
- Validate key-required API behavior.

This exercise should take approximately **60** minutes to complete.

> **Note**: This lab uses the fixed Application Gateway `sc500-lab4c-agw` and generated services whose names begin with `sc500-lab4c-apim-`, `sc500-lab4c-webapp-`, and `sc500-lab4c-func-`. Throughout the lab, `<apim-name>`, `<web-app-name>`, and `<function-app-name>` refer to those resources. The `sc500-lab4c-rg` resource group contains exactly one of each service type.

---

## Review the Preconfigured State

1. In the Azure portal, open **Resource groups** and select **sc500-lab4c-rg**.

1. Confirm the following resources are present:

    - **sc500-lab4c-agw**
    - **<apim-name>**
    - **<web-app-name>**
    - **<function-app-name>**

1. From the resource list, select **sc500-lab4c-waf**.

1. On the Overview page, confirm that Policy mode is set to **Detection**.

---

## Validate WAF Detection Mode

1. In the **Azure portal**, search for and select **Application gateways**, then select **sc500-lab4c-agw**.

1. On the **Overview** page, copy the **Frontend public IP address**.

1. Open **Cloud Shell** in the Azure portal.

1. Send a test request using the Application Gateway public endpoint and a SQL-injection-style payload:

    ```bash
    curl -H "X-Scan-Test: 1" "http://<agw-public-ip>/?id=1+UNION+SELECT+NULL,username,password+FROM+users--"
    ```

   > **Note**: Replace <agw-public-ip> with the Frontend public IP address of your Application Gateway before running the command.

1. In the Azure portal search bar, search for and select **Log Analytics workspaces**.

1. Select **sc500-lab4c-log**, then from the left menu, select **Logs**.

1. Close the **Queries** dialog if it appears.

   > **Note:** If **Agent mode** is On, switch the **Agent** toggle to Off before continuing.

1. In the upper-right corner of the page, select the mode dropdown and switch from **Simple mode** to **KQL mode**. This opens the KQL query editor.

1. Run a query similar to the following to confirm WAF logged the request:

    ```kusto
    AzureDiagnostics
    | where ResourceType == "APPLICATIONGATEWAYS"
    | where requestUri_s contains "UNION"
    | sort by TimeGenerated desc
    ```

1. Wait up to **10 minutes** for diagnostic data to arrive. Re-run the query every 1-2 minutes until the request appears.

1. Confirm that the request was logged while the WAF policy was in **Detection** mode.

---

## Switch WAF to Prevention Mode and Re-test

1. In the Azure portal, search for **Web Application Firewalls**, then select **Web Application Firewall policies (WAF)** from the search results.

1. Select **sc500-lab4c-waf**.

1. At the top of the **Overview** page, select **Switch to prevention mode**.

1. Confirm that **Policy mode** changes from **Detection** to **Prevention**.

1. Run the same `curl` test again from Cloud Shell:

   ```bash
    curl -H "X-Scan-Test: 1" "http://<agw-public-ip>/?id=1+UNION+SELECT+NULL,username,password+FROM+users--"
    ```

   > **Note**: Replace <agw-public-ip> with the Frontend public IP address of your Application Gateway before running the command.

1. Confirm the request is blocked (typically HTTP 403).

1. Record the result in your notes:

    | Test | Expected result |
    |------|-----------------|
    | Detection mode request | Logged, not blocked |
    | Prevention mode request | Blocked (HTTP 403) |

---

## Enable App Service Authentication

1. In the **Azure portal**, search for and select **App Services**, then select **<web-app-name>**.

1. In the left navigation menu, expand **Settings**, select **Authentication**, and then select **Add identity provider**.

1. For **Identity provider**, select **Microsoft**.

1. Configure the provider:

    | Setting | Value |
    |---------|-------|
    | **Tenant configuration** | Workforce configuration (current tenant) |
    | **App registration type** | Create new app registration |
    | **Client secret expiration** | 90 days (3 months) |
    | **Supported account types** | Current tenant - Single tenant |
    | **Restrict access** | Require authentication |
    | **Unauthenticated requests** | HTTP 302 Found redirect |
    | **Redirect to** | Microsoft |

1. Select **Add**. Confirm the Microsoft identity provider is listed and authentication is enabled.

1. If provider creation fails or the page reports a missing secret, use Cloud Shell to configure the same provider. Replace `<web-app-name>` with the generated App Service name:

    ```bash
    WEB_APP_NAME='<web-app-name>'
    TENANT_ID=$(az account show --query tenantId -o tsv)
    APP_URL="https://$WEB_APP_NAME.azurewebsites.net"

    APP_ID=$(az ad app create \
      --display-name "$WEB_APP_NAME-auth" \
      --sign-in-audience AzureADMyOrg \
      --web-redirect-uris "$APP_URL/.auth/login/aad/callback" \
      --query appId -o tsv)

    CLIENT_SECRET=$(az ad app credential reset \
      --id "$APP_ID" \
      --append \
      --display-name app-service-auth \
      --query password -o tsv)

    test -n "$APP_ID" || { echo "The app registration could not be created."; exit 1; }
    test -n "$CLIENT_SECRET" || { echo "The client secret could not be created."; exit 1; }

    az webapp config appsettings set \
      --resource-group sc500-lab4c-rg \
      --name "$WEB_APP_NAME" \
      --settings MICROSOFT_PROVIDER_AUTHENTICATION_SECRET="$CLIENT_SECRET" \
      --output none

    SUBSCRIPTION_ID=$(az account show --query id -o tsv)

    AUTH_BODY=$(jq -n \
      --arg clientId "$APP_ID" \
      --arg issuer "https://sts.windows.net/$TENANT_ID/v2.0" \
      '{properties:{platform:{enabled:true,runtimeVersion:"~1"},globalValidation:{requireAuthentication:true,unauthenticatedClientAction:"RedirectToLoginPage",redirectToProvider:"azureactivedirectory"},identityProviders:{azureActiveDirectory:{enabled:true,registration:{openIdIssuer:$issuer,clientId:$clientId,clientSecretSettingName:"MICROSOFT_PROVIDER_AUTHENTICATION_SECRET"}}},login:{tokenStore:{enabled:true}}}}')

    az rest --method put \
      --uri "https://management.azure.com/subscriptions/$SUBSCRIPTION_ID/resourceGroups/sc500-lab4c-rg/providers/Microsoft.Web/sites/$WEB_APP_NAME/config/authsettingsV2?api-version=2022-03-01" \
      --body "$AUTH_BODY" \
      --output none

    az rest --method get \
      --uri "https://management.azure.com/subscriptions/$SUBSCRIPTION_ID/resourceGroups/sc500-lab4c-rg/providers/Microsoft.Web/sites/$WEB_APP_NAME/config/authsettingsV2?api-version=2022-03-01" \
      --query '{Enabled:properties.platform.enabled,UnauthenticatedAction:properties.globalValidation.unauthenticatedClientAction}' \
      --output table

    unset CLIENT_SECRET AUTH_BODY
    ```

1. Wait up to **2 minutes** for authentication settings to propagate. Open the app URL in a private browser window and confirm it redirects to Microsoft sign-in.

---

## Apply Network Restrictions to App Service and Function App

1. In **<web-app-name>**, expand **Settings** in the left navigation menu, and then select **Networking**.

1. Under **Inbound traffic configuration**, select **Enabled with no access restrictions** next to **Public network access**.

1. On the **Access Restrictions** page, under **Public network access**, select **Enabled from select virtual networks and IP addresses**.

1. Under **Main site**, select **Add**.

1. On the **Add rule** pane, configure the following settings:

   | **Setting** | **Value** |
   | --- | --- |
   | **Name** | `Allow-AppGateway` |
   | **Action** | **Allow** |
   | **Priority** | `300` |
   | **Type** | **Virtual Network** |
   | **Subscription** | Select the current subscription |
   | **Virtual Network** | **sc500-lab4c-vnet** |
   | **Subnet** | **agw-subnet** |

1. Select **Add rule**.

1. For **Unmatched rule action**, select **Deny**.

1. Select **Save**. On the **Access update confirmation**, select the confirmation checkbox, and then select **Continue**.

1. In the Azure portal, search for and select **Function Apps**, and then select **<function-app-name>**.

1. In the left navigation menu, expand **Settings**, and then select **Networking**.

1. Under **Inbound traffic configuration**, select **Enabled with no access restrictions** next to **Public network access**.

1. On the **Access Restrictions** page, under **Public network access**, select **Enabled from select virtual networks and IP addresses**.

1. Under **Main site**, select **Add**, and configure the rule as follows:

   | **Setting** | **Value** |
   | --- | --- |
   | **Name** | `Allow-FunctionSubnet` |
   | **Action** | **Allow** |
   | **Priority** | `300` |
   | **Type** | **Virtual Network** |
   | **Subscription** | Select the current subscription |
   | **Virtual Network** | **sc500-lab4c-vnet** |
   | **Subnet** | **func-allowed-subnet** |

1. Select **Add rule**.

1. For **Unmatched rule action**, select **Deny**, and then select **Save**.

1. On the **Access update confirmation** page, select the confirmation checkbox, and then select **Continue**.

---

### Enforce Subscription Key Protection in API Management

1. In the **Azure portal**, search for and select **API Management services**, and then select **sc500-lab4c-apim-XXXX**.

1. In the left navigation menu, expand **APIs**, select **APIs**, and then select **Lab 4C API**.

1. Select **Settings**, set **Subscription required** to **Required**, and then select **Save**.

1. In the left navigation menu, under **APIs**, select **Subscriptions**. Create a test subscription if needed, or open an existing subscription, and copy one of its subscription keys.

1. Return to **APIs** > **Lab 4C API**, select the **Test** tab, and then select **Get Status**.

1. Under **Headers**, select **+ Add header**, and enter the following:

   | **Setting** | **Value** |
   | --- | --- |
   | Name | `Ocp-Apim-Subscription-Key` |
   | Value | Paste the subscription key copied in the previous step |

1. Select **Send** and confirm that the request returns **HTTP 200**.

1. Test without a valid subscription key. In the **Headers** section, clear the value of the **Ocp-Apim-Subscription-Key** header or replace it with an invalid key, and then select **Send**. Confirm that API Management returns **HTTP 401 Access Denied**.
   
1. Record the results in your notes:

   | **Request type** | **Expected result** |
   | --- | --- |
   | With key | HTTP 200 |
   | Without key | HTTP 401 |

---

## Summary

In this lab, you implemented layered controls for web and API workloads:

- WAF inspection and active blocking with prevention mode.
- Identity enforcement with Entra authentication for App Service.
- Network narrowing for App Service and Function App.
- API admission control through APIM subscription keys.

These controls reduce exploitability, limit unauthenticated access paths, and enforce policy at both network and application layers.
