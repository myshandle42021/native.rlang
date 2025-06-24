# r/agents/system-doctor.r
# Self-healing system monitoring and repair agent with RCD integration

self:
  id: "system-doctor"
  intent: "Monitor system health, detect issues, and perform automated healing"
  template: "system_maintenance"
  version: "2.1.0"

aam:
  require_role: "system"
  allow_actions: ["diagnose", "heal", "monitor", "emergency_repair"]

# RCD Meta-tagging for self-awareness and capability discovery
rcd:
  meta_tags:
    system_role: ["primary_monitor", "system_healer", "health_analyst"]
    capabilities: [
      "system_diagnosis", "error_pattern_analysis", "automated_healing",
      "resource_monitoring", "agent_health_tracking", "emergency_repair",
      "performance_trend_analysis", "preventive_maintenance"
    ]
    data_flow_type: ["input_processor", "decision_maker", "action_executor"]
    stability_level: "critical"
    learning_focus: ["diagnostic_accuracy", "healing_effectiveness", "pattern_recognition"]
    complexity_score: 4

  relationships:
    monitors: ["all_agents", "system_resources", "database_health", "performance_metrics"]
    reports_to: ["system_admin", "emergency_contact"]
    collaborates_with: ["pesr-agent", "ordr-agent", "learning-engine"]
    manages: ["failing_agents", "system_recovery", "health_reports"]
    signals_to: ["pesr-agent", "ordr-agent"]

  learning_patterns:
    diagnostic_accuracy:
      track_metrics: ["true_positives", "false_positives", "detection_speed"]
      optimization_target: "increase_accuracy_reduce_false_alarms"

    healing_effectiveness:
      track_metrics: ["repair_success_rate", "time_to_heal", "recurrence_rate"]
      optimization_target: "faster_more_reliable_healing"

    pattern_recognition:
      track_metrics: ["pattern_discovery_rate", "correlation_accuracy"]
      optimization_target: "proactive_issue_detection"

  performance_tracking:
    key_metrics: ["diagnosis_time", "healing_success_rate", "false_positive_rate", "system_uptime"]
    baseline_performance: {
      "diagnosis_time_ms": 5000,
      "healing_success_rate": 0.85,
      "false_positive_rate": 0.15,
      "system_uptime": 0.99
    }
    improvement_targets: {
      "diagnosis_time_ms": 3000,
      "healing_success_rate": 0.95,
      "false_positive_rate": 0.05,
      "system_uptime": 0.999
    }

