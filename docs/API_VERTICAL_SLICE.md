# API Vertical Slice — Campaign Catalog

## Reviewer Check

Koneksi API sudah tersedia melalui Supabase. Fitur yang dipakai untuk vertical
slice adalah daftar campaign.

```text
HomeScreen
  → campaignListProvider (Riverpod AsyncNotifier)
  → CampaignRepository
  → CampaignRepositoryImpl
  → Supabase table `campaigns`
  → Campaign.fromJson
  → UI list campaign
```

File utama:

- Model: `lib/features/campaign/domain/entities/campaign.dart`
- Kontrak repository: `lib/features/campaign/domain/repositories/campaign_repository.dart`
- Implementasi API: `lib/features/campaign/data/repositories/campaign_repository_impl.dart`
- Provider/state: `lib/features/campaign/presentation/providers/campaign_list_provider.dart`
- UI: `lib/features/campaign/presentation/screens/home_screen.dart`
- Test: `test/features/campaign/campaign_api_test.dart`

## State UI

- **Loading**: provider sedang request Supabase.
- **Success**: campaign berhasil diparse dari JSON lalu ditampilkan sebagai card.
- **Empty**: response Supabase berupa list kosong.
- **Error**: PostgREST/network/JSON error ditampilkan lewat error widget.
- **Retry**: tombol `Coba Lagi` memanggil repository lagi melalui notifier.
- **Fallback lokal**: jika Supabase belum dikonfigurasi, demo lokal memakai data dummy. Saat Supabase aktif, data dibaca dari backend.

## Unit Test

`campaign_api_test.dart` memiliki minimal enam test:

1. Model valid dari JSON.
2. Model invalid menolak field wajib.
3. API sukses mengembalikan campaign.
4. API mengembalikan list kosong.
5. Backend/HTTP gagal menghasilkan `NetworkFailure`.
6. JSON rusak menghasilkan `CampaignApiFailure`.

Jalankan:

```bash
flutter test test/features/campaign/campaign_api_test.dart
flutter test
```

## SQL Supabase

Jalankan di SQL Editor:

```sql
create table public.campaigns (
  id uuid primary key default gen_random_uuid(),
  organizer_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  description text not null,
  target_amount numeric not null check (target_amount > 0),
  collected_amount numeric not null default 0,
  image_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.campaigns enable row level security;

create policy "campaigns are readable"
on public.campaigns for select
using (true);

create policy "organizer owns campaigns"
on public.campaigns for insert
with check (auth.uid() = organizer_id);
```

Setelah tabel terisi, jalankan aplikasi dengan Supabase URL dan publishable key.
Home akan memuat data dari table `campaigns`, bukan data dummy.
