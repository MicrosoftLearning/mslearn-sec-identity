---
lab:
    title: 'Configure and Use Microsoft Security Copilot'
    description: 'Provision Security Copilot capacity, configure workspace settings and roles, enable core Microsoft security plugins, review agent capabilities, and run grounded security prompts.'
    level: 300
    duration: 45
    islab: true
    primarytopics:
        - Microsoft Security Copilot
        - Workspace configuration and RBAC
        - Plugins and agents
---

# Lab Setup

Lab profile - Bring Your Own Subscription (BYOS). 

This lab requires both a Security Admin role and a Global Admin role to run. Additionally, it requires access to SCUs, and a Microsoft Security Copilot license. Most ALH hosted environments cannot provide this within their hosted lab environment. Please feel free to read over the steps to learn about the features and capabilities. If you have a personally available subscription that meets the requirements, the lab will work as built. Please use as needed. The Global Admin and Security Admin roles have privileged access that can be used to exploit systems, so its use has to be limited.

===

# Configure and Use Microsoft Security Copilot

You are preparing Security Copilot for operational use in a production security environment. The objective is not just to run prompts, but to set up capacity, permissions, data access, and plugin scope so Copilot can provide grounded, useful responses without unnecessary blast radius.

In this lab, you will:

- Provision Security Copilot SCU capacity.
- Configure workspace data-sharing settings.
- Assign contributor access for a delegated analyst user.
- Enable core Microsoft security plugins.
- Review and enable a built-in Copilot agent.
- Run structured prompts against connected security data.

This exercise should take approximately **45** minutes to complete.

> **Note**: This lab assumes Security Copilot SCU provisioning is enabled in your environment and that relevant Microsoft security data sources are available.

---

## Review the Preconfigured State

1. Sign in to the Azure portal and open **Resource groups**.

1. Select **sc500-lab4f-rg** and confirm **sc500-lab4f-storage** exists.

1. Confirm your tenant account includes access required to provision SCU capacity in Security Copilot.

---

## Provision Security Copilot Capacity

1. Sign in to [https://securitycopilot.microsoft.com](https://securitycopilot.microsoft.com) using your Global Administrator account.

1. Start the setup flow for capacity provisioning.

1. Provision **1 SCU** in **East US**.

1. Confirm provisioning completes and the workspace becomes available.

1. Record capacity settings in your notes:

    | Field | Value |
    |-------|-------|
    | Region | East US |
    | SCU count | 1 |

---

## Configure Workspace and Role Assignments

1. Open **Owner settings** in Security Copilot.

1. Open **Data sharing** and configure least-privilege sharing choices for this lab environment.

1. Save settings.

1. Open **Roles**.

1. Confirm your account is listed as workspace owner.

1. Assign **Security Copilot Contributor** role to **sc500-user12**.

1. Confirm the role assignment is visible.

---

## Enable Security Plugins

1. Open **Sources** or **Plugins** in Security Copilot.

1. Enable the following plugins:

    - Microsoft Defender XDR
    - Microsoft Defender for Cloud
    - Microsoft Sentinel
    - Microsoft Entra

1. Wait for plugin connection states to update.

1. Confirm each plugin shows connected.

1. Record plugin status in your notes:

    | Plugin | Status |
    |--------|--------|
    | Defender XDR | |
    | Defender for Cloud | |
    | Sentinel | |
    | Entra | |

---

## Review and Enable a Built-in Agent

1. Open **Agents** in Security Copilot.

1. Select **Vulnerability Impact Assessment** (or the equivalent built-in vulnerability-focused agent in your environment).

1. Review agent details:

    - Purpose
    - Required data sources
    - Permission scope implications

1. Enable the agent.

1. In your notes, summarize in 2-3 lines how this agent's potential blast radius depends on plugin access scope.

---

## Run Grounded Security Prompts

1. Return to the main Security Copilot prompt experience.

1. Run this prompt:

    ```input
    Summarize the current security posture of this environment based on Defender for Cloud findings. What are the top 3 recommendations?
    ```

1. Review the response and citations.

1. Run this follow-up prompt:

    ```input
    Provide step-by-step remediation actions for the top recommendation you just identified.
    ```

1. Record in your notes:

    | Field | Value |
    |-------|-------|
    | Top recommendation returned | |
    | Referenced source/plugin | |
    | Actionability of remediation steps | |

---

## Summary

In this lab, you configured Security Copilot as an operational security platform component:

- Provisioned compute capacity.
- Applied workspace governance and delegated role access.
- Connected core Microsoft security data sources through plugins.
- Enabled a built-in autonomous security agent.
- Executed grounded prompts tied to Defender posture data.

This establishes the day-4 capstone pattern: configuration quality in your security stack directly improves Copilot output quality.