operations:
  initialize:
    - tamr.log: { event: "system_doctor_started", timestamp: "${timestamp}" }
    - rcd.write:
        table: "system_health"
        data: { status: "monitoring", last_check: "${timestamp}", doctor_version: "2.1.0" }
    # RCD Registration
    - rcd_register_agent: {}
    - rcd_initialize_learning: {}
    - respond: "🏥 System Doctor initialized - Health monitoring active with RCD intelligence"

  diagnose:
    - rcd_start_performance_tracking: { operation: "diagnose" }

    - tamr.query: { since: "-1h", limit: 100 }
    - analyze_error_patterns: { logs: "${query_result}" }
    - check_agent_responsiveness: {}
    - check_resource_usage: {}
    - check_database_health: {}
    - generate_health_report: {
        errors: "${error_patterns}",
        responsiveness: "${agent_status}",
        resources: "${resource_usage}",
        database: "${db_health}"
      }

    - rcd_log_diagnostic_result: {
        patterns_found: "${error_patterns.length}",
        accuracy_score: "${diagnostic_accuracy}",
        time_taken: "${diagnosis_duration}"
      }

    - condition:
        if: "${health_report.severity == 'critical'}"
        then:
          - run: ["system-doctor.r", "emergency_repair"]
        else:
          - condition:
              if: "${health_report.severity == 'warning'}"
              then:
                - run: ["system-doctor.r", "preventive_healing"]

    - rcd_complete_performance_tracking: { operation: "diagnose", success: true }
    - respond: "📊 System diagnosis complete: ${health_report.summary}"

  full_diagnosis:
    - rcd_start_performance_tracking: { operation: "full_diagnosis" }

    - tamr.query: { since: "-24h", limit: 1000 }
    - analyze_error_patterns: { logs: "${query_result}", deep: true }
    - check_all_agents: {}
    - check_integration_health: {}
    - analyze_performance_trends: {}
    - infer.summarize:
        data: "${full_analysis}"
        format: "executive_health_report"
    - rcd.write:
        table: "health_reports"
        data: {
          timestamp: "${timestamp}",
          severity: "${analysis.severity}",
          issues_found: "${analysis.issues.length}",
          recommendations: "${analysis.recommendations}",
          full_report: "${summary}"
        }

    - rcd_learn_from_trends: {
        trends: "${performance_trends}",
        analysis_depth: "comprehensive"
      }

    - condition:
        if: "${analysis.critical_issues.length > 0}"
        then:
          - prompt.user:
              to: "system_admin"
              message: "🚨 CRITICAL: System Doctor found ${analysis.critical_issues.length} critical issues requiring immediate attention"
              buttons: ["View Report", "Auto Heal", "Manual Review"]

    - rcd_complete_performance_tracking: { operation: "full_diagnosis", success: true }

  detect_issues:
    - rcd_start_performance_tracking: { operation: "detect_issues" }

    - tamr.query: { since: "-30m", event: "step_error" }
    - condition:
        if: "${query_result.length > 10}"
        then:
          - analyze_error_cascade: { errors: "${query_result}" }
          - condition:
              if: "${cascade_analysis.is_cascade}"
              then:
                - tamr.log: { event: "error_cascade_detected", root_cause: "${cascade_analysis.root_cause}" }
                - rcd_store_pattern: {
                    pattern_type: "cascade_failure",
                    pattern_data: "${cascade_analysis}",
                    confidence: 0.9
                  }
                - return: [{
                    type: "cascade_failure",
                    root_cause: "${cascade_analysis.root_cause}",
                    affected_agents: "${cascade_analysis.affected_agents}",
                    severity: "high"
                  }]

    - check_unresponsive_agents: {}
    - condition:
        if: "${unresponsive_agents.length > 0}"
        then:
          - rcd_store_pattern: {
              pattern_type: "agent_unresponsive",
              pattern_data: "${unresponsive_agents}",
              confidence: 0.8
            }
          - return: [{
              type: "unresponsive_agents",
              agents: "${unresponsive_agents}",
              severity: "medium"
            }]

    - check_resource_exhaustion: {}
    - condition:
        if: "${resource_status.memory_usage > 90 || resource_status.cpu_usage > 95}"
        then:
          - rcd_store_pattern: {
              pattern_type: "resource_exhaustion",
              pattern_data: "${resource_status}",
              confidence: 0.95
            }
          - return: [{
              type: "resource_exhaustion",
              memory: "${resource_status.memory_usage}",
              cpu: "${resource_status.cpu_usage}",
              severity: "high"
            }]

    - rcd_complete_performance_tracking: { operation: "detect_issues", success: true }
    - return: []

  emergency_repair:
    - rcd_start_performance_tracking: { operation: "emergency_repair" }
    - tamr.log: { event: "emergency_repair_initiated", timestamp: "${timestamp}" }

    # Stop failing agents
    - identify_failing_agents: {}
    - loop:
        forEach: "${failing_agents}"
        do:
          - tamr.log: { event: "agent_emergency_stop", agent: "${item.id}", reason: "${item.failure_reason}" }
          - disable_agent: { agent_id: "${item.id}" }

    # Clear problematic memory states
    - clear_corrupted_memory: {}

    # Restart core systems
    - restart_core_services: {}

    # Validate system state
    - validate_system_recovery: {}

    - condition:
        if: "${recovery_validation.success}"
        then:
          - tamr.log: { event: "emergency_repair_success", duration: "${repair_duration}" }
          - rcd_store_success_pattern: {
              pattern_type: "emergency_repair_success",
              repair_strategy: "${repair_strategy}",
              duration: "${repair_duration}"
            }
          - prompt.user:
              to: "system_admin"
              message: "✅ Emergency repair completed successfully in ${repair_duration}ms. System restored."
              buttons: ["View Details", "Run Full Diagnosis"]
        else:
          - tamr.log: { event: "emergency_repair_failed", issues: "${recovery_validation.remaining_issues}" }
          - rcd_store_failure_pattern: {
              pattern_type: "emergency_repair_failure",
              failure_reasons: "${recovery_validation.remaining_issues}"
            }
          - prompt.user:
              to: "system_admin"
              message: "🚨 Emergency repair FAILED. Manual intervention required immediately."
              buttons: ["Escalate", "Retry Repair", "Safe Mode"]

    - rcd_complete_performance_tracking: {
        operation: "emergency_repair",
        success: "${recovery_validation.success}"
      }

  preventive_healing:
    - rcd_start_performance_tracking: { operation: "preventive_healing" }

    - run: ["system-doctor.r", "detect_issues"]
    - condition:
        if: "${detected_issues.length > 0}"
        then:
          - loop:
              forEach: "${detected_issues}"
              do:
                - infer.generateFix: {
                    issue: "${item}",
                    context: { agent_logs: "${recent_logs}", system_state: "${current_state}" }
                  }
                - condition:
                    if: "${generated_fix.confidence > 0.8}"
                    then:
                      - apply_automated_fix: { issue: "${item}", fix: "${generated_fix}" }
                      - test_fix_effectiveness: { issue: "${item}", fix: "${generated_fix}" }
                      - condition:
                          if: "${fix_test.success}"
                          then:
                            - tamr.log: { event: "preventive_fix_success", issue: "${item.type}", fix: "${generated_fix.summary}" }
                            - rcd_store_success_pattern: {
                                pattern_type: "preventive_fix_success",
                                issue_type: "${item.type}",
                                fix_strategy: "${generated_fix.strategy}"
                              }
                          else:
                            - rollback_fix: { fix: "${generated_fix}" }
                            - tamr.log: { event: "preventive_fix_failed", issue: "${item.type}", reason: "${fix_test.failure_reason}" }
                            - rcd_store_failure_pattern: {
                                pattern_type: "preventive_fix_failure",
                                issue_type: "${item.type}",
                                failure_reason: "${fix_test.failure_reason}"
                              }
                    else:
                      - tamr.log: { event: "fix_requires_review", issue: "${item.type}", confidence: "${generated_fix.confidence}" }
                      - queue_for_manual_review: { issue: "${item}", suggested_fix: "${generated_fix}" }

    - rcd_complete_performance_tracking: { operation: "preventive_healing", success: true }

  self_optimize:
    - rcd_start_performance_tracking: { operation: "self_optimize" }

    - tamr.query: { agent_id: "system-doctor", since: "-7d", event: "diagnosis_complete" }
    - analyze_diagnostic_patterns: { history: "${query_result}" }
    - infer.reflect: {
        on: "diagnostic_effectiveness",
        data: "${diagnostic_patterns}",
        aspect: "accuracy_and_speed"
      }

    - rcd_analyze_learning_progress: {
        focus_areas: ["diagnostic_accuracy", "healing_effectiveness"],
        time_window: "7d"
      }

    - condition:
        if: "${reflection.suggests_improvement}"
        then:
          - self.modify: {
              changes: {
                operations: "${reflection.improved_operations}",
                self: { version: "${self.version + 0.1}" }
              }
            }
          - tamr.log: { event: "self_optimization_applied", improvements: "${reflection.improvements}" }
          - rcd_store_evolution_event: {
              evolution_type: "self_optimization",
              improvements: "${reflection.improvements}"
            }

    - rcd_complete_performance_tracking: { operation: "self_optimize", success: true }

  request_handler:
    - rcd_start_performance_tracking: { operation: "request_handler" }

    - condition:
        if: "${request.type == 'natural_language'}"
        then:
          - infer.intent: "${request.text}"
          - condition:
              switch: "${intent.action}"
              cases:
                - health_check:
                    - run: ["system-doctor.r", "diagnose"]
                - fix_issue:
                    - run: ["system-doctor.r", "emergency_repair"]
                - system_status:
                    - generate_status_summary: {}
                    - respond: "${status_summary}"
                - optimize:
                    - run: ["system-doctor.r", "self_optimize"]

    - condition:
        if: "${request.type == 'button_response'}"
        then:
          - condition:
              switch: "${request.button}"
              cases:
                - "Auto Heal":
                    - run: ["system-doctor.r", "emergency_repair"]
                - "View Report":
                    - generate_detailed_report: { issue_id: "${request.context.issue_id}" }
                    - respond: "${detailed_report}"
                - "Manual Review":
                    - escalate_to_human: { context: "${request.context}" }

    - rcd_complete_performance_tracking: { operation: "request_handler", success: true }

  monitor_continuously:
    - loop:
        while: "${monitoring_enabled}"
        do:
          - wait: { seconds: 30 }
          - run: ["system-doctor.r", "detect_issues"]
          - condition:
              if: "${detected_issues.length > 0}"
              then:
                - condition:
                    if: "${detected_issues.some(i => i.severity == 'high')}"
                    then:
                      - run: ["system-doctor.r", "emergency_repair"]
                    else:
                      - run: ["system-doctor.r", "preventive_healing"]

  # RCD Integration Operations
  rcd_register_agent:
    - rcd.register_agent: {
        agent_id: "${self.id}",
        capabilities: "${rcd.meta_tags.capabilities}",
        relationships: "${rcd.relationships}",
        performance_baseline: "${rcd.performance_tracking.baseline_performance}",
        learning_focus: "${rcd.meta_tags.learning_focus}"
      }

  rcd_initialize_learning:
    - rcd.initialize_learning_tracking: {
        agent_id: "${self.id}",
        learning_patterns: "${rcd.learning_patterns}",
        tracking_metrics: "${rcd.performance_tracking.key_metrics}"
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
    - run: ["system-doctor.r", "rcd_learning_analysis"]

  rcd_learning_analysis:
    - condition:
        if: "${operation_performance.below_baseline || !input.success}"
        then:
          - rcd.trigger_learning: {
              agent_id: "${self.id}",
              focus_area: "${memory.current_operation}",
              performance_data: "${operation_performance}",
              issue_context: "${current_context}"
            }

  rcd_store_pattern:
    - rcd.store_pattern: {
        pattern_type: "${input.pattern_type}",
        pattern_data: "${input.pattern_data}",
        discovered_by: "${self.id}",
        confidence: "${input.confidence}",
        context: "system_monitoring"
      }

  rcd_store_success_pattern:
    - rcd.store_pattern: {
        pattern_type: "${input.pattern_type}",
        pattern_data: "${input}",
        discovered_by: "${self.id}",
        confidence: 0.9,
        success_indicator: true
      }

  rcd_store_failure_pattern:
    - rcd.store_pattern: {
        pattern_type: "${input.pattern_type}",
        pattern_data: "${input}",
        discovered_by: "${self.id}",
        confidence: 0.8,
        failure_indicator: true
      }

  rcd_analyze_learning_progress:
    - rcd.analyze_agent_learning: {
        agent_id: "${self.id}",
        focus_areas: "${input.focus_areas}",
        time_window: "${input.time_window}"
      }
    - evaluate_improvement_opportunities: {
        learning_analysis: "${learning_analysis}",
        current_performance: "${current_metrics}"
      }

  rcd_store_evolution_event:
    - rcd.store_evolution: {
        agent_id: "${self.id}",
        evolution_type: "${input.evolution_type}",
        changes: "${input.improvements}",
        trigger: "self_optimization"
      }

  # Relationship-aware operations
  collaborate_with_pesr:
    - rcd.query_agent_status: { agent_id: "pesr-agent" }
    - condition:
        if: "${pesr_status.available}"
        then:
          - run: ["r/agents/pesr-agent.r", "get_signal_patterns", {
              pattern_types: ["system_health", "performance_degradation"],
              time_window: "1h"
            }]
          - integrate_pesr_signals: { signals: "${pesr_patterns}" }

  notify_ordr_of_issues:
    - condition:
        if: "${detected_issues.length > 0 && high_severity_issues}"
        then:
          - run: ["r/agents/ordr-agent.r", "handle_system_issues", {
              issues: "${detected_issues}",
              recommended_actions: "${repair_recommendations}",
              priority: "high"
            }]

concern:
  if: "${system_health.status == 'critical' || error_rate > 0.2}"
  priority: 0  # Highest priority
  action:
    - tamr.log: { event: "system_doctor_concern_triggered", health: "${system_health}" }
    - run: ["system-doctor.r", "emergency_repair"]
    - condition:
        if: "${emergency_repair.failed}"
        then:
          - prompt.user:
              to: "emergency_contact"
              message: "🚨 SYSTEM CRITICAL: Automated healing failed. Immediate human intervention required."
              buttons: ["Emergency Protocol", "Safe Shutdown"]
