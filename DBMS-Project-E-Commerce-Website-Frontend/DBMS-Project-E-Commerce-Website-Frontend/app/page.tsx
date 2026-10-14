"use client";

import React from "react";
import { WorksWheel, type WorksWheelItem } from "@/components/ui/works-wheel";
import { BeamsBackground } from "@/components/ui/beams-background";
import { useStore } from "@/context/store-context";
import { AccountAccessButton } from "@/components/account-access";

export default function HomePage() {
  const {
    theme,
    toggleTheme,
    globalSchedule,
    setIsGlobalScheduleModalOpen,
    categories,
    catalogLoading,
    catalogError,
  } = useStore();

  const wheelCategories: WorksWheelItem[] = categories.map((cat) => ({
    title: cat.title,
    image: cat.image,
    href: `/category/${cat.slug}`,
    subtitle: cat.subtitle,
    badge: cat.badge,
    iconName: cat.slug,
  }));

  return (
    <BeamsBackground intensity="strong">
      <main className="h-screen w-full overflow-hidden">
        <div className="absolute top-5 right-5 z-20">
          <AccountAccessButton className="border-white/20 bg-black/35 text-white hover:bg-black/50" />
        </div>
        {catalogError ? (
          <div className="absolute left-1/2 top-6 z-10 w-[min(90vw,36rem)] -translate-x-1/2 rounded-xl border border-rose-500/40 bg-background/90 px-4 py-3 text-center text-sm text-rose-500 backdrop-blur">
            {catalogError}
          </div>
        ) : catalogLoading && categories.length === 0 ? (
          <div className="absolute inset-0 grid place-items-center text-sm text-muted-foreground">
            Connecting to the store database…
          </div>
        ) : (
          <WorksWheel
          items={wheelCategories}
          label="SwiftCart '26"
          action="Shop"
          onToggleTheme={toggleTheme}
          isDark={theme === "dark"}
          onOpenMapModal={() => setIsGlobalScheduleModalOpen(true)}
          currentAddress={globalSchedule.address}
          className="bg-transparent"
          />
        )}
      </main>
    </BeamsBackground>
  );
}
