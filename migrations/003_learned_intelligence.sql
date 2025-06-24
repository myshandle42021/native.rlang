-- migrations/003_learned_intelligence.sql
-- Database schema for Learning Evolution Architecture

-- ============================================================================
-- LEARNED SERVICE CONFIGURATIONS
-- ============================================================================

CREATE TABLE IF NOT EXISTS learned_service_configs (
  service_name TEXT PRIMARY KEY,
  configuration JSONB NOT NULL,
  discovery_method TEXT NOT NULL DEFAULT 'serpapi_claude_analysis',
  confidence_score FLOAT NOT NULL DEFAULT 0.0,
  success_rate FLOAT DEFAULT 1.0,
  usage_count INTEGER DEFAULT 0,
  last_success TIMESTAMP,
  last_failure TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  active BOOLEAN DEFAULT TRUE,
  discovery_metadata JSONB DEFAULT '{}'::jsonb
);

-- Add helpful comments
COMMENT ON TABLE learned_service_configs IS 'Dynamically discovered and learned service configurations';
COMMENT ON COLUMN learned_service_configs.configuration IS 'Full service config with endpoints, auth, etc.';
COMMENT ON COLUMN learned_service_configs.discovery_method IS 'How this config was discovered (serpapi_claude_analysis, predicted, manual)';
COMMENT ON COLUMN learned_service_configs.confidence_score IS 'AI confidence in this configuration (0.0-1.0)';
COMMENT ON COLUMN learned_service_configs.success_rate IS 'Historical success rate of this configuration';

-- ============================================================================
-- USER SERVICE CREDENTIALS (Enhanced from existing)
-- ============================================================================

CREATE TABLE IF NOT EXISTS user_service_credentials (
  id SERIAL PRIMARY KEY,
  user_id TEXT NOT NULL,
  service TEXT NOT NULL,
  credentials JSONB NOT NULL,
  active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  expires_at TIMESTAMP,
  credential_type TEXT DEFAULT 'unknown',
  UNIQUE(user_id, service)
);

-- Add helpful comments
COMMENT ON TABLE user_service_credentials IS 'Per-user encrypted service credentials';
COMMENT ON COLUMN user_service_credentials.credentials IS 'Encrypted user credentials (tokens, keys, etc.)';
COMMENT ON COLUMN user_service_credentials.credential_type IS 'Type of credentials (oauth, api_key, bearer, basic)';

-- ============================================================================
-- BACKGROUND REFRESH QUEUE
-- ============================================================================

CREATE TABLE IF NOT EXISTS config_refresh_queue (
  id SERIAL PRIMARY KEY,
  service_name TEXT NOT NULL,
  priority TEXT DEFAULT 'medium' CHECK (priority IN ('high', 'medium', 'low')),
  reason TEXT,
  scheduled_at TIMESTAMP DEFAULT NOW(),
  processed BOOLEAN DEFAULT FALSE,
  processed_at TIMESTAMP,
  error_details TEXT,
  retry_count INTEGER DEFAULT 0,
  max_retries INTEGER DEFAULT 3
);

-- Add helpful comments
COMMENT ON TABLE config_refresh_queue IS 'Queue for background service configuration updates';
COMMENT ON COLUMN config_refresh_queue.reason IS 'Why refresh was scheduled (stale_config, poor_performance, api_changes)';

-- ============================================================================
-- DISCOVERY ANALYTICS
-- ============================================================================

CREATE TABLE IF NOT EXISTS discovery_analytics (
  id SERIAL PRIMARY KEY,
  service_name TEXT NOT NULL,
  discovery_method TEXT NOT NULL,
  success BOOLEAN NOT NULL,
  confidence_achieved FLOAT,
  time_taken_ms INTEGER,
  serpapi_queries INTEGER DEFAULT 0,
  claude_tokens INTEGER DEFAULT 0,
  error_details TEXT,
  discovered_at TIMESTAMP DEFAULT NOW(),
  sources_analyzed INTEGER DEFAULT 0,
  config_quality_score FLOAT
);

-- Add helpful comments
COMMENT ON TABLE discovery_analytics IS 'Analytics and metrics for service discovery operations';
COMMENT ON COLUMN discovery_analytics.config_quality_score IS 'Overall quality assessment of discovered configuration';

-- ============================================================================
-- SERVICE USAGE METRICS
-- ============================================================================

CREATE TABLE IF NOT EXISTS service_usage_metrics (
  id SERIAL PRIMARY KEY,
  service_name TEXT NOT NULL,
  user_id TEXT NOT NULL,
  operation TEXT NOT NULL,
  success BOOLEAN NOT NULL,
  response_time_ms INTEGER,
  error_type TEXT,
  error_message TEXT,
  executed_at TIMESTAMP DEFAULT NOW(),
  config_version TEXT
);

-- Add helpful comments
COMMENT ON TABLE service_usage_metrics IS 'Track actual usage and performance of generated service integrations';

-- ============================================================================
-- PERFORMANCE INDEXES
-- ============================================================================

-- Learned configs indexes
CREATE INDEX IF NOT EXISTS idx_learned_configs_active
  ON learned_service_configs(active, service_name)
  WHERE active = TRUE;

CREATE INDEX IF NOT EXISTS idx_learned_configs_updated
  ON learned_service_configs(updated_at DESC)
  WHERE active = TRUE;

CREATE INDEX IF NOT EXISTS idx_learned_configs_success_rate
  ON learned_service_configs(success_rate DESC)
  WHERE active = TRUE;

