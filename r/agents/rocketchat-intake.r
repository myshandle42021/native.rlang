# r/agents/rocketchat-intake.r
# Natural language interface for ROL3 system - Primary user interaction point

self:
  id: "rocketchat-intake"
  intent: "Process RocketChat messages, route requests, and enable natural language agent creation"
  version: "2.0.0"
  template: "chat_interface"

aam:
  require_role: "user"
  allow_actions: ["process_message", "create_agent", "provide_feedback", "query_system"]

dependencies:
  services: ["rocketchat"]
  agents: ["agent-factory", "ordr-agent", "system-doctor", "learning-engine"]

# RCD Meta-tagging for chat intelligence
rcd:
  meta_tags:
    system_role: ["user_interface", "message_processor", "feedback_collector", "demo_interface"]
    capabilities: [
      "natural_language_processing", "intent_extraction", "agent_creation_routing",
      "user_feedback_processing", "system_status_queries", "credential_collection",
      "real_time_updates", "multi_turn_conversations", "learning_integration"
    ]
    data_flow_type: ["input_processor", "intent_router", "response_generator"]
    stability_level: "critical"
    learning_focus: ["intent_accuracy", "user_satisfaction", "conversation_quality"]
    complexity_score: 4

  relationships:
    receives_from: ["users", "rocketchat_webhooks"]
    reports_to: ["users", "system_admin"]
    collaborates_with: ["agent-factory", "ordr-agent", "learning-engine"]
    manages: ["user_conversations", "agent_creation_flows", "feedback_processing"]
    triggers: ["agent_creation", "system_queries", "learning_updates"]

  conversation_intelligence:
    intent_classification:
      track_metrics: ["classification_accuracy", "ambiguity_resolution", "context_retention"]
      optimization_target: "improve_intent_understanding"

    user_satisfaction:
      track_metrics: ["response_relevance", "task_completion", "user_corrections"]
      optimization_target: "maximize_user_satisfaction"

    learning_effectiveness:
      track_metrics: ["feedback_integration", "improvement_rate", "pattern_recognition"]
      optimization_target: "continuous_improvement"

