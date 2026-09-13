-- Public bucket "join" hosts the tiny https landing page (supabase/join.html)
-- used by invite links. WhatsApp and most chat apps refuse to linkify the
-- custom "shareadi://" scheme, but they do linkify "https://...". Tapping the
-- link opens the published page, whose "Open in Share Adi" button hands the
-- browser off to the real shareadi://join?code=... deep link that the app
-- already handles (see android/app/src/main/AndroidManifest.xml).
--
-- After running this SQL, upload supabase/join.html into the "join" bucket
-- from the Supabase dashboard (Storage -> join -> Upload file). Public
-- buckets serve objects without requiring any extra storage.objects policy.

insert into storage.buckets (id, name, public)
values ('join', 'join', true)
on conflict (id) do update set public = true;