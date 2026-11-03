import type { Timestamp } from "firebase-admin/firestore";
import type { CoinSku } from "./catalog.js";

/** Contracts only: TypeScript types neither validate untrusted data nor write Firestore. */
export interface Wallet {
  readonly schemaVersion: 1;
  readonly uid: string;
  readonly paidBalance: number; // Safe integral coins; refunds may create debt.
  readonly version: number; // Incremented atomically for each wallet mutation.
  readonly status: "active" | "review_required" | "closed";
  readonly updatedAt: Timestamp; // Server timestamp, never a client clock.
}

/** Global ID is SHA-256 of the JSON tuple [packageName, purchaseToken]. */
export interface VerifiedPurchase {
  readonly purchaseId: string;
  readonly uid: string;
  readonly packageName: "com.tugrahek.nospace";
  readonly sku: CoinSku;
  readonly quantity: 1;
  readonly coins: number;
  readonly catalogVersion: 1;
  readonly environment: "test" | "production";
  readonly accountBinding: string;
  readonly status: "credited" | "refunded" | "review_required";
  readonly verifiedAt: Timestamp;
}

/** Records FIFO allocation from verified purchase lots, never local earned coins. */
export interface PaidFunding {
  readonly purchaseId: string;
  readonly coins: number;
}

export interface PaidEntitlement {
  readonly uid: string;
  readonly itemKind: "character" | "arena";
  readonly itemId: string;
  readonly spendId: string;
  readonly cost: number;
  readonly funding: readonly PaidFunding[];
  readonly status: "active" | "review_required" | "revoked";
  readonly updatedAt: Timestamp;
}

export type LedgerCause =
  | { readonly kind: "purchase_credit"; readonly purchaseId: string }
  | { readonly kind: "unlock_debit"; readonly spendId: string }
  | { readonly kind: "refund_debit"; readonly purchaseId: string; readonly refundId: string }
  | { readonly kind: "unlock_reversal_credit"; readonly spendId: string; readonly refundId: string }
  | { readonly kind: "review_adjustment"; readonly reviewId: string };

/** Append-only; cause-specific stable event IDs enforce at-most-once application. */
export interface LedgerEntry {
  readonly eventId: string;
  readonly uid: string;
  readonly cause: LedgerCause;
  readonly delta: number; // Signed safe integer; direction must match cause.
  readonly balanceAfter: number;
  readonly walletVersion: number;
  readonly createdAt: Timestamp;
}

/** Created in the same transaction as credit; worker consumes only after commit. */
export interface ConsumptionOutbox {
  readonly purchaseId: string;
  readonly uid: string;
  readonly state: "pending" | "consumed" | "review_required";
  readonly attempts: number;
  readonly nextAttemptAt: Timestamp;
  readonly acknowledgementDeadlineAt: Timestamp;
}
