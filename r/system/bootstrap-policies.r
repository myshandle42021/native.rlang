# r/system/bootstrap-policies.r
# Declarative system startup policies with self-modification capabilities

self:
  id: "bootstrap-policies"
  intent: "Orchestrate system startup with adaptive policies and self-optimization"
  version: "1.0.0"
  template: "system_bootstrap"

aam:
  require_role: "system"
  allow_actions: ["genesis", "bootstrap", "policy_modify", "system_restart"]

operations:
  system_genesis:
    - tamr.log: { event: "bootstrap_genesis_start", timestamp: "${timestamp}", version: "${self.version}" }

    # Phase 1: Environment Validation
    - validate_environment:
        checks: ["database", "file_system", "memory", "dependencies"]
        failure_action: "abort_with_diagnostics"

    # Phase 2: Core Infrastructure
    - initialize_core_infrastructure:
        systems: ["database_pool", "logging", "signal_handlers"]
        parallel: true

    # Phase 3: System Policies Load
    - load_system_policies:
        policies: ["monitoring", "healing", "optimization", "security"]
        validate_after_load: true

    # Phase 4: Agent Ecosystem Startup
    - start_agent_ecosystem:
        critical_agents: ["system-doctor", "pesr-agent", "ordr-agent"]
        startup_sequence: "dependency_ordered"
        timeout_per_agent: "30s"

    # Phase 5: Adaptive Configuration
    - configure_adaptive_systems:
        based_on: ["system_health", "load_patterns", "historical_performance"]

    # Phase 6: Validation & Monitoring
    - validate_system_readiness: {}
    - start_continuous_monitoring: {}
    - initialize_learning_systems: {}

    - tamr.log: { event: "bootstrap_genesis_complete", duration: "${genesis_duration}", status: "healthy" }
    - respond: "🌱 ROL3 System Genesis Complete - Adaptive startup in ${genesis_duration}ms"

  validate_environment:
    - check_database_connectivity:
        timeout: "10s"
        retry_attempts: 3
        health_endpoint: "SELECT NOW()"
    - validate_database_health:
        health_result: "${database_connectivity}"
        condition:
          if: "!${health_result.healthy}"
          then:
            - tamr.log: { event: "database_unhealthy", error: "${health_result.error}" }
            - add_validation_error: { error: "Database unhealthy: ${health_result.error}" }

    - check_file_system_permissions:
        required_paths: ["r/", "utils/", "logs/"]
        operations: ["read", "write", "create"]
    - validate_file_permissions:
        permission_results: "${file_system_permissions}"
        loop:
          forEach: "${permission_results}"
          do:
            - condition:
                if: "!${item.accessible}"
                then:
                  - add_validation_error: { error: "Cannot access ${item.path} for ${item.operation}" }

    - check_memory_availability:
        minimum_mb: 512
        check_swap: true
    - validate_memory_requirements:
        memory_check: "${memory_availability}"
        condition:
          if: "${memory_check.available_mb < memory_check.minimum_required}"
          then:
            - add_validation_error: { error: "Insufficient memory: ${memory_check.available_mb}MB < ${memory_check.minimum_required}MB" }

    - check_dependencies:
        critical_modules: ["fs/promises", "path", "crypto"]
        optional_modules: ["sharp", "canvas"]
    - validate_dependencies:
        dependency_results: "${dependencies_check}"
        loop:
          forEach: "${dependency_results.critical_modules}"
          do:
            - condition:
                if: "!${item.available}"
                then:
                  - add_validation_error: { error: "Critical module missing: ${item.name}" }

    - evaluate_validation_results:
        errors: "${collected_validation_errors}"
        condition:
          if: "${collected_validation_errors.length > 0}"
          then:
            - tamr.log: { event: "environment_validation_failed", errors: "${collected_validation_errors}" }
            - run: ["r/system/bootstrap-policies.r", "abort_with_diagnostics"]
          else:
            - tamr.log: { event: "environment_validation_success", checks_passed: "${validation_results.length}" }

  initialize_core_infrastructure:
    - parallel.execute:
        tasks:
          - name: "database_pool"
            action: { bootstrap.connectDatabase: { pool_size: "${config.db_pool_size || 20}" } }
          - name: "logging_system"
            action: { bootstrap.writeFile: { path: "logs/system.log", content: "System started at ${timestamp}" } }
          - name: "signal_handlers"
            action: { bootstrap.registerSignalHandler: {
                signal: "SIGINT",
                rlang_file: "r/system/bootstrap-policies.r",
                operation: "graceful_shutdown"
              } }
          - name: "memory_manager"
            action: { bootstrap.setTimer: {
                rlang_file: "r/system/bootstrap-policies.r",
                operation: "memory_cleanup",
                interval_ms: 300000
              } }

    - validate_infrastructure_results:
        parallel_results: "${parallel_results}"
        loop:
          forEach: "${parallel_results}"
          do:
            - condition:
                if: "${item.error}"
                then:
                  - add_infrastructure_failure: {
                      system: "${item.name}",
                      error: "${item.error}",
                      critical: true
                    }
                else:
                  - mark_system_ready: { system: "${item.name}", result: "${item.result}" }

    - evaluate_infrastructure_status:
        failed_systems: "${infrastructure_failures}"
        condition:
          if: "${infrastructure_failures.length > 0}"
          then:
            - tamr.log: { event: "infrastructure_init_failed", failed: "${infrastructure_failures}" }
            - run: ["r/system/bootstrap-policies.r", "emergency_fallback"]
          else:
            - tamr.log: { event: "infrastructure_init_success", systems: "${initialized_systems}" }

  load_system_policies:
    - discover_policy_files:
        locations: ["r/policies/", "r/system/policies/"]
        pattern: "*.r"
        required: ["monitoring.r", "healing.r", "optimization.r"]

    - loop:
        forEach: "${discovered_policies}"
        do:
          - load_policy_file: { file: "${item.path}" }
          - validate_policy: { policy: "${loaded_policy}", file: "${item.path}" }
          - condition:
              if: "${policy_validation.success}"
              then:
                - register_policy: { policy: "${loaded_policy}", source: "${item.path}" }
                - tamr.log: { event: "policy_loaded", policy: "${loaded_policy.id}", source: "${item.path}" }
              else:
                - tamr.log: { event: "policy_load_failed", policy: "${item.path}", error: "${policy_validation.error}" }
                - condition:
                    if: "${item.required}"
                    then:
                      - run: ["r/system/bootstrap-policies.r", "abort_with_diagnostics"]

    - activate_policies: { loaded_policies: "${registered_policies}" }

  start_agent_ecosystem:
    - analyze_agent_dependencies: { agents: "${input.critical_agents}" }
    - create_startup_sequence: { dependencies: "${agent_dependencies}" }

    - loop:
        forEach: "${startup_sequence}"
        do:
          - condition:
              if: "${item.type == 'parallel_group'}"
              then:
                - parallel.execute:
                    tasks: "${item.agents.map(agent => ({name: agent, action: {run: ['r/agents/' + agent + '.r', 'initialize']}}))"
              else:
                - run: ["r/agents/${item.agent}.r", "initialize"]
                - wait: { seconds: "${item.delay || 2}" }

          - validate_agent_startup: { agent: "${item.agent || item.agents}", timeout: "${input.timeout_per_agent}" }

          - condition:
              if: "!${startup_validation.success}"
              then:
                - tamr.log: { event: "agent_startup_failed", agent: "${item.agent}", error: "${startup_validation.error}" }
                - run: ["r/system/bootstrap-policies.r", "handle_agent_startup_failure"]

    - tamr.log: { event: "agent_ecosystem_started", agents: "${startup_sequence.length}", duration: "${ecosystem_startup_duration}" }

  configure_adaptive_systems:
    - analyze_system_context:
        factors: ["available_memory", "cpu_cores", "disk_space", "network_latency"]
        historical_data: { since: "-30d", metrics: ["startup_time", "error_rate", "throughput"] }

    - calculate_optimal_settings:
        context: "${system_context}"
        historical: "${historical_performance}"
        defaults: {
          monitoring_interval: "5m",
          health_check_frequency: "1m",
          log_retention_days: 30,
          agent_timeout: "30s"
        }

    - apply_adaptive_configuration:
        settings: "${optimal_settings}"
        scope: "system_wide"
        backup_current: true

    - condition:
        if: "${configuration_changed}"
        then:
          - tamr.log: { event: "adaptive_config_applied", changes: "${configuration_changes}", performance_impact: "${estimated_improvement}" }
        else:
          - tamr.log: { event: "adaptive_config_unchanged", reason: "current_settings_optimal" }

  validate_system_readiness:
    - run_health_checks:
        agents: "all_critical"
        services: ["database", "logging", "monitoring"]
        timeout: "60s"

    - check_system_responsiveness:
        test_operations: ["agent_creation", "file_operation", "database_query"]
        performance_baseline: true

    - validate_policy_enforcement:
        test_scenarios: ["access_control", "resource_limits", "error_handling"]

    - calculate_readiness_score:
        health: "${health_check_results}"
        responsiveness: "${responsiveness_results}"
        policy_compliance: "${policy_validation_results}"

    - condition:
        if: "${readiness_score < 0.8}"
        then:
          - tamr.log: { event: "system_not_ready", score: "${readiness_score}", issues: "${readiness_issues}" }
          - run: ["r/system/bootstrap-policies.r", "address_readiness_issues"]
        else:
          - tamr.log: { event: "system_ready", score: "${readiness_score}", startup_complete: true }

  start_continuous_monitoring:
    - configure_monitoring_policies:
        based_on: "${system_context}"
        adaptive_intervals: true
        escalation_rules: true

    - start_background_monitors:
        monitors: [
          { name: "health_monitor", interval: "${monitoring_config.health_interval}", agent: "system-doctor" },
          { name: "performance_monitor", interval: "${monitoring_config.perf_interval}", agent: "pesr-agent" },
          { name: "security_monitor", interval: "${monitoring_config.security_interval}", agent: "security-agent" }
        ]

    - setup_alerting_channels:
        channels: ["console", "log", "admin_notification"]
        severity_routing: {
          critical: ["console", "admin_notification"],
          warning: ["log", "admin_notification"],
          info: ["log"]
        }

    - tamr.log: { event: "monitoring_started", monitors: "${background_monitors.length}", channels: "${alerting_channels.length}" }

  setup_signal_handling:
    # All signal handling logic moved from TypeScript
    - register_critical_signals:
        signals: ["SIGINT", "SIGTERM", "SIGUSR1", "SIGUSR2"]
        loop:
          forEach: "${signals}"
          do:
            - bootstrap.registerSignalHandler: {
                signal: "${item}",
                rlang_file: "r/system/bootstrap-policies.r",
                operation: "handle_signal"
              }

    - register_error_handlers:
        error_types: ["uncaughtException", "unhandledRejection"]
        loop:
          forEach: "${error_types}"
          do:
            - bootstrap.registerSignalHandler: {
                signal: "${item}",
                rlang_file: "r/system/bootstrap-policies.r",
                operation: "handle_fatal_error"
              }

    - tamr.log: { event: "signal_handlers_registered", count: "${signals.length + error_types.length}" }

  handle_signal:
    # Signal handling logic moved from TypeScript bootstrap.ts
    - determine_signal_action:
        signal: "${input.signal}"
        actions: {
          "SIGINT": "graceful_shutdown",
          "SIGTERM": "graceful_shutdown",
          "SIGUSR1": "reload_config",
          "SIGUSR2": "toggle_debug_mode"
        }

    - tamr.log: { event: "signal_received", signal: "${input.signal}", action: "${determined_action}" }

    - condition:
        switch: "${determined_action}"
        cases:
          - graceful_shutdown:
              - run: ["r/system/bootstrap-policies.r", "graceful_shutdown"]
          - reload_config:
              - run: ["r/system/bootstrap-policies.r", "reload_system_config"]
          - toggle_debug_mode:
              - run: ["r/system/bootstrap-policies.r", "toggle_debug_logging"]

  handle_fatal_error:
    # Fatal error handling logic moved from TypeScript
    - tamr.log: {
        event: "fatal_error_occurred",
        error: "${input.error}",
        stack: "${input.stack}",
        type: "${input.type}"
      }

    - attempt_error_recovery:
        error_type: "${input.type}"
        error_message: "${input.error}"

    - condition:
        if: "${error_recovery.possible}"
        then:
          - execute_recovery_plan: { plan: "${error_recovery.plan}" }
          - condition:
              if: "${recovery_execution.success}"
              then:
                - tamr.log: { event: "error_recovery_success", recovery_plan: "${error_recovery.plan}" }
              else:
                - run: ["r/system/bootstrap-policies.r", "emergency_shutdown"]
        else:
          - run: ["r/system/bootstrap-policies.r", "emergency_shutdown"]

  memory_cleanup:
    # Memory management logic moved from TypeScript
    - check_memory_usage: {}
    - condition:
        if: "${memory_usage.heap_used_percent > 85}"
        then:
          - force_garbage_collection: {}
          - check_memory_after_gc: {}
          - condition:
              if: "${memory_after_gc.heap_used_percent > 80}"
              then:
                - tamr.log: { event: "memory_pressure_detected", usage: "${memory_after_gc}" }
                - run: ["r/agents/system-doctor.r", "investigate_memory_leak"]

    - cleanup_temporary_data: { max_age: "1h" }
    - tamr.log: { event: "memory_cleanup_complete", before: "${memory_usage}", after: "${current_memory}" }
    - tamr.log: { event: "graceful_shutdown_initiated", timestamp: "${timestamp}" }

    - stop_background_monitors: { monitors: "all" }
    - stop_agents: { agents: "all", timeout: "30s" }
    - flush_logs: { wait_for_completion: true }
    - close_database_connections: { timeout: "10s" }

    - tamr.log: { event: "graceful_shutdown_complete", duration: "${shutdown_duration}" }
    - bootstrap.exitProcess: { code: 0 }

  emergency_fallback:
    - tamr.log: { event: "emergency_fallback_triggered", reason: "${fallback_reason}" }

    - disable_non_critical_systems: {}
    - start_minimal_safe_mode: {
        agents: ["system-doctor"],
        monitoring: "basic",
        logging: "error_only"
      }

    - prompt.user:
        to: "system_admin"
        message: "🚨 EMERGENCY: System entered fallback mode. Critical systems only."
        buttons: ["Diagnose", "Restart", "Safe Shutdown"]

  abort_with_diagnostics:
    - tamr.log: { event: "bootstrap_abort", reason: "${abort_reason}", diagnostics: "${system_diagnostics}" }

    - generate_diagnostic_report: {
        include: ["environment_check", "dependency_status", "error_logs", "system_state"]
      }

    - bootstrap.writeFile: {
        path: "logs/bootstrap_failure_${timestamp}.json",
        content: "${diagnostic_report}"
      }

    - prompt.user:
        to: "system_admin"
        message: "💥 BOOTSTRAP FAILED: ${abort_reason}. Diagnostic report saved."
        buttons: ["View Diagnostics", "Retry Bootstrap", "Manual Recovery"]

    - bootstrap.exitProcess: { code: 1 }

  optimize_startup_sequence:
    # Self-modification operation - analyzes startup performance and improves policies
    - analyze_startup_history:
        period: "-30d"
        metrics: ["total_time", "agent_startup_times", "failure_rates", "resource_usage"]

    - identify_optimization_opportunities:
        analysis: "${startup_history}"
        threshold: { improvement_potential: 0.15 }

    - condition:
        if: "${optimization_opportunities.length > 0}"
        then:
          - generate_optimized_policies:
              opportunities: "${optimization_opportunities}"
              current_policies: "${current_bootstrap_policies}"

          - test_optimized_sequence:
              new_policies: "${optimized_policies}"
              test_environment: "sandbox"

          - condition:
              if: "${test_results.improvement > 0.1}"
              then:
                - backup_current_policies: { backup_path: "r/system/backup/bootstrap-policies-${timestamp}.r" }
                - self.modify: { changes: { operations: "${optimized_policies.operations}" } }
                - tamr.log: { event: "bootstrap_self_optimized", improvement: "${test_results.improvement}" }
              else:
                - tamr.log: { event: "optimization_rejected", reason: "insufficient_improvement", improvement: "${test_results.improvement}" }

  adaptive_monitoring_adjustment:
    # Continuously adjusts monitoring based on system health and load
    - assess_current_load:
        metrics: ["cpu_usage", "memory_usage", "disk_io", "network_io", "active_agents"]

    - calculate_adaptive_intervals:
        base_intervals: "${monitoring_config.base_intervals}"
        load_factor: "${current_load.normalized_score}"
        health_factor: "${system_health.score}"
        formula: "base_interval * (1 + load_factor) * (2 - health_factor)"

    - update_monitoring_configuration:
        new_intervals: "${adaptive_intervals}"
        apply_immediately: true

    - tamr.log: {
        event: "monitoring_adjusted",
        load_score: "${current_load.normalized_score}",
        health_score: "${system_health.score}",
        new_intervals: "${adaptive_intervals}"
      }

concern:
  if: "${startup_failure_rate > 0.1 || average_startup_time > 60000}"
  priority: 1
  action:
    - tamr.log: { event: "bootstrap_performance_concern", failure_rate: "${startup_failure_rate}", avg_time: "${average_startup_time}" }
    - run: ["r/system/bootstrap-policies.r", "optimize_startup_sequence"]

# Bootstrap configuration that can be modified by the system itself
bootstrap_config:
  performance_targets:
    max_startup_time: 30000  # 30 seconds
    max_failure_rate: 0.05   # 5%
    min_readiness_score: 0.8

  adaptive_settings:
    enable_self_optimization: true
    optimization_frequency: "weekly"
    test_optimizations: true
    rollback_on_failure: true

  monitoring_defaults:
    health_check_interval: "5m"
    performance_check_interval: "1m"
    log_analysis_interval: "10m"

  agent_startup:
    parallel_groups: [
      ["system-doctor", "pesr-agent"],  # Core monitoring agents start together
      ["ordr-agent"],                   # Orchestration agent starts after monitoring
      ["nlp-router", "capability-index"] # User-facing agents start last
    ]
    inter_group_delay: "2s"
    agent_timeout: "30s"
