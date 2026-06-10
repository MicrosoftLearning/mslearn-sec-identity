---
lab:
    title: 'Explore Defender for Cloud Security Posture and CSPM'
    description: 'Review Secure Score and recommendations, map compliance controls, investigate CSPM secret scanning findings, and assign governance ownership in Defender for Cloud.'
    level: 300
    duration: 75
    islab: true
    primarytopics:
        - Microsoft Defender for Cloud
        - Defender CSPM
        - Regulatory compliance and governance rules
---

# Explore Defender for Cloud Security Posture and CSPM

Your organization needs a posture update that goes beyond single findings. Leadership wants to know:

- Current Secure Score and top risk drivers.
- Compliance state against a named framework.
- Whether secrets are exposed outside approved secret stores.
- Who owns remediation and by when.

In this lab, you will use Defender for Cloud to evaluate and action security posture using recommendation prioritization, compliance mapping, secret scanning, governance assignment, and attack path review.

In this lab, you will:

- Record Secure Score and key recommendation signals.
- Assign and review NIST SP 800-53 Rev. 5 compliance controls.
- Investigate a CSPM secret-scanning finding.
- Compare unsafe secret placement with correct Key Vault usage.
- Review attack path analysis.
- Assign a governance rule with owner and due date.
- Optionally review multicloud connector scope.

This exercise should take approximately **75** minutes to complete.

> **Note**: This lab relies on pre-populated Defender for Cloud findings and recommendations in the environment.

---

## Review the Preconfigured State

1. In the Azure portal, open **Resource groups** and select **sc500-lab4d-rg**.

1. Confirm the following resources are present:

    - **sc500-lab4d-storage**
    - **sc500-lab4d-webapp**
    - **sc500-lab4d-kv**
    - **sc500-lab4d-vm**

1. Open **Microsoft Defender for Cloud** and confirm the subscription shows active posture data.

---

## Review Secure Score and Top Recommendations

1. Sign in to the [Azure portal](https://portal.azure.com) with your Global Administrator account.

1. Open **Microsoft Defender for Cloud**.

1. On **Overview**, record:

    | Field | Value |
    |-------|-------|
    | Secure Score (%) | |
    | Unhealthy resources count | |
    | Active recommendations count | |

1. Open **Recommendations**.

1. Sort by **Max score impact**.

1. Open the highest-impact recommendation and review affected resources and remediation guidance.

1. If a non-destructive quick fix is available, apply it.

---

## Assign and Review Regulatory Compliance

1. In Defender for Cloud, open **Regulatory compliance**.

1. Select **Add standards**.

1. Assign **NIST SP 800-53 Rev. 5** to the subscription.

1. After assignment appears, open the NIST view.

1. Identify two failing controls and capture:

    | Field | Control 1 | Control 2 |
    |-------|-----------|-----------|
    | Control ID and title | | |
    | Backing policy name | | |
    | Quick fix available (Y/N) | | |

---

## Investigate CSPM Secret Scanning Findings

1. Open **Cloud Security Posture Management** and navigate to **Secret scanning**.

1. Locate the finding for **sc500-lab4d-webapp**.

1. Open finding details and record:

    | Field | Value |
    |-------|-------|
    | Finding type | |
    | Affected resource | sc500-lab4d-webapp |
    | Detected secret category | |

1. Open **sc500-lab4d-webapp** configuration and identify the exposed app setting.

1. Open **sc500-lab4d-kv** in a second tab.

1. Confirm the Key Vault secret exists as a managed secret baseline.

1. In your notes, write a short explanation that covers:

    - Why secrets in app settings are flagged.
    - Why properly stored Key Vault secrets are not treated as the same CSPM finding type.
    - Why this distinction matters for remediation ownership.

---

## Review Attack Path Analysis

1. Return to Defender for Cloud and open **Attack path analysis**.

1. Open the highest-severity path shown.

1. Record the path chain in order:

    | Step | Resource or edge |
    |------|-------------------|
    | Initial exposure | |
    | Lateral movement | |
    | Blast radius target | |

1. Record one mitigation action recommended by Defender for Cloud.

---

## Assign Governance Ownership

1. Go back to **Recommendations**.

1. Select an open recommendation.

1. Assign a **Governance rule** with these settings:

    - Owner: **sc500-user11**
    - Due date: 14 days from today
    - Notification cadence: weekly

1. Save the governance assignment.

1. Confirm owner and due date appear in recommendation details.

---

## Optional Task: Review Multicloud Connector Scope

1. Open **Environment settings** and select **AWS** connectors.

1. If a connector exists, review covered resource types and finding contribution.

1. If no connector exists in your environment, mark this step as not configured in your notes.

---

## Summary

In this lab, you used Defender for Cloud to move from raw findings to actionable posture governance:

- Quantified risk with Secure Score and recommendation impact.
- Mapped posture to a named compliance framework.
- Investigated secret exposure outside secure secret-management patterns.
- Used attack path context to prioritize remediation.
- Assigned accountable governance ownership and timeline.

This is the core operating pattern for cloud security posture management at scale.
