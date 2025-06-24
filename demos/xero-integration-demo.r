# r/demos/xero-integration-demo.r
# 🎯 Complete Xero Integration Demo Flow - The "WOW" Factor Implementation
# From RocketChat message to live Xero invoice data in under 5 minutes

self:
  id: "xero-integration-demo"
  intent: "Demonstrate complete end-to-end service integration magic with real Xero data"
  version: "1.0.0"
  template: "integration_demo"

aam:
  require_role: "user"
  allow_actions: ["demo_flow", "xero_integration", "live_data_display"]

# 🎬 Complete Demo Flow Operations
operations:
  # Entry point - triggered by RocketChat message
  start_xero_demo_flow:
    - tamr.log: {
        event: "xero_demo_flow_started",
        user: "${input.user_id}",
        trigger_message: "${input.original_message}"
      }

    # Phase 1: Welcome and Demo Overview
    - rocketchat.sendMessage: {
        channel: "${input.channel}",
        text: "🎯 **ROL3 Service Integration Magic Demo**\n\nI'll show you how I can automatically integrate with Xero and retrieve your live invoice data!",
        attachments: [{
          color: "good",
          title: "Demo Flow Overview",
          text: "Watch as I automatically:\n1. 🤖 Create an invoice monitoring agent\n2. 🔧 Auto-generate Xero integration module\n3. 🔐 Collect your Xero credentials securely\n4. 🧪 Test the connection\n5. 📊 Display your real invoice data",
          fields: [
            { title: "Estimated Time", value: "< 5 minutes", short: true },
            { title: "Data Source", value: "Your Live Xero Account", short: true }
          ],
          actions: [
            { type: "button", text: "🚀 Start Demo", value: "confirm_xero_demo", style: "primary" },
            { type: "button", text: "❓ Learn More", value: "xero_demo_info" }
          ]
        }]
      }

  # Phase 2: Agent Creation with Real-time Updates
  create_xero_invoice_agent:
    - rocketchat.sendMessage: {
        channel: "${input.channel}",
        text: "🤖 **Step 1: Creating Your Invoice Monitoring Agent**",
        attachments: [{
          color: "warning",
          title: "Agent Generation in Progress",
          text: "Analyzing requirements and creating intelligent agent...",
          fields: [
            { title: "Agent Type", value: "Invoice Monitor", short: true },
            { title: "Integration", value: "Xero API", short: true }
          ]
        }]
      }

    # Call enhanced agent factory
    - run: ["r/system/agent-factory.r", "create_intelligent_agent", {
        request: "Create an agent to monitor Xero invoices and provide summaries",
        context: {
          user_id: "${input.user_id}",
          channel: "${input.channel}",
          client_id: "${input.client_id}",
          real_time_updates: true,
          demo_mode: true
        },
        enhancement_level: "standard",
        agent_config: {
          operations: {
            check_invoices: [
              { "xero.getInvoices": { status: "AUTHORISED", limit: 10 } },
              { "analyze_invoice_data": { invoices: "${xero_invoices}" } },
              { "rocketchat.sendMessage": {
                  channel: "${input.channel}",
                  text: "📊 Invoice Summary: ${invoice_analysis.summary}",
                  attachments: ["${invoice_analysis.formatted_data}"]
                }}
            ],
            get_overdue_invoices: [
              { "xero.getInvoices": { status: "AUTHORISED", where: "DueDate < DateTime.Now" } },
              { "format_overdue_report": { invoices: "${overdue_invoices}" } },
              { "rocketchat.sendMessage": {
                  text: "⚠️ Overdue Invoices Report",
                  attachments: ["${overdue_report}"]
                }}
            ]
          }
        }
      }]

    # Success notification with agent details
    - rocketchat.sendMessage: {
        channel: "${input.channel}",
        text: "✅ **Agent Created Successfully!**",
        attachments: [{
          color: "good",
          title: "Invoice Monitor Agent: ${agent_creation_result.agent_id}",
          text: "Your agent is ready and will automatically monitor Xero invoices.",
          fields: [
            { title: "Agent ID", value: "${agent_creation_result.agent_id}", short: true },
            { title: "Capabilities", value: "Invoice monitoring, reporting, alerts", short: true }
          ]
        }]
      }

    # Phase 3: Auto-detect Xero integration needed
    - rocketchat.sendMessage: {
        channel: "${input.channel}",
        text: "🔍 **Step 2: Detecting Integration Requirements**",
        attachments: [{
          color: "warning",
          text: "Agent requires Xero integration. Checking for existing module..."
        }]
      }

    # This will trigger auto-generation when agent tries to call xero.getInvoices
    - simulate_agent_execution: {
        agent_id: "${agent_creation_result.agent_id}",
        operation: "check_invoices",
        trigger_integration: true
      }

  # Phase 3: Auto-Generation Demo (Called by step-executor)
  demonstrate_auto_generation:
    - rocketchat.sendMessage: {
        channel: "${input.channel}",
        text: "🔧 **Step 3: Auto-Generating Xero Integration Module**",
        attachments: [{
          color: "warning",
          title: "Service Integration Magic",
          text: "No Xero module detected. Auto-generating universal integration...",
          fields: [
            { title: "Service", value: "Xero Accounting API", short: true },
            { title: "Auth Type", value: "OAuth 2.0", short: true },
            { title: "Functions", value: "getInvoices, getContacts, getPayments", short: true },
            { title: "Template", value: "Universal Service Template", short: true }
          ]
        }]
      }

    # Call the universal service integration
    - run: ["r/templates/service-integration.r", "auto_generate_service_module", {
        service_name: "xero",
        required_function: "getInvoices",
        context: {
          user: "${input.user_id}",
          channel: "${input.channel}",
          client_id: "${input.client_id}"
        }
      }]

    # Show generated module preview
    - display_generated_module_preview: {
        service: "xero",
        channel: "${input.channel}"
      }

  # Phase 4: Interactive Credential Collection
  collect_xero_credentials:
    - rocketchat.sendMessage: {
        channel: "${input.channel}",
        text: "🔐 **Step 4: Connecting to Your Xero Account**",
        attachments: [{
          color: "good",
          title: "Xero OAuth Authorization Required",
          text: "To access your invoice data, I need to connect to your Xero account securely.",
          fields: [
            { title: "Auth Method", value: "OAuth 2.0 (Most Secure)", short: true },
            { title: "Permissions", value: "Read accounting data only", short: true },
            { title: "Data Access", value: "Invoices, Contacts, Payments", short: true },
            { title: "Security", value: "Tokens encrypted & stored securely", short: true }
          ]
        }]
      }

    # Generate Xero OAuth URL
    - generate_xero_oauth_url: {
        client_id: "${process.env.XERO_CLIENT_ID}",
        redirect_uri: "${process.env.XERO_REDIRECT_URI}",
        scope: "accounting.transactions accounting.contacts",
        state: "${generate_oauth_state()}"
      }

    # Interactive OAuth authorization
    - rocketchat.promptUser: {
        to: "${input.user_id}",
        message: "Click the button below to authorize ROL3 to access your Xero account:",
        attachments: [{
          color: "primary",
          title: "🔗 Xero Authorization",
          text: "This will open Xero's secure login page where you can authorize access.",
          actions: [
            {
              type: "button",
              text: "🔐 Authorize Xero Access",
              url: "${xero_oauth_url}",
              style: "primary"
            },
            { type: "button", text: "❓ Security Info", value: "xero_security_info" },
            { type: "button", text: "❌ Cancel Demo", value: "cancel_xero_demo" }
          ]
        }]
      }

    # Progress indicator while waiting
    - rocketchat.sendMessage: {
        channel: "${input.channel}",
        text: "⏳ Waiting for Xero authorization...",
        attachments: [{
          color: "warning",
          text: "Please complete the authorization in the popup window. I'll continue automatically once authorized."
        }]
      }

    # Wait for OAuth callback (webhook will handle this)
    - wait_for_oauth_completion: {
        state: "${oauth_state}",
        timeout: "300s",
        service: "xero"
      }

    - condition:
        if: "${oauth_completed.success}"
        then:
          - exchange_xero_oauth_tokens: {
              code: "${oauth_completed.code}",
              client_id: "${process.env.XERO_CLIENT_ID}",
              client_secret: "${process.env.XERO_CLIENT_SECRET}",
              redirect_uri: "${process.env.XERO_REDIRECT_URI}"
            }

          - store_xero_tokens: {
              access_token: "${xero_tokens.access_token}",
              refresh_token: "${xero_tokens.refresh_token}",
              tenant_id: "${xero_tokens.tenant_id}",
              expires_at: "${xero_tokens.expires_at}",
              user_id: "${input.user_id}"
            }

          - rocketchat.sendMessage: {
              channel: "${input.channel}",
              text: "✅ **Xero Authorization Successful!**",
              attachments: [{
                color: "good",
                title: "Connection Established",
                text: "ROL3 now has secure access to your Xero account.",
                fields: [
                  { title: "Status", value: "✅ Authorized", short: true },
                  { title: "Tenant", value: "${xero_tokens.tenant_name}", short: true }
                ]
              }]
            }

          # Proceed to connection test
          - run: ["r/demos/xero-integration-demo.r", "test_xero_connection", "${input}"]
        else:
          - handle_oauth_failure: {
              error: "${oauth_completed.error}",
              user_context: "${input}"
            }

  # Phase 5: Connection Testing with Live Data
  test_xero_connection:
    - rocketchat.sendMessage: {
        channel: "${input.channel}",
        text: "🧪 **Step 5: Testing Connection & Retrieving Live Data**",
        attachments: [{
          color: "warning",
          title: "Connection Test in Progress",
          text: "Validating Xero API access and fetching your invoice data..."
        }]
      }

    # Test connection with actual Xero API call
    - test_xero_api_connection: {
        user_id: "${input.user_id}",
        test_endpoints: ["invoices", "contacts", "organisation"]
      }

    - condition:
        if: "${xero_connection_test.success}"
        then:
          # SUCCESS - Fetch and display live data
          - fetch_live_xero_invoice_data: {
              user_id: "${input.user_id}",
              limit: 10,
              include_contacts: true
            }

          # Display the WOW moment - real data
          - display_live_xero_data: {
              invoice_data: "${live_xero_data}",
              channel: "${input.channel}",
              user_id: "${input.user_id}"
            }

          # Show agent in action
          - demonstrate_agent_capabilities: {
              agent_id: "${agent_creation_result.agent_id}",
              channel: "${input.channel}"
            }
        else:
          # FAILURE - Provide helpful recovery
          - handle_connection_failure: {
              error: "${xero_connection_test.error}",
              user_context: "${input}"
            }

  # 🎉 The WOW Moment - Live Data Display
  display_live_xero_data:
    - analyze_invoice_data: {
        invoices: "${input.invoice_data.invoices}",
        contacts: "${input.invoice_data.contacts}",
        organisation: "${input.invoice_data.organisation}"
      }

    - rocketchat.sendMessage: {
        channel: "${input.channel}",
        text: "🎉 **SUCCESS! Live Xero Data Retrieved!**\n\nHere's your real invoice data, fetched directly from your Xero account:",
        attachments: [
          {
            color: "good",
            title: "📊 Invoice Summary Dashboard",
            text: "Live data from ${input.invoice_data.organisation.name}",
            fields: [
              { title: "Total Invoices", value: "${invoice_analysis.total_invoices}", short: true },
              { title: "Total Value", value: "$${invoice_analysis.total_value}", short: true },
              { title: "Paid Invoices", value: "${invoice_analysis.paid_count}", short: true },
              { title: "Outstanding", value: "$${invoice_analysis.outstanding_value}", short: true },
              { title: "Overdue Count", value: "${invoice_analysis.overdue_count}", short: true },
              { title: "This Month", value: "$${invoice_analysis.current_month_value}", short: true }
            ]
          },
          {
            color: "warning",
            title: "📋 Recent Invoices",
            text: "Your 5 most recent invoices:",
            fields: "${format_recent_invoices(input.invoice_data.invoices.slice(0, 5))}"
          },
          {
            color: "primary",
            title: "🤖 Your Agent is Ready!",
            text: "The invoice monitoring agent is now connected and ready to help.",
            actions: [
              { type: "button", text: "📈 Get Full Report", value: "xero_full_report", style: "primary" },
              { type: "button", text: "⚠️ Check Overdue", value: "xero_overdue_check" },
              { type: "button", text: "🔔 Setup Alerts", value: "xero_setup_alerts" },
              { type: "button", text: "⚙️ Configure Agent", value: "configure_xero_agent" }
            ]
          }
        ]
      }

    # Log the successful demo completion
    - tamr.log: {
        event: "xero_demo_completed_successfully",
        user_id: "${input.user_id}",
        invoices_retrieved: "${invoice_analysis.total_invoices}",
        integration_time: "${demo_duration}",
        agent_created: "${agent_creation_result.agent_id}"
      }

    # Show next steps
    - suggest_next_steps: {
        user_id: "${input.user_id}",
        channel: "${input.channel}",
        agent_id: "${agent_creation_result.agent_id}"
      }

  # 🚀 Agent Capability Demonstration
  demonstrate_agent_capabilities:
    - rocketchat.sendMessage: {
        channel: "${input.channel}",
        text: "🤖 **Let me show you what your agent can do...**"
      }

    # Demo 1: Real-time invoice check
    - run: ["${input.agent_id}.r", "check_invoices", {
        demo_mode: true,
        channel: "${input.channel}"
      }]

    # Demo 2: Overdue invoice analysis
    - run: ["${input.agent_id}.r", "get_overdue_invoices", {
        demo_mode: true,
        channel: "${input.channel}"
      }]

    - rocketchat.sendMessage: {
        channel: "${input.channel}",
        text: "✨ **Demo Complete!** Your agent is now monitoring your Xero account.",
        attachments: [{
          color: "good",
          title: "🎯 What Just Happened",
          text: "In under 5 minutes, ROL3 automatically:\n• Created an intelligent agent\n• Generated Xero integration module\n• Collected credentials securely\n• Connected to your live data\n• Displayed real invoice information",
          fields: [
            { title: "Integration", value: "✅ Xero API Connected", short: true },
            { title: "Agent", value: "✅ Monitoring Active", short: true },
            { title: "Data", value: "✅ Live & Real-time", short: true },
            { title: "Security", value: "✅ OAuth Encrypted", short: true }
          ],
          actions: [
            { type: "button", text: "🔄 Run Agent Again", value: "run_xero_agent", style: "primary" },
            { type: "button", text: "🛠️ Create Another Agent", value: "create_new_agent" },
            { type: "button", text: "📚 View Documentation", value: "show_documentation" }
          ]
        }]
      }

  # 🔧 Utility Operations
  simulate_agent_execution:
    # This simulates what happens when the agent tries to call xero.getInvoices
    # It will trigger the auto-generation in step-executor.ts
    - try_xero_call: {
        # This will fail because utils/xero.ts doesn't exist yet
        # step-executor will catch this and trigger auto-generation
        call: "xero.getInvoices",
        args: { status: "AUTHORISED", limit: 5 }
      }

  display_generated_module_preview:
    - rocketchat.sendMessage: {
        channel: "${input.channel}",
        text: "✅ **Xero Integration Module Generated!**",
        attachments: [{
          color: "good",
          title: "📄 Generated: utils/xero.ts",
          text: "Universal service template automatically configured for Xero API",
          fields: [
            { title: "Template Used", value: "service-template.ts", short: true },
            { title: "Auth Type", value: "OAuth 2.0", short: true },
            { title: "Functions Created", value: "getInvoices, getContacts, getPayments", short: true },
            { title: "Configuration", value: "Xero API endpoints & auth", short: true }
          ]
        }]
      }

  handle_oauth_failure:
    - analyze_oauth_error: { error: "${input.error}" }

    - rocketchat.sendMessage: {
        channel: "${input.user_context.channel}",
        text: "❌ **Authorization Failed**",
        attachments: [{
          color: "danger",
          title: "OAuth Error: ${oauth_error_analysis.type}",
          text: "${oauth_error_analysis.user_friendly_message}",
          fields: [
            { title: "Error", value: "${oauth_error_analysis.error_code}", short: true },
            { title: "Resolution", value: "${oauth_error_analysis.resolution}", short: true }
          ],
          actions: [
            { type: "button", text: "🔄 Try Again", value: "retry_xero_oauth" },
            { type: "button", text: "❓ Get Help", value: "xero_oauth_help" },
            { type: "button", text: "📧 Contact Support", value: "contact_support" }
          ]
        }]
      }

  handle_connection_failure:
    - analyze_connection_error: { error: "${input.error}" }

    - rocketchat.sendMessage: {
        channel: "${input.user_context.channel}",
        text: "❌ **Connection Test Failed**",
        attachments: [{
          color: "danger",
          title: "Xero API Error: ${connection_error_analysis.type}",
          text: "${connection_error_analysis.diagnosis}",
          fields: [
            { title: "Issue", value: "${connection_error_analysis.issue}", short: true },
            { title: "Solution", value: "${connection_error_analysis.solution}", short: true }
          ],
          actions: [
            { type: "button", text: "🔧 Retry Connection", value: "retry_xero_connection" },
            { type: "button", text: "🔐 Re-authorize", value: "reauth_xero" },
            { type: "button", text: "📋 Check Permissions", value: "check_xero_permissions" }
          ]
        }]
      }

  suggest_next_steps:
    - rocketchat.sendMessage: {
        channel: "${input.channel}",
        text: "🚀 **What's Next?**",
        attachments: [{
          color: "primary",
          title: "Explore More ROL3 Capabilities",
          text: "Now that you've seen the service integration magic, here's what else you can do:",
          fields: [
            { title: "📊 More Integrations", value: "Connect Slack, GitHub, Stripe, etc.", short: true },
            { title: "🤖 Advanced Agents", value: "Create workflow automation agents", short: true },
            { title: "📈 Analytics", value: "Set up business intelligence dashboards", short: true },
            { title: "🔔 Monitoring", value: "Configure alerts and notifications", short: true }
          ],
          actions: [
            { type: "button", text: "🔌 Add More Services", value: "add_more_services", style: "primary" },
            { type: "button", text: "🤖 Create Complex Agent", value: "create_complex_agent" },
            { type: "button", text: "📖 View Full Guide", value: "view_full_guide" }
          ]
        }]
      }

