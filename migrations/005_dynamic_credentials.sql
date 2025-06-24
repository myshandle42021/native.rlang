-- migrations/005_dynamic_credentials.sql
CREATE TABLE user_service_credentials (
    id SERIAL PRIMARY KEY,
    user_id TEXT NOT NULL,
    service TEXT NOT NULL,
    credentials JSONB NOT NULL, -- Encrypted
    metadata JSONB DEFAULT '{}', -- Service-specific info
    active BOOLEAN DEFAULT true,
    expires_at TIMESTAMP, -- For OAuth tokens
    created_at TIMESTAMP DEFAULT NOW (),
    updated_at TIMESTAMP DEFAULT NOW (),
    UNIQUE (user_id, service)
);

CREATE INDEX idx_user_service_creds_user_id ON user_service_credentials (user_id);

CREATE INDEX idx_user_service_creds_service ON user_service_credentials (service);
