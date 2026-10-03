# Auth, Profile, dan Organizer

## Database

Blockchain tetap menjadi sumber data untuk transaksi, saldo, dan catatan
campaign yang sudah dicatat oleh smart contract. Supabase dipakai untuk
data identitas aplikasi yang tidak sesuai disimpan di blockchain: akun,
profil, peran, dan metadata pendukung.

Supabase Auth menyimpan email dan password secara aman. Password tidak
disimpan oleh aplikasi dan tidak ditulis ke blockchain. Tabel `profiles`
menyimpan username, email, nomor telepon, foto profil, dan role.

SQL awal yang perlu dijalankan di Supabase:

```sql
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null unique,
  email text not null,
  phone text,
  avatar_url text,
  role text not null default 'donatur' check (role in ('donatur', 'organizer')),
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "profile owner can read"
on public.profiles for select
using (auth.uid() = id);

create policy "profile owner can insert"
on public.profiles for insert
with check (auth.uid() = id);

create policy "profile owner can update"
on public.profiles for update
using (auth.uid() = id);
```

Untuk membuat profile otomatis setelah signup, tambahkan trigger pada
`auth.users`, atau lakukan insert profile dari Edge Function. Service role
key tidak boleh dimasukkan ke aplikasi Flutter.

## Konfigurasi Flutter

Jalankan aplikasi dengan dua nilai konfigurasi:

```bash
flutter run --dart-define=SUPABASE_URL=https://project.supabase.co --dart-define=SUPABASE_ANON_KEY=public-anon-key
```

Nilai tersebut dibaca oleh `lib/core/constants/supabase_config.dart`.
Anon key boleh digunakan di aplikasi dengan RLS aktif. Service role key
harus tetap berada di server atau Edge Function.

## Alur Fitur

- Signup menerima username, email, password, dan konfirmasi password.
- Password strength diperbarui setiap karakter dengan kategori Weak,
  Medium, dan Strong.
- Login memakai email dan password melalui Supabase Auth.
- Forgot password mengirim link reset melalui email Supabase.
- Profile menampilkan username, email, nomor telepon, dan role.
- Settings menyediakan logout dan permintaan hapus akun.
- Pengguna biasa dapat membuka syarat penyelenggara.
- Semua syarat harus dicentang sebelum role organizer diaktifkan.
- Organizer mendapat akses ke form pembuatan campaign.

Penghapusan akun Auth membutuhkan Edge Function karena penghapusan user dari
`auth.users` memerlukan service role. Tombol pada aplikasi saat ini memberi
pesan yang menjelaskan kebutuhan tersebut, bukan menyimpan service role key
di perangkat.

## Penamaan Navigasi

- Wallet hanya untuk pembuatan, import, backup, alamat, dan saldo wallet.
- Explorer hanya untuk riwayat transaksi on-chain.
- Profile untuk identitas pengguna dan akses menjadi organizer.
- Settings untuk logout dan penghapusan akun.
