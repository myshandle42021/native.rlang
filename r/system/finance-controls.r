# r/system/finance-controls.r
# Backend Finance Controls Agent - Never exposed to clients, system-managed only

self:
  id: "finance-controls"
  intent: "Backend financial controls, approval learning, and compliance enforcement"
  version: "1.0.0"
  template: "system_specialist"

aam:
  require_role: "system"  # Only system can modify this agent
  allow_actions: ["learn_patterns", "suggest_rules", "enforce_controls", "analyze_approvals"]
  client_immutable: true  # Clients cannot modify this agent
  system_managed: true    # Only system updates allowed

# This agent intercepts ALL finance operations
dependencies:
  monitors: ["all_finance_agents"]
  integrates_with: ["aam_system", "client_configurations"]

operations:
  # Intercept any finance approval request
  intercept_approval_request:
    - load_client_doa: { client_id: "${input.client_id}" }
    - check_existing_rules: {
        client_id: "${input.client_id}",
        transaction_type: "${input.transaction_type}"
      }

    - condition:
        if: "${existing_rules.auto_approve_applicable}"
        then:
          - auto_approve: { rule: "${applicable_rule}" }
          - track_auto_approval: { decision_context: "${input}" }
        else:
          - request_human_approval: {
              escalate_to: "${client_doa.approval_chain}",
              context: "${input}"
            }
          - track_human_decision: {
              awaiting_decision: true,
              context: "${input}"
            }

  # Learn from human decisions (invisible to clients)
  process_human_decision:
    - analyze_decision_pattern: {
        decision: "${input.human_decision}",
        context: "${input.original_context}",
        client_id: "${input.client_id}"
      }

    - update_pattern_library: {
        client_id: "${input.client_id}",
        new_pattern: "${decision_analysis}"
      }

    - evaluate_rule_suggestion: {
        patterns: "${updated_patterns}",
        confidence_threshold: 0.85,
        client_preferences: "${client_doa.learning_preferences}"
      }

    - condition:
        if: "${rule_suggestion.ready}"
        then:
          - suggest_new_rule: {
              to_client: "${input.client_id}",
              suggested_rule: "${rule_suggestion}",
              evidence: "${supporting_patterns}"
            }
