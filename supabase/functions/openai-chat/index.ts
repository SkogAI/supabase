// openai-chat edge function
// Example demonstrating OpenAI integration with Supabase Edge Functions

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// CORS headers for browser requests
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// Types for our request/response
interface RequestBody {
  message: string;
  model?: string;
}

interface ResponseBody {
  reply: string;
  model: string;
  timestamp: string;
  user?: {
    id: string;
    email?: string;
  };
}

// Main request handler
serve(async (req: Request): Promise<Response> => {
  // Handle CORS preflight requests
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Get OpenAI API key from environment
    const openaiApiKey = Deno.env.get("OPENAI_API_KEY");

    if (!openaiApiKey) {
      console.error("OPENAI_API_KEY is not set in environment variables");
      return new Response(
        JSON.stringify({
          error:
            "OpenAI API key is not configured. Please set OPENAI_API_KEY in your Supabase secrets.",
          hint: "Run: supabase secrets set OPENAI_API_KEY=your_key_here",
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

    // Parse request body
    const { message, model = "gpt-3.5-turbo" }: RequestBody = await req.json();

    if (!message) {
      return new Response(
        JSON.stringify({
          error: "Message is required",
        }),
        {
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json",
          },
          status: 400,
        },
      );
    }

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

    // Call OpenAI API
    console.log(`Calling OpenAI API with model: ${model}`);
    const openaiResponse = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${openaiApiKey}`,
      },
      body: JSON.stringify({
        model: model,
        messages: [
          {
            role: "user",
            content: message,
          },
        ],
        temperature: 0.7,
        max_tokens: 500,
      }),
    });

    if (!openaiResponse.ok) {
      const errorData = await openaiResponse.json();
      console.error("OpenAI API error:", errorData);

      return new Response(
        JSON.stringify({
          error: "OpenAI API request failed",
          details: errorData,
        }),
        {
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json",
          },
          status: openaiResponse.status,
        },
      );
    }

    const data = await openaiResponse.json();
    const reply = data.choices[0]?.message?.content || "No response generated";

    // Prepare response
    const response: ResponseBody = {
      reply,
      model,
      timestamp: new Date().toISOString(),
      ...(user && { user }),
    };

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
 * 1. Set up OpenAI API key:
 *    supabase secrets set OPENAI_API_KEY=your_openai_api_key_here
 *
 * 2. Local development:
 *    supabase functions serve openai-chat
 *
 * 3. Basic test:
 *    curl -i http://localhost:54321/functions/v1/openai-chat \
 *      -H "Content-Type: application/json" \
 *      -d '{"message": "Hello, how are you?"}'
 *
 * 4. With custom model:
 *    curl -i http://localhost:54321/functions/v1/openai-chat \
 *      -H "Content-Type: application/json" \
 *      -d '{"message": "Explain quantum computing", "model": "gpt-4"}'
 *
 * 5. With authentication:
 *    curl -i http://localhost:54321/functions/v1/openai-chat \
 *      -H "Authorization: Bearer YOUR_JWT_TOKEN" \
 *      -H "Content-Type: application/json" \
 *      -d '{"message": "Hello!"}'
 *
 * 6. Deploy:
 *    supabase functions deploy openai-chat
 */
