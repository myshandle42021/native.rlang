# r/agents/ordr-agent.r
# Order/Orchestration Agent with RCD integration - Routes and prioritizes all system requests

self:
  id: "ordr-agent"
  intent: "Route requests, prioritize tasks, and orchestrate multi-agent workflows"
  version: "2.0.0"
  template: "orchestration"

aam:
  require_role: "system"
  allow_actions: ["route", "prioritize", "orchestrate", "dispatch"]

dependencies:
  agents: ["system-doctor", "pesr-agent"]
  services: ["intent_analysis", "load_balancing"]

# RCD Meta-tagging for orchestration intelligence
rcd:
  meta_tags:
    system_role: ["request_router", "workflow_orchestrator", "load_balancer"]
    capabilities: [
      "request_routing", "priority_management", "workflow_orchestration",
      "agent_selection", "load_balancing", "performance_optimization",
      "failure_recovery", "parallel_execution", "resource_allocation"
    ]
    data_flow_type: ["request_processor", "decision_coordinator", "execution_manager"]
    stability_level: "critical"
    learning_focus: ["routing_accuracy", "performance_optimization", "workflow_efficiency"]
    complexity_score: 4

  relationships:
    monitors: ["all_agents", "system_load", "request_queues", "performance_metrics"]
    reports_to: ["system_admin"]
    collaborates_with: ["system-doctor", "pesr-agent", "learning-engine"]
    manages: ["request_routing", "agent_workloads", "execution_workflows"]
    receives_from: ["pesr-agent", "system-doctor", "user_agents"]
    dispatches_to: ["all_agents"]

  routing_intelligence:
    agent_capabilities:
      track_metrics: ["success_rate", "response_time", "load_capacity", "specialization_match"]
      optimization_target: "optimal_agent_selection"

    workflow_efficiency:
      track_metrics: ["parallel_execution_rate", "workflow_completion_time", "resource_utilization"]
      optimization_target: "maximize_throughput_minimize_latency"

    load_balancing:
      track_metrics: ["agent_load_distribution", "queue_depth_variation", "bottleneck_frequency"]
      optimization_target: "even_load_distribution"

  learning_patterns:
    routing_accuracy:
      track_metrics: ["correct_agent_selection", "request_satisfaction", "routing_efficiency"]
      optimization_target: "improve_routing_decisions"

    performance_optimization:
      track_metrics: ["system_throughput", "average_response_time", "resource_efficiency"]
      optimization_target: "maximize_system_performance"

    failure_recovery:
      track_metrics: ["failure_detection_time", "recovery_success_rate", "failover_latency"]
      optimization_target: "faster_more_reliable_recovery"

  performance_tracking:
    key_metrics: ["routing_time", "workflow_completion_rate", "agent_utilization", "queue_processing_speed"]
    baseline_performance: {
      "routing_time_ms": 100,
      "workflow_completion_rate": 0.95,
      "agent_utilization": 0.75,
      "queue_processing_speed": 50
    }
    improvement_targets: {
      "routing_time_ms": 50,
      "workflow_completion_rate": 0.98,
      "agent_utilization": 0.85,
      "queue_processing_speed": 100
    }

