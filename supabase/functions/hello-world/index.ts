// hello-world edge function
// This is a comprehensive example demonstrating best practices for Supabase Edge Functions

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// CORS headers for browser requests
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// Types for our request/response
interface RequestBody {
  name?: string;
  includeDatabase?: boolean;
}

interface ResponseBody {
  message: string;
  timestamp: string;
  user?: {
    id: string;
    email?: string;
  };
  databaseCheck?: {
    connected: boolean;
    profileCount?: number;
  };
}

// Main request handler
serve(async (req: Request): Promise<Response> => {
  // Handle CORS preflight requests
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Parse request body
    const { name = "World", includeDatabase = false }: RequestBody = await req.json().catch(
      () => ({}),
    );

    // Get authorization header to check if user is authenticated
    const authHeader = req.headers.get("Authorization");
    let user = null;

    if (authHeader) {
      // Create Supabase client with the user's JWT
      const supabaseClient = createClient(
        Deno.env.get("SUPABASE_URL") ?? "",
        Deno.env.get("SUPABASE_ANON_KEY") ?? "",
        {
          global: {
            headers: { Authorization: authHeader },
          },
        },
      );

      // Get the authenticated user
      const { data: { user: authUser } } = await supabaseClient.auth.getUser();
      if (authUser) {
        user = {
          id: authUser.id,
          email: authUser.email,
        };
      }
    }

    // Prepare response
    const response: ResponseBody = {
      message: `Hello, ${name}!`,
      timestamp: new Date().toISOString(),
      ...(user && { user }),
    };

    // Optional database check
    if (includeDatabase) {
      try {
        const supabaseClient = createClient(
          Deno.env.get("SUPABASE_URL") ?? "",
          Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
        );

        const { count, error } = await supabaseClient
          .from("profiles")
          .select("*", { count: "exact", head: true });

        response.databaseCheck = {
          connected: !error,
          ...(count !== null && { profileCount: count }),
        };
      } catch (error) {
        console.error("Database check failed:", error);
        response.databaseCheck = {
          connected: false,
        };
      }
    }

    // Return successful response
    return new Response(
      JSON.stringify(response),
      {
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
        },
        status: 200,
      },
    );
  } catch (error) {
    // Error handling
    console.error("Function error:", error);

    return new Response(
      JSON.stringify({
        error: error instanceof Error ? error.message : "Unknown error",
        timestamp: new Date().toISOString(),
      }),
      {
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
        },
        status: 500,
      },
    );
  }
});

/*
 * Testing this function:
 *
 * 1. Local development:
 *    supabase functions serve hello-world
 *
 * 2. Basic test:
 *    curl -i http://localhost:54321/functions/v1/hello-world \
 *      -H "Content-Type: application/json" \
 *      -d '{"name": "Supabase"}'
 *
 * 3. With authentication:
 *    curl -i http://localhost:54321/functions/v1/hello-world \
 *      -H "Authorization: Bearer YOUR_JWT_TOKEN" \
 *      -H "Content-Type: application/json" \
 *      -d '{"name": "User", "includeDatabase": true}'
 *
 * 4. Deploy:
 *    supabase functions deploy hello-world
 */
