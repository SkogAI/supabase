# AI Integration with Supabase

This guide explains how to integrate AI providers (OpenAI, OpenRouter, etc.) with your Supabase project for AI-powered features.

## Overview

Supabase supports AI integration in two ways:

1. **Supabase Studio AI Features** - OpenAI integration within the Supabase Studio UI
2. **Edge Functions** - Custom AI integration in your serverless functions (supports OpenAI, OpenRouter, and other providers)

### AI Provider Options

For Edge Functions, you can use:
- **OpenAI**: Direct access to GPT models - https://platform.openai.com
- **OpenRouter**: Unified API for 100+ AI models with automatic fallbacks - https://openrouter.ai

---

## 1. Supabase Studio AI Features

The Supabase Studio includes AI-powered features for SQL generation, query optimization, and more.

### Setup for Local Development

1. **Get your OpenAI API key**
   - Visit [OpenAI Platform](https://platform.openai.com/api-keys)
   - Create a new API key or use an existing one

2. **Create a `.env` file** (if it doesn't exist)
   ```bash
   cp .env.example .env
   ```

3. **Add your OpenAI API key to `.env`**
   ```bash
   # OpenAI API Key for Supabase Studio AI features
   SUPABASE_OPENAI_API_KEY=sk-your-openai-api-key-here
   ```

4. **Start Supabase**
   ```bash
   npm run db:start
   # OR
   supabase start
   ```

5. **Access Studio**
   - Open http://localhost:8000
   - The AI features will now be available in the Studio UI

### Configuration Reference

The OpenAI API key is configured in `supabase/config.toml`:

```toml
[studio]
enabled = true
port = 8000
api_url = "http://10.10.0.6"
# OpenAI API Key to use for Supabase AI in the Supabase Studio.
openai_api_key = "env(SUPABASE_OPENAI_API_KEY)"
```

The `env(SUPABASE_OPENAI_API_KEY)` syntax tells Supabase to read the value from the environment variable.

### Troubleshooting

**Issue**: AI features not working in Studio  
**Solution**: 
- Ensure `.env` file exists with `SUPABASE_OPENAI_API_KEY` set
- Verify the API key is valid at https://platform.openai.com/api-keys
- Restart Supabase: `supabase stop && supabase start`

**Issue**: Environment variable not found  
**Solution**: 
- The `.env` file must be in the root directory of your project
- Check that the variable name is exactly `SUPABASE_OPENAI_API_KEY` (no typos)
- Do not add quotes around the value in the `.env` file

---

## 2. OpenAI in Edge Functions

Use OpenAI APIs directly in your Supabase Edge Functions for custom AI features.

### Setup

1. **Set OpenAI API key as a secret**
   
   For local development, create a `.env` file in your project root:
   ```bash
   OPENAI_API_KEY=sk-your-openai-api-key-here
   ```

   For production, set the secret via Supabase CLI:
   ```bash
   supabase secrets set OPENAI_API_KEY=sk-your-openai-api-key-here
   ```

   Or via Supabase Dashboard:
   - Go to your project dashboard
   - Navigate to **Settings → Edge Functions → Secrets**
   - Add `OPENAI_API_KEY` with your API key

2. **Use the example function**

   We provide an example function at `supabase/functions/openai-chat/` that demonstrates:
   - OpenAI API integration
   - Error handling
   - User authentication
   - CORS configuration

3. **Test locally**

   ```bash
   # Start Supabase
   supabase start

   # Serve the function
   supabase functions serve openai-chat

   # Test with curl
   curl -i http://localhost:54321/functions/v1/openai-chat \
     -H "Content-Type: application/json" \
     -d '{"message": "Hello, how are you?"}'
   ```

4. **Deploy to production**

   ```bash
   # Deploy the function
   supabase functions deploy openai-chat

   # Test production endpoint
   curl -i https://your-project.supabase.co/functions/v1/openai-chat \
     -H "Authorization: Bearer YOUR_ANON_KEY" \
     -H "Content-Type: application/json" \
     -d '{"message": "Hello!"}'
   ```

### Example Code

See `supabase/functions/openai-chat/index.ts` for a complete example that includes:

```typescript
// Get OpenAI API key from environment
const openaiApiKey = Deno.env.get("OPENAI_API_KEY");

// Call OpenAI API
const response = await fetch("https://api.openai.com/v1/chat/completions", {
  method: "POST",
  headers: {
    "Content-Type": "application/json",
    "Authorization": `Bearer ${openaiApiKey}`,
  },
  body: JSON.stringify({
    model: "gpt-3.5-turbo",
    messages: [{ role: "user", content: message }],
  }),
});
```

### Available Models

Common OpenAI models you can use:

| Model | Description | Use Case |
|-------|-------------|----------|
| `gpt-3.5-turbo` | Fast, cost-effective | Chat, simple tasks |
| `gpt-4` | Most capable, slower | Complex reasoning |
| `gpt-4-turbo` | Fast GPT-4 | Advanced tasks |
| `text-embedding-ada-002` | Embeddings | Vector search, similarity |

### Best Practices

1. **Error Handling**: Always check if API key is set and handle errors gracefully
2. **Rate Limiting**: Implement rate limiting to control costs
3. **Streaming**: Use streaming responses for better UX with long outputs
4. **Caching**: Cache responses when appropriate to reduce API calls
5. **Security**: Never expose API keys in client-side code
6. **Authentication**: Protect endpoints with Supabase Auth
7. **Monitoring**: Log API usage and errors

### Cost Management

OpenAI charges per token. To manage costs:

- Use `gpt-3.5-turbo` for simple tasks (cheaper)
- Set `max_tokens` to limit response length
- Implement caching for repeated queries
- Use rate limiting per user
- Monitor usage in OpenAI dashboard

### Troubleshooting

**Issue**: "OPENAI_API_KEY is not set" error  
**Solution**: 
```bash
# For local development
echo "OPENAI_API_KEY=sk-your-key" >> .env

# For production
supabase secrets set OPENAI_API_KEY=sk-your-key
```

**Issue**: OpenAI API returns 401 Unauthorized  
**Solution**: 
- Verify your API key is valid
- Check you haven't hit rate limits
- Ensure billing is set up in OpenAI account

**Issue**: Function times out  
**Solution**: 
- Reduce `max_tokens` in your request
- Use streaming responses
- Consider using a faster model

---

## 3. Using OpenRouter (Alternative to OpenAI)

[OpenRouter](https://openrouter.ai) provides a unified API to access 100+ AI models from different providers through a single endpoint. It offers automatic fallbacks, cost optimization, and supports models from OpenAI, Anthropic, Google, Meta, and more.

### Why Use OpenRouter?

- **Access to Multiple Models**: Use GPT-4, Claude, Gemini, Llama, and 100+ other models
- **Cost Optimization**: Automatically routes to the most cost-effective model
- **Automatic Fallbacks**: If one model is down, it automatically tries alternatives
- **Single API Key**: One key for all models
- **Simple Migration**: Compatible with OpenAI SDK format

### Setup

1. **Get an OpenRouter API key**
   - Visit [OpenRouter](https://openrouter.ai)
   - Sign up and get your API key from the dashboard
   - API keys start with `sk-or-`

2. **Set OpenRouter API key as a secret**
   
   For local development:
   ```bash
   OPENROUTER_API_KEY=sk-or-your-openrouter-api-key-here
   ```

   For production:
   ```bash
   supabase secrets set OPENROUTER_API_KEY=sk-or-your-key
   ```

3. **Use in Edge Functions**

The OpenRouter API is compatible with OpenAI's format, so you can easily switch:

```typescript
// Get OpenRouter API key from environment
const openrouterApiKey = Deno.env.get("OPENROUTER_API_KEY");

// Call OpenRouter API (OpenAI-compatible format)
const response = await fetch("https://openrouter.ai/api/v1/chat/completions", {
  method: "POST",
  headers: {
    "Authorization": `Bearer ${openrouterApiKey}`,
    "HTTP-Referer": `${Deno.env.get("SUPABASE_URL")}`, // Optional, for rankings
    "X-Title": "My Supabase App", // Optional, for rankings
    "Content-Type": "application/json"
  },
  body: JSON.stringify({
    model: "openai/gpt-3.5-turbo", // Or any other model
    messages: [
      { role: "user", content: "Hello!" }
    ]
  })
});
```

### Available Models

OpenRouter provides access to many models. Some popular options:

| Model | Provider | Use Case |
|-------|----------|----------|
| `openai/gpt-4-turbo` | OpenAI | Advanced reasoning |
| `openai/gpt-3.5-turbo` | OpenAI | Fast, cost-effective |
| `anthropic/claude-3-opus` | Anthropic | Complex tasks |
| `anthropic/claude-3-sonnet` | Anthropic | Balanced performance |
| `google/gemini-pro` | Google | Multimodal tasks |
| `meta-llama/llama-3-70b` | Meta | Open source, powerful |
| `mistralai/mistral-medium` | Mistral AI | European alternative |

See [OpenRouter Models](https://openrouter.ai/models) for the complete list.

### Example: Modified openai-chat Function for OpenRouter

You can modify the `openai-chat` function to use OpenRouter:

```typescript
// Get API key - support both OpenAI and OpenRouter
const apiKey = Deno.env.get("OPENROUTER_API_KEY") || Deno.env.get("OPENAI_API_KEY");
const apiUrl = Deno.env.get("OPENROUTER_API_KEY") 
  ? "https://openrouter.ai/api/v1/chat/completions"
  : "https://api.openai.com/v1/chat/completions";

// Call the API
const response = await fetch(apiUrl, {
  method: "POST",
  headers: {
    "Authorization": `Bearer ${apiKey}`,
    "Content-Type": "application/json",
    // OpenRouter-specific headers (optional)
    ...(Deno.env.get("OPENROUTER_API_KEY") && {
      "HTTP-Referer": Deno.env.get("SUPABASE_URL") || "",
      "X-Title": "Supabase AI App"
    })
  },
  body: JSON.stringify({
    model: model, // e.g., "openai/gpt-3.5-turbo" for OpenRouter
    messages: [{ role: "user", content: message }]
  })
});
```

### Benefits of OpenRouter

1. **Cost Savings**: Automatically routes to cheaper alternatives when available
2. **Reliability**: Built-in fallbacks ensure uptime
3. **Flexibility**: Easy to switch between models
4. **Unified Billing**: Single bill for all AI providers
5. **No Vendor Lock-in**: Can use any model without changing code much

### Troubleshooting

**Issue**: "OPENROUTER_API_KEY is not set" error  
**Solution**: 
```bash
# For local development
echo "OPENROUTER_API_KEY=sk-or-your-key" >> .env

# For production
supabase secrets set OPENROUTER_API_KEY=sk-or-your-key
```

**Issue**: Model not found  
**Solution**: 
- Check the model name format: `provider/model-name`
- See [OpenRouter Models](https://openrouter.ai/models) for valid model names
- Example: `openai/gpt-3.5-turbo`, `anthropic/claude-3-sonnet`

**Issue**: Rate limits  
**Solution**: 
- OpenRouter has different rate limits per model
- Check your usage at https://openrouter.ai/activity
- Implement exponential backoff for retries

### Migration from OpenAI to OpenRouter

To migrate from OpenAI to OpenRouter:

1. Change the base URL from `api.openai.com` to `openrouter.ai/api/v1`
2. Update model names to include provider prefix (e.g., `openai/gpt-3.5-turbo`)
3. Add optional OpenRouter headers for app attribution
4. Update your API key environment variable

The request and response format remains the same!

---

## Common Variable Names

To avoid confusion, here are the different AI-related variable names used:

| Variable Name | Purpose | Where Used |
|--------------|---------|------------|
| `SUPABASE_OPENAI_API_KEY` | Studio AI features | `.env` file, read by `config.toml` |
| `OPENAI_API_KEY` | OpenAI in Edge Functions | Function secrets |
| `OPENROUTER_API_KEY` | OpenRouter in Edge Functions | Function secrets |

**Important**: These are **different variables** for different purposes:
- `SUPABASE_OPENAI_API_KEY` → For Supabase Studio UI (OpenAI only)
- `OPENAI_API_KEY` → For your custom Edge Functions (OpenAI direct)
- `OPENROUTER_API_KEY` → For your custom Edge Functions (OpenRouter for multiple models)

---

## Security Notes

⚠️ **Important Security Practices**:

1. **Never commit API keys to git**
   - Keep `.env` in `.gitignore` (already configured)
   - Use environment variables or secrets
   - Rotate keys regularly

2. **Use different keys for different environments**
   - Development key for local work
   - Production key for deployed functions

3. **Monitor usage**
   - Set up usage alerts in OpenAI dashboard
   - Implement rate limiting
   - Log all API calls

4. **Validate inputs**
   - Always validate user input before sending to OpenAI
   - Implement content filtering
   - Set reasonable token limits

---

## Resources

- [OpenAI API Documentation](https://platform.openai.com/docs)
- [OpenAI API Keys](https://platform.openai.com/api-keys)
- [OpenAI Pricing](https://openai.com/pricing)
- [Supabase Edge Functions](https://supabase.com/docs/guides/functions)
- [Supabase Secrets Management](https://supabase.com/docs/guides/functions/secrets)

---

## Support

If you encounter issues:

1. Check this guide for troubleshooting steps
2. Review the example function in `supabase/functions/openai-chat/`
3. Verify your OpenAI API key is valid
4. Check function logs: `supabase functions logs openai-chat`
5. Open an issue on GitHub if the problem persists

---

**Last Updated**: 2025-10-05
