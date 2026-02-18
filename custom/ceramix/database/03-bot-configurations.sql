-- Bot Configurations Table
-- Stores configuration for each bot type (accounting, client_management)

CREATE TABLE IF NOT EXISTS bot_configurations (
  bot_type VARCHAR(50) PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  enabled BOOLEAN DEFAULT true,
  model VARCHAR(255),
  temperature DECIMAL(3,2) DEFAULT 0.7,
  max_tokens INTEGER DEFAULT 1024,
  use_lora BOOLEAN DEFAULT false,
  lora_adapter VARCHAR(255),
  context_window INTEGER DEFAULT 2048,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_bot_configurations_enabled 
  ON bot_configurations(enabled);

-- Insert default configurations
INSERT INTO bot_configurations (
  bot_type, name, description, enabled, model, 
  temperature, max_tokens, use_lora, lora_adapter, context_window
) VALUES
  (
    'accounting',
    'Asystent Księgowy',
    'Bot do analizy faktur i dokumentów księgowych',
    true,
    'bielik-invoice-extraction',
    0.3,
    2048,
    true,
    'bielik-invoice-extraction',
    4096
  ),
  (
    'client_management',
    'Zarządzanie Klientami',
    'Bot do wyszukiwania i analizy danych klientów',
    true,
    'qwen2.5-3b',
    0.7,
    1024,
    false,
    '',
    2048
  )
ON CONFLICT (bot_type) DO NOTHING;

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_bot_configurations_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-update updated_at
CREATE TRIGGER bot_configurations_updated_at
  BEFORE UPDATE ON bot_configurations
  FOR EACH ROW
  EXECUTE FUNCTION update_bot_configurations_updated_at();