operations:
  initialize:
    - tamr.log: { event: "rocketchat_intake_started", timestamp: "${timestamp}" }
    - setup_service_configuration: {}
    - initialize_conversation_memory: {}
    - start_webhook_listener: {}
    # RCD Registration
    - rcd_register_chat_agent: {}
    - rcd_initialize_conversation_tracking: {}
    - respond: "💬 RocketChat Intake Agent initialized - Ready for natural language interactions"

  # Primary message processing entry point
  message_handler:
    - rcd_start_performance_tracking: { operation: "message_handler" }

    # Extract comprehensive message context
    - extract_message_context: {
        message: "${input}",
        include_history: true,
        conversation_window: "10m"
      }

    # Enrich context with user profile and preferences
    - rcd_enrich_user_context: {
        user_id: "${message_context.user_id}",
        message_history: "${message_context.history}",
        preferences: "${user_preferences}"
      }

    # Enhanced natural language intent extraction using intent-detector
    - run:
        - "r/system/intent-detector.r"
        - "analyze_user_request"
        - {
            text: "${extract_message_context.text}",
            context: {
              conversation_type: "agent_creation_and_system_interaction",
              user_profile: "${enriched_context.user_profile}",
              system_context: "ROL3_autonomous_agent_system",
              available_capabilities: [
                "agent_creation", "system_monitoring", "api_integration",
                "data_processing", "workflow_automation", "learning_feedback"
              ],
              user_id: "${message_context.user_id}"
            }
          }

    # Validate and enhance intent classification
    - rcd_validate_intent_classification: {
        intent: "${run_result}",
        message_context: "${enriched_context}",
        confidence_threshold: 0.7
      }

    # Route based on classified intent
    - condition:
        switch: "${validated_intent.action || run_result.action}"
        cases:
          # Agent creation flow - The main demo path
          - create_agent:
              - run:
                  - "rocketchat-intake.r"
                  - "handle_agent_creation"
                  - {
                      intent: "${validated_intent}",
                      user_context: "${enriched_context}",
                      message: "${message_context}"
                    }

          # System status and monitoring
          - system_status:
              - run:
                  - "rocketchat-intake.r"
                  - "handle_system_query"
                  - {
                      query_type: "${validated_intent.query_type}",
                      user_context: "${enriched_context}"
                    }

          # User feedback and corrections - Critical for learning
          - feedback_correction:
              - run:
                  - "rocketchat-intake.r"
                  - "process_user_feedback"
                  - {
                      feedback: "${validated_intent.correction}",
                      context: "${enriched_context}",
                      correction_type: "${validated_intent.feedback_type}"
                    }

          # Agent management (start, stop, modify)
          - agent_management:
              - run:
                  - "rocketchat-intake.r"
                  - "handle_agent_management"
                  - {
                      action: "${validated_intent.management_action}",
                      agent_id: "${validated_intent.target_agent}",
                      parameters: "${validated_intent.parameters}"
                    }

          # General conversation and help
          - general_conversation:
              - run:
                  - "rocketchat-intake.r"
                  - "handle_general_conversation"
                  - {
                      intent: "${validated_intent}",
                      context: "${enriched_context}"
                    }

          # Clarification needed
          - clarification_needed:
              - run:
                  - "rocketchat-intake.r"
                  - "request_clarification"
                  - {
                      ambiguity: "${validated_intent.ambiguity}",
                      suggestions: "${validated_intent.suggestions}"
                    }

    # Log conversation for learning and improvement
    - rcd_log_conversation_interaction: {
        user_id: "${enriched_context.user_id}",
        intent: "${validated_intent}",
        response: "${interaction_response}",
        satisfaction_indicators: "${response_quality_metrics}"
      }

    - rcd_complete_performance_tracking: { operation: "message_handler", success: true }

  # Core agent creation workflow - The star of the demo
  handle_agent_creation:
    - rcd_start_performance_tracking: { operation: "handle_agent_creation" }

    # Send immediate acknowledgment with real-time updates
    - rocketchat.sendMessage: {
        channel: "${input.user_context.channel}",
        text: "🤖 Creating your ${input.intent.agent_type} agent... I'll keep you updated in real-time!",
        attachments: [{
          color: "good",
          text: "Analyzing requirements...",
          fields: [
            { title: "Agent Type", value: "${input.intent.agent_type}", short: true },
            { title: "Purpose", value: "${input.intent.purpose}", short: true }
          ]
        }]
      }

    # Real-time update: Template selection
    - update_creation_progress: {
        stage: "template_selection",
        message: "🔍 Selecting optimal template for ${input.intent.agent_type}..."
      }

    # Call the enhanced agent factory
    - run:
        - "r/system/agent-factory.r"
        - "create_intelligent_agent"
        - {
            request: "${input.intent.detailed_description}",
            context: {
              user_id: "${input.user_context.user_id}",
              channel: "${input.user_context.channel}",
              client_id: "${input.user_context.client_id}",
              real_time_updates: true,
              update_channel: "${input.user_context.channel}"
            },
            enhancement_level: "${input.intent.complexity || 'standard'}"
          }

    # Handle agent creation result
    - condition:
        if: "${agent_creation_result.success}"
        then:
          # Success flow
          - update_creation_progress: {
              stage: "creation_complete",
              message: "✅ Agent '${agent_creation_result.agent_id}' created successfully!"
            }

          # Detect if external service integration is needed
          - detect_service_integrations: {
              agent_config: "${agent_creation_result.agent_config}",
              user_intent: "${input.intent}"
            }

          - condition:
              if: "${service_integrations.length > 0}"
              then:
                - run:
                    - "rocketchat-intake.r"
                    - "handle_service_integration"
                    - {
                        agent_id: "${agent_creation_result.agent_id}",
                        required_services: "${service_integrations}",
                        user_context: "${input.user_context}"
                      }
              else:
                # Agent is ready to use immediately
                - rocketchat.sendMessage: {
                    channel: "${input.user_context.channel}",
                    text: "🎉 Your agent is ready! Type 'test my agent' to see it in action.",
                    attachments: [{
                      color: "good",
                      title: "Agent: ${agent_creation_result.agent_id}",
                      text: "${agent_creation_result.agent_description}",
                      actions: [
                        { type: "button", text: "Test Agent", value: "test_agent:${agent_creation_result.agent_id}" },
                        { type: "button", text: "View Details", value: "agent_details:${agent_creation_result.agent_id}" },
                        { type: "button", text: "Modify Agent", value: "modify_agent:${agent_creation_result.agent_id}" }
                      ]
                    }]
                  }
        else:
          # Creation failed
          - update_creation_progress: {
              stage: "creation_failed",
              message: "❌ Agent creation failed: ${agent_creation_result.error}"
            }
          - rocketchat.promptUser: {
              to: "${input.user_context.user_id}",
              message: "I encountered an issue creating your agent. Would you like me to try a different approach?",
              buttons: ["Try Again", "Simplify Requirements", "Get Help"]
            }

    - rcd_complete_performance_tracking: { operation: "handle_agent_creation", success: "${agent_creation_result.success}" }

  # Service integration flow - Critical for demo
  handle_service_integration:
    - rcd_start_performance_tracking: { operation: "handle_service_integration" }

    - loop:
        forEach: "${input.required_services}"
        do:
          # Auto-generate service module if needed
          - check_service_module_exists: { service: "${item.service_name}" }
          - condition:
              if: "!${service_module_exists}"
              then:
                - update_integration_progress: {
                    service: "${item.service_name}",
                    stage: "generating_integration",
                    message: "🔧 Auto-generating ${item.service_name} integration module..."
                  }
                - auto_generate_service_integration: {
                    service: "${item.service_name}",
                    requirements: "${item.requirements}",
                    user_intent: "${original_intent}"
                  }

          # Request credentials from user
          - rocketchat.promptUser: {
              to: "${input.user_context.user_id}",
              message: "🔐 I need to connect to ${item.service_name} to make your agent work. Please provide your API credentials:",
              attachments: [{
                color: "warning",
                title: "${item.service_name} Integration",
                text: "Your credentials are stored securely and only used by your agent.",
                fields: [
                  { title: "Required", value: "${item.credential_requirements}", short: false },
                  { title: "Help", value: "Need help finding your credentials? Click the guide below.", short: false }
                ],
                actions: [
                  { type: "button", text: "Enter Credentials", value: "enter_credentials:${item.service_name}" },
                  { type: "button", text: "Credential Guide", value: "credential_guide:${item.service_name}" },
                  { type: "button", text: "Skip for Now", value: "skip_credentials:${item.service_name}" }
                ]
              }]
            }

          # Wait for credential input (this would be handled by button response)
          - await_credential_input: {
              service: "${item.service_name}",
              user_id: "${input.user_context.user_id}",
              timeout: "300s"
            }

          # Test the connection
          - condition:
              if: "${credentials_provided}"
              then:
                - update_integration_progress: {
                    service: "${item.service_name}",
                    stage: "testing_connection",
                    message: "🔌 Testing ${item.service_name} connection..."
                  }
                - test_service_connection: {
                    service: "${item.service_name}",
                    credentials: "${provided_credentials}",
                    agent_id: "${input.agent_id}"
                  }
                - condition:
                    if: "${connection_test.success}"
                    then:
                      - rocketchat.sendMessage: {
                          channel: "${input.user_context.channel}",
                          text: "✅ ${item.service_name} connected successfully! Testing with live data...",
                          attachments: [{
                            color: "good",
                            text: "Connection established and verified."
                          }]
                        }
                      # Demonstrate with live data
                      - run:
                          - "${input.agent_id}.r"
                          - "test_integration"
                          - {
                              service: "${item.service_name}",
                              demo_mode: true
                            }
                      - display_live_data_sample: {
                          agent_id: "${input.agent_id}",
                          service: "${item.service_name}",
                          data: "${integration_test_result}"
                        }
                    else:
                      - rocketchat.sendMessage: {
                          channel: "${input.user_context.channel}",
                          text: "❌ Connection to ${item.service_name} failed: ${connection_test.error}",
                          attachments: [{
                            color: "danger",
                            text: "Please check your credentials and try again.",
                            actions: [
                              { type: "button", text: "Retry", value: "retry_credentials:${item.service_name}" },
                              { type: "button", text: "Get Help", value: "credential_help:${item.service_name}" }
                            ]
                          }]
                        }

    - rcd_complete_performance_tracking: { operation: "handle_service_integration", success: true }

  # User feedback processing - Critical for learning integration
  process_user_feedback:
    - rcd_start_performance_tracking: { operation: "process_user_feedback" }

    # Classify the type of feedback received
    - classify_feedback_type: {
        feedback: "${input.feedback}",
        context: "${input.context}",
        conversation_history: "${input.context.conversation_history}"
      }

    - condition:
        switch: "${feedback_classification.type}"
        cases:
          # User correcting a wrong response
          - correction:
              - rocketchat.sendMessage: {
                  channel: "${input.context.channel}",
                  text: "💡 Thank you for the correction! I'm learning from this...",
                  attachments: [{
                    color: "warning",
                    title: "Learning from your feedback",
                    text: "I'll remember this for future interactions."
                  }]
                }
              - process_correction_feedback: {
                  original_response: "${input.context.previous_response}",
                  corrected_response: "${input.feedback.correct_answer}",
                  correction_context: "${input.context}",
                  user_id: "${input.context.user_id}"
                }
              # Trigger learning engine update
              - run:
                  - "r/system/learning-engine.r"
                  - "process_user_correction"
                  - {
                      agent_id: "${responsible_agent}",
                      original_context: "${input.context.original_context}",
                      user_correction: "${input.feedback}",
                      learning_priority: "high"
                    }
              # Confirm learning
              - rocketchat.sendMessage: {
                  channel: "${input.context.channel}",
                  text: "✅ Learning complete! I've updated my understanding and will do better next time."
                }

          # User confirming a good response
          - confirmation:
              - rocketchat.sendMessage: {
                  channel: "${input.context.channel}",
                  text: "😊 Great! I'm glad that was helpful.",
                  attachments: [{
                    color: "good",
                    text: "This positive feedback helps me improve!"
                  }]
                }
              - log_positive_feedback: {
                  response: "${input.context.confirmed_response}",
                  user_satisfaction: "positive",
                  context: "${input.context}"
                }
              # Reinforce successful patterns
              - run:
                  - "r/system/learning-engine.r"
                  - "reinforce_success_pattern"
                  - {
                      agent_id: "${responsible_agent}",
                      successful_interaction: "${input.context}",
                      user_satisfaction: "high"
                    }

          # User requesting clarification
          - clarification_request:
              - rocketchat.sendMessage: {
                  channel: "${input.context.channel}",
                  text: "🤔 Let me clarify that for you...",
                  attachments: [{
                    color: "good",
                    title: "Clarification",
                    text: "${generate_clarification(input.feedback.question)}"
                  }]
                }
              - handle_clarification_request: {
                  question: "${input.feedback.question}",
                  original_context: "${input.context}"
                }

          # User expressing dissatisfaction
          - complaint:
              - rocketchat.sendMessage: {
                  channel: "${input.context.channel}",
                  text: "😔 I apologize that wasn't what you expected. Let me try to do better...",
                  attachments: [{
                    color: "danger",
                    text: "Would you like me to try a different approach?",
                    actions: [
                      { type: "button", text: "Try Again", value: "retry_request" },
                      { type: "button", text: "Explain What You Want", value: "clarify_request" },
                      { type: "button", text: "Get Human Help", value: "escalate_to_human" }
                    ]
                  }]
                }
              - log_negative_feedback: {
                  issue: "${input.feedback.complaint}",
                  context: "${input.context}",
                  severity: "${feedback_classification.severity}"
                }

    # Always log feedback for system learning
    - rcd_log_feedback_interaction: {
        feedback_type: "${feedback_classification.type}",
        user_id: "${input.context.user_id}",
        agent_involved: "${responsible_agent}",
        learning_signal: "${feedback_classification.learning_value}"
      }

    - rcd_complete_performance_tracking: { operation: "process_user_feedback", success: true }

  # System status and queries
  handle_system_query:
    - rcd_start_performance_tracking: { operation: "handle_system_query" }

    - condition:
        switch: "${input.query_type}"
        cases:
          - system_health:
              - run: ["r/agents/system-doctor.r", "generate_status_summary"]
              - rocketchat.sendMessage: {
                  channel: "${input.user_context.channel}",
                  text: "🏥 System Health Report",
                  attachments: [{
                    color: "${status_summary.overall_health == 'healthy' ? 'good' : 'warning'}",
                    title: "ROL3 System Status",
                    text: "${status_summary.summary}",
                    fields: [
                      { title: "Active Agents", value: "${status_summary.active_agents}", short: true },
                      { title: "System Load", value: "${status_summary.system_load}", short: true },
                      { title: "Recent Issues", value: "${status_summary.recent_issues}", short: true },
                      { title: "Uptime", value: "${status_summary.uptime}", short: true }
                    ]
                  }]
                }

          - agent_list:
              - query_user_agents: { user_id: "${input.user_context.user_id}" }
              - format_agent_list: { agents: "${user_agents}" }
              - rocketchat.sendMessage: {
                  channel: "${input.user_context.channel}",
                  text: "🤖 Your Agents",
                  attachments: "${formatted_agent_list}"
                }

          - performance_metrics:
              - gather_performance_metrics: { user_id: "${input.user_context.user_id}" }
              - rocketchat.sendMessage: {
                  channel: "${input.user_context.channel}",
                  text: "📊 Performance Metrics",
                  attachments: [{
                    color: "good",
                    title: "System Performance",
                    fields: "${performance_metrics.formatted_fields}"
                  }]
                }

    - rcd_complete_performance_tracking: { operation: "handle_system_query", success: true }

  # General conversation handling
  handle_general_conversation:
    - rcd_start_performance_tracking: { operation: "handle_general_conversation" }

    # Use LLM to generate appropriate response
    - infer.generateResponse: {
        user_message: "${input.intent.message}",
        context: {
          system_role: "ROL3 autonomous agent assistant",
          capabilities: "${system_capabilities}",
          user_profile: "${input.context.user_profile}",
          conversation_tone: "helpful_and_technical"
        }
      }

    - rocketchat.sendMessage: {
        channel: "${input.context.channel}",
        text: "${generated_response.message}",
        attachments: "${generated_response.suggested_actions ? [{
          color: 'good',
          title: 'What would you like to do?',
          actions: generated_response.suggested_actions
        }] : []}"
      }

    - rcd_complete_performance_tracking: { operation: "handle_general_conversation", success: true }

  # Real-time progress updates during agent creation
  update_creation_progress:
    - rocketchat.sendMessage: {
        channel: "${current_channel}",
        text: "${input.message}",
        attachments: [{
          color: "good",
          title: "Agent Creation Progress",
          text: "Stage: ${input.stage}",
          ts: "${timestamp}"
        }]
      }

  # Button response handler for interactive elements
  button_response_handler:
    - extract_button_context: { button_value: "${input.button}" }
    - condition:
        switch: "${button_context.action}"
        cases:
          - test_agent:
              - run:
                  - "${button_context.agent_id}.r"
                  - "request_handler"
                  - {
                      type: "demo_test",
                      user_id: "${input.user_id}",
                      channel: "${input.channel}"
                    }
          - enter_credentials:
              - initiate_credential_collection: {
                  service: "${button_context.service}",
                  user_id: "${input.user_id}"
                }
          - retry_request:
              - retry_last_request: { user_id: "${input.user_id}" }

  # Service configuration setup
  setup_service_configuration:
    - config.get: { key: "ROCKETCHAT_CONFIG" }
    - condition:
        if: "!${config_value}"
        then:
          - config.set:
              key: "ROCKETCHAT_CONFIG"
              value: {
                "service": "rocketchat",
                "auth_type": "bearer",
                "base_url": "${process.env.ROCKETCHAT_URL || 'https://your-rocketchat.com'}",
                "endpoints": {
                  "send_message": "/api/v1/chat.postMessage",
                  "get_messages": "/api/v1/channels.messages",
                  "create_webhook": "/api/v1/integrations.create",
                  "prompt_user": "/api/v1/chat.postMessage",
                  "upload_file": "/api/v1/rooms.upload"
                },
                "credentials": {
                  "token": "${process.env.ROCKETCHAT_TOKEN}",
                  "user_id": "${process.env.ROCKETCHAT_USER_ID}"
                },
                "aliases": {
                  "sendMessage": "sendMessage",
                  "promptUser": "sendMessage"
                }
              }
    # Store configuration for auto-generation
    - rcd.write:
        table: "api_connections"
        data: {
          service: "rocketchat",
          client_id: "system",
          auth_type: "bearer",
          base_url: "${config_value.base_url}",
          endpoints: "${config_value.endpoints}",
          credentials: "${config_value.credentials}",
          active: true
        }

  # Missing internal operations
  extract_message_context:
    - return: {
        text: "${input.message.msg || input.message.text || input.message}",
        user_id: "${input.message.u._id || input.message.user_id || input.user_id}",
        channel: "${input.message.rid || input.message.channel_id || input.channel}",
        message_id: "${input.message._id || input.message.message_id}",
        username: "${input.message.u.username || input.message.username}",
        timestamp: "${input.message.ts || input.message.timestamp}",
        history: [],
        valid: true
      }

  initialize_conversation_memory:
    - tamr.log: { event: "conversation_memory_initialized" }
    - return: { initialized: true }

  start_webhook_listener:
    - tamr.log: { event: "webhook_listener_started" }
    - return: { listening: true }

  validate_webhook_payload:
    - return: {
        valid: true,
        message: "${input.payload}"
      }

  extract_message_from_webhook:
    - return: {
        valid: true,
        text: "${input.webhook_data.msg}",
        user_id: "${input.webhook_data.u._id}",
        channel: "${input.webhook_data.rid}"
      }

  webhook_message_handler:
    - validate_webhook_payload: { payload: "${input}" }
    - extract_message_from_webhook: { webhook_data: "${input}" }
    - condition:
        if: "${extract_message_from_webhook.valid}"
        then:
          - run:
              - "rocketchat-intake.r"
              - "message_handler"
              - "${extract_message_from_webhook}"
        else:
          - tamr.log: { event: "invalid_webhook_payload", payload: "${input}" }

  # RCD Integration Operations
  rcd_register_chat_agent:
    - rcd.register_agent: {
        agent_id: "${self.id}",
        capabilities: "${rcd.meta_tags.capabilities}",
        relationships: "${rcd.relationships}",
        conversation_intelligence: "${rcd.conversation_intelligence}",
        performance_baseline: {
          "response_time_ms": 2000,
          "intent_accuracy": 0.85,
          "user_satisfaction": 0.8,
          "conversation_completion_rate": 0.9
        }
      }

  rcd_initialize_conversation_tracking:
    - rcd.initialize_conversation_system: {
        agent_id: "${self.id}",
        tracking_capabilities: ["intent_analysis", "user_satisfaction", "learning_feedback"],
        conversation_memory: "persistent"
      }

  rcd_start_performance_tracking:
    - tamr.remember: { key: "operation_start_time", value: "${timestamp}" }
    - tamr.remember: { key: "current_operation", value: "${input.operation}" }

  rcd_complete_performance_tracking:
    - calculate_operation_performance: {
        operation: "${input.operation}",
        start_time: "${memory.operation_start_time}",
        end_time: "${timestamp}",
        success: "${input.success}"
      }
    - rcd.log_performance: {
        agent_id: "${self.id}",
        operation: "${input.operation}",
        metrics: "${operation_performance}",
        success: "${input.success}"
      }

  rcd_enrich_user_context:
    - rcd.get_user_profile: {
        user_id: "${input.user_id}",
        include_preferences: true,
        include_history: true
      }
    - enhance_context_with_patterns: {
        base_context: "${input}",
        user_profile: "${user_profile}",
        conversation_patterns: "${user_conversation_patterns}"
      }
    - return: "${enhanced_context}"

  rcd_validate_intent_classification:
    - rcd.check_intent_confidence: {
        intent: "${input.intent}",
        confidence_threshold: "${input.confidence_threshold}",
        context_validation: true
      }
    - condition:
        if: "${intent_confidence.score < input.confidence_threshold}"
        then:
          - enhance_intent_with_context: {
              low_confidence_intent: "${input.intent}",
              message_context: "${input.message_context}"
            }
    - return: "${validated_intent}"

  rcd_log_conversation_interaction:
    - rcd.log_conversation: {
        user_id: "${input.user_id}",
        intent: "${input.intent}",
        response: "${input.response}",
        satisfaction_score: "${input.satisfaction_indicators.score}",
        learning_value: "${conversation_learning_value}"
      }

  rcd_log_feedback_interaction:
    - rcd.log_feedback: {
        feedback_type: "${input.feedback_type}",
        user_id: "${input.user_id}",
        agent_id: "${input.agent_involved}",
        learning_signal: "${input.learning_signal}",
        context: "${feedback_context}"
      }

