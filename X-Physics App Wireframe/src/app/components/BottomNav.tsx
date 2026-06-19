import { Home, BookOpen, TrendingUp, User } from "lucide-react";

interface BottomNavProps {
  active: "home" | "chapters" | "progress" | "profile";
  onNavigate: (screen: string) => void;
}

const items = [
  { key: "home", icon: Home, label: "Trang chủ" },
  { key: "chapters", icon: BookOpen, label: "Chương học" },
  { key: "progress", icon: TrendingUp, label: "Tiến độ" },
  { key: "profile", icon: User, label: "Hồ sơ" },
];

export function BottomNav({ active, onNavigate }: BottomNavProps) {
  return (
    <div className="absolute bottom-0 left-0 right-0 bg-card border-t border-border flex items-center pb-4 pt-2 px-2">
      {items.map(({ key, icon: Icon, label }) => {
        const isActive = active === key;
        return (
          <button
            key={key}
            onClick={() => onNavigate(key)}
            className="flex-1 flex flex-col items-center gap-0.5 transition-all"
          >
            <div
              className={`p-1.5 rounded-xl transition-all ${isActive ? "bg-primary/10" : ""}`}
            >
              <Icon
                size={20}
                className={isActive ? "text-primary" : "text-muted-foreground"}
                strokeWidth={isActive ? 2.5 : 1.8}
              />
            </div>
            <span
              className={`text-[10px] font-semibold transition-all ${
                isActive ? "text-primary" : "text-muted-foreground"
              }`}
            >
              {label}
            </span>
          </button>
        );
      })}
    </div>
  );
}
