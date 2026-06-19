// =============================================================================
// SC-500 ILT — Lab 1D: Custom Tag Enforcement Policy
// =============================================================================
//
// What this file does:
//   1. Defines a custom Azure Policy that requires an 'Environment' tag on all
//      resource groups (Deny effect, subscription scope).
//   2. Creates a subscription-scope assignment for the policy definition.
//
// Student deployment command (run in Cloud Shell — Bash):
//   az deployment sub create \
//     --name sc500-tag-policy \
//     --location eastus \
//     --template-file ~/sc500-lab1d-policy.bicep
//
// Required permissions:
//   Caller must have Owner or Policy Contributor at the subscription scope.
//   Microsoft.PolicyInsights resource provider must be registered on the
//   subscription (pre-registered as part of the Skillable lab template setup).
//
// =============================================================================

targetScope = 'subscription'

// ---------------------------------------------------------------------------
// Variables
// ---------------------------------------------------------------------------

var policyDefinitionName = 'sc500-require-env-tag-on-rgs'
var policyAssignmentName = 'sc500-require-env-tag-assign'

// ---------------------------------------------------------------------------
// Policy Definition
//
// mode: 'All' is required to evaluate resource groups.
// mode: 'Indexed' only evaluates resource types that natively support tags
// and would skip Microsoft.Resources/subscriptions/resourceGroups.
//
// Effect: 'deny' blocks creation of resource groups missing the Environment
// tag. Existing non-compliant resource groups appear as Non-compliant in the
// compliance report but are not modified or deleted.
// ---------------------------------------------------------------------------

resource tagPolicyDefinition 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: policyDefinitionName
  properties: {
    policyType: 'Custom'
    mode: 'All'
    displayName: 'Require Environment tag on resource groups'
    description: 'Denies creation of resource groups that do not include an Environment tag. Deployed as part of SC-500 ILT Lab 1D to demonstrate Infrastructure as Code policy governance.'
    metadata: {
      category: 'Tags'
      version: '1.0.0'
    }
    parameters: {}
    // The policy rule is expressed as a JSON string using Bicep's multiline
    // string syntax (''' delimiters) to avoid the single-quote escaping issue
    // that affects tag field references like tags['Environment'] in some
    // versions of the Bicep compiler. The json() function converts it to an
    // object at compile time — the output ARM JSON is identical either way.
    policyRule: json('''
      {
        "if": {
          "allOf": [
            {
              "field": "type",
              "equals": "Microsoft.Resources/subscriptions/resourceGroups"
            },
            {
              "field": "tags['Environment']",
              "exists": "false"
            }
          ]
        },
        "then": {
          "effect": "deny"
        }
      }
    ''')
  }
}

// ---------------------------------------------------------------------------
// Policy Assignment (subscription scope)
//
// Assigns the custom policy definition to the entire subscription.
// enforcementMode: 'Default' means the Deny effect is fully enforced.
// enforcementMode: 'DoNotEnforce' would audit without blocking — useful for
// testing; not used here so students see the policy is actively governing.
// ---------------------------------------------------------------------------

resource tagPolicyAssignment 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
  name: policyAssignmentName
  properties: {
    displayName: 'Require Environment tag on resource groups'
    description: 'Subscription-scope assignment requiring the Environment tag on all resource groups. Part of SC-500 ILT Lab 1D.'
    policyDefinitionId: tagPolicyDefinition.id
    enforcementMode: 'Default'
    nonComplianceMessages: [
      {
        message: 'Resource groups must include an Environment tag. Add the Environment tag before creating this resource group.'
      }
    ]
  }
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------

output policyDefinitionId string = tagPolicyDefinition.id
output policyDefinitionName string = tagPolicyDefinition.name
output policyAssignmentId string = tagPolicyAssignment.id