# Webhook configuration for incoming messages
incoming:
  webhook:
    path: "/webhooks/rocketchat"
    method: "POST"
    operation: "webhook_message_handler"

concern:
  if: "${user_satisfaction_score < 0.7 || intent_accuracy < 0.8}"
  priority: 2
  action:
    - tamr.log: { event: "chat_interface_performance_concern", metrics: "${performance_metrics}" }
    - run:
        - "r/system/learning-engine.r"
        - "analyze_chat_performance"
        - {
            agent_id: "${self.id}",
            focus_areas: ["intent_classification", "user_satisfaction"],
            improvement_priority: "high"
          }
    - condition:
        if: "${performance_concern_critical}"
        then:
          - prompt.user:
              to: "system_admin"
              message: "💬 RocketChat interface performance degraded. User satisfaction: ${user_satisfaction_score}"
              buttons: ["Review Conversations", "Retrain Models", "Manual Review"]

# Configuration for auto-generation
service_auto_generation:
  trigger_patterns: ["rocketchat.sendMessage", "rocketchat.promptUser", "rocketchat.uploadFile"]
  template_source: "service-template.ts"
  generation_config: {
    "service_name": "rocketchat",
    "config_key": "ROCKETCHAT_CONFIG",
    "required_functions": ["sendMessage", "promptUser", "getMessages", "uploadFile"],
    "auth_pattern": "bearer_token"
  }
