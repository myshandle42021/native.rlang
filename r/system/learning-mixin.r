# r/templates/learning-mixin.r
# Universal Learning Behavior - Inherit this to make any agent learning-enabled

# 🧠 LEARNING MIXIN - Add intelligence to any agent
# Usage: Include this in your agent with: `include: "r/templates/learning-mixin.r"`

learning_config:
  enabled: true
  immediate_learning: true     # Learn from each operation
  batch_learning: true        # Participate in learning cycles
  knowledge_sharing: true     # Share/receive patterns from other agents
  self_optimization: true     # Allow auto-optimization
  feedback_learning: true     # Learn from user corrections
  performance_tracking: true  # Track operation performance

learning_hooks:
  # Automatically called after each operation
  after_operation:
    - condition:
        if: "${learning_config.immediate_learning}"
        then:
          - capture_execution_metrics: {
              operation: "${completed_operation}",
              result: "${operation_result}",
              context: "${operation_context}",
              performance: {
                duration_ms: "${execution_time}",
                memory_mb: "${memory_usage}",
                success: "${operation_result.success}"
              }
            }
          - run: ["r/system/learning-engine.r", "analyze_agent_execution", {
              agent_id: "${self.id}",
              operation: "${completed_operation}",
              context: "${operation_context}",
              result: "${operation_result}",
              performance_metrics: "${execution_metrics}",
              input_hash: "${input_hash}"
            }]

  # Called when operation fails
  on_failure:
    - condition:
        if: "${learning_config.immediate_learning}"
        then:
          - analyze_failure_immediately: {
              operation: "${failed_operation}",
              error: "${failure_error}",
              context: "${failure_context}"
            }
          # Trigger emergency learning for critical failures
          - condition:
              if: "${failure_severity == 'critical'}"
              then:
                - run: ["r/system/learning-engine.r", "emergency_learning", {
                    agent_id: "${self.id}",
                    failure_context: "${failure_context}",
                    priority: "high"
                  }]

  # Called when user provides feedback
  on_user_feedback:
    - condition:
        if: "${learning_config.feedback_learning}"
        then:
          - process_user_feedback: {
              feedback: "${user_feedback}",
              operation_context: "${original_context}",
              agent_response: "${agent_response}"
            }
          - update_behavior_patterns: {
              feedback_type: "${feedback.type}",
              correction: "${feedback.correction}",
              context: "${operation_context}"
            }

