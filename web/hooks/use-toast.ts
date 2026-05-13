"use client";

import { useState, useCallback } from "react";

export type ToastVariant = "success" | "error";

interface ToastState {
  message: string;
  variant: ToastVariant;
  /** Incremented on each show so the same message rerenders and resets its timer. */
  key: number;
}

export interface UseToastReturn {
  toast: ToastState | null;
  showToast: (message: string, variant?: ToastVariant) => void;
  dismiss: () => void;
}

export function useToast(): UseToastReturn {
  const [toast, setToast] = useState<ToastState | null>(null);

  const dismiss = useCallback(() => setToast(null), []);

  const showToast = useCallback((message: string, variant: ToastVariant = "success") => {
    setToast((prev) => ({ message, variant, key: (prev?.key ?? 0) + 1 }));
  }, []);

  return { toast, showToast, dismiss };
}
