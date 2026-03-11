// supabase/functions/record_payment/index.ts
// Atomic: updates due status + inserts payment record + inserts transaction ledger entry

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

// ─── Types ────────────────────────────────────────────────────────────────────

interface RecordPaymentBody {
  due_id:           number;
  amount:           number;
  payment_mode:     'cash' | 'upi' | 'bank_transfer' | 'other';
  reference_number?: string;  // UPI txn id, cheque number, etc.
  notes?:           string;
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

    const body: RecordPaymentBody = await req.json();

    // ── Validate ──────────────────────────────────────────────────────────────
    if (!body.due_id) {
      return new Response(
        JSON.stringify({ error: 'due_id is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }
    if (!body.amount || body.amount <= 0) {
      return new Response(
        JSON.stringify({ error: 'amount must be greater than 0' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }
    if (!body.payment_mode) {
      return new Response(
        JSON.stringify({ error: 'payment_mode is required (cash | upi | bank_transfer | other)' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // ── 1. Load due ───────────────────────────────────────────────────────────
    const { data: due, error: dueErr } = await supabase
      .from('dues')
      .select('*, rentals(id, rent_amount, rental_type)')
      .eq('id', body.due_id)
      .single();

    if (dueErr || !due) {
      return new Response(
        JSON.stringify({ error: 'Due record not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // ── 2. Reject if already fully paid / waived ──────────────────────────────
    if (due.status === 'paid' || due.status === 'waived') {
      return new Response(
        JSON.stringify({ error: `Due is already ${due.status}` }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // ── 3. Calculate amounts ──────────────────────────────────────────────────
    const balance    = Number(due.amount_due) - Number(due.amount_paid);
    const paying     = Math.min(body.amount, balance);      // cap at remaining balance
    const newPaid    = Number(due.amount_paid) + paying;
    const newStatus  = newPaid >= Number(due.amount_due) ? 'paid' : 'partial';

    // ── 4. Update due ─────────────────────────────────────────────────────────
    const { error: dueUpdateErr } = await supabase
      .from('dues')
      .update({
        amount_paid: newPaid,
        status:      newStatus,
      })
      .eq('id', body.due_id);

    if (dueUpdateErr) throw new Error(`Failed to update due: ${dueUpdateErr.message}`);

    // ── 5. Insert payment record ──────────────────────────────────────────────
    const paymentDate = new Date().toISOString();
    const { data: payment, error: paymentErr } = await supabase
      .from('payments')
      .insert({
        due_id:           body.due_id,
        rental_id:        due.rental_id,
        customer_id:      due.customer_id,
        amount:           paying,
        payment_date:     paymentDate,
        payment_mode:     body.payment_mode,
        reference_number: body.reference_number ?? null,
        notes:            body.notes ?? null,
      })
      .select()
      .single();

    if (paymentErr) throw new Error(`Failed to insert payment: ${paymentErr.message}`);

    // ── 6. Insert transaction ledger entry ────────────────────────────────────
    const txnType = newStatus === 'paid' ? 'rent_payment' : 'partial_payment';
    const { error: txnErr } = await supabase.from('transactions').insert({
      type:        txnType,
      customer_id: due.customer_id,
      rental_id:   due.rental_id,
      due_id:      body.due_id,
      amount:      paying,
      description: `${txnType === 'rent_payment' ? 'Full payment' : 'Partial payment'} for ${due.cycle_label ?? `due #${body.due_id}`} via ${body.payment_mode}`,
    });

    if (txnErr) throw new Error(`Failed to insert transaction: ${txnErr.message}`);

    // ── 7. Audit log ──────────────────────────────────────────────────────────
    await supabase.from('audit_logs').insert({
      entity_type:  'due',
      entity_id:    body.due_id,
      action:       'update',
      old_values:   { status: due.status, amount_paid: due.amount_paid },
      new_values:   { status: newStatus,  amount_paid: newPaid, payment_id: payment?.id },
      performed_by: 'admin',
    });

    // ── Return success ────────────────────────────────────────────────────────
    return new Response(
      JSON.stringify({
        success:        true,
        new_status:     newStatus,
        amount_paid:    paying,
        balance_before: balance,
        balance_after:  Number(due.amount_due) - newPaid,
        payment_id:     payment?.id,
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (err) {
    console.error('[record_payment] Unhandled error:', err);
    return new Response(
      JSON.stringify({ error: err instanceof Error ? err.message : 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});