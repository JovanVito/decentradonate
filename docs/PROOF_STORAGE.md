## Proof-of-Impact Storage

Buat bucket Storage `proofs` di Supabase dan tabel metadata berikut:

```sql
create table public.proof_of_impact (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  photo_url text not null,
  ipfs_hash text not null,
  latitude double precision not null,
  longitude double precision not null,
  captured_at timestamptz not null,
  created_at timestamptz not null default now()
);

alter table public.proof_of_impact enable row level security;

create policy "owner can insert proof"
on public.proof_of_impact for insert
with check (auth.uid() = user_id);

create policy "owner can read proof"
on public.proof_of_impact for select
using (auth.uid() = user_id);
```

Atur bucket `proofs` sebagai public hanya jika URL foto boleh diakses publik.
Untuk produksi, gunakan bucket private dan signed URL. Setelah foto berhasil
diunggah ke Pinata, aplikasi menyimpan salinan foto di Storage dan metadata
foto, lokasi, waktu, serta IPFS hash di tabel `proof_of_impact`.
