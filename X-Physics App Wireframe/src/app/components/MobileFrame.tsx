import { ReactNode } from "react";

interface MobileFrameProps {
  children: ReactNode;
}

export function MobileFrame({ children }: MobileFrameProps) {
  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-800 to-slate-900 flex items-center justify-center p-4">
      <div
        className="relative bg-background rounded-[2.5rem] overflow-hidden shadow-2xl"
        style={{ width: 390, height: 844, fontFamily: "'Nunito', sans-serif" }}
      >
        {/* Status bar */}
        <div className="absolute top-0 left-0 right-0 z-50 flex items-center justify-between px-6 pt-3 pb-1">
          <span className="text-xs font-semibold" style={{ color: "inherit" }}>9:41</span>
          <div className="flex gap-1 items-center">
            <div className="w-4 h-2.5 border border-current rounded-sm opacity-80 relative">
              <div className="absolute inset-0.5 right-1 bg-current rounded-xs" />
            </div>
          </div>
        </div>
        <div className="absolute top-0 left-1/2 -translate-x-1/2 w-24 h-6 bg-foreground/90 rounded-b-xl z-50" />
        <div className="h-full overflow-hidden">{children}</div>
      </div>
    </div>
  );
}
