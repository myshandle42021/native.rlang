# r/system/rcd-capability-resolver.r
# ALL complex RCD logic lives here - TypeScript just delegates to this file
# This maintains the 90/10 rule: TypeScript = infrastructure, R-lang = logic

self:
  id: "rcd-capability-resolver"
  intent: "Handle all complex RCD capability resolution logic that TypeScript delegates to"
  version: "1.0.0"
  template: "system_core"

aam:
  require_role: "system"
  allow_actions: ["resolve_capability", "register_capability", "resolve_file_path", "optimize_resolution"]

operations:
  # Handles all capability resolution requests from TypeScript
  resolve_capability:
    - validate_capability_request: {
        capability: "${input.capability}",
        consumer: "${input.consumer || context.agentId}",
        requirements: "${input.requirements || {}}"
      }

    # Check cache first for performance
    - check_capability_cache: {
        capability: "${validated_request.capability}",
        consumer: "${validated_request.consumer}",
        cache_timeout: 300000
      }

    - condition:
        if: "${cache_result.hit && cache_result.valid}"
        then:
          - log_cache_hit: { capability: "${validated_request.capability}" }
          - return: {
              provider: "${cache_result.provider}",
              interface: "${cache_result.interface}",
              cached: true,
              resolution_time: "${cache_result.resolution_time}"
            }

    # Query RCD for providers
    - rcd.query_capability_providers: {
        capability: "${validated_request.capability}",
        min_performance_score: 0.7,
        status: "active"
      }

    - condition:
        if: "${available_providers.length == 0}"
        then:
          - handle_no_providers: {
              capability: "${validated_request.capability}",
              consumer: "${validated_request.consumer}"
            }
          - return: {
              error: "no_providers_available",
              fallback_required: true
            }

    # Score and select best provider
    - score_providers: {
        providers: "${available_providers}",
        consumer: "${validated_request.consumer}",
        requirements: "${validated_request.requirements}"
      }

    - select_optimal_provider: {
        scored_providers: "${provider_scores}",
        algorithm: "weighted_performance"
      }

    # Create and cache the binding
    - create_capability_binding: {
        provider: "${selected_provider}",
        consumer: "${validated_request.consumer}",
        capability: "${validated_request.capability}"
      }

    - cache_resolution: {
        capability: "${validated_request.capability}",
        consumer: "${validated_request.consumer}",
        provider: "${selected_provider}",
        binding: "${capability_binding}"
      }

    - log_successful_resolution: {
        capability: "${validated_request.capability}",
        provider: "${selected_provider}",
        method: "rcd_resolution"
      }

    - return: {
        provider: "${selected_provider.file_path}",
        interface: "${capability_binding.interface}",
        cached: false,
        resolution_time: "${resolution_duration}"
      }

  # Handles capability registration from TypeScript runtime
  register_capability:
    - validate_registration: {
        module: "${input.module}",
        function: "${input.function}",
        provider: "${input.provider}"
      }

    # Store in RCD system
    - rcd.store_capability: {
        capability_name: "${input.module}_${input.function}",
        provider_files: ["${input.provider}"],
        interface_spec: {
          module: "${input.module}",
          function: "${input.function}",
          provider_path: "${input.provider}"
        },
        stability_rating: 0.8,
        performance_score: 0.7
      }

    # Update capability index
    - update_capability_index: {
        capability: "${input.module}_${input.function}",
        provider: "${input.provider}",
        registration_time: "${timestamp}"
      }

    - return: {
        registered: true,
        capability: "${input.module}_${input.function}"
      }

  # Handles file path resolution from interpreter
  resolve_file_path:
    - validate_file_request: {
        file_id: "${input.file_id}",
        client_id: "${input.client_id}"
      }

    # Check file resolution cache
    - check_file_cache: {
        file_id: "${input.file_id}",
        client_id: "${input.client_id}",
        cache_timeout: 600000  # 10 minutes for files
      }

    - condition:
        if: "${file_cache.hit}"
        then:
          - return: {
              resolved_path: "${file_cache.path}",
              cached: true
            }

    # Query RCD for file location
    - rcd.query_file_metadata: {
        file_pattern: "${input.file_id}",
        client_id: "${input.client_id}",
        status: "active"
      }

    - condition:
        if: "${file_metadata.length > 0}"
        then:
          - select_best_file_match: {
              matches: "${file_metadata}",
              client_preference: "${input.client_id}",
              version_preference: "latest"
            }
          - cache_file_resolution: {
              file_id: "${input.file_id}",
              client_id: "${input.client_id}",
              resolved_path: "${best_match.file_path}"
            }
          - return: {
              resolved_path: "${best_match.file_path}",
              cached: false
            }

    # File not found in RCD - let TypeScript handle fallback
    - return: { resolved_path: null }

  # Complex provider scoring algorithm
  score_providers:
    - loop:
        forEach: "${input.providers}"
        do:
          # Performance scoring (40%)
          - calculate_performance_score: {
              provider: "${item}",
              metrics: ["response_time", "success_rate", "throughput"],
              time_window: "7d"
            }

          # Compatibility scoring (30%)
          - calculate_compatibility_score: {
              provider: "${item}",
              consumer: "${input.consumer}",
              interface_requirements: "${input.requirements}"
            }

          # Load balancing (20%)
          - calculate_load_score: {
              provider: "${item}",
              current_connections: "${provider_current_load}",
              max_capacity: "${provider_capacity}"
            }

          # Reliability scoring (10%)
          - calculate_reliability_score: {
              provider: "${item}",
              uptime_history: "30d",
              failure_patterns: "${historical_failures}"
            }

          # Weighted composite score
          - calculate_composite_score: {
              performance: "${performance_score}",
              compatibility: "${compatibility_score}",
              load: "${load_score}",
              reliability: "${reliability_score}",
              weights: {
                performance: 0.4,
                compatibility: 0.3,
                load: 0.2,
                reliability: 0.1
              }
            }

    - return: "${provider_scores}"

  # Handle missing providers - attempt auto-generation
  handle_no_providers:
    - tamr.log: {
        event: "no_providers_available",
        capability: "${input.capability}",
        consumer: "${input.consumer}"
      }

    # Check if this is a known capability that's temporarily down
    - rcd.query_capability_definition: {
        capability: "${input.capability}"
      }

    - condition:
        if: "${capability_definition.exists}"
        then:
          # Known capability - providers might be down
          - check_provider_health: {
              capability: "${input.capability}"
            }
          - schedule_health_recovery: {
              capability: "${input.capability}",
              retry_interval: "60s"
            }
        else:
          # Unknown capability - try auto-generation
          - analyze_capability_requirements: {
              capability: "${input.capability}",
              consumer: "${input.consumer}",
              usage_context: "${context}"
            }
          - condition:
              if: "${capability_analysis.can_generate}"
              then:
                - trigger_auto_generation: {
                    capability: "${input.capability}",
                    requirements: "${capability_analysis.requirements}",
                    urgency: "high"
                  }
              else:
                - escalate_missing_capability: {
                    capability: "${input.capability}",
                    consumer: "${input.consumer}",
                    analysis: "${capability_analysis}"
                  }

  # Performance optimization for resolution system
  optimize_resolution_performance:
    - analyze_resolution_patterns: {
        time_window: "24h",
        metrics: ["resolution_frequency", "cache_hit_rate", "provider_selection_accuracy"]
      }

    # Optimize cache strategy
    - optimize_cache_policies: {
        current_hit_rate: "${resolution_patterns.cache_hit_rate}",
        memory_usage: "${cache_memory_usage}",
        target_hit_rate: 0.85
      }

    # Optimize provider selection
    - analyze_provider_selection_effectiveness: {
        selection_history: "${provider_selections}",
        success_metrics: ["binding_success", "performance_satisfaction"]
      }

    - condition:
        if: "${selection_effectiveness.accuracy < 0.9}"
        then:
          - retrain_selection_algorithm: {
              training_data: "${selection_history}",
              target_accuracy: 0.95,
              algorithm_type: "weighted_learning"
            }

    # Pre-cache hot capabilities
    - identify_hot_capabilities: {
        resolution_patterns: "${resolution_patterns}",
        frequency_threshold: 10
      }

    - pre_cache_capabilities: {
        hot_capabilities: "${hot_capabilities}",
        cache_strategy: "predictive"
      }

    - return: {
        optimizations_applied: "${optimization_results}",
        performance_improvement: "${expected_improvement}"
      }

  # Monitor and learn from resolution patterns
  learn_from_resolutions:
    - collect_resolution_metrics: {
        time_window: "1h",
        include_failures: true
      }

    # Analyze success patterns
    - identify_success_patterns: {
        successful_resolutions: "${resolution_metrics.successful}",
        pattern_types: ["provider_selection", "timing_patterns", "consumer_patterns"]
      }

    # Analyze failure patterns
    - identify_failure_patterns: {
        failed_resolutions: "${resolution_metrics.failed}",
        failure_types: ["provider_unavailable", "interface_mismatch", "performance_timeout"]
      }

    # Update learning models
    - update_resolution_models: {
        success_patterns: "${success_patterns}",
        failure_patterns: "${failure_patterns}",
        model_type: "adaptive_learning"
      }

    # Suggest system improvements
    - generate_improvement_suggestions: {
        pattern_analysis: "${pattern_analysis}",
        current_performance: "${system_performance}",
        improvement_targets: ["speed", "accuracy", "reliability"]
      }

    - condition:
        if: "${improvement_suggestions.length > 0 && improvement_suggestions[0].confidence > 0.8}"
        then:
          - apply_safe_improvements: {
              suggestions: "${improvement_suggestions}",
              safety_threshold: 0.9
            }

concern:
  if: "${resolution_failure_rate > 0.05 || cache_hit_rate < 0.7}"
  priority: 1
  action:
    - tamr.log: {
        event: "rcd_resolver_performance_degraded",
        failure_rate: "${resolution_failure_rate}",
        cache_hit_rate: "${cache_hit_rate}"
      }
    - run: ["rcd-capability-resolver.r", "optimize_resolution_performance"]
