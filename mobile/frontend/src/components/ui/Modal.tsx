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
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/40 p-4">
      <div className="w-full max-w-lg rounded-xl bg-white p-5 shadow-xl">
        <div className="mb-4 flex items-center justify-between">
          <h3 className="text-lg font-semibold text-slate-900">{title}</h3>
          <Button variant="secondary" onClick={onClose}>
            Tutup
          </Button>
        </div>
        {children}
      </div>
    </div>
  );
}
