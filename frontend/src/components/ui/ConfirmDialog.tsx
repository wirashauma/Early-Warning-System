"use client";

import { useEffect, useRef, useState } from "react";
import { createPortal } from "react-dom";

interface ConfirmDialogProps {
  open: boolean;
  title: string;
  description: string;
  confirmText?: string;
  cancelText?: string;
  onConfirm: () => void;
  onCancel: () => void;
}

export function ConfirmDialog({
  open,
  title,
  description,
  confirmText = "Ya, lanjutkan",
  cancelText = "Batal",
  onConfirm,
  onCancel,
}: ConfirmDialogProps) {
  const overlayRef = useRef<HTMLDivElement | null>(null);
  const dialogRef = useRef<HTMLDivElement | null>(null);
  const cancelButtonRef = useRef<HTMLButtonElement | null>(null);
  const previouslyFocused = useRef<HTMLElement | null>(null);

  useEffect(() => {
    if (!open) return;

    // Save previously focused element to restore focus later
    previouslyFocused.current = document.activeElement as HTMLElement | null;

    // Prevent background scrolling while modal is open
    const prevOverflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";

    // Focus the cancel button by default to avoid accidental destructive actions
    cancelButtonRef.current?.focus();

    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") {
        e.preventDefault();
        onCancel();
        return;
      }

      if (e.key === "Tab") {
        // Simple focus trap: keep focus within dialog
        const dialog = dialogRef.current;
        if (!dialog) return;
        const focusable = dialog.querySelectorAll<HTMLElement>(
          'a[href], button:not([disabled]), textarea, input, select, [tabindex]:not([tabindex="-1"])'
        );
        if (focusable.length === 0) return;

        const first = focusable[0];
        const last = focusable[focusable.length - 1];

        if (e.shiftKey && document.activeElement === first) {
          e.preventDefault();
          last.focus();
        } else if (!e.shiftKey && document.activeElement === last) {
          e.preventDefault();
          first.focus();
        }
      }
    };

    window.addEventListener("keydown", onKey);

    return () => {
      window.removeEventListener("keydown", onKey);
      document.body.style.overflow = prevOverflow;
      // restore focus to previously focused element
      previouslyFocused.current?.focus();
    };
  }, [open, onCancel]);

  const [mounted] = useState(() => typeof window !== "undefined");

  if (!open || !mounted) return null;

  const titleId = "confirm-dialog-title";
  const descId = "confirm-dialog-desc";

  const onOverlayClick = (e: React.MouseEvent) => {
    if (e.target === overlayRef.current) {
      onCancel();
    }
  };

  const dialog = (
    <div
      ref={overlayRef}
      onClick={onOverlayClick}
      className="fixed inset-0 z-70 flex items-center justify-center bg-slate-950/35 p-4 backdrop-blur-[2px]"
      aria-hidden={!open}
    >
      <div
        ref={dialogRef}
        role="dialog"
        aria-modal="true"
        aria-labelledby={titleId}
        aria-describedby={descId}
        className="w-full max-w-md overflow-hidden rounded-3xl border border-slate-100 bg-white shadow-[0_24px_70px_-32px_rgba(15,23,42,0.55)]"
      >
        <div className="border-b border-slate-100 bg-rose-50/70 px-5 py-4">
          <div className="inline-flex items-center gap-2 rounded-full border border-rose-200 bg-white px-3 py-1 text-[11px] font-semibold uppercase tracking-[0.18em] text-rose-700">
            <span className="size-2 rounded-full bg-rose-500" />
            Konfirmasi Aksi
          </div>
        </div>

        <div className="px-5 py-5">
          <h3 id={titleId} className="text-lg font-semibold tracking-tight text-slate-900">
            {title}
          </h3>
          <p id={descId} className="mt-2 text-sm leading-relaxed text-slate-600">
            {description}
          </p>

          <div className="mt-6 flex flex-col-reverse gap-2 sm:flex-row sm:justify-end">
            <button
              ref={cancelButtonRef}
              type="button"
              onClick={onCancel}
              className="rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm font-semibold text-slate-700 transition hover:bg-slate-50"
            >
              {cancelText}
            </button>
            <button
              type="button"
              onClick={onConfirm}
              className="rounded-xl bg-rose-600 px-4 py-2.5 text-sm font-semibold text-white shadow-sm transition hover:bg-rose-700"
            >
              {confirmText}
            </button>
          </div>
        </div>
      </div>
    </div>
  );

  return createPortal(dialog, document.body);
}