operations:
  initialize:
    - tamr.log: { event: "ordr_agent_started" }
    - load_routing_rules: {}
    - initialize_priority_queues: {}
    - start_request_processor: {}
    # RCD Registration
    - rcd_register_orchestration_agent: {}
    - rcd_initialize_routing_intelligence: {}
    - rcd_load_agent_capability_map: {}
    - respond: "🎯 ORDR Agent initialized - Request routing and orchestration active with RCD intelligence"

  route_request:
    - rcd_start_performance_tracking: { operation: "route_request" }

    # Main routing entry point for all system requests
    - analyze_request: { request: "${input}" }
    - rcd_enrich_request_analysis: {
        analysis: "${request_analysis}",
        historical_context: "24h"
      }

    - determine_priority: {
        request: "${input}",
        analysis: "${enriched_analysis}"
      }
    - rcd_validate_priority_assignment: {
        priority: "${request_priority}",
        similar_requests: "${historical_similar_requests}"
      }

    - find_target_agents: {
        intent: "${enriched_analysis.intent}",
        requirements: "${enriched_analysis.requirements}"
      }
    - rcd_score_agent_candidates: {
        candidates: "${target_agents}",
        request_context: "${enriched_analysis}",
        current_loads: "${agent_current_loads}"
      }

    - select_optimal_agent: {
        candidates: "${scored_agents}",
        priority: "${validated_priority}",
        load_balance: true
      }
    - rcd_log_routing_decision: {
        selected_agent: "${selected_agent}",
        decision_factors: "${selection_factors}",
        alternatives: "${alternative_agents}"
      }

    - dispatch_to_agent: {
        agent: "${selected_agent}",
        request: "${input}",
        priority: "${validated_priority}",
        tracking_id: "${generate_tracking_id()}"
      }

    - rcd_complete_performance_tracking: { operation: "route_request", success: true }

  route_signal:
    - rcd_start_performance_tracking: { operation: "route_signal" }

    # Specialized routing for PESR signals
    - classify_signal_urgency: { signal: "${input.signal}" }
    - rcd_apply_signal_routing_patterns: {
        signal: "${input.signal}",
        classification: "${input.classification}",
        learned_patterns: "${signal_routing_patterns}"
      }

    - determine_signal_routing: {
        classification: "${input.classification}",
        urgency: "${signal_urgency}",
        priority: "${input.priority}",
        patterns: "${applied_patterns}"
      }

    - condition:
        switch: "${signal_routing.target_type}"
        cases:
          - emergency:
              - rcd_track_emergency_routing: { signal: "${input.signal}" }
              - run: ["r/agents/system-doctor.r", "emergency_repair", "${input.signal}"]
              - notify_admins: { signal: "${input.signal}", action: "emergency_repair" }

          - agent_specific:
              - rcd_track_agent_specific_routing: {
                  signal: "${input.signal}",
                  target_agent: "${signal_routing.target_agent}"
                }
              - dispatch_to_agent: {
                  agent: "${signal_routing.target_agent}",
                  request: {
                    type: "signal_response",
                    signal: "${input.signal}",
                    priority: "high"
                  }
                }

          - workflow:
              - create_signal_workflow: { signal: "${input.signal}" }
              - rcd_track_workflow_creation: {
                  workflow: "${signal_workflow}",
                  trigger_signal: "${input.signal}"
                }
              - run: ["ordr-agent.r", "orchestrate_workflow", "${signal_workflow}"]

          - log_only:
              - rcd_track_signal_logging: {
                  signal: "${input.signal}",
                  reason: "${signal_routing.log_reason}"
                }
              - tamr.log: {
                  event: "signal_logged_only",
                  signal: "${input.signal}",
                  reason: "${signal_routing.log_reason}"
                }

    - rcd_complete_performance_tracking: { operation: "route_signal", success: true }

  orchestrate_workflow:
    - rcd_start_performance_tracking: { operation: "orchestrate_workflow" }

    # Multi-step workflow orchestration with RCD intelligence
    - validate_workflow: { workflow: "${input}" }
    - rcd_optimize_workflow_plan: {
        workflow: "${input}",
        agent_capabilities: "${current_agent_capabilities}",
        load_distribution: "${current_loads}"
      }

    - create_execution_plan: {
        steps: "${optimized_workflow.steps}",
        dependencies: "${optimized_workflow.dependencies}",
        parallel_opportunities: "${optimized_workflow.parallel}"
      }

    - loop:
        forEach: "${execution_plan.phases}"
        do:
          - rcd_track_phase_start: { phase: "${item}" }

          - condition:
              if: "${item.type == 'parallel'}"
              then:
                - execute_parallel_phase: {
                    steps: "${item.steps}",
                    timeout: "${item.timeout || 30000}"
                  }
                - rcd_analyze_parallel_efficiency: {
                    phase: "${item}",
                    results: "${parallel_results}",
                    expected_performance: "${item.performance_target}"
                  }
              else:
                - execute_sequential_phase: {
                    steps: "${item.steps}",
                    continue_on_error: "${item.continue_on_error || false}"
                  }
                - rcd_analyze_sequential_efficiency: {
                    phase: "${item}",
                    results: "${sequential_results}"
                  }

          - validate_phase_completion: {
              phase: "${item}",
              results: "${phase_results}"
            }

          - rcd_track_phase_completion: {
              phase: "${item}",
              validation: "${phase_validation}",
              performance: "${phase_performance}"
            }

          - condition:
              if: "${phase_validation.failed}"
              then:
                - handle_workflow_failure: {
                    failed_phase: "${item}",
                    error: "${phase_validation.error}"
                  }
                - rcd_learn_from_workflow_failure: {
                    workflow: "${input}",
                    failed_phase: "${item}",
                    failure_context: "${failure_context}"
                  }
                - return: {
                    workflow_status: "failed",
                    failed_at: "${item.name}",
                    error: "${phase_validation.error}"
                  }

    - rcd_analyze_workflow_performance: {
        workflow: "${input}",
        execution_plan: "${execution_plan}",
        total_duration: "${workflow_duration}",
        phase_results: "${all_phase_results}"
      }

    - tamr.log: {
        event: "workflow_completed",
        workflow_id: "${input.id}",
        total_phases: "${execution_plan.phases.length}",
        duration_ms: "${workflow_duration}"
      }

    - rcd_complete_performance_tracking: { operation: "orchestrate_workflow", success: true }

  analyze_request:
    - rcd_start_performance_tracking: { operation: "analyze_request" }

    - infer.analyzeRequest:
        request: "${input.request}"
        context: "ROL3 system routing and orchestration"
        extract: [
          "primary_intent",
          "secondary_intents",
          "urgency_level",
          "resource_requirements",
          "expected_agents",
          "complexity_score"
        ]

    - enrich_analysis: {
        base_analysis: "${request_analysis}",
        system_context: {
          current_load: "${system_load}",
          available_agents: "${active_agents}",
          recent_patterns: "${routing_history}"
        }
      }

    - rcd_complete_performance_tracking: { operation: "analyze_request", success: true }
    - return: "${enriched_analysis}"

  determine_priority:
    - rcd_start_performance_tracking: { operation: "determine_priority" }

    - calculate_base_priority: { request: "${input.request}" }
    - rcd_apply_learned_priority_patterns: {
        base_priority: "${base_priority}",
        request_analysis: "${input.analysis}",
        historical_priorities: "${priority_learning_data}"
      }

    - apply_urgency_multiplier: {
        base_priority: "${adjusted_base_priority}",
        urgency: "${input.analysis.urgency_level}"
      }
    - consider_system_load: {
        priority: "${urgency_adjusted_priority}",
        current_load: "${system_metrics.load_average}",
        queue_depth: "${request_queue.depth}"
      }
    - apply_client_priority: {
        priority: "${load_adjusted_priority}",
        client_id: "${input.request.client_id}",
        client_tier: "${client_settings.priority_tier}"
      }

    - rcd_complete_performance_tracking: { operation: "determine_priority", success: true }
    - return: {
        final_priority: "${client_adjusted_priority}",
        priority_factors: {
          base: "${base_priority}",
          learned_adjustment: "${learned_priority_adjustment}",
          urgency: "${urgency_multiplier}",
          load: "${load_factor}",
          client: "${client_factor}"
        }
      }

  find_target_agents:
    - rcd_start_performance_tracking: { operation: "find_target_agents" }

    - query_available_agents: {
        requirements: "${input.requirements}",
        exclude_overloaded: true
      }
    - rcd_enhance_agent_selection: {
        available_agents: "${available_agents}",
        capability_requirements: "${input.requirements}",
        agent_performance_history: "${agent_performance_data}"
      }

    - match_intent_to_capabilities: {
        intent: "${input.intent}",
        available_agents: "${enhanced_agent_list}"
      }
    - score_agent_matches: {
        candidates: "${matched_agents}",
        criteria: ["capability_match", "current_load", "success_rate", "response_time"]
      }
    - filter_by_access_control: {
        agents: "${scored_agents}",
        request_context: "${input.request.aam_context}"
      }

    - rcd_complete_performance_tracking: { operation: "find_target_agents", success: true }
    - return: "${filtered_agents}"

  select_optimal_agent:
    - rcd_start_performance_tracking: { operation: "select_optimal_agent" }

    - condition:
        if: "${input.candidates.length == 0}"
        then:
          - handle_no_available_agents: { request: "${original_request}" }
          - rcd_track_routing_failure: { reason: "no_agents_available" }
          - return: { agent: "fallback-handler", reason: "no_agents_available" }

    - condition:
        if: "${input.candidates.length == 1}"
        then:
          - rcd_track_single_agent_selection: { agent: "${input.candidates[0]}" }
          - return: { agent: "${input.candidates[0].id}", reason: "single_match" }

    - apply_selection_algorithm: {
        candidates: "${input.candidates}",
        algorithm: "${selection_algorithm || 'weighted_round_robin'}",
        load_balance: "${input.load_balance}",
        rcd_insights: "${agent_performance_insights}"
      }

    - rcd_track_selection_decision: {
        selected: "${selected_agent}",
        alternatives: "${input.candidates}",
        algorithm_used: "${selection_algorithm}",
        decision_factors: "${selection_factors}"
      }

    - rcd_complete_performance_tracking: { operation: "select_optimal_agent", success: true }
    - return: {
        agent: "${selected_agent.id}",
        reason: "optimal_selection",
        selection_score: "${selected_agent.final_score}",
        confidence: "${selection_confidence}"
      }

  dispatch_to_agent:
    - rcd_start_performance_tracking: { operation: "dispatch_to_agent" }

    - validate_agent_availability: { agent: "${input.agent}" }
    - create_dispatch_record: {
        tracking_id: "${input.tracking_id}",
        agent: "${input.agent}",
        request: "${input.request}",
        priority: "${input.priority}",
        dispatched_at: "${timestamp}"
      }

    - rcd_track_dispatch_start: {
        tracking_id: "${input.tracking_id}",
        target_agent: "${input.agent}",
        expected_response_time: "${expected_response_time}"
      }

    - run: ["r/agents/${input.agent}.r", "request_handler", "${input.request}"]

    - update_dispatch_record: {
        tracking_id: "${input.tracking_id}",
        status: "completed",
        result: "${agent_result}",
        completed_at: "${timestamp}"
      }

    - rcd_track_dispatch_completion: {
        tracking_id: "${input.tracking_id}",
        result: "${agent_result}",
        actual_response_time: "${dispatch_duration}",
        success: "${agent_result.success}"
      }

    - tamr.log: {
        event: "request_dispatched",
        tracking_id: "${input.tracking_id}",
        agent: "${input.agent}",
        priority: "${input.priority}",
        success: "${agent_result.success}"
      }

    - rcd_complete_performance_tracking: { operation: "dispatch_to_agent", success: "${agent_result.success}" }

  load_routing_rules:
    - rcd_start_performance_tracking: { operation: "load_routing_rules" }

    - config.get: { key: "ORDR_ROUTING_RULES" }
    - condition:
        if: "!${config_value}"
        then:
          - config.set:
              key: "ORDR_ROUTING_RULES"
              value: {
                "default_routes": {
                  "financial_operations": ["invoice-agent", "payment-agent"],
                  "system_monitoring": ["system-doctor", "pesr-agent"],
                  "user_communication": ["notification-agent", "chat-agent"],
                  "data_operations": ["etl-agent", "backup-agent"]
                },
                "priority_rules": {
                  "emergency": { "weight": 10, "max_queue_time": 0 },
                  "high": { "weight": 5, "max_queue_time": 30000 },
                  "normal": { "weight": 1, "max_queue_time": 300000 },
                  "low": { "weight": 0.5, "max_queue_time": 3600000 }
                },
                "load_balancing": {
                  "algorithm": "weighted_round_robin",
                  "health_check_interval": 60000,
                  "max_agent_load": 10
                }
              }

    - load_rules_into_memory: { rules: "${config_value}" }
    - rcd_register_routing_rules: { rules: "${config_value}" }

    - rcd_complete_performance_tracking: { operation: "load_routing_rules", success: true }

  process_request_queue:
    # Continuous queue processing with RCD optimization
    - loop:
        while: "${queue_processing_enabled}"
        do:
          - get_next_request: { queue: "priority_queue" }
          - condition:
              if: "${next_request}"
              then:
                - rcd_log_queue_processing: {
                    request: "${next_request}",
                    queue_depth: "${current_queue_depth}"
                  }
                - run: ["ordr-agent.r", "route_request", "${next_request}"]
              else:
                - wait: { milliseconds: 100 }

  handle_agent_failure:
    - rcd_start_performance_tracking: { operation: "handle_agent_failure" }

    - tamr.log: {
        event: "agent_dispatch_failed",
        agent: "${input.failed_agent}",
        request: "${input.request}",
        error: "${input.error}"
      }

    - rcd_analyze_failure_pattern: {
        failed_agent: "${input.failed_agent}",
        failure_context: "${input.error}",
        recent_failures: "${agent_failure_history}"
      }

    - find_backup_agents: {
        original_agent: "${input.failed_agent}",
        request: "${input.request}",
        exclude_similar_failures: true
      }

    - condition:
        if: "${backup_agents.length > 0}"
        then:
          - rcd_track_failover: {
              original_agent: "${input.failed_agent}",
              backup_agent: "${backup_agents[0].id}",
              failover_reason: "${input.error}"
            }
          - dispatch_to_agent: {
              agent: "${backup_agents[0].id}",
              request: "${input.request}",
              priority: "high",
              tracking_id: "${input.tracking_id}_retry"
            }
        else:
          - rcd_track_escalation: {
              failed_agent: "${input.failed_agent}",
              request: "${input.request}",
              escalation_reason: "no_backup_agents"
            }
          - escalate_to_human: {
              issue: "no_available_agents",
              request: "${input.request}",
              failed_agent: "${input.failed_agent}"
            }

    - rcd_complete_performance_tracking: { operation: "handle_agent_failure", success: "${backup_agents.length > 0}" }

  self_optimize:
    - rcd_start_performance_tracking: { operation: "self_optimize" }

    - analyze_routing_performance: { time_window: "24h" }
    - rcd_comprehensive_routing_analysis: {
        performance_data: "${routing_performance}",
        agent_utilization: "${agent_utilization_data}",
        workflow_efficiency: "${workflow_metrics}",
        time_window: "24h"
      }

    - identify_bottlenecks: { performance_data: "${routing_performance}" }
    - rcd_identify_optimization_opportunities: {
        bottlenecks: "${identified_bottlenecks}",
        routing_patterns: "${routing_patterns}",
        agent_performance: "${agent_performance_trends}"
      }

    - infer.optimizeRouting:
        current_rules: "${routing_rules}",
        performance_data: "${routing_performance}",
        bottlenecks: "${identified_bottlenecks}",
        rcd_insights: "${optimization_opportunities}"

    - condition:
        if: "${routing_optimization.improvement_potential > 0.15}"
        then:
          - test_optimized_rules: {
              new_rules: "${routing_optimization.suggested_rules}",
              test_duration: 3600000
            }
          - condition:
              if: "${rule_test.performance_improvement > 0.1}"
              then:
                - config.set: {
                    key: "ORDR_ROUTING_RULES",
                    value: "${routing_optimization.suggested_rules}"
                  }
                - rcd_store_optimization_success: {
                    optimization_type: "routing_rules",
                    improvement: "${rule_test.performance_improvement}",
                    new_rules: "${routing_optimization.suggested_rules}"
                  }
                - tamr.log: {
                    event: "routing_rules_optimized",
                    improvement: "${rule_test.performance_improvement}"
                  }

    - rcd_complete_performance_tracking: { operation: "self_optimize", success: true }

  handle_system_issues:
    # Called by system-doctor to coordinate system-wide responses
    - rcd_start_performance_tracking: { operation: "handle_system_issues" }

    - prioritize_system_issues: {
        issues: "${input.issues}",
        recommended_actions: "${input.recommended_actions}",
        system_priority: "${input.priority}"
      }

    - create_system_response_workflow: {
        prioritized_issues: "${prioritized_issues}",
        available_agents: "${active_agents}",
        resource_constraints: "${current_system_load}"
      }

    - rcd_track_system_response: {
        issues: "${input.issues}",
        workflow: "${system_response_workflow}",
        coordination_strategy: "${coordination_strategy}"
      }

    - run: ["ordr-agent.r", "orchestrate_workflow", "${system_response_workflow}"]

    - rcd_complete_performance_tracking: { operation: "handle_system_issues", success: true }

  # RCD Integration Operations
  rcd_register_orchestration_agent:
    - rcd.register_agent: {
        agent_id: "${self.id}",
        capabilities: "${rcd.meta_tags.capabilities}",
        relationships: "${rcd.relationships}",
        routing_intelligence: "${rcd.routing_intelligence}",
        performance_baseline: "${rcd.performance_tracking.baseline_performance}"
      }

  rcd_initialize_routing_intelligence:
    - rcd.initialize_routing_system: {
        agent_id: "${self.id}",
        learning_patterns: "${rcd.learning_patterns}",
        routing_algorithms: "${routing_algorithms}",
        intelligence_focus: "${rcd.routing_intelligence}"
      }

  rcd_load_agent_capability_map:
    - rcd.query_agent_capabilities: {
        active_only: true,
        include_performance_data: true
      }
    - build_capability_routing_map: { agents: "${agent_capabilities}" }
    - cache_capability_map: { map: "${capability_routing_map}" }

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
    - run: ["ordr-agent.r", "rcd_adaptive_routing_learning"]

  rcd_adaptive_routing_learning:
    - condition:
        if: "${operation_performance.below_baseline || !input.success}"
        then:
          - rcd.trigger_learning: {
              agent_id: "${self.id}",
              focus_area: "${memory.current_operation}",
              performance_data: "${operation_performance}",
              routing_context: "${current_routing_context}"
            }

  rcd_enrich_request_analysis:
    - rcd.query_similar_requests: {
        request_analysis: "${input.analysis}",
        time_window: "${input.historical_context}",
        similarity_threshold: 0.8
      }
    - apply_historical_insights: {
        analysis: "${input.analysis}",
        similar_requests: "${similar_requests}",
        success_patterns: "${historical_success_patterns}"
      }
    - return: "${enriched_analysis}"

  rcd_score_agent_candidates:
    - rcd.get_agent_performance_data: {
        agents: "${input.candidates}",
        metrics: ["success_rate", "response_time", "current_load", "specialization_match"],
        time_window: "7d"
      }
    - calculate_dynamic_scores: {
        candidates: "${input.candidates}",
        performance_data: "${agent_performance_data}",
        request_context: "${input.request_context}",
        current_loads: "${input.current_loads}"
      }
    - return: "${scored_candidates}"

  rcd_log_routing_decision:
    - rcd.log_routing_decision: {
        agent_id: "${self.id}",
        selected_agent: "${input.selected_agent}",
        decision_factors: "${input.decision_factors}",
        alternatives: "${input.alternatives}",
        timestamp: "${timestamp}"
      }

  rcd_track_dispatch_start:
    - rcd.track_dispatch: {
        tracking_id: "${input.tracking_id}",
        phase: "start",
        target_agent: "${input.target_agent}",
        expected_response_time: "${input.expected_response_time}"
      }

  rcd_track_dispatch_completion:
    - rcd.track_dispatch: {
        tracking_id: "${input.tracking_id}",
        phase: "completion",
        result: "${input.result}",
        actual_response_time: "${input.actual_response_time}",
        success: "${input.success}"
      }
    - update_agent_performance_metrics: {
        agent: "${target_agent}",
        performance: "${dispatch_performance}"
      }

  rcd_optimize_workflow_plan:
    - rcd.analyze_workflow_optimization: {
        workflow: "${input.workflow}",
        agent_capabilities: "${input.agent_capabilities}",
        load_distribution: "${input.load_distribution}",
        historical_performance: "${workflow_history}"
      }
    - apply_optimization_patterns: {
        workflow: "${input.workflow}",
        optimization_analysis: "${workflow_optimization}",
        learned_patterns: "${workflow_patterns}"
      }
    - return: "${optimized_workflow}"

  rcd_analyze_workflow_performance:
    - calculate_workflow_metrics: {
        workflow: "${input.workflow}",
        execution_plan: "${input.execution_plan}",
        duration: "${input.total_duration}",
        phase_results: "${input.phase_results}"
      }
    - rcd.store_workflow_performance: {
        workflow_id: "${input.workflow.id}",
        metrics: "${workflow_metrics}",
        optimization_opportunities: "${identified_optimizations}"
      }

  rcd_comprehensive_routing_analysis:
    - rcd.analyze_routing_performance: {
        agent_id: "${self.id}",
        performance_data: "${input.performance_data}",
        utilization_data: "${input.agent_utilization}",
        workflow_metrics: "${input.workflow_efficiency}",
        time_window: "${input.time_window}"
      }
    - identify_performance_trends: {
        analysis: "${routing_analysis}",
        trend_detection: "advanced"
      }

  rcd_store_optimization_success:
    - rcd.store_optimization: {
        agent_id: "${self.id}",
        optimization_type: "${input.optimization_type}",
        improvement_metrics: "${input.improvement}",
        optimization_data: "${input.new_rules}",
        success: true
      }

  # Collaboration operations with RCD awareness
  coordinate_with_system_doctor:
    - rcd.query_agent_status: { agent_id: "system-doctor" }
    - condition:
        if: "${system_doctor_status.health_issues_detected}"
        then:
          - adjust_routing_for_health_issues: {
              health_status: "${system_doctor_status}",
              affected_agents: "${health_issues.affected_agents}"
            }

  coordinate_with_pesr:
    - rcd.query_agent_status: { agent_id: "pesr-agent" }
    - condition:
        if: "${pesr_status.high_priority_signals}"
        then:
          - prioritize_signal_responses: {
              signals: "${pesr_status.signals}",
              routing_adjustments: "${signal_routing_adjustments}"
            }

  provide_routing_insights:
    # API for other agents to query routing patterns and performance
    - rcd.query_routing_patterns: {
        pattern_types: "${input.pattern_types}",
        time_window: "${input.time_window}",
        include_performance: true
      }
    - format_insights_for_requestor: {
        patterns: "${routing_patterns}",
        requesting_agent: "${context.agentId}"
      }
    - return: "${formatted_insights}"

