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

1. Open **sc500-lab4c-agw** and confirm the attached WAF policy is currently in **Detection** mode.

---

## Validate WAF Detection Mode

1. Sign in to the [Azure portal](https://portal.azure.com) with your **User1** account.

1. Open **Application gateways** and select **sc500-lab4c-agw**.

1. Open the attached WAF policy and confirm:

    - Mode: **Detection**
    - Rule set: OWASP CRS (current configured version)

1. Open **Cloud Shell** in the Azure portal.

1. Send a test request using the Application Gateway public endpoint and a SQL-injection-style payload:

    ```bash
    curl -H "X-Scan-Test: 1" "http://<agw-public-ip>/?id=1+UNION+SELECT+NULL,username,password+FROM+users--"
    ```

1. Open **Log Analytics workspaces** and select **sc500-lab4c-log**.

1. Run a query similar to the following to confirm WAF logged the request:

    ```kusto
    AzureDiagnostics
    | where ResourceType == "APPLICATIONGATEWAYS"
    | where requestUri_s contains "UNION"
    | sort by TimeGenerated desc
    ```

1. Wait up to **10 minutes** for diagnostic data to arrive. Re-run the query every 1-2 minutes until the request appears.

1. Confirm the request is logged in detection mode.

---

## Switch WAF to Prevention Mode and Re-test

1. Return to the WAF policy for **sc500-lab4c-agw**.

1. Change mode from **Detection** to **Prevention**.

1. Save the policy.

1. Run the same `curl` test again from Cloud Shell.

1. Confirm the request is blocked (typically HTTP 403).

1. Record the result in your notes:

    | Test | Expected result |
    |------|-----------------|
    | Detection mode request | Logged, not blocked |
    | Prevention mode request | Blocked |

---

## Enable App Service Authentication

1. Open **App Services** and select **<web-app-name>**.

1. Open **Authentication**, and then select **Add identity provider**.

1. For **Identity provider**, select **Microsoft**.

1. Configure the provider:

    | Setting | Value |
    |---------|-------|
    | **Tenant configuration** | Workforce configuration (current tenant) |
    | **App registration type** | Create new app registration |
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

    az webapp auth show \
      --resource-group sc500-lab4c-rg \
      --name "$WEB_APP_NAME" \
      --query '{Enabled:platform.enabled,UnauthenticatedAction:globalValidation.unauthenticatedClientAction}' \
      --output table

    unset CLIENT_SECRET AUTH_BODY
    ```

1. Open the app URL in a private browser window and confirm it redirects to Microsoft sign-in.

---

## Apply Network Restrictions to App Service and Function App

1. In **<web-app-name>**, open **Networking** and then **Access restrictions**.

1. Add an allow rule for the approved subnet associated with Application Gateway.

1. Set default action to **Deny** for unmatched traffic.

1. Save changes.

1. Open **Function Apps** and select **<function-app-name>**.

1. Open **Networking** and configure access restrictions.

1. Add an allow rule for the approved function subnet only.

1. Set default action to **Deny**.

1. Save changes.

---

## Enforce Subscription Key Protection in API Management

1. Open **API Management services** and select **<apim-name>**.

1. Open **APIs** and select the pre-configured API.

1. In API settings, set **Subscription required** to **Required**.

1. Save changes.

1. Create or open a test subscription and copy a key.

1. Test with a key. Include the `Ocp-Apim-Subscription-Key` header and confirm the mock API returns HTTP **200**.

1. Test without a key. Remove the subscription key header and confirm APIM returns HTTP **401**.

1. Record results in your notes:

    | Request type | Expected result |
    |--------------|-----------------|
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
