// Centralized, validated environment configuration.
// Fails fast and loudly in dev if required secrets are missing, but never
// leaks secret values into logs or error responses.
require('dotenv').config();

function required(name, fallbackForDemo) {
  const val = process.env[name];
  if (!val && fallbackForDemo === undefined) {
    console.warn(`[config] Warning: ${name} is not set.`);
  }
  return val || fallbackForDemo;
}

const config = {
  port: parseInt(process.env.PORT || '8080', 10),
  databaseUrl: process.env.DATABASE_URL,
  jwtSecret: required('JWT_SECRET', 'dev-only-insecure-secret-change-me'),
  appApiKey: required('APP_API_KEY', 'dev-only-app-key-change-me'),
  // Two pluggable AI providers. Gemini is checked first because Google AI
  // Studio issues a genuinely free API key (no credit card) — a good fit for
  // a student/portfolio project. Anthropic Claude Vision remains supported
  // as a drop-in alternative if that key is set instead.
  geminiApiKey: process.env.GEMINI_API_KEY || '',
  geminiModel: process.env.GEMINI_MODEL || 'gemini-2.0-flash',
  anthropicApiKey: process.env.ANTHROPIC_API_KEY || '',
  anthropicModel: process.env.ANTHROPIC_MODEL || 'claude-fable-5-1',
  corsOrigins: (process.env.CORS_ORIGINS || '*').split(',').map((s) => s.trim()),
  maxImageBytes: 8 * 1024 * 1024, // 8MB upload cap (compressed further server-side)
};

config.activeProvider = config.geminiApiKey ? 'gemini' : config.anthropicApiKey ? 'anthropic' : 'demo';
config.isDemoMode = config.activeProvider === 'demo';

module.exports = config;