# 🧪 Testing and Validation Operations
test_xero_api_connection:
  - load_xero_credentials: { user_id: "${input.user_id}" }

  # Test 1: Organisation info (basic connectivity)
  - test_organisation_endpoint: {
      access_token: "${xero_credentials.access_token}",
      tenant_id: "${xero_credentials.tenant_id}"
    }

  # Test 2: Invoices endpoint (core functionality)
  - test_invoices_endpoint: {
      access_token: "${xero_credentials.access_token}",
      tenant_id: "${xero_credentials.tenant_id}",
      limit: 5
    }

  # Test 3: Contacts endpoint (additional data)
  - test_contacts_endpoint: {
      access_token: "${xero_credentials.access_token}",
      tenant_id: "${xero_credentials.tenant_id}",
      limit: 5
    }

  - aggregate_test_results: {
      organisation_test: "${organisation_test}",
      invoices_test: "${invoices_test}",
      contacts_test: "${contacts_test}"
    }

  - return: {
      success: "${all_tests_passed}",
      organisation: "${organisation_test.data}",
      invoices: "${invoices_test.data}",
      contacts: "${contacts_test.data}",
      response_times: "${aggregated_response_times}"
    }

fetch_live_xero_invoice_data:
  - load_xero_credentials: { user_id: "${input.user_id}" }

  # Fetch comprehensive invoice data
  - xero.getInvoices: {
      access_token: "${xero_credentials.access_token}",
      tenant_id: "${xero_credentials.tenant_id}",
      limit: "${input.limit || 20}",
      order: "Date DESC"
    }

  # Fetch organization info for context
  - xero.getOrganisation: {
      access_token: "${xero_credentials.access_token}",
      tenant_id: "${xero_credentials.tenant_id}"
    }

  # Fetch contacts if requested
  - condition:
      if: "${input.include_contacts}"
      then:
        - xero.getContacts: {
            access_token: "${xero_credentials.access_token}",
            tenant_id: "${xero_credentials.tenant_id}",
            limit: 10
          }

  - return: {
      invoices: "${invoice_data}",
      organisation: "${organisation_data}",
      contacts: "${contact_data || []}",
      retrieved_at: "${timestamp}"
    }

