/**
 * Standard CORS headers for Supabase Edge Functions
 *
 * Usage:
 * ```typescript
 * import { corsHeaders } from '../_shared/cors.ts';
 *
 * // In OPTIONS handler
 * return new Response('ok', { headers: corsHeaders });
 *
 * // In actual response
 * return new Response(JSON.stringify(data), {
 *   headers: { ...corsHeaders, 'Content-Type': 'application/json' },
 * });
 * ```
 */

export const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, GET, OPTIONS, PUT, DELETE',
};
