# Environment Setup Guide

## Required Environment Variables

### Supabase Configuration

```bash
EXPO_PUBLIC_SUPABASE_URL=your_supabase_url
EXPO_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
EXPO_PUBLIC_SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
EXPO_PUBLIC_SUPABASE_CONNECTION_STRING=your_connection_string
```

### Payment Integration

#### VNPay Configuration

```bash
VNPAY_TMN_CODE=your_vnpay_tmn_code
VNPAY_HASH_SECRET=your_vnpay_hash_secret
VNPAY_RETURN_URL=your_return_url
```

#### Momo Configuration

```bash
MOMO_PARTNER_CODE=your_momo_partner_code
MOMO_ACCESS_KEY=your_momo_access_key
MOMO_SECRET_KEY=your_momo_secret_key
MOMO_REDIRECT_URL=your_redirect_url
MOMO_IPN_URL=your_ipn_url
```

### AI Integration

```bash
EXPO_PUBLIC_OPENAI_API_KEY=your_openai_api_key
EXPO_PUBLIC_AI_MODEL=gpt-4
EXPO_PUBLIC_AI_MAX_TOKENS=2000
EXPO_PUBLIC_AI_TEMPERATURE=0.7
```

### Other Services

```bash
EXPO_PUBLIC_RORK_API_BASE_URL=your_api_base_url
EXPO_PUBLIC_GITHUB_TOKEN=your_github_token
EXPO_PUBLIC_USE_MOCK_DATA=false
```

### Social Media Integration

```bash
FACEBOOK_APP_ID=your_facebook_app_id
INSTAGRAM_ACCESS_TOKEN=your_instagram_access_token
```

### Expo Push Notifications

```bash
EXPO_ACCESS_TOKEN=your_expo_access_token
```

## Setup Instructions

1. Copy `.env.example` to `.env.local`
2. Fill in your actual values
3. Never commit `.env.local` to version control
4. For production, set these in your deployment platform
