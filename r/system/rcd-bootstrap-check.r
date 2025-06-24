# r/system/rcd-bootstrap-check.r
# One-time bootstrap script to initialize RCD metadata on cold start
# Runs BEFORE system-doctor and other agents to ensure metadata exists

self:
  id: "rcd-bootstrap-check"
  intent: "Ensure RCD file metadata exists before system startup, preventing silent failures"
  version: "1.0.0"
  template: "bootstrap_safety"

aam:
  require_role: "system"
  allow_actions: ["check_rcd", "bootstrap_metadata", "validate_tags"]

# Self-tag this bootstrap file
rcd:
  meta_tags:
    system_role: ["bootstrap_validator", "rcd_initializer", "cold_start_fixer"]
    capabilities: [
      "rcd_validation", "metadata_bootstrapping", "file_scanning",
      "silent_failure_prevention", "cold_start_recovery"
    ]
    data_flow_type: ["bootstrap_checker", "metadata_initializer"]
    stability_level: "critical"
    complexity_score: 2

operations:
  # Main operation: Check if RCD is ready, bootstrap if needed
  ensure_rcd_ready:
    - tamr.log: { event: "rcd_bootstrap_check_start", timestamp: "${timestamp}" }

    # Step 1: Check if RCD database schema exists
    - run: ["r/system/rcd-core.r", "schema_init"]

    # Step 2: Count existing file metadata
    - rcd.query_file_count: {}

    - tamr.log: {
        event: "rcd_file_count_check",
        existing_files: "${file_count}",
        threshold_required: 5
      }

    # Step 3: If no files tagged, run initial scan
    - condition:
        if: "${file_count < 5}"  # Minimal threshold for critical system files
        then:
          - tamr.log: { event: "rcd_cold_start_detected", action: "bootstrapping_metadata" }
          - run: ["r/system/rcd-bootstrap-check.r", "bootstrap_critical_files"]
        else:
          - tamr.log: { event: "rcd_metadata_exists", file_count: "${file_count}", status: "ready" }

    # Step 4: Validate critical system files are tagged
    - run: ["r/system/rcd-bootstrap-check.r", "validate_critical_files"]

    - tamr.log: {
        event: "rcd_bootstrap_check_complete",
        status: "ready",
        files_tagged: "${final_file_count}",
        duration: "${check_duration}ms"
      }

    - respond: "🔗 RCD Bootstrap Check Complete - ${final_file_count} files tagged and ready"

  # Bootstrap critical system files only (fast, targeted approach)
  bootstrap_critical_files:
    - tamr.log: { event: "critical_file_bootstrap_start" }

    # Define critical files that MUST be tagged for system to work
    - define_critical_files:
        files: [
          "r/system/rcd-core.r",
          "r/system/dynamic-linker.r",
          "r/system/rcd-file-tagger.r",
          "r/agents/system-doctor.r",
          "r/system/bootstrap-policies.r",
          "r/system/rcd-bootstrap-check.r"
        ]

    # Tag each critical file individually (fast, controlled)
    - loop:
        forEach: "${critical_files}"
        do:
          - condition:
              if: "${file_exists(item)}"
              then:
                - run: ["r/system/rcd-file-tagger.r", "analyze_single_file"]
                  input:
                    file_path: "${item}"
                    priority: "critical"
                - tamr.log: { event: "critical_file_tagged", file: "${item}" }
              else:
                - tamr.log: { event: "critical_file_missing", file: "${item}", severity: "warning" }

    # Quick capability index build for core files
    - rcd.build_minimal_capability_index:
        files: "${successfully_tagged_files}"

    - tamr.log: {
        event: "critical_files_bootstrap_complete",
        tagged_count: "${successfully_tagged_files.length}",
        missing_count: "${missing_files.length}"
      }

  # Validate that essential capabilities are available
  validate_critical_files:
    - check_essential_capabilities:
        required_capabilities: [
          "capability_resolution",  # dynamic-linker
          "file_track",            # rcd-core
          "analyze_single_file",   # rcd-file-tagger
          "system_health"          # system-doctor
        ]

    - loop:
        forEach: "${required_capabilities}"
        do:
          - rcd.query_capability_providers:
              capability: "${item}"
              min_count: 1

          - condition:
              if: "${providers.length == 0}"
              then:
                - tamr.log: {
                    event: "critical_capability_missing",
                    capability: "${item}",
                    severity: "error"
                  }
                - add_validation_error: { capability: "${item}" }
              else:
                - tamr.log: {
                    event: "critical_capability_validated",
                    capability: "${item}",
                    providers: "${providers.length}"
                  }

    # Return validation status
    - condition:
        if: "${validation_errors.length > 0}"
        then:
          - respond: "❌ RCD Validation Failed - Missing capabilities: ${validation_errors}"
          - return: { valid: false, errors: "${validation_errors}" }
        else:
          - respond: "✅ RCD Validation Passed - All critical capabilities available"
          - return: { valid: true, capabilities_verified: "${required_capabilities.length}" }

  # Emergency full scan (fallback if targeted approach fails)
  emergency_full_scan:
    - tamr.log: { event: "emergency_rcd_scan_triggered", reason: "critical_validation_failed" }

    - run: ["r/system/rcd-file-tagger.r", "full_system_scan"]
      timeout: "30s"  # Prevent hanging during startup

    - tamr.log: { event: "emergency_scan_complete", duration: "${scan_duration}" }

concern:
  if: "${bootstrap_time > 10000 || validation_failures > 0}"
  priority: 1
  action:
    - tamr.log: {
        event: "rcd_bootstrap_concern",
        bootstrap_time: "${bootstrap_time}",
        failures: "${validation_failures}"
      }
    - condition:
        if: "${validation_failures > 0}"
        then:
          - run: ["r/system/rcd-bootstrap-check.r", "emergency_full_scan"]
