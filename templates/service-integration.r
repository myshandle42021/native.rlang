# r/templates/service-integration.r
# Universal Service Integration Generator - Auto-generates TypeScript modules from API discovery
# CRITICAL FIX #3: Fixed generation paths to match step-executor expectations

self:
  id: "service-integration"
  intent: "Automatically generate TypeScript service modules from API discovery and analysis"
  version: "1.0.0"
  template: "universal_generator"

aam:
  require_role: "system"
  allow_actions: ["generate_service", "analyze_api", "create_template", "validate_integration"]

dependencies:
  services: ["tamr", "rcd", "infer", "claude_api"]
  templates: ["service-template.ts"]
  agents: ["service-discovery"]

operations:
  initialize:
    - tamr.log: { event: "service_integration_started", timestamp: "${timestamp}" }
    - load_universal_template: {}
    - initialize_generation_cache: {}
    - setup_output_directories: {}
    - respond: "🔧 Service Integration Generator initialized - Auto-generation ready"

  # CRITICAL FIX #3: Main auto-generation entry point with corrected paths
  auto_generate_service_module:
    - tamr.log: {
        event: "auto_generation_requested",
        service: "${input.service_name}",
        function: "${input.required_function}",
        context: "${input.context.user || 'system'}"
      }

    # Phase 1: Check if we have existing config
    - check_existing_service_config: {
        service_name: "${input.service_name}"
      }

    - condition:
        if: "${existing_config.found}"
        then:
          - generate_from_existing_config: {
              service_name: "${input.service_name}",
              config: "${existing_config.data}",
              required_function: "${input.required_function}"
            }
        else:
          - discover_and_generate_service: {
              service_name: "${input.service_name}",
              required_function: "${input.required_function}",
              context: "${input.context}"
            }

    # CRITICAL FIX #3: Generate to correct path that step-executor expects
    - generate_typescript_module: {
        template: "${service_template}",
        config: "${final_service_config}",
        output_path: "utils/${input.service_name}.ts",  # FIX: Changed from templates/generated-services/
        service_name: "${input.service_name}",
        required_function: "${input.required_function}",
        metadata: "${generation_metadata}"
      }

    # Store generation record in RCD system
    - store_generated_service: {
        service_name: "${input.service_name}",
        file_path: "utils/${input.service_name}.ts",  # FIX: Match output path
        generation_method: "universal_template",
        config_source: "${config_source}",
        required_function: "${input.required_function}",
        timestamp: "${timestamp}",
        success: true,
        user_context: "${input.context.user || 'system'}"
      }

    # Update capability registry
    - rcd.store_capability_provider: {
        capability: "${input.service_name}_${input.required_function}",
        provider_files: ["utils/${input.service_name}.ts"],  # FIX: Match path
        category: "integration",
        stability_rating: 0.8,
        interface_spec: {
          module: "${input.service_name}",
          function: "${input.required_function}",
          auto_generated: true
        }
      }

    - tamr.log: {
        event: "service_module_generated",
        service: "${input.service_name}",
        output_file: "utils/${input.service_name}.ts",  # FIX: Log correct path
        functions_created: "${generation_result.functions}",
        generation_time: "${generation_duration}"
      }

    - return: {
        generated: true,
        file_path: "utils/${input.service_name}.ts",  # FIX: Return correct path
        functions_created: "${generation_result.functions}",
        auth_type: "${final_service_config.auth_type}",
        service_ready: true
      }

  # Generate from existing discovered configuration
  generate_from_existing_config:
    - tamr.log: {
        event: "generating_from_existing_config",
        service: "${input.service_name}"
      }

    - validate_existing_config: {
        config: "${input.config}",
        required_function: "${input.required_function}"
      }

    - enhance_config_for_generation: {
        base_config: "${input.config}",
        required_function: "${input.required_function}",
        template_requirements: "${universal_template_spec}"
      }

    - return: {
        final_service_config: "${enhanced_config}",
        config_source: "existing_discovery",
        service_template: "${universal_template_spec}"
      }

  # Discover service and generate configuration
  discover_and_generate_service:
    - tamr.log: {
        event: "discovering_service",
        service: "${input.service_name}"
      }

    # Step 1: Intelligent Service Discovery
    - run: ["r/templates/service-discovery.r", "discover_service_api", {
        service_name: "${input.service_name}",
        required_function: "${input.required_function}",
        discovery_depth: "comprehensive"
      }]

    # Step 2: Generate Universal Configuration
    - generate_service_configuration: {
        analysis: "${service_discovery_result.analysis}",
        service_name: "${input.service_name}",
        required_function: "${input.required_function}"
      }

    # Step 3: Validate & Store Configuration
    - validate_and_store_config: {
        service_name: "${input.service_name}",
        generated_config: "${service_configuration}",
        discovery_metadata: "${service_discovery_result.metadata}"
      }

    - return: {
        final_service_config: "${service_configuration}",
        config_source: "auto_discovery",
        service_template: "${universal_template_spec}",
        discovery_confidence: "${service_discovery_result.confidence}"
      }

  # CRITICAL FIX #3: Updated generation function with correct paths
  generate_typescript_module:
    - load_universal_service_template: {
        template_path: "templates/service-template.ts"
      }

    - prepare_template_variables: {
        service_name: "${input.service_name}",
        config: "${input.config}",
        required_function: "${input.required_function}",
        output_path: "${input.output_path}"  # Use the corrected path
      }

    - render_template: {
        template: "${universal_service_template}",
        variables: "${template_variables}",
        target_file: "${input.output_path}"  # FIX: Generate to utils/ directory
      }

    # CRITICAL FIX #3: Ensure directory exists
    - ensure_output_directory: {
        directory: "utils"  # FIX: Ensure utils directory exists
      }

    # Write the generated file
    - write_generated_file: {
        content: "${rendered_template}",
        file_path: "${input.output_path}",  # FIX: Write to correct path
        service_name: "${input.service_name}"
      }

    # Validate generated module
    - validate_generated_module: {
        file_path: "${input.output_path}",
        required_exports: ["${input.required_function}", "authenticate", "makeRequest"],
        syntax_check: true
      }

    - return: {
        generated_file: "${input.output_path}",  # FIX: Return correct path
        functions: "${validation_result.exported_functions}",
        syntax_valid: "${validation_result.syntax_ok}",
        file_size: "${validation_result.file_size}"
      }

  # Check for existing service configurations
  check_existing_service_config:
    - rcd.query: |
        SELECT configuration, discovery_method, confidence_score, created_at
        FROM discovered_service_configs
        WHERE service_name = '${input.service_name}'
        AND validation_passed = true
        ORDER BY created_at DESC
        LIMIT 1

    - condition:
        if: "${query_result.length > 0}"
        then:
          - return: {
              found: true,
              data: "${query_result[0].configuration}",
              discovery_method: "${query_result[0].discovery_method}",
              confidence: "${query_result[0].confidence_score}"
            }
        else:
          - return: {
              found: false,
              message: "No existing configuration found - will discover"
            }

  # Service discovery integration
  discover_service_api:
    - run: ["r/templates/service-discovery.r", "discover_service_intelligence", {
        service_name: "${input.service_name}",
        required_function: "${input.required_function}",
        discovery_method: "comprehensive_analysis"
      }]

    - return: {
        analysis: "${service_discovery_intelligence}",
        metadata: "${discovery_metadata}",
        confidence: "${discovery_confidence}"
      }

  # Generate service configuration from analysis
  generate_service_configuration:
    - tamr.log: { event: "config_generation_started", service: "${input.service_name}" }

    # Load universal template requirements
    - load_template_specification: {
        template: "service-template.ts",
        required_fields: ["auth_type", "base_url", "endpoints", "headers"]
      }

    # Map analysis to template format
    - map_analysis_to_template: {
        analysis: "${input.analysis}",
        template_spec: "${template_specification}",
        service_name: "${input.service_name}"
      }

    # Generate specific endpoint mappings
    - generate_endpoint_mappings: {
        detected_endpoints: "${input.analysis.endpoints}",
        required_function: "${input.required_function}",
        service_patterns: "${input.analysis.api_structure}"
      }

    # Create authentication configuration
    - generate_auth_configuration: {
        auth_analysis: "${input.analysis.authentication}",
        service_name: "${input.service_name}"
      }

    # Generate error handling patterns
    - generate_error_handling: {
        error_analysis: "${input.analysis.error_handling}",
        rate_limit_info: "${input.analysis.api_structure.rate_limiting}"
      }

    # Assemble final configuration
    - assemble_service_config: {
        service_name: "${input.service_name}",
        auth_config: "${auth_configuration}",
        api_config: "${mapped_template}",
        endpoint_mappings: "${endpoint_mappings}",
        error_handling: "${error_handling_config}",
        metadata: {
          generated_by: "dynamic_discovery",
          source_confidence: "${input.analysis.confidence}",
          generation_timestamp: "${timestamp}",
          sources: "${input.analysis.sources}"
        }
      }

    - tamr.log: {
        event: "config_generation_complete",
        service: "${input.service_name}",
        config_size: "${assembled_config.size}",
        endpoints_mapped: "${endpoint_mappings.count}"
      }

    - return: {
        service_configuration: "${assembled_config}",
        endpoints_count: "${endpoint_mappings.count}",
        generation_metadata: "${generation_metadata}"
      }

  # Validate and store configuration
  validate_and_store_config:
    - tamr.log: { event: "config_validation_started", service: "${input.service_name}" }

    # Validate against template requirements
    - validate_template_compatibility: {
        config: "${input.generated_config}",
        template_requirements: "${universal_template_requirements}"
      }

    # Test configuration with mock data
    - test_config_structure: {
        config: "${input.generated_config}",
        test_scenarios: ["auth_flow", "basic_request", "error_handling"]
      }

    # Store in RCD system
    - rcd.write: {
        table: "discovered_service_configs",
        data: {
          service_name: "${input.service_name}",
          configuration: "${input.generated_config}",
          discovery_method: "comprehensive_analysis",
          confidence_score: "${input.discovery_metadata.confidence}",
          validation_passed: "${validation_result.passed}",
          source_urls: "${input.discovery_metadata.sources}",
          created_at: "${timestamp}",
          auto_generated: true
        }
      }

    # Log learning event
    - rcd.log_learning_event: {
        event_type: "service_discovery_success",
        context_data: {
          service: "${input.service_name}",
          discovery_quality: "${validation_result.quality_score}",
          reusability_score: "${validation_result.reusability}"
        },
        outcome: "success",
        impact_score: 0.3
      }

    - tamr.log: {
        event: "service_config_stored",
        service: "${input.service_name}",
        validation_passed: "${validation_result.passed}",
        storage_id: "${rcd_storage_result.id}"
      }

    - return: {
        stored: true,
        config_id: "${rcd_storage_result.id}",
        validation: "${validation_result}",
        ready_for_generation: "${validation_result.passed}"
      }

  # CRITICAL FIX #3: Enhanced template rendering with correct paths
  render_template:
    - load_template_content: {
        template: "${input.template}"
      }

    - substitute_template_variables: {
        template_content: "${template_content}",
        variables: "${input.variables}",
        advanced_substitution: true
      }

    - validate_rendered_output: {
        rendered_content: "${substituted_template}",
        expected_structure: "typescript_module"
      }

    - return: {
        rendered_template: "${substituted_template}",
        validation_passed: "${validation_result.passed}",
        template_size: "${substituted_template.length}"
      }

  # CRITICAL FIX #3: File writing with proper directory handling
  write_generated_file:
    - create_file_backup: {
        target_path: "${input.file_path}",
        backup_existing: true
      }

    # CRITICAL FIX #3: Ensure correct directory structure
    - ensure_directory_structure: {
        file_path: "${input.file_path}",
        create_missing: true
      }

    - write_file_content: {
        path: "${input.file_path}",
        content: "${input.content}",
        encoding: "utf8",
        mode: "644"
      }

    - verify_file_written: {
        path: "${input.file_path}",
        expected_size: "${input.content.length}"
      }

    - tamr.log: {
        event: "file_written_successfully",
        path: "${input.file_path}",
        service: "${input.service_name}",
        file_size: "${verification_result.actual_size}"
      }

    - return: {
        written: true,
        file_path: "${input.file_path}",
        file_size: "${verification_result.actual_size}",
        backup_created: "${backup_result.created}"
      }

  # Enhanced validation for generated modules
  validate_generated_module:
    - check_file_exists: {
        path: "${input.file_path}"
      }

    - analyze_typescript_syntax: {
        file_path: "${input.file_path}",
        check_exports: "${input.required_exports}",
        validate_imports: true
      }

    - test_module_loading: {
        file_path: "${input.file_path}",
        test_mode: "syntax_only"
      }

    - extract_exported_functions: {
        file_path: "${input.file_path}",
        typescript_analysis: "${syntax_analysis}"
      }

    - return: {
        syntax_ok: "${syntax_analysis.valid}",
        exported_functions: "${exported_functions.list}",
        file_size: "${file_stats.size}",
        import_errors: "${syntax_analysis.import_issues}",
        validation_score: "${overall_validation_score}"
      }

  # CRITICAL FIX #3: Store generation record with correct paths
  store_generated_service:
    - rcd.write: {
        table: "service_generation_history",
        data: {
          service_name: "${input.service_name}",
          file_path: "${input.file_path}",  # Now correctly points to utils/
          generation_method: "${input.generation_method}",
          success: "${input.success}",
          required_function: "${input.required_function}",
          config_source: "${input.config_source}",
          generation_duration: "${input.duration}",
          user_context: "${input.user_context}",
          created_at: "${timestamp}"
        }
      }

    # Log as learning event for system improvement
    - rcd.log_learning_event: {
        event_type: "service_generation",
        context_data: {
          service: "${input.service_name}",
          method: "${input.generation_method}",
          duration: "${input.duration}",
          success: "${input.success}",
          file_path: "${input.file_path}"  # Track correct path
        },
        outcome: "${input.success ? 'success' : 'failure'}",
        impact_score: "${input.success ? 0.3 : -0.2}"
      }

    - return: {
        recorded: true,
        record_id: "${generation_record.id}"
      }

  # CRITICAL FIX #3: Setup output directories during initialization
  setup_output_directories:
    - ensure_directory_exists: {
        directory: "utils",
        create_if_missing: true,
        permissions: "755"
      }

    - ensure_directory_exists: {
        directory: "templates",
        create_if_missing: true,
        permissions: "755"
      }

    - verify_write_permissions: {
        directories: ["utils", "templates"],
        required_permissions: ["read", "write", "execute"]
      }

    - tamr.log: {
        event: "output_directories_ready",
        directories: ["utils", "templates"],
        permissions_verified: "${permission_verification.passed}"
      }

    - return: {
        directories_ready: true,
        utils_directory: "utils",
        templates_directory: "templates"
      }

  # Load universal template specification
  load_universal_template:
    - read_template_file: {
        template_path: "templates/service-template.ts"
      }

    - parse_template_structure: {
        template_content: "${template_file_content}",
        extract_variables: true,
        validate_syntax: true
      }

    - identify_template_requirements: {
        template_structure: "${parsed_template}",
        required_variables: ["service_name", "auth_type", "base_url", "endpoints"]
      }

    - return: {
        universal_template_spec: "${template_requirements}",
        template_variables: "${required_variables}",
        template_valid: "${template_validation.passed}"
      }

  # Initialize generation cache for performance
  initialize_generation_cache:
    - setup_template_cache: {
        cache_size: 50,
        cache_ttl: 3600000  # 1 hour
      }

    - setup_config_cache: {
        cache_size: 100,
        cache_ttl: 1800000  # 30 minutes
      }

    - load_frequently_used_templates: {
        templates: ["service-template.ts"],
        preload: true
      }

    - return: {
        cache_initialized: true,
        template_cache_size: 50,
        config_cache_size: 100
      }

  # Continuous improvement and learning
  improve_generation_patterns:
    # Analyze success/failure patterns across generations
    - analyze_generation_success_patterns: {
        time_window: "30d",
        min_samples: 10
      }

    - identify_common_failure_points: {
        generation_history: "${generation_patterns}",
        failure_threshold: 0.1
      }

    - generate_improvement_recommendations: {
        success_patterns: "${success_analysis}",
        failure_patterns: "${failure_analysis}",
        focus_areas: ["template_accuracy", "discovery_quality", "generation_speed"]
      }

    - apply_approved_improvements: {
        recommendations: "${improvement_recommendations}",
        approval_threshold: 0.8
      }

    - return: {
        improvements_applied: "${applied_improvements.length}",
        success_rate_improvement: "${overall_improvement.success_rate}",
        generation_speed_improvement: "${overall_improvement.speed}"
      }

concern:
  if: "${generation_failure_rate > 0.1 || average_generation_time > 30000}"
  priority: 1
  action:
    - tamr.log: {
        event: "service_generation_performance_concern",
        failure_rate: "${generation_failure_rate}",
        avg_generation_time: "${average_generation_time}"
      }
    - run: ["service-integration.r", "improve_generation_patterns"]
    - condition:
        if: "${generation_degradation_critical}"
        then:
          - prompt.user:
              to: "system_admin"
              message: "🔧 Service Generation performance degraded. Failure rate: ${generation_failure_rate}"
              buttons: ["Optimize Templates", "Reset Cache", "Manual Review"]
