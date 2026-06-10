---
lab:
    title: 'Secure Azure App Services and API Management'
    description: 'Use WAF detection and prevention controls, configure Microsoft Entra authentication and network restrictions for app services, and enforce API subscription key protection in API Management.'
    level: 300
    duration: 45
    islab: true
    primarytopics:
        - Web Application Firewall (WAF)
        - Azure App Service and Function App security
        - Azure API Management
---

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

This exercise should take approximately **45** minutes to complete.

> **Note**: This lab uses pre-provisioned resources in the subscription, including `sc500-lab4c-agw`, `sc500-lab4c-apim`, `sc500-lab4c-webapp`, and `sc500-lab4c-func`.

---

## Review the Preconfigured State

1. In the Azure portal, open **Resource groups** and select **sc500-lab4c-rg**.

1. Confirm the following resources are present:

    - **sc500-lab4c-agw**
    - **sc500-lab4c-apim**
    - **sc500-lab4c-webapp**
    - **sc500-lab4c-func**

1. Open **sc500-lab4c-agw** and confirm the attached WAF policy is currently in **Detection** mode.

---

## Validate WAF Detection Mode

1. Sign in to the [Azure portal](https://portal.azure.com) with your Global Administrator account.

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

1. Open **App Services** and select **sc500-lab4c-webapp**.

1. Open **Authentication**.

1. Turn authentication **On**.

1. Set **Identity provider** to Microsoft Entra ID.

1. Set unauthenticated request behavior to redirect to sign-in.

1. Save configuration.

1. Open the app URL in a private browser window and confirm sign-in is required.

---

## Apply Network Restrictions to App Service and Function App

1. In **sc500-lab4c-webapp**, open **Networking** and then **Access restrictions**.

1. Add an allow rule for the approved subnet associated with Application Gateway.

1. Set default action to **Deny** for unmatched traffic.

1. Save changes.

1. Open **Function Apps** and select **sc500-lab4c-func**.

1. Open **Networking** and configure access restrictions.

1. Add an allow rule for the approved function subnet only.

1. Set default action to **Deny**.

1. Save changes.

---

## Enforce Subscription Key Protection in API Management

1. Open **API Management services** and select **sc500-lab4c-apim**.

1. Open **APIs** and select the pre-configured API.

1. In API settings, set **Subscription required** to **Required**.

1. Save changes.

1. Create or open a test subscription and copy a key.

1. Test with key (expect success):

    - Include header `Ocp-Apim-Subscription-Key`.

1. Test without key (expect denial):

    - Remove the subscription key header.

1. Record results in your notes:

    | Request type | Expected result |
    |--------------|-----------------|
    | With key | Success |
    | Without key | Unauthorized/denied |

---

## Summary

In this lab, you implemented layered controls for web and API workloads:

- WAF inspection and active blocking with prevention mode.
- Identity enforcement with Entra authentication for App Service.
- Network narrowing for App Service and Function App.
- API admission control through APIM subscription keys.

These controls reduce exploitability, limit unauthenticated access paths, and enforce policy at both network and application layers.
