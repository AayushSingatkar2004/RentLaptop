// supabase/functions/complete_rental/index.ts
// Atomic: marks rental completed + laptop available + customer inactive + optional deposit return txn

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

// ─── Types ────────────────────────────────────────────────────────────────────

interface CompleteRentalBody {
  rental_id:      number;
  return_deposit: boolean;
}

// ─── CORS headers ─────────────────────────────────────────────────────────────

const corsHeaders = {
  'Access-Control-Allow-Origin':  '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// ─── Handler ──────────────────────────────────────────────────────────────────

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    );

    const body: CompleteRentalBody = await req.json();

    // ── Validate ──────────────────────────────────────────────────────────────
    if (!body.rental_id) {
      return new Response(
        JSON.stringify({ error: 'rental_id is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // ── 1. Load rental with laptop + customer info ────────────────────────────
    const { data: rental, error: rentalErr } = await supabase
      .from('rentals')
      .select('*, laptops(id, model, serial_number), customers(id, name, phone)')
      .eq('id', body.rental_id)
      .single();

    if (rentalErr || !rental) {
      return new Response(
        JSON.stringify({ error: 'Rental not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    if (rental.status !== 'active') {
      return new Response(
        JSON.stringify({ error: `Rental is already ${rental.status}` }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // ── 2. Check for unpaid dues (warn — admin confirmed already via Flutter UI) ─
    const { data: unpaidDues } = await supabase
      .from('dues')
      .select('id, amount_due, amount_paid, cycle_label')
      .eq('rental_id', body.rental_id)
      .in('status', ['pending', 'partial']);

    const totalOutstanding = (unpaidDues ?? []).reduce(
      (sum, d) => sum + (d.amount_due - d.amount_paid), 0
    );

    // ── 3. Mark rental as completed ───────────────────────────────────────────
    const completedAt = new Date().toISOString();
    const { error: rentalUpdateErr } = await supabase
      .from('rentals')
      .update({
        status:           'completed',
        completed_at:     completedAt,
        deposit_returned: body.return_deposit,
      })
      .eq('id', body.rental_id);

    if (rentalUpdateErr) throw new Error(`Failed to update rental: ${rentalUpdateErr.message}`);

    // ── 4. Mark laptop as available ───────────────────────────────────────────
    const { error: laptopErr } = await supabase
      .from('laptops')
      .update({ status: 'available' })
      .eq('id', rental.laptop_id);

    if (laptopErr) throw new Error(`Failed to update laptop: ${laptopErr.message}`);

    // ── 5. Mark customer as inactive ──────────────────────────────────────────
    const { error: customerErr } = await supabase
      .from('customers')
      .update({ status: 'inactive' })
      .eq('id', rental.customer_id);

    if (customerErr) throw new Error(`Failed to update customer: ${customerErr.message}`);

    // ── 6. Deposit return transaction (if applicable) ─────────────────────────
    if (body.return_deposit) {
      const { error: txnErr } = await supabase.from('transactions').insert({
        type:        'deposit_returned',
        customer_id: rental.customer_id,
        rental_id:   body.rental_id,
        amount:      -rental.deposit_amount,   // negative = money going out
        description: `Deposit returned for rental #${body.rental_id} — ${rental.laptops?.model ?? ''}`,
      });

      if (txnErr) throw new Error(`Failed to record deposit return transaction: ${txnErr.message}`);
    }

    // ── 7. Audit log ──────────────────────────────────────────────────────────
    await supabase.from('audit_logs').insert({
      entity_type:  'rental',
      entity_id:    body.rental_id,
      action:       'status_change',
      old_values:   { status: 'active' },
      new_values:   {
        status:           'completed',
        completed_at:     completedAt,
        deposit_returned: body.return_deposit,
      },
      performed_by: 'admin',
    });

    // ── Return success ────────────────────────────────────────────────────────
    return new Response(
      JSON.stringify({
        success:              true,
        deposit_returned:     body.return_deposit,
        outstanding_dues:     unpaidDues?.length ?? 0,
        outstanding_amount:   totalOutstanding,
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (err) {
    console.error('[complete_rental] Unhandled error:', err);
    return new Response(
      JSON.stringify({ error: err instanceof Error ? err.message : 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});