import {
  CategoryInfo,
  ProductItem,
  categoryFromDatabase,
  categorySlugFromName,
  productFromDatabase,
} from "@/lib/catalog";

const API_BASE_URL = (
  process.env.NEXT_PUBLIC_API_URL || "http://127.0.0.1:3000"
).replace(/\/$/, "");

export interface ApiCategory {
  category_id: number;
  category_name: string;
  description: string | null;
}

export interface ApiProduct {
  product_id: number;
  product_name: string;
  price: number;
  stock_quantity: number | null;
  category_id: number | null;
  category_name: string | null;
  image_url: string | null;
}

export interface ApiOrderSummary {
  order_id: number;
  customer_id: number;
  order_date: string | null;
  order_status: string | null;
  total_amount: number;
  payment_status: string | null;
}

export interface ApiOrderDetail {
  order: ApiOrderSummary;
  items: Array<{
    product_id: number;
    product_name: string;
    quantity: number;
    unit_price: number;
  }>;
  payment: { payment_status: string | null } | null;
  delivery: {
    delivery_address: string;
    delivery_status: string | null;
  } | null;
}

export interface CustomerInput {
  name: string;
  email?: string;
  phone?: string;
  address: string;
}

export interface AuthCustomer {
  customer_id: number;
  name: string;
  email: string | null;
  phone: string | null;
  address: string;
}

export interface OtpRequestResult {
  challenge_id: string;
  expires_in_seconds: number;
  message: string;
}

export interface CatalogData {
  categories: CategoryInfo[];
  products: ProductItem[];
}

async function apiRequest<T>(path: string, init?: RequestInit): Promise<T> {
  let response: Response;
  try {
    response = await fetch(`${API_BASE_URL}${path}`, {
      ...init,
      headers: {
        ...(init?.body ? { "Content-Type": "application/json" } : {}),
        ...init?.headers,
      },
      cache: "no-store",
    });
  } catch {
    throw new Error(
      `Cannot reach the backend at ${API_BASE_URL}. Start the Rust API and try again.`
    );
  }

  if (!response.ok) {
    const payload = (await response.json().catch(() => null)) as
      | { error?: string }
      | null;
    throw new Error(payload?.error || `Backend request failed (${response.status})`);
  }

  if (response.status === 204) return undefined as T;
  return (await response.json()) as T;
}

export async function loadCatalog(): Promise<CatalogData> {
  const [apiCategories, apiProducts] = await Promise.all([
    apiRequest<ApiCategory[]>("/api/categories"),
    apiRequest<ApiProduct[]>("/api/products"),
  ]);
  const hiddenCategorySlugs = new Set([
    "baby-care",
    "cosmetics-and-personal-care",
    "cleaning-and-household",
    "pet-supplies",
  ]);
  const categories = apiCategories
    .filter((category) => !hiddenCategorySlugs.has(categorySlugFromName(category.category_name)))
    .map(categoryFromDatabase)
    .filter((category, index, all) => all.findIndex((item) => item.slug === category.slug) === index);
  return {
    categories,
    products: apiProducts
      .filter((product) => !product.category_name || !hiddenCategorySlugs.has(categorySlugFromName(product.category_name)))
      .map((product) => productFromDatabase(product, categories)),
  };
}

export function createCustomer(input: CustomerInput) {
  return apiRequest<{ customer_id: number }>("/api/customers", {
    method: "POST",
    body: JSON.stringify(input),
  });
}

export function requestAuthOtp(input: {
  contact: string;
  name?: string;
  purpose: "signup" | "signin";
}) {
  return apiRequest<OtpRequestResult>("/api/auth/request-otp", {
    method: "POST",
    body: JSON.stringify(input),
  });
}

export function verifyAuthOtp(input: { challenge_id: string; code: string }) {
  return apiRequest<{ customer: AuthCustomer }>("/api/auth/verify-otp", {
    method: "POST",
    body: JSON.stringify(input),
  });
}

export function updateCustomer(customerId: number, input: CustomerInput) {
  return apiRequest<{ customer_id: number }>(`/api/customers/${customerId}`, {
    method: "PUT",
    body: JSON.stringify(input),
  });
}

export function loadWishlist(customerId: number) {
  return apiRequest<ApiProduct[]>(`/api/customers/${customerId}/wishlist`);
}

export function addWishlistItem(customerId: number, productId: number) {
  return apiRequest<{ message: string }>(`/api/customers/${customerId}/wishlist`, {
    method: "POST",
    body: JSON.stringify({ product_id: productId }),
  });
}

export function removeWishlistItem(customerId: number, productId: number) {
  return apiRequest<void>(
    `/api/customers/${customerId}/wishlist/${productId}`,
    { method: "DELETE" }
  );
}

export function placeApiOrder(input: {
  customer_id: number;
  items: Array<{ product_id: number; quantity: number }>;
  payment_method: string;
  delivery_address: string;
  scheduled_delivery_date?: string;
  scheduled_delivery_time?: string;
}) {
  return apiRequest<ApiOrderDetail>("/api/orders", {
    method: "POST",
    body: JSON.stringify(input),
  });
}

export function loadCustomerOrders(customerId: number) {
  return apiRequest<ApiOrderSummary[]>(`/api/customers/${customerId}/orders`);
}
