import webPush from 'npm:web-push@3.6.7';
import { createClient } from 'npm:@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type, x-webhook-secret',
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  const webhookSecret = req.headers.get('x-webhook-secret');
  if (webhookSecret !== Deno.env.get('WEBHOOK_SECRET')) {
    return new Response('Unauthorized', { status: 401 });
  }

  const { household_id, inserter_id, amount, type, note } = await req.json();
  if (!household_id) {
    return new Response('Missing household_id', { status: 400 });
  }

  webPush.setVapidDetails(
    `mailto:${Deno.env.get('VAPID_EMAIL') ?? 'admin@meowny.app'}`,
    Deno.env.get('VAPID_PUBLIC_KEY')!,
    Deno.env.get('VAPID_PRIVATE_KEY')!,
  );

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  );

  const { data: subscriptions } = await supabase
    .from('push_subscriptions')
    .select('endpoint, p256dh, auth')
    .eq('household_id', household_id)
    .neq('profile_id', inserter_id);

  if (!subscriptions?.length) {
    return new Response(JSON.stringify({ sent: 0 }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const isExpense = type === 'expense';
  const amountFormatted = new Intl.NumberFormat('vi-VN', {
    style: 'currency',
    currency: 'VND',
  }).format(Math.abs(amount));

  const payload = JSON.stringify({
    title: isExpense ? '🐱 Chi tiêu mới' : '🐱 Thu nhập mới',
    body: note
      ? `${isExpense ? '-' : '+'}${amountFormatted} • ${note}`
      : `${isExpense ? '-' : '+'}${amountFormatted}`,
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
  });

  const results = await Promise.allSettled(
    subscriptions.map((sub) =>
      webPush.sendNotification(
        { endpoint: sub.endpoint, keys: { p256dh: sub.p256dh, auth: sub.auth } },
        payload,
      )
    ),
  );

  // Clean up expired subscriptions (410/404 means the subscription is gone)
  for (let i = 0; i < results.length; i++) {
    const r = results[i];
    if (r.status === 'rejected') {
      const code = (r.reason as { statusCode?: number })?.statusCode;
      if (code === 410 || code === 404) {
        await supabase
          .from('push_subscriptions')
          .delete()
          .eq('endpoint', subscriptions[i].endpoint);
      }
    }
  }

  const sent = results.filter((r) => r.status === 'fulfilled').length;
  return new Response(JSON.stringify({ sent }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
});
