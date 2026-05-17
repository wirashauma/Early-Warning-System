"use client";

import type { PropsWithChildren } from "react";
import { Button } from "./Button";

interface ModalProps {
  open: boolean;
  title: string;
  onClose: () => void;
}

export function Modal({ open, title, onClose, children }: PropsWithChildren<ModalProps>) {
  if (!open) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-950/35 p-4 backdrop-blur-[2px]">
      <div className="w-full max-w-2xl overflow-hidden rounded-3xl border border-slate-100 bg-white shadow-[0_30px_80px_-40px_rgba(15,23,42,0.55)]">
        <div className="border-b border-slate-100 bg-slate-50/80 px-5 py-4">
          <div className="flex items-center justify-between gap-3">
            <div>
              <p className="text-[11px] font-semibold uppercase tracking-[0.18em] text-blue-700">Flood Guard</p>
              <h3 className="mt-1 text-lg font-semibold tracking-tight text-slate-900">{title}</h3>
            </div>
            <Button variant="secondary" onClick={onClose} className="rounded-xl border border-slate-200 bg-white px-3 py-2 text-xs font-semibold text-slate-700 hover:bg-slate-50">
              Tutup
            </Button>
          </div>
        </div>
        <div className="px-5 py-5 md:px-6 md:py-6">{children}</div>
      </div>
    </div>
  );
}