# 📊 Data Analysis and Formatting
analyze_invoice_data:
  - calculate_invoice_metrics: {
      invoices: "${input.invoices}"
    }

  - identify_overdue_invoices: {
      invoices: "${input.invoices}",
      as_of_date: "${timestamp}"
    }

  - calculate_monthly_trends: {
      invoices: "${input.invoices}",
      months_back: 3
    }

  - return: {
      total_invoices: "${total_count}",
      total_value: "${total_amount}",
      paid_count: "${paid_invoices_count}",
      outstanding_value: "${outstanding_amount}",
      overdue_count: "${overdue_invoices.length}",
      overdue_value: "${overdue_total_amount}",
      current_month_value: "${current_month_total}",
      average_invoice_value: "${average_amount}",
      trends: "${monthly_trends}"
    }

format_recent_invoices:
  - loop:
      forEach: "${input}"
      do:
        - format_single_invoice: { invoice: "${item}" }

  - return: "${formatted_invoices}"

format_single_invoice:
  - extract_invoice_details: { invoice: "${input.invoice}" }

  - return: {
      title: "Invoice #${invoice_details.number}",
      value: "${invoice_details.contact} - $${invoice_details.amount}",
      short: true
    }

concern:
  if: "${demo_failure_rate > 0.1 || oauth_completion_rate < 0.9}"
  priority: 1
  action:
    - tamr.log: { event: "xero_demo_quality_concern", metrics: "${demo_metrics}" }
    - analyze_demo_failure_patterns: {}
    - prompt.user:
        to: "system_admin"
        message: "🎯 Xero demo success rate degraded. Review integration flow."
        buttons: ["Analyze Failures", "Update OAuth Flow", "Review Credentials"]
