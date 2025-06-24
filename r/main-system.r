# r/main-system.r
# The digital genome - core system orchestration

self:
  id: "rol3-main-system"
  intent: "Orchestrate multi-client agent ecosystem with self-healing and learning"
  version: "1.0.0"

aam:
  require_role: "system"
  allow_actions: ["genesis", "diagnose", "heal", "spawn_agent"]

operations:
  genesis:
    - tamr.log: { event: "system_startup", timestamp: "${timestamp}" }
    - run: "r/shared/capability-index.r"
    - self.reflect: { on: "system_health", aspect: "initialization" }
    - condition:
        if: "${system_health.status != 'healthy'}"
        then:
          - run: ["r/agents/system-doctor.r", "diagnose"]
    - respond: "🌱 ROL3 System Genesis Complete - All agents ready"

  request_handler:
    - infer.intent: "${request.text}"
    - condition:
        switch: "${intent.category}"
        cases:
          - agent_creation:
              - generateAgent:
                  template: "${intent.agent_type}"
                  config: "${intent.parameters}"
                  client_id: "${request.client_id}"
              - respond: "✅ Agent ${generated_agent.id} created and deployed"

          - natural_query:
              - run: ["r/agents/nlp-router.r", "route_query"]
              - respond: "${query_result}"

          - system_command:
              - condition:
                  if: "${intent.action == 'diagnose'}"
                  then:
                    - run: ["r/agents/system-doctor.r", "full_diagnosis"]
                    - respond: "${diagnosis_summary}"

  spawn_agent:
    - condition:
        if: "${input.client_id}"
        then:
          - generateAgent:
              template: "${input.template}"
              config: "${input.config}"
              output_path: "r/clients/${input.client_id}/agents/${input.agent_id}.r"
        else:
          - generateAgent:
              template: "${input.template}"
              config: "${input.config}"
              output_path: "r/agents/${input.agent_id}.r"

    - tamr.log:
        event: "agent_spawned"
        agent_id: "${input.agent_id}"
        template: "${input.template}"
        client_id: "${input.client_id}"

    - run: ["${generated_agent_path}", "initialize"]

  heal_system:
    - run: ["r/agents/system-doctor.r", "detect_issues"]
    - condition:
        if: "${detected_issues.length > 0}"
        then:
          - loop:
              forEach: "${detected_issues}"
              do:
                - infer.generateFix: { issue: "${item}" }
                - self.modify: {
                    target: "${item.agent_id}",
                    changes: "${generated_fix}"
                  }
                - run: ["${item.agent_id}", "test_fix"]
                - condition:
                    if: "${fix_result.success}"
                    then:
                      - tamr.log: { event: "auto_heal_success", issue: "${item}" }
                    else:
                      - prompt.user:
                          to: "admin"
                          message: "Auto-heal failed for ${item.description}. Manual intervention needed."
                          buttons: ["Investigate", "Rollback", "Ignore"]

concern:
  if: "${error_rate > 0.1 || response_time > 5000}"
  priority: 1
  action:
    - run: ["r/main-system.r", "heal_system"]
