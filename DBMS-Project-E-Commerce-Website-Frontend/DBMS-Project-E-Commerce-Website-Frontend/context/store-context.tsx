"use client";

import React, { createContext, useContext, useEffect, useState } from "react";
import { CategoryInfo, ProductItem } from "@/lib/catalog";
import {
  addWishlistItem,
  createCustomer,
  loadCatalog,
  loadCustomerOrders,
  loadWishlist,
  placeApiOrder,
  removeWishlistItem,
  updateCustomer,
  type CustomerInput,
} from "@/lib/api";

export interface DeliverySchedule {
  mode: "instant" | "scheduled";
  date: string; // e.g. "Today, Oct 10" or "Tomorrow, Oct 11" or custom YYYY-MM-DD
  timeSlot: string; // e.g. "4:00 PM - 5:00 PM"
  frequency: "once" | "daily" | "weekly";
  instructions?: string;
  address: string;
}

export interface CartItem {
  product: ProductItem;
  quantity: number;
  variant?: string;
  schedule?: DeliverySchedule;
}

export interface ScheduledOrder {
  id: string;
  createdAt: string;
  items: CartItem[];
  total: number;
  schedule: DeliverySchedule;
  status: string;
}

interface ToastMessage {
  id: string;
  title: string;
  subtitle?: string;
  type: "cart" | "wishlist" | "schedule" | "order";
}

interface StoreContextValue {
  theme: "dark" | "light";
  products: ProductItem[];
  categories: CategoryInfo[];
  catalogLoading: boolean;
  catalogError: string | null;
  refreshCatalog: () => Promise<void>;
  toggleTheme: () => void;
  cart: CartItem[];
  wishlist: string[];
  globalSchedule: DeliverySchedule;
  orders: ScheduledOrder[];
  isCartOpen: boolean;
  setIsCartOpen: (open: boolean) => void;
  isWishlistOpen: boolean;
  setIsWishlistOpen: (open: boolean) => void;
  schedulingProduct: ProductItem | null;
  setSchedulingProduct: (product: ProductItem | null) => void;
  isGlobalScheduleModalOpen: boolean;
  setIsGlobalScheduleModalOpen: (open: boolean) => void;
  addToCart: (
    product: ProductItem,
    variant?: string,
    schedule?: DeliverySchedule
  ) => void;
  removeFromCart: (productId: string, variant?: string) => void;
  updateQuantity: (productId: string, delta: number, variant?: string) => void;
  setToastMessage: (title: string, subtitle?: string, type?: ToastMessage["type"]) => void;
  getItemQuantity: (productId: string, variant?: string) => number;
  toggleWishlist: (product: ProductItem) => void;
  isWishlisted: (productId: string) => boolean;
  updateGlobalSchedule: (schedule: DeliverySchedule) => void;
  placeOrder: (customer: Omit<CustomerInput, "address">) => Promise<ScheduledOrder | null>;
  checkoutBusy: boolean;
  cartCount: number;
  cartSubtotal: number;
  toasts: ToastMessage[];
  dismissToast: (id: string) => void;
}

const DEFAULT_SCHEDULE: DeliverySchedule = {
  mode: "instant",
  date: "Today",
  timeSlot: "Instant (8–15 mins)",
  frequency: "once",
  address: "",
  instructions: "",
};

