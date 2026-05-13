"use client";

import { useEffect } from "react";
import { cn } from "@/lib/cn";
import type { ToastVariant } from "@/hooks/use-toast";

const AUTO_DISMISS_MS: Record<ToastVariant, number> = {
  success: 3000,
  error: 5000
};

interface ToastProps {
  message: string;
  variant: ToastVariant;
  /** Changing this key resets the auto-dismiss timer for the same message. */
  toastKey: number;
  onDismiss: () => void;
}

export function Toast({ message, variant, toastKey, onDismiss }: ToastProps) {
  useEffect(() => {
    const id = setTimeout(onDismiss, AUTO_DISMISS_MS[variant]);
    return () => clearTimeout(id);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [toastKey]);

  return (
    <div
      role="status"
      aria-live="polite"
      aria-atomic="true"
      className={cn(
        "fixed bottom-6 left-1/2 z-50 -translate-x-1/2",
        "rounded-full px-5 py-2.5 text-sm font-medium shadow-lg",
        "pointer-events-none select-none transition-opacity duration-200",
        variant === "success"
          ? "bg-city-ink text-white"
          : "border border-rose-300 bg-rose-50 text-rose-950"
      )}
    >
      {message}
    </div>
  );
}
