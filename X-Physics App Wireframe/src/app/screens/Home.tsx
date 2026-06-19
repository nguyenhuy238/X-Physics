import { Bell, Coins, ChevronRight, Play, Flame } from "lucide-react";
import { motion } from "motion/react";
import { BottomNav } from "../components/BottomNav";
import { chapters } from "../data";

interface HomeProps {
  onNavigate: (screen: string, data?: unknown) => void;
}

export function Home({ onNavigate }: HomeProps) {
  return (
    <div className="h-full flex flex-col bg-background">
      {/* Header */}
      <div className="bg-gradient-to-br from-primary to-blue-700 pt-12 pb-6 px-5">
        <div className="flex items-start justify-between">
          <div>
            <p className="text-blue-200 text-sm font-medium">Hôm nay là ngày học!</p>
            <h1 className="text-white text-xl font-black mt-0.5">Chào Nam 👋</h1>
          </div>
          <div className="flex items-center gap-2">
            <div className="flex items-center gap-1 bg-white/15 rounded-full px-3 py-1.5">
              <Coins size={14} className="text-secondary" />
              <span className="text-white text-xs font-black">240</span>
            </div>
            <button className="w-8 h-8 bg-white/15 rounded-full flex items-center justify-center relative">
              <Bell size={16} className="text-white" />
              <div className="absolute top-0.5 right-0.5 w-2 h-2 bg-secondary rounded-full border border-primary" />
            </button>
          </div>
        </div>

        {/* Progress Card */}
        <div className="mt-4 bg-white/10 backdrop-blur rounded-2xl p-4 border border-white/10">
          <div className="flex items-center justify-between mb-2">
            <span className="text-white text-sm font-semibold">Tiến độ tổng thể</span>
            <span className="text-secondary font-black text-sm">48%</span>
          </div>
          <div className="h-2.5 bg-white/20 rounded-full overflow-hidden">
            <motion.div
              initial={{ width: 0 }}
              animate={{ width: "48%" }}
              transition={{ duration: 1, delay: 0.3, ease: "easeOut" }}
              className="h-full bg-secondary rounded-full"
            />
          </div>
          <div className="flex gap-4 mt-3">
            {[
              { label: "Bài học", value: "8" },
              { label: "Điểm TB", value: "8.5" },
              { label: "Xu", value: "240" },
            ].map(({ label, value }) => (
              <div key={label}>
                <p className="text-white font-black text-base">{value}</p>
                <p className="text-blue-200 text-[10px] font-medium">{label}</p>
              </div>
            ))}
            <div className="ml-auto flex items-center gap-1 bg-orange-500/20 rounded-full px-2 py-1">
              <Flame size={12} className="text-orange-400" />
              <span className="text-orange-300 text-[10px] font-black">7 ngày</span>
            </div>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-y-auto px-5 pt-4 pb-20 scrollbar-hide">
        <div className="flex items-center justify-between mb-3">
          <h2 className="text-foreground font-black text-base">Chương học</h2>
          <button className="text-primary text-sm font-semibold">Xem tất cả</button>
        </div>

        <div className="flex flex-col gap-3">
          {chapters.map((ch, i) => (
            <motion.div
              key={ch.id}
              initial={{ x: -20, opacity: 0 }}
              animate={{ x: 0, opacity: 1 }}
              transition={{ delay: i * 0.1 + 0.2 }}
              onClick={() => onNavigate("chapter", ch)}
              className="bg-card rounded-2xl p-4 border border-border shadow-sm active:scale-[0.98] transition-transform cursor-pointer"
            >
              <div className="flex items-start gap-3">
                <div
                  className="w-12 h-12 rounded-xl flex items-center justify-center text-2xl shrink-0"
                  style={{ backgroundColor: ch.bgColor }}
                >
                  {ch.icon}
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center justify-between">
                    <h3 className="text-foreground font-black text-sm truncate pr-2">{ch.title}</h3>
                    <ChevronRight size={16} className="text-muted-foreground shrink-0" />
                  </div>
                  <p className="text-muted-foreground text-xs mt-0.5">{ch.lessons} bài học</p>
                  <div className="mt-2 flex items-center gap-2">
                    <div className="flex-1 h-1.5 bg-muted rounded-full overflow-hidden">
                      <div
                        className="h-full rounded-full transition-all"
                        style={{ width: `${ch.progress}%`, backgroundColor: ch.color }}
                      />
                    </div>
                    <span className="text-xs font-black shrink-0" style={{ color: ch.color }}>
                      {ch.progress}%
                    </span>
                  </div>
                </div>
              </div>
              {ch.progress > 0 && ch.progress < 100 && (
                <button
                  onClick={(e) => { e.stopPropagation(); onNavigate("chapter", ch); }}
                  className="mt-3 w-full py-2 rounded-xl flex items-center justify-center gap-1.5 text-xs font-black transition-all active:scale-95"
                  style={{ backgroundColor: ch.bgColor, color: ch.color }}
                >
                  <Play size={12} fill="currentColor" />
                  Tiếp tục học
                </button>
              )}
            </motion.div>
          ))}
        </div>

        {/* Daily tip */}
        <div className="mt-4 bg-gradient-to-r from-purple-500/10 to-primary/10 rounded-2xl p-4 border border-primary/10">
          <div className="flex gap-3 items-start">
            <span className="text-2xl">💡</span>
            <div>
              <p className="text-foreground font-black text-sm">Công thức hôm nay</p>
              <p className="text-muted-foreground text-xs mt-0.5">
                <span className="text-primary font-black">s = v × t</span> — Quãng đường = Vận tốc × Thời gian
              </p>
            </div>
          </div>
        </div>
      </div>

      <BottomNav active="home" onNavigate={onNavigate} />
    </div>
  );
}
