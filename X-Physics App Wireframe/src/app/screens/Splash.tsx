import { motion } from "motion/react";
import { Atom } from "lucide-react";

interface SplashProps {
  onStart: () => void;
}

export function Splash({ onStart }: SplashProps) {
  return (
    <div className="h-full flex flex-col items-center justify-between bg-gradient-to-b from-primary to-blue-800 px-8 pt-16 pb-12">
      {/* Top decoration */}
      <div className="flex gap-3 opacity-20">
        {[...Array(5)].map((_, i) => (
          <div key={i} className={`rounded-full bg-white ${i % 2 === 0 ? "w-2 h-2" : "w-1.5 h-1.5 mt-1"}`} />
        ))}
      </div>

      {/* Center */}
      <div className="flex flex-col items-center gap-6">
        <motion.div
          initial={{ scale: 0.5, opacity: 0 }}
          animate={{ scale: 1, opacity: 1 }}
          transition={{ duration: 0.6, type: "spring" }}
          className="w-28 h-28 bg-white/10 rounded-3xl flex items-center justify-center border-2 border-white/20 backdrop-blur"
        >
          <div className="relative">
            <Atom size={56} className="text-secondary" strokeWidth={1.5} />
            <div className="absolute -top-1 -right-1 w-4 h-4 bg-secondary rounded-full border-2 border-primary" />
          </div>
        </motion.div>

        <motion.div
          initial={{ y: 20, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ delay: 0.3, duration: 0.5 }}
          className="text-center"
        >
          <h1 className="text-white text-4xl font-black tracking-tight">X-Physics</h1>
          <p className="text-blue-200 mt-2 text-base font-medium leading-relaxed">
            Học Vật Lý dễ hiểu hơn{"\n"}mỗi ngày
          </p>
        </motion.div>

        {/* Illustration */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.5 }}
          className="flex gap-4 mt-2"
        >
          {[
            { icon: "⚡", label: "Điện học" },
            { icon: "🔬", label: "Thí nghiệm" },
            { icon: "🚀", label: "Cơ học" },
          ].map(({ icon, label }) => (
            <div key={label} className="flex flex-col items-center gap-1">
              <div className="w-14 h-14 bg-white/10 rounded-2xl flex items-center justify-center text-2xl border border-white/10">
                {icon}
              </div>
              <span className="text-blue-200 text-[10px] font-medium">{label}</span>
            </div>
          ))}
        </motion.div>
      </div>

      {/* CTA */}
      <motion.div
        initial={{ y: 30, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{ delay: 0.6 }}
        className="w-full flex flex-col gap-3"
      >
        <button
          onClick={onStart}
          className="w-full py-4 bg-secondary rounded-2xl font-black text-base text-slate-900 shadow-lg shadow-yellow-400/20 active:scale-95 transition-transform"
        >
          Bắt đầu học ngay 🎯
        </button>
        <p className="text-center text-blue-300 text-xs font-medium">
          Dành cho học sinh lớp 8–9 · Miễn phí hoàn toàn
        </p>
      </motion.div>
    </div>
  );
}
