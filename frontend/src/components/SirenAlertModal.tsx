"use client";

import { useEffect } from "react";
import type { RealtimeAlert } from "@/hooks/useSupabaseRealtime";

interface SirenAlertModalProps {
  alert: RealtimeAlert | null;
  isSirenPlaying: boolean;
  autoplayBlocked: boolean;
  onPlaySiren: () => void;
  onStopSiren: () => void;
  onDismiss: () => void;
}

export function SirenAlertModal({
  alert,
  isSirenPlaying,
  autoplayBlocked,
  onPlaySiren,
  onStopSiren,
  onDismiss,
}: SirenAlertModalProps) {
  useEffect(() => {
    // If modal is active, prevent body scrolling for absolute focus
    if (alert) {
      document.body.style.overflow = "hidden";
    } else {
      document.body.style.overflow = "unset";
    }
    return () => {
      document.body.style.overflow = "unset";
    };
  }, [alert]);

  if (!alert) return null;

  return (
    <div className="fixed inset-0 z-[9999] flex items-center justify-center bg-slate-950/85 p-4 backdrop-blur-md animate-fade-in">
      {/* Blinking Red Ambient Glow */}
      <div className="absolute inset-0 bg-rose-950/20 opacity-30 animate-pulse pointer-events-none" />

      {/* Glassmorphic Container Card */}
      <div className="relative w-full max-w-lg overflow-hidden rounded-3xl border border-rose-500/30 bg-slate-900/90 p-6 text-white shadow-[0_0_50px_rgba(244,63,94,0.3)] backdrop-blur-2xl md:p-8 animate-scale-up">
        {/* Beacon Siren Flashing Circle */}
        <div className="flex justify-center mb-6">
          <div className="relative flex h-24 w-24 items-center justify-center">
            <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-rose-500 opacity-20" />
            <span className="animate-ping absolute inline-flex h-4/5 w-4/5 rounded-full bg-rose-500 opacity-40 [animation-delay:0.3s]" />
            <div className="relative flex h-16 w-16 items-center justify-center rounded-full bg-rose-600 shadow-[0_0_20px_#f43f5e] border border-rose-400">
              {/* Siren Megaphone Icon */}
              <svg
                className="h-8 w-8 text-white animate-bounce"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
                strokeWidth={2}
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"
                />
              </svg>
            </div>
          </div>
        </div>

        {/* Header */}
        <div className="text-center space-y-2">
          <span className="inline-flex rounded-full bg-rose-500/10 px-4 py-1 text-xs font-bold tracking-widest uppercase text-rose-400 border border-rose-500/20">
            {alert.severity} ALERT
          </span>
          <h2 className="text-2xl font-black tracking-tight text-rose-100 md:text-3xl">
            {alert.title}
          </h2>
          {alert.targetArea && (
            <p className="text-sm font-semibold tracking-wide text-rose-300">
              Lokasi: Sungai/Area {alert.targetArea}
            </p>
          )}
        </div>

        {/* Warning Details & Message */}
        <div className="mt-6 rounded-2xl border border-slate-800 bg-slate-950/60 p-4 text-center md:p-5">
          <p className="text-sm leading-relaxed text-slate-300 md:text-base font-medium">
            &ldquo;{alert.message}&rdquo;
          </p>
        </div>

        {/* Siren Sound Controller */}
        <div className="mt-6 rounded-2xl border border-rose-500/20 bg-rose-950/15 p-4">
          <div className="flex flex-col items-center justify-between gap-3 sm:flex-row">
            <div className="flex items-center gap-3">
              <span className="relative flex h-3 w-3">
                <span className={`absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75 ${isSirenPlaying ? 'animate-ping' : ''}`} />
                <span className={`relative inline-flex h-3 w-3 rounded-full ${isSirenPlaying ? 'bg-emerald-500' : 'bg-slate-500'}`} />
              </span>
              <p className="text-xs font-semibold text-rose-200">
                {isSirenPlaying ? "Emergency Siren: AKTIF (Sedang Berbunyi)" : "Siren: MATI / DIAM"}
              </p>
            </div>

            <div className="flex items-center gap-2">
              {isSirenPlaying ? (
                <button
                  type="button"
                  onClick={onStopSiren}
                  className="inline-flex items-center gap-2 rounded-xl bg-slate-800 px-4 py-2 text-xs font-bold text-white hover:bg-slate-700 transition-all border border-slate-700"
                >
                  <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                    <path strokeLinecap="round" strokeLinejoin="round" d="M5.586 15H4a1 1 0 01-1-1v-4a1 1 0 011-1h1.586l4.707-4.707C10.923 3.663 12 4.109 12 5v14c0 .891-1.077 1.337-1.707.707L5.586 15z" />
                    <path strokeLinecap="round" strokeLinejoin="round" d="M17 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2" />
                  </svg>
                  Matikan Suara
                </button>
              ) : (
                <button
                  type="button"
                  onClick={onPlaySiren}
                  className="inline-flex items-center gap-2 rounded-xl bg-rose-600 px-4 py-2 text-xs font-bold text-white hover:bg-rose-500 transition-all shadow-[0_0_15px_rgba(220,38,38,0.4)]"
                >
                  <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                    <path strokeLinecap="round" strokeLinejoin="round" d="M15.536 8.464a5 5 0 010 7.072m2.828-9.9a9 9 0 010 12.728M5.586 15H4a1 1 0 01-1-1v-4a1 1 0 011-1h1.586l4.707-4.707C10.923 3.663 12 4.109 12 5v14c0 .891-1.077 1.337-1.707.707L5.586 15z" />
                  </svg>
                  Bunyikan Siren
                </button>
              )}
            </div>
          </div>

          {autoplayBlocked && (
            <p className="mt-3 text-center text-[11px] font-semibold text-rose-300 animate-pulse">
              ⚠️ Browser memblokir suara otomatis. Klik &quot;Bunyikan Siren&quot; di atas untuk memutar secara manual.
            </p>
          )}
        </div>

        {/* Action Buttons */}
        <div className="mt-8 flex flex-col gap-2 sm:flex-row sm:justify-end">
          <button
            type="button"
            onClick={onDismiss}
            className="w-full rounded-2xl bg-slate-800 px-6 py-3.5 text-sm font-bold text-white transition-all hover:bg-slate-700/80 active:scale-95 sm:w-auto"
          >
            Tutup & Abaikan
          </button>
          <a
            href="/emergency"
            className="w-full text-center rounded-2xl bg-rose-600 px-6 py-3.5 text-sm font-black text-white transition-all hover:bg-rose-500 hover:shadow-[0_0_20px_rgba(220,38,38,0.5)] active:scale-95 sm:w-auto"
          >
            PANGGIL BPBD / AMBULANS
          </a>
        </div>
      </div>
    </div>
  );
}
