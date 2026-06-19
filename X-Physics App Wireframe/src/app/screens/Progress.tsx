import { BottomNav } from "../components/BottomNav";
import { chapters, quizHistory } from "../data";
import { BarChart, Bar, XAxis, YAxis, ResponsiveContainer, Cell } from "recharts";
import { Flame, Target, BookOpen, Star } from "lucide-react";
import { motion } from "motion/react";

interface ProgressProps {
  onNavigate: (screen: string, data?: unknown) => void;
}

export function Progress({ onNavigate }: ProgressProps) {
  return (
    <div className="h-full flex flex-col bg-background">
      {/* Header */}
      <div className="bg-gradient-to-br from-primary to-blue-700 pt-12 pb-5 px-5">
        <p className="text-blue-200 text-xs font-medium uppercase tracking-wide">Thống kê</p>
        <h1 className="text-white font-black text-xl mt-0.5">Tiến độ học tập</h1>

        <div className="grid grid-cols-4 gap-2 mt-4">
          {[
            { icon: BookOpen, value: "8", label: "Bài học", color: "text-secondary" },
            { icon: Star, value: "8.5", label: "Điểm TB", color: "text-green-300" },
            { icon: Flame, value: "7", label: "Chuỗi ngày", color: "text-orange-300" },
            { icon: Target, value: "48%", label: "Hoàn thành", color: "text-purple-300" },
          ].map(({ icon: Icon, value, label, color }) => (
            <div key={label} className="bg-white/10 rounded-2xl p-2.5 text-center border border-white/10">
              <Icon size={14} className={`${color} mx-auto mb-1`} />
              <p className="text-white font-black text-base leading-none">{value}</p>
              <p className="text-blue-200 text-[9px] font-medium mt-0.5">{label}</p>
            </div>
          ))}
        </div>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-y-auto px-5 pt-4 pb-20 scrollbar-hide flex flex-col gap-4">
        {/* Quiz history chart */}
        <div className="bg-card rounded-2xl p-4 border border-border shadow-sm">
          <h3 className="text-foreground font-black text-sm mb-3">5 bài kiểm tra gần nhất</h3>
          <ResponsiveContainer width="100%" height={120}>
            <BarChart data={quizHistory} barSize={28}>
              <XAxis dataKey="date" tick={{ fontSize: 11, fontWeight: 700, fill: "#64748B" }} axisLine={false} tickLine={false} />
              <YAxis domain={[0, 10]} hide />
              <Bar dataKey="score" radius={[6, 6, 0, 0]}>
                {quizHistory.map((entry, i) => (
                  <Cell key={i} fill={entry.score >= 8 ? "#22C55E" : entry.score >= 6 ? "#2563EB" : "#F59E0B"} />
                ))}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
          <div className="flex gap-3 justify-center mt-1">
            {[{ color: "#22C55E", label: "≥8 Xuất sắc" }, { color: "#2563EB", label: "≥6 Tốt" }, { color: "#F59E0B", label: "<6 Cần cố gắng" }].map(({ color, label }) => (
              <div key={label} className="flex items-center gap-1">
                <div className="w-2 h-2 rounded-full" style={{ backgroundColor: color }} />
                <span className="text-muted-foreground text-[10px] font-medium">{label}</span>
              </div>
            ))}
          </div>
        </div>

        {/* Chapter progress */}
        <div className="bg-card rounded-2xl p-4 border border-border shadow-sm">
          <h3 className="text-foreground font-black text-sm mb-3">Tiến độ theo chương</h3>
          <div className="flex flex-col gap-3">
            {chapters.map((ch, i) => (
              <motion.div
                key={ch.id}
                initial={{ x: -10, opacity: 0 }}
                animate={{ x: 0, opacity: 1 }}
                transition={{ delay: i * 0.1 }}
              >
                <div className="flex items-center justify-between mb-1">
                  <div className="flex items-center gap-2">
                    <span className="text-base">{ch.icon}</span>
                    <span className="text-foreground font-semibold text-xs">{ch.title}</span>
                  </div>
                  <span className="font-black text-xs" style={{ color: ch.color }}>{ch.progress}%</span>
                </div>
                <div className="h-2 bg-muted rounded-full overflow-hidden">
                  <motion.div
                    initial={{ width: 0 }}
                    animate={{ width: `${ch.progress}%` }}
                    transition={{ delay: i * 0.1 + 0.3, duration: 0.7 }}
                    className="h-full rounded-full"
                    style={{ backgroundColor: ch.color }}
                  />
                </div>
              </motion.div>
            ))}
          </div>
        </div>

        {/* Difficult lessons */}
        <div className="bg-card rounded-2xl p-4 border border-border shadow-sm">
          <h3 className="text-foreground font-black text-sm mb-3">Bài học khó cần ôn lại 📚</h3>
          <div className="flex flex-col gap-2">
            {[
              { title: "Vận tốc trung bình", score: 6.5, icon: "🏃" },
              { title: "Tính tương đối của chuyển động", score: 5.0, icon: "🔄" },
            ].map(({ title, score, icon }) => (
              <div key={title} className="flex items-center gap-3 p-3 bg-muted rounded-xl">
                <span className="text-xl">{icon}</span>
                <div className="flex-1">
                  <p className="text-foreground font-semibold text-xs">{title}</p>
                  <p className="text-muted-foreground text-[10px]">Điểm thấp nhất</p>
                </div>
                <span className="text-destructive font-black text-sm">{score}/10</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      <BottomNav active="progress" onNavigate={onNavigate} />
    </div>
  );
}
