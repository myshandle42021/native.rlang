# r/templates/basic_agent.r - Basic Agent Template
self:
  template: "basic_agent"
  intent: "Basic agent functionality"

operations:
  initialize:
    - tamr.log: { event: "agent_initialized", agent: "${self.id}" }
    - respond: "✅ Agent ${self.id} initialized"

  default:
    - respond: "Hello! I am ${self.id}"