learning_operations:
  # Initialize learning capabilities for this agent
  initialize_learning:
    - tamr.log: {
        event: "learning_enabled",
        agent_id: "${self.id}",
        capabilities: "${learning_config}"
      }
    - register_with_learning_engine: { agent_id: "${self.id}" }
    - load_applicable_patterns: { agent_id: "${self.id}" }
    - respond: "🧠 Learning capabilities activated for ${self.id}"

  # Capture detailed metrics for each operation
  capture_execution_metrics:
    - calculate_input_hash: { input: "${input.context.input}" }
    - measure_performance: {
        start_time: "${input.context.start_time}",
        end_time: "${timestamp}",
        memory_before: "${input.context.memory_before}",
        memory_after: "${current_memory_usage}"
      }
    - extract_context_features: {
        input_type: "${input.context.input_type}",
        user: "${input.context.user}",
        channel: "${input.context.channel}",
        time_of_day: "${timestamp.hour}",
        system_load: "${current_system_load}"
      }
    - return: {
        input_hash: "${calculated_hash}",
        duration_ms: "${performance.duration}",
        memory_mb: "${performance.memory_delta}",
        success: "${input.result.success}",
        error_type: "${input.result.error_type}",
        context_features: "${extracted_features}"
      }

  # Immediate failure analysis
  analyze_failure_immediately:
    - classify_failure: {
        error: "${input.error}",
        operation: "${input.operation}",
        context: "${input.context}"
      }
    - extract_failure_patterns: {
        classification: "${failure_classification}",
        recent_context: "${input.context}",
        error_details: "${input.error}"
      }
    - check_known_solutions: {
        failure_pattern: "${extracted_patterns}",
        agent_id: "${self.id}"
      }
    - condition:
        if: "${known_solutions.found}"
        then:
          - tamr.log: {
              event: "known_solution_available",
              failure_type: "${failure_classification}",
              solution: "${known_solutions.solution}"
            }
          - suggest_immediate_fix: { solution: "${known_solutions.solution}" }

  # Process user feedback and corrections
  process_user_feedback:
    - classify_feedback: {
        feedback: "${input.feedback}",
        types: ["correction", "improvement", "preference", "error_report"]
      }
    - condition:
        switch: "${feedback_classification.type}"
        cases:
          - correction:
              - learn_from_correction: {
                  original_response: "${input.agent_response}",
                  correct_response: "${input.feedback.correction}",
                  context: "${input.operation_context}"
                }
              - update_response_patterns: {
                  context_pattern: "${context_hash}",
                  correct_pattern: "${correction_pattern}"
                }

          - improvement:
              - analyze_improvement_suggestion: {
                  suggestion: "${input.feedback.improvement}",
                  current_behavior: "${agent_current_behavior}"
                }
              - queue_for_optimization: {
                  improvement: "${improvement_analysis}",
                  priority: "medium"
                }

          - preference:
              - store_user_preference: {
                  user: "${input.operation_context.user}",
                  preference: "${input.feedback.preference}",
                  context: "${preference_context}"
                }

          - error_report:
              - investigate_reported_error: {
                  error_report: "${input.feedback.error}",
                  operation_context: "${input.operation_context}"
                }

  # Load and apply patterns discovered by learning engine
  load_applicable_patterns:
    - run: ["r/system/learning-engine.r", "get_learning_insights", {
        agent_id: "${input.agent_id}"
      }]
    - filter_relevant_patterns: {
        insights: "${learning_insights}",
        agent_capabilities: "${self_capabilities}",
        confidence_threshold: 0.7
      }
    - apply_learned_patterns: {
        patterns: "${relevant_patterns}",
        integration_mode: "gradual"
      }
    - tamr.log: {
        event: "patterns_loaded",
        agent_id: "${input.agent_id}",
        patterns_count: "${relevant_patterns.length}"
      }

  # Self-optimization workflow
  request_self_optimization:
    - condition:
        if: "${learning_config.self_optimization}"
        then:
          - analyze_current_performance: { window: "7d" }
          - identify_optimization_opportunities: {
              performance_data: "${performance_analysis}",
              target_improvements: ["speed", "accuracy", "resource_usage"]
            }
          - condition:
              if: "${optimization_opportunities.length > 0}"
              then:
                - request_optimization_from_learning_engine: {
                    agent_id: "${self.id}",
                    opportunities: "${optimization_opportunities}",
                    current_performance: "${performance_analysis}"
                  }
        else:
          - tamr.log: {
              event: "self_optimization_disabled",
              agent_id: "${self.id}"
            }

  # Share successful patterns with other agents
  share_knowledge:
    - condition:
        if: "${learning_config.knowledge_sharing}"
        then:
          - extract_shareable_patterns: {
              agent_id: "${self.id}",
              success_threshold: 0.8,
              recency: "30d"
            }
          - identify_similar_agents: {
              criteria: ["similar_operations", "shared_services", "comparable_context"]
            }
          - register_patterns_for_sharing: {
              patterns: "${shareable_patterns}",
              source_agent: "${self.id}",
              target_agents: "${similar_agents}"
            }

  # Receive and integrate knowledge from other agents
  receive_knowledge:
    - validate_incoming_knowledge: {
        knowledge: "${input.knowledge}",
        source_agent: "${input.source_agent}",
        compatibility_check: true
      }
    - condition:
        if: "${validation.compatible && validation.beneficial}"
        then:
          - integrate_external_knowledge: {
              knowledge: "${input.knowledge}",
              integration_strategy: "cautious",
              rollback_plan: true
            }
          - test_knowledge_integration: {
              test_scenarios: "${knowledge_test_cases}",
              baseline_comparison: true
            }
          - condition:
              if: "${integration_test.improvement > 0.05}"
              then:
                - commit_knowledge_integration: { integration_id: "${integration.id}" }
                - tamr.log: {
                    event: "knowledge_received",
                    from_agent: "${input.source_agent}",
                    improvement: "${integration_test.improvement}"
                  }
              else:
                - rollback_knowledge_integration: { integration_id: "${integration.id}" }

  # Performance tracking and reporting
  track_performance:
    - condition:
        if: "${learning_config.performance_tracking}"
        then:
          - calculate_performance_metrics: {
              window: "${input.window || '24h'}",
              metrics: ["success_rate", "avg_response_time", "error_rate", "user_satisfaction"]
            }
          - compare_with_baseline: {
              current_metrics: "${performance_metrics}",
              baseline_period: "30d"
            }
          - detect_performance_trends: {
              metrics_history: "${historical_metrics}",
              trend_analysis: "regression"
            }
          - return: {
              current_performance: "${performance_metrics}",
              baseline_comparison: "${baseline_comparison}",
              trends: "${performance_trends}"
            }

  # Learn from operation patterns over time
  analyze_operation_patterns:
    - tamr.query: {
        agent_id: "${self.id}",
        since: "${input.window || '-7d'}",
        limit: 500
      }
    - group_by_operation: { logs: "${query_result}" }
    - analyze_success_patterns: {
        grouped_operations: "${operation_groups}",
        success_criteria: "completion_without_error"
      }
    - identify_failure_correlations: {
        grouped_operations: "${operation_groups}",
        correlation_types: ["time_based", "input_based", "context_based"]
      }
    - extract_behavioral_insights: {
        success_patterns: "${success_analysis}",
        failure_correlations: "${failure_correlations}"
      }
    - return: "${behavioral_insights}"

  # Continuous improvement workflow
  continuous_improvement:
    - schedule_improvement_cycle: { interval: "${input.interval || '24h'}" }
    - loop:
        while: "${improvement_enabled}"
        do:
          - wait: { duration: "${improvement_interval}" }
          - run: ["analyze_operation_patterns"]
          - run: ["track_performance"]
          - condition:
              if: "${performance_declining || error_rate_increasing}"
              then:
                - run: ["request_self_optimization"]
          - condition:
              if: "${performance_excellent && stable}"
              then:
                - run: ["share_knowledge"]

