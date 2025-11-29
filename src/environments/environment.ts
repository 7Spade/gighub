// This file can be replaced during build by using the `fileReplacements` array.
// `ng build ---prod` replaces `environment.ts` with `environment.prod.ts`.
// The list of file replacements can be found in `angular.json`.

import * as MOCKDATA from '@_mock';
import { mockInterceptor, provideMockConfig } from '@delon/mock';
import { Environment } from '@delon/theme';

export const environment = {
  production: false,
  useHash: true,
  api: {
    baseUrl: './',
    refreshTokenEnabled: true,
    refreshTokenType: 'auth-refresh'
  },
  supabase: {
    // Supabase project configuration
    // For setup instructions, see: docs/SUPABASE_SETUP.md
    url: 'https://hbiihihbbicwktdtgcqc.supabase.co',
    anonKey:
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhiaWloaWhiYmljd2t0ZHRnY3FjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzODY5NzIsImV4cCI6MjA3OTk2Mjk3Mn0.XtgPA95L2cL_bvYUpVnWDb7NrRc5tulyhEPUbwNubx4',
    serviceRoleKey:
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh4eWN5cnNnempscGhvaHFqcHNoIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2Mzc0NTg1NywiZXhwIjoyMDc5MzIxODU3fQ.THaX_Uk6_OLcBgVFDI4We8qpIAzhJh7598LADMzu6V4'
  },
  providers: [provideMockConfig({ data: MOCKDATA })],
  interceptorFns: [mockInterceptor]
} as Environment;
