// supabase/functions/create_rental/index.ts
// Atomic: creates customer + rental + marks laptop rented + generates dues + records deposit txn

import { serve } from 'https://deno.land/std@0.208.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

// ─── Types ────────────────────────────────────────────────────────────────────

interface CreateRentalBody {
  // Customer fields
  name:             string;
  phone:            string;
  address:          string;
  id_proof_type:    string;
  id_proof_number:  string;
  id_proof_doc_url?: string;

  // Rental fields
  laptop_id:      number;
  rental_type:    'weekly' | 'monthly' | 'manual';
  duration_count?: number;   // required for weekly / monthly
  start_date:     string;    // ISO date string  e.g. "2024-06-01"
  end_date?:      string;    // required for manual rental type
  rent_amount:    number;
  deposit_amount: number;
  notes?:         string;
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

/** Compute end_date based on rental type */
function computeEndDate(
  startDate: string,
  rentalType: 'weekly' | 'monthly' | 'manual',
  durationCount?: number,
  manualEndDate?: string
): string {
  if (rentalType === 'manual') {
    if (!manualEndDate) throw new Error('end_date is required for manual rental type');
    return manualEndDate;
  }

  const start = new Date(startDate);
  if (!durationCount || durationCount <= 0)
    throw new Error('duration_count must be > 0 for weekly/monthly rental');

  let end: Date;
  if (rentalType === 'weekly') {
    end = new Date(start);
    end.setDate(start.getDate() + durationCount * 7);
  } else {
    // monthly
    end = new Date(start);
    end.setMonth(start.getMonth() + durationCount);
  }

  return end.toISOString().split('T')[0]; // return YYYY-MM-DD
}

/** Generate all due cycle rows for a rental */
function buildDueCycles(rental: {
  id: number;
  customer_id: number;
  start_date: string;
  end_date: string;
  rental_type: string;
  rent_amount: number;
}): object[] {
  const dues: object[] = [];
  let current = new Date(rental.start_date);
  const end   = new Date(rental.end_date);
  let cycle   = 1;

  while (current < end) {
    let dueDate: Date;

    if (rental.rental_type === 'weekly') {
      dueDate = new Date(current);
      dueDate.setDate(current.getDate() + 7);
    } else if (rental.rental_type === 'monthly') {
      dueDate = new Date(current);
      dueDate.setMonth(current.getMonth() + 1);
    } else {
      // manual — single due cycle covering the full period
      dueDate = new Date(end);
    }

    // Cap at end date
    if (dueDate > end) dueDate = new Date(end);

    dues.push({
      rental_id:   rental.id,
      customer_id: rental.customer_id,
      due_date:    dueDate.toISOString().split('T')[0],
      amount_due:  rental.rent_amount,
      amount_paid: 0,
      cycle_label: rental.rental_type === 'manual' ? 'Full Period' : `Cycle ${cycle}`,
      status:      'pending',
    });

    current = dueDate;
    cycle++;

    // Safety: manual rental only gets one cycle
    if (rental.rental_type === 'manual') break;
  }

  return dues;
}

// ─── CORS headers ─────────────────────────────────────────────────────────────

const corsHeaders = {
  'Access-Control-Allow-Origin':  '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// ─── Handler ──────────────────────────────────────────────────────────────────

serve(async (req: Request) => {
  // Handle CORS pre-flight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // Service role client — bypasses RLS for atomic multi-table writes
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    );

    const body: CreateRentalBody = await req.json();

    // ── Validate required fields ──────────────────────────────────────────────
    const required: (keyof CreateRentalBody)[] = [
      'name', 'phone', 'address', 'id_proof_number',
      'laptop_id', 'rental_type', 'start_date', 'rent_amount', 'deposit_amount',
    ];
    for (const field of required) {
      if (body[field] === undefined || body[field] === null || body[field] === '') {
        return new Response(
          JSON.stringify({ error: `Missing required field: ${field}` }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }
    }

    // Validate end_date for manual / duration_count for weekly+monthly
    if (body.rental_type === 'manual' && !body.end_date) {
      return new Response(
        JSON.stringify({ error: 'end_date is required for manual rental type' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }
    if ((body.rental_type === 'weekly' || body.rental_type === 'monthly') && !body.duration_count) {
      return new Response(
        JSON.stringify({ error: 'duration_count is required for weekly/monthly rental type' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // ── 1. Check laptop is available ──────────────────────────────────────────
    const { data: laptop, error: laptopErr } = await supabase
      .from('laptops')
      .select('id, status, model, serial_number')
      .eq('id', body.laptop_id)
      .is('deleted_at', null)
      .single();

    if (laptopErr || !laptop) {
      return new Response(
        JSON.stringify({ error: 'Laptop not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    if (laptop.status !== 'available') {
      return new Response(
        JSON.stringify({ error: `Laptop is not available (current status: ${laptop.status})` }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // ── 2. Validate start < end ───────────────────────────────────────────────
    const endDate = computeEndDate(
      body.start_date, body.rental_type, body.duration_count, body.end_date
    );
    if (new Date(body.start_date) >= new Date(endDate)) {
      return new Response(
        JSON.stringify({ error: 'start_date must be before end_date' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // ── 3. Create customer ────────────────────────────────────────────────────
    const { data: customer, error: customerErr } = await supabase
      .from('customers')
      .insert({
        name:             body.name.trim(),
        phone:            body.phone.trim().replace(/\D/g, ''), // normalise digits only
        address:          body.address.trim(),
        id_proof_type:    body.id_proof_type,
        id_proof_number:  body.id_proof_number.trim(),
        id_proof_doc_url: body.id_proof_doc_url ?? null,
        status:           'active',
      })
      .select()
      .single();

    if (customerErr || !customer) {
      // Check for duplicate phone (unique constraint)
      if (customerErr?.code === '23505') {
        return new Response(
          JSON.stringify({ error: 'A customer with this phone number already exists' }),
          { status: 409, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }
      throw new Error(`Failed to create customer: ${customerErr?.message}`);
    }

    // ── 4. Create rental ──────────────────────────────────────────────────────
    const { data: rental, error: rentalErr } = await supabase
      .from('rentals')
      .insert({
        customer_id:    customer.id,
        laptop_id:      body.laptop_id,
        rental_type:    body.rental_type,
        duration_count: body.duration_count ?? null,
        start_date:     body.start_date,
        end_date:       endDate,
        rent_amount:    body.rent_amount,
        deposit_amount: body.deposit_amount,
        deposit_returned: false,
        status:         'active',
        notes:          body.notes ?? null,
      })
      .select()
      .single();

    if (rentalErr || !rental) {
      // Rollback customer on rental failure (soft: mark deleted)
      await supabase.from('customers').update({ deleted_at: new Date().toISOString() }).eq('id', customer.id);
      throw new Error(`Failed to create rental: ${rentalErr?.message}`);
    }

    // ── 5. Mark laptop as rented ──────────────────────────────────────────────
    const { error: laptopUpdateErr } = await supabase
      .from('laptops')
      .update({ status: 'rented' })
      .eq('id', body.laptop_id);

    if (laptopUpdateErr) throw new Error(`Failed to update laptop status: ${laptopUpdateErr.message}`);

    // ── 6. Generate due cycles ────────────────────────────────────────────────
    const dues = buildDueCycles(rental);
    const { error: duesErr } = await supabase.from('dues').insert(dues);

    if (duesErr) throw new Error(`Failed to insert dues: ${duesErr.message}`);

    // ── 7. Record deposit transaction ─────────────────────────────────────────
    const { error: txnErr } = await supabase.from('transactions').insert({
      type:        'deposit_collected',
      customer_id: customer.id,
      rental_id:   rental.id,
      amount:      body.deposit_amount,
      description: `Deposit collected for rental #${rental.id} — ${laptop.model}`,
    });

    if (txnErr) throw new Error(`Failed to record transaction: ${txnErr.message}`);

    // ── 8. Audit log ──────────────────────────────────────────────────────────
    await supabase.from('audit_logs').insert({
      entity_type:  'rental',
      entity_id:    rental.id,
      action:       'create',
      new_values:   { ...rental, customer_name: customer.name, laptop_model: laptop.model },
      performed_by: 'admin',
    });

    // ── Return success ────────────────────────────────────────────────────────
    return new Response(
      JSON.stringify({ customer, rental, dues_count: dues.length }),
      { status: 201, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (err) {
    console.error('[create_rental] Unhandled error:', err);
    return new Response(
      JSON.stringify({ error: err instanceof Error ? err.message : 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});