import { Environment } from '@delon/theme';

export const environment = {
  production: true,
  useHash: true,
  api: {
    baseUrl: './',
    refreshTokenEnabled: true,
    refreshTokenType: 'auth-refresh'
  },
  supabase: {
    // Supabase project configuration
    // For setup instructions, see: docs/SUPABASE_SETUP.md
    url: 'https://nvxhnmkmwekuhzhprfqo.supabase.co',
    anonKey:
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im52eGhubWttd2VrdWh6aHByZnFvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ0ODE5MjUsImV4cCI6MjA4MDA1NzkyNX0.UMismCDE4Z-YX7v2o_U-1fUkMUYhcKdD2M_-nXYeskw',
    serviceRoleKey:
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh4eWN5cnNnempscGhvaHFqcHNoIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2Mzc0NTg1NywiZXhwIjoyMDc5MzIxODU3fQ.THaX_Uk6_OLcBgVFDI4We8qpIAzhJh7598LADMzu6V4'
  }
} as Environment;
