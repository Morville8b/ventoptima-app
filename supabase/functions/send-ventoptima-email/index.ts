import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const { to, toName, subject, body, kundePdfPath, tekniskPdfPath } = await req.json()

    console.log('📧 Original modtager:', to)
    console.log('🧪 TEST MODE: Sender til morville1976@gmail.com i stedet')

    // Generer signed URLs (30 dage)
    const { data: kundeSignedUrl } = await supabaseClient
      .storage
      .from('ventoptima-rapporter')
      .createSignedUrl(kundePdfPath, 2592000)

    const { data: tekniskSignedUrl } = await supabaseClient
      .storage
      .from('ventoptima-rapporter')
      .createSignedUrl(tekniskPdfPath, 2592000)

    if (!kundeSignedUrl || !tekniskSignedUrl) {
      throw new Error('Kunne ikke generere download links')
    }

    console.log('✅ Download links genereret')

    // Email body med download links
    const emailBody = `
🧪 TEST MODE - Skulle oprindeligt til: ${to} (${toName})

${body}

═══════════════════════════════════════════════
📥 DOWNLOAD RAPPORTER
═══════════════════════════════════════════════

Klik på links nedenfor for at downloade rapporterne:

📄 Kunderapport:
${kundeSignedUrl.signedUrl}

📄 Intern rapport:
${tekniskSignedUrl.signedUrl}

⚠️ Links udløber efter 30 dage

═══════════════════════════════════════════════
    `.trim()

    console.log('📧 Sender via Resend til test-email...')

    const resendApiKey = Deno.env.get('RESEND_API_KEY')
    
    const emailResponse = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${resendApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: 'VentOptima <onboarding@resend.dev>',
        to: ['morville1976@gmail.com'], // TEST MODE: Din email
        subject: `[TEST] ${subject}`,
        text: emailBody,
      }),
    })

    if (!emailResponse.ok) {
      const errorText = await emailResponse.text()
      console.error('Resend fejl:', errorText)
      throw new Error(`Resend error: ${errorText}`)
    }

    const emailResult = await emailResponse.json()
    console.log('✅ Test email sendt!', emailResult)

    return new Response(
      JSON.stringify({ success: true, testMode: true }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      },
    )
  } catch (error) {
    console.error('❌ Fejl:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      },
    )
  }
})