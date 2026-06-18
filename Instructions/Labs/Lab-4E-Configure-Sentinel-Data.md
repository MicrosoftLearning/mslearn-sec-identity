---
lab:
    title: 'Configure Microsoft Sentinel Data Collection and Automation'
    description: 'Connect Microsoft Defender XDR and Azure Activity data into Sentinel, verify ingestion, and configure automation rules that trigger a pre-built playbook.'
    level: 300
    duration: 45
    islab: true
    primarytopics:
        - Microsoft Sentinel
        - Data connectors
        - Automation rules and playbooks
---

# Configure Microsoft Sentinel Data Collection and Automation

Your SOC cannot automate triage if data sources are disconnected and workflow actions are missing. In this lab, you will connect high-value Microsoft data sources, verify ingestion in the workspace, and configure an automation rule that drives a pre-built playbook.

In this lab, you will:

- Review the pre-provisioned Sentinel workspace state.
- Connect the Microsoft Defender XDR connector.
- Connect the Azure Activity connector.
- Verify event ingestion with a Log Analytics query.
- Build an automation rule for high-severity incidents.
- Link the rule to the pre-built playbook.
- Review content available through Content Hub.

This exercise should take approximately **45** minutes to complete.

> **Note**: This lab uses the pre-provisioned Sentinel workspace `sc500-lab4e-sentinel` and playbook `sc500-incident-playbook`.

---

## Review / Create a Workspace for use in Microsoft Sentinel

1. Sign in to the **Azure portal** `https://portal.azure.com` with your Administrator account.

2. Open **Microsoft Sentinel**.

3. Select workspace **sc500-lab4e-sentinel**.

4. Review the workspace overview and confirm the current baseline state (connectors and incidents).

---

## Add a Microsoft Sentinel instance to a Workspace

1. If you are not already in Azure Portal, log in.

1. Open **Microsoft Sentinel**.

1. Select **Create** to add **Microsoft Sentinel** to your workspace.

1. Select **sc500-lab4e-sentinel**, then select **Add**.

---

## Connect Microsoft Defender XDR

1. In the **Microsoft Sentinel** menu, expand the **Configuration** section. Then open **Data connectors**.

1. Search for and select **Microsoft Defender XDR**.

1. Open the connector page and select **Open connector page**.

1. Complete the connection workflow if requested. By default XDR should be connected automatically.

1. Enable bi-directional incident synchronization if presented in connector options.

1. Save settings.

1. Record what data this connector contributes (alerts/incidents/entities).

---

## Connect Azure Activity

1. In **Data connectors**, search for **Azure Activity**.

1. Open the connector and connect the active subscription.

1. Save the connector configuration.

1. Confirm connector status shows connected.

---

## Verify Ingestion

1. Open **Logs** for **sc500-lab4e-sentinel**.

1. Run the following query:

    ```kusto
    AzureActivity
    | take 10
    ```

1. Confirm at least one row is returned.

1. Record values from one result:

    | Field | Value |
    |-------|-------|
    | OperationName | |
    | Caller | |
    | TimeGenerated | |

---

## Configure Automation Rule and Playbook Link

1. In Sentinel, open **Automation** then **Automation rules**.

1. Select **Create** and configure:

    - Rule name: `sc500-auto-triage`
    - Trigger: Incident created
    - Condition: Severity equals High

1. Add actions:

    - Change severity to Critical
    - Assign owner to your Global Administrator account
    - Run playbook: **sc500-incident-playbook**

1. Save the automation rule.

1. Open **sc500-incident-playbook** and review:

    - Trigger type
    - Key action steps
    - Final action output target

1. Record these details in your notes.

---

## Review Content Hub Package Scope

1. Open **Content hub** in Sentinel.

1. Search for **Microsoft Defender XDR**.

1. Open the solution details page and review included content types.

1. Record at least two analytics rule names or content artifacts listed in the package.

---

## Summary

In this lab, you established Sentinel collection and orchestration fundamentals:

- Connected core Microsoft security telemetry sources.
- Verified that events are ingesting into the workspace.
- Configured incident automation to standardize triage actions.
- Linked automation to a reusable playbook.

This creates the base operating pattern for SOC data readiness and repeatable incident response automation.