-- User credentials indexes
CREATE INDEX IF NOT EXISTS idx_user_credentials_lookup
  ON user_service_credentials(user_id, service, active)
  WHERE active = TRUE;

CREATE INDEX IF NOT EXISTS idx_user_credentials_expires
  ON user_service_credentials(expires_at)
  WHERE expires_at IS NOT NULL AND active = TRUE;

-- Refresh queue indexes
CREATE INDEX IF NOT EXISTS idx_refresh_queue_pending
  ON config_refresh_queue(processed, priority, scheduled_at)
  WHERE processed = FALSE;

CREATE INDEX IF NOT EXISTS idx_refresh_queue_service
  ON config_refresh_queue(service_name, processed);

-- Discovery analytics indexes
CREATE INDEX IF NOT EXISTS idx_discovery_analytics_service
  ON discovery_analytics(service_name, discovered_at DESC);

CREATE INDEX IF NOT EXISTS idx_discovery_analytics_success
  ON discovery_analytics(success, discovered_at DESC);

CREATE INDEX IF NOT EXISTS idx_discovery_analytics_method
  ON discovery_analytics(discovery_method, success);

-- Usage metrics indexes
CREATE INDEX IF NOT EXISTS idx_usage_metrics_service_user
  ON service_usage_metrics(service_name, user_id, executed_at DESC);

CREATE INDEX IF NOT EXISTS idx_usage_metrics_performance
  ON service_usage_metrics(service_name, success, executed_at DESC);

-- ============================================================================
-- USEFUL VIEWS FOR ANALYTICS
-- ============================================================================

-- Service health overview
CREATE OR REPLACE VIEW service_health_overview AS
SELECT
  lsc.service_name,
  lsc.confidence_score,
  lsc.success_rate,
  lsc.usage_count,
  lsc.last_success,
  lsc.last_failure,
  lsc.created_at,
  COUNT(usc.user_id) as users_configured,
  AVG(sum.response_time_ms) as avg_response_time,
  SUM(CASE WHEN sum.success THEN 1 ELSE 0 END)::float / COUNT(sum.id) as recent_success_rate
FROM learned_service_configs lsc
LEFT JOIN user_service_credentials usc ON usc.service = lsc.service_name AND usc.active = TRUE
LEFT JOIN service_usage_metrics sum ON sum.service_name = lsc.service_name
  AND sum.executed_at > NOW() - INTERVAL '7 days'
WHERE lsc.active = TRUE
GROUP BY lsc.service_name, lsc.confidence_score, lsc.success_rate, lsc.usage_count,
         lsc.last_success, lsc.last_failure, lsc.created_at;

-- Discovery performance metrics
CREATE OR REPLACE VIEW discovery_performance_metrics AS
SELECT
  discovery_method,
  COUNT(*) as total_attempts,
  SUM(CASE WHEN success THEN 1 ELSE 0 END) as successful_discoveries,
  SUM(CASE WHEN success THEN 1 ELSE 0 END)::float / COUNT(*) as success_rate,
  AVG(time_taken_ms) as avg_time_ms,
  AVG(CASE WHEN success THEN confidence_achieved END) as avg_confidence,
  AVG(serpapi_queries) as avg_serpapi_queries,
  AVG(claude_tokens) as avg_claude_tokens
FROM discovery_analytics
WHERE discovered_at > NOW() - INTERVAL '30 days'
GROUP BY discovery_method;

-- ============================================================================
-- CLEANUP FUNCTIONS
-- ============================================================================

-- Function to clean old analytics data
CREATE OR REPLACE FUNCTION cleanup_old_analytics(retention_days INTEGER DEFAULT 90)
RETURNS INTEGER AS $$
DECLARE
  deleted_count INTEGER;
BEGIN
  DELETE FROM discovery_analytics
  WHERE discovered_at < NOW() - (retention_days || ' days')::INTERVAL;

  GET DIAGNOSTICS deleted_count = ROW_COUNT;

  DELETE FROM service_usage_metrics
  WHERE executed_at < NOW() - (retention_days || ' days')::INTERVAL;

  RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Function to update success rates
CREATE OR REPLACE FUNCTION update_service_success_rates()
RETURNS VOID AS $$
BEGIN
  UPDATE learned_service_configs
  SET success_rate = (
    SELECT COALESCE(
      SUM(CASE WHEN success THEN 1 ELSE 0 END)::float / COUNT(*),
      success_rate
    )
    FROM service_usage_metrics
    WHERE service_name = learned_service_configs.service_name
      AND executed_at > NOW() - INTERVAL '30 days'
    GROUP BY service_name
  ),
  updated_at = NOW()
  WHERE EXISTS (
    SELECT 1 FROM service_usage_metrics
    WHERE service_name = learned_service_configs.service_name
      AND executed_at > NOW() - INTERVAL '30 days'
  );
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- MIGRATION COMPLETION
-- ============================================================================

-- Insert migration record
INSERT INTO migrations (name, executed_at)
VALUES ('003_learned_intelligence', NOW())
ON CONFLICT (name) DO UPDATE SET executed_at = NOW();

-- Grant necessary permissions (adjust as needed for your setup)
-- GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO your_app_user;
-- GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO your_app_user;

-- Final success message
DO $$
BEGIN
  RAISE NOTICE 'Migration 003_learned_intelligence completed successfully!';
  RAISE NOTICE 'Tables created: learned_service_configs, config_refresh_queue, discovery_analytics, service_usage_metrics';
  RAISE NOTICE 'Views created: service_health_overview, discovery_performance_metrics';
  RAISE NOTICE 'Functions created: cleanup_old_analytics(), update_service_success_rates()';
END $$;
