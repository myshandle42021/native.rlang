# r/examples/test-log-agent.r
self:
  id: "test-log-agent"
  intent: "Test condition and logging"
  version: "0.1.1"

operations:
  run_test:
    - condition:
        if: context.agentId.startsWith("test-")
        then:
          - tamr.log:
              event: "test_log_event"
              message: "Condition matched and log written"
          - respond: "✅ Condition passed and log written"
        else:
          - respond: "❌ Condition failed, no log written"