function scheduleDateForDatabase(label: string): string | undefined {
  if (/^\d{4}-\d{2}-\d{2}$/.test(label)) return label;
  const date = new Date();
  if (label === "Tomorrow") date.setDate(date.getDate() + 1);
  if (label === "This Weekend") {
    const daysUntilSaturday = (6 - date.getDay() + 7) % 7 || 7;
    date.setDate(date.getDate() + daysUntilSaturday);
  }
  if (!["Today", "Tomorrow", "This Weekend"].includes(label)) return undefined;
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}-${String(date.getDate()).padStart(2, "0")}`;
}

function scheduleTimeForDatabase(label: string): string | undefined {
  const match = label.match(/^(\d{1,2}):(\d{2})\s*(AM|PM)/i);
  if (!match) return undefined;
  let hours = Number(match[1]) % 12;
  if (match[3].toUpperCase() === "PM") hours += 12;
  return `${String(hours).padStart(2, "0")}:${match[2]}:00`;
}

const StoreContext = createContext<StoreContextValue | undefined>(undefined);

export function StoreProvider({ children }: { children: React.ReactNode }) {
  // Default mode is DARK as requested by user
  const [theme, setTheme] = useState<"dark" | "light">("dark");
  const [products, setProducts] = useState<ProductItem[]>([]);
  const [categories, setCategories] = useState<CategoryInfo[]>([]);
  const [catalogLoading, setCatalogLoading] = useState(true);
  const [catalogError, setCatalogError] = useState<string | null>(null);
  const [checkoutBusy, setCheckoutBusy] = useState(false);
  const [cart, setCart] = useState<CartItem[]>([]);
  const [wishlist, setWishlist] = useState<string[]>([]);
  const [globalSchedule, setGlobalSchedule] =
    useState<DeliverySchedule>(DEFAULT_SCHEDULE);
  const [orders, setOrders] = useState<ScheduledOrder[]>([]);
  const [isCartOpen, setIsCartOpen] = useState(false);
  const [isWishlistOpen, setIsWishlistOpen] = useState(false);
  const [schedulingProduct, setSchedulingProduct] =
    useState<ProductItem | null>(null);
  const [isGlobalScheduleModalOpen, setIsGlobalScheduleModalOpen] =
    useState(false);
  const [toasts, setToasts] = useState<ToastMessage[]>([]);

  const pushToast = (
    title: string,
    subtitle?: string,
    type: ToastMessage["type"] = "cart"
  ) => {
    const id = `${Date.now()}-${Math.random()}`;
    setToasts((prev) => [...prev.slice(-2), { id, title, subtitle, type }]);
    setTimeout(() => {
      setToasts((prev) => prev.filter((t) => t.id !== id));
    }, 3200);
  };

  const setToastMessage = (
    title: string,
    subtitle?: string,
    type: ToastMessage["type"] = "cart"
  ) => pushToast(title, subtitle, type);

  const dismissToast = (id: string) => {
    setToasts((prev) => prev.filter((t) => t.id !== id));
  };

  const refreshCatalog = async () => {
    setCatalogLoading(true);
    try {
      const catalog = await loadCatalog();
      setCategories(catalog.categories);
      setProducts(catalog.products);
      setCart((current) =>
        current.flatMap((item) => {
          const freshProduct = catalog.products.find((product) => product.id === item.product.id);
          return freshProduct ? [{ ...item, product: freshProduct }] : [];
        })
      );
      setCatalogError(null);
    } catch (error) {
      setCatalogError(error instanceof Error ? error.message : "Could not load store inventory");
    } finally {
      setCatalogLoading(false);
    }
  };

  useEffect(() => {
    void refreshCatalog();
  }, []);

  // Hydrate from localStorage & sync dark class on <html>
  useEffect(() => {
    try {
      const savedTheme = localStorage.getItem("instamart-theme") as
        | "dark"
        | "light"
        | null;
      const initialTheme = savedTheme || "dark";
      setTheme(initialTheme);
      document.documentElement.classList.toggle("dark", initialTheme === "dark");

      const savedCart = localStorage.getItem("instamart-cart");
      if (savedCart) setCart(JSON.parse(savedCart));

      const savedWishlist = localStorage.getItem("instamart-wishlist");
      if (savedWishlist) {
        const savedIds = JSON.parse(savedWishlist) as string[];
        setWishlist(savedIds.filter((id) => /^\d+$/.test(id)));
      }

      const customerId = Number(localStorage.getItem("swiftcart-customer-id"));
      const isAuthenticated = localStorage.getItem("swiftcart-authenticated") === "true";
      if (isAuthenticated && Number.isInteger(customerId) && customerId > 0) {
        void loadWishlist(customerId)
          .then((items) => setWishlist(items.map((item) => String(item.product_id))))
          .catch(() => {});
        void loadCustomerOrders(customerId)
          .then((rows) => {
            setOrders(rows.map((row) => ({
              id: String(row.order_id),
              createdAt: row.order_date || "",
              items: [],
              total: row.total_amount,
              schedule: {
                ...DEFAULT_SCHEDULE,
                address: "Saved delivery address",
                date: row.order_date || "Order date unavailable",
                timeSlot: "See order status",
              },
              status: row.order_status || "Processing",
            })));
          })
          .catch(() => {});
      }
    } catch {
      document.documentElement.classList.add("dark");
    }
  }, []);

  useEffect(() => {
    const syncSignedInCustomer = () => {
      if (localStorage.getItem("swiftcart-authenticated") !== "true") {
        setOrders([]);
        setWishlist([]);
        return;
      }
      const customerId = Number(localStorage.getItem("swiftcart-customer-id"));
      if (!Number.isInteger(customerId) || customerId <= 0) return;
      void loadWishlist(customerId)
        .then((items) => setWishlist(items.map((item) => String(item.product_id))))
        .catch(() => {});
      void loadCustomerOrders(customerId)
        .then((rows) => {
          setOrders(rows.map((row) => ({
            id: String(row.order_id),
            createdAt: row.order_date || "",
            items: [],
            total: row.total_amount,
            schedule: {
              ...DEFAULT_SCHEDULE,
              address: "Saved delivery address",
              date: row.order_date || "Order date unavailable",
              timeSlot: "See order status",
            },
            status: row.order_status || "Processing",
          })));
        })
        .catch(() => {});
    };
    window.addEventListener("swiftcart-auth-changed", syncSignedInCustomer);
    return () => window.removeEventListener("swiftcart-auth-changed", syncSignedInCustomer);
  }, []);

  useEffect(() => {
    try {
      localStorage.setItem("instamart-cart", JSON.stringify(cart));
    } catch {}
  }, [cart]);

  useEffect(() => {
    try {
      localStorage.setItem("instamart-wishlist", JSON.stringify(wishlist));
    } catch {}
  }, [wishlist]);

  useEffect(() => {
    try {
      localStorage.setItem("instamart-orders", JSON.stringify(orders));
    } catch {}
  }, [orders]);

  const toggleTheme = () => {
    setTheme((prev) => {
      const next = prev === "dark" ? "light" : "dark";
      document.documentElement.classList.toggle("dark", next === "dark");
      try {
        localStorage.setItem("instamart-theme", next);
      } catch {}
      return next;
    });
  };

  const addToCart = (
    product: ProductItem,
    variant?: string,
    schedule?: DeliverySchedule
  ) => {
    if (!product.inStock) {
      pushToast("Currently out of stock", product.name, "cart");
      return;
    }
    const selectedQuantity = cart
      .filter((item) => item.product.id === product.id)
      .reduce((total, item) => total + item.quantity, 0);
    if (
      product.stockQuantity !== null &&
      product.stockQuantity !== undefined &&
      selectedQuantity >= product.stockQuantity
    ) {
      pushToast("Stock limit reached", `${product.stockQuantity} available`, "cart");
      return;
    }
    const chosenVariant = variant || product.variants?.[0];
    setCart((prev) => {
      const idx = prev.findIndex(
        (item) =>
          item.product.id === product.id && item.variant === chosenVariant
      );
      if (idx > -1) {
        const updated = [...prev];
        updated[idx] = {
          ...updated[idx],
          quantity: updated[idx].quantity + 1,
          schedule: schedule || updated[idx].schedule,
        };
        return updated;
      }
      return [
        ...prev,
        {
          product,
          quantity: 1,
          variant: chosenVariant,
          schedule,
        },
      ];
    });

    if (schedule) {
      pushToast(
        `Scheduled: ${product.name}`,
        `${schedule.date} • ${schedule.timeSlot}`,
        "schedule"
      );
    } else {
      pushToast(
        `Added to Cart`,
        `${product.name}${chosenVariant ? ` (${chosenVariant})` : ""}`,
        "cart"
      );
    }
  };

  const removeFromCart = (productId: string, variant?: string) => {
    setCart((prev) =>
      prev.filter(
        (item) =>
          !(
            item.product.id === productId &&
            (variant === undefined || item.variant === variant)
          )
      )
    );
  };

  const updateQuantity = (
    productId: string,
    delta: number,
    variant?: string
  ) => {
    if (delta > 0) {
      const product = products.find((item) => item.id === productId);
      const selectedQuantity = cart
        .filter((item) => item.product.id === productId)
        .reduce((total, item) => total + item.quantity, 0);
      if (
        product?.stockQuantity !== null &&
        product?.stockQuantity !== undefined &&
        selectedQuantity >= product.stockQuantity
      ) {
        pushToast("Stock limit reached", `${product.stockQuantity} available`, "cart");
        return;
      }
    }
    setCart((prev) =>
      prev
        .map((item) => {
          if (
            item.product.id === productId &&
            (variant === undefined || item.variant === variant)
          ) {
            const nextQty = item.quantity + delta;
            return nextQty > 0 ? { ...item, quantity: nextQty } : null;
          }
          return item;
        })
        .filter(Boolean) as CartItem[]
    );
  };

  const getItemQuantity = (productId: string, variant?: string) => {
    return cart
      .filter(
        (item) =>
          item.product.id === productId &&
          (variant === undefined || item.variant === variant)
      )
      .reduce((acc, item) => acc + item.quantity, 0);
  };

  const toggleWishlist = (product: ProductItem) => {
    const customerId = Number(localStorage.getItem("swiftcart-customer-id"));
    const isAuthenticated = localStorage.getItem("swiftcart-authenticated") === "true";
    const productId = Number(product.id);
    const wasSaved = wishlist.includes(product.id);
    setWishlist((prev) => {
      if (wasSaved) {
        pushToast("Removed from Wishlist", product.name, "wishlist");
        return prev.filter((id) => id !== product.id);
      } else {
        pushToast("Saved to Wishlist ❤️", product.name, "wishlist");
        return [...prev, product.id];
      }
    });
    if (isAuthenticated && Number.isInteger(customerId) && customerId > 0 && productId > 0) {
      const request = wasSaved
        ? removeWishlistItem(customerId, productId)
        : addWishlistItem(customerId, productId);
      void request.catch((error) => {
        setWishlist((prev) =>
          wasSaved ? [...prev, product.id] : prev.filter((id) => id !== product.id)
        );
        pushToast("Wishlist could not be saved", error instanceof Error ? error.message : "Try again", "wishlist");
      });
    }
  };

  const isWishlisted = (productId: string) => wishlist.includes(productId);

  const updateGlobalSchedule = (schedule: DeliverySchedule) => {
    setGlobalSchedule(schedule);
    pushToast(
      schedule.mode === "instant"
        ? "Switched to Instant Delivery ⚡"
        : "Delivery Slot Scheduled 📅",
      `${schedule.date} • ${schedule.timeSlot}`,
      "schedule"
    );
  };

  const cartCount = cart.reduce((sum, item) => sum + item.quantity, 0);
  const cartSubtotal = cart.reduce(
    (sum, item) => sum + item.product.price * item.quantity,
    0
  );

  const placeOrder = async (
    customer: Omit<CustomerInput, "address">
  ): Promise<ScheduledOrder | null> => {
    if (cart.length === 0) return null;
    if (localStorage.getItem("swiftcart-authenticated") !== "true") {
      pushToast("Sign in to continue", "Create an account or sign in before placing your order.", "order");
      window.dispatchEvent(new Event("swiftcart-open-auth"));
      return null;
    }
    if (!globalSchedule.address.trim()) {
      pushToast(
        "Delivery address required",
        "Add your address before placing the order.",
        "schedule"
      );
      return null;
    }
    if (!customer.name.trim()) {
      pushToast("Name required", "Enter your name before placing the order.", "order");
      return null;
    }
    setCheckoutBusy(true);
    try {
      const customerInput: CustomerInput = {
        ...customer,
        address: globalSchedule.address.trim(),
      };
      const deliveryAddress = globalSchedule.instructions?.trim()
        ? `${globalSchedule.address.trim()} (Delivery instructions: ${globalSchedule.instructions.trim()})`
        : globalSchedule.address.trim();
      let customerId = Number(localStorage.getItem("swiftcart-customer-id"));
      if (!Number.isInteger(customerId) || customerId <= 0) {
        const created = await createCustomer(customerInput);
        customerId = created.customer_id;
        localStorage.setItem("swiftcart-customer-id", String(customerId));
        await Promise.all(
          wishlist.map((id) => {
            const productId = Number(id);
            return productId > 0
              ? addWishlistItem(customerId, productId).catch(() => undefined)
              : Promise.resolve()
          })
        );
      } else {
        await updateCustomer(customerId, customerInput);
      }
      localStorage.setItem("swiftcart-customer-name", customerInput.name);
      localStorage.setItem("swiftcart-customer-email", customerInput.email || "");
      localStorage.setItem("swiftcart-customer-phone", customerInput.phone || "");

      const quantities = new Map<number, number>();
      for (const item of cart) {
        const productId = Number(item.product.id);
        quantities.set(productId, (quantities.get(productId) || 0) + item.quantity);
      }
      const order = await placeApiOrder({
        customer_id: customerId,
        items: [...quantities].map(([product_id, quantity]) => ({ product_id, quantity })),
        payment_method: "Cash on Delivery",
        delivery_address: deliveryAddress,
        ...(globalSchedule.mode === "scheduled"
          ? {
              scheduled_delivery_date: scheduleDateForDatabase(globalSchedule.date),
              scheduled_delivery_time: scheduleTimeForDatabase(globalSchedule.timeSlot),
            }
          : {}),
      });
      const savedOrder: ScheduledOrder = {
        id: String(order.order.order_id),
        createdAt: order.order.order_date || new Date().toISOString(),
        items: [...cart],
        total: order.order.total_amount,
        schedule: { ...globalSchedule },
        status: order.order.order_status || "Processing",
      };
      setOrders((prev) => [savedOrder, ...prev.filter((old) => old.id !== savedOrder.id)]);
      setCart([]);
      pushToast(`Order #${savedOrder.id} confirmed`, "The order was saved to the database.", "order");
      await refreshCatalog();
      return savedOrder;
    } catch (error) {
      pushToast("Order could not be placed", error instanceof Error ? error.message : "Try again", "order");
      return null;
    } finally {
      setCheckoutBusy(false);
    }
  };

  return (
    <StoreContext.Provider
      value={{
        theme,
        toggleTheme,
        products,
        categories,
        catalogLoading,
        catalogError,
        refreshCatalog,
        cart,
        wishlist,
        globalSchedule,
        orders,
        isCartOpen,
        setIsCartOpen,
        isWishlistOpen,
        setIsWishlistOpen,
        schedulingProduct,
        setSchedulingProduct,
        isGlobalScheduleModalOpen,
        setIsGlobalScheduleModalOpen,
        addToCart,
        removeFromCart,
        updateQuantity,
        setToastMessage,
        getItemQuantity,
        toggleWishlist,
        isWishlisted,
        updateGlobalSchedule,
        placeOrder,
        checkoutBusy,
        cartCount,
        cartSubtotal,
        toasts,
        dismissToast,
      }}
    >
      {children}
    </StoreContext.Provider>
  );
}

export function useStore() {
  const ctx = useContext(StoreContext);
  if (!ctx) {
    throw new Error("useStore must be used within a StoreProvider");
  }
  return ctx;
}

export function getWishlistedProducts(ids: string[], products: ProductItem[]): ProductItem[] {
  return products.filter((p) => ids.includes(p.id));
}