concern:
  if: "${queue_depth > 100 || average_response_time > 10000}"
  priority: 1
  action:
    - tamr.log: { event: "ordr_performance_concern", metrics: "${performance_metrics}" }
    - run: ["ordr-agent.r", "self_optimize"]
    - condition:
        if: "${queue_depth > 500}"
        then:
          - prompt.user:
              to: "system_admin"
              message: "🚨 ORDR Agent overloaded. Queue depth: ${queue_depth}. Immediate action needed."
              buttons: ["Scale Agents", "Emergency Mode", "Manual Override"]

# Enhanced routing algorithm configurations with RCD metadata
routing_algorithms:
  weighted_round_robin:
    weights: ["success_rate", "response_time", "current_load"]
    load_factor: 0.3
    rcd_metadata:
      learning_enabled: true
      optimization_target: "balanced_performance"
      adaptation_frequency: "hourly"

  least_connections:
    metric: "active_requests"
    fallback: "round_robin"
    rcd_metadata:
      learning_enabled: true
      optimization_target: "load_distribution"
      adaptation_frequency: "real_time"

  capability_match:
    scoring: ["exact_match", "partial_match", "fallback_capability"]
    threshold: 0.7
    rcd_metadata:
      learning_enabled: true
      optimization_target: "accuracy_over_speed"
      adaptation_frequency: "daily"

  rcd_intelligent_routing:
    factors: ["historical_success", "agent_specialization", "current_performance", "predicted_load"]
    weights: { "historical_success": 0.3, "agent_specialization": 0.25, "current_performance": 0.25, "predicted_load": 0.2 }
    rcd_metadata:
      learning_enabled: true
      optimization_target: "maximum_success_rate"
      adaptation_frequency: "continuous"
