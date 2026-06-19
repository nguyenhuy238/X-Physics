import { BottomNav } from "../components/BottomNav";
import { badges } from "../data";
import { Download, LogOut, ChevronRight, Settings, HelpCircle } from "lucide-react";
import { motion } from "motion/react";

interface ProfileProps {
  onNavigate: (screen: string, data?: unknown) => void;
  onLogout: () => void;
}

export function Profile({ onNavigate, onLogout }: ProfileProps) {
  return (
    <div className="h-full flex flex-col bg-background">
      {/* Header */}
      <div className="bg-gradient-to-br from-primary to-blue-700 pt-12 pb-8 px-5 flex flex-col items-center">
        <div className="relative">
          <div className="w-20 h-20 rounded-full bg-secondary flex items-center justify-center text-3xl border-4 border-white/30 shadow-xl">
            🧑‍🎓
          </div>
          <div className="absolute -bottom-1 -right-1 w-6 h-6 bg-green-400 rounded-full border-2 border-white" />
        </div>
        <h2 className="text-white font-black text-lg mt-3">Nguyễn Văn Nam</h2>
        <p className="text-blue-200 text-sm">nam@example.com</p>
        <div className="flex gap-3 mt-4">
          <div className="bg-white/10 rounded-2xl px-4 py-2 text-center border border-white/10">
            <p className="text-white font-black text-base">Cấp 5</p>
            <p className="text-blue-200 text-[10px]">Cấp độ</p>
          </div>
          <div className="bg-white/10 rounded-2xl px-4 py-2 text-center border border-white/10">
            <p className="text-white font-black text-base">240 🪙</p>
            <p className="text-blue-200 text-[10px]">Xu tích lũy</p>
          </div>
          <div className="bg-white/10 rounded-2xl px-4 py-2 text-center border border-white/10">
            <p className="text-white font-black text-base">8.5</p>
            <p className="text-blue-200 text-[10px]">Điểm TB</p>
          </div>
        </div>
      </div>

      <div className="flex-1 overflow-y-auto px-5 pt-4 pb-20 scrollbar-hide flex flex-col gap-4">
        {/* Badges */}
        <div className="bg-card rounded-2xl p-4 border border-border shadow-sm">
          <div className="flex items-center justify-between mb-3">
            <h3 className="text-foreground font-black text-sm">Huy hiệu của tôi</h3>
            <span className="text-muted-foreground text-xs font-medium">{badges.filter(b => b.earned).length}/{badges.length}</span>
          </div>
          <div className="grid grid-cols-4 gap-3">
            {badges.map((badge, i) => (
              <motion.div
                key={badge.id}
                initial={{ scale: 0.8, opacity: 0 }}
                animate={{ scale: 1, opacity: 1 }}
                transition={{ delay: i * 0.05 }}
                className="flex flex-col items-center gap-1"
              >
                <div className={`w-12 h-12 rounded-2xl flex items-center justify-center text-2xl ${badge.earned ? "bg-secondary/20 border-2 border-secondary/30" : "bg-muted opacity-40 grayscale"}`}>
                  {badge.icon}
                </div>
                <span className="text-[9px] text-center text-muted-foreground font-medium leading-tight">{badge.name}</span>
              </motion.div>
            ))}
          </div>
        </div>

        {/* Offline lessons */}
        <div className="bg-card rounded-2xl p-4 border border-border shadow-sm">
          <div className="flex items-center justify-between mb-3">
            <h3 className="text-foreground font-black text-sm">Bài học offline</h3>
            <button onClick={() => onNavigate("offline")} className="text-primary text-xs font-semibold flex items-center gap-0.5">
              Xem tất cả <ChevronRight size={12} />
            </button>
          </div>
          <div className="flex flex-col gap-2">
            {[
              { title: "Chuyển động đều", size: "2.3 MB", date: "10/06" },
              { title: "Vận tốc trung bình", size: "1.8 MB", date: "09/06" },
            ].map(({ title, size, date }) => (
              <div key={title} className="flex items-center gap-3 p-3 bg-muted rounded-xl">
                <div className="w-8 h-8 bg-primary/10 rounded-lg flex items-center justify-center">
                  <Download size={14} className="text-primary" />
                </div>
                <div className="flex-1">
                  <p className="text-foreground font-semibold text-xs">{title}</p>
                  <p className="text-muted-foreground text-[10px]">{size} · {date}</p>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Menu items */}
        <div className="bg-card rounded-2xl border border-border shadow-sm overflow-hidden">
          {[
            { icon: Settings, label: "Cài đặt" },
            { icon: HelpCircle, label: "Trợ giúp & Phản hồi" },
          ].map(({ icon: Icon, label }) => (
            <button key={label} className="w-full flex items-center gap-3 px-4 py-3.5 border-b border-border last:border-0 active:bg-muted transition-colors">
              <div className="w-8 h-8 bg-muted rounded-lg flex items-center justify-center">
                <Icon size={15} className="text-muted-foreground" />
              </div>
              <span className="text-foreground font-semibold text-sm flex-1 text-left">{label}</span>
              <ChevronRight size={15} className="text-muted-foreground" />
            </button>
          ))}
        </div>

        <button
          onClick={onLogout}
          className="w-full py-3.5 bg-destructive/10 rounded-2xl font-black text-destructive flex items-center justify-center gap-2 active:scale-95 transition-transform border border-destructive/20"
        >
          <LogOut size={16} /> Đăng xuất
        </button>
      </div>

      <BottomNav active="profile" onNavigate={onNavigate} />
    </div>
  );
}