# Helper functions for learning integration
learning_helpers:
  calculate_input_hash:
    - infer.generateHash: {
        data: "${input.input}",
        algorithm: "sha256",
        normalize: true
      }
    - return: "${generated_hash}"

  classify_failure:
    - infer.classifyFailure: {
        error: "${input.error}",
        operation: "${input.operation}",
        context: "${input.context}",
        categories: [
          "input_validation_error",
          "external_service_failure",
          "resource_exhaustion",
          "logic_error",
          "timeout_error",
          "permission_error"
        ]
      }
    - return: "${failure_classification}"

  extract_context_features:
    - return: {
        input_type: "${typeof(input.input_type)}",
        user_id: "${input.user}",
        channel_type: "${input.channel}",
        hour_of_day: "${new Date(input.timestamp).getHours()}",
        day_of_week: "${new Date(input.timestamp).getDay()}",
        system_load: "${input.system_load || 'unknown'}",
        concurrent_operations: "${active_operations_count}"
      }

  measure_performance:
    - return: {
        duration: "${input.end_time - input.start_time}",
        memory_delta: "${input.memory_after - input.memory_before}",
        timestamp: "${input.end_time}"
      }

# Learning state management
learning_state:
  patterns_learned: []
  optimization_history: []
  knowledge_shared: []
  knowledge_received: []
  performance_baseline: {}
  last_learning_cycle: null
  learning_effectiveness: 0.0

# Integration with main agent operations
operation_wrappers:
  # Wrap any operation with learning hooks
  with_learning:
    - tamr.remember: { key: "operation_start_time", value: "${timestamp}" }
    - tamr.remember: { key: "memory_before", value: "${current_memory_usage}" }

    # Execute the wrapped operation
    - "${input.operation}"

    # Post-operation learning
    - run: ["learning_hooks.after_operation", {
        completed_operation: "${input.operation}",
        operation_result: "${operation_result}",
        operation_context: {
          start_time: "${memory.operation_start_time}",
          memory_before: "${memory.memory_before}",
          input: "${input}",
          agent_id: "${self.id}"
        }
      }]

# Automatic learning integration for common patterns
auto_learning_triggers:
  # Trigger learning analysis after N operations
  operation_count_trigger:
    condition: "${completed_operations_count % 10 == 0}"
    action:
      - run: ["analyze_operation_patterns", { window: "1h" }]

  # Trigger optimization after performance degradation
  performance_trigger:
    condition: "${current_success_rate < baseline_success_rate * 0.9}"
    action:
      - run: ["request_self_optimization"]

  # Share knowledge after consistent good performance
  knowledge_sharing_trigger:
    condition: "${success_rate > 0.95 && stable_performance_days > 7}"
    action:
      - run: ["share_knowledge"]
