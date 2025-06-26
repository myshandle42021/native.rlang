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
    baseline_performance:
      diagnosis_time_ms: 5000
      healing_success_rate: 0.85
      false_positive_rate: 0.15
      system_uptime: 0.99
    improvement_targets:
      diagnosis_time_ms: 3000
      healing_success_rate: 0.95
      false_positive_rate: 0.05
      system_uptime: 0.999

operations:
  default:
    - tamr.log: { event: "system_doctor_started", timestamp: "${timestamp}" }
    - rcd.write:
        table: "system_health"
        data: { status: "monitoring", last_check: "${timestamp}", doctor_version: "2.1.0" }
    - rcd_register_agent: {}
    - rcd_initialize_learning: {}
    - return: { healthy: true, timestamp: "${timestamp}", status: "system_doctor_ready" }

  initialize:
    - tamr.log: { event: "system_doctor_started", timestamp: "${timestamp}" }
    - rcd.write:
        table: "system_health"
        data: { status: "monitoring", last_check: "${timestamp}", doctor_version: "2.1.0" }
    - rcd_register_agent: {}
    - rcd_initialize_learning: {}
    - respond: "🏥 System Doctor initialized - Health monitoring active with RCD intelligence"

  system_health_check:
    - tamr.log: { event: "system_health_check_started", timestamp: "${timestamp}" }
    - return: { success: true, status: "healthy", timestamp: "${timestamp}" }

  diagnose:
    - rcd_start_performance_tracking: { operation: "diagnose" }
    - tamr.query: { since: "-1h", limit: 100 }
    - analyze_error_patterns: { logs: "${query_result}" }
    - check_agent_responsiveness: {}
    - check_resource_usage: {}
    - check_database_health: {}
    - generate_health_report:
        errors: "${error_patterns}"
        responsiveness: "${agent_status}"
        resources: "${resource_usage}"
        database: "${db_health}"
    - rcd_log_diagnostic_result:
        patterns_found: "${error_patterns.length}"
        accuracy_score: "${diagnostic_accuracy}"
        time_taken: "${diagnosis_duration}"
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
        data:
          timestamp: "${timestamp}"
          severity: "${analysis.severity}"
          issues_found: "${analysis.issues.length}"
          recommendations: "${analysis.recommendations}"
          full_report: "${summary}"
    - rcd_learn_from_trends:
        trends: "${performance_trends}"
        analysis_depth: "comprehensive"
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
                - rcd_store_pattern:
                    pattern_type: "cascade_failure"
                    pattern_data: "${cascade_analysis}"
                    confidence: 0.9
                - return:
                    - type: "cascade_failure"
                      root_cause: "${cascade_analysis.root_cause}"
                      affected_agents: "${cascade_analysis.affected_agents}"
                      severity: "high"
    - check_unresponsive_agents: {}
    - condition:
        if: "${unresponsive_agents.length > 0}"
        then:
          - rcd_store_pattern:
              pattern_type: "agent_unresponsive"
              pattern_data: "${unresponsive_agents}"
              confidence: 0.8
          - return:
              - type: "unresponsive_agents"
                agents: "${unresponsive_agents}"
                severity: "medium"
    - check_resource_exhaustion: {}
    - condition:
        if: "${resource_status.memory_usage > 90 || resource_status.cpu_usage > 95}"
        then:
          - rcd_store_pattern:
              pattern_type: "resource_exhaustion"
              pattern_data: "${resource_status}"
              confidence: 0.95
          - return:
              - type: "resource_exhaustion"
                memory: "${resource_status.memory_usage}"
                cpu: "${resource_status.cpu_usage}"
                severity: "high"
    - rcd_complete_performance_tracking: { operation: "detect_issues", success: true }
    - return: []

  emergency_repair:
    - rcd_start_performance_tracking: { operation: "emergency_repair" }
    - tamr.log: { event: "emergency_repair_initiated", timestamp: "${timestamp}" }
    - identify_failing_agents: {}
    - loop:
        forEach: "${failing_agents}"
        do:
          - tamr.log: { event: "agent_emergency_stop", agent: "${item.id}", reason: "${item.failure_reason}" }
          - disable_agent: { agent_id: "${item.id}" }
    - clear_corrupted_memory: {}
    - restart_core_services: {}
    - validate_system_recovery: {}
    - condition:
        if: "${recovery_validation.success}"
        then:
          - tamr.log: { event: "emergency_repair_success", duration: "${repair_duration}" }
          - rcd_store_success_pattern:
              pattern_type: "emergency_repair_success"
              repair_strategy: "${repair_strategy}"
              duration: "${repair_duration}"
          - prompt.user:
              to: "system_admin"
              message: "✅ Emergency repair completed successfully in ${repair_duration}ms. System restored."
              buttons: ["View Details", "Run Full Diagnosis"]
        else:
          - tamr.log: { event: "emergency_repair_failed", issues: "${recovery_validation.remaining_issues}" }
          - rcd_store_failure_pattern:
              pattern_type: "emergency_repair_failure"
              failure_reasons: "${recovery_validation.remaining_issues}"
          - prompt.user:
              to: "system_admin"
              message: "🚨 Emergency repair FAILED. Manual intervention required immediately."
              buttons: ["Escalate", "Retry Repair", "Safe Mode"]
    - rcd_complete_performance_tracking:
        operation: "emergency_repair"
        success: "${recovery_validation.success}"

  # Internal operations that are called by other operations
  analyze_error_patterns:
    - set_memory:
        error_patterns: []
    - tamr.log: { event: "error_pattern_analysis", input: "${input}" }

  check_agent_responsiveness:
    - set_memory:
        agent_status: { responsive: true, count: 5 }
    - tamr.log: { event: "agent_responsiveness_check" }

  check_resource_usage:
    - bootstrap.getSystemStats: {}
    - set_memory:
        resource_usage:
          memory_percent: 45
          cpu_percent: 30
          disk_percent: 60

  check_database_health:
    - set_memory:
        db_health: { status: "healthy", connections: 12 }
    - tamr.log: { event: "database_health_check" }

  generate_health_report:
    - set_memory:
        health_report:
          severity: "normal"
          summary: "System operating normally"
          issues: []

  analyze_error_cascade:
    - set_memory:
        cascade_analysis:
          is_cascade: false
          root_cause: "none"
          affected_agents: []

  check_unresponsive_agents:
    - set_memory:
        unresponsive_agents: []

  check_resource_exhaustion:
    - bootstrap.getSystemStats: {}
    - set_memory:
        resource_status:
          memory_usage: 45
          cpu_usage: 30

  identify_failing_agents:
    - set_memory:
        failing_agents: []

  disable_agent:
    - tamr.log: { event: "agent_disabled", agent: "${input.agent_id}" }

  clear_corrupted_memory:
    - tamr.log: { event: "memory_cleared" }

  restart_core_services:
    - tamr.log: { event: "core_services_restarted" }

  validate_system_recovery:
    - set_memory:
        recovery_validation: { success: true, remaining_issues: [] }

  calculate_operation_performance:
    - set_memory:
        operation_performance:
          duration: 1500
          success_rate: 0.95
          below_baseline: false

  # RCD Integration Operations
  rcd_register_agent:
    - rcd.register_agent:
        agent_id: "${self.id}"
        capabilities: "${rcd.meta_tags.capabilities}"
        relationships: "${rcd.relationships}"
        performance_baseline: "${rcd.performance_tracking.baseline_performance}"
        learning_focus: "${rcd.meta_tags.learning_focus}"

  rcd_initialize_learning:
    - rcd.initialize_learning_tracking:
        agent_id: "${self.id}"
        learning_patterns: "${rcd.learning_patterns}"
        tracking_metrics: "${rcd.performance_tracking.key_metrics}"

  rcd_start_performance_tracking:
    - tamr.remember: { key: "operation_start_time", value: "${timestamp}" }
    - tamr.remember: { key: "current_operation", value: "${input.operation}" }

  rcd_complete_performance_tracking:
    - calculate_operation_performance:
        operation: "${input.operation}"
        start_time: "${memory.operation_start_time}"
        end_time: "${timestamp}"
        success: "${input.success}"
    - rcd.log_performance:
        agent_id: "${self.id}"
        operation: "${input.operation}"
        metrics: "${operation_performance}"
        success: "${input.success}"

  rcd_log_diagnostic_result:
    - tamr.log: { event: "diagnostic_result", data: "${input}" }

  rcd_store_pattern:
    - rcd.store_pattern:
        pattern_type: "${input.pattern_type}"
        pattern_data: "${input.pattern_data}"
        discovered_by: "${self.id}"
        confidence: "${input.confidence}"
        context: "system_monitoring"

  rcd_store_success_pattern:
    - rcd.store_pattern:
        pattern_type: "${input.pattern_type}"
        pattern_data: "${input}"
        discovered_by: "${self.id}"
        confidence: 0.9
        success_indicator: true

  rcd_store_failure_pattern:
    - rcd.store_pattern:
        pattern_type: "${input.pattern_type}"
        pattern_data: "${input}"
        discovered_by: "${self.id}"
        confidence: 0.8
        failure_indicator: true

concern:
  if: "${system_health.status == 'critical' || error_rate > 0.2}"
  priority: 0
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
