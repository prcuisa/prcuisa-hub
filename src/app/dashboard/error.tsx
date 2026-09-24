'use client';
export default function DashboardError({ reset }: { reset: () => void }) {
  return <main className="shell"><section className="card stack">
    <h1>Dashboard belum dapat dimuat</h1>
    <p role="alert">Data workspace tidak dapat dibaca. Coba lagi. Jika berulang, periksa migrasi database dan kebijakan akses Supabase.</p>
    <button className="btn" onClick={reset}>Coba lagi</button>
  </section></main>;
}
