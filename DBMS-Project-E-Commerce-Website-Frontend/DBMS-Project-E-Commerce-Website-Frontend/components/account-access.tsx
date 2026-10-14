"use client";

import { FormEvent, useEffect, useState } from "react";
import { ArrowLeft, ArrowRight, LoaderCircle, LogOut, ShieldCheck, UserRound, X } from "lucide-react";
import { AuthCustomer, requestAuthOtp, verifyAuthOtp } from "@/lib/api";
import { cn } from "@/lib/utils";

type AuthMode = "signup" | "signin";

function readAccount(): AuthCustomer | null {
  if (typeof window === "undefined" || localStorage.getItem("swiftcart-authenticated") !== "true") return null;
  const customerId = Number(localStorage.getItem("swiftcart-customer-id"));
  const name = localStorage.getItem("swiftcart-customer-name") || "";
  if (!Number.isInteger(customerId) || customerId <= 0 || !name) return null;
  return {
    customer_id: customerId,
    name,
    email: localStorage.getItem("swiftcart-customer-email") || null,
    phone: localStorage.getItem("swiftcart-customer-phone") || null,
    address: "",
  };
}

export function AccountAccessButton({ className }: { className?: string }) {
  const [account, setAccount] = useState<AuthCustomer | null>(null);
  const [open, setOpen] = useState(false);
  const [mode, setMode] = useState<AuthMode>("signup");
  const [step, setStep] = useState<"contact" | "code">("contact");
  const [name, setName] = useState("");
  const [contact, setContact] = useState("");
  const [code, setCode] = useState("");
  const [challengeId, setChallengeId] = useState("");
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    const syncAccount = () => setAccount(readAccount());
    const openDialog = () => {
      setAccount(readAccount());
      setOpen(true);
    };
    syncAccount();
    window.addEventListener("swiftcart-auth-changed", syncAccount);
    window.addEventListener("swiftcart-open-auth", openDialog);
    return () => {
      window.removeEventListener("swiftcart-auth-changed", syncAccount);
      window.removeEventListener("swiftcart-open-auth", openDialog);
    };
  }, []);

  const switchMode = (nextMode: AuthMode) => {
    setMode(nextMode);
    setStep("contact");
    setCode("");
    setChallengeId("");
    setError("");
  };

  const resetAuthForm = () => {
    setMode("signup");
    setStep("contact");
    setName("");
    setContact("");
    setCode("");
    setChallengeId("");
    setError("");
    setBusy(false);
  };

  const closeDialog = () => {
    resetAuthForm();
    setOpen(false);
  };

  const sendCode = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setBusy(true);
    setError("");
    try {
      const result = await requestAuthOtp({
        contact: contact.trim(),
        ...(mode === "signup" ? { name: name.trim() } : {}),
        purpose: mode,
      });
      setChallengeId(result.challenge_id);
      setStep("code");
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : "Could not send the code.");
    } finally {
      setBusy(false);
    }
  };

  const verifyCode = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setBusy(true);
    setError("");
    try {
      const result = await verifyAuthOtp({ challenge_id: challengeId, code: code.trim() });
      const customer = result.customer;
      localStorage.setItem("swiftcart-customer-id", String(customer.customer_id));
      localStorage.setItem("swiftcart-customer-name", customer.name);
      localStorage.setItem("swiftcart-customer-email", customer.email || "");
      localStorage.setItem("swiftcart-customer-phone", customer.phone || "");
      localStorage.setItem("swiftcart-authenticated", "true");
      setAccount(customer);
      setOpen(false);
      setStep("contact");
      setCode("");
      window.dispatchEvent(new Event("swiftcart-auth-changed"));
    } catch (verifyError) {
      setError(verifyError instanceof Error ? verifyError.message : "Could not verify the code.");
    } finally {
      setBusy(false);
    }
  };

  const signOut = () => {
    for (const key of [
      "swiftcart-authenticated",
      "swiftcart-customer-id",
      "swiftcart-customer-name",
      "swiftcart-customer-email",
      "swiftcart-customer-phone",
    ]) localStorage.removeItem(key);
    setAccount(null);
    resetAuthForm();
    setOpen(true);
    window.dispatchEvent(new Event("swiftcart-auth-changed"));
  };

  return (
    <>
      <button
        type="button"
        onClick={() => {
          setAccount(readAccount());
          setError("");
          setOpen(true);
        }}
        aria-label={account ? `Account for ${account.name}` : "Sign up or sign in"}
        className={cn(
          "border-border/70 bg-secondary/60 hover:bg-secondary flex h-9 items-center gap-1.5 rounded-xl border px-3 text-xs font-medium transition-colors",
          className
        )}
      >
        <UserRound className="size-4" />
        <span className="max-w-24 truncate">{account?.name || "Account"}</span>
      </button>

      {open && (
        <div className="fixed inset-0 z-[80] grid place-items-center bg-black/65 p-4 backdrop-blur-sm" onMouseDown={(event) => { if (event.target === event.currentTarget) closeDialog(); }}>
          <section role="dialog" aria-modal="true" aria-labelledby="account-dialog-title" className="border-border bg-card text-card-foreground relative w-full max-w-md rounded-2xl border p-6 shadow-2xl">
            <button type="button" onClick={closeDialog} aria-label="Close account dialog" className="text-muted-foreground hover:text-foreground absolute top-4 right-4 rounded-lg p-1.5">
              <X className="size-4" />
            </button>

            {account ? (
              <div className="space-y-5">
                <div className="bg-primary/10 text-primary flex size-12 items-center justify-center rounded-2xl"><UserRound className="size-6" /></div>
                <div>
                  <h2 id="account-dialog-title" className="text-xl font-bold">Your account</h2>
                  <p className="text-muted-foreground mt-1 text-sm">Signed in as {account.name}</p>
                  <p className="text-muted-foreground mt-1 break-all text-xs">{account.email || account.phone}</p>
                </div>
                <button type="button" onClick={signOut} className="border-border hover:bg-secondary flex w-full items-center justify-center gap-2 rounded-xl border py-2.5 text-sm font-semibold">
                  <LogOut className="size-4" /> Sign out
                </button>
              </div>
            ) : (
              <>
                <div className="bg-primary/10 text-primary mb-4 flex size-12 items-center justify-center rounded-2xl"><ShieldCheck className="size-6" /></div>
                <h2 id="account-dialog-title" className="text-xl font-bold">{step === "code" ? "Verify your contact" : mode === "signup" ? "Create your account" : "Welcome back"}</h2>
                <p className="text-muted-foreground mt-1 text-sm">
                  {step === "code" ? `Enter the 6-digit code sent to ${contact}.` : "Use your email address or phone number. We’ll send you a one-time code."}
                </p>

                {step === "contact" ? (
                  <form onSubmit={sendCode} className="mt-5 space-y-4">
                    {mode === "signup" && (
                      <label className="block text-xs font-semibold">
                        Your name
                        <input value={name} onChange={(event) => setName(event.target.value)} required maxLength={120} autoComplete="name" placeholder="Full name" className="border-border bg-background mt-1.5 w-full rounded-xl border px-3 py-2.5 text-sm outline-none focus:ring-2 focus:ring-orange-500/50" />
                      </label>
                    )}
                    <label className="block text-xs font-semibold">
                      Email or phone number
                      <input value={contact} onChange={(event) => setContact(event.target.value)} required autoComplete="email tel" inputMode="text" placeholder="you@gmail.com or +91 98765 43210" className="border-border bg-background mt-1.5 w-full rounded-xl border px-3 py-2.5 text-sm outline-none focus:ring-2 focus:ring-orange-500/50" />
                    </label>
                    {error && <p role="alert" className="rounded-lg bg-rose-500/10 px-3 py-2 text-xs text-rose-500">{error}</p>}
                    <button disabled={busy} className="bg-primary text-primary-foreground flex w-full items-center justify-center gap-2 rounded-xl py-2.5 text-sm font-semibold disabled:opacity-60">
                      {busy ? <LoaderCircle className="size-4 animate-spin" /> : null} Send verification code <ArrowRight className="size-4" />
                    </button>
                    <p className="text-muted-foreground text-center text-xs">
                      {mode === "signup" ? "Already have an account?" : "New to SwiftCart?"}{" "}
                      <button type="button" onClick={() => switchMode(mode === "signup" ? "signin" : "signup")} className="text-primary font-semibold hover:underline">
                        {mode === "signup" ? "Sign in" : "Create an account"}
                      </button>
                    </p>
                  </form>
                ) : (
                  <form onSubmit={verifyCode} className="mt-5 space-y-4">
                    <label className="block text-xs font-semibold">
                      6-digit verification code
                      <input value={code} onChange={(event) => setCode(event.target.value.replace(/\D/g, "").slice(0, 6))} required inputMode="numeric" autoComplete="one-time-code" pattern="[0-9]{6}" maxLength={6} placeholder="000000" className="border-border bg-background mt-1.5 w-full rounded-xl border px-3 py-3 text-center text-lg tracking-[0.4em] outline-none focus:ring-2 focus:ring-orange-500/50" />
                    </label>
                    {error && <p role="alert" className="rounded-lg bg-rose-500/10 px-3 py-2 text-xs text-rose-500">{error}</p>}
                    <button disabled={busy || code.length !== 6} className="bg-primary text-primary-foreground flex w-full items-center justify-center gap-2 rounded-xl py-2.5 text-sm font-semibold disabled:opacity-60">
                      {busy ? <LoaderCircle className="size-4 animate-spin" /> : null} Verify and continue <ArrowRight className="size-4" />
                    </button>
                    <button type="button" onClick={() => { setStep("contact"); setCode(""); setError(""); }} className="text-muted-foreground hover:text-foreground mx-auto flex items-center gap-1 text-xs font-medium">
                      <ArrowLeft className="size-3.5" /> Use a different email or phone
                    </button>
                  </form>
                )}
              </>
            )}
          </section>
        </div>
      )}
    </>
  );
}
